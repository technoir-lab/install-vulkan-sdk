# helper functions for downloading/installing platform-specific Vulkan SDKs
# originally meant for use from GitHub Actions
#   see: https://github.com/technoir-lab/install-vulkan-sdk
# -- humbletim 2022.02

# example of running manually:
# $ . vulkan_prebuilt_helpers.sh
# $ VULKAN_SDK_VERSION=1.4.357.0 download_linux    # fetches vulkan_sdk.tar.gz
# $ VULKAN_SDK_DIR=$PWD/VULKAN_SDK VULKAN_SDK_COMPONENTS=com.lunarg.vulkan.core,com.lunarg.vulkan.volk install_linux   # installs

function _os_filename() {
  case $1 in
    mac) echo vulkan_sdk.zip ;;
    linux) echo vulkan_sdk.tar.gz ;;
    windows|warm) echo vulkan_sdk.exe ;;
    *) echo "unknown $1" >&2 ; exit 9 ;;
  esac
}

# validates that $2 is a known com.lunarg.vulkan.* component available on $1,
# returning 0 when valid, 1 when known but unavailable on $1 (skipped),
# or erroring (to stderr) with status 2 for unknown component ids
function _vulkan_component_valid() {
  local os=$1 component=$2
  case $component in
    com.lunarg.vulkan.core) return 0 ;;
    com.lunarg.vulkan.usr|com.lunarg.vulkan.ios|com.lunarg.vulkan.kosmic)
      [[ $os == mac ]] || return 1
      return 0
      ;;
    com.lunarg.vulkan.debug|com.lunarg.vulkan.x64|com.lunarg.vulkan.arm64)
      [[ $os == windows || $os == warm ]] || return 1
      return 0
      ;;
    com.lunarg.vulkan.sdl2|com.lunarg.vulkan.glm|com.lunarg.vulkan.volk|com.lunarg.vulkan.vma)
      [[ $os == mac || $os == windows || $os == warm ]] || return 1
      return 0
      ;;
    *)
      echo "error: unknown Vulkan SDK component '$component'; aborting" >&2
      return 2
      ;;
  esac
}

# normalizes VULKAN_SDK_COMPONENTS (default: com.lunarg.vulkan.core) into lowercase shell words
function _vulkan_requested_components() {
  echo ${VULKAN_SDK_COMPONENTS:-com.lunarg.vulkan.core} | tr ',' ' ' | tr '[:upper:]' '[:lower:]'
}

# reduces the requested com.lunarg.vulkan.* component ids to the ones available
# on the given os: known components that are unavailable on the os are silently
# skipped, while unknown component ids are an error (status 2)
function _vulkan_effective_components() {
  local os=$1 ; shift
  local -a effective=()
  local component rc
  for component in "$@"; do
    _vulkan_component_valid $os $component
    rc=$?
    case $rc in
      0) effective+=("$component") ;;
      1) : ;; # known component that is not available on this os; skip
      2) return 2 ;;
    esac
  done
  # com.lunarg.vulkan.core is always installed
  local -a out=(com.lunarg.vulkan.core)
  local component
  for component in "${effective[@]}"; do
    [[ $component == com.lunarg.vulkan.core ]] && continue
    out+=("$component")
  done
  echo "${out[*]}"
}

function download_vulkan_installer() {
  local os=$1
  local filename=$(_os_filename $os)
  local url=https://sdk.lunarg.com/sdk/download/$VULKAN_SDK_VERSION/$os/$filename?Human=true
  echo "_download_os_installer $os $filename $url" >&2
  if [[ -f $filename ]] ; then
    echo "using cached: $filename" >&2
  else
    curl --fail-with-body -s -L -o ${filename}.tmp $url || { echo "curl failed with error code: $?" >&2 ; curl -s -L --head $url >&2 ; exit 32 ; }
    test -f ${filename}.tmp
    mv -v ${filename}.tmp ${filename} 
  fi
  ls -lh $filename >&2
}

function unpack_vulkan_installer() {
  local os=$1
  local filename=$(_os_filename $os)
  test -f $filename
  install_${os}
}

