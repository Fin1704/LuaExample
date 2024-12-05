local LANGUAGES = {
	en_us = "English",
	ja_jp = "Japanese",
	vi_vn = "Vietnamese",
	it_it = "Italian",
	fr_fr = "French",
	id_id = "Indonesian",
	pl_pl = "Polish",
	zh_tw = "Chinese (Traditional)",
	zh_cn = "Chinese (Simplified)"
}

local GuiService = game:GetService("GuiService")
local UIService = game:GetService("UserInputService")
local platform = "PC"

if GuiService:IsTenFootInterface() then
	platform = "PAD"
	elseif UIService.TouchEnabled and not UIService.MouseEnabled then
	platform = "SP"
end

local DEFAULT_LANGUAGE = "ja_jp"
local OTHER_LOCALIZATION = "en_us"
local MAX_TIMEOUT = 10
local localeId = DEFAULT_LANGUAGE:gsub("-", "_")

local logger = require(script.Parent:WaitForChild("Logger"))
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local TweenService = game:GetService("TweenService")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local currentLocaleId = player.LocaleId
local isRunning = false

local function sizeOf(tbl)
	local count = 0
	for _ in pairs(tbl) do
		count += 1
	end
	return count
end

local function findNonTableData(tbl)
	local result = {}
	for _, value in pairs(tbl) do
		if type(value) ~= "table" then
			table.insert(result, value)
		else
			local subResult = findNonTableData(value)
			for _, data in ipairs(subResult) do
				table.insert(result, data)
			end
		end
	end
	return result
end

local function findImageObjList(ui)
	local result = {}
	for _, child in ipairs(ui:GetChildren()) do
		if (child:IsA("ImageLabel") or child:IsA("ImageButton")) and sizeOf(child:GetAttributes()) > 0 then
			table.insert(result, child)
		end
		if sizeOf(child:GetChildren()) > 0 then
			local subResult = findImageObjList(child)
			for _, subChild in ipairs(subResult) do
				table.insert(result, subChild)
			end
		end
	end
	return findNonTableData(result)
end

local function screenLoading(isLoading)
	local loadingUI = playerGui:FindFirstChild("NowLoading")
	if loadingUI then
		loadingUI.Enabled = isLoading
	end
end

local function LocalizationUI(newLocaleId)
	isRunning = true
	local startTime = os.time()
	local loadedImages = 0
	local imageList = findImageObjList(playerGui)
	local totalImages = 0
	local loadingList = {}

	for i, image in ipairs(imageList) do
		local attr = image:GetAttribute(newLocaleId:gsub("-", "_"))
			or image:GetAttribute(newLocaleId:gsub("-", "_") .. "_" .. platform)
			or image:GetAttribute(OTHER_LOCALIZATION:gsub("-", "_"))

		if attr then
			totalImages += 1
			image.Image = attr
			spawn(function()
				loadingList[i] = image
				while not image.IsLoaded and isRunning do
					task.wait()
				end
				logger.log(image.Name .. " loaded!")
				loadedImages += 1
				loadingList[i] = nil
			end)
		end
	end

	spawn(function()
		while totalImages - loadedImages > 0 and os.time() - startTime < MAX_TIMEOUT and isRunning do
			task.wait()
		end
		isRunning = false

		if totalImages - loadedImages == 0 then
			logger.log("[LocalizationUI] All localization UI loaded")
		elseif os.time() - startTime >= MAX_TIMEOUT then
			logger.warn("[LocalizationUI] Timeout reached. Disabling UI.")
			logger.log("Error with locale [" .. newLocaleId:gsub("-", "_") .. "]: ")
			logger.log(loadingList)
		end

		screenLoading(false)
	end)
end

local function changeMeshParts()
	local taggedParts = CollectionService:GetTagged("Localization")
	local newLocaleId = player.LocaleId
	for _, part in ipairs(taggedParts) do
		if part:IsA("MeshPart") then
			local attr = part:GetAttribute(newLocaleId:gsub("-", "_"))
				or part:GetAttribute(newLocaleId:gsub("-", "_") .. "_" .. platform)
				or part:GetAttribute(OTHER_LOCALIZATION:gsub("-", "_"))
			part.TextureID = attr
		end
	end
end

local function checkLocaleChange()
	local newLocaleId = player.LocaleId
	if newLocaleId ~= currentLocaleId then
		isRunning = false
		screenLoading(true)
		currentLocaleId = newLocaleId
		LocalizationUI(newLocaleId)
		changeMeshParts()
		--ReplicatedStorage.BF.ChangeLanguage:Fire(newLocaleId)
	end
end

local imageList = findImageObjList(playerGui)
for _, image in ipairs(imageList) do
	local attr = image:GetAttribute(localeId)
	if not attr then
		image:SetAttribute(localeId, image.Image)
	end
end

logger.warn("[LocalizationUI] Reloading localization...")
LocalizationUI(currentLocaleId)

spawn(function()
	while true do
		task.wait(1)
		checkLocaleChange()
	end
end)

wait(3)
changeMeshParts()
