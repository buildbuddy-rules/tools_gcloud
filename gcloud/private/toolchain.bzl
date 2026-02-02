"""Google Cloud CLI toolchain definitions."""

GcloudInfo = provider(
    doc = "Information about the Google Cloud CLI.",
    fields = {
        "binary": "The gcloud executable file.",
    },
)

def _gcloud_toolchain_impl(ctx):
    """Implementation of the gcloud toolchain."""
    default_info = DefaultInfo(files = depset([ctx.file.gcloud]))
    toolchain_info = platform_common.ToolchainInfo(
        gcloud_info = GcloudInfo(
            binary = ctx.file.gcloud,
        ),
    )
    template_variable_info = platform_common.TemplateVariableInfo({
        "GCLOUD_BINARY": ctx.file.gcloud.path,
    })
    return [default_info, toolchain_info, template_variable_info]

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
GCLOUD_RUNTIME_TOOLCHAIN_TYPE = "@tools_gcloud//gcloud:runtime_toolchain_type"
