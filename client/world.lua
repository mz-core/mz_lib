function mz.getClosestEntity(poolName, coords, maxDistance, filter)
  coords = coords or GetEntityCoords(PlayerPedId())
  local closest, distance = nil, maxDistance or math.huge
  for _, entity in ipairs(GetGamePool(poolName)) do
    if not filter or filter(entity) then
      local current = #(coords - GetEntityCoords(entity))
      if current < distance then closest, distance = entity, current end
    end
  end
  return closest, distance
end

function mz.closestVehicle(coords, maxDistance) return mz.getClosestEntity('CVehicle', coords, maxDistance) end
function mz.closestPed(coords, maxDistance) return mz.getClosestEntity('CPed', coords, maxDistance, function(ped) return ped ~= PlayerPedId() end) end
function mz.closestObject(coords, maxDistance) return mz.getClosestEntity('CObject', coords, maxDistance) end

function mz.requestControl(entity, timeout)
  if NetworkHasControlOfEntity(entity) then return true end
  NetworkRequestControlOfEntity(entity)
  return mz.waitUntil(function() return NetworkHasControlOfEntity(entity) end, timeout or 2000)
end

function mz.raycast(distance, flags)
  local ped = PlayerPedId()
  local origin = GetGameplayCamCoord()
  local rotation = GetGameplayCamRot(2)
  local rz, rx = math.rad(rotation.z), math.rad(rotation.x)
  local direction = vector3(-math.sin(rz) * math.abs(math.cos(rx)), math.cos(rz) * math.abs(math.cos(rx)), math.sin(rx))
  local destination = origin + direction * (distance or 10.0)
  local ray = StartShapeTestRay(origin.x, origin.y, origin.z, destination.x, destination.y, destination.z, flags or -1, ped, 0)
  local _, hit, endCoords, normal, entity = GetShapeTestResult(ray)
  return hit == 1, endCoords, normal, entity
end

exports('closestVehicle', mz.closestVehicle)
exports('closestPed', mz.closestPed)
exports('closestObject', mz.closestObject)
exports('requestControl', mz.requestControl)
exports('raycast', mz.raycast)
