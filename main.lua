local balloon = require 'balloon'
local input = require 'input'

viewport = {
  translation = 0,
  rotation = 0
}

function lovr.load()
  world = lovr.physics.newWorld()
  input:init()
  balloon:init()
  lovr.graphics.setShader(require('shaders/simple'))
  lovr.graphics.setBackgroundColor(130, 200, 220)
end

function lovr.update(dt)
  input:update(dt)
  balloon:update(dt)
  world:update(dt)
end

function lovr.draw()
  input:draw()
  balloon:draw()
end

function lovr.controlleradded()
  input:refresh()
end

function lovr.controllerremoved()
  input:refresh()
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