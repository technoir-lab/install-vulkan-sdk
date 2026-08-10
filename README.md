# install-vulkan-sdk

This action automatically downloads and installs the Vulkan SDK development environment.

### Usage

```yaml
  - name: Install Vulkan SDK
    uses: technoir-lab/install-vulkan-sdk@v1.3.1
    with:
      version: 1.4.357.0
      components: com.lunarg.vulkan.volk # Defaults to com.lunarg.vulkan.core
      cache: true
```

Parameters:
- *version* (optional; default=latest): `N.N.N.N` style Vulkan SDK release number (or `latest` to use most recent official release).
- *components* (optional; default=`com.lunarg.vulkan.core`): space-separated list of component ids to install, e.g. `com.lunarg.vulkan.core com.lunarg.vulkan.vma`; `com.lunarg.vulkan.core` is always installed. On macOS and Windows only the listed components are installed (by default: core only). Component ids that are not available on the runner's OS are skipped. The Linux SDK is a single archive, so it always installs the full SDK.
- *cache* (optional; default=false): boolean indicating whether to cache the downloaded installer file between builds. The cache key includes the resolved component list, so different component sets use separate cache entries.
- *quiet* (optional; default=false): when using `latest` an Annotation is added to builds with actual SDK number; set `quiet: true` to silence.

### SDK Revisions

Know working SDK version for windows/mac/linux:
- 1.4.357.0

##### Available SDK versions:
- [windows.json](https://vulkan.lunarg.com/sdk/versions/windows.json) / [warm.json](https://vulkan.lunarg.com/sdk/versions/warm.json)
- [linux.json](https://vulkan.lunarg.com/sdk/versions/linux.json)
- [mac.json](https://vulkan.lunarg.com/sdk/versions/mac.json)
- See also https://vulkan.lunarg.com/sdk/home

### SDK Components

| ID                       | OS            | Description                                                                                                      |
|--------------------------|---------------|------------------------------------------------------------------------------------------------------------------|
| com.lunarg.vulkan.core   | All           | The Vulkan SDK core (always installed): Vulkan Loader, layers, VkConfig, and essential shader development tools. |
| com.lunarg.vulkan.ios    | macOS         | Development libraries for iOS.                                                                                   |
| com.lunarg.vulkan.kosmic | macOS         | KosmicKrisp (Vulkan on Metal) technical preview.                                                                 |
| com.lunarg.vulkan.usr    | macOS         | System-wide installation of ICDs, layers, and SDK tools to /usr/local.                                           |
| com.lunarg.vulkan.vma    | macOS/Windows | Vulkan Memory Allocator header.                                                                                  |
| com.lunarg.vulkan.volk   | macOS/Windows | Volk header, source, and library.                                                                                |
| com.lunarg.vulkan.glm    | macOS/Windows | GLM headers.                                                                                                     |
| com.lunarg.vulkan.sdl2   | macOS/Windows | SDL2 and SDL3 libraries and headers.                                                                             |
| com.lunarg.vulkan.x64    | Windows       | X64 binaries for cross compiling.                                                                                |
| com.lunarg.vulkan.arm64  | Windows       | ARM64 binaries for cross compiling.                                                                              |
| com.lunarg.vulkan.debug  | Windows       | Shader toolchain debug symbols (64-bit).                                                                         |

### Environment

Exported variables:
- `VULKAN_SDK` (standard variable used by cmake and other build tools; on macOS
  this points at the installed `macOS` subdirectory)
- `VULKAN_SDK_VERSION`
- `VULKAN_SDK_PLATFORM`
- `PATH` is extended to include `VULKAN_SDK/bin` (so SDK tools like `glslangValidator` can be used directly)
- `C_INCLUDE_PATH` (set to `$VULKAN_SDK/include`, or `$VULKAN_SDK/Include` on
  Windows) so C/C++ compilers find the SDK headers without extra `-I` flags
- `LIBRARY_PATH` (set to `$VULKAN_SDK/lib`, or `$VULKAN_SDK/Lib` on Windows) so
  linkers find the SDK libraries without extra `-L` flags
- `LD_LIBRARY_PATH` (Linux; set to `$VULKAN_SDK/lib`) so dynamically linked SDK
  libraries (e.g. the Vulkan loader) are found at run time without extra rpath flags
- `DYLD_LIBRARY_PATH` (macOS; set to `$VULKAN_SDK/lib`) so dynamically linked
  SDK libraries (e.g. the Vulkan loader) are found at run time without extra rpath flags

Any pre-existing `C_INCLUDE_PATH`/`LIBRARY_PATH`/`LD_LIBRARY_PATH`/`DYLD_LIBRARY_PATH`
values are preserved (the SDK directories are prepended).

### Caveats

Please be aware that Vulkan SDKs can use a lot of disk space; up to 2.4GB depending on the OS and components installed.

## References
- [Vulkan SDK](https://www.lunarg.com/products/vulkan-sdk/)
- [Vulkan SDK web services API](https://vulkan.lunarg.com/content/view/latest-sdk-version-api)
