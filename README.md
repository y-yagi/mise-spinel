# mise-spinel

A [mise](https://mise.jdx.dev/) plugin (vfox-style / Lua) for [Spinel](https://github.com/matz/spinel), the Ruby AOT compiler.

It downloads the release source tarball (`spinel-<version>.tar.xz`), builds it with `make`, and installs it with `make install`.

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

The `spinel`, `spin`, and `spinel-*` commands are added to `PATH`.

## Requirements

- Linux or macOS (Windows is not supported)
- A C compiler (`cc`; override with the `CC` environment variable)
- `make`

Ruby is not required. The tarball bundles prism and rbs, so the build needs no network access.

## Environment variables

| Variable | Description |
| --- | --- |
| `SPINEL_MAKE_OPTS` | Extra arguments passed to `make` / `make install` (e.g. `CC=clang`) |
| `SPINEL_KEEP_BUILD=1` | Keep the build directory (`<install path>.build`) instead of removing it |
| `GITHUB_TOKEN` / `GH_TOKEN` | Used when listing versions, to avoid GitHub API rate limits |

## License

MIT
