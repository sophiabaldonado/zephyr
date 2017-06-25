local Editor = {}

local maf = require 'maf'
local vector = maf.vector
local quaternion = maf.quat
local util = require 'util'

Editor.grabRange = .5

function Editor:init(level)
  self.active = true
  self:refreshControllers()
  self.level = level
  self.isDirty = false
  self.lastChange = lovr.timer.getTime()
  self.satchel = self:generateEntities()
end

function Editor:update(dt)
  self:updateControllers()
  self:checkSave()
end

function Editor:draw()
  --
end

function Editor:controllerpressed(controller, button)
  controller = self.controllers[controller]
  local otherController = self:getOtherController(controller)
  button = button or 'trigger'

  local entity = self:getClosestEntityInRange(self.grabRange, controller.object:getPosition())

  if entity then
    if button == 'trigger' then
      if otherController.drag.active and otherController.activeEntity == entity then
        self:beginScale(controller, entity)
      else
        self:beginDrag(controller, entity)
      end
    elseif button == 'grip' then
      self:beginRotate(controller, entity)
    end
  end
end

function Editor:controllerreleased(controller, button)
  controller = self.controllers[controller]
  button = button or 'trigger'

  if button == 'trigger' then
    self:endScale(controller)
    self:endDrag(controller)
  elseif button == 'grip' then
    self:endRotate(controller)
  end
end

function Editor:refreshControllers()
  self.controllers = {}

  for i, controller in ipairs(lovr.headset.getControllers()) do
    self.controllers[controller] = {
      index = i,
      object = controller,
      currentPosition = vector(),
      lastPosition = vector(),
      activeEntity = nil,
      drag = {
        active = false,
        offset = vector()
      },
      scale = {
        active = false,
        lastDistance = 0
      },
      rotate = {
        active = false,
      }
    }
    table.insert(self.controllers, self.controllers[controller])
  end
end

function Editor:updateControllers()
  util.each(self.controllers, function(controller)
    controller.currentPosition:set(controller.object:getPosition())

    if controller.drag.active then self:updateDrag(controller) end
    if controller.rotate.active then self:updateRotate(controller) end
    if controller.scale.active then self:updateScale(controller) end

    controller.lastPosition:set(controller.currentPosition)
  end, ipairs)
end

function Editor:checkSave()
  if self.isDirty and lovr.timer.getTime() - self.lastChange > 3 then
    self.level:save()
    self.isDirty = false
  end
end

function Editor:dirty()
  self.isDirty = true
  self.lastChange = lovr.timer.getTime()
end

function Editor:generateEntities()
  local modelPath = 'art/models/'
  local texturePath = 'art/textures/'
  local modelNames = lovr.filesystem.getDirectoryItems(modelPath)
  local textureNames = lovr.filesystem.getDirectoryItems(texturePath)
  local entityNames = {}
  for i,modelName in ipairs(modelNames) do
    local name = modelName:sub(1, -5)
    entityNames[i] = name
  end

  textures = {}
  for i, textureName in ipairs(textureNames) do
    local name = textureName:sub(1, -5)
    textures[name] = textureName
  end
  models = {}
  for i, modelName in ipairs(modelNames) do
    local name = modelName:sub(1, -5)
    models[name] = modelName
  end
  
  local entities = {}
  for i, name in ipairs(entityNames) do
    local texturePathOrNil = textures[name] and texturePath..textures[name] or nil
    entities[i] = {
      modelPath = modelPath..models[name],
      texturePath = texturePathOrNil,
      transform = {
        x = 0,
        y = 1.5,
        z = 0,
        scale = .1,
        angle = 0,
        ax = 0,
        ay = 0,
        az = 0
      }
    }
  end

  return entities
end

function Editor:getOtherController(controller)
  return self.controllers[3 - controller.index]
end

function Editor:getClosestEntityInRange(range, x, y, z)
  local minDistance, closestEntity = range ^ 2, nil
  util.each(self.level.data.entities, function(entity)
    local d = (x - entity.transform.x) ^ 2 + (y - entity.transform.y) ^ 2 + (z - entity.transform.z) ^ 2
    if d < minDistance then
      minDistance = d
      closestEntity = entity
    end
  end)
  return closestEntity, math.sqrt(minDistance)
end

function Editor:beginDrag(controller, entity)
  local entityPosition = vector(entity.transform.x, entity.transform.y, entity.transform.z)
  controller.activeEntity = entity
  controller.drag.active = true
  controller.drag.offset = entityPosition - controller.currentPosition
end

function Editor:updateDrag(controller)
  if controller.scale.active or self:getOtherController(controller).scale.active then return end
  local newPosition = controller.currentPosition + controller.drag.offset
  self.level:updateEntityPosition(controller.activeEntity.index, newPosition:unpack())
  self:dirty()
end

function Editor:endDrag(controller)
  controller.drag.active = false
end

function Editor:beginRotate(controller, entity)
  controller.activeEntity = entity
  controller.rotate.active = true
end

function Editor:updateRotate(controller)
  local t = controller.activeEntity.transform
  local entityPosition = vector(t.x, t.y, t.z)

  local d1 = (controller.currentPosition - entityPosition):normalize()
  local d2 = (controller.lastPosition - entityPosition):normalize()
  local rotation = quaternion():between(d2, d1)

  self.level:updateEntityRotation(controller.activeEntity.index, rotation)
  self:dirty()
end

function Editor:endRotate(controller)
  controller.rotate.active = false
end

function Editor:beginScale(controller, entity)
  controller.scale.active = true
  controller.activeEntity = entity
  controller.scale.lastDistance = (controller.currentPosition - self:getOtherController(controller).currentPosition):length()
end

function Editor:updateScale(controller)
  local currentDistance = controller.currentPosition:distance(self:getOtherController(controller).currentPosition)
  local distanceRatio = (currentDistance / controller.scale.lastDistance)
  controller.scale.lastDistance = currentDistance

  self.level:updateEntityScale(controller.activeEntity.index, distanceRatio)
  self:dirty()
end

function Editor:endScale(controller)
  local otherController = self:getOtherController(controller)

  otherController.scale.active = false
  if otherController.drag.active then
    local entity = otherController.activeEntity
    local entityPosition = vector(entity.transform.x, entity.transform.y, entity.transform.z)
    otherController.drag.offset = entityPosition - otherController.currentPosition
  end

  controller.scale.active = false
end

return Editor
