local simple = require 'shaders.simple'

function lovr.load()
  level = lovr.graphics.newModel('art/level.obj')
  world = lovr.physics.newWorld()
  balloon = {
    model = lovr.graphics.newModel('art/mobile_balloon.obj', 'art/mobile_DIFF.png'),
    collider = world:newBoxCollider(.075)
  }
  balloon.collider:setPosition(0, .25, -1)
  balloon.collider:getShapeList()[1]:setPosition(0, -.2, 0)
  balloon.collider:setGravityIgnored(true)
  windmillBlades = lovr.graphics.newModel('art/windmill-blades.obj', 'art/windmill-blades_texture0.png')
  lovr.graphics.setShader(simple())
end

function lovr.update(dt)
  world:update(dt)
end

function lovr.draw()
  local x, y, z = 0, -.75, -2
  local angle = lovr.timer.getTime() * 2
  level:draw(x, y, z, .03)
  windmillBlades:draw(.5, 0, -1.3, .2, angle, 0, 0, 1)
  x, y, z = balloon.collider:getPosition()
  balloon.model:draw(x, y, z, .005, balloon.collider:getOrientation())
  local sx, sy, sz = balloon.collider:getShapeList()[1]:getPosition()
  lovr.graphics.cube('fill', x + sx, y + sy, z + sz, .075)
end
