local Players = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local MarketplaceService = game:GetService("MarketplaceService")

local HUB_NAME = "WatHUB"
local VERSION = "v1.0"

local SCRIPTS_BY_PLACE_ID = {
	[84882418635353] = {
		Name = "Malam Sama Ayam",
		Url = "https://raw.githubusercontent.com/WatScript/Scripts/refs/heads/main/MalamSamaRembo.lua",
	},
	[72594159905471] = {
		Name = "Malam Sama Ayam - Chapter 2",
		Url = "https://raw.githubusercontent.com/WatScript/Scripts/refs/heads/main/MalamSamaRemboCh2.lua",
	},
	[99066225512279] = {
		Name = "Name Them All",
		Url = "https://raw.githubusercontent.com/WatScript/Scripts/refs/heads/main/SebutkanSemuaNama.lua",
	},
	[101051454784523] = {
		Name = "Malam Sama Nenek",
		Url = "https://raw.githubusercontent.com/WatScript/Scripts/refs/heads/main/MalamSamaNenek.lua",
	},
}

-- Letakkan PlaceId lobby di sini (pastikan PlaceId yang sama tidak berada di SCRIPTS_BY_PLACE_ID)
local LOBBY_MESSAGES_BY_PLACE_ID = {
	[120078531045807] = {
		Status = "Lobby",
		Color = "#FFD43B",
		Message = '<font color="#FFFFFF">Silakan masuk ke bus dahulu untuk memulakannya.</font>',
	},
	[91246277860636] = {
		Status = "Lobby",
		Color = "#FFD43B",
		Message = '<font color="#FFFFFF">Silakan masuk ke bus dahulu untuk memulakannya.</font>',
	},
}

local function getCurrentGameName(placeId)
	local ok, info = pcall(function()
		return MarketplaceService:GetProductInfoAsync(placeId, Enum.InfoType.Asset)
	end)

	if ok and info and type(info.Name) == "string" and info.Name ~= "" then
		return info.Name
	end

	if game.Name and game.Name ~= "" and game.Name ~= "Roblox" then
		return game.Name
	end

	return "Place " .. tostring(placeId)
end

local function getParentGui()
	local localPlayer = Players.LocalPlayer
	if localPlayer then
		local playerGui = localPlayer:FindFirstChildOfClass("PlayerGui")
		if playerGui then
			return playerGui
		end
	end

	local coreOk, coreGui = pcall(function()
		return game:GetService("CoreGui")
	end)
	if coreOk and coreGui then
		return coreGui
	end

	return nil
end

local function showCustomNotify(statusLabel, statusColorHex, bodyRichText, duration)
	local parentGui = getParentGui()
	if not parentGui then
		pcall(function()
			StarterGui:SetCore("SendNotification", {
				Title = HUB_NAME .. " | " .. statusLabel,
				Text = bodyRichText:gsub("<[^>]+>", ""),
				Duration = duration or 3,
			})
		end)
		return
	end

	local oldGui = parentGui:FindFirstChild("WatHUB_CustomNotify")
	if oldGui then
		oldGui:Destroy()
	end

	local cardWidth = 310
	local cardHeight = 64
	local topMargin = 14
	local rightMargin = 14

	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "WatHUB_CustomNotify"
	screenGui.ResetOnSpawn = false
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	screenGui.DisplayOrder = 999999
	screenGui.Parent = parentGui

	local card = Instance.new("Frame")
	card.Name = "Card"
	card.AnchorPoint = Vector2.new(1, 0)
	card.Position = UDim2.new(1, cardWidth + 30, 0, topMargin)
	card.Size = UDim2.new(0, cardWidth, 0, cardHeight)
	card.BackgroundColor3 = Color3.fromRGB(16, 18, 24)
	card.BackgroundTransparency = 0.14
	card.BorderSizePixel = 0
	card.Parent = screenGui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 9)
	corner.Parent = card

	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 1.8
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Color = Color3.fromRGB(255, 255, 255)
	stroke.Parent = card

	local rainbowGrad = Instance.new("UIGradient")
	rainbowGrad.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0.00, Color3.fromRGB(255, 65, 65)),
		ColorSequenceKeypoint.new(0.20, Color3.fromRGB(255, 190, 40)),
		ColorSequenceKeypoint.new(0.40, Color3.fromRGB(70, 235, 110)),
		ColorSequenceKeypoint.new(0.60, Color3.fromRGB(55, 185, 255)),
		ColorSequenceKeypoint.new(0.80, Color3.fromRGB(175, 85, 255)),
		ColorSequenceKeypoint.new(1.00, Color3.fromRGB(255, 65, 65)),
	})
	rainbowGrad.Parent = stroke

	local titleLabel = Instance.new("TextLabel")
	titleLabel.BackgroundTransparency = 1
	titleLabel.Position = UDim2.new(0, 10, 0, 6)
	titleLabel.Size = UDim2.new(1, -20, 0, 18)
	titleLabel.Font = Enum.Font.GothamBold
	titleLabel.TextSize = 13
	titleLabel.TextXAlignment = Enum.TextXAlignment.Left
	titleLabel.RichText = true
	titleLabel.Text = string.format(
		'<font color="#2ECC71">W</font><font color="#FFFFFF">at</font><font color="#FF8C1A">HUB</font><font color="#FFFFFF"> | </font><font color="%s">%s</font>',
		statusColorHex,
		statusLabel
	)
	titleLabel.Parent = card

	local descLabel = Instance.new("TextLabel")
	descLabel.BackgroundTransparency = 1
	descLabel.Position = UDim2.new(0, 10, 0, 25)
	descLabel.Size = UDim2.new(1, -20, 1, -30)
	descLabel.Font = Enum.Font.Gotham
	descLabel.TextSize = 12
	descLabel.TextWrapped = true
	descLabel.TextXAlignment = Enum.TextXAlignment.Left
	descLabel.TextYAlignment = Enum.TextYAlignment.Top
	descLabel.RichText = true
	descLabel.Text = bodyRichText
	descLabel.Parent = card

	local rotConn
	rotConn = RunService.RenderStepped:Connect(function(dt)
		if not screenGui.Parent then
			if rotConn then
				rotConn:Disconnect()
			end
			return
		end
		rainbowGrad.Rotation = (rainbowGrad.Rotation + dt * 120) % 360
	end)

	local slideIn = TweenService:Create(
		card,
		TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
		{ Position = UDim2.new(1, -rightMargin, 0, topMargin) }
	)
	slideIn:Play()

	task.delay(duration or 3, function()
		if rotConn then
			rotConn:Disconnect()
		end
		if not card or not card.Parent then
			return
		end
		local slideOut = TweenService:Create(
			card,
			TweenInfo.new(0.22, Enum.EasingStyle.Quint, Enum.EasingDirection.In),
			{ Position = UDim2.new(1, cardWidth + 30, 0, topMargin) }
		)
		slideOut:Play()
		slideOut.Completed:Connect(function()
			if screenGui and screenGui.Parent then
				screenGui:Destroy()
			end
		end)
	end)
