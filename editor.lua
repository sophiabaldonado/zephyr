local editor = {}
local maf = require 'maf'
local vector = maf.vector

local offset = vector()

function editor:init(level)
  self.active = true
  self:refresh()
  self.level = level

end

function editor:refresh()
  self.controllers = {}

  for i, controller in ipairs(lovr.headset.getControllers()) do
    self.controllers[i] = {
      object = controller,
      drag = {
        active = false,
        entity = nil,
        offset = vector()
      }
    }
  end
end

function editor:draw()

end

function editor:update(dt)
  for i,controller in ipairs(self.controllers) do
    local currentPosition = vector(controller.object:getPosition())
    for j,entity in ipairs(self.level.data.entities) do
      local t = entity.transform
      offset:set(t.x, t.y, t.z)

      if controller.object:getAxis('trigger') > 0 then
        if controller.drag.active then
          local newPosition = currentPosition + controller.drag.offset
          t.x, t.y, t.z = newPosition:unpack()
          self.level:updateEntityTransform(j)
        elseif #offset:sub(currentPosition) < 1 then
          controller.drag.entity = entity
          controller.drag.active = true
          controller.drag.offset:set(offset)
        end
      else
        controller.drag.active = false
      end
    end
  end
end

return editor