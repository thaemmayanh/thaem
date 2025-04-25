-- 🧼 Xoá GUI cũ nếu tồn tại
local CoreGui = game:GetService("CoreGui")
local HUI = CoreGui:FindFirstChild("HUI")
if HUI then
	local existingGui = HUI:FindFirstChildOfClass("ScreenGui")
	if existingGui then existingGui:Destroy() end
end

for _, gui in ipairs(CoreGui:GetChildren()) do
	if gui.Name == "FPSPingDisplay" or gui.Name == "ImageButtonGUI" then
		gui:Destroy()
	end
end

-- 🚫 Bypass Anti-Teleport (tăng speed)
local replicated = game:GetService("ReplicatedStorage")
local success, extraFunctionsModule = pcall(function()
	return require(replicated:WaitForChild("SharedModules"):WaitForChild("ExtraFunctions"))
end)

if success and extraFunctionsModule and not getgenv()._original_GetPlayerSpeed then
	getgenv()._original_GetPlayerSpeed = extraFunctionsModule.GetPlayerSpeed
	extraFunctionsModule.GetPlayerSpeed = function(player) return 9999999 end
end

-- 🧱 Load Maclib & tạo Window
local MacLib = loadstring(game:HttpGet("https://github.com/biggaboy212/Maclib/releases/latest/download/maclib.txt"))()

local Window = MacLib:Window({
	Title = "Pịa Hub",
	Subtitle = "Vãi Pịa 💩",
	Size = UDim2.fromOffset(640, 450),
	Keybind = Enum.KeyCode.K,
	AcrylicBlur = true,
	ShowUserInfo = false,
	DragStyle = 1,
	DisabledWindowControls = {}
})

-- ⚙️ Cài đặt config & file lưu
local HttpService = game:GetService("HttpService")
local settingsFile = "piahubv2.json"
local settings = {}

pcall(function()
	if isfile(settingsFile) then
		settings = HttpService:JSONDecode(readfile(settingsFile))
	end
end)

local defaultSettings = {
	AutoFarm = false,
	FarmScales = "Normal", -- 🔧 chỉnh lại từ list → string (nếu dùng single dropdown)
	FarmDelay = 0.2,
	AutoDestroy = false,
	AriseModels = {"Jinwoo", "Pucci", "Freeza"},
	OnlyCastleParts = false,
	AutoCastleCustom = false,
	AutoOutCastleFloor = 0,
	AutoBypassDungeon = false,
	AutoCheckDD = false,
	AutoClick = false,
	AutoAttack = false,
	AutoLoadScript = false,
	BypassCooldown = false,
	SpecialScript = false,
	AutoHideUI = false,
	AutoSendPetFast = false,
	SelectedCheckpoint = "25",
	AutoAddRune = false,
	SelectedRuneName = "Black Clover",
	AutoLeaveDungeonEnd = false,
	OnlyDungeon = false,
	AutoBypassDungeonBlockTime = false,
}

for key, value in pairs(defaultSettings) do
	if settings[key] == nil then
		settings[key] = value
	end
end

local function saveSettings()
	writefile(settingsFile, HttpService:JSONEncode(settings))
end

local TabGroups = {
	MainGroup = Window:TabGroup()
}

local Tabs = {
	Main = TabGroups.MainGroup:Tab({ Name = "Main", Image = "rbxassetid://18821914323" }),
	Dungeon = TabGroups.MainGroup:Tab({ Name = "Dungeon", Image = "rbxassetid://10734950309" }),
	Misc = TabGroups.MainGroup:Tab({ Name = "Misc", Image = "rbxassetid://10734950309" }),
	Shop = TabGroups.MainGroup:Tab({ Name = "Shop", Image = "rbxassetid://10734950309" }),
	Teleport = TabGroups.MainGroup:Tab({ Name = "Teleport", Image = "rbxassetid://10734950309" }),
	Settings = TabGroups.MainGroup:Tab({ Name = "Settings", Image = "rbxassetid://10734950309" }),
}

-- Tạo Section bên trái tab Misc (nếu chưa có)
local MiscSection = Tabs.Misc:Section({ Side = "Left" })

-- Toggle: Auto Hide UI
MiscSection:Toggle({
	Name = "Auto Hide UI",
	Default = settings["AutoHideUI"],
	Callback = function(val)
		settings["AutoHideUI"] = val
		saveSettings()
	end
}, "AutoHideUI")

task.delay(0.2, function()
	if settings["AutoHideUI"] then
		local vu = game:GetService("VirtualInputManager")
		vu:SendKeyEvent(true, Enum.KeyCode.K, false, game)
		vu:SendKeyEvent(false, Enum.KeyCode.K, false, game)
	end
end)

-- Tạo Section bên trái tab Main (nếu chưa có)
local MainSection = Tabs.Main:Section({ Side = "Left" })

-- Toggle: Auto Send Pet Fast (new)
MainSection:Toggle({
	Name = "Auto Send Pet Fast (new)",
	Default = settings["AutoSendPetFast"],
	Callback = function(val)
		settings["AutoSendPetFast"] = val
		saveSettings()
	end
}, "AutoSendPetFast")

task.spawn(function()
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local Players = game:GetService("Players")
    local LocalPlayer = Players.LocalPlayer
    local PetsController = require(ReplicatedStorage:WaitForChild("SharedModules"):WaitForChild("Pets"):WaitForChild("PetsController"))

    repeat task.wait() until LocalPlayer.Character and LocalPlayer.Character.PrimaryPart

    -- Hàm tìm quái gần nhất còn sống
    local function getNearestEnemy()
        local myPos = LocalPlayer.Character.PrimaryPart.Position
        local nearest, minDist = nil, math.huge

        for _, clientEnemy in ipairs(workspace.__Main.__Enemies.Client:GetChildren()) do
            local serverEnemy = workspace.__Main.__Enemies.Server:FindFirstChild(clientEnemy.Name, true)
            if serverEnemy and not serverEnemy:GetAttribute("Dead") and (serverEnemy:GetAttribute("HP") or 1) > 0 then
                local dist = (clientEnemy.PrimaryPart.Position - myPos).Magnitude
                if dist < minDist then
                    nearest = clientEnemy
                    minDist = dist
                end
            end
        end

        return nearest
    end

    while true do
        if settings["AutoSendPetFast"] then
            local target = getNearestEnemy()
            if target then
                pcall(function()
                    PetsController.AutoEnemy(target)
                end)
            end
        end
        task.wait(0.1)
    end
end)

