#!/usr/bin/env bash

###################
### Definitions ###
###################

ZATHURA_EXE_DEFAULT="/opt/homebrew/bin/zathura"
ZATHURA_APP="/Applications/AAA_Zathura.app"
ZATHURA_ICON_URL="https://raw.githubusercontent.com/homebrew-zathura/homebrew-zathura/refs/heads/master/zathura-brosasaki.icns"

########################
### Helper functions ###
########################

COLOR_RESET="\033[0m"
COLOR_RED="\033[31m"
COLOR_GREEN="\033[32m"
COLOR_YELLOW="\033[33m"

info() {
  echo -e "${COLOR_GREEN}$@${COLOR_RESET}"
}

warn() {
  echo -e "${COLOR_YELLOW}$@${COLOR_RESET}"
}

error() {
  echo -e "${COLOR_RED}$@${COLOR_RESET}"
  exit 1
}

# TODO: remove it
rm -rf "${ZATHURA_APP}"

#######################
### Find executable ###
#######################

info "Finding executable"

if [[ -f "${ZATHURA_EXE_DEFAULT}" ]]
then
  info "zathura executable found at ${ZATHURA_EXE_DEFAULT}"
  ZATHURA_EXE="${ZATHURA_EXE_DEFAULT}"
elif [[ -f "$(command -v zathura)" ]]
then
  ZATHURA_EXE="$(command -v zathura)"
  warn "zathura executable not found at ${ZATHURA_EXE_DEFAULT};"
  warn "use ${ZATHURA_EXE} from \$PATH instead"
else
  error "zathura executable not found neither at ${ZATHURA_EXE_DEFAULT}, nor in \$PATH"
fi

############################
### Create app structure ###
############################

info "Creating app structure"

mkdir -p "${ZATHURA_APP}/Contents/MacOS" "${ZATHURA_APP}/Contents/Resources/plugins"

#######################
### Copy executable ###
#######################

info "Copying app structure"

cp "${ZATHURA_EXE}" "${ZATHURA_APP}/Contents/MacOS"

################################################
### Copy plugins and form list of extensions ###
################################################

info "Copying plugins and forming list of extensions"

# Note: If any plugin is installed, then this will
# have extra space symbol at the beginning.
ZATHURA_SUPPORTED_EXTS=""

# @param1 plugin name without zathura- prefix
# @param2 plugin supported extensions
function process_plugin () {
  plugin="$1"
  exts="$2"

  plugin_prefix=$(brew --prefix "zathura-${plugin}" 2>/dev/null)
  [[ $? -eq 0 ]] || return 0

  plugin_path="${plugin_prefix}/lib${plugin}.dylib"
  [[ -f "${plugin_path}" ]] || return 0

  info "zathura-${plugin} plugin was found"

  ZATHURA_SUPPORTED_EXTS="${ZATHURA_SUPPORTED_EXTS} ${exts}"
  cp "${plugin_path}" "${ZATHURA_APP}/Contents/Resources/plugins"
}

process_plugin cb "" # TODO
process_plugin djvu "djvu djv"
process_plugin pdf-mupdf "pdf"
process_plugin pdf-poppler "pdf"
process_plugin ps "ps eps"

if [[ -z "${ZATHURA_SUPPORTED_EXTS}" ]]
then
  warn "No plugins has been found"
fi

if [[ $(echo "${ZATHURA_SUPPORTED_EXTS}" | grep -o pdf | wc -l) -gt 1 ]]
then
  warn "zathura-pdf-mupdf and zathura-pdf-poppler are installed simultaneously."
  warn "It is recommended to delete one of them."
fi

#########################
### Create Info.plist ###
#########################

info "Creating Info.plist"

ZATHURA_VER=$(
  zathura --version |
  head -n1 |
  cut -d ' '  -f2
)
ZATHURA_SUPPORTED_EXTS_XML=$(
  echo "${ZATHURA_SUPPORTED_EXTS:1}" |
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
    <string>AAA_Zathura</string>

    <key>CFBundleDisplayName</key>
    <string>AAA_Zathura</string>

    <key>CFBundleIdentifier</key>
    <string>com.pwmt.aaa_zathura</string>

    <key>CFBundleVersion</key>
    <string>${ZATHURA_VER}</string>

    <key>CFBundleGetInfoString</key>
    <string>zathura, a highly customizable and functional document viewer. Visit https://pwmt.org/projects/zathura for details.</string>

    <key>NSHumanReadableCopyright</key>
    <string>Copyright (c) 2009-$(date +%Y), pwmt.org</string>

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

######################
### Download image ###
######################

info "Downloading image"

curl -o "${ZATHURA_APP}/Contents/Resources/AppIcon.icns" "${ZATHURA_ICON_URL}"

###############
### Caveats ###
###############

info "Caveats"

cat <<EOF
Now you can run the app by double clicking on it.

Next steps:
To change the icon, follow the README.md in the repo.
You will notice that when Zathura opens, no file is showing.
To open a file, type \`:open <path to file>\` while within zathura,
or \`zathura example.pdf\` from the command line. Pressing <Tab>
will show recent files that the viewer has opened.
EOF
