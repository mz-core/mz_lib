mz.table = {}

function mz.table.clone(value, seen)
  if type(value) ~= 'table' then return value end
  seen = seen or {}
  if seen[value] then return seen[value] end
  local copy = {}
  seen[value] = copy
  for key, item in pairs(value) do copy[mz.table.clone(key, seen)] = mz.table.clone(item, seen) end
  return setmetatable(copy, getmetatable(value))
end

function mz.table.merge(base, extra)
  local output = mz.table.clone(base or {})
  for key, value in pairs(extra or {}) do
    output[key] = type(value) == 'table' and type(output[key]) == 'table'
      and mz.table.merge(output[key], value) or mz.table.clone(value)
  end
  return output
end

function mz.table.contains(items, target)
  for _, value in pairs(items or {}) do if value == target then return true end end
  return false
end

function mz.uuid(prefix)
  local template = 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'
  local id = template:gsub('[xy]', function(char)
    local value = char == 'x' and math.random(0, 15) or math.random(8, 11)
    return ('%x'):format(value)
  end)
  return prefix and (prefix .. ':' .. id) or id
end

function mz.clamp(value, minimum, maximum)
  return math.max(minimum, math.min(maximum, value))
end

function mz.round(value, precision)
  local factor = 10 ^ (precision or 0)
  return math.floor(value * factor + 0.5) / factor
end

function mz.debounce(delay, callback)
  local generation = 0
  return function(...)
    generation = generation + 1
    local current, args = generation, { ... }
    SetTimeout(delay, function()
      if current == generation then callback(table.unpack(args)) end
    end)
  end
end

function mz.waitUntil(predicate, timeout, interval)
  local started = GetGameTimer()
  while not predicate() do
    if GetGameTimer() - started >= (timeout or 5000) then return false end
    Wait(interval or 0)
  end
  return true
end
