local dictionaries = {}

local function loadLocale(locale)
  if dictionaries[locale] then return dictionaries[locale] end
  local raw = LoadResourceFile(mz.resource, ('locales/%s.json'):format(locale))
  dictionaries[locale] = raw and json.decode(raw) or {}
  return dictionaries[locale]
end

function mz.t(key, values)
  local selected = loadLocale(MzConfig.locale)
  local fallback = loadLocale('en')
  local phrase = selected[key] or fallback[key] or key
  for name, value in pairs(values or {}) do phrase = phrase:gsub('{' .. name .. '}', tostring(value)) end
  return phrase
end

exports('t', mz.t)
