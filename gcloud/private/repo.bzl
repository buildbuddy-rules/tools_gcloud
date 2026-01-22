"""Repository rule for downloading the Google Cloud CLI binary."""

_GCLOUD_BASE_URL = "https://dl.google.com/dl/cloudsdk/channels/rapid/downloads"
_GCLOUD_VERSION_URL = "https://dl.google.com/dl/cloudsdk/channels/rapid/components-2.json"

# Platform mapping: bazel platform -> (os, arch for gcloud SDK naming)
_PLATFORMS = {
    "darwin_arm64": ("darwin", "arm"),
    "darwin_amd64": ("darwin", "x86_64"),
    "linux_arm64": ("linux", "arm"),
    "linux_amd64": ("linux", "x86_64"),
}

def _get_platform(repository_ctx):
    """Determine the current platform."""
    os_name = repository_ctx.os.name.lower()
    arch = repository_ctx.os.arch

    if "mac" in os_name or "darwin" in os_name:
        os_key = "darwin"
    elif "linux" in os_name:
        os_key = "linux"
    else:
        fail("Unsupported operating system: {}".format(os_name))

    if arch == "aarch64" or arch == "arm64":
        arch_key = "arm64"
    elif arch == "x86_64" or arch == "amd64":
        arch_key = "amd64"
    else:
        fail("Unsupported architecture: {}".format(arch))

    return "{}_{}".format(os_key, arch_key)

def _get_archive_name(version, os_name, arch):
    """Generate the archive filename for the given version and platform."""
    # Google Cloud SDK naming convention:
    # google-cloud-cli-VERSION-OS-ARCH.tar.gz
    # Examples:
    #   google-cloud-cli-503.0.0-darwin-arm.tar.gz
    #   google-cloud-cli-503.0.0-darwin-x86_64.tar.gz
    #   google-cloud-cli-503.0.0-linux-arm.tar.gz
    #   google-cloud-cli-503.0.0-linux-x86_64.tar.gz
    return "google-cloud-cli-{}-{}-{}.tar.gz".format(version, os_name, arch)

def _gcloud_toolchains_impl(repository_ctx):
    """Download the gcloud CLI binary for the specified or current platform."""
    # Use specified platform or detect current
    platform = repository_ctx.attr.platform
    if not platform:
        platform = _get_platform(repository_ctx)

    if platform not in _PLATFORMS:
        fail("Unsupported platform: {}".format(platform))

    os_name, arch = _PLATFORMS[platform]

    # Get version - use provided version or fetch latest
    version = repository_ctx.attr.version
    if not version:
        repository_ctx.report_progress("Fetching latest Google Cloud CLI version...")
        repository_ctx.download(
            url = _GCLOUD_VERSION_URL,
            output = "components.json",
        )
        components_content = repository_ctx.read("components.json")

        # Parse the version from the JSON response
        # The version is in the format: "version": "VERSION"
        # We look for the SDK version which is typically at the top level
        version_start = components_content.find('"version"')
        if version_start == -1:
            fail("Could not find version in components.json")

        # Find the version value
        colon_pos = components_content.find(":", version_start)
        quote_start = components_content.find('"', colon_pos + 1)
        quote_end = components_content.find('"', quote_start + 1)
        version = components_content[quote_start + 1:quote_end]

        repository_ctx.delete("components.json")

    # Download the archive
    archive_name = _get_archive_name(version, os_name, arch)
    archive_url = "{}/{}".format(_GCLOUD_BASE_URL, archive_name)
    repository_ctx.report_progress("Downloading Google Cloud CLI {} for {}".format(version, platform))

    repository_ctx.download_and_extract(
        url = archive_url,
        output = "sdk",
        stripPrefix = "google-cloud-sdk",
    )

    # The gcloud binary is at sdk/bin/gcloud
    # Create a symlink at the repository root for easier access
    repository_ctx.symlink("sdk/bin/gcloud", "gcloud")

    # Write version file for reference
    repository_ctx.file("VERSION", version)

    # Create BUILD file
    repository_ctx.file(
        "BUILD.bazel",
        content = '''
package(default_visibility = ["//visibility:public"])

exports_files(["gcloud"])

filegroup(
    name = "sdk",
    srcs = glob(["sdk/**"]),
)
''',
    )

gcloud_toolchains = repository_rule(
    implementation = _gcloud_toolchains_impl,
    attrs = {
        "version": attr.string(
            doc = "Version to download. If empty, downloads the latest version.",
        ),
        "platform": attr.string(
            doc = "Platform to download for (e.g., 'darwin_arm64'). If empty, detects current platform.",
        ),
    },
    doc = "Downloads the Google Cloud CLI for the specified platform.",
)
