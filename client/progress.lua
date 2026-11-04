local active = nil

local function toggleControls(disable)
  if not disable then return end
  CreateThread(function()
    while active do
      if disable.move then DisableAllControlActions(0) EnableControlAction(0, 1, true) EnableControlAction(0, 2, true) end
      if disable.car then DisableControlAction(0, 71, true) DisableControlAction(0, 72, true) end
      if disable.combat then DisablePlayerFiring(PlayerId(), true) end
      Wait(0)
    end
  end)
end

function mz.progress(options)
  if active then return false end
  options = options or {}
  active = { cancelled = false }
  SendNUIMessage({ action = 'progress:show', data = options })
  toggleControls(options.disable)

  if options.anim then
    mz.requestAnimDict(options.anim.dict)
    TaskPlayAnim(PlayerPedId(), options.anim.dict, options.anim.clip, 3.0, 1.0, -1, options.anim.flag or 49, 0, false, false, false)
  end

  local started, duration = GetGameTimer(), options.duration or 5000
  while GetGameTimer() - started < duration do
    if options.canCancel ~= false and IsControlJustReleased(0, MzConfig.controls.cancel) then active.cancelled = true break end
    Wait(0)
  end

  local completed = not active.cancelled
  active = nil
  ClearPedTasks(PlayerPedId())
  SendNUIMessage({ action = 'progress:hide', data = { completed = completed } })
  return completed
end

function mz.cancelProgress()
  if active then active.cancelled = true return true end
  return false
end

exports('progress', mz.progress)
exports('cancelProgress', mz.cancelProgress)
