#!/usr/bin/env bash

###################
### Definitions ###
###################

ZATHURA_EXE_DEFAULT="/opt/homebrew/bin/zathura"
ZATHURA_APP="/Applications/Zathura.app"
ZATHURA_ICON_URL="https://raw.githubusercontent.com/homebrew-zathura/homebrew-zathura/refs/heads/master/zathura-brosasaki.icns"

########################
### Helper functions ###
########################

COLOR_RESET="\033[0m"
COLOR_RED="\033[31m"
COLOR_YELLOW="\033[33m"
COLOR_GRAY="\033[90m"

# @param1 level name (error|warn|info|debug)
# @param2 message
__log() {
  level=$1
  message=$2

  case ${level} in
    error)
      color=${COLOR_RED}
      prefix="ERROR"
      ;;
    warn)
      color=${COLOR_YELLOW}
      prefix="WARN"
      ;;
    info)
      color=""
      prefix="INFO"
      ;;
    debug)
      color=${COLOR_GRAY}
      prefix="DEBUG"
      ;;
    *)
      color=""
      prefix="UNKNOWN"
      ;;
  esac

  echo -e "${color}[${prefix}] ${message}${COLOR_RESET}" 1>&2
}

# @param1 message
debug() {
  __log debug "$*"
}

# @param1 message
info() {
  __log info "$*"
}

# @param1 message
warn() {
  __log warn "$*"
}

# @param1 message
error() {
  __log error "$*"
}

#######################
### Find executable ###
#######################

debug "Finding executable..."

ZATHURA_EXE_FROM_PATH=$(command -v zathura)

if [[ -f ${ZATHURA_EXE_DEFAULT} ]]
then
  info "zathura executable found at ${ZATHURA_EXE_DEFAULT}"
  ZATHURA_EXE=${ZATHURA_EXE_DEFAULT}
elif [[ -f ${ZATHURA_EXE_FROM_PATH} ]]
then
  warn "zathura executable not found at default location (${ZATHURA_EXE_DEFAULT});"
  warn "use ${ZATHURA_EXE_FROM_PATH} from \$PATH instead"
  ZATHURA_EXE=${ZATHURA_EXE_FROM_PATH}
else
  echo "zathura executable not found neither at ${ZATHURA_EXE_DEFAULT}, nor in \$PATH"
  exit 1
fi

############################
### Create app structure ###
############################

debug "Creating app structure..."

mkdir -p "${ZATHURA_APP}/Contents/MacOS" "${ZATHURA_APP}/Contents/Resources"

#######################
### Copy executable ###
#######################

debug "Copying executable..."

cp -f "${ZATHURA_EXE}" "${ZATHURA_APP}/Contents/MacOS/zathura"

#########################
### Create Info.plist ###
#########################

debug "Creating Info.plist..."

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

debug "Downloading the icon..."

curl -o "${ZATHURA_APP}/Contents/Resources/AppIcon.icns" "${ZATHURA_ICON_URL}"

###############
### Caveats ###
###############

debug "Caveats..."

cat <<EOF
Now you can run the app by double clicking on it.

Next steps:
To change the icon, follow the README.md in the repo.
You will notice that when Zathura opens, no file is showing. To open a file, type \`:open <path to file>\` while within zathura, or \`zathura example.pdf\` from the command line. Pressing <Tab> will show recent files that the viewer has opened
EOF
