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

function util.copy(x)
  local t = type(x)
  if t ~= 'table' then return x end
  local y = {}
  for k, v in next, x, nil do y[k] = util.copy(v) end
  setmetatable(y, getmetatable(x))
  return y
end

function util.round(x)
  return math.floor(x + .5)
end

return util
