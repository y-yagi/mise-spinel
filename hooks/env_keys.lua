--- Returns environment variables for Spinel
--- @param ctx table Context provided by vfox
--- @return table Environment configuration
function PLUGIN:EnvKeys(ctx)
    local sdkInfo = ctx.sdkInfo["spinel"]
    local installDir = sdkInfo.path

    return {
        {
            key = "PATH",
            value = installDir .. "/bin",
        },
    }
end