-- 🧱 Section trong tab Main bên trái
local MainSection = Tabs.Main:Section({ Side = "Left" })

-- 🏷️ Label: Auto Farm all mode
MainSection:Label({ Text = "Auto Farm all mode" })

-- ✅ Toggle: Auto Farm
MainSection:Toggle({
	Name = "Auto Farm",
	Default = settings["AutoFarm"],
	Callback = function(val)
		settings["AutoFarm"] = val
		saveSettings()
	end
}, "AutoFarm")

-- ✅ Toggle: Only Dungeon/Castle
MainSection:Toggle({
	Name = "Only Dungeon/Castle",
	Default = settings["OnlyDungeon"],
	Callback = function(val)
		settings["OnlyDungeon"] = val
		saveSettings()
	end
}, "OnlyDungeon")

-- 📦 Dropdown: Select Mob
local farmDropdown = MainSection:Dropdown({
	Name = "Select Mob",
	Options = {"All", "Normal", "Big", "big priority"},
	Default = tostring(settings["FarmScales"]):gsub("^%s*(.-)%s*$", "%1"),
	Multi = false,
	Callback = function(val)
		settings["FarmScales"] = val
		saveSettings()
	end
}, "FarmScales")

-- 🛠 Fix thủ công sau khi tạo xong: force tick lại bằng tay
task.delay(0.2, function()
	farmDropdown:UpdateSelection(settings["FarmScales"])
end)

-- ⏱️ Input: Delay TP
MainSection:Input({
	Name = "Delay TP",
	Placeholder = "0.2",
	Default = tostring(settings["FarmDelay"]),
	AcceptedCharacters = function(text)
		return text:gsub("[^%d%.]", "") -- Cho phép số & dấu chấm
	end,
	Callback = function(val)
		local num = tonumber(val)
		if num and num > 0 then
			settings["FarmDelay"] = num
			saveSettings()
		else
			warn("Delay không hợp lệ:", val)
		end
	end
}, "FarmDelay")

