--이건 적 몬스터의 AI를 구현하는 모듈입니다. 여기에 필요하면 pathfinding을 추가해서 더 똑똑한 AI를 만들수도 있습니다.
local module = {}
module.__index = module

local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")

local Animations = game.ServerStorage.MonsterAnims
local MonsterSettings = game.ServerStorage.MonsterSettings

local ZombieMinDis = 1
local ZombieDamageCoolTime = .8
local ZombieAttackDis = 5.2

function module.new(Model: Model, Type)
	local self = setmetatable({}, module)
	local Setting = MonsterSettings[Model.Name]
	self.Model = Model
	self.Humanoid = Model.Humanoid :: Humanoid
	self.HumR = Model.HumanoidRootPart
	
	self.Target = nil
	self.TargetPos = nil
	
	self.Range = Setting.Range.Value
	self.DamageAmount = Setting.Damage.Value
	self.DamageCool = true
	
	local Animator = self.Humanoid.Animator :: Animator
	
	self.Anims = {}
	for i,v in ipairs(Animations[Type]:GetChildren()) do
		self.Anims[v.Name] = Animator:LoadAnimation(v)
	end
	
	self.Humanoid.WalkSpeed = Setting.WalkSpeed.Value
	Model.Hitbox.CanCollide = false
	
	self.Humanoid.Died:Connect(function()
		
		for i,v in ipairs(Model:GetChildren()) do
			if v:IsA("BasePart") then
				v.CollisionGroup = "Default"
			end
		end
		game.Debris:AddItem(Model, 3)
	end)
	
	self:SetJump()
	
	task.spawn(function()
		self:StartFindingTarget(self.Range)
	end)
	
	task.spawn(function()
		self:SetChase()
	end)
	
	return self
end

function module:StartFindingTarget(MaxDis)
	local Model = self.Model :: Instance

	while Model and Model.Parent ~= nil do
		self.Target, self.TargetPos = self:GetClosestTarget(MaxDis)
		task.wait(.1)
	end
end

function module:GetClosestTarget(MaxDis)
	local FinalTarget
	local TargetDis = MaxDis
	local TargetPos
	local HumR = self.HumR :: BasePart
	if not HumR then return end
	
	for i,v in ipairs(Players:GetPlayers()) do
		local Char = v.Character
		if not Char then continue end
		local TargetHumR = Char:FindFirstChild("HumanoidRootPart") :: BasePart
		local TargetHumanoid = Char:FindFirstChild("Humanoid") :: Humanoid
		if not TargetHumR or not TargetHumanoid or TargetHumanoid and TargetHumanoid.Health <= 0 then continue end

		local YFixedVector = Vector3.new(TargetHumR.Position.X, HumR.Position.Y, TargetHumR.Position.Z)
		local Dis = (YFixedVector - HumR.Position).Magnitude
		
		if Dis < TargetDis and Dis <= MaxDis then
			FinalTarget = Char
			TargetDis = Dis
			TargetPos = TargetHumR.Position
		end

	end

	return FinalTarget, TargetPos
end

function module:DamageTarget()
	local Model = self.Model
	local HumR = self.HumR
	local DamageAmount = self.DamageAmount
	
	local Target = self.Target :: Instance
	if not Target or not Target:FindFirstChild("HumanoidRootPart") or not Target:FindFirstChild("Humanoid") then return end
			
	local PlayerHumR = Target.HumanoidRootPart
	local PlayerHum = Target.Humanoid
	local dist = (HumR.Position - PlayerHumR.Position).Magnitude
	
	if dist > ZombieAttackDis or PlayerHum.Health <= 0 then return end
	PlayerHum:TakeDamage(DamageAmount)
	
end

function module:DoAttack()
	local AttackAnim = self.Anims.Attack :: AnimationTrack
	
	AttackAnim:Play()
	
	local conn
	conn = AttackAnim.KeyframeReached:Connect(function(keyframe)
		if keyframe == "Damage" then
			self:DamageTarget()
		elseif keyframe == "AttackEnd" then
			conn:Disconnect()
		end
	end)
	
end

function module:ChaseClosestCharacter()
	local Model = self.Model :: Model
	local MonsterAnims = self.Anims
	local Humanoid = self.Humanoid :: Humanoid
	local HumR = self.HumR :: BasePart
	local Target, TargetPos = self.Target, self.TargetPos
	
	if not Humanoid or Humanoid and Humanoid.Health <= 0 or not HumR then return end
	
	if Target and TargetPos then
		local YFixedVector = Vector3.new(TargetPos.X, HumR.Position.Y, TargetPos.Z)
		local WhereToLookAt = CFrame.lookAt(HumR.Position, YFixedVector)
		local Dis = (YFixedVector-HumR.Position).Magnitude
		
		local Destination = (WhereToLookAt*CFrame.new(0,0,-Dis)).Position
		
		if Dis < ZombieMinDis + ZombieAttackDis then
			
			Humanoid:MoveTo(Destination)
			--if Dis < ZombieMinDis + .3 then HumR.CFrame = WhereToLookAt end
			
			if self.DamageCool == true then
				task.spawn(function()
					self.DamageCool = false
					self:DoAttack()
					task.wait(ZombieDamageCoolTime)
					self.DamageCool = true
				end)
			end
			
		else
			
			Humanoid:MoveTo(Destination + Vector3.new(math.random(-3,3),0,math.random(-3,3)))
		end
		
	else
		Humanoid:MoveTo(Model:GetPivot().Position)
	end
end

function module:SetJump()
	local Model = self.Model
	local Humanoid = self.Humanoid :: Humanoid
	local HumR = self.HumR :: BasePart
	if not HumR then return end
	
	local JumpCool = true

	HumR.Touched:Connect(function(h)
		local CheckIfAncestorIsA_Model = h:FindFirstAncestorOfClass("Model")
		if CheckIfAncestorIsA_Model and CheckIfAncestorIsA_Model:FindFirstChild("Humanoid") and CheckIfAncestorIsA_Model.Name ~= "Jeep" then return end

		if JumpCool and h.Name ~= "Detector" or h.Parent.Name == "Jeep" then
			JumpCool = false
			Humanoid.Jump = true
			task.wait(.1)
			JumpCool = true
		end
	end)
end

function module:SetChase()
	local Model = self.Model
	local Humanoid = Model.Humanoid :: Humanoid
	
	while Humanoid and Humanoid.Health > 0 do
		self:ChaseClosestCharacter()
		task.wait(.1)
	end
end

return module