function install_linux() {
  test -d $VULKAN_SDK_DIR && test -f vulkan_sdk.tar.gz
  echo "note: the Linux SDK is distributed as a single archive; the full SDK is installed regardless of components" >&2
  echo "extract just the SDK's prebuilt binaries ($VULKAN_SDK_VERSION/x86_64) from vulkan_sdk.tar.gz into $VULKAN_SDK_DIR" >&2
  tar -C "$VULKAN_SDK_DIR" --strip-components 2 -xf vulkan_sdk.tar.gz $VULKAN_SDK_VERSION/x86_64
  # SDK 1.4.350.0+ packages the Vulkan loader under lib/VulkanLoader/lib; also
  # expose it from lib/ so find_package(Vulkan) keeps working (CMake's FindVulkan
  # module still searches $VULKAN_SDK/lib for the loader).
  if [[ ! -e "$VULKAN_SDK_DIR/lib/libvulkan.so" && -f "$VULKAN_SDK_DIR/lib/VulkanLoader/lib/libvulkan.so" ]] ; then
    echo "note: symlinking Vulkan loader from lib/VulkanLoader/lib into lib/ for CMake compatibility" >&2
    ln -s VulkanLoader/lib/libvulkan.so "$VULKAN_SDK_DIR/lib/libvulkan.so"
    ln -s VulkanLoader/lib/libvulkan.so.1 "$VULKAN_SDK_DIR/lib/libvulkan.so.1"
  fi
}

# the SDK installer needs to be executed (7z only sees Bin/)
function _install_windows() {
  local os=$1
  test -d $VULKAN_SDK_DIR && test -f vulkan_sdk.exe
  echo "Executing Vulkan SDK installer headlessly to $VULKAN_SDK_DIR..." >&2
  local components
  components=$(_vulkan_effective_components $os $(_vulkan_requested_components)) || return $?
  ./vulkan_sdk.exe --root "$VULKAN_SDK_DIR" --accept-licenses --default-answer --confirm-command install $components
}
function install_windows() {
  local os=${1:-windows}
  test -d $VULKAN_SDK_DIR && test -f vulkan_sdk.exe
  _install_windows $os
  # Verify that the installation was successful by checking for a key directory
  if [ ! -d "$VULKAN_SDK_DIR/Include" ]; then
    echo "Installer did not create the expected Include directory." >&2
    # You can add more detailed logging here, like listing the contents of VULKAN_SDK_DIR
    ls -l "$VULKAN_SDK_DIR" >&2
    exit 1
  fi
}

function install_warm() {
  # Windows ARM installs the same way as Windows
  install_windows warm
}

function install_mac() {
  test -d $VULKAN_SDK_DIR && test -f vulkan_sdk.zip
  unzip vulkan_sdk.zip
  local InstallVulkan
  if [[ -d InstallVulkan-${VULKAN_SDK_VERSION}.app/Contents ]] ; then
    InstallVulkan=InstallVulkan-${VULKAN_SDK_VERSION}
  elif [[ -d vulkansdk-macOS-${VULKAN_SDK_VERSION}.app/Contents ]] ; then
    InstallVulkan=vulkansdk-macOS-${VULKAN_SDK_VERSION}
  elif [[ -d InstallVulkan.app/Contents ]] ; then
    InstallVulkan=InstallVulkan
  else
    echo "expecting ..vulkan.app/Contents folder (perhaps lunarg changed the archive layout again?): vulkan_sdk.zip" >&2
    echo "file vulkan_sdk.zip" >&2
    file vulkan_sdk.zip
    echo "unzip -t vulkan_sdk.zip" >&2
    unzip -t vulkan_sdk.zip
    exit 7
  fi
  echo "recognized zip layout 'vulkan_sdk.zip' ${InstallVulkan}.app/Contents" >&2
  local sdk_temp=${VULKAN_SDK_DIR}.tmp
  local components
  components=$(_vulkan_effective_components mac $(_vulkan_requested_components)) || return $?
  sudo ${InstallVulkan}.app/Contents/MacOS/${InstallVulkan} --root "$sdk_temp" --accept-licenses --default-answer --confirm-command install $components
  du -hs $sdk_temp
  test -d $sdk_temp/macOS || { echo "unrecognized dmg folder layout: $sdk_temp" ; ls -l $sdk_temp ; exit 10 ; }
  cp -a $sdk_temp/macOS $VULKAN_SDK_DIR/
  if [[ -d $sdk_temp/iOS ]] ; then
    cp -a $sdk_temp/iOS $VULKAN_SDK_DIR/
  else
    echo "warning: installer produced no iOS tree; skipping iOS SDK" >&2
  fi
  if [[ -d ${InstallVulkan}.app/Contents ]] ; then
    sudo rm -rf "$sdk_temp"
    rm -rf ${InstallVulkan}.app
  fi
}