task.spawn(function()
    local Players = game:GetService("Players")
    local player = Players.LocalPlayer
    local character = player.Character or player.CharacterAdded:Wait()
    local rootPart = character:WaitForChild("HumanoidRootPart")
    local humanoid = character:WaitForChild("Humanoid")

    local enemiesRoot = workspace:WaitForChild("__Main"):WaitForChild("__Enemies")
    local enemiesServer = enemiesRoot:WaitForChild("Server")
    local enemiesClient = enemiesRoot:WaitForChild("Client")

    local scaleMap = {
        ["Normal"] = 1,
        ["Big"] = 2
    }

    local noclipConnection

    local function enableNoClip()
        if noclipConnection then return end
        noclipConnection = game:GetService("RunService").Stepped:Connect(function()
            if settings["AutoFarm"] and character and humanoid then
                for _, part in ipairs(character:GetDescendants()) do
                    if part:IsA("BasePart") then
                        part.CanCollide = false
                    end
                end
            end
        end)
    end

    local function disableNoClip()
        if noclipConnection then
            noclipConnection:Disconnect()
            noclipConnection = nil
        end

        for _, part in ipairs(character:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = true
            end
        end
    end

    local function isScaleAllowed(scale)
        local selected = settings["FarmScales"]

        if selected == "All" then
            return true
        elseif selected == "big priority" then
            return scale >= 1
        elseif selected == "Normal" and scale == 1 then
            return true
        elseif selected == "Big" and scale == 2 then
            return true
        end

        return false
    end

    local function findNearestMob()
        local nearestNormal, nearestBoss
        local minNormalDist, minBossDist = math.huge, math.huge
        local selected = settings["FarmScales"]

        local function check(part)
            local hp = part:GetAttribute("HP")
            local scale = part:GetAttribute("Scale")
            if not hp or hp <= 0 or not scale then return end
            if not isScaleAllowed(scale) then return end

            local uuid = part.Name
            local model = enemiesClient:FindFirstChild(uuid, true)
            local pos = (model and model:FindFirstChild("HumanoidRootPart")) and model.HumanoidRootPart.Position or part.Position
            local dist = (pos - rootPart.Position).Magnitude

            -- Ưu tiên Boss nếu chọn "Đánh Boss trước"
            if selected == "big priority" and scale >= 2 then
                if dist < minBossDist then
                    minBossDist = dist
                    nearestBoss = { model = model, part = part }
                end
            elseif dist < minNormalDist then
                minNormalDist = dist
                nearestNormal = { model = model, part = part }
            end
        end

        for _, child in ipairs(enemiesServer:GetDescendants()) do
            if child:IsA("Part") then
                check(child)
            end
        end

        return (nearestBoss or nearestNormal or {}).model, (nearestBoss or nearestNormal or {}).part
    end

    local function teleportNearMob(pos)
        if typeof(pos) ~= "Vector3" then return end
        local dir = rootPart.Position - pos
        if dir.Magnitude == 0 then return end

        local success, direction = pcall(function() return dir.Unit end)
        if not success then return end

        local offset = direction * 2 + Vector3.new(0, 1, 0)
        local finalCFrame = CFrame.new(pos + offset, pos)

        local originalGravity = workspace.Gravity
        workspace.Gravity = 0

        rootPart.Velocity = Vector3.zero
        humanoid.AutoRotate = false
        humanoid:ChangeState(Enum.HumanoidStateType.Physics)
        rootPart.CFrame = finalCFrame

        task.delay(0.1, function()
            workspace.Gravity = originalGravity
            humanoid.AutoRotate = true
            humanoid:ChangeState(Enum.HumanoidStateType.RunningNoPhysics)
        end)
    end

    local function handleMob(model, part)
        if not part then return end

        local function getTargetPosition()
            if model and model:FindFirstChild("HumanoidRootPart") then
                return model.HumanoidRootPart.Position
            elseif part:IsA("Part") then
                return part.Position
            end
            return nil
        end

        while settings["AutoFarm"] and part:IsDescendantOf(workspace) and part:GetAttribute("Dead") ~= true do
            local targetPos = getTargetPosition()
            if targetPos and (targetPos - rootPart.Position).Magnitude > 7 then
                teleportNearMob(targetPos)
            end
            task.wait(0.1)
        end

        task.wait(settings["FarmDelay"] or 0.1)
    end

    -- Main loop
    local LOBBY_PLACE_ID = 87039211657390

    while true do
        local isInLobby = game.PlaceId == LOBBY_PLACE_ID
        local onlyDungeon = settings["OnlyDungeon"]

        if settings["AutoFarm"] and (not onlyDungeon or not isInLobby) then
            enableNoClip()
            local model, part = findNearestMob()
            if part then
                handleMob(model, part)
            else
                task.wait(0.1)
            end
        else
            disableNoClip()
            task.wait(0.1)
        end
    end
end)

-- 🛡 Section bên tab Main (nếu chưa có)
local MainSection = Tabs.Main:Section({ Side = "Right" })

-- ⚙️ Toggle: Auto Destroy
MainSection:Toggle({
	Name = "Auto Destroy",
	Default = settings["AutoDestroy"],
	Callback = function(val)
		settings["AutoDestroy"] = val
		saveSettings()
	end
}, "AutoDestroy")

-- 🧟‍♂️ Dropdown: Select Mob Arise (Multi Selection)
local ariseDropdown = MainSection:Dropdown({
	Name = "Select Mob Arise",
	Options = {"JinWoo", "Pucci", "Metus", "Saitama", "Esil", "Baran", "Vulcan", "Kamish"},
	Default = settings["AriseModels"] or {},
	Multi = true,
	Callback = function(optionList)
		settings["AriseModels"] = optionList
		saveSettings()
	end
}, "AriseModels")

-- 🛠 Force chọn lại thủ công đúng danh sách
task.delay(0.2, function()
	ariseDropdown:UpdateSelection(settings["AriseModels"])
end)

--  Xử lý Auto Destroy/Arise
task.spawn(function()
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local Workspace = game:GetService("Workspace")
    local Players = game:GetService("Players")

    local player = Players.LocalPlayer
    local char = player.Character or player.CharacterAdded:Wait()
    local hrp = char:WaitForChild("HumanoidRootPart")

    local enemiesRoot = Workspace:WaitForChild("__Main"):WaitForChild("__Enemies")
    local enemiesServer = enemiesRoot:WaitForChild("Server")
    local enemiesClient = enemiesRoot:WaitForChild("Client")

    local remote = ReplicatedStorage:WaitForChild("BridgeNet2"):WaitForChild("dataRemoteEvent")

    -- Hàm tìm mob gần nhất, kết hợp Server và Client để lấy UUID chính xác
    local function getNearestMob()
        local nearestPart, nearestModel, minDist = nil, nil, math.huge

        local function check(uuidPart)
            local uuid = uuidPart.Name
            local hp = uuidPart:GetAttribute("HP")
            local scale = uuidPart:GetAttribute("Scale")

            if not hp or hp > 0 then return end -- chỉ xử lý mob đã chết

            local model = enemiesClient:FindFirstChild(uuid, true)
            if model and model:IsA("Model") and model:FindFirstChild("HumanoidRootPart") then
                local dist = (model.HumanoidRootPart.Position - hrp.Position).Magnitude
                if dist < minDist then
                    minDist = dist
                    nearestPart = uuidPart
                    nearestModel = model
                end
            end
        end

        -- Duyệt hết từ Server
        for _, child in pairs(enemiesServer:GetChildren()) do
            if child:IsA("Folder") then
                for _, uuidPart in pairs(child:GetChildren()) do
                    if uuidPart:IsA("Part") then
                        check(uuidPart)
                    end
                end
            elseif child:IsA("Part") then
                check(child)
            end
        end

        return nearestPart, nearestModel
    end

    -- Xử lý Arise hoặc Destroy
    local function handleMob()
    local mobPart, mobModel = getNearestMob()
    if not mobPart or not mobModel then return end

    local uuid = mobPart.Name
    local modelName = mobPart:GetAttribute("Model")

    local eventType = "EnemyDestroy"
    if table.find(settings["AriseModels"] or {}, modelName) then
        eventType = "EnemyCapture"
    end

    for _ = 1, 4 do
        local args = {
            [1] = {
                [1] = {
                    ["Event"] = eventType,
                    ["Enemy"] = uuid
                },
                [2] = "\4"
            }
        }
        remote:FireServer(unpack(args))
        task.wait(0.1)
    end
end

    while true do
        if autoDestroy then
            pcall(handleMob)
        end
        task.wait(0.1)
    end
end)

-- 📌 Section cho Dungeon tab (bên trái)
local DungeonSection = Tabs.Dungeon:Section({ Side = "Left" })

-- 🏷 Label: Auto farm Dungeon
DungeonSection:Label({ Text = "Auto farm Dungeon" })

-- ⏱️ Toggle: Out dungeon xx:45m
DungeonSection:Toggle({
	Name = "Out dungeon xx:45m",
	Default = settings["AutoBypassDungeonBlockTime"],
	Callback = function(val)
		settings["AutoBypassDungeonBlockTime"] = val
		saveSettings()
	end
}, "AutoBypassDungeonBlockTime")

task.spawn(function()
    local TeleportService = game:GetService("TeleportService")
    local Players = game:GetService("Players")
    local LocalPlayer = Players.LocalPlayer

    while true do
        if settings["AutoBypassDungeonBlockTime"] and game.PlaceId ~= 87039211657390 then
            local curTime = os.date("*t")

            if curTime.min >= 45 and curTime.min <= 58 then
                local isInCastle = false

                pcall(function()
                    local label = LocalPlayer.PlayerGui.Hud.UpContanier:FindFirstChild("Room")
                    if label and typeof(label.Text) == "string" then
                        -- Nếu match Floor: xx/xx thì đang ở Castle
                        isInCastle = label.Text:match("Floor:%s*%d+/%d+") ~= nil
                    end
                end)

                if not isInCastle then
                    TeleportService:Teleport(87039211657390)
                    task.wait(60) -- tránh spam
                end
            end
        end
        task.wait(10)
    end
end)

-- 🛡 Toggle: Auto Bypass Dungeon
DungeonSection:Toggle({
	Name = "Auto Bypass Dungeon",
	Default = settings["AutoBypassDungeon"],
	Callback = function(val)
		settings["AutoBypassDungeon"] = val
		saveSettings()
	end
}, "AutoBypassDungeon")

-- 🔍 Toggle: Auto Check DD (fix)
DungeonSection:Toggle({
	Name = "Auto Check DD (fix)",
	Default = settings["AutoCheckDD"],
	Callback = function(val)
		settings["AutoCheckDD"] = val
		saveSettings()
	end
}, "AutoCheckDD")

--  Hàm tạo Dungeon
local function createAndStartDungeon()
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local Players = game:GetService("Players")
    local bridge = ReplicatedStorage:WaitForChild("BridgeNet2"):WaitForChild("dataRemoteEvent")

    -- 🔢 Lấy ID người chơi hiện tại
    local idPlayer = Players.LocalPlayer.UserId

    -- Mua vé
    local args1 = {
        [1] = {
            [1] = {
                ["Type"] = "Gems",
                ["Event"] = "DungeonAction",
                ["Action"] = "BuyTicket"
            },
            [2] = "\n"
        }
    }
    bridge:FireServer(unpack(args1))
    task.wait(0.5)

    -- Tạo dungeon
    local args2 = {
        [1] = {
            [1] = {
                ["Event"] = "DungeonAction",
                ["Action"] = "Create"
            },
            [2] = "\n"
        }
    }
    bridge:FireServer(unpack(args2))

    task.wait(0.5)
    -- ⚡️ Auto Add Rune nếu bật
if settings["AutoAddRune"] then
    local runeDisplayNames = {
        ["DgBCRune"] = "Black Clover",
        ["DgBleachRune"] = "Bleach",
        ["DgOPRune"] = "One Piece",
        ["DgDbRune"] = "Dragon Ball",
        ["DgChainsawRune"] = "Chainsaw Man",
        ["DgNarutoRune"] = "Naruto",
        ["DgSoloRune"] = "Solo Leveling",
        ["DgJojoRune"] = "JoJo",
        ["DgOPMRune"] = "OPM Rune",
        ["DgURankUpRune"] = "Ultimate Rank UP",
        ["DgRankDownRune"] = "Rank Down Rune",
        ["DgHealthRune"] = "Heal Rune",
        ["DgRankUpRune"] = "Rank Up Rune",
        ["DgRoomRune"] = "- Room Rune",
        ["DgTimeRune"] = "Time Rune",
        ["DgMoreRoomRune"] = "More Room Rune"
    }

    for slot = 1, 5 do
        local selectedName = settings["SelectedRuneSlot" .. slot]
        if selectedName and selectedName ~= "None" then
            for id, name in pairs(runeDisplayNames) do
                if name == selectedName then
                    local addArgs = {
                        [1] = {
                            [1] = {
                                ["Dungeon"] = idPlayer,
                                ["Action"] = "AddItems",
                                ["Slot"] = slot,
                                ["Event"] = "DungeonAction",
                                ["Item"] = id
                            },
                            [2] = "\n"
                        }
                    }
                    bridge:FireServer(unpack(addArgs))
                    task.wait(0.1) -- ✅ Thêm delay giữa các AddItems để đảm bảo server nhận đầy đủ
                    break
                end
            end
        end
    end
end

    -- ⏳ Bắt đầu dungeon sau 0.5s
    task.wait(3)

    local args3 = {
        [1] = {
            [1] = {
                ["Dungeon"] = idPlayer,
                ["Event"] = "DungeonAction",
                ["Action"] = "Start"
            },
            [2] = "\n"
        }
    }
    bridge:FireServer(unpack(args3))

    -- 🛑 Rời dungeon cũ sau khi bắt đầu dungeon mới (spam 3 lần)
    task.spawn(function()
        task.wait(0.2)
        local leaveArgs = {
            [1] = {
                [1] = {
                    ["Dungeon"] = idPlayer,
                    ["Event"] = "DungeonAction",
                    ["Action"] = "Leave"
                },
                [2] = "\n"
            }
        }
        for i = 1, 3 do
            bridge:FireServer(unpack(leaveArgs))
            task.wait(0.3)
        end
    end)
end

--  Luồng xử lý Auto Dungeon (cho cả hai toggle)
task.spawn(function()
    local lastText = ""
    local waitFor12s = false
    local isDoubleDungeonCheck = false
    local hasCheckedDoubleDD = false

    while true do
        if not settings["AutoBypassDungeon"] and not settings["AutoCheckDD"] then
            task.wait(1)
        else
            if game.PlaceId == 87039211657390 then
                if settings["AutoBypassDungeon"] then
                    task.wait(1)
                    createAndStartDungeon()
                end
            else
                local player = game.Players.LocalPlayer
                local infoGui = player:WaitForChild("PlayerGui"):WaitForChild("Hud"):FindFirstChild("UpContanier")
                local dungeonInfo = infoGui and infoGui:FindFirstChild("DungeonInfo")

                if dungeonInfo then
                    local textLabel = dungeonInfo:FindFirstChild("TextLabel")
                    local currentText = textLabel and textLabel.Text or ""

                    -- 📌 Khi thấy Dungeon Ends in 20s → bắt đầu kiểm tra double dungeon
                    if currentText == "Dungeon Ends in 20s" then
                        isDoubleDungeonCheck = true
                        waitFor12s = false
                        hasCheckedDoubleDD = false
                    end

                    -- 🧠 Auto Check Double Dungeon
                    if settings["AutoCheckDD"] and isDoubleDungeonCheck and not hasCheckedDoubleDD then
                        if currentText == "Dungeon Ends in 13s" then
                            waitFor12s = true
                        elseif waitFor12s and currentText == "Dungeon Ends in 12s" then
                            createAndStartDungeon()
                            waitFor12s = false
                            isDoubleDungeonCheck = false
                            hasCheckedDoubleDD = true
                        elseif currentText ~= "Dungeon Ends in 13s" and currentText ~= "Dungeon Ends in 12s" then
                            waitFor12s = false
                        end
                    end

                    -- 🛡️ Auto Bypass Dungeon
                    if settings["AutoBypassDungeon"] then
                        -- ⏳ Kiểm tra giờ thực
                        local curTime = os.date("*t")
                        local isInBlockTime = (curTime.min >= 45 and curTime.min <= 58)
                        local allowBypass = true

                        if settings["AutoLeaveDungeonByTime"] and isInBlockTime then
                            allowBypass = false
                        end

                        if allowBypass then
                            local isEndTimer = currentText:match("^Dungeon Ends in %d+s$")
                            local isNewText = currentText ~= lastText

                            if isEndTimer and isNewText then
                                if hasCheckedDoubleDD then
                                    createAndStartDungeon()
                                    hasCheckedDoubleDD = false
                                elseif not settings["AutoCheckDD"] then
                                    createAndStartDungeon()
                                end
                            end
                        end
                    end

                    lastText = currentText
                end
            end

            task.wait(0.3)
        end
    end
end)

-- 📦 Section Rune bên Dungeon tab
local RuneSection = Tabs.Dungeon:Section({ Side = "Right" })

-- 🧠 Rune display list
local runeDisplayNames = {
	["DgBCRune"] = "Black Clover",
	["DgBleachRune"] = "Bleach",
	["DgOPRune"] = "One Piece",
	["DgDbRune"] = "Dragon Ball",
	["DgChainsawRune"] = "Chainsaw Man",
	["DgNarutoRune"] = "Naruto",
	["DgSoloRune"] = "Solo Leveling",
	["DgJojoRune"] = "JoJo",
	["DgOPMRune"] = "OPM Rune",
	["DgURankUpRune"] = "Ultimate Rank UP",
	["DgRankDownRune"] = "Rank Down Rune",
	["DgHealthRune"] = "Heal Rune",
	["DgRankUpRune"] = "Rank Up Rune",
	["DgRoomRune"] = "- Room Rune",
	["DgTimeRune"] = "Time Rune",
	["DgMoreRoomRune"] = "More Room Rune"
}

-- 📋 Build dropdown option list
local runeDropdownOptions = { "None" }
for _, display in pairs(runeDisplayNames) do
	table.insert(runeDropdownOptions, display)
end

-- ✅ Toggle: Auto Add Rune
RuneSection:Toggle({
	Name = "Auto Add Rune",
	Default = settings["AutoAddRune"],
	Callback = function(val)
		settings["AutoAddRune"] = val
		saveSettings()
	end
}, "AutoAddRune")

-- 🔽 Dropdowns for 5 rune slots
for slot = 1, 5 do
	local flag = "SelectedRuneSlot" .. slot
	local defaultVal = tostring(settings[flag] or runeDropdownOptions[1])

	local dropdown = RuneSection:Dropdown({
		Name = "Slot " .. slot .. " Rune",
		Options = runeDropdownOptions,
		Default = defaultVal,
		Multi = false,
		Callback = function(opt)
			local selected = typeof(opt) == "table" and opt[1] or opt
			settings[flag] = selected
			saveSettings()
		end
	}, flag)

	-- 🛠 Ensure dropdown shows correct selection
	task.delay(0.2, function()
		dropdown:UpdateSelection(settings[flag] or runeDropdownOptions[1])
	end)
end

-- 📦 Castle Section chung bên Dungeon tab (Right side)
local CastleSection = Tabs.Dungeon:Section({ Side = "Right" })

-- 🏰 Label
CastleSection:Label({ Text = "Auto Castle" })

-- 🔘 Toggle: Auto Castle Join
local autoCastleJoinToggle = CastleSection:Toggle({
	Name = "Auto Castle Join",
	Default = settings["AutoCastleCustom"],
	Callback = function(val)
		settings["AutoCastleCustom"] = val
		if val and MacLib.Flags["AutoCastleCheckpoint"] then
			MacLib.Flags["AutoCastleCheckpoint"]:Set(false)
		end
		saveSettings()

		if val then
			task.spawn(function()
				while settings["AutoCastleCustom"] do
					local minute = os.date("*t").min
					if minute >= 45 and minute <= 58 then
						local args = {
							[1] = {
								[1] = { ["Event"] = "CastleAction" },
								[2] = "\n"
							}
						}
						pcall(function()
							game:GetService("ReplicatedStorage").BridgeNet2.dataRemoteEvent:FireServer(unpack(args))
						end)
					end
					task.wait(3)
				end
			end)
		end
	end
}, "AutoCastleCustom")

-- 🔘 Toggle: Auto Castle Checkpoint
local autoCastleCheckpointToggle = CastleSection:Toggle({
	Name = "Auto Castle Checkpoint",
	Default = settings["AutoCastleCheckpoint"],
	Callback = function(val)
		settings["AutoCastleCheckpoint"] = val
		if val and MacLib.Flags["AutoCastleCustom"] then
			MacLib.Flags["AutoCastleCustom"]:Set(false)
		end
		saveSettings()

		if val then
			task.spawn(function()
				while settings["AutoCastleCheckpoint"] do
					local minute = os.date("*t").min
					if minute >= 45 and minute <= 58 then
						local args = {
							[1] = {
								[1] = {
									["Check"] = true,
									["Event"] = "CastleAction",
									["Action"] = "Join"
								},
								[2] = "\n"
							}
						}
						pcall(function()
							game:GetService("ReplicatedStorage").BridgeNet2.dataRemoteEvent:FireServer(unpack(args))
						end)
					end
					task.wait(3)
				end
			end)
		end
	end
}, "AutoCastleCheckpoint")

-- 🛠 Auto bật lại nếu đang lưu
task.delay(0.5, function()
	if settings["AutoCastleCustom"] and MacLib.Flags["AutoCastleCustom"] then
		MacLib.Flags["AutoCastleCustom"]:Set(false)
		task.wait(0.05)
		MacLib.Flags["AutoCastleCustom"]:Set(true)
	end
	if settings["AutoCastleCheckpoint"] and MacLib.Flags["AutoCastleCheckpoint"] then
		MacLib.Flags["AutoCastleCheckpoint"]:Set(false)
		task.wait(0.05)
		MacLib.Flags["AutoCastleCheckpoint"]:Set(true)
	end
end)

-- 🛗 Dropdown chọn tầng checkpoint
local teleportFloors = { "25", "50", "75", "100" }

local teleportDropdown = CastleSection:Dropdown({
	Name = "Teleport Floor",
	Options = teleportFloors,
	Default = table.find(teleportFloors, settings["SelectedCheckpoint"]) and settings["SelectedCheckpoint"] or "25",
	Multi = false,
	Callback = function(option)
		local selected = typeof(option) == "table" and option[1] or option
		settings["SelectedCheckpoint"] = selected
		saveSettings()
	end
}, "SelectedCheckpoint")

task.delay(0.2, function()
	teleportDropdown:UpdateSelection(settings["SelectedCheckpoint"] or "25")
end)

-- 🔢 Input: Boss die out (floor)
local bossOutInput = CastleSection:Input({
	Name = "Boss die out (floor)",
	Placeholder = "VD: 50",
	Default = tostring(settings["AutoOutCastleFloor"]),
	AcceptedCharacters = function(text)
		return text:gsub("[^%d]", "")
	end,
	Callback = function(val)
		local num = tonumber(val)
		if num and num >= 1 then
			settings["AutoOutCastleFloor"] = num
			saveSettings()
		else
			warn("❌ Sai giá trị tầng:", val)
		end
	end
}, "AutoOutCastleFloor")

task.delay(0.2, function()
	bossOutInput:Set(tostring(settings["AutoOutCastleFloor"]))
end)

-- 📦 Section duy nhất bên trái tab Misc
local MiscSection = Tabs.Misc:Section({ Side = "Left" })

-- 🖱️ Toggle: AutoClick
MiscSection:Toggle({
	Name = "AutoClick",
	Default = settings["AutoClick"],
	Callback = function(val)
		settings["AutoClick"] = val
		autoClicking = val
		saveSettings()
	end
}, "AutoClick")

-- ⚔️ Toggle: Auto Attack
MiscSection:Toggle({
	Name = "Auto Attack",
	Default = settings["AutoAttack"],
	Callback = function(val)
		settings["AutoAttack"] = val
		autoAttackEnabled = val
		saveSettings()
	end
}, "AutoAttack")

-- 📥 Toggle: Auto Load Script
MiscSection:Toggle({
	Name = "Auto Load Script",
	Default = settings["AutoLoadScript"],
	Callback = function(val)
		settings["AutoLoadScript"] = val
		saveSettings()

		if val then
			queue_on_teleport([[
				loadstring(game:HttpGet('https://raw.githubusercontent.com/thaemmayanh/thaem/refs/heads/main/main'))()
			]])
		end
	end
}, "AutoLoadScript")

-- 🧼 Toggle: Giảm lag
MiscSection:Toggle({
	Name = "Giảm lag",
	Default = settings["SpecialScript"],
	Callback = function(val)
		settings["SpecialScript"] = val
		saveSettings()

		if val then
			task.spawn(function()
				pcall(function()
					loadstring(game:HttpGet("https://raw.githubusercontent.com/skyemngu13/hee/refs/heads/main/giamlag"))()
				end)
			end)
		end
	end
}, "SpecialScript")

-- Luồng xử lý AutoClick
task.spawn(function()
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local Player = game:GetService("Players").LocalPlayer
    local SharedModules = ReplicatedStorage:WaitForChild("SharedModules")
    local WeaponsModule = require(SharedModules:WaitForChild("WeaponsModule"))

    repeat task.wait(1) until Player:GetAttribute("Loaded") == true

    while true do
        task.wait(0.3)
        if autoClicking then
            if Player.leaderstats:FindFirstChild("Passes") and Player.leaderstats.Passes:GetAttribute("AutoClicker") ~= true then
                task.wait(0.2)
            end

            if Player:GetAttribute("AutoClick") ~= true then
                Player:SetAttribute("AutoClick", true)
            end

            WeaponsModule.Click({
                ["KeyCode"] = Enum.KeyCode.ButtonX
            }, false, nil, true)
        end
    end
end)

--auto attack
task.spawn(function()
	local Players = game:GetService("Players")
	local player = Players.LocalPlayer
	local character = player.Character or player.CharacterAdded:Wait()
	local rootPart = character:WaitForChild("HumanoidRootPart")
	local enemies = workspace:WaitForChild("__Main"):WaitForChild("__Enemies"):WaitForChild("Server")
	local dataRemoteEvent = game:GetService("ReplicatedStorage"):WaitForChild("BridgeNet2"):WaitForChild("dataRemoteEvent")

	local attackRange = 10
	local lastAttackTime = 0
	local lastUUID = nil

	local function getClosestEnemy()
		local closest = nil
		local minDist = math.huge

		for _, part in pairs(enemies:GetDescendants()) do
			if part:IsA("Part") then
				local hp = part:GetAttribute("HP")
				if hp and hp > 0 then
					local dist = (part.Position - rootPart.Position).Magnitude
					if dist <= attackRange and dist < minDist then
						minDist = dist
						closest = part
					end
				end
			end
		end

		return closest
	end

	while true do
		if autoAttackEnabled then
			local target = getClosestEnemy()
			if target then
				local uuid = target.Name
				local now = tick()

				-- Nếu target mới → reset delay cho phép đánh ngay nếu đã đủ khoảng cách
				if uuid ~= lastUUID then
					lastUUID = uuid
					lastAttackTime = now - 0.1 -- cho phép đánh ngay
				end

				if (target.Position - rootPart.Position).Magnitude <= attackRange and (now - lastAttackTime) >= 0.1 then
					local args = {
						[1] = {
							[1] = {
								["Event"] = "PunchAttack",
								["Enemy"] = uuid
							},
							[2] = "\4"
						}
					}
					pcall(function()
						dataRemoteEvent:FireServer(unpack(args))
					end)
					lastAttackTime = now
				end
			else
				lastUUID = nil
			end
		end
		task.wait() -- quét liên tục
	end
end)

-- 🏪 Section bên trái của Shop Tab
local ShopSection = Tabs.Shop:Section({ Side = "Left" })

-- 🏷 Label: Đổi DUST
ShopSection:Label({ Text = "Đổi DUST" })

-- 🧠 Mapping tên → mã exchange
local exchangeOptions = {
	["10 rare = 1 legend"] = "EnchLegendary",
	["1 legend = 1 rare"] = "EnchRare2",
	["10 common = 1 rare"] = "EnchRare"
}

-- ✅ Biến điều khiển
local selectedExchange = exchangeOptions[settings["EnchantType"]] or "EnchLegendary"
local isExchanging = false

-- 🔽 Dropdown: Chọn loại đổi
local dustDropdown = ShopSection:Dropdown({
	Name = "Loại đổi Enchant (fix)",
	Options = { "10 rare = 1 legend", "1 legend = 1 rare", "10 common = 1 rare" },
	Default = settings["EnchantType"] or "10 rare = 1 legend",
	Multi = false,
	Callback = function(option)
		local selected = typeof(option) == "table" and option[1] or option
		selectedExchange = exchangeOptions[selected]
		settings["EnchantType"] = selected
		saveSettings()
	end
}, "EnchantType")

-- 🛠 Force set đúng sau khi GUI load
task.delay(0.2, function()
	dustDropdown:UpdateSelection(settings["EnchantType"] or "10 rare = 1 legend")
end)

-- 🔁 Toggle: Auto Exchange Enchant
ShopSection:Toggle({
	Name = "Auto Exchange Enchant",
	Default = settings["AutoExchangeEnchant"],
	Callback = function(val)
		isExchanging = val
		settings["AutoExchangeEnchant"] = val
		saveSettings()

		local ReplicatedStorage = game:GetService("ReplicatedStorage")
		local remote = ReplicatedStorage:WaitForChild("BridgeNet2"):WaitForChild("dataRemoteEvent")

		if val then
			local openGUIArgs = {
				[1] = {
					[1] = {
						["Shop"] = "ExchangeShop",
						["Event"] = "OpenShop"
					},
					[2] = "\n"
				}
			}
			remote:FireServer(unpack(openGUIArgs))
		else
			local closeGUIArgs = {
				[1] = {
					[1] = {
						["Event"] = "CloseShop"
					},
					[2] = "\n"
				}
			}
			remote:FireServer(unpack(closeGUIArgs))
		end
	end
}, "AutoExchangeEnchant")

-- ♻️ Vòng lặp auto exchange
task.spawn(function()
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local remote = ReplicatedStorage:WaitForChild("BridgeNet2"):WaitForChild("dataRemoteEvent")

	while true do
		if isExchanging and selectedExchange then
			local args = {
				[1] = {
					[1] = {
						["Action"] = "Buy",
						["Shop"] = "ExchangeShop",
						["Item"] = selectedExchange,
						["Event"] = "ItemShopAction"
					},
					[2] = "\n"
				}
			}
			pcall(function()
				remote:FireServer(unpack(args))
			end)
		end
		task.wait(0.5)
	end
end)

-- 🧭 Section bên trái Teleport tab
local TeleportSection = Tabs.Teleport:Section({ Side = "Left" })

-- 🗺️ Dữ liệu các điểm dịch chuyển
local teleportData = {
	{Name = "Solo lvl", Position = CFrame.new(577.968262, 27.9623756, 261.452271)},
	{Name = "Naruto", Position = CFrame.new(-3380.2373, 29.8265285, 2257.26196)},
	{Name = "One piece", Position = CFrame.new(-2851.1062, 49.8987885, -2011.39526)},
	{Name = "Bleach", Position = CFrame.new(2641.79517, 45.9265289, -2645.07568)},
	{Name = "Black clover", Position = CFrame.new(198.338684, 39.2076797, 4296.10938)},
	{Name = "Chain sawn man", Position = CFrame.new(236.932678, 33.3960934, -4301.60547)},
	{Name = "JoJo", Position = CFrame.new(4816.31641, 30.4423409, -120.22998)},
	{Name = "DB", Position = CFrame.new(-6295.89209, 24.6981049, -73.7149353, 0, 0, 1, 0, 1, -0, -1, 0, 0)},
	{Name = "OPM", Position = CFrame.new(5994.5376, 171.666214, 4863.9458, 0.776914835, -0, -0.62960577, 0, 1, -0, 0.62960577, 0, 0.776914835)},
	{Name = "GuildHall", Position = CFrame.new(289.015015, 31.8532162, 157.246201, 1, 0, 0, 0, 1, 0, 0, 0, 1)},
}

-- 🔘 Tạo nút teleport cho từng khu
for _, data in ipairs(teleportData) do
	TeleportSection:Button({
		Name = data.Name,
		Callback = function()
			local player = game.Players.LocalPlayer
			local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
			if hrp then
				hrp.Anchored = true
				hrp.CFrame = data.Position

				MacLib:Notify({
					Title = "Teleported!",
					Content = "Đã dịch chuyển đến " .. data.Name,
					Duration = 3
				})

				task.delay(1, function()
					if hrp then hrp.Anchored = false end
				end)
			end
		end
	})
end

local RunService = game:GetService("RunService")
local Stats = game:GetService("Stats")

-- Xóa GUI cũ nếu đã tồn tại
local old = game:GetService("CoreGui"):FindFirstChild("FPSPingDisplay")
if old then
	old:Destroy()
end

-- Tạo GUI mới
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "FPSPingDisplay"
screenGui.IgnoreGuiInset = true
screenGui.ResetOnSpawn = false
screenGui.DisplayOrder = 999999
screenGui.Enabled = true

pcall(function()
	screenGui.Parent = game:GetService("CoreGui")
end)

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 240, 0, 100)
mainFrame.Position = UDim2.new(0, 10, 0, 10)
mainFrame.BackgroundTransparency = 1
mainFrame.Parent = screenGui

