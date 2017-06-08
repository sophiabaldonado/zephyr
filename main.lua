local simple = require 'shaders.simple'
local balloon = require 'balloon'
local input = require 'input'

viewport = {
  translation = 0,
  rotation = 0
}

function lovr.load()
  debug = true
<<<<<<< HEAD
  level = lovr.graphics.newModel('art/level1.obj', 'art/level1.png')
  star = lovr.graphics.newModel('art/star.dae', 'art/gold.png')
=======
  level = lovr.graphics.newModel('art/level2.obj')
  obstacle = lovr.graphics.newModel('art/obstacle.obj')
>>>>>>> Level 2;
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
  input:draw()

  lovr.graphics.push()
  lovr.graphics.translate(0, -viewport.translation, 0)
  lovr.graphics.rotate(viewport.rotation)

  local x, y, z = 0, -.75, -2
  local angle = lovr.timer.getTime() * 2
  level:draw(x, y, z, .12)
  star:draw(0, 4, 0, .1)
  obstacle:draw(0, .5, -2, .03)
  windmillBlades:draw(.5, 0, -1.3, .2, angle, 0, 0, 1)
  balloon:draw()
  lovr.graphics.pop()
end

function lovr.controlleradded()
  input:refresh()
end

function lovr.controllerremoved()
  input:refresh()
end
