-- CONSTANTS
local DEPTH = 10

local WEDGE = Instance.new("WedgePart")
WEDGE.Anchored = true
WEDGE.TopSurface = Enum.SurfaceType.Smooth
WEDGE.BottomSurface = Enum.SurfaceType.Smooth

local FRAME = Instance.new("Frame")
FRAME.BorderSizePixel = 0
FRAME.Size = UDim2.new(0, 0, 0, 0)
FRAME.BackgroundColor3 = Color3.new(1, 1, 1)

-- Functions

local function draw(properties)
	local frame = FRAME:Clone()
	for k, v in next, properties do
		frame[k] = v
	end
	return frame
end

local function rayPlane(p, v, o, n)
	local r = p - o
	local t = -r:Dot(n) / v:Dot(n)
	return p + t*v, t
end

local function point(p)
	return draw({
		AnchorPoint = Vector2.new(0.5, 0.5);
		Position = UDim2.new(0, p.x, 0, p.y);
		Size = UDim2.new(0, 4, 0, 4);
		BackgroundColor3 = Color3.new(0, 1, 0);
	})
end

local function line(a, b)
	local v = (b - a)
	local m = (a + b) / 2
	
	return draw({
		AnchorPoint = Vector2.new(0.5, 0.5);
		Position = UDim2.new(0, m.x, 0, m.y);
		Size = UDim2.new(0, 2, 0, v.Magnitude);
		Rotation = math.deg(math.atan2(v.y, v.x)) - 90;
		BackgroundColor3 = Color3.new(1, 1, 0);
	})
end

local function triangle(parent, a, b, c, color)
	WEDGE.Color = color
	local w1 = WEDGE:Clone()
	local w2 = WEDGE:Clone()

	local points = {a, b, c}
	
	local myCam = workspace.CurrentCamera
	local myCamCF = myCam.CFrame
	
	for i, p in next, points do
		local r = myCam:ViewportPointToRay(p.x, p.y, 0)
		local p = rayPlane(r.Origin, r.Direction, Vector3.new(0, 0, -DEPTH), Vector3.new(0, 0, 1))
		points[i] = myCamCF:PointToObjectSpace(p)
	end

	a, b, c = unpack(points)
	
	-- Render the 3D triangle
	local ab, ac, bc = b - a, c - a, c - b
	local abd, acd, bcd = ab:Dot(ab), ac:Dot(ac), bc:Dot(bc)
	
	if (abd > acd and abd > bcd) then
		c, a = a, c
	elseif (acd > bcd and acd > abd) then
		a, b = b, a
	end
	
	ab, ac, bc = b - a, c - a, c - b
	
	local right = ac:Cross(ab).Unit
	local up = bc:Cross(right).Unit
	local back = bc.Unit
	
	local height = math.abs(ab:Dot(up))
	
	w1.Size = Vector3.new(0, height, math.abs(ab:Dot(back)))
	w1.CFrame = CFrame.fromMatrix((a + b)/2, right, up, back)
	w1.Parent = parent

	w2.Size = Vector3.new(0, height, math.abs(ac:Dot(back)))
	w2.CFrame = CFrame.fromMatrix((a + c)/2, -right, up, -back)
	w2.Parent = parent

	return function()
		w1:Destroy()
		w2:Destroy()
	end
end

local function makeVPF(color3)
	local cam = Instance.new("Camera")
	cam.CameraType = Enum.CameraType.Scriptable
	cam.CFrame = CFrame.new()
	cam.Focus = CFrame.new(0, 0, -DEPTH)
	
	local vpf = Instance.new("ViewportFrame")
	vpf.Size = UDim2.new(1, 0, 1, 0)
	vpf.BackgroundTransparency = 1
	vpf.BackgroundColor3 = color3
	vpf.CurrentCamera = cam
	cam.Parent = vpf
	
	return vpf
end


return {
	Point = point;
	Line = line;
	Triangle = triangle;
	MakeVPF = makeVPF;
}