-- Tạo dòng text
local function createRow(y)
	local row = Instance.new("Frame")
	row.Size = UDim2.new(1, 0, 0, 30)
	row.Position = UDim2.new(0, 0, 0, y)
	row.BackgroundTransparency = 1
	row.Parent = mainFrame

	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Horizontal
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Padding = UDim.new(0, 4)
	layout.Parent = row

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(0, 50, 1, 0)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.SourceSansBold
	label.TextSize = 24
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextStrokeTransparency = 0.5
	label.Parent = row

	local value = label:Clone()
	value.Size = UDim2.new(1, -50, 1, 0)
	value.Parent = row

	return label, value
end

local fpsLabel, fpsValue = createRow(0)
local pingLabel, pingValue = createRow(30)
local timeLabel, timeValue = createRow(60)

fpsLabel.Text = "FPS:"
pingLabel.Text = "Ping:"
timeLabel.Text = "Time:"

-- Hiệu ứng rainbow
local function rainbow(offset)
	local t = tick()
	local r = 0.5 + 0.5 * math.sin(t * 3 + offset)
	local g = 0.5 + 0.5 * math.sin(t * 3 + offset + 2)
	local b = 0.5 + 0.5 * math.sin(t * 3 + offset + 4)
	return Color3.new(r, g, b)
