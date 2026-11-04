mz.cache = { playerId = PlayerId(), ped = PlayerPedId(), serverId = GetPlayerServerId(PlayerId()), vehicle = false }

CreateThread(function()
  while true do
    local ped = PlayerPedId()
    mz.cache.ped = ped
    mz.cache.coords = GetEntityCoords(ped)
    mz.cache.vehicle = GetVehiclePedIsIn(ped, false)
    Wait(500)
  end
end)

function mz.keyboardInput(title, defaultText, maxLength)
  AddTextEntry('MZ_KEYBOARD', title or 'Digite um valor')
  DisplayOnscreenKeyboard(1, 'MZ_KEYBOARD', '', defaultText or '', '', '', '', maxLength or 64)
  while UpdateOnscreenKeyboard() == 0 do Wait(0) end
  return GetOnscreenKeyboardResult()
end

function mz.registerCommand(name, description, defaultKey, callback)
  RegisterCommand(name, callback, false)
  if defaultKey then RegisterKeyMapping(name, description or name, 'keyboard', defaultKey) end
end

exports('getCache', function() return mz.cache end)
exports('keyboardInput', mz.keyboardInput)
exports('registerCommand', mz.registerCommand)
