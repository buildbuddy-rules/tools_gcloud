"""Google Cloud CLI toolchain definitions."""

GcloudInfo = provider(
    doc = "Information about the Google Cloud CLI.",
    fields = {
        "binary": "The gcloud executable file.",
    },
)

def _gcloud_toolchain_impl(ctx):
    """Implementation of the gcloud toolchain."""
    toolchain_info = platform_common.ToolchainInfo(
        gcloud_info = GcloudInfo(
            binary = ctx.file.gcloud,
        ),
    )
    return [toolchain_info]

gcloud_toolchain = rule(
    implementation = _gcloud_toolchain_impl,
    attrs = {
        "gcloud": attr.label(
            doc = "The gcloud CLI binary.",
            allow_single_file = True,
            mandatory = True,
        ),
    },
    doc = "Defines a Google Cloud CLI toolchain.",
)

GCLOUD_TOOLCHAIN_TYPE = "@tools_gcloud//gcloud:toolchain_type"
