mz = rawget(_G, 'mz') or {}
mz.name = 'mz_lib'
mz.version = '1.0.0'
mz.isServer = IsDuplicityVersion()
mz.resource = GetCurrentResourceName()

local function assertType(value, expected, label)
  local actual = type(value)
  if actual ~= expected then
    error(('%s deve ser %s, recebeu %s'):format(label or 'valor', expected, actual), 3)
  end
  return value
end

mz.assertType = assertType

function mz.assertCallable(value, label)
  if type(value) == 'function'
      or (type(value) == 'table' and rawget(value, '__cfx_functionReference') ~= nil) then
    return value
  end
  error(('%s deve ser invocável, recebeu %s'):format(label or 'valor', type(value)), 2)
end

function mz.log(level, message, ...)
  if level == 'debug' and not MzConfig.debug then return end
  local text = select('#', ...) > 0 and message:format(...) or message
  print(('[%s] [%s] %s'):format(mz.name, level:upper(), text))
end

exports('getVersion', function() return mz.version end)
exports('getConfig', function() return MzConfig end)
