#!/usr/bin/env bash

###################
### Definitions ###
###################

ZATHURA_EXE_DEFAULT="/opt/homebrew/bin/zathura"
ZATHURA_APP="/Applications/Zathura.app"
ZATHURA_ICON_URL="https://raw.githubusercontent.com/homebrew-zathura/homebrew-zathura/132bb38829938ed8dfdd24f46946aab93f4482e5/icon/zathura-brosasaki.icns"

#######################
### Find executable ###
#######################

echo "Finding executable..."

ZATHURA_EXE_FROM_PATH=$(command -v zathura)

if [[ -f ${ZATHURA_EXE_DEFAULT} ]]
then
  echo "zathura executable found at ${ZATHURA_EXE_DEFAULT}"
  ZATHURA_EXE=${ZATHURA_EXE_DEFAULT}
elif [[ -f ${ZATHURA_EXE_FROM_PATH} ]]
then
  echo "zathura executable not found at default location (${ZATHURA_EXE_DEFAULT});"
  echo "use ${ZATHURA_EXE_FROM_PATH} from \$PATH instead"
  ZATHURA_EXE=${ZATHURA_EXE_FROM_PATH}
else
  echo "zathura executable not found neither at ${ZATHURA_EXE_DEFAULT}, nor in \$PATH"
  exit 1
fi

############################
### Create app structure ###
############################

echo "Creating app structure..."

mkdir -p "${ZATHURA_APP}/Contents/MacOS" "${ZATHURA_APP}/Contents/Resources"

#######################
### Copy executable ###
#######################

echo "Copying executable..."

cp -f "${ZATHURA_EXE}" "${ZATHURA_APP}/Contents/MacOS/zathura"

#########################
### Create Info.plist ###
#########################

echo "Creating Info.plist..."

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
    <string>com.pwmt.zathura</string>
    <key>CFBundleVersion</key>
    <string>1.0</string>
    <key>CFBundleExecutable</key>
    <string>zathura</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
</dict>
</plist>
EOF

echo "${info_plist}" >"${ZATHURA_APP}/Contents/Info.plist"

#########################
### Download the icon ###
#########################

echo "Downloading the icon..."

curl -o "${ZATHURA_APP}/Contents/Resources/AppIcon.icns" "${ZATHURA_ICON_URL}"

###############
### Caveats ###
###############

echo "Caveats..."

cat <<EOF
Now you can run the app by double clicking on it.

Next steps:
To change the icon, follow the README.md in the repo.
You will notice that when Zathura opens, no file is showing. To open a file, type \`:open <path to file>\` while within zathura, or \`zathura open example.pdf\` from the command line. Pressing <Tab> will show recent files that the viewer has opened
EOF
