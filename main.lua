local simple = require 'shaders.simple'

function lovr.load()
  level = lovr.graphics.newModel('art/level.obj')
  balloon = lovr.graphics.newModel('art/mobile_balloon.obj', 'art/mobile_DIFF.png')
  windmillBlades = lovr.graphics.newModel('art/windmill-blades.obj', 'art/windmill-blades_texture0.png')
  lovr.graphics.setShader(simple())
end

function lovr.draw()
  local x, y, z = 0, -.75, -2
  local angle = lovr.timer.getTime() * 6
  level:draw(x, y, z, .03)
  balloon:draw(x, math.sin(angle * .15) * .03, -1, .005)
  windmillBlades:draw(.5, 0, -1.3, .2, angle, 0, 0, 1)
end
