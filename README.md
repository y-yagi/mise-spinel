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
| `SPINEL_MAKE_OPTS` | Extra arguments passed to `make` / `make install` (e.g. `CC=clang`) |
| `SPINEL_KEEP_BUILD=1` | Keep the build directory (`<install path>.build`) instead of removing it |
| `GITHUB_TOKEN` / `GH_TOKEN` | Used when calling the GitHub API (listing versions, resolving the source revision), to avoid rate limits |

## License

MIT
