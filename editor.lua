local editor = {}
local maf = require 'maf'
local vector = maf.vector

local offset = vector()
local initialDistance = 0

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
      currentPosition = vector(),
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
    controller.currentPosition:set(controller.object:getPosition())
    for j,entity in ipairs(self.level.data.entities) do
      local t = entity.transform
      offset:set(t.x, t.y, t.z)


      if self:bothControllersTriggered() then

        if initialDistance > 0 then
          local d = self.controllers[1].currentPosition:distance(self.controllers[2].currentPosition)
          local changeInDistance = (d / initialDistance)
          controller.drag.offset:set(controller.drag.offset:scale(changeInDistance))
          initialDistance = d
          self.level:updateEntityScale(j, changeInDistance)
        else
          initialDistance = (self.controllers[1].currentPosition - self.controllers[2].currentPosition):length()
        end
      elseif self:triggered(controller) then
        if controller.drag.active then
          local newPosition = controller.currentPosition + controller.drag.offset
          self.level:updateEntityPosition(j, newPosition:unpack())
        elseif #offset:sub(controller.currentPosition) < 1 then
          controller.drag.entity = entity
          controller.drag.active = true
          controller.drag.offset:set(offset)
        end
      else
        initialDistance = 0
        controller.drag.active = false
      end
    end
  end
end

function editor:bothControllersTriggered()
  return #self.controllers == 2 and self:triggered(self.controllers[1]) and self:triggered(self.controllers[2])
end

function editor:triggered(controller)
  return controller.object:getAxis('trigger') > 0
end


return editor