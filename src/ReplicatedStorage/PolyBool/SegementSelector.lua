-- (c) Copyright 2016, Sean Connelly (@voidqk), http:--syntheti.cc
-- MIT License
-- Project Home: https:--github.com/voidqk/polybooljs
-- Converted to Lua by EgoMoose

--
-- filter a list of segments based on boolean operations
--

local function iif(bool, a, b)
	if (bool) then return a end
	return b
end

local function select(segments, selection, buildLog)
	local result = {}
	for _, seg in next, segments do
		local index =
			iif(seg.myFill.above, 8, 0) +
			iif(seg.myFill.below, 4, 0) +
			iif((seg.otherFill and seg.otherFill.above), 2, 0) +
			iif((seg.otherFill and seg.otherFill.below), 1, 0) + 1
		if (selection[index] ~= 0) then
			-- copy the segment to the results, while also calculating the fill status
			table.insert(result, {
				id = buildLog and buildLog.segmentId() or -1,
				start = seg.start,
				finish = seg.finish,
				myFill = {
					above = selection[index] == 1, -- 1 if filled above
					below = selection[index] == 2  -- 2 if filled below
				},
				otherFill = nil
			})
		end
	end

	if (buildLog) then
		buildLog.selected(result)
	end

	return result
end

local SegmentSelector = {
	union = function(segments, buildLog) -- primary | secondary
		-- above1 below1 above2 below2    Keep?               Value
		--    0      0      0      0   =>   no                  0
		--    0      0      0      1   =>   yes filled below    2
		--    0      0      1      0   =>   yes filled above    1
		--    0      0      1      1   =>   no                  0
		--    0      1      0      0   =>   yes filled below    2
		--    0      1      0      1   =>   yes filled below    2
		--    0      1      1      0   =>   no                  0
		--    0      1      1      1   =>   no                  0
		--    1      0      0      0   =>   yes filled above    1
		--    1      0      0      1   =>   no                  0
		--    1      0      1      0   =>   yes filled above    1
		--    1      0      1      1   =>   no                  0
		--    1      1      0      0   =>   no                  0
		--    1      1      0      1   =>   no                  0
		--    1      1      1      0   =>   no                  0
		--    1      1      1      1   =>   no                  0
		return select(segments, {
			0, 2, 1, 0,
			2, 2, 0, 0,
			1, 0, 1, 0,
			0, 0, 0, 0
		}, buildLog)
	end,
	intersect = function(segments, buildLog) -- primary & secondary
		-- above1 below1 above2 below2    Keep?               Value
		--    0      0      0      0   =>   no                  0
		--    0      0      0      1   =>   no                  0
		--    0      0      1      0   =>   no                  0
		--    0      0      1      1   =>   no                  0
		--    0      1      0      0   =>   no                  0
		--    0      1      0      1   =>   yes filled below    2
		--    0      1      1      0   =>   no                  0
		--    0      1      1      1   =>   yes filled below    2
		--    1      0      0      0   =>   no                  0
		--    1      0      0      1   =>   no                  0
		--    1      0      1      0   =>   yes filled above    1
		--    1      0      1      1   =>   yes filled above    1
		--    1      1      0      0   =>   no                  0
		--    1      1      0      1   =>   yes filled below    2
		--    1      1      1      0   =>   yes filled above    1
		--    1      1      1      1   =>   no                  0
		return select(segments, {
			0, 0, 0, 0,
			0, 2, 0, 2,
			0, 0, 1, 1,
			0, 2, 1, 0
		}, buildLog)
	end,
	difference = function(segments, buildLog) -- primary - secondary
		-- above1 below1 above2 below2    Keep?               Value
		--    0      0      0      0   =>   no                  0
		--    0      0      0      1   =>   no                  0
		--    0      0      1      0   =>   no                  0
		--    0      0      1      1   =>   no                  0
		--    0      1      0      0   =>   yes filled below    2
		--    0      1      0      1   =>   no                  0
		--    0      1      1      0   =>   yes filled below    2
		--    0      1      1      1   =>   no                  0
		--    1      0      0      0   =>   yes filled above    1
		--    1      0      0      1   =>   yes filled above    1
		--    1      0      1      0   =>   no                  0
		--    1      0      1      1   =>   no                  0
		--    1      1      0      0   =>   no                  0
		--    1      1      0      1   =>   yes filled above    1
		--    1      1      1      0   =>   yes filled below    2
		--    1      1      1      1   =>   no                  0
		return select(segments, {
			0, 0, 0, 0,
			2, 0, 2, 0,
			1, 1, 0, 0,
			0, 1, 2, 0
		}, buildLog)
	end,
	differenceRev = function(segments, buildLog) -- secondary - primary
		-- above1 below1 above2 below2    Keep?               Value
		--    0      0      0      0   =>   no                  0
		--    0      0      0      1   =>   yes filled below    2
		--    0      0      1      0   =>   yes filled above    1
		--    0      0      1      1   =>   no                  0
		--    0      1      0      0   =>   no                  0
		--    0      1      0      1   =>   no                  0
		--    0      1      1      0   =>   yes filled above    1
		--    0      1      1      1   =>   yes filled above    1
		--    1      0      0      0   =>   no                  0
		--    1      0      0      1   =>   yes filled below    2
		--    1      0      1      0   =>   no                  0
		--    1      0      1      1   =>   yes filled below    2
		--    1      1      0      0   =>   no                  0
		--    1      1      0      1   =>   no                  0
		--    1      1      1      0   =>   no                  0
		--    1      1      1      1   =>   no                  0
		return select(segments, {
			0, 2, 1, 0,
			0, 0, 1, 1,
			0, 2, 0, 2,
			0, 0, 0, 0
		}, buildLog)
	end,
	xor = function(segments, buildLog) -- primary ^ secondary
		-- above1 below1 above2 below2    Keep?               Value
		--    0      0      0      0   =>   no                  0
		--    0      0      0      1   =>   yes filled below    2
		--    0      0      1      0   =>   yes filled above    1
		--    0      0      1      1   =>   no                  0
		--    0      1      0      0   =>   yes filled below    2
		--    0      1      0      1   =>   no                  0
		--    0      1      1      0   =>   no                  0
		--    0      1      1      1   =>   yes filled above    1
		--    1      0      0      0   =>   yes filled above    1
		--    1      0      0      1   =>   no                  0
		--    1      0      1      0   =>   no                  0
		--    1      0      1      1   =>   yes filled below    2
		--    1      1      0      0   =>   no                  0
		--    1      1      0      1   =>   yes filled above    1
		--    1      1      1      0   =>   yes filled below    2
		--    1      1      1      1   =>   no                  0
		return select(segments, {
			0, 2, 1, 0,
			2, 0, 0, 1,
			1, 0, 0, 2,
			0, 1, 2, 0
		}, buildLog)
	end
}

return SegmentSelector