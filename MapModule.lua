--이건 제가 만든 게임에서 랜덤으로 오브젝트들을 소환하기 위해 쓰인 모듈입니다.
local module = {}
module.__index = module

local Base = game.ServerStorage.Base
local Canvas = game.ServerStorage["Military Canvas"]
local Soldier = game.ServerStorage.Soldier

local FieldItems = game.ServerStorage.FieldItems

local CanvasSizeY = Canvas.PosPart.Size.Y

local WorldTrees = workspace["World Trees"]
local WorldMonsters = workspace["World Monsters"]
local WorldMuds = workspace["World Muds"]

local MonsterLimitParts = workspace["Monster LimitParts"]
local LeftXLimit = MonsterLimitParts.LeftMonsterLimit.Position.X
local RightXLimit = MonsterLimitParts.RightMonsterLimit.Position.X

local Trees = game.ServerStorage.Trees:GetChildren()
local Monsters = game.ServerStorage.Monsters

local SandBag = game.ServerStorage.Sandbag
local Wire = game.ServerStorage["Barbed Wire"]

local Muds = game.ServerStorage.Muds

function module.new(Map)
	local self = setmetatable({}, module)
	self.Map = Map
	
	return self
end

function module:DestroyObjectPoints()
	local Map = self.Map :: Model
	local ObjectPoints = Map.ObjectPoints :: Folder
	local WirePoints = Map.WirePoints :: Folder
	local MudPoints = Map:FindFirstChild("MudPoints") :: Folder
	
	for i,v in ipairs(ObjectPoints:GetChildren()) do
		v:Destroy()
		
		if i%200 == 0 then
			task.wait() -- in order to avoid being laggy
		end
		
	end
	
	for i,v in ipairs(WirePoints:GetChildren()) do
		v:Destroy()
	end
	
	if MudPoints then
		MudPoints:Destroy()
	end
	
end

function module:GenerateBase(DoSpawnItem)
	local Map = self.Map :: Model
	local BasePos = Map.BasePos :: BasePart
	local ClonedBase = Base:Clone()
	
	for i,v in ipairs(Map.ObjectPoints:GetChildren()) do
		if v.Name == "PointAtBase" then
			v:Destroy()
		end
	end
	
	if not DoSpawnItem then
		ClonedBase.Items:Destroy()
	end
	
	ClonedBase.Parent = Map
	ClonedBase:MoveTo(BasePos.Position) --need to be fixed (i mean pivotTo in order to avoid bases being spawned on something)
end

local TreeFrequencies = 100

function module:GenerateTrees()
	local Map = self.Map :: Model
	local TreePoints = Map.ObjectPoints :: Folder
	
	for i,v in ipairs(TreePoints:GetChildren()) do
		
		if math.random(1, TreeFrequencies) <= 40 then
			local RandomTree = Trees[math.random(1, 3)]:Clone() :: Model
			RandomTree.Parent = WorldTrees
			RandomTree:MoveTo(v.Position)
			RandomTree:PivotTo(RandomTree:GetPivot()*CFrame.new(0,-.6,0)) -- doing this I can completely nail all the trees
			RandomTree.Collider.CanCollide = false
		end
		
		if i%200 == 0 then
			task.wait()
		end
	end
end

