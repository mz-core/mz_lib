function mz.notifyPlayer(player, data)
  TriggerClientEvent('mz_lib:notify', player, data)
end

function mz.notifyAll(data)
  TriggerClientEvent('mz_lib:notify', -1, data)
end

function mz.getIdentifiers(player)
  local identifiers = {}
  for _, identifier in ipairs(GetPlayerIdentifiers(player)) do
    local kind = identifier:match('^([^:]+):')
    identifiers[kind] = identifier
  end
  return identifiers
end

exports('notifyPlayer', mz.notifyPlayer)
exports('notifyAll', mz.notifyAll)
exports('getIdentifiers', mz.getIdentifiers)
