local simple = require 'shaders.simple'
local balloon = require 'balloon'
local input = require 'input'

function lovr.load()
  debug = true
  level = lovr.graphics.newModel('art/level.obj')
  obstacle = lovr.graphics.newModel('art/obstacle.obj')
  world = lovr.physics.newWorld()
  balloon:init()
  windmillBlades = lovr.graphics.newModel('art/windmill-blades.obj', 'art/windmill-blades_texture0.png')
  lovr.graphics.setShader(simple())
  input:init()
end

function lovr.update(dt)
  world:update(dt)
  input:update(dt)
  balloon:update(dt)
end

function lovr.draw()
  local x, y, z = 0, -.75, -2
  local angle = lovr.timer.getTime() * 2
  level:draw(x, y, z, .03)
  obstacle:draw(0, .5, -2, .03)
  windmillBlades:draw(.5, 0, -1.3, .2, angle, 0, 0, 1)
  balloon:draw()
  input:draw()
end

function lovr.controlleradded()
  input:refresh()
end

function lovr.controllerremoved()
  input:refresh()
end
