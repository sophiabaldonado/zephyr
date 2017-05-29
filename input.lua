local util = require 'util'

input = {}

function input:init()
  self:refresh()
end

function input:update(dt)
  for i, fan in ipairs(self.fans) do
    fan.power = util.lerp(fan.power, fan.controller:getAxis('trigger'), 2 * dt)
  end
end

function input:refresh()
  self.fans = {}

  for i, controller in ipairs(lovr.headset.getControllers()) do
    self.fans[i] = {
      controller = controller,
      model = nil,
      power = 0
    }
  end
end

function input:draw()
  lovr.graphics.setColor(255, 255, 255)
  for i, fan in ipairs(self.fans) do
    local x, y, z = fan.controller:getPosition()
    local size = .1 + fan.power * .05
    lovr.graphics.cube('fill', x, y, z, size, fan.controller:getOrientation())
  end
end

return input