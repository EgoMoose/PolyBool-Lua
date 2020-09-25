-- (c) Copyright 2016, Sean Connelly (@voidqk), http:--syntheti.cc
-- MIT License
-- Project Home: https:--github.com/voidqk/polybooljs
-- Converted to Lua by EgoMoose

--
-- provides the raw computation functions that takes epsilon into account
--
-- zero is defined to be between (-epsilon, epsilon) exclusive
--

local function iif(bool, a, b)
	if (bool) then return a end
	return b
end

function Epsilon(eps)
	if (type(eps) ~= 'number') then
		eps = 0.0000000001; -- sane default? sure why not
	end
	
	local my
	my = {
		epsilon = function(v)
			if (type(v) == 'number') then
				eps = v
			end
			return eps
		end,
		pointAboveOrOnLine = function(pt, left, right)
			local Ax = left[1]
			local Ay = left[2]
			local Bx = right[1]
			local By = right[2]
			local Cx = pt[1]
			local Cy = pt[2]
			return (Bx - Ax) * (Cy - Ay) - (By - Ay) * (Cx - Ax) >= -eps
		end,
		pointBetween = function(p, left, right)
			-- p must be collinear with left->right
			-- returns false if p == left, p == right, or left == right
			local d_py_ly = p[2] - left[2]
			local d_rx_lx = right[1] - left[1]
			local d_px_lx = p[1] - left[1]
			local d_ry_ly = right[2] - left[2]

			local dot = d_px_lx * d_rx_lx + d_py_ly * d_ry_ly
			-- if `dot` is 0, then `p` == `left` or `left` == `right` (reject)
			-- if `dot` is less than 0, then `p` is to the left of `left` (reject)
			if (dot < eps) then
				return false
			end

			local sqlen = d_rx_lx * d_rx_lx + d_ry_ly * d_ry_ly
			-- if `dot` > `sqlen`, then `p` is to the right of `right` (reject)
			-- therefore, if `dot - sqlen` is greater than 0, then `p` is to the right of `right` (reject)
			if (dot - sqlen > -eps) then
				return false
			end

			return true
		end,
		pointsSameX = function(p1, p2)
			return math.abs(p1[1] - p2[1]) < eps
		end,
		pointsSameY = function(p1, p2)
			return math.abs(p1[2] - p2[2]) < eps
		end,
		pointsSame = function(p1, p2)
			return my.pointsSameX(p1, p2) and my.pointsSameY(p1, p2)
		end,
		pointsCompare = function(p1, p2)
			-- returns -1 if p1 is smaller, 1 if p2 is smaller, 0 if equal
			if (my.pointsSameX(p1, p2)) then
				return iif(my.pointsSameY(p1, p2), 0, iif(p1[2] < p2[2], -1, 1))
			end
			return iif(p1[1] < p2[1], -1, 1)
		end,
		pointsCollinear = function(pt1, pt2, pt3)
			-- does pt1->pt2->pt3 make a straight line?
			-- essentially this is just checking to see if the slope(pt1->pt2) === slope(pt2->pt3)
			-- if slopes are equal, then they must be collinear, because they share pt2
			local dx1 = pt1[1] - pt2[1]
			local dy1 = pt1[2] - pt2[2]
			local dx2 = pt2[1] - pt3[1]
			local dy2 = pt2[2] - pt3[2]
			return math.abs(dx1 * dy2 - dx2 * dy1) < eps
		end,
		linesIntersect = function(a0, a1, b0, b1)
			-- returns false if the lines are coincident (e.g., parallel or on top of each other)
			--
			-- returns an object if the lines intersect:
			--   {
			--     pt: [x, y],    where the intersection point is at
			--     alongA: where intersection point is along A,
			--     alongB: where intersection point is along B
			--   }
			--
			--  alongA and alongB will each be one of: -2, -1, 0, 1, 2
			--
			--  with the following meaning:
			--
			--    -2   intersection point is before segment's first point
			--    -1   intersection point is directly on segment's first point
			--     0   intersection point is between segment's first and second points (exclusive)
			--     1   intersection point is directly on segment's second point
			--     2   intersection point is after segment's second point
			local adx = a1[1] - a0[1]
			local ady = a1[2] - a0[2]
			local bdx = b1[1] - b0[1]
			local bdy = b1[2] - b0[2]

			local axb = adx * bdy - ady * bdx
			if (math.abs(axb) < eps) then
				return false; -- lines are coincident
			end

			local dx = a0[1] - b0[1]
			local dy = a0[2] - b0[2]

			local A = (bdx * dy - bdy * dx) / axb
			local B = (adx * dy - ady * dx) / axb

			local ret = {
				alongA = 0,
				alongB = 0,
				pt = {
					a0[1] + A * adx,
					a0[2] + A * ady
				}
			};

			-- categorize where intersection point is along A and B

			if (A <= -eps) then
				ret.alongA = -2
			elseif (A < eps) then
				ret.alongA = -1
			elseif (A - 1 <= -eps) then
				ret.alongA = 0
			elseif (A - 1 < eps) then
				ret.alongA = 1
			else
				ret.alongA = 2
			end

			if (B <= -eps) then
				ret.alongB = -2
			elseif (B < eps) then
				ret.alongB = -1
			elseif (B - 1 <= -eps) then
				ret.alongB = 0
			elseif (B - 1 < eps) then
				ret.alongB = 1
			else
				ret.alongB = 2
			end

			return ret
		end,
		pointInsideRegion = function(pt, region)
			local x = pt[1]
			local y = pt[2]
			local last_x = region[#region][1]
			local last_y = region[#region][2]
			local inside = false
			for i = 1, #region do
				local curr_x = region[i][1]
				local curr_y = region[i][2]

				-- if y is between curr_y and last_y, and
				-- x is to the right of the boundary created by the line
				if ((curr_y - y > eps) ~= (last_y - y > eps) and (last_x - curr_x) * (y - curr_y) / (last_y - curr_y) + curr_x - x > eps) then
					inside = not inside
				end

				last_x = curr_x
				last_y = curr_y
			end
			return inside
		end
	}
	return my;
end

return Epsilon