local input = require 'input'
local util = require 'util'
local maf = require 'maf'
local vector = maf.vector

local position = vector()
local fanPosition = vector()
local fanForce = vector()

local balloon = {}
balloon.scale = .005
balloon.forceRange = { .25, 1 }

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
  local minDistance, maxDistance = unpack(balloon.forceRange)
  position:set(self.collider:getPosition())

  for i, fan in ipairs(input.fans) do
    if fan.power > 0 then
      fanPosition:set(fan.controller:getPosition())
      position:sub(fanPosition, fanForce)
      local distance = fanForce:length()
      fanForce:normalize()
      fanForce:scale(fan.power)
      fanForce:scale(1 - ((util.clamp(distance, minDistance, maxDistance) - minDistance) / (maxDistance - minDistance)))

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