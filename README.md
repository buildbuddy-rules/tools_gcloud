# tools_gcloud

Bazel toolchain for [Google Cloud CLI (gcloud)](https://cloud.google.com/sdk/gcloud) - Google Cloud's command-line interface.

## Setup

Add the dependency to your `MODULE.bazel` using `git_override`:

```starlark
bazel_dep(name = "tools_gcloud", version = "0.1.0")
git_override(
    module_name = "tools_gcloud",
    remote = "https://github.com/buildbuddy-rules/tools_gcloud.git",
    commit = "9fc9ce9821a03d6af4e48e9f9ddfb8bd3e9ac5ee",
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

### In custom rules

Use the toolchain in your rule implementation:

```starlark
load("@tools_gcloud//gcloud:defs.bzl", "GCLOUD_TOOLCHAIN_TYPE")

def _my_rule_impl(ctx):
    toolchain = ctx.toolchains[GCLOUD_TOOLCHAIN_TYPE]
    gcloud_binary = toolchain.gcloud_info.binary

    # Use gcloud_binary in your actions
    ctx.actions.run(
        executable = gcloud_binary,
        arguments = ["--help"],
        # ...
    )

my_rule = rule(
    implementation = _my_rule_impl,
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
