local Balloon = {}
Balloon.scale = .005

function Balloon:init()
  self.model = lovr.graphics.newModel('art/mobile_balloon.obj', 'art/mobile_DIFF.png')

  self.collider = world:newCollider()
  self.collider:setPosition(0, .25, -1)
  self.collider:setGravityIgnored(true)

  self.basket = lovr.physics.newBoxShape(.075)
  self.collider:addShape(self.basket)
  self.basket:setPosition(0, -.2, 0)
end

function Balloon:draw()
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

return Balloon