# Referência rápida

## Notification

```lua
exports.mz_lib:notify({ title = 'Título', description = 'Mensagem', type = 'success', duration = 4000 })
```

## Progress

```lua
local completed = exports.mz_lib:progress({ label = 'Processando...', duration = 5000, canCancel = true, disable = { move = true, car = true, combat = true }, anim = { dict = 'amb@world_human_hammering@male@base', clip = 'base', flag = 49 } })
```

## Confirmação Y/N

```lua
local accepted = exports.mz_lib:alertDialog({
  title = 'Aceitar orçamento?',
  description = 'Y para aceitar ou N para recusar.',
  keyboard = true,
  duration = 10000,        -- opcional: fecha sozinho após 10s
  variant = 'compact',     -- opcional: discreto, sem backdrop escurecendo a tela
  confirmLabel = 'Aceitar',
  cancelLabel = 'Recusar'
})
```

Retorna `true` para Y, `false` apenas para recusa explícita (N ou botão) e `nil`
para ESC, timeout ou substituição por outra solicitação. `duration` é em
milissegundos; sem ele, o diálogo aguarda o jogador indefinidamente. Com
`keyboard = true` a NUI recebe o teclado sem cursor. Ao expirar o `duration` ou
ser substituído, o foco NUI é liberado normalmente.

Para verificar aceitar, recusar, ESC, timeout e sobreposição, inclua
`examples/client.lua` temporariamente no manifest e use `/mz_alert_test`,
`/mz_alert_test compact`, `/mz_alert_test timeout` e `/mz_alert_test overlap`.

## Taskbar

```lua
local passed = exports.mz_lib:taskbar({
  title = 'Instalação',
  label = 'Acerte a zona de sucesso',
  duration = 6500,
  key = 'Space',
  keyLabel = 'ESPAÇO'
})
```

`skillCheck(options)` permanece como alias compatível de `taskbar(options)`.

## SkillProgress

```lua
local result = exports.mz_lib:SkillProgress({
  label = 'Arrombando veículo',
  duration = 20000,
  difficulty = 'medium', -- easy, medium ou hard
  skillchecks = { min = 2, max = 4 },
  perfectBonus = 6,
  missPenalty = 7,
  canCancel = true
})
```

Retorna `success`, `cancelled`, `reason`, `hits`, `perfects`, `misses` e `duration` em milissegundos. O alias camelCase `skillProgress` expõe o mesmo contrato. A conclusão local é somente feedback de interação; consumo de item, recompensa, permissão e demais mutações continuam validados pelo servidor do resource de domínio.

## Input fields

Tipos: `text`, `textarea`, `number`, `checkbox`, `select`, `multiselect`, `slider`, `date` e `color`. Cada campo aceita `name`, `label`, `required`, `default` e `options` quando aplicável.

## Eventos

- Client: `mz_lib:notify` recebe o mesmo payload do export.
- Client interno: `mz_lib:uiAction` recebe `name, data` para ações NUI.
- Eventos de callbacks são internos e não devem ser disparados manualmente.

## Convenções

Todas as APIs públicas usam camelCase. Configurações são tabelas nomeadas; resultados cancelados retornam `nil` ou `false`. Recursos consumer devem declarar `dependency 'mz_lib'` no próprio manifest.
