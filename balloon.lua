local input = require 'input'
local util = require 'util'
local maf = require 'maf'
local vector = maf.vector
local quaternion = maf.rotation

local position = vector()
local lastPosition = vector()
local fanPosition = vector()
local fanForce = vector()
local fanDirection = vector()
local fanRotation = quaternion()
local viewRotation = quaternion()

local balloon = {}
balloon.scale = .001
balloon.fanStrength = 20
balloon.fanRange = { .05, 1 }
balloon.fanCone = { 0, .5 }

local function affine(x, min, max)
  return (util.clamp(x, min, max) - min) / (max - min)
end

function balloon:init()
  self.model = lovr.graphics.newModel('art/mobile_balloon.obj', 'art/mobile_DIFF.png')

  self.collider = world:newCollider()
  self.collider:setMass(50)
  self.collider:setPosition(0, 1.5, 0)
  self.collider:setGravityIgnored(true)
  self.collider:setLinearDamping(.05)

  self.basket = lovr.physics.newBoxShape(.05)
  self.collider:addShape(self.basket)
  self.basket:setPosition(0, -.12, 0)
end

function balloon:update(dt)
  lastPosition:set(self.collider:getPosition())
  position:set(self.collider:getPosition())
  viewRotation:angleAxis(-viewport.rotation, 0, 1, 0)

  for i, fan in ipairs(input.fans) do
    if fan.power > 0 then
      fanPosition:set(fan.controller:getPosition())
      fanPosition:rotate(viewRotation)
      fanPosition.y = fanPosition.y + viewport.translation

      position:sub(fanPosition, fanForce)
      local distance = fanForce:length()
      fanForce:normalize()
      fanDirection:set(0, 0, -1):rotate(fanRotation:angleAxis(fan.controller:getOrientation()):mul(input.rotationOffset)):rotate(viewRotation)
      local dot = fanDirection:dot(fanForce)

      -- Scale by how turned on the fan is
      fanForce:scale(fan.power)

      -- Scale by distance so the fan is more effective up close
      fanForce:scale(1 - affine(distance, unpack(balloon.fanRange)))

      -- Scale by dot product so the fan is directional
      fanForce:scale(1 - affine(1 - math.max(dot, 0), unpack(balloon.fanCone)))

      -- Global scaling factor
      fanForce:scale(balloon.fanStrength)

      self.collider:applyForce(fanForce:unpack())
    end
  end

  -- Float down
  local vx, vy, vz = self.collider:getLinearVelocity()
  if vy > -.5 then
    self.collider:applyForce(0, -3, 0)
  end
end

function balloon:draw()
  lovr.graphics.setColor(255, 255, 255)

  position:set(self.collider:getPosition())
  position:lerp(lastPosition, 1 - tick.accum / tick.rate)

  -- Model
  local x, y, z = position:unpack()
  self.model:draw(x, y, z, self.scale, self.collider:getOrientation())
end

return balloon
