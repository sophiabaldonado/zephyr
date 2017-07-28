local editor = require 'editor'
local level = require 'level'
local net = require 'net'

viewport = {
  viewMatrix = lovr.math.newTransform()
}

function lovr.load()
  level:init('levels/level.json')
  editor:init(level)
  lovr.graphics.setShader(require('shaders/simple'))
  lovr.graphics.setBackgroundColor(20, 20, 25)
  lovr.headset.setClipDistance(.01, 21)
	net:init()
end

function lovr.update(dt)
  level:update(dt)
  editor:update(dt)
	net:update(dt)
end

function lovr.draw()
  local shader = lovr.graphics.getShader()
  viewport.viewMatrix:origin()
  viewport.viewMatrix:translate(lovr.headset.getPosition())
  viewport.viewMatrix:rotate(lovr.headset.getOrientation())
  shader:send('zephyrView', viewport.viewMatrix:inverse())
  shader:send('ambientColor', { .5, .5, .5 })

  level:draw()
  editor:draw()
end

function lovr.controlleradded()
  editor:refreshControllers()
end

function lovr.controllerremoved()
  editor:refreshControllers()
end

function lovr.controllerpressed(...)
  editor:controllerpressed(...)
end

function lovr.controllerreleased(...)
  editor:controllerreleased(...)
end

function lovr.quit()
  if editor.isDirty then level:save() end
end

tick = {
  rate = .03,
  dt = 0,
  accum = 0
}
function lovr.step()
  tick.dt = lovr.timer.step()
  tick.accum = tick.accum + tick.dt
  while tick.accum >= tick.rate do
    tick.accum = tick.accum - tick.rate
    lovr.event.pump()
    for name, a, b, c, d in lovr.event.poll() do
      if name == 'quit' and (not lovr.quit or not lovr.quit()) then
        return a
      end
      lovr.handlers[name](a, b, c, d)
    end
    lovr.update(tick.rate)
  end
  if lovr.audio then
    lovr.audio.update()
    if lovr.headset and lovr.headset.isPresent() then
      lovr.audio.setOrientation(lovr.headset.getOrientation())
      lovr.audio.setPosition(lovr.headset.getPosition())
      lovr.audio.setVelocity(lovr.headset.getVelocity())
    end
  end
  lovr.graphics.clear()
  lovr.graphics.origin()
  if lovr.draw then
    if lovr.headset and lovr.headset.isPresent() then
      lovr.headset.renderTo(lovr.draw)
    else
      lovr.draw()
    end
  end
  lovr.graphics.present()
  lovr.timer.sleep(.001)
end
