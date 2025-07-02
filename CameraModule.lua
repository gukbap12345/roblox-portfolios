local module = {}
module.__index = module

local TweenService = game:GetService("TweenService")

local Camera = workspace:WaitForChild("Camera")
local Cams = workspace:WaitForChild("CutSceneCameras")

function module.new(Cam)
	local self = setmetatable({}, module)
	
	self.Cam = Cam
	
	return self
end

function module:CreateTween(Time, Style)
	local Cam = self.Cam :: BasePart
	
	local TweenInfos = {
		Info = TweenInfo.new(Time, Style, Enum.EasingDirection.Out),
		Goal = {
			CFrame = Cam.CFrame
		}
	}
	
	return TweenService:Create(Camera, TweenInfos.Info, TweenInfos.Goal)
end

function module:TeleportCam(BonusVector: Vector3)
	local Cam = self.Cam :: BasePart
	
	Camera.CFrame = Cam.CFrame + (BonusVector or Vector3.new(0,0,0))
end

function module:FocusOnPart()
	local Cam = self.Cam :: BasePart
	
	Camera.CameraSubject = Cam
end

return module
