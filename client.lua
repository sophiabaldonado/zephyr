local Client = {}

function Client:init()
	local self = setmetatable({}, { __index = Client })

	return self
end

function Client:update(dt)
	--
end

return Client
