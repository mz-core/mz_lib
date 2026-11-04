local zones, nextId = {}, 0
local function insidePoly(point, vertices)
  local inside, j = false, #vertices
  for i = 1, #vertices do
    local a, b = vertices[i], vertices[j]
    if ((a.y > point.y) ~= (b.y > point.y)) and (point.x < (b.x - a.x) * (point.y - a.y) / (b.y - a.y) + a.x) then inside = not inside end
    j = i
  end
  return inside
end

local function contains(zone, coords)
  if zone.type == 'sphere' then return #(coords - zone.coords) <= zone.radius end
  if zone.type == 'box' then
    local delta = coords - zone.coords
    return math.abs(delta.x) <= zone.size.x / 2 and math.abs(delta.y) <= zone.size.y / 2 and math.abs(delta.z) <= zone.size.z / 2
  end
  if zone.type == 'poly' then return coords.z >= zone.minZ and coords.z <= zone.maxZ and insidePoly(coords, zone.points) end
end

function mz.addZone(options)
  nextId = nextId + 1
  options.id = options.id or ('zone:%s'):format(nextId)
  zones[options.id] = options
  return options.id
end
function mz.removeZone(id) zones[id] = nil end

CreateThread(function()
  while true do
    local sleep, coords = 750, GetEntityCoords(PlayerPedId())
    for _, zone in pairs(zones) do
      local isInside = contains(zone, coords)
      if isInside then sleep = 0 if not zone.inside then zone.inside = true if zone.onEnter then zone.onEnter(zone) end end if zone.nearby then zone.nearby(zone) end
      elseif zone.inside then zone.inside = false if zone.onExit then zone.onExit(zone) end end
    end
    Wait(sleep)
  end
end)

exports('addZone', mz.addZone)
exports('removeZone', mz.removeZone)
