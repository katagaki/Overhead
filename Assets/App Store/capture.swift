#!/usr/bin/env swift
// Captures raw App Store screenshots from the simulator.
// Usage: swift capture.swift <path-to-Overhead.app> <ja|en> [shot names...]
// Stages each screen through the DEBUG-only overtrain:// deep-link harness
// (see Overhead/Classes/ScreenshotHarness.swift).

import Foundation

let udid = "571BCB64-DC54-4C4A-8985-E076E8E4EE08"  // "iPhone 4" (iPhone 17 Pro, iOS 27)
let bundleId = "com.tsubuzaki.Overhead"
let scriptDir = URL(fileURLWithPath: CommandLine.arguments[0]).deletingLastPathComponent()
let language = CommandLine.arguments.count > 2 ? CommandLine.arguments[2] : "ja"
let rawDir = scriptDir.appendingPathComponent("Raw").appendingPathComponent(language)

@discardableResult
func xcrun(_ args: [String]) -> (status: Int32, output: String) {
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/usr/bin/xcrun")
    process.arguments = args
    let pipe = Pipe()
    process.standardOutput = pipe
    process.standardError = pipe
    try! process.run()
    process.waitUntilExit()
    let data = pipe.fileHandleForReading.readDataToEndOfFile()
    return (process.terminationStatus, String(data: data, encoding: .utf8) ?? "")
}

// The overtrain:// staging URLs ride along as launch arguments: the DEBUG
// harness consumes them at startup, and no system open-URL prompt appears.
func launchApp(urls: [String] = []) {
    xcrun(["simctl", "terminate", udid, bundleId])
    sleep(2)
    xcrun(["simctl", "launch", udid, bundleId,
           "-hasDismissedStartupNotice", "YES",
           "-AppleLanguages", "(\(language))"] + urls)
    sleep(5)
}

struct Shot {
    let name: String
    /// overtrain:// staging URLs, sent in order after a clean launch.
    let urls: [String]
    let waitSeconds: UInt32
}

let shots: [Shot] = [
    Shot(name: "01-home", urls: [], waitSeconds: 2),
    Shot(name: "02-planner", urls: ["overtrain://planner?action=search"], waitSeconds: 6),
    Shot(name: "03-journey", urls: [
        "overtrain://lcd?style=joban",
        "overtrain://journey?minutesAgo=55",
    ], waitSeconds: 5),
    Shot(name: "04-lcd-metro", urls: [
        "overtrain://lcd?style=tokyoMetro",
        "overtrain://journey?minutesAgo=40&line=Railway:TokyoMetro.Tozai&from=Station:TokyoMetro.Tozai.Nakano&to=Station:TokyoMetro.Tozai.NishiFunabashi",
    ], waitSeconds: 5),
    Shot(name: "05-lcd-yamanote", urls: [
        "overtrain://lcd?style=yamanote",
        "overtrain://journey?minutesAgo=20&line=Railway:JR-East.Yamanote&from=Station:JR-East.Yamanote.Ikebukuro&to=Station:JR-East.Yamanote.Akihabara",
    ], waitSeconds: 5),
    Shot(name: "06-timetable", urls: ["overtrain://timetable"], waitSeconds: 5),
    Shot(name: "07-avoid", urls: ["overtrain://planner?action=avoid"], waitSeconds: 5),
    Shot(name: "08-customline", urls: [
        "overtrain://lcd?style=kivotos",
        "overtrain://custom-line",
    ], waitSeconds: 5),
]

try? FileManager.default.createDirectory(at: rawDir, withIntermediateDirectories: true)

// Boot and configure the simulator.
xcrun(["simctl", "bootstatus", udid, "-b"])
xcrun(["simctl", "ui", udid, "appearance", "dark"])
xcrun(["simctl", "privacy", udid, "grant", "location-always", bundleId])
// Marunouchi side, a short walk from Tokyo Station.
xcrun(["simctl", "location", udid, "set", "35.6796,139.7625"])
xcrun(["simctl", "status_bar", udid, "override",
       "--time", "9:41",
       "--batteryState", "discharging", "--batteryLevel", "55",
       "--cellularMode", "active", "--cellularBars", "2",
       "--dataNetwork", "4g",
       "--operatorName", ""])

// Fresh install when an app path is passed in.
if CommandLine.arguments.count > 1 {
    let appPath = CommandLine.arguments[1]
    xcrun(["simctl", "terminate", udid, bundleId])
    let result = xcrun(["simctl", "install", udid, appPath])
    guard result.status == 0 else {
        print("install failed: \(result.output)")
        exit(1)
    }
}

// Seeding pass: reset clears leftover planner state (vias, avoided lines);
// favorites and the sample custom line persist across launches, but the
// home screen only shows them from the next launch on.
launchApp(urls: ["overtrain://reset", "overtrain://seed/favorites", "overtrain://seed/custom-line"])

// Extra arguments past the app path and language select a subset of shots.
let onlyNames = Set(CommandLine.arguments.dropFirst(3))
for shot in shots where onlyNames.isEmpty || onlyNames.contains(shot.name) {
    launchApp(urls: shot.urls)
    sleep(shot.waitSeconds)
    let file = rawDir.appendingPathComponent("\(shot.name).png").path
    let capture = xcrun(["simctl", "io", udid, "screenshot", file])
    print(capture.status == 0 ? "captured \(shot.name)" : "screenshot failed for \(shot.name): \(capture.output)")
}

xcrun(["simctl", "terminate", udid, bundleId])
print("done")
