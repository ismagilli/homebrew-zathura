#!/usr/bin/env bash

# Default executable path
ZATHURA_EXE_DEFAULT="/opt/homebrew/bin/zathura"
# Fallback executable path (may be empty)
ZATHURA_EXE_FROM_PATH="$(command -v zathura)"
# Application path
ZATHURA_APP="/Applications/Zathura.app"
# Icon URL
ZATHURA_ICON_URL="https://raw.githubusercontent.com/homebrew-zathura/homebrew-zathura/refs/heads/master/zathura-brosasaki.icns"
# Package info
ZATHURA_IDENTIFIER="com.pwmt.zathura"
ZATHURA_VER="0.5.11"
ZATHURA_ABOUT="zathura, a highly customizable and functional document viewer. Visit https://pwmt.org/projects/zathura for details."
ZATHURA_COPYRIGHT="Copyright (c) 2009-2025, pwmt.org"
ZATHURA_SUPPORTED_EXTS="pdf,djvu" # comma-separated list, e.g. "pdf,djvu"

echo "This script will convert the zathura binary into a macOS App"

if [[ -f "${ZATHURA_EXE_DEFAULT}" ]]
then
  echo "zathura executable found at ${ZATHURA_EXE_DEFAULT}"
  ZATHURA_EXE="${ZATHURA_EXE_DEFAULT}"
elif [[ -f "${ZATHURA_EXE_FROM_PATH}" ]]
then
  echo "zathura executable not found at ${ZATHURA_EXE_DEFAULT}; use ${ZATHURA_EXE_FROM_PATH} from \$PATH instead"
  ZATHURA_EXE="${ZATHURA_EXE_FROM_PATH}"
else
  echo "zathura executable not found neither at ${ZATHURA_EXE_DEFAULT}, nor in \$PATH"
  exit 1
fi

echo "Creating ${ZATHURA_APP}"
mkdir -p "${ZATHURA_APP}/Contents/MacOS"
mkdir -p "${ZATHURA_APP}/Contents/Resources"
cp "${ZATHURA_EXE}" "${ZATHURA_APP}/Contents/MacOS/zathura"
touch "${ZATHURA_APP}/Contents/Info.plist"

# SC2312 (info): Consider invoking this command separately to avoid masking its return value (or use '|| true' to ignore).
# shellcheck disable=SC2312
ZATHURA_SUPPORTED_EXTS_XML=$(
  echo "${ZATHURA_SUPPORTED_EXTS}" |
    tr ',' '\n' |
    sed 's/.*/<string>&<\/string>/' |
    tr '\n' ' '
)
read -r -d '' info_plist <<-EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key>
    <string>Zathura</string>

    <key>CFBundleDisplayName</key>
    <string>Zathura</string>

    <key>CFBundleIdentifier</key>
    <string>${ZATHURA_IDENTIFIER}</string>

    <key>CFBundleVersion</key>
    <string>${ZATHURA_VER}</string>

    <key>CFBundleGetInfoString</key>
    <string>${ZATHURA_ABOUT}</string>

    <key>NSHumanReadableCopyright</key>
    <string>${ZATHURA_COPYRIGHT}</string>

    <key>CFBundleDocumentTypes</key>
    <array>
        <dict>
            <key>CFBundleTypeExtensions</key>
            <array>
                ${ZATHURA_SUPPORTED_EXTS_XML}
            </array>

            <key>CFBundleTypeIconFile</key>
            <string>AppIcon</string>

            <key>CFBundleTypeName</key>
            <string>Documents</string>

            <key>CFBundleTypeRole</key>
            <string>Viewer</string>
        </dict>
    </array>

    <key>CFBundlePackageType</key>
    <string>APPL</string>

    <key>CFBundleExecutable</key>
    <string>zathura</string>

    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
</dict>
</plist>
EOF

echo "${info_plist}" >"${ZATHURA_APP}/Contents/Info.plist"

echo "Getting the icon"
curl -o "${ZATHURA_APP}/Contents/Resources/AppIcon.icns" "${ZATHURA_ICON_URL}"

echo "Making it executable"
chmod +x "${ZATHURA_APP}/Contents/MacOS/zathura"

cat <<EOF
Now you can run the app by double clicking on it.

Next steps:
To change the icon, follow the README.md in the repo. You will notice that when Zathura opens, no file is showing. To open a file, type \`:open <path to file>\` while within zathura, or \`zathura open example.pdf\` from the command line. Pressing <Tab> will show recent files that the viewer has opened.
EOF
