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
    -- The Makefile asks git for the revision first. Stop git from finding a repository that
    -- encloses the build directory (e.g. a dotfiles repo at $HOME) and reporting its HEAD.
    local buildParent = string.match(buildDir, "^(.*)/[^/]*$") or "/"
    local make = "GIT_CEILING_DIRECTORIES=" .. sq(buildParent) .. " make"

    -- The wasm32-wasi runtime (`spinel --target=wasm32-wasi`) is not part of the default build:
    -- `make wasm-rt` builds it with the wasi-sdk, which is looked up the way Spinel does
    -- (WASI_SDK, then WASI_SDK_PATH, else /opt/wasi-sdk). `make install` copies it when built.
    -- Older Spinel (the 2026.09.12 release and earlier) has no `wasm-rt` target at all.
    -- SPINEL_WASM_RT: unset builds it when both are there, 0 never, 1 always (required).
    -- Decide before the long native build, so a bad setting fails early.
    local wasmRt = os.getenv("SPINEL_WASM_RT") or ""
    if wasmRt ~= "" and wasmRt ~= "0" and wasmRt ~= "1" then
        cleanup()
        error("SPINEL_WASM_RT must be 0, 1 or unset (got '" .. wasmRt .. "')")
    end
    local buildWasmRt = false
    local wasiSdk = os.getenv("WASI_SDK")
    if wasiSdk == nil or wasiSdk == "" then
        wasiSdk = os.getenv("WASI_SDK_PATH")
    end
    if wasiSdk == nil or wasiSdk == "" then
        wasiSdk = "/opt/wasi-sdk"
    end
    if wasmRt == "0" then
        print("SPINEL_WASM_RT=0: skipping the wasm32-wasi runtime")
    else
        local skipReason = nil
        if not ok(os.execute("grep -q '^wasm-rt:' " .. sq(buildDir .. "/Makefile"))) then
            skipReason = "this Spinel version has no wasm32-wasi support (no `make wasm-rt`)"
        elseif not ok(os.execute("test -x " .. sq(wasiSdk .. "/bin/clang"))) then
            skipReason = "no wasi-sdk found at "
                .. wasiSdk
                .. " (set WASI_SDK or WASI_SDK_PATH to the wasi-sdk directory)"
        end
        if skipReason == nil then
            buildWasmRt = true
        elseif wasmRt == "1" then
            cleanup()
            error("SPINEL_WASM_RT=1 but " .. skipReason)
        else
            print("Skipping the wasm32-wasi runtime: " .. skipReason)
        end
    end

    if not is_spinel_release(sdkInfo.version) then
        -- The git source archive bundles neither prism nor rbs; fetch them from rubygems.org
        if not ok(os.execute("command -v curl >/dev/null 2>&1")) then
            cleanup()
            error("'curl' not found. It is required to build Spinel from source.")
        end
        print("Fetching Spinel dependencies (prism, rbs)...")
        run(
            string.format("cd %s && %s deps %s", sq(buildDir), make, makeOpts),
            "Failed to fetch Spinel dependencies (check access to rubygems.org)"
        )

        -- The archive carries no .git; record the revision so `spinel --version` names it.
        -- PreInstall pinned the download to this revision. If it could not, fall back to the
        -- version itself when it already looks like a commit SHA.
        local version = sdkInfo.version
        local rev = SPINEL_SOURCE_REVISIONS and SPINEL_SOURCE_REVISIONS[version]
        if rev == nil and string.match(version, "^%x%x%x%x%x%x%x+$") then
            rev = version
        end
        if rev == nil then
            print("warning: could not determine the Spinel source revision; `spinel --version` will show 'unknown'")
        else
            local f = io.open(buildDir .. "/.spinel-dist", "w")
            if f == nil then
                print(
                    "warning: could not write " .. buildDir .. "/.spinel-dist; `spinel --version` will show 'unknown'"
                )
            else
                f:write(string.sub(rev, 1, 7) .. "\n\n")
                f:close()
            end
        end
    end

    print("Building Spinel (this may take several minutes)...")
    run(
        string.format("cd %s && %s -j%s %s", sq(buildDir), make, nproc, makeOpts),
        "Failed to build Spinel (set SPINEL_KEEP_BUILD=1 to keep the build directory: " .. buildDir .. ")"
    )

    if buildWasmRt then
        print("Building the wasm32-wasi runtime with the wasi-sdk at " .. wasiSdk .. "...")
        run(
            string.format("cd %s && %s -j%s wasm-rt WASI_SDK=%s %s", sq(buildDir), make, nproc, sq(wasiSdk), makeOpts),
            "Failed to build the wasm32-wasi runtime (set SPINEL_KEEP_BUILD=1 to keep the build directory: "
                .. buildDir
                .. ", or SPINEL_WASM_RT=0 to skip it)"
        )
    end

    print("Installing Spinel...")
    run(
        string.format("cd %s && %s install PREFIX=%s %s", sq(buildDir), make, sq(sdkPath), makeOpts),
        "Failed to install Spinel"
    )

    if buildWasmRt then
        -- `make wasm-rt` also builds the runtime for `--exceptions=abort`, but upstream's install
        -- rule copies only libspinel_rt.a. Install it too so that option works.
        local noexcLib = "lib/wasm32-wasi/libspinel_rt_noexc.a"
        run(
            string.format(
                "cd %s && if [ -f %s ]; then install -m 644 %s %s; fi",
                sq(buildDir),
                noexcLib,
                noexcLib,
                sq(sdkPath .. "/lib/spinel/lib/wasm32-wasi/")
            ),
            "Failed to install the wasm32-wasi runtime for --exceptions=abort"
        )
    end

    cleanup()
    print("Spinel installation complete!")
end
