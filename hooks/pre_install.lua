--- Returns pre-install information for Spinel
--- @param ctx table Context provided by vfox
--- @return table Pre-install info
function PLUGIN:PreInstall(ctx)
    local version = ctx.version

    -- mise strips the top-level directory when extracting
    if is_spinel_release(version) then
        return {
            version = version,
            url = "https://github.com/matz/spinel/releases/download/" .. version .. "/spinel-" .. version .. ".tar.xz",
        }
    end

    -- Anything else (e.g. "master" or a commit SHA) is built from the git source archive.
    -- Resolve the ref to a commit first and download that commit, so the revision PostInstall
    -- records is the one that was built even if the branch moves in between.
    local ref = version
    local rev = resolve_spinel_revision(version)
    if rev ~= nil then
        SPINEL_SOURCE_REVISIONS = SPINEL_SOURCE_REVISIONS or {}
        SPINEL_SOURCE_REVISIONS[version] = rev
        ref = rev
    end
    return {
        version = version,
        url = "https://github.com/matz/spinel/archive/" .. ref .. ".tar.gz",
    }
end

--- Returns true if the version is a release tag (YYYY.MM.DD[.N])
function is_spinel_release(version)
    return string.match(version, "^%d%d%d%d%.%d%d%.%d%d$") ~= nil
        or string.match(version, "^%d%d%d%d%.%d%d%.%d%d%.%d+$") ~= nil
end

--- Resolves a git ref (branch or commit) to its commit SHA. Returns nil on failure.
function resolve_spinel_revision(ref)
    local http = require("http")
    local headers = {
        ["Accept"] = "application/vnd.github.sha",
        ["User-Agent"] = "mise-spinel",
    }
    local token = os.getenv("GITHUB_TOKEN")
    if token == nil or token == "" then
        token = os.getenv("GH_TOKEN")
    end
    if token ~= nil and token ~= "" then
        headers["Authorization"] = "Bearer " .. token
    end

    local resp, err = http.get({
        url = "https://api.github.com/repos/matz/spinel/commits/" .. ref,
        headers = headers,
    })
    if err ~= nil or resp.status_code ~= 200 then
        return nil
    end
    return string.match(resp.body, "^%s*(%x+)%s*$")
end
