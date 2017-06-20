local level = {}

function level:init(data)
  self.data = data
  self.entities = {}

  for i,entity in ipairs(data.entities) do
    local t = entity.transform
    self.entities[i] = {
      model = lovr.graphics.newModel(entity.model, entity.texture),
      transform = { t.x, t.y, t.z, t.scale, t.angle, t.ax, t.ay, t.az }
    }
  end
end

function level:updateEntityTransform(entityIndex)
  local t = self.data.entities[entityIndex].transform
  self.entities[entityIndex].transform = { t.x, t.y, t.z, t.scale, t.angle, t.ax, t.ay, t.az }
end

function level:draw()
  for i,entity in ipairs(self.entities) do
    entity.model:draw(unpack(entity.transform))
  end
end


return level