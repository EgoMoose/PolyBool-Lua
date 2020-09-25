-- (c) Copyright 2016, Sean Connelly (@voidqk), http:--syntheti.cc
-- MIT License
-- Project Home: https:--github.com/voidqk/polybooljs
-- Converted to Lua by EgoMoose

--
-- simple linked list implementation that allows you to traverse down nodes and save positions
--

local function iif(bool, a, b)
	if (bool) then return a end
	return b
end

local LinkedList = {
	create = function()
		local my
		my = {
			root = { root = true, next = nil },
			exists = function(node)
				if (node == nil or node == my.root) then
					return false
				end
				return true
			end,
			isEmpty = function()
				return my.root.next == nil
			end,
			getHead = function()
				return my.root.next
			end,
			insertBefore = function(node, check)
				local last = my.root
				local here = my.root.next
				while (here ~= nil) do
					if (check(here)) then
						node.prev = here.prev
						node.next = here
						here.prev.next = node
						here.prev = node
						return
					end
					last = here
					here = here.next
				end
				last.next = node
				node.prev = last
				node.next = nil
			end,
			findTransition = function(check)
				local prev = my.root
				local here = my.root.next
				while (here ~= nil) do
					if (check(here)) then
						break
					end
					prev = here
					here = here.next
				end
				return {
					before = iif(prev == my.root, nil, prev),
					after = here,
					insert = function(node)
						node.prev = prev
						node.next = here
						prev.next = node
						if (here ~= nil) then
							here.prev = node
						end
						return node
					end
				}
			end
		}
		return my
	end,
	node = function(data)
		data.prev = nil
		data.next = nil
		data.remove = function()
			data.prev.next = data.next
			if (data.next) then
				data.next.prev = data.prev
			end
			data.prev = nil
			data.next = nil
		end
		return data
	end
}

return LinkedList