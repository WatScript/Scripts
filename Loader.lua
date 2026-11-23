local SCRIPTS_BY_PLACE_ID = {
	[120078531045807] = "https://raw.githubusercontent.com/WatScript/Scripts/refs/heads/main/MalamSamaRembo.lua",
	[99066225512279] = "https://raw.githubusercontent.com/WatScript/Scripts/refs/heads/main/SebutkanSemuaNama.lua",
}

local target_url = SCRIPTS_BY_PLACE_ID[game.PlaceId]

if target_url then
	loadstring(game:HttpGet(target_url))()
else
	warn("WatHUB: Tidak ada skrip didaftarkan untuk PlaceId -> " .. tostring(game.PlaceId))
end