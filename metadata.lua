PLUGIN = {}

PLUGIN.name = "spinel"
PLUGIN.version = "0.1.0"
PLUGIN.homepage = "https://github.com/y-yagi/mise-spinel"
PLUGIN.license = "MIT"
PLUGIN.description = "Spinel - Ruby AOT compiler (https://github.com/matz/spinel)"
PLUGIN.minRuntimeVersion = "0.3.0"
PLUGIN.notes = {
    "Builds Spinel from the release source tarball. Requires: C compiler (cc or $CC) and make.",
    "Environment variables: SPINEL_MAKE_OPTS (extra make args), SPINEL_KEEP_BUILD=1 (keep build dir).",
    "Linux and macOS only.",
}
