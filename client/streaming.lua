local function awaitAsset(request, loaded, value, timeout)
  request(value)
  local started = GetGameTimer()
  while not loaded(value) do
    if GetGameTimer() - started > (timeout or MzConfig.streamingTimeout) then return false end
    Wait(0)
  end
  return true
end

function mz.requestModel(model, timeout)
  local hash = type(model) == 'number' and model or joaat(model)
  if not IsModelInCdimage(hash) then return false end
  return awaitAsset(RequestModel, HasModelLoaded, hash, timeout) and hash or false
end
function mz.requestAnimDict(dict, timeout) return awaitAsset(RequestAnimDict, HasAnimDictLoaded, dict, timeout) end
function mz.requestAnimSet(set, timeout) return awaitAsset(RequestAnimSet, HasAnimSetLoaded, set, timeout) end
function mz.requestTextureDict(dict, timeout) return awaitAsset(RequestStreamedTextureDict, HasStreamedTextureDictLoaded, dict, timeout) end
function mz.requestWeaponAsset(weapon, timeout) return awaitAsset(RequestWeaponAsset, HasWeaponAssetLoaded, weapon, timeout) end
function mz.requestNamedPtfxAsset(asset, timeout) return awaitAsset(RequestNamedPtfxAsset, HasNamedPtfxAssetLoaded, asset, timeout) end

exports('requestModel', mz.requestModel)
exports('requestAnimDict', mz.requestAnimDict)
exports('requestAnimSet', mz.requestAnimSet)
exports('requestTextureDict', mz.requestTextureDict)
exports('requestWeaponAsset', mz.requestWeaponAsset)
exports('requestNamedPtfxAsset', mz.requestNamedPtfxAsset)
