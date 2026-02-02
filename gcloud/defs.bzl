"""Public API for tools_gcloud."""

load(
    "//gcloud/private:toolchain.bzl",
    _GCLOUD_RUNTIME_TOOLCHAIN_TYPE = "GCLOUD_RUNTIME_TOOLCHAIN_TYPE",
    _GCLOUD_TOOLCHAIN_TYPE = "GCLOUD_TOOLCHAIN_TYPE",
    _GcloudInfo = "GcloudInfo",
    _gcloud_toolchain = "gcloud_toolchain",
)

# Toolchain
gcloud_toolchain = _gcloud_toolchain
GcloudInfo = _GcloudInfo
GCLOUD_TOOLCHAIN_TYPE = _GCLOUD_TOOLCHAIN_TYPE
GCLOUD_RUNTIME_TOOLCHAIN_TYPE = _GCLOUD_RUNTIME_TOOLCHAIN_TYPE
