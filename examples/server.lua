-- Inclua manualmente no manifest somente durante o desenvolvimento.
exports.mz_lib:registerCallback('mz_example:serverTime', function(source)
  return { source = source, time = os.time() }
end)

RegisterCommand('mz_broadcast', function(source)
  if source ~= 0 then return end
  exports.mz_lib:notifyAll({
    title = 'Servidor',
    description = 'Mensagem global enviada pelo console.',
    type = 'info'
  })
end, true)
