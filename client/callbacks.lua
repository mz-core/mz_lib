local pending, handlers, sequence = {}, {}, 0

RegisterNetEvent('mz_lib:callback:client:resolve', function(id, result)
  local request = pending[id]
  if not request then return end
  pending[id] = nil
  request:resolve(result)
end)

RegisterNetEvent('mz_lib:callback:client:request', function(name, id, ...)
  local handler = handlers[name]
  local result = handler and handler(...) or nil
  TriggerServerEvent('mz_lib:callback:server:resolve', id, result)
end)

function mz.callback(name, ...)
  sequence = sequence + 1
  local id, deferred = ('%s:%s'):format(GetPlayerServerId(PlayerId()), sequence), promise.new()
  pending[id] = deferred
  TriggerServerEvent('mz_lib:callback:server:request', name, id, ...)
  SetTimeout(MzConfig.callbackTimeout, function()
    if pending[id] then pending[id] = nil deferred:resolve(nil) end
  end)
  return Citizen.Await(deferred)
end

function mz.registerCallback(name, handler)
  mz.assertType(name, 'string', 'callback name')
  handlers[name] = mz.assertCallable(handler, 'callback handler')
end

exports('callback', mz.callback)
exports('registerCallback', mz.registerCallback)
