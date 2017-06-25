local balloon = require 'balloon'
local input = require 'input'
local editor = require 'editor'
local level = require 'level'

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
  level:init('levels/level.json')
  editor:init(level)
  lovr.graphics.setShader(require('shaders/simple'))
  lovr.graphics.setBackgroundColor(130, 200, 220)
  lovr.headset.setClipDistance(.01, 21)

  for i = 1, 20 do
    local direction = math.random() * 2 * math.pi
    local distance = 4 + math.random() * 4
    local y = 1 + math.random() * 10
    local x = math.cos(direction) * distance
    local z = math.sin(direction) * distance
    table.insert(clouds, { x, y, z })
  end
end

function lovr.update(dt)
  input:update(dt)
  balloon:update(dt)
  world:update(dt)
  level:update(dt)
  editor:update(dt)
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

  if not editor.active then
    input:draw()
  end

  lovr.graphics.push()
  lovr.graphics.translate(0, -viewport.translation, 0)
  lovr.graphics.rotate(viewport.rotation)

  balloon:draw()

  shader:send('ambientColor', { .9, .9, .9 })
  for i = 1, #clouds do
    local x, y, z = unpack(clouds[i])
    lovr.graphics.cube('fill', x, y, z, .2)
  end

  lovr.graphics.pop()
end

function lovr.controlleradded()
  input:refresh()
  editor:refreshControllers()
end

function lovr.controllerremoved()
  input:refresh()
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
