#!/usr/bin/env bash

###################
### Definitions ###
###################

ZATHURA_EXE_DEFAULT="/opt/homebrew/bin/zathura"
ZATHURA_APP="/Applications/Zathura.app"
# ZATHURA_ICON_URL="https://raw.githubusercontent.com/homebrew-zathura/homebrew-zathura/refs/heads/master/zathura-brosasaki.icns"
ZATHURA_ICON_URL="https://raw.githubusercontent.com/homebrew-zathura/homebrew-zathura/132bb38829938ed8dfdd24f46946aab93f4482e5/icon/zathura-brosasaki.icns"

# TODO: add extensions for CB plugin and finish list for MUPDF plugin.
# Those plugins support following MIME types (see $PLUGIN_NAME/plugin.c file):
# CB: application/{x-cbr,x-rar,x-cbz,zip,x-cb7,x-7z-compressed,x-cbt,x-tar}, inode/directory
# MUPDF: application/{oxps,epub+zip,x-fictionbook,x-mobipocket-ebook}, text/xml
ZATHURA_CB_EXTS=""
ZATHURA_DJVU_EXTS="djvu djv"
ZATHURA_MUPDF_EXTS="pdf"
ZATHURA_POPPLER_EXTS="pdf"
ZATHRUA_PS_EXTS="ps eps"

########################
### Helper functions ###
########################

COLOR_RESET="\033[0m"
COLOR_RED="\033[31m"
COLOR_GREEN="\033[32m"
COLOR_YELLOW="\033[33m"
COLOR_GRAY="\033[90m"

# @param1 level name
# @param2 level color
# @param3 message
__log() {
  echo -e "$2[$1] $3${COLOR_RESET}" 1>&2
}

debug() {
  __log "DEBUG" "${COLOR_GRAY}" "$@"
}

info() {
  __log "INFO" "" "$@"
}

warn() {
  __log "WARNING" "${COLOR_YELLOW}" "$@"
}

error() {
  __log "ERROR" "${COLOR_RED}" "$@"
}

#######################
### Find executable ###
#######################

debug "Finding executable..."

ZATHURA_EXE_FROM_PATH="$(command -v zathura)"

if [[ -f "${ZATHURA_EXE_DEFAULT}" ]]
then
  info "zathura executable found at ${ZATHURA_EXE_DEFAULT}"
  ZATHURA_EXE="${ZATHURA_EXE_DEFAULT}"
elif [[ -f "${ZATHURA_EXE_FROM_PATH}" ]]
then
  warn "zathura executable not found at default location (${ZATHURA_EXE_DEFAULT});"
  warn "use ${ZATHURA_EXE_FROM_PATH} from \$PATH instead"
  ZATHURA_EXE="${ZATHURA_EXE_FROM_PATH}"
else
  error "zathura executable not found neither at ${ZATHURA_EXE_DEFAULT}, nor in \$PATH"
  exit 1
fi

##############################
### Find installed plugins ###
##############################

debug "Finding installed plugins..."

# @param1 plugin name without zathura- prefix
find_plugin () {
  plugin="$1"

  plugin_prefix=$(brew --prefix "zathura-${plugin}" 2>/dev/null)
  plugin_path="${plugin_prefix}/lib${plugin}.dylib"

  if [[ -f "${plugin_path}" ]]
  then
    info "zathura-${plugin} plugin found"
    echo "${plugin_path}"
  fi
}

CB_PLUGIN=$(find_plugin cb)
DJVU_PLUGIN=$(find_plugin djvu)
MUPDF_PLUGIN=$(find_plugin pdf-mupdf)
POPPLER_PLUGIN=$(find_plugin pdf-poppler)
PS_PLUGIN=$(find_plugin ps)

if [[ -z "${CB_PLUGIN}${DJVU_PLUGIN}${MUPDF_PLUGIN}${POPPLER_PLUGIN}${PS_PLUGIN}" ]]
then
  error "No plugins have been found. Please install at least one plugin and try again."
  error "List of official plugins: zathura-{cb,djvu,pdf-mupdf,pdf-poppler,ps}."
  exit 1
fi

if [[ -n "${MUPDF_PLUGIN}" && -n "${POPPLER_PLUGIN}" ]]
then
  warn "zathura-pdf-mupdf and zathura-pdf-poppler are installed simultaneously."
  warn "It is recommended to delete one of them."
fi

############################
### Create app structure ###
############################

debug "Creating app structure..."

mkdir -p "${ZATHURA_APP}/Contents/MacOS" "${ZATHURA_APP}/Contents/Resources/plugins"

#######################
### Copy executable ###
#######################

debug "Copying executable..."

cp "${ZATHURA_EXE}" "${ZATHURA_APP}/Contents/MacOS/zathura"

################################################
### Copy plugins and form list of extensions ###
################################################

debug "Copying plugins and forming list of extensions..."

# Note: This variable will have an extra space symbol at the beginning.
ZATHURA_SUPPORTED_EXTS=""

# @param1 plugin's .dylib path
# @param2 plugin supported extensions
add_plugin () {
  path="$1"
  exts="$2"

  if [[ -f "${path}" ]]
  then
    ln -s "${path}" "${ZATHURA_APP}/Contents/Resources/plugins"
    ZATHURA_SUPPORTED_EXTS="${ZATHURA_SUPPORTED_EXTS} ${exts}"
  fi
}

add_plugin "${CB_PLUGIN}" "${ZATHURA_CB_EXTS}"
add_plugin "${DJVU_PLUGIN}" "${ZATHURA_DJVU_EXTS}"
add_plugin "${MUPDF_PLUGIN}" "${ZATHURA_MUPDF_EXTS}"
add_plugin "${POPPLER_PLUGIN}" "${ZATHURA_POPPLER_EXTS}"
add_plugin "${PS_PLUGIN}" "${ZATHURA_PS_EXTS}"

#########################
### Create Info.plist ###
#########################

debug "Creating Info.plist..."

# SC2312 (info): Consider invoking this command separately to avoid masking its return value (or use '|| true' to ignore).
# shellcheck disable=SC2312
ZATHURA_VER=$(
  ${ZATHURA_EXE} --version |
    head -n1 |
    cut -d ' '  -f2
)
# shellcheck disable=SC2312
ZATHURA_SUPPORTED_EXTS_XML=$(
  echo "${ZATHURA_SUPPORTED_EXTS:1}" |
    xargs -n1 -I% echo "        <string>%</string>"
)
CURRENT_YEAR=$(date +%Y)
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
  <string>${ZATHURA_VER}</string>

  <key>CFBundleGetInfoString</key>
  <string>zathura, a highly customizable and functional document viewer. Visit https://pwmt.org/projects/zathura for details.</string>

  <key>NSHumanReadableCopyright</key>
  <string>Copyright (c) 2009-${CURRENT_YEAR}, pwmt.org</string>

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

debug "${info_plist}" >"${ZATHURA_APP}/Contents/Info.plist"

######################
### Download image ###
######################

debug "Downloading image..."

curl -o "${ZATHURA_APP}/Contents/Resources/AppIcon.icns" "${ZATHURA_ICON_URL}"

###############
### Caveats ###
###############

debug "Caveats..."

cat <<EOF
Now you can run the app by double clicking on it.

Next steps:
To change the icon, follow the README.md in the repo.
You will notice that when Zathura opens, no file is showing.
To open a file, type \`:open <path to file>\` while within zathura,
or \`zathura example.pdf\` from the command line. Pressing <Tab>
will show recent files that the viewer has opened.
EOF
