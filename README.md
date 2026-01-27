# tools_gcloud

Bazel toolchain for [Google Cloud CLI (gcloud)](https://cloud.google.com/sdk/gcloud) - Google Cloud's command-line interface.

## Setup

Add the dependency to your `MODULE.bazel` using `git_override`:

```starlark
bazel_dep(name = "tools_gcloud", version = "0.1.0")
git_override(
    module_name = "tools_gcloud",
    remote = "https://github.com/buildbuddy-rules/tools_gcloud.git",
    commit = "a7d3dc09f9360ed92cc8c9893035a57719d002e8",
)
```

The toolchain is automatically registered and downloads the latest gcloud CLI.

### Pinning a gcloud version

To pin a specific gcloud CLI version:

```starlark
gcloud = use_extension("@tools_gcloud//gcloud:gcloud.bzl", "gcloud")
gcloud.download(version = "503.0.0")
```

## Usage

### In genrule

Use the toolchain in a genrule via `toolchains` and make variable expansion:

```starlark
load("@tools_gcloud//gcloud:defs.bzl", "GCLOUD_TOOLCHAIN_TYPE")

genrule(
    name = "my_genrule",
    outs = ["project_info.json"],
    cmd = "$(GCLOUD_BINARY) projects describe my-project --format=json > $@",
    toolchains = [GCLOUD_TOOLCHAIN_TYPE],
)
```

The `$(GCLOUD_BINARY)` make variable expands to the path of the gcloud binary.

### In custom rules

Use the toolchain in your rule implementation:

```starlark
load("@tools_gcloud//gcloud:defs.bzl", "GCLOUD_TOOLCHAIN_TYPE")

def _my_rule_impl(ctx):
    toolchain = ctx.toolchains[GCLOUD_TOOLCHAIN_TYPE]
    gcloud_binary = toolchain.gcloud_info.binary

    out = ctx.actions.declare_file(ctx.label.name + ".json")
    ctx.actions.run_shell(
        outputs = [out],
        tools = [gcloud_binary],
        command = "{gcloud} projects describe {project} --format=json > {out}".format(
            gcloud = gcloud_binary.path,
            project = ctx.attr.project,
            out = out.path,
        ),
        use_default_shell_env = True,
    )
    return [DefaultInfo(files = depset([out]))]

my_rule = rule(
    implementation = _my_rule_impl,
    attrs = {
        "project": attr.string(mandatory = True),
    },
    toolchains = [GCLOUD_TOOLCHAIN_TYPE],
)
```

### Public API

From `@tools_gcloud//gcloud:defs.bzl`:

| Symbol | Description |
|--------|-------------|
| `GCLOUD_TOOLCHAIN_TYPE` | Toolchain type string for use in `toolchains` attribute |
| `GcloudInfo` | Provider with `binary` field containing the gcloud executable |
| `gcloud_toolchain` | Rule for defining custom toolchain implementations |

## Supported platforms

- `darwin_arm64` (macOS Apple Silicon)
- `darwin_amd64` (macOS Intel)
- `linux_arm64`
- `linux_amd64`

## Requirements

- Bazel 7.0+ with bzlmod enabled
- Google Cloud authentication configured for gcloud to function