end

-- Luồng riêng để update UI
task.spawn(function()
	local fps, count, last = 0, 0, tick()

	RunService.RenderStepped:Connect(function()
		if not screenGui.Enabled then return end

		count = count + 1
		local now = tick()

		if now - last >= 1 then
			fps = count
			count = 0
			last = now

			local pingStat = Stats:FindFirstChild("Network") and Stats.Network:FindFirstChild("ServerStatsItem")
			local ping = pingStat and pingStat["Data Ping"]:GetValue() or 0
			pingValue.Text = math.floor(ping + 0.5) .. " ms"
			fpsValue.Text = tostring(fps)
		end

		local t = os.date("*t")
		timeValue.Text = string.format("%02d:%02d:%02d", t.hour, t.min, t.sec)

		-- Rainbow màu
		fpsLabel.TextColor3 = rainbow(0)
		fpsValue.TextColor3 = rainbow(1)
		pingLabel.TextColor3 = rainbow(2)
		pingValue.TextColor3 = rainbow(3)
		timeLabel.TextColor3 = rainbow(4)
		timeValue.TextColor3 = rainbow(5)
	end)
end)

-- 🔁 Khởi động lại các toggle đã bật trong settings
task.delay(1, function()
	local function reTrigger(flag)
		local toggle = MacLib.Flags[flag]
		if toggle and settings[flag] then
			toggle:Set(false)
			task.wait(0.05)
			toggle:Set(true)
		end
	end

	local allFlags = {
		"AutoClick",
		"AutoAttack",
		"AutoLoadScript",
		"SpecialScript",
		"BypassCooldown",
		"AutoCastleCustom",
		"AutoCheckDD",
		"AutoCastleBossOut",
		"AutoCastleBossFloor",
	}

	for _, flag in ipairs(allFlags) do
		reTrigger(flag)
	end
end)

-- 🖱️ Tạo nút ImageButton GUI mở UI
local UIS = game:GetService("UserInputService")
local gui = Instance.new("ScreenGui")
gui.Name = "ImageButtonGUI"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
pcall(function()
	gui.Parent = game:GetService("CoreGui")
end)

local btn = Instance.new("ImageButton")
btn.Name = "KButton"
btn.Size = UDim2.new(0, 40, 0, 40)
btn.Position = UDim2.new(1, -40, 0.30, -25)
btn.BackgroundTransparency = 1
btn.Image = "rbxassetid://126309628188296"
btn.Parent = gui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(1, 0)
corner.Parent = btn

btn.MouseButton1Click:Connect(function()
	local vu = game:GetService("VirtualInputManager")
	vu:SendKeyEvent(true, Enum.KeyCode.K, false, game)
	vu:SendKeyEvent(false, Enum.KeyCode.K, false, game)
end)

-- 🚫 Anti-AFK
local vu = game:GetService("VirtualUser")
game:GetService("Players").LocalPlayer.Idled:Connect(function()
	vu:CaptureController()
	vu:ClickButton2(Vector2.new(0, 0))
end)
