# install-vulkan-sdk

This action automatically downloads and installs the Vulkan SDK development environment.

### Usage

```yaml
  - name: Install Vulkan SDK
    uses: technoir-lab/install-vulkan-sdk@v1.2.4
    with:
      version: 1.4.357.0
      components: com.lunarg.vulkan.vma com.lunarg.vulkan.volk com.lunarg.vulkan.kosmic com.lunarg.vulkan.ios com.lunarg.vulkan.glm com.lunarg.vulkan.sdl2
      cache: true
```

Parameters:
- *version* (optional; default=latest): `N.N.N.N` style Vulkan SDK release number (or `latest` to use most recent official release).
- *components* (optional; default=`com.lunarg.vulkan.core`): space-separated list of LunarG installer component ids to install, e.g. `com.lunarg.vulkan.core com.lunarg.vulkan.vma`; `com.lunarg.vulkan.core` is always installed. On macOS and Windows only the listed components are installed (by default: core only). Component ids that are not available on the runner's OS are skipped. The Linux SDK is a single archive, so it always installs the full SDK.
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

### Environment

Exported variables:
- `VULKAN_SDK` (standard variable used by cmake and other build tools; on macOS
  this points at the installed `macOS` subdirectory)
- `VULKAN_SDK_VERSION`
- `VULKAN_SDK_PLATFORM`
- `PATH` is extended to include `VULKAN_SDK/bin` (so SDK tools like `glslangValidator` can be used directly)

### Caveats

Please be aware that Vulkan SDKs can use a lot of disk space; windows/linux approximately ~0.75GB; macOS approximately ~1.75GB.

## References
- [Vulkan SDK](https://www.lunarg.com/products/vulkan-sdk/)
- [Vulkan SDK web services API](https://vulkan.lunarg.com/content/view/latest-sdk-version-api)