end

local placeId = game.PlaceId
local entry = SCRIPTS_BY_PLACE_ID[placeId]
local lobbyInfo = LOBBY_MESSAGES_BY_PLACE_ID[placeId]
local playerName = Players.LocalPlayer and Players.LocalPlayer.Name or "Player"

print(string.format("[%s %s] Memeriksa PlaceId: %s | Pengguna: %s", HUB_NAME, VERSION, tostring(placeId), playerName))

if entry then
	local supportMsg = string.format(
		'<font color="#FFFFFF">Map disokong! Script </font><font color="#FFD43B">%s</font><font color="#FFFFFF"> sedang dimuatkan...</font>',
		entry.Name
	)
	showCustomNotify("Support", "#2ECC71", supportMsg, 2.8)

	local fetchOk, sourceCode = pcall(function()
		return game:HttpGet(entry.Url)
	end)

	if not fetchOk or type(sourceCode) ~= "string" or sourceCode == "" then
		warn(string.format("[%s] Gagal memuatkan skrip %s: %s", HUB_NAME, entry.Name, tostring(sourceCode)))
		local errMsg = string.format(
			'<font color="#FFFFFF">Gagal memuatkan script </font><font color="#FFD43B">%s</font><font color="#FFFFFF">.</font>',
			entry.Name
		)
		showCustomNotify("Error", "#FF3B30", errMsg, 3.5)
		return
	end

	local fn, compileErr = loadstring(sourceCode)
	if not fn then
		warn(string.format("[%s] Ralat sintaks pada %s: %s", HUB_NAME, entry.Name, tostring(compileErr)))
		local synMsg = string.format(
			'<font color="#FFFFFF">Ralat sintaks pada script </font><font color="#FFD43B">%s</font><font color="#FFFFFF">.</font>',
			entry.Name
		)
		showCustomNotify("Syntax Error", "#FF3B30", synMsg, 3.5)
		return
	end

	local runOk, runErr = pcall(fn)
	if not runOk then
		warn(string.format("[%s] Ralat semasa menjalankan %s: %s", HUB_NAME, entry.Name, tostring(runErr)))
		local runMsg = string.format(
			'<font color="#FFFFFF">Ralat semasa menjalankan </font><font color="#FFD43B">%s</font><font color="#FFFFFF">.</font>',
			entry.Name
		)
		showCustomNotify("Runtime Error", "#FF3B30", runMsg, 3.5)
	end
elseif lobbyInfo then
	showCustomNotify(lobbyInfo.Status, lobbyInfo.Color, lobbyInfo.Message, 4)
	return
else
	local currentGameName = getCurrentGameName(placeId)
	warn(string.format("[%s] Map tidak disokong: %s (PlaceId: %s)", HUB_NAME, currentGameName, tostring(placeId)))

	local msg = string.format(
		'<font color="#FFFFFF">Maaf, </font><font color="#2ECC71">W</font><font color="#FFFFFF">at</font><font color="#FF8C1A">HUB</font><font color="#FFFFFF"> belum buat script untuk </font><font color="#FFD43B">%s</font><font color="#FFFFFF">.</font>',
		currentGameName
	)

	showCustomNotify("Unsupported", "#FF3B30", msg, 3.5)
	return
end
