# tools_gcloud

Bazel toolchain for [Google Cloud CLI (gcloud)](https://cloud.google.com/sdk/gcloud) - Google Cloud's command-line interface.

## Setup

### Using BuildBuddy Registry (Recommended)

Add the BuildBuddy registry to your `.bazelrc`:

```
common --registry=https://registry.buildbuddy.io/
```

Then add the dependency to your `MODULE.bazel`:

```starlark
bazel_dep(name = "tools_gcloud", version = "main-github.buildbuddy-rules")
```

To pin to a specific tag or commit, replace `main` with the tag or commit SHA:

```starlark
# Pin to a tag
bazel_dep(name = "tools_gcloud", version = "v0.1.0-github.buildbuddy-rules")

# Pin to a specific commit
bazel_dep(name = "tools_gcloud", version = "87235fe-github.buildbuddy-rules")
```

### Using git_override

Alternatively, use `git_override` directly in your `MODULE.bazel`:

```starlark
bazel_dep(name = "tools_gcloud", version = "0.1.0")
git_override(
    module_name = "tools_gcloud",
    remote = "https://github.com/buildbuddy-rules/tools_gcloud.git",
    commit = "<commit_sha>",  # Replace with the desired commit
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
