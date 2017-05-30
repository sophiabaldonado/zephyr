local util = require 'util'
local maf = require 'maf'
local vector = maf.vector
local quaternion = maf.rotation

local position = vector()
local projected1 = vector()
local projected2 = vector()
local up = vector(0, 1, 0)

input = {}

function input:init()
  self:refresh()
end

function input:update(dt)
  for i, fan in ipairs(self.fans) do
    fan.power = util.lerp(fan.power, fan.controller:getAxis('trigger'), 2 * dt)

    if fan.controller:isDown('touchpad') then
      if fan.drag.active then
        position:set(fan.controller:getPosition())

        local dy = fan.drag.position.y - position.y
        viewport.translation = viewport.translation + dy

        projected1:set(fan.drag.position)
        projected2:set(position)

        projected1.y = 0
        projected2.y = 0
        local angle = vector.angle(projected1, projected2)
        if up:dot(projected1:cross(projected2)) < 0 then
          angle = -angle
        end

        viewport.rotation = viewport.rotation + angle

        fan.drag.position:set(position)
      else
        fan.drag.active = true
        fan.drag.position:set(fan.controller:getPosition())
      end
    else
      fan.drag.active = false
    end
  end
end

function input:refresh()
  self.fans = {}

  for i, controller in ipairs(lovr.headset.getControllers()) do
    self.fans[i] = {
      controller = controller,
      model = nil,
      power = 0,
      drag = {
        active = false,
        position = vector()
      }
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