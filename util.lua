local util = {}

function util.lerp(x, y, z)
  return x + (y - x) * z
end

function util.clamp(x, min, max)
  return math.max(math.min(x, max), min)
end

function util.each(t, f, iterator)
  iterator = iterator or pairs
  for k, v in iterator(t) do
    f(v, k)
  end
end

return util