function module:GenerateSandBags()
	local Map = self.Map :: Model
	local ObjectPoints = Map.ObjectPoints:GetChildren()
	
	for i=1, 6 do
		local index = math.random(1, #ObjectPoints)
		local Point = ObjectPoints[index] :: BasePart
		local RandomAngle = CFrame.Angles(0, math.rad(math.random(-90, 90)), 0)
		local AdditionalVector = Vector3.new(math.random(8,16), 0, math.random(8,16))
		local SandBagClone = SandBag:Clone()
		SandBagClone:PivotTo(CFrame.new(Vector3.new(Point.Position.X, SandBagClone.HitBox.Size.Y/2, Point.Position.Z) + AdditionalVector) * RandomAngle)
		SandBagClone.Parent = Map
		
		Point:Destroy()
		table.remove(ObjectPoints, index)
	end
	
end

function module:GenerateWires()
	local Map = self.Map :: Model
	local ObjectPoints = Map.WirePoints:GetChildren()
	
	for i=1, 6 do
		local index = math.random(1, #ObjectPoints)
		local Point = ObjectPoints[index] :: BasePart
		local RandomAngle = CFrame.Angles(0, math.rad(math.random(-60, 60)), 0)
		local WireClone = Wire:Clone()
		WireClone:PivotTo(CFrame.new(Point.Position + Vector3.yAxis * 3.036) * RandomAngle)
		WireClone.Parent = Map
		
		Point:Destroy()
		table.remove(ObjectPoints, index)
	end
end

local CurrentCanvasNum = 1

function module:GenerateCanvas(NumOfCanvas, NumOfSoldiers) --this should be called first
	local Map = self.Map :: Instance
	local CanvasPoints = Map.CanvasPoints :: BasePart
	
	local newFolder = Instance.new("Folder", Map)
	newFolder.Name = "SoldierFolders"
	
	for i=1, NumOfCanvas do
		local ClonedCanvas = Canvas:Clone() :: Instance
		local CanvasPosPart = ClonedCanvas.PosPart
		ClonedCanvas.Name = "Canvas"..CurrentCanvasNum
		CurrentCanvasNum += 1
		ClonedCanvas:PivotTo(CFrame.new() + Vector3.new(CanvasPoints:GetChildren()[i].Position.X, CanvasSizeY/2, CanvasPoints:GetChildren()[i].Position.Z))
		ClonedCanvas.Parent = Map
		
		local SoliderFolder = Instance.new("Folder", newFolder)
		SoliderFolder.Name = ClonedCanvas.Name.." Soldiers"
		
		local Barriers = ClonedCanvas:FindFirstChild("Barriers")
		local conn
		conn = SoliderFolder.ChildRemoved:Connect(function()
			if #SoliderFolder:GetChildren() == 0 and Barriers then
				conn:Disconnect()
				ClonedCanvas.Barriers:Destroy()
			end
		end)
		
		local SoldierPoints = ClonedCanvas.SoldierPoints :: Instance
		
		for j=1, NumOfSoldiers do
			local RandomSpot = SoldierPoints:GetChildren()[math.random(1, #SoldierPoints:GetChildren())]
			local ClonedSoldier = Soldier:Clone()
			ClonedSoldier:PivotTo(CFrame.Angles(0,math.rad(math.random(1, 360)),0))
			ClonedSoldier.Parent = SoliderFolder
			ClonedSoldier:MoveTo(RandomSpot.Position)
			RandomSpot:Destroy()
		end
		
		local RegionSize = CanvasPosPart.Size
		
		local Params = OverlapParams.new()
		Params.FilterType = Enum.RaycastFilterType.Exclude
		Params.FilterDescendantsInstances = {ClonedCanvas}
		
		local DetectedParts = workspace:GetPartBoundsInBox(CanvasPosPart.CFrame, RegionSize, Params)
		
		for i,v in ipairs(DetectedParts) do
			if v.Parent and v.Parent:IsA("Folder") then
				v:Destroy()
			end
		end
		
		SoldierPoints:Destroy()
	end
	
end

local ZombieList = {Zombie = 12, ["Rapid Zombie"] = 0, ["Tank Zombie"] = 0}

function module:SpawnMonsters() --this method must be called at last because of deleting points
	local Map = self.Map :: Model
	local SpawnPoints = Map.ObjectPoints :: Folder

	local MapNumber = tonumber(Map.Name:match("%d+"))
	
	if MapNumber ~= nil then
		if MapNumber == 3 then
			ZombieList = {Zombie = 14, ["Rapid Zombie"] = 0, ["Tank Zombie"] = 0}
			
		elseif MapNumber == 5 then
			ZombieList = {Zombie = 12, ["Rapid Zombie"] = 3, ["Tank Zombie"] = 1}

		elseif MapNumber == 7 then
			ZombieList = {Zombie = 13, ["Rapid Zombie"] = 4, ["Tank Zombie"] = 3}

		elseif MapNumber == 10 then
			ZombieList = {Zombie = 12, ["Rapid Zombie"] = 10, ["Tank Zombie"] = 4}

		elseif MapNumber == 14 then
			ZombieList = {Zombie = 10, ["Rapid Zombie"] = 10, ["Tank Zombie"] = 6}

		end
		
	end
	
	for i,v in ipairs(SpawnPoints:GetChildren()) do
		if v.Position.X < LeftXLimit or v.Position.X > RightXLimit then
			v:Destroy()
		end
	end
	
	for i,v in pairs(ZombieList) do
		if v == 0 then continue end
		for j=1, v do
			local ClonedMonster = Monsters[i]:Clone() :: Model
			local AdditionalVector = Vector3.new(math.random(8,16), 0, math.random(8,16))

			local DecidedPoint = SpawnPoints:GetChildren()[math.random(1, #SpawnPoints:GetChildren())] :: BasePart
			ClonedMonster.Parent = WorldMonsters
			ClonedMonster:PivotTo(CFrame.Angles(0, math.rad(math.random(1,360)), 0))
			ClonedMonster:MoveTo(DecidedPoint.Position + AdditionalVector)
		end
	end
	
	for i,v in pairs(SpawnPoints:GetChildren()) do
		v:Destroy()
		if i%200 == 0 then
			task.wait()
		end
	end
end

function module:GenerateMuds(MudType: string, Num: number, Item: string)
	local Map = self.Map :: Model
	local MudPoints = Map.MudPoints :: Folder
	
	for i=1, Num do
		local ClonedMud = Muds[MudType]:Clone()
		local index = math.random(1, #MudPoints:GetChildren())
		local Point = MudPoints:GetChildren()[index]
		
		if MudType == "ItemMud" and Item then
			ClonedMud.Item.Value = Item
		end
		
		ClonedMud:PivotTo(CFrame.new(Point.CFrame.Position) + Vector3.yAxis * -4)
		ClonedMud.Parent = WorldMuds
	end
	
end

return module
