"""Repository rule for downloading the Google Cloud CLI binary."""

_GCLOUD_VERSION = "554.0.0"
_GCLOUD_BASE_URL = "https://dl.google.com/dl/cloudsdk/channels/rapid/downloads"
_GCLOUD_VERSION_URL = "https://dl.google.com/dl/cloudsdk/channels/rapid/components-2.json"

# SHA256 hashes for the default version (554.0.0)
# To find hashes for other versions, download the archive and run:
#   curl -sL "https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-cli-VERSION-OS-ARCH.tar.gz" | shasum -a 256
_DEFAULT_HASHES = {
    "darwin_arm64": "8dd7846501c28ceae3a6090db7cd9ed49970321ef917815cad9672098afd74df",
    "darwin_amd64": "9e039870e2ad3b0a6d03075792b7b491dd8cbd850290ad24430db1837597f853",
    "linux_arm64": "d60500ab90cb5357f79c2c16b780a86e286dfe2d10686b52c918706f7e7c9e68",
    "linux_amd64": "054ff88650d8b12b2b075fb0f31ebed09a2af23958b72a7bafac44f26e0ec481",
}

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

    # Determine version and hash
    use_latest = repository_ctx.attr.use_latest
    version = repository_ctx.attr.version
    sha256 = repository_ctx.attr.sha256

    if use_latest:
        # Fetch latest version from Google's components API
        repository_ctx.report_progress("Fetching latest Google Cloud CLI version...")
        repository_ctx.download(
            url = _GCLOUD_VERSION_URL,
            output = "components.json",
        )
        components_data = json.decode(repository_ctx.read("components.json"))
        repository_ctx.delete("components.json")

        version = components_data.get("version", "")
        if not version:
            for component in components_data.get("components", []):
                if component.get("id") == "core":
                    version_info = component.get("version", {})
                    version = version_info.get("version_string") or version_info.get("build_number", "")
                    break

        if not version:
            fail("Could not determine Google Cloud CLI version from components-2.json")
        version = str(version)
        # No hash verification for latest (hashes not available via API)
        sha256 = ""
    elif not version:
        # Use default version with default hash
        version = _GCLOUD_VERSION
        if not sha256:
            sha256 = _DEFAULT_HASHES.get(platform, "")

    # Download the archive
    archive_name = _get_archive_name(version, os_name, arch)
    archive_url = "{}/{}".format(_GCLOUD_BASE_URL, archive_name)
    repository_ctx.report_progress("Downloading Google Cloud CLI {} for {}".format(version, platform))

    download_kwargs = {
        "url": archive_url,
        "output": "sdk",
        "stripPrefix": "google-cloud-sdk",
    }
    if sha256:
        download_kwargs["sha256"] = sha256
    repository_ctx.download_and_extract(**download_kwargs)

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
            doc = "Version to download. If empty, uses default version.",
        ),
        "platform": attr.string(
            doc = "Platform to download for (e.g., 'darwin_arm64'). If empty, detects current platform.",
        ),
        "sha256": attr.string(
            doc = "SHA256 hash of the archive for this platform.",
        ),
        "use_latest": attr.bool(
            default = False,
            doc = "If true, fetches the latest version instead of the default.",
        ),
    },
    doc = "Downloads the Google Cloud CLI for the specified platform.",
)

GCLOUD_DEFAULT_VERSION = _GCLOUD_VERSION
GCLOUD_DEFAULT_HASHES = _DEFAULT_HASHES
