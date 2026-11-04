local handlers, pending, sequence = {}, {}, 0

RegisterNetEvent('mz_lib:callback:server:request', function(name, id, ...)
  local player, handler = source, handlers[name]
  local result = handler and handler(player, ...) or nil
  TriggerClientEvent('mz_lib:callback:client:resolve', player, id, result)
end)

RegisterNetEvent('mz_lib:callback:server:resolve', function(id, result)
  local request = pending[id]
  if not request or request.source ~= source then return end
  pending[id] = nil
  request.deferred:resolve(result)
end)

function mz.registerCallback(name, handler)
  mz.assertType(name, 'string', 'callback name')
  handlers[name] = mz.assertCallable(handler, 'callback handler')
end

function mz.callback(player, name, ...)
  sequence = sequence + 1
  local id, deferred = ('server:%s'):format(sequence), promise.new()
  pending[id] = { source = player, deferred = deferred }
  TriggerClientEvent('mz_lib:callback:client:request', player, name, id, ...)
  SetTimeout(MzConfig.callbackTimeout, function()
    if pending[id] then pending[id] = nil deferred:resolve(nil) end
  end)
  return Citizen.Await(deferred)
end

exports('registerCallback', mz.registerCallback)
exports('callback', mz.callback)
