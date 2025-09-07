Locales = {}

function _U(key, ...)
    if Locales[Config.Locale] and Locales[Config.Locale][key] then
        return string.format(Locales[Config.Locale][key], ...)
    else
        return '['..Config.Locale..'] '..key
    end
end
