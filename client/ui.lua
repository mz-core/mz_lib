local activeFocus = nil
local awaiting = {}
local sequence = 0
local activeSkillProgress = nil

local function send(action, data)
  SendNUIMessage({ action = action, data = data })
end

local function beginRequest(action, data, focus)
  sequence = sequence + 1
  local id, deferred = ('ui:%s'):format(sequence), promise.new()
  -- A NUI substitui o overlay atual: encerra de forma deterministica qualquer
  -- request anterior ainda pendente, para nao deixar o chamador bloqueado
  -- para sempre e para liberar o foco antes de assumir o novo.
  if activeFocus then
    local previous = activeFocus
    activeFocus = nil
    SetNuiFocus(false, false)
    local previousDeferred = awaiting[previous]
    if previousDeferred then awaiting[previous] = nil previousDeferred:resolve(nil) end
  end
  awaiting[id] = deferred
  if focus then activeFocus = id SetNuiFocus(true, focus ~= 'keyboard') end
  send(action, mz.table.merge(data or {}, { requestId = id }))
  return id, deferred
end

local function finishRequest(id, result)
  local deferred = awaiting[id]
  if deferred then awaiting[id] = nil deferred:resolve(result) end
  if activeFocus == id then activeFocus = nil SetNuiFocus(false, false) end
end

local function request(action, data, focus)
  local _, deferred = beginRequest(action, data, focus)
  return Citizen.Await(deferred)
end

RegisterNUICallback('resolve', function(payload, cb)
  finishRequest(payload.requestId, payload.result)
  cb({ ok = true })
end)

RegisterNUICallback('action', function(payload, cb)
  TriggerEvent('mz_lib:uiAction', payload.name, payload.data)
  cb({ ok = true })
end)

function mz.notify(data)
  if type(data) == 'string' then data = { description = data } end
  data.id = data.id or mz.uuid('notify')
  data.type = data.type or 'info'
  data.duration = data.duration or 4000
  send('notify', data)
  return data.id
end

function mz.textUI(text, options) send('textUI:show', mz.table.merge(options or {}, { text = text })) end
function mz.hideTextUI() send('textUI:hide', {}) end
function mz.contextMenu(options) return request('context:show', options, true) end
function mz.radialMenu(options) return request('radial:show', options, true) end
function mz.inputDialog(title, fields, options) return request('input:show', mz.table.merge(options or {}, { title = title, fields = fields }), true) end
function mz.alertDialog(options)
  options = options or {}
  return request('alert:show', options, options.keyboard == true and 'keyboard' or true)
end
function mz.taskbar(options)
  options = options or {}
  options.target = tonumber(options.target) or math.random(58, 76)
  options.zone = tonumber(options.zone) or 14
  options.duration = math.max(1500, tonumber(options.duration) or 6500)
  return request('taskbar:show', options, 'keyboard') == true
end
function mz.skillCheck(options) return mz.taskbar(options) end
function mz.skillProgress(options)
  if activeSkillProgress then
    return { success = false, cancelled = false, error = 'busy', hits = 0, perfects = 0, misses = 0, duration = 0 }
  end

  if type(options) ~= 'table' then options = {} end
  local checks = type(options.skillchecks) == 'table' and options.skillchecks or {}
  local difficulty = options.difficulty
  if difficulty ~= 'easy' and difficulty ~= 'hard' then difficulty = 'medium' end

  sequence = sequence + 1
  local token = sequence
  activeSkillProgress = token
  options.duration = mz.clamp(tonumber(options.duration) or 20000, 1000, 600000)
  options.difficulty = difficulty
  options.skillchecks = {
    min = math.floor(mz.clamp(tonumber(checks.min) or 2, 1, 8)),
    max = math.floor(mz.clamp(tonumber(checks.max) or 4, 1, 8))
  }
  if options.skillchecks.max < options.skillchecks.min then options.skillchecks.max = options.skillchecks.min end
  options.perfectBonus = mz.clamp(tonumber(options.perfectBonus) or 6, 0, 25)
  options.missPenalty = mz.clamp(tonumber(options.missPenalty) or 7, 0, 25)
  options.canCancel = options.canCancel ~= false

  local requestId, deferred = beginRequest('skillProgress:show', options, 'keyboard')
  CreateThread(function()
    local started = GetGameTimer()
    local failsafe = options.duration + (options.duration * options.missPenalty / 100 * options.skillchecks.max) + 10000
    while activeSkillProgress == token do
      Wait(100)
      if IsEntityDead(PlayerPedId()) then
        send('skillProgress:cancel', { reason = 'death' })
        Wait(250)
        finishRequest(requestId, { success = false, cancelled = true, reason = 'death', hits = 0, perfects = 0, misses = 0, duration = GetGameTimer() - started })
        return
      end
      if GetGameTimer() - started >= failsafe then
        send('skillProgress:cancel', { reason = 'timeout' })
        Wait(250)
        finishRequest(requestId, { success = false, cancelled = true, reason = 'timeout', hits = 0, perfects = 0, misses = 0, duration = GetGameTimer() - started })
        return
      end
    end
  end)

  local result = Citizen.Await(deferred)
  if activeSkillProgress == token then activeSkillProgress = nil end
  if type(result) ~= 'table' then
    return { success = false, cancelled = true, reason = 'nui_closed', hits = 0, perfects = 0, misses = 0, duration = 0 }
  end
  return result
end
function mz.SkillProgress(options) return mz.skillProgress(options) end
function mz.spinner(options) send('spinner:show', options or {}) end
function mz.hideSpinner() send('spinner:hide', {}) end
function mz.setClipboard(value) send('clipboard', { value = value }) end

RegisterNetEvent('mz_lib:notify', mz.notify)
exports('notify', mz.notify)
exports('textUI', mz.textUI)
exports('hideTextUI', mz.hideTextUI)
exports('contextMenu', mz.contextMenu)
exports('radialMenu', mz.radialMenu)
exports('inputDialog', mz.inputDialog)
exports('alertDialog', mz.alertDialog)
exports('taskbar', mz.taskbar)
exports('skillCheck', mz.skillCheck)
exports('skillProgress', mz.skillProgress)
exports('SkillProgress', mz.SkillProgress)
exports('spinner', mz.spinner)
exports('hideSpinner', mz.hideSpinner)
exports('setClipboard', mz.setClipboard)

AddEventHandler('onResourceStop', function(resource)
  if resource ~= mz.resource then return end
  activeSkillProgress = nil
  send('skillProgress:cancel', { reason = 'resource_stop' })
  SetNuiFocus(false, false)
  for _, deferred in pairs(awaiting) do deferred:resolve(nil) end
end)
