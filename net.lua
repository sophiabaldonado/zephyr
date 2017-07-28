local enet = require 'enet'

local url = 'localhost:6789'

local net = {}

function net:init()
	print('connecting...', url)
	self.host = enet.host_create()
	self.server = self.host:connect(url)
end

function net:update(dt)
	local event = self.host:service(0)
	if event and event.type == 'connect' then
		print('connected!')
	end
end

return net
