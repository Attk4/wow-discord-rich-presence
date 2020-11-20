local frame_count = 0
local frames = {}
local realmData = {"US", "KR", "EU", "TW", "CH"}
local last_encoded = ""

function DRP_CreateFrames()
	local size = 12
	frame_count = math.floor(GetScreenWidth() / size)
	-- print("Max bytes that can be stored: " .. (frame_count * 3) - 1)

	for i=1, frame_count do
		frames[i] = CreateFrame("Frame", nil, UIParent)
		frames[i]:SetFrameStrata("TOOLTIP")
		frames[i]:SetWidth(size)
		frames[i]:SetHeight(size)

		-- initialise it as black
		local t = frames[i]:CreateTexture(nil, "TOOLTIP")
		t:SetColorTexture(0, 0, 0, 1)
		t:SetAllPoints(frames[i])
		frames[i].texture = t

		frames[i]:SetPoint("TOPLEFT", (i - 1) * size, 0)
		frames[i]:Show()
	end
	return frames
end

function DRP_PaintFrame(frame, r, g, b, force)
	-- turn them into black if they are null
	if r == nil then r = 0 end
	if g == nil then g = 0 end
	if b == nil then b = 0 end

	-- from 0-255 to 0.0-1.0
	r = r / 255
	g = g / 255
	b = b / 255

    -- set alpha to 1 if this pixel is black and force is 0 or null
	if r == 0 and g == 0 and b == 0 and (force == 0 or force == nil) then a = 0 else a = 1 end

    -- and now paint it
	frame.texture:SetColorTexture(r, g, b, a)
	frame.texture:SetAllPoints(frame)
end

function DRP_PaintSomething(text)
	local max_bytes = (frame_count - 1) * 3
	if text:len() >= max_bytes then
		-- print("You're painting too many bytes (" .. #text .. " vs " .. max_bytes .. ")")
		return
	end

	-- clean all
	DRP_CleanFrames()

	local squares_painted = 0

	for trio in text:gmatch".?.?.?" do
		r = 0; g = 0; b = 0
		r = string.byte(trio:sub(1,1))
		if #trio > 1 then g = string.byte(trio:sub(2,2)) end
		if #trio > 2 then b = string.byte(trio:sub(3,3)) end
		squares_painted = squares_painted + 1
		DRP_PaintFrame(frames[squares_painted], r, g, b)
	end

	-- and then paint the last one black
	DRP_PaintFrame(frames[squares_painted], 0, 0, 0, 1)
end

function DRP_EncodeZoneType()
	local name, instanceType, difficultyID, difficultyName, maxPlayers,
		dynamicDifficulty, isDynamic, instanceID, instanceGroupSize, LfgDungeonID = GetInstanceInfo()
	local firstLine = nil
	local secondLineFirst = nil
	local secondLineSecond = nil
	local playerName = UnitName("player")
	local playerRealm = GetRealmName()
	local playerRegion = realmData[GetCurrentRegion()]
	local playerClass = UnitClass("player")
	local zone_name = GetRealZoneText()
	if(zone_name == nil) then zone_name = "Not available" end
	local sub_name = GetSubZoneText()
	if instanceType == 'party' then
		firstLine = zone_name
		secondLine = string.format('In %s Dungeon', difficultyName)
	elseif instanceType == 'raid' then
		firstLine = zone_name
		secondLine = string.format('In %s Raid', difficultyName)
	elseif instanceType == 'pvp' then
		firstLine = zone_name
		secondLine = "In Battleground"
	else
		if UnitIsDeadOrGhost("player") and not UnitIsDead("player") then
			firstLine = sub_name
			secondLine = "Corpse Running"
		else
			firstLine = sub_name
			secondLine = zone_name
		end
	end
	local playerInfo = playerName .. " - " .. playerClass
	local realmInfo = playerRegion .. " - " .. playerRealm
	if firstLine == "" or firstLine == nil or secondLine == "" or secondLine == nil then return nil end
	return "$WorldOfWarcraftDRP$" .. firstLine .. "|" .. secondLine .. "|" .. playerInfo .. "|" .. realmInfo .. "$WorldOfWarcraftDRP$"
end

function DRP_CleanFrames()
	for i=1, frame_count do
		DRP_PaintFrame(frames[i], 0, 0, 0, 0)
	end
end

function paintMessageWait()
	local encoded = DRP_EncodeZoneType()
	if(last_encoded ~= encoded and encoded ~= nil) then
		last_encoded = encoded
		DRP_PaintSomething(encoded)
		C_Timer.After(10, DRP_CleanFrames)
	end
end

function DRP_OnLoad()
	print("Discord Rich Presence Loaded")
	DRPFrame:RegisterEvent("PLAYER_LOGIN")
	DRPFrame:RegisterEvent("ZONE_CHANGED")
	DRPFrame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
	DRPFrame:RegisterEvent("ZONE_CHANGED_INDOORS")
	DRPFrame:RegisterEvent("PLAYER_UNGHOST")
	DRP_CreateFrames()
	paintMessageWait()
end

function DRP_OnEvent(event)
	paintMessageWait()
end

SLASH_DRP1, SLASH_DRP2 = '/drp', '/discordrichpresence'
function SlashCmdList.DRP()
	paintMessageWait()
end

SLASH_DRPTEST1 = '/drptest'
function SlashCmdList.DRPTEST()
	local encoded = DRP_EncodeZoneType()
	if encoded ~= nil then DRP_PaintSomething(encoded) end
end

SLASH_CLEAN1 = '/drpclean'
function SlashCmdList.CLEAN()
	DRP_CleanFrames()
end
