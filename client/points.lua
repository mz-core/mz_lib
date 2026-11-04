local points, nextId = {}, 0
function mz.addPoint(options)
  nextId = nextId + 1
  options.id = options.id or ('point:%s'):format(nextId)
  points[options.id] = options
  return options.id
end
function mz.removePoint(id) points[id] = nil end

CreateThread(function()
  while true do
    local sleep, coords = 750, GetEntityCoords(PlayerPedId())
    for _, point in pairs(points) do
      point.currentDistance = #(coords - point.coords)
      local nearby = point.currentDistance <= (point.distance or 10.0)
      if nearby then
        sleep = 0
        if not point.isNearby then point.isNearby = true if point.onEnter then point.onEnter(point) end end
        if point.nearby then point.nearby(point) end
      elseif point.isNearby then point.isNearby = false if point.onExit then point.onExit(point) end end
    end
    Wait(sleep)
  end
end)
exports('addPoint', mz.addPoint)
exports('removePoint', mz.removePoint)
