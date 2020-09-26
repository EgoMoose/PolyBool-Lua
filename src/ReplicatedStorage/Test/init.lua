local Mouse = game.Players.LocalPlayer:GetMouse()
local PolyBool = require(game.ReplicatedStorage.PolyBool)
local Screen = game.Players.LocalPlayer.PlayerGui:WaitForChild("ScreenGui")

local Maid = require(script:WaitForChild("Maid")).new()
local Dragger = require(script:WaitForChild("Dragger"))
local Draw = require(script:WaitForChild("Draw"))

local HEIGHT = Vector2.new(0, 36)
local VPF = Draw.MakeVPF(Screen.Background.BackgroundColor3)
VPF.Parent = Screen.Render

local funcName = nil
local lastButton = nil
local polygonFrames = {Screen.Container.Polygon1, Screen.Container.Polygon2}

local function toV2(p)
	return Vector2.new(p[1], p[2])
end

local function selectButton(button)
	if lastButton then
		funcName = nil
		lastButton.BackgroundColor3 = lastButton.BorderColor3
	end
	funcName = "select" .. button.Name
	button.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
	lastButton = button
end

local function render()
	Maid:Sweep()

	local polygons = {}

	for k, polyFrame in pairs(polygonFrames) do
		local n = #polyFrame:GetChildren()
		local vertices = {}
		for i = 1, n do
			local framei = polyFrame[i]
			local framej = polyFrame[i % n + 1]
			local posi = framei.AbsolutePosition + framei.AbsoluteSize / 2 + HEIGHT
			local posj = framej.AbsolutePosition + framej.AbsoluteSize / 2 + HEIGHT

			vertices[i] = {posi.x, posi.y}
			
			local line = Draw.Line(posi, posj)
			line.BackgroundColor3 = polyFrame.BackgroundColor3
			line.ZIndex = 2
			line.Parent = Screen.Render
			Maid:Mark(line)
		end

		polygons[k] = {
			regions = {vertices};
			inverted = false;
		}
	end

	if funcName ~= "selectNone" then
		local segments = PolyBool.segments(polygons[1])
		for i = 2, #polygons do
			local seg2 = PolyBool.segments(polygons[i])
			local comb = PolyBool.combine(segments, seg2)
			segments = PolyBool[funcName](comb)
		end

		local polygon = PolyBool.polygon(segments)

		for k, region in pairs(polygon.regions) do
			local color = (funcName == "selectXor" and BrickColor.new(k).Color)
			for i = 1, #region do
				local pi = toV2(region[i])
				local pj = toV2(region[i % #region + 1])
				local line = Draw.Line(pi, pj)
				line.BackgroundColor3 = color or line.BackgroundColor3
				line.Parent = Screen.Result
				Maid:Mark(line)
			end
		end
	end
end

for _, polygon in pairs(polygonFrames) do
	for _, handle in pairs(polygon:GetChildren()) do
		local drag = Dragger.new(handle)
		drag.DragChanged:Connect(function(element, input, delta)
			local size = polygon.Parent.AbsoluteSize
			local pos = Vector2.new(input.Position.x, input.Position.y)
			pos = pos - polygon.Parent.AbsolutePosition

			pos = Vector2.new(
				math.clamp(pos.x, 0, size.x),
				math.clamp(pos.y, 0, size.y)
			)

			element.Position = UDim2.new(0, pos.x, 0, pos.y)
			render()
		end)
	end
end

for _, button in pairs(Screen.Options:GetChildren()) do
	if button:IsA("TextButton") then
		button.Activated:Connect(function()
			selectButton(button)
			render()
		end)
	end
end

selectButton(Screen.Options.None)
render()

return true