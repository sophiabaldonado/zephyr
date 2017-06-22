local json = require('json')
local vector = require('maf').vector
local level = {}
local defaultFilename = 'levels/default.json'
local position = vector() 

function level:init(filename)
  self:load(filename)

  for i, entity in ipairs(self.data.entities) do
    entity.model = lovr.graphics.newModel(entity.modelPath, entity.texturePath)
    entity.lastPosition = vector()
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

function level:draw()
  for i, entity in ipairs(self.data.entities) do
    local t = entity.transform
    position:set(t.x, t.y, t.z)
    position:lerp(entity.lastPosition, 1 - tick.accum / tick.rate)

    entity.model:draw(position.x, position.y, position.z, t.scale, t.angle, t.ax, t.ay, t.az)
  end
end

function level:update()
  for i,entity in ipairs(self.data.entities) do
    local t = entity.transform
    entity.lastPosition:set(t.x, t.y, t.z)
  end
end

function level:save()
  local saveData = {}
  saveData.name = self.data.name
  saveData.entities = {}

  for i,entitty in ipairs(self.data.entities) do
    saveData.entities[i] = {
      transform = entitty.transform,
      modelPath = entitty.modelPath,
      texturePath = entitty.texturePath
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
