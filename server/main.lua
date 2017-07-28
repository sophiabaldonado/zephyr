local enet = require 'enet'

local clients = {}

function lovr.load()
	host = enet.host_create('localhost:6789')
	print('listening on localhost:6789')
end

function lovr.update(dt)
	local event = host:service(100)
	if event and event.type == 'connect' then
		print('Someone connected!', event.data, event.peer)
		table.insert(clients, {
			peer = event.peer
		})
	end
end
