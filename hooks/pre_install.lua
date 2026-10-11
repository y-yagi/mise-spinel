--- Returns pre-install information for Spinel
--- @param ctx table Context provided by vfox
--- @return table Pre-install info
function PLUGIN:PreInstall(ctx)
    local version = ctx.version

    -- mise strips the top-level directory when extracting
    return {
        version = version,
        url = "https://github.com/matz/spinel/releases/download/" .. version .. "/spinel-" .. version .. ".tar.xz",
    }
end
