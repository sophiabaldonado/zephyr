local input = require 'input'
local util = require 'util'
local maf = require 'maf'
local vector = maf.vector
local quaternion = maf.rotation

local position = vector()
local fanPosition = vector()
local fanForce = vector()
local fanDirection = vector()
local fanRotation = quaternion()

local balloon = {}
balloon.scale = .005
balloon.fanRange = { .25, 1 }
balloon.fanCone = { 0, .5 }

local function affine(x, min, max)
  return (util.clamp(x, min, max) - min) / (max - min)
end

function balloon:init()
  self.model = lovr.graphics.newModel('art/mobile_balloon.obj', 'art/mobile_DIFF.png')

  self.collider = world:newCollider()
  self.collider:setPosition(0, 1.5, 0)
  self.collider:setGravityIgnored(true)
  self.collider:setLinearDamping(.025)

  self.basket = lovr.physics.newBoxShape(.075)
  self.collider:addShape(self.basket)
  self.basket:setPosition(0, -.2, 0)
end

function balloon:update(dt)
  position:set(self.collider:getPosition())

  for i, fan in ipairs(input.fans) do
    if fan.power > 0 then
      fanPosition:set(fan.controller:getPosition())
      position:sub(fanPosition, fanForce)
      local distance = fanForce:length()
      fanForce:normalize()
      fanDirection:set(0, 0, -1):rotate(fanRotation:angleAxis(fan.controller:getOrientation()))
      local dot = fanDirection:dot(fanForce)

      -- Scale by how turned on the fan is
      fanForce:scale(fan.power)

      -- Scale by distance so the fan is more effective up close
      fanForce:scale(1 - affine(distance, unpack(balloon.fanRange)))

      -- Scale by dot product so the fan is directional
      fanForce:scale(1 - affine(1 - math.max(dot, 0), unpack(balloon.fanCone)))

      self.collider:applyForce(fanForce:unpack())
    end
  end
end

function balloon:draw()
  lovr.graphics.setColor(255, 255, 255)

  -- Model
  local x, y, z = self.collider:getPosition()
  self.model:draw(x, y, z, self.scale, self.collider:getOrientation())

  -- Basket
  if debug then
    lovr.graphics.push()
    lovr.graphics.translate(self.collider:getPosition())
    local x, y, z = self.basket:getPosition()
    local size = self.basket:getDimensions()
    lovr.graphics.cube('fill', x, y, z, size)
    lovr.graphics.pop()
  end
end

return balloon