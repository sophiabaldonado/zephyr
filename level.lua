local level = {}

function level:init(data)
  self.data = data
  self.models = {}

  for i,entity in ipairs(self.data.entities) do
    self.models[i] = lovr.graphics.newModel(entity.model, entity.texture)
  end
end

function level:updateEntityPosition(entityIndex, x, y, z)
  local t = self.data.entities[entityIndex].transform
  t.x, t.y, t.z = x, y, z
end

function level:draw()
  for i,entity in ipairs(self.data.entities) do
    local t = entity.transform
    self.models[i]:draw(t.x, t.y, t.z, t.scale, t.angle, t.ax, t.ay, t.az)
  end
end


return level