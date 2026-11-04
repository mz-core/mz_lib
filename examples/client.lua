-- Remova este arquivo da pasta examples ou inclua-o no manifest apenas para testes.
RegisterCommand('mz_demo', function()
  exports.mz_lib:notify({ title = 'mz_lib', description = 'Resource funcionando.', type = 'success' })
end)

RegisterCommand('mz_progress', function()
  local completed = exports.mz_lib:progress({
    label = 'Executando ação...', duration = 4000, canCancel = true,
    disable = { move = true, combat = true }
  })
  exports.mz_lib:notify({ description = completed and 'Concluído' or 'Cancelado', type = completed and 'success' or 'warning' })
end)

RegisterCommand('mz_menu', function()
  local selected = exports.mz_lib:contextMenu({
    title = 'Exemplo',
    items = {
      { title = 'Notificação', description = 'Dispara um feedback', value = 'notify' },
      { title = 'Desabilitado', disabled = true }
    }
  })
  if selected == 'notify' then exports.mz_lib:notify('Selecionado pelo context menu') end
end)

RegisterCommand('mz_skill', function()
  local passed = exports.mz_lib:skillCheck({ title = 'Ligação direta', key = 'Space' })
  exports.mz_lib:notify({ description = passed and 'Você passou' or 'Você falhou', type = passed and 'success' or 'error' })
end)

-- Ferramenta de desenvolvimento: este arquivo não é carregado pelo manifest de produção.

-- Teste do alertDialog Y/N. Modos:
--   /mz_alert_test            -> modal com keyboard + duration (Y, N, ESC ou timeout)
--   /mz_alert_test compact    -> variante discreta sem backdrop
--   /mz_alert_test timeout    -> duration curto, deve voltar nil sem input
--   /mz_alert_test overlap    -> segundo request encerra o primeiro com nil
RegisterCommand('mz_alert_test', function(_, args)
  local mode = (args[1] or 'modal'):lower()

  local function report(label, result)
    local text = result == true and 'aceito (Y)'
      or result == false and 'recusado (N)'
      or 'nil (ESC, timeout ou sobreposicao)'
    exports.mz_lib:notify({
      title = label,
      description = text,
      type = result == true and 'success' or result == false and 'error' or 'warning'
    })
  end

  if mode == 'overlap' then
    CreateThread(function()
      local first = exports.mz_lib:alertDialog({
        title = 'Primeiro (deve virar nil)',
        description = 'O segundo request deve encerrar este.',
        keyboard = true,
        duration = 15000,
        variant = 'compact'
      })
      report('Sobreposição: primeiro', first)
    end)
    Wait(700)
    local second = exports.mz_lib:alertDialog({
      title = 'Segundo (deve abrir)',
      keyboard = true,
      duration = 8000,
      variant = 'compact'
    })
    report('Sobreposição: segundo', second)
    return
  end

  local duration = mode == 'timeout' and 3000 or 10000
  local result = exports.mz_lib:alertDialog({
    title = 'Confirmação de teste',
    description = 'Y aceita, N recusa, ESC cancela; fecha sozinho em ' .. (duration / 1000) .. 's.',
    keyboard = true,
    duration = duration,
    variant = mode == 'compact' and 'compact' or nil,
    confirmLabel = 'Aceitar',
    cancelLabel = 'Recusar'
  })
  report('alertDialog (' .. mode .. ')', result)
end)
RegisterCommand('mz_skillprogress_test', function()
  local result = exports.mz_lib:SkillProgress({
    style = 'dbd',
    label = 'Testando SkillProgress DBD',
    duration = 30000,
    difficulty = 'medium',
    skillchecks = { min = 3, max = 5 },
    perfectBonus = 6,
    missPenalty = 7,
    canCancel = true
  })
  exports.mz_lib:notify({
    title = result.success and 'SkillProgress concluído' or 'SkillProgress encerrado',
    description = ('Acertos: %d · Perfeitos: %d · Erros: %d · %.1fs'):format(result.hits, result.perfects, result.misses, result.duration / 1000),
    type = result.success and 'success' or 'warning'
  })
end)
