local placeIdStr = string.format("%.0f", game.PlaceId)
local gameId = game.GameId

if placeIdStr == "2753915549" or placeIdStr == "79091703265657" or placeIdStr == "100117331123089" then
    loadstring(game:HttpGet("https://raw.githubusercontent.com/tyxca01/ActriumHub/refs/heads/main/BloxFruits.lua"))()
elseif gameId == 10200395747 then
    loadstring(game:HttpGet("https://raw.githubusercontent.com/tyxca01/ActriumHub/refs/heads/main/GrowaGarden2.lua"))()
else
    print("Unsupported PlaceId: " .. placeIdStr .. " | GameId: " .. tostring(gameId))
end
