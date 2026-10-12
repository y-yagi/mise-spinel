--- Returns available Spinel versions from GitHub releases
--- @param ctx table Context provided by vfox
--- @return table Available versions
function PLUGIN:Available(ctx)
    local http = require("http")
    local json = require("json")
    local result = {}
    local seen = {}

    local headers = {
        ["Accept"] = "application/vnd.github+json",
        ["User-Agent"] = "mise-spinel",
    }
    local token = os.getenv("GITHUB_TOKEN")
    if token == nil or token == "" then
        token = os.getenv("GH_TOKEN")
    end
    if token ~= nil and token ~= "" then
        headers["Authorization"] = "Bearer " .. token
    end

    local page = 1
    local per_page = 100

    while true do
        local resp, err = http.get({
            url = "https://api.github.com/repos/matz/spinel/releases?per_page=" .. per_page .. "&page=" .. page,
            headers = headers,
        })

        if err ~= nil then
            error("Failed to fetch Spinel releases: " .. tostring(err))
        end
        if resp.status_code ~= 200 then
            error("Failed to fetch Spinel releases: HTTP " .. tostring(resp.status_code))
        end

        local releases = json.decode(resp.body)
        if releases == nil or #releases == 0 then
            break
        end

        for _, release in ipairs(releases) do
            local tag = release.tag_name
            if tag ~= nil and is_spinel_release(tag) then
                local wanted = "spinel-" .. tag .. ".tar.xz"
                local has_asset = false
                for _, asset in ipairs(release.assets or {}) do
                    if asset.name == wanted then
                        has_asset = true
                        break
                    end
                end
                if has_asset and not seen[tag] then
                    seen[tag] = true
                    table.insert(result, { version = tag })
                end
            end
        end

        if #releases < per_page then
            break
        end
        page = page + 1
        if page > 20 then
            break
        end
    end

    -- Newest first
    table.sort(result, function(a, b)
        return compare_spinel_versions(a.version, b.version) > 0
    end)

    if #result > 0 then
        result[1].note = "latest"
    end

    return result
end

--- Compare YYYY.MM.DD[.N] versions. Returns positive if a > b, negative if a < b, 0 if equal.
function compare_spinel_versions(a, b)
    local function parts(v)
        local y, m, d, n = string.match(v, "^(%d+)%.(%d+)%.(%d+)%.?(%d*)$")
        return { tonumber(y) or 0, tonumber(m) or 0, tonumber(d) or 0, tonumber(n) or 0 }
    end
    local pa, pb = parts(a), parts(b)
    for i = 1, 4 do
        if pa[i] ~= pb[i] then
            return pa[i] - pb[i]
        end
    end
    return 0
end
