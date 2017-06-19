local balloon = require 'balloon'
local input = require 'input'

viewport = {
  translation = 0,
  rotation = 0,
  viewMatrix = lovr.math.newTransform()
}

clouds = {}

function lovr.load()
  world = lovr.physics.newWorld()
  input:init()
  balloon:init()
  lovr.graphics.setShader(require('shaders/simple'))
  lovr.graphics.setBackgroundColor(130, 200, 220)
  lovr.headset.setClipDistance(.01, 20)

  for i = 1, 20 do
    local direction = math.random() * 2 * math.pi
    local distance = 4 + math.random() * 4
    local y = 1 + math.random() * 10
    local x = math.cos(direction) * distance
    local z = math.sin(direction) * distance
    table.insert(clouds, { x, y, z })
  end

  model1 = lovr.graphics.newModel('art/island1.dae', 'art/island1.png')
  model2 = lovr.graphics.newModel('art/island2.dae', 'art/island2.png')
  model3 = lovr.graphics.newModel('art/island3.dae', 'art/island3.png')
  obstacle = lovr.graphics.newModel('art/obstacle.obj')
  bell = lovr.graphics.newModel('art/bell.obj', 'art/bell.png')
  bridge = lovr.graphics.newModel('art/arch.dae', 'art/arch.png')
  halfbridge = lovr.graphics.newModel('art/arch-half.dae', 'art/arch-half.png')
  shroom = lovr.graphics.newModel('art/shroom.dae', 'art/shroom.png')
end

function lovr.update(dt)
  input:update(dt)
  balloon:update(dt)
  world:update(dt)
end

function lovr.draw()
  local shader = lovr.graphics.getShader()
  viewport.viewMatrix:origin()
  viewport.viewMatrix:translate(lovr.headset.getPosition())
  viewport.viewMatrix:rotate(lovr.headset.getOrientation())
  shader:send('zephyrView', viewport.viewMatrix:inverse())
  shader:send('ambientColor', { .5, .5, .5 })
  input:draw()

  lovr.graphics.push()
  lovr.graphics.translate(0, -viewport.translation, 0)
  lovr.graphics.rotate(viewport.rotation)

  balloon:draw()
  model1:draw(.3, 1, .3, .05)
  model2:draw(-.3, 1, -.3, .05)
  model3:draw(.3, 1, -.3, .05)
  obstacle:draw(-.3, 1, .3, .05)
  bell:draw(-.35, .95, .3, .01)
  bridge:draw(.3, .75, -.3, .05)
  halfbridge:draw(-.3, 1, .13, .05, 1, 0, 1, 0)
  shroom:draw(.3, 1.025, -.3, .005)

  shader:send('ambientColor', { .9, .9, .9 })
  for i = 1, #clouds do
    local x, y, z = unpack(clouds[i])
    lovr.graphics.cube('fill', x, y, z, .2)
  end

  lovr.graphics.pop()
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
