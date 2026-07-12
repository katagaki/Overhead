import Foundation

// MARK: - JR East Line Data

enum JREastLineData {

    static func st(_ line: String, _ suffix: String, _ ja: String, _ en: String,
                    _ code: String, _ lat: Double, _ lon: Double) -> Station {
        Station(
            id: "Station:JR-East.\(line).\(suffix)",
            name: ja, nameEn: en, stationCode: code,
            latitude: lat, longitude: lon
        )
    }

    static func through(_ junction: String, _ end: ThroughService.LineEnd,
                         _ lineJa: String, _ lineEn: String,
                         _ towardJa: String, _ towardEn: String,
                         to connectingLineId: String? = nil) -> ThroughService {
        ThroughService(
            junctionStationId: "Station:JR-East.\(junction)",
            end: end,
            lineNameJa: lineJa, lineNameEn: lineEn,
            towardJa: towardJa, towardEn: towardEn,
            connectingLineId: connectingLineId
        )
    }

    /// Chuo Rapid exact run: terminus suffix resolves to a ChuoRapid station id;
    /// `thru: true` marks a run entering the line mid-way (中央本線から at 高尾,
    /// 青梅線から at 立川) rather than originating there (当駅始発); `cont: true`
    /// marks a run continuing beyond its last in-line station onto another line
    /// (青梅行き leaving at 立川, or 大月方面 continuing past 高尾).
    static func jc(_ dep: String, to: String? = nil, thru: Bool = false, cont: Bool = false) -> ExactRun {
        ExactRun(dep, terminusStationId: to.map { "Station:JR-East.ChuoRapid.\($0)" },
                 startsHere: !thru, continuesBeyond: cont)
    }

    /// Chuo-Sobu Local exact run: terminus suffix resolves to a ChuoSobuLocal
    /// station id; `thru: true` marks a run entering the line mid-way (東西線から
    /// at 中野/西船橋); `cont: true` marks a run leaving onto the 東西線 mid-line.
    static func jb(_ dep: String, to: String? = nil, thru: Bool = false, cont: Bool = false) -> ExactRun {
        ExactRun(dep, terminusStationId: to.map { "Station:JR-East.ChuoSobuLocal.\($0)" },
                 startsHere: !thru, continuesBeyond: cont)
    }

    /// Keihin-Tohoku exact run: terminus suffix resolves to a KeihinTohoku
    /// station id; `thru: true` marks a run entering from the 横浜線 at 東神奈川;
    /// `cont: true` marks a run leaving onto the 横浜線 there.
    static func jk(_ dep: String, to: String? = nil, thru: Bool = false, cont: Bool = false) -> ExactRun {
        ExactRun(dep, terminusStationId: to.map { "Station:JR-East.KeihinTohoku.\($0)" },
                 startsHere: !thru, continuesBeyond: cont)
    }

    /// Pattern backed by real exact runs; first/last are informative only.
    static func exact(_ runs: [ExactRun], first: String, last: String,
                       _ type: TrainService.TrainType = .local) -> ServicePattern {
        ServicePattern(first: first, last: last, bands: [], trainType: type, exactRuns: runs)
    }

    static func pattern(_ first: String, _ last: String, _ bands: [(String, Double)],
                         _ trainType: TrainService.TrainType = .local) -> ServicePattern {
        ServicePattern(
            first: first, last: last,
            bands: bands.map { HeadwayBand(from: $0.0, headwayMinutes: $0.1) },
            trainType: trainType
        )
    }

    static func direction(_ line: String, _ suffix: String, _ ja: String, _ en: String,
                           ascending: Bool,
                           weekday: ServicePattern, holiday: ServicePattern,
                           intermediateOrigins: [IntermediateOrigin] = []) -> StaticLineDirection {
        StaticLineDirection(
            id: "static.RailDirection:JR-East.\(line).\(suffix)",
            nameJa: ja, nameEn: en,
            isAscending: ascending,
            weekday: weekday, saturdayHoliday: holiday,
            intermediateOrigins: intermediateOrigins
        )
    }

    /// Joban Local exact run: terminus suffix resolves to a JobanLocal station id;
    /// `thru: true` marks a through-run entering at the origin (not 当駅始発).
    static func jl(_ dep: String, to: String? = nil, thru: Bool = false) -> ExactRun {
        ExactRun(dep, terminusStationId: to.map { "Station:JR-East.JobanLocal.\($0)" }, startsHere: !thru)
    }

    /// Joban Rapid exact run (same shape, JobanRapid station ids).
    static func jj(_ dep: String, to: String? = nil, thru: Bool = false) -> ExactRun {
        ExactRun(dep, terminusStationId: to.map { "Station:JR-East.JobanRapid.\($0)" }, startsHere: !thru)
    }

    // MARK: Delay Check

    // Delays of 15+ minutes are posted on the Train Operation Information page
    static let delayInfo = DelayCheckInfo(
        statusPageURL: "https://traininfo.jreast.co.jp/train_info/kanto.aspx",
        statusPageURLEn: "https://traininfo.jreast.co.jp/train_info/e/kanto.aspx",
        xAccount: nil,
        checkMethodJa: "JR東日本「列車運行情報」ページまたはJR東日本アプリで確認できます。首都圏エリアでは15分以上の遅れ・運休が発生または見込まれる場合に掲載されます。",
        checkMethodEn: "Check the JR East Train Operation Information page or the JR East app. In the Tokyo area, delays or suspensions of 15 minutes or more are posted."
    )

    static let lines: [StaticTrainLine] = [
        yamanote,
        chuoRapid,
        chuoSobuLocal,
        keihinTohoku,
        saikyo,
        keiyo,
    ] + extendedLines

    static var extendedLines: [StaticTrainLine] {
        [
            jobanRapid, jobanLocal, yokosukaSobu, tokaido, shonanShinjuku,
            utsunomiya, takasaki, yokohamaLine, nambu, musashino, keiyoBranch,
            ome, itsukaichi,
        ]
    }
}
