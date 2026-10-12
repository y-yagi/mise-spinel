# mise-spinel

A [mise](https://mise.jdx.dev/) plugin (vfox-style / Lua) for [Spinel](https://github.com/matz/spinel), the Ruby AOT compiler.

It downloads the release source tarball (`spinel-<version>.tar.xz`), builds it with `make`, and installs it with `make install`.
It can also build the latest source from the `master` branch (or any branch / commit).

## Usage

```sh
mise plugin install spinel https://github.com/y-yagi/mise-spinel

# List available versions
mise ls-remote spinel

# Install and use
mise use spinel@latest
mise use spinel@2026.09.12

spinel --version
spinel -e 'puts 42' && ./a
```

### Building from source

Any version that is not a release tag is treated as a git ref of [matz/spinel](https://github.com/matz/spinel), and built from its source archive.

```sh
# Latest source on the master branch
mise use spinel@master

# A specific commit
mise use spinel@52d3521
```

mise does not update an installed `master` by itself. To rebuild it with the latest source, reinstall it:

```sh
mise install -f spinel@master
```

The `spinel`, `spin`, and `spinel-*` commands are added to `PATH`.

## Requirements

- Linux or macOS (Windows is not supported)
- A C compiler (`cc`; override with the `CC` environment variable)
- `make`

Ruby is not required. The release tarball bundles prism and rbs, so the build needs no network access.
When building from source, prism and rbs are fetched from rubygems.org with `make deps`, which requires `curl`.

## Environment variables

| Variable | Description |
| --- | --- |
| `SPINEL_MAKE_OPTS` | Extra make variables passed to every `make` invocation (e.g. `CC=clang`). Not for make targets: it is also passed to `make deps` and `make install` |
| `SPINEL_KEEP_BUILD=1` | Keep the build directory (`<install path>.build`) instead of removing it |
| `WASI_SDK` / `WASI_SDK_PATH` | The [wasi-sdk](https://github.com/WebAssembly/wasi-sdk) directory (default: `/opt/wasi-sdk`). When it is found at install time, the wasm32-wasi runtime is built too (see [WebAssembly](#webassembly-wasm32-wasi)) |
| `SPINEL_WASM_RT` | Whether to build the wasm32-wasi runtime: unset builds it when the wasi-sdk is found and the Spinel version supports it, `0` never builds it, `1` requires it (the install fails if it cannot be built) |
| `GITHUB_TOKEN` / `GH_TOKEN` | Used when calling the GitHub API (listing versions, resolving the source revision), to avoid rate limits |

## WebAssembly (wasm32-wasi)

`spinel --target=wasm32-wasi` needs a runtime built with the [wasi-sdk](https://github.com/WebAssembly/wasi-sdk), which Spinel does not build by default.
This plugin builds it when the wasi-sdk is found at install time (`WASI_SDK`, then `WASI_SDK_PATH`, else `/opt/wasi-sdk`). Set `SPINEL_WASM_RT=1` to make the install fail if it cannot be built, or `SPINEL_WASM_RT=0` to skip it.
Set `WASI_SDK` as an environment variable, not in `SPINEL_MAKE_OPTS`.

The runtime needs a Spinel version with the `make wasm-rt` target. The 2026.09.12 release and earlier don't have it, so for them the runtime is skipped (or the install fails with `SPINEL_WASM_RT=1`). Until a release has it, install Spinel from source (`master` or a commit, see [Building from source](#building-from-source)).

Spinel looks up the wasi-sdk the same way when it compiles to wasm. So unless the wasi-sdk is at `/opt/wasi-sdk`, `WASI_SDK` or `WASI_SDK_PATH` must also be set when running `spinel --target=wasm32-wasi`, not only at install time.

With mise, the wasi-sdk can be installed and `WASI_SDK` set in `mise.toml`. `depends` installs the wasi-sdk before Spinel, so Spinel's install finds it, and `[env]` sets `WASI_SDK` for both the install and `spinel`:

```toml
[tools]
"github:WebAssembly/wasi-sdk" = { version = "wasi-sdk-34", bin_path = "no-bin" }
spinel = { version = "master", depends = ["github:WebAssembly/wasi-sdk"] }

[env]
WASI_SDK = { value = "{{ tools['github:WebAssembly/wasi-sdk'].path | default(value='') }}", tools = true }
```

If Spinel was installed before the wasi-sdk was available, reinstall it (e.g. `mise install -f spinel@<version>`) to build the runtime.

## License

MIT
