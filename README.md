# tools_gcloud

Bazel toolchain for [Google Cloud CLI (gcloud)](https://cloud.google.com/sdk/gcloud) - Google Cloud's command-line interface.

## Setup

Add the dependency to your `MODULE.bazel` using `git_override`:

```starlark
bazel_dep(name = "tools_gcloud", version = "0.1.0")
git_override(
    module_name = "tools_gcloud",
    remote = "https://github.com/buildbuddy-rules/tools_gcloud.git",
    commit = "597944311adc76730b64f781b68d1a90a039dad8",
)
```

The toolchain is automatically registered. By default, it downloads version `554.0.0` with SHA256 verification for reproducible builds.

### Pinning a gcloud version

To pin a specific gcloud CLI version:

```starlark
gcloud = use_extension("@tools_gcloud//gcloud:gcloud.bzl", "gcloud")
gcloud.download(version = "550.0.0")
```

### Using the latest version

To always fetch the latest version:

```starlark
gcloud = use_extension("@tools_gcloud//gcloud:gcloud.bzl", "gcloud")
gcloud.download(use_latest = True)
```

Note: When using `use_latest`, SHA256 verification is not available as hashes cannot be fetched automatically from Google's API.

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

### In tests

For tests that need to run the gcloud binary at runtime, use the runtime toolchain type. This ensures the binary matches the target platform where the test executes:

```starlark
load("@tools_gcloud//gcloud:defs.bzl", "GCLOUD_RUNTIME_TOOLCHAIN_TYPE")

def _gcloud_test_impl(ctx):
    toolchain = ctx.toolchains[GCLOUD_RUNTIME_TOOLCHAIN_TYPE]
    gcloud_binary = toolchain.gcloud_info.binary

    test_script = ctx.actions.declare_file(ctx.label.name + ".sh")
    ctx.actions.write(
        output = test_script,
        content = """#!/bin/bash
{gcloud} --version
""".format(gcloud = gcloud_binary.short_path),
        is_executable = True,
    )
    return [DefaultInfo(
        executable = test_script,
        runfiles = ctx.runfiles(files = [gcloud_binary]),
    )]

gcloud_test = rule(
    implementation = _gcloud_test_impl,
    test = True,
    toolchains = [GCLOUD_RUNTIME_TOOLCHAIN_TYPE],
)
```

### Toolchain types

There are two toolchain types depending on your use case:

- **`GCLOUD_TOOLCHAIN_TYPE`** - Use for build-time actions (genrules, custom rules). Selected based on the execution platform. Use this when gcloud's output isn't platform-specific.

- **`GCLOUD_RUNTIME_TOOLCHAIN_TYPE`** - Use for tests or run targets where the gcloud binary executes on the target platform.

### Public API

From `@tools_gcloud//gcloud:defs.bzl`:

| Symbol | Description |
|--------|-------------|
| `GCLOUD_TOOLCHAIN_TYPE` | Toolchain type for build actions (exec platform only) |
| `GCLOUD_RUNTIME_TOOLCHAIN_TYPE` | Toolchain type for test/run (target platform) |
| `GcloudInfo` | Provider with `binary` field containing the gcloud executable |
| `gcloud_toolchain` | Rule for defining custom toolchain implementations |

## Supported platforms

- `darwin_arm64` (macOS Apple Silicon)
- `darwin_amd64` (macOS Intel)
- `linux_arm64`
- `linux_amd64`

## Authentication

gcloud requires authentication to access Google Cloud resources. Since Bazel actions run in a sandbox, you cannot rely on local gcloud configuration. Instead, pass an access token via environment variable.

### Usage

Pass the token on the command line using your existing gcloud authentication:

```bash
bazel build //... --action_env=CLOUDSDK_AUTH_ACCESS_TOKEN=$(gcloud auth print-access-token)
```

The token is automatically picked up by gcloud commands in your actions—no additional setup needed in your rules.

Access tokens expire after 1 hour by default. For longer builds, you can extend the token lifetime (up to 12 hours):

```bash
bazel build //... --action_env=CLOUDSDK_AUTH_ACCESS_TOKEN=$(gcloud auth print-access-token --lifetime=43200)
```

## Requirements

- Bazel 7.0+ with bzlmod enabled
