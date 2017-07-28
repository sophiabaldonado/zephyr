local Editor = require 'editor'
local json = require('json')
local vector = require('maf').vector
local quaternion = require('maf').quat
local level = {}
local defaultFilename = 'levels/default.json'
local position = vector()

function level:init(filename)
  self:load(filename)

  for i, entity in ipairs(self.data.entities) do
    entity.index = i
    entity.model = entity.texturePath and lovr.graphics.newModel(entity.modelPath, entity.texturePath) or lovr.graphics.newModel(entity.modelPath)
    entity.lastPosition = vector()
    entity.lastRotation = quaternion()
  end
end

function level:updateEntityPosition(entityIndex, x, y, z)
  local t = self.data.entities[entityIndex].transform
  t.x, t.y, t.z = x, y, z
end

function level:updateEntityScale(entityIndex, scaleMultiplier)
  local t = self.data.entities[entityIndex].transform
  t.scale = t.scale * scaleMultiplier
end

function level:updateEntityRotation(entityIndex, angle, ax, ay, az)
  local t = self.data.entities[entityIndex].transform
  --local ogRotation = quaternion():angleAxis(t.angle, t.ax, t.ay, t.az)

  --t.angle, t.ax, t.ay, t.az = (rotation * ogRotation):getAngleAxis()
	t.angle, t.ax, t.ay, t.az = angle, ax, ay, az
end

function level:addEntity(entityData)
  local newEntity = entityData
  newEntity.lastPosition = vector()
  newEntity.lastRotation = quaternion()

  table.insert(self.data.entities, newEntity)
  newEntity.index = #self.data.entities
end

function level:draw()
  for i, entity in ipairs(self.data.entities) do
    local lerped = self:lerp(entity)
    local t = entity.transform
    entity.model:draw(lerped.x, lerped.y, lerped.z, lerped.scale, lerped.angle, lerped.ax, lerped.ay, lerped.az)
  end
end

function level:lerp(entity)
  local t = entity.transform
  position:set(t.x, t.y, t.z)
  position:lerp(entity.lastPosition, 1 - tick.accum / tick.rate)

  for _, controller in ipairs(Editor.controllers) do
    local otherController = Editor:getOtherController(controller)
    if controller.drag.active and controller.activeEntity == entity and not controller.scale.active and (not otherController or not otherController.scale.active) then
      position:set(controller.object:getPosition())
      position:add(controller.drag.offset)
    end
  end

  local scale = t.scale
  local s = scale + (entity.lastScale - scale) *  (1 - tick.accum / tick.rate)

  local rot = quaternion():angleAxis(t.angle, t.ax, t.ay, t.az)
  rot:slerp(entity.lastRotation, 1 - tick.accum / tick.rate)
  local angle, ax, ay, az = rot:getAngleAxis()

  return { x = position.x, y = position.y, z = position.z, scale = s, angle = angle, ax = ax, ay = ay, az = az }
end

function level:update()
  for i,entity in ipairs(self.data.entities) do
    local t = entity.transform
    entity.lastPosition:set(t.x, t.y, t.z)
    entity.lastScale = entity.transform.scale
    entity.lastRotation:angleAxis(t.angle, t.ax, t.ay, t.az)
  end
end

function level:save()
  local saveData = {}
  saveData.name = self.data.name
  saveData.entities = {}

  for i,entity in ipairs(self.data.entities) do
    saveData.entities[i] = {
      transform = entity.transform,
      modelPath = entity.modelPath,
      texturePath = entity.texturePath
    }
  end

  lovr.filesystem.createDirectory('levels')
  lovr.filesystem.write(self.filename, json.encode(saveData))
end

function level:load(filename)
  self.filename = filename
  filename = lovr.filesystem.exists(filename) and filename or defaultFilename
  self.data = json.decode(lovr.filesystem.read(filename))
end


return level
