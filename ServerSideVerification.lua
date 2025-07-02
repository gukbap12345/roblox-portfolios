--이 코드는 클라이언트에서 서버로 리모트 이벤트/펑션을 통해 신호를 보냈을때 전해진 정보가(여기선 쿨타임) 합당한지 평가하는 모듈입니다.
local WeaponConfigs = game:GetService("ReplicatedStorage"):WaitForChild("WeaponConfigs")

local CoolDownList = {}

local module = {}
module.__index = module

function module.new(plr: Player)
	local self = setmetatable({}, module)
	self.Player = plr
	
	local Character = plr.Character
	local Humanoid = Character.Humanoid :: Humanoid
	if not Character or not Humanoid or Humanoid.Health <= 0 then return end
	
	CoolDownList[plr.Name] = {}
	
	Humanoid.Died:Once(function()
		CoolDownList[plr.Name] = nil
	end)
	
	return self
end

function module:AddWeaponCool(WeaponName: string)
	local Player = self.Player
	local Configs = WeaponConfigs:WaitForChild(WeaponName)
	
	local CoolTime = Configs:WaitForChild("Cooltime").Value
	
	CoolDownList[Player.Name][WeaponName] = {
		Cooldown = true,
		Cooltime = CoolTime,
		MinCool = CoolTime/2,
		LatestTick = 0
	}
	
end

function module.RemovePlrCool(plr: Player)
	if CoolDownList[plr.Name] then
		CoolDownList[plr.Name] = nil
	end
end

function module.ValidateCool(plr: Player, WeaponName: string)
	if CoolDownList[plr.Name] == nil then return end
	
	local WeaponInfos = CoolDownList[plr.Name][WeaponName]
	local CurrentTick = os.clock()
	if CurrentTick - WeaponInfos.LatestTick > WeaponInfos.MinCool then
		WeaponInfos.LatestTick = CurrentTick
		return true
	else
		WeaponInfos.LatestTick = CurrentTick
		print("Exploiter!?")
		return
	end
end

return module
