local util = {}

function util.lerp(x, y, z)
  return x + (y - x) * z
end

function util.clamp(x, min, max)
  return math.max(math.min(x, max), min)
end

return util