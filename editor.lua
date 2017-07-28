local Editor = {}

local maf = require 'maf'
local vector = maf.vector
local quaternion = maf.quat
local util = require 'util'

Editor.satchelItemSize = .095
Editor.headPosition = vector()

function Editor:init(level)
  self.active = true
  self:refreshControllers()
  self.level = level
  self.isDirty = false
  self.lastChange = lovr.timer.getTime()
  self.satchel = self:generateEntities()
  self.menu = {
    active = false,
    controller = {}
  }
end

function Editor:update(dt)
  self:checkSave()
  util.each(self.level.data.entities, function(entity)
    entity.wasHovered = entity.wasHovered or {}
    entity.isHovered = entity.isHovered or {}
    util.each(self.controllers, function(controller)
      entity.wasHovered[controller] = entity.isHovered[controller]
      entity.isHovered[controller] = self:isHoveredByController(entity, controller)
      if (not entity.wasHovered[controller] and entity.isHovered[controller]) then
        if not controller.drag.active and not controller.scale.active and not controller.rotate.active then
          controller.object:vibrate(.002)
        end
      end
    end, ipairs)
  end)
end

function Editor:draw()
  self:updateControllers()

  if self.menu.active then self:drawSatchel() end

  util.each(self.controllers, function(controller)
    local x, y, z = controller.object:getPosition()
    --controller.model:draw(x, y, z, 1, controller.object:getOrientation())

    if controller.scale.active then
      lovr.graphics.setColor(0, 0, 255)
    elseif controller.drag.active then
      lovr.graphics.setColor(0, 255, 0)
    else
      lovr.graphics.setColor(255, 255, 255)
    end

    lovr.graphics.cube('fill', x, y, z, .005, controller.object:getOrientation())

    if controller.rotate.active then
      lovr.graphics.setColor(255, 255, 255)
      local t = controller.activeEntity.transform
      lovr.graphics.cylinder(t.x, t.y, t.z, x, y, z, .003, .003)
    end
  end, ipairs)

  local width, depth = lovr.headset.getBoundsDimensions()
  width, depth = math.ceil(width), math.ceil(depth)
  for x = -width, width, .25 do
    local alpha = math.floor(x) == x and 200 or 50
    lovr.graphics.setColor(255, 255, 255, alpha)
    lovr.graphics.line(x, 0, -depth, x, 0, depth)
  end

  for z = -depth, depth, .25 do
    local alpha = math.floor(z) == z and 200 or 50
    lovr.graphics.setColor(255, 255, 255, alpha)
    lovr.graphics.line(-width, 0, z, width, 0, z)
  end

  util.each(self.level.data.entities, function(entity)
    local lerpd = self.level:lerp(entity)
    local minx, maxx, miny, maxy, minz, maxz = entity.model:getAABB()
    local w, h, d = (maxx - minx) * lerpd.scale, (maxy - miny) * lerpd.scale, (maxz - minz) * lerpd.scale
    local cx, cy, cz = (maxx + minx) / 2 * lerpd.scale, (maxy + miny) / 2 * lerpd.scale, (maxz + minz) / 2 * lerpd.scale
    lovr.graphics.push()
    lovr.graphics.translate(lerpd.x, lerpd.y, lerpd.z)
    lovr.graphics.rotate(lerpd.angle, lerpd.ax, lerpd.ay, lerpd.az)
    lovr.graphics.setColor(255, 255, 255, 100 + ((entity.isHovered[self.controllers[1]] or entity.isHovered[self.controllers[2]]) and 100 or 0))
    lovr.graphics.box('line', cx, cy, cz, w, h, d)
    lovr.graphics.setColor(255, 255, 255)
    lovr.graphics.pop()
  end)
end

