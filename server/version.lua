CreateThread(function()
  Wait(0)
  mz.log('info', 'mz_lib v%s iniciada em modo standalone', mz.version)
end)

AddEventHandler('playerDropped', function()
  mz.log('debug', 'Player %s desconectou', source)
end)
