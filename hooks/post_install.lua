--- Builds and installs Spinel from the release source tarball
--- @param ctx table Context provided by vfox
--- @field ctx.sdkInfo table SDK information with version and path
function PLUGIN:PostInstall(ctx)
    local sdkInfo = ctx.sdkInfo["spinel"]
    local sdkPath = sdkInfo.path

    if RUNTIME.osType == "windows" then
        error("Spinel plugin does not support Windows (Linux and macOS only)")
    end

    local function ok(status)
        return status == 0 or status == true
    end

    local function sq(s)
        return "'" .. string.gsub(s, "'", "'\\''") .. "'"
    end

    -- Prerequisites
    local cc = os.getenv("CC")
    if cc == nil or cc == "" then
        cc = "cc"
    end
    -- $CC may contain arguments; check the first word only
    local cc_bin = string.match(cc, "^%s*(%S+)") or "cc"
    if not ok(os.execute("command -v " .. sq(cc_bin) .. " >/dev/null 2>&1")) then
        error(
            "C compiler '"
                .. cc_bin
                .. "' not found. Install a C compiler (e.g. build-essential / Xcode CLT) or set CC."
        )
    end
    if not ok(os.execute("command -v make >/dev/null 2>&1")) then
        error("'make' not found. Please install make.")
    end

    -- sdkPath/bin collides with the source tree's bin/, so build in a sibling directory (<sdkPath>.build)
    local buildDir = string.gsub(sdkPath, "/+$", "") .. ".build"
    local keepBuild = os.getenv("SPINEL_KEEP_BUILD") == "1"

    local function cleanup()
        if not keepBuild then
            os.execute("rm -rf " .. sq(buildDir))
        end
    end

    local function run(cmd, msg)
        local status = os.execute(cmd)
        if not ok(status) then
            cleanup()
            error(msg)
        end
    end

    run("rm -rf " .. sq(buildDir) .. " && mkdir -p " .. sq(buildDir), "Failed to create build directory")
    run(
        string.format(
            'cd %s && for f in * .[!.]* ..?*; do [ -e "$f" ] || [ -L "$f" ] || continue; mv "$f" %s/; done',
            sq(sdkPath),
            sq(buildDir)
        ),
        "Failed to move sources to build directory"
    )

    local makeOpts = os.getenv("SPINEL_MAKE_OPTS") or ""
    local nproc = "$(nproc 2>/dev/null || sysctl -n hw.ncpu 2>/dev/null || echo 4)"

    print("Building Spinel (this may take several minutes)...")
    run(
        string.format("cd %s && make -j%s %s", sq(buildDir), nproc, makeOpts),
        "Failed to build Spinel (set SPINEL_KEEP_BUILD=1 to keep the build directory: " .. buildDir .. ")"
    )

    print("Installing Spinel...")
    run(
        string.format("cd %s && make install PREFIX=%s %s", sq(buildDir), sq(sdkPath), makeOpts),
        "Failed to install Spinel"
    )

    cleanup()
    print("Spinel installation complete!")
end