function Editor:controllerpressed(controller, button)
  controller = self.controllers[controller]
  local otherController = self:getOtherController(controller)
  button = button or 'trigger'

  local satchelItem = self:getClosestSatchelItemInRange(self.satchelItemSize, controller.object:getPosition())
  if self.menu.active and satchelItem then
    if button == 'trigger' then
      self.level:addEntity(util.copy(satchelItem))
    end
  end

  local entity = self:getClosestEntity(controller)

  if entity then
    if button == 'trigger' then
      if otherController and otherController.drag.active and otherController.activeEntity == entity then
        self:beginScale(controller, entity)
      else
        self:beginDrag(controller, entity)
      end
    elseif button == 'grip' then
      self:beginRotate(controller, entity)
    end
  end

  if button == 'menu' and not self.menu.active then
    self.menu.active = true
    self.menu.controller = controller
    self:setSatchelItems()
  elseif button =='menu' then
    self.menu.active = false
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
      model = controller:newModel(),
      currentPosition = vector(),
      lastPosition = vector(),
      activeEntity = nil,
      drag = {
        active = false,
        offset = vector(),
        counter = 0
      },
      scale = {
        active = false,
        lastDistance = 0,
        counter = 0
      },
      rotate = {
        active = false,
        lastRotation = quaternion(),
        counter = 0
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
  local modelPath, texturePath = 'art/models/', 'art/textures/'
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
    local model = texturePathOrNil and lovr.graphics.newModel(modelPath..models[name], texturePathOrNil) or lovr.graphics.newModel(modelPath..models[name])

    entities[i] = {
      modelPath = modelPath..models[name],
      texturePath = texturePathOrNil,
      transform = {
        x = 0,
        y = 0,
        z = 0,
        scale = self:constrainScale(model),
        angle = 0,
        ax = 0,
        ay = 0,
        az = 0,
      },
      model = model
    }
  end

  return entities
end

function Editor:createMenuGrid(total, direction)
  local spacing = self.satchelItemSize * 2.5
  local rowCount = 6
  local radius = .25

  local grid = {}
  local startingY = 1.5
  local y = startingY
  for i = 1, total, rowCount do
    for j = 1, rowCount do
      local angle = (((j - 1) / (rowCount - 1)) * 2) - 1
      local r = quaternion():angleAxis(angle, 0, 1, 0)
      local p = (r * direction) * radius
      table.insert(grid, { x = p.x, y = y, z = p.z })
    end
    y = y - spacing
  end
  return grid
end

function Editor:setSatchelItems()
  for i, entity in ipairs(self.satchel) do
    local menu = self.menu
    local t = entity.transform
    local pos = menu.controller.currentPosition

    local direction = pos - self.headPosition:set(lovr.headset.getPosition())
    direction.y = 0
    local grid = self:createMenuGrid(#self.satchel, direction:normalize())

    t.x, t.y, t.z = grid[i].x, grid[i].y, grid[i].z
    t.x, t.z = t.x + pos.x, t.z + pos.z
  end
end

function Editor:drawSatchel()
  for i, entity in ipairs(self.satchel) do
    local t = entity.transform
    entity.model:draw(t.x, t.y, t.z, t.scale, lovr.timer.getTime() / 5, 0, 1, 0)
  end
end

function Editor:constrainScale(model)
  local minx, maxx, miny, maxy, minz, maxz = model:getAABB()
  local width, height, depth = maxx - minx, maxy - miny, maxz - minz
  local max = math.max(width, height, depth)

  return self.satchelItemSize / max
end

function Editor:getClosestSatchelItemInRange(range, x, y, z)
  local minDistance, closestEntity = range ^ 2, nil
  util.each(self.satchel, function(entity)
    local d = (x - entity.transform.x) ^ 2 + (y - entity.transform.y) ^ 2 + (z - entity.transform.z) ^ 2
    if d < minDistance then
      minDistance = d
      closestEntity = entity
    end
  end)
  return closestEntity, math.sqrt(minDistance)
end

function Editor:getOtherController(controller)
  return self.controllers[3 - controller.index]
end

function Editor:getClosestEntity(controller)
  local x, y, z = controller.object:getPosition()
  local minDistance, closestEntity = math.huge, nil
  util.each(self.level.data.entities, function(entity)
    local d = (x - entity.transform.x) ^ 2 + (y - entity.transform.y) ^ 2 + (z - entity.transform.z) ^ 2
    if d < minDistance and Editor:isHoveredByController(entity, controller) then
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
  controller.drag.counter = 0
end

local tmpVector = vector()
function Editor:updateDrag(controller)
  local otherController = self:getOtherController(controller)
  if controller.scale.active or (otherController and otherController.scale.active) then return end
  local newPosition = controller.currentPosition + controller.drag.offset
  local t = controller.activeEntity.transform
  tmpVector:set(t.x, t.y, t.z)
  tmpVector:sub(newPosition)
  controller.drag.counter = controller.drag.counter + tmpVector:length()
  if controller.drag.counter >= .1 then
    controller.object:vibrate(.001)
    controller.drag.counter = 0
  end
  self.level:updateEntityPosition(controller.activeEntity.index, newPosition:unpack())
  self:dirty()
end

function Editor:endDrag(controller)
  controller.drag.active = false
end

function Editor:beginRotate(controller, entity)
  controller.activeEntity = entity
  controller.rotate.active = true
  controller.rotate.lastRotation:angleAxis(controller.object:getOrientation())
end

local tmpquat = quaternion()
function Editor:updateRotate(controller)
  local t = controller.activeEntity.transform
  local entityPosition = vector(t.x, t.y, t.z)

  local d1 = (controller.currentPosition - entityPosition):normalize()
  local d2 = (controller.lastPosition - entityPosition):normalize()
  local rotation = quaternion():between(d2, d1)

	local x, y, z = controller.object:getPosition()
	local angle, ax, ay, az = lovr.math.lookAt(t.x, t.y, t.z, x, y, z, 0, 1, 0)

  --local delta = tmpquat:angleAxis(controller.object:getOrientation()):mul(controller.rotate.lastRotation:inverse())
  --controller.rotate.counter = controller.rotate.counter + tmpquat:getAngleAxis()
  controller.rotate.counter = controller.rotate.counter + (controller.currentPosition - controller.lastPosition):length()
  if controller.rotate.counter >= .1 then
    controller.object:vibrate(.001)
    controller.rotate.counter = 0
  end

  controller.rotate.lastRotation:angleAxis(controller.object:getOrientation())

  --self.level:updateEntityRotation(controller.activeEntity.index, delta)

  self.level:updateEntityRotation(controller.activeEntity.index, angle, ax, ay, az)
  self:dirty()
end

function Editor:endRotate(controller)
  controller.rotate.active = false
end

function Editor:beginScale(controller, entity)
  controller.scale.active = true
  controller.activeEntity = entity
  local otherController = self:getOtherController(controller)
  controller.scale.counter = 0
  controller.scale.lastDistance = (controller.currentPosition - otherController.currentPosition):length()
end

function Editor:updateScale(controller)
  local currentDistance = controller.currentPosition:distance(self:getOtherController(controller).currentPosition)
  local distanceRatio = (currentDistance / controller.scale.lastDistance)
  controller.scale.counter = controller.scale.counter + math.abs(currentDistance - controller.scale.lastDistance)
  if controller.scale.counter >= .1 then
    controller.object:vibrate(.001)
    self:getOtherController(controller).object:vibrate(.001)
    controller.scale.counter = 0
  end
  controller.scale.lastDistance = currentDistance

  self.level:updateEntityScale(controller.activeEntity.index, distanceRatio)
  self:dirty()
end

function Editor:endScale(controller)
  local otherController = self:getOtherController(controller)

  if otherController then
    otherController.scale.active = false
    if otherController.drag.active then
      local entity = otherController.activeEntity
      local entityPosition = vector(entity.transform.x, entity.transform.y, entity.transform.z)
      otherController.drag.offset = entityPosition - otherController.currentPosition
    end
  end

  controller.scale.active = false
end

local transform = lovr.math.newTransform()
function Editor:isHoveredByController(entity, controller)
  if not controller then return false end
  local t = entity.transform
  local minx, maxx, miny, maxy, minz, maxz = entity.model:getAABB()
  minx, maxx, miny, maxy, minz, maxz = t.x + minx * t.scale, t.x + maxx * t.scale, t.y + miny * t.scale, t.y + maxy * t.scale, t.z + minz * t.scale, t.z + maxz * t.scale
  transform:origin()
  transform:translate(t.x, t.y, t.z)
  transform:rotate(-t.angle, t.ax, t.ay, t.az)
  local x, y, z = controller.object:getPosition()
  x, y, z = transform:transformPoint(x - t.x, y - t.y, z - t.z)
  return x >= minx and x <= maxx and y >= miny and y <= maxy and z >= minz and z <= maxz
end

function Editor:isHovered(entity)
  for _, controller in ipairs(self.controllers) do
    if self:isHoveredByController(entity, controller) then
      return controller
    end
  end
end

return Editor
