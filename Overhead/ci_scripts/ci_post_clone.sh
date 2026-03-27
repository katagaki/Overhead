#!/bin/sh
set -e

PLIST_PATH="${CI_PRIMARY_REPOSITORY_PATH}/Overhead/Overhead/ODPTKey.plist"

if [ -z "$ODPT_CONSUMER_KEY" ]; then
    echo "warning: ODPT_CONSUMER_KEY not set — writing placeholder to ODPTKey.plist"
    ODPT_CONSUMER_KEY="YOUR_ODPT_CONSUMER_KEY_HERE"
fi

cat > "$PLIST_PATH" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>ODPTConsumerKey</key>
	<string>${ODPT_CONSUMER_KEY}</string>
</dict>
</plist>
EOF

echo "ODPTKey.plist generated at ${PLIST_PATH}"
