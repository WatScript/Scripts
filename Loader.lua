local Players = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")

local HUB_NAME = "WatHUB"
local VERSION = "v1.0"

local SCRIPTS_BY_PLACE_ID = {
	[120078531045807] = {
		Name = "Malam Sama Ayam",
		Url = "https://raw.githubusercontent.com/WatScript/Scripts/refs/heads/main/MalamSamaRembo.lua",
	},
	[99066225512279] = {
		Name = "Name Them All",
		Url = "https://raw.githubusercontent.com/WatScript/Scripts/refs/heads/main/SebutkanSemuaNama.lua",
	},
}

local function sendNotify(title, text, duration)
	pcall(function()
		StarterGui:SetCore("SendNotification", {
			Title = title,
			Text = text,
			Duration = duration or 5,
		})
	end)
end

local placeId = game.PlaceId
local entry = SCRIPTS_BY_PLACE_ID[placeId]
local playerName = Players.LocalPlayer and Players.LocalPlayer.Name or "Player"

print(string.format("[%s %s] Memeriksa PlaceId: %s | Pengguna: %s", HUB_NAME, VERSION, tostring(placeId), playerName))

if not entry then
	warn(string.format("[%s] Map tidak disokong (PlaceId: %s)", HUB_NAME, tostring(placeId)))
	sendNotify(
		HUB_NAME .. " | Unsupported",
		"Map ini belum disokong (" .. tostring(placeId) .. ").",
		6
	)
	return
end

sendNotify(
	HUB_NAME .. " | Loading",
	"Memuatkan skrip untuk " .. entry.Name .. "...",
	4
)

local fetchOk, sourceCode = pcall(function()
	return game:HttpGet(entry.Url)
end)

if not fetchOk or type(sourceCode) ~= "string" or sourceCode == "" then
	warn(string.format("[%s] Gagal memuatkan skrip %s: %s", HUB_NAME, entry.Name, tostring(sourceCode)))
	sendNotify(
		HUB_NAME .. " | Error",
		"Gagal memuatkan skrip " .. entry.Name .. ".",
		6
	)
	return
end

local fn, compileErr = loadstring(sourceCode)
if not fn then
	warn(string.format("[%s] Ralat sintaks pada %s: %s", HUB_NAME, entry.Name, tostring(compileErr)))
	sendNotify(
		HUB_NAME .. " | Syntax Error",
		"Ralat kod pada skrip " .. entry.Name .. ".",
		6
	)
	return
end

local runOk, runErr = pcall(fn)
if not runOk then
	warn(string.format("[%s] Ralat semasa menjalankan %s: %s", HUB_NAME, entry.Name, tostring(runErr)))
	sendNotify(
		HUB_NAME .. " | Runtime Error",
		"Skrip " .. entry.Name .. " mengalami ralat.",
		6
	)
end
