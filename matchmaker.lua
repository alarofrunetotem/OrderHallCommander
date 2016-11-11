local __FILE__=tostring(debugstack(1,2,0):match("(.*):1:")) -- Always check line number in regexp and file
--*TYPE module
--*CONFIG noswitch=false,profile=true,enhancedProfile=true
--*MIXINS "AceHook-3.0","AceEvent-3.0","AceTimer-3.0","AceSerializer-3.0","AceConsole-3.0"
--*MINOR 35
-- Generated on 04/11/2016 15:14:56
local me,ns=...
local addon=ns --#Addon (to keep eclipse happy)
ns=nil
local module=addon:NewSubModule('Matchmaker',"AceHook-3.0","AceEvent-3.0","AceTimer-3.0","AceSerializer-3.0","AceConsole-3.0")  --#Module
function addon:GetMatchmaker() return module end
-- Template
local G=C_Garrison
local _
local AceGUI=LibStub("AceGUI-3.0")
local C=addon:GetColorTable()
local L=addon:GetLocale()
local new=addon.NewTable
local del=addon.DelTable
local kpairs=addon:GetKpairs()
local OHF=OrderHallMissionFrame
local OHFMissionTab=OrderHallMissionFrame.MissionTab --Container for mission list and single mission
local OHFMissions=OrderHallMissionFrame.MissionTab.MissionList -- same as OrderHallMissionFrameMissions 
local OHFFollowerTab=OrderHallMissionFrame.FollowerTab -- Contains model view
local OHFFollowerList=OrderHallMissionFrame.FollowerList -- Contains follower list (visibe in both follower and mission mode)
local OHFFollowers=OrderHallMissionFrameFollowers -- Contains scroll list
local OHFMissionPage=OrderHallMissionFrame.MissionTab.MissionPage -- Contains mission description and party setup 
local OHFMapTab=OrderHallMissionFrame.MapTab -- Contains quest map
--*if-non-addon*
local ShowTT=OrderHallCommanderMixin.ShowTT
local HideTT=OrderHallCommanderMixin.HideTT
--*end-if-non-addon*
local dprint=print
local ddump
--@debug@
LoadAddOn("Blizzard_DebugTools")
ddump=DevTools_Dump
LoadAddOn("LibDebug")
--*if-non-addon*
if LibDebug then LibDebug() dprint=print end
--*end-if-non-addon*
--[===[*if-addon*
-- Addon Build, we need to create globals the easy way
local function encapsulate()
if LibDebug then LibDebug() dprint=print end
end
encapsulate()
--*end-if-addon*[===]
--@end-debug@
--[===[@non-debug@
dprint=function() end
ddump=function() end
local print=function() end
--@end-non-debug@]===]

-- End Template
--*BEGIN 
local function parse(default,rc,...)
	if rc then 
		return ... 
	else
	--@debug@
		error(message,2) 
	--@end-debug@
		return default
	end
end
	
local meta={
__index = function(t,key)
	return function(...) return parse(nil,pcall(C_Garrison[key],...)) end end
}
--upvalues
local MAX_LEVEL=110
local assert,pairs,wipe,GetFramesRegisteredForEvent=assert,pairs,wipe,GetFramesRegisteredForEvent
local followerType=LE_FOLLOWER_TYPE_GARRISON_7_0
local parties={}
local party={} --#Party Metatable for party managementy
local emptyTable={}
local holdEvents
local releaseEvents
local champions={}
local troops={}
local catPool={}
local numChampions=0
local numTroops=0
local troopTypes={}
function module:Clear(event,...)
	if next(parties) then
		for k,v in pairs(parties) do
			parties[k]:release()
		end
		wipe(parties)
	end
	wipe(champions)
	wipe(troops)
	wipe(troopTypes)
end
function module:ClearTroops(event,...)
	wipe(troops)
	wipe(troopTypes)
end
function module:GetParty(missionID)
	if not parties[missionID] then
		parties[missionID]=party:new(missionID)
	end
	return parties[missionID]
end

---@function
-- This function serves 2 purposes:
-- 1) Keep a count of followers and troops
-- 2) Update icons in OrderHall main frame
function module:ParseFollowers()
	local categoryInfo = C_Garrison.GetClassSpecCategoryInfo(LE_FOLLOWER_TYPE_GARRISON_7_0);
	local numCategories = #categoryInfo;
	local prevCategory, firstCategory;
	local xSpacing = 20;	-- space between categories
	for _,t in pairs(troops) do
		del(t)
	end
	wipe(troopTypes)
	wipe(champions)
	for i,t in pairs(troops) do
		wipe(t)
	end
	numChampions=0
	numTroops=0
	for index, category in ipairs(categoryInfo) do
		if not catPool[index] then
			catPool[index]=CreateFrame("Frame","FollowerIcon",OHF,"OrderHallClassSpecCategoryTemplate")
		end
		if category.count>0 then
			tinsert(troopTypes,category.classSpec)
		end
		local categoryInfoFrame = catPool[index];
		categoryInfoFrame.Icon:SetTexture(category.icon);
		categoryInfoFrame.Icon:SetTexCoord(0, 1, 0.25, 0.75)
		categoryInfoFrame.TroopPortraitCover:Hide()		
		categoryInfoFrame.Icon:SetHeight(15)
		categoryInfoFrame.Icon:SetWidth(35)
		categoryInfoFrame.name = category.name;
		categoryInfoFrame.description = category.description;
		categoryInfoFrame.Count:SetFormattedText(ORDER_HALL_COMMANDBAR_CATEGORY_COUNT, category.count, category.limit);
		categoryInfoFrame:ClearAllPoints();
		if (not firstCategory) then
			-- calculate positioning so that the set of categories ends up being centered
			categoryInfoFrame:SetPoint("TOPLEFT", OHF, "TOPRIGHT", (0 - (numCategories * (categoryInfoFrame:GetWidth() + xSpacing))) - 30, 2);
			firstCategory = categoryInfoFrame;
		else
			categoryInfoFrame:SetPoint("TOPLEFT", prevCategory, "TOPRIGHT", xSpacing, 2);
		end
		categoryInfoFrame:Show();
		prevCategory = categoryInfoFrame;
	end
	for i,follower in pairs(addon:GetChampionData()) do
		if follower.isCollected then
			if follower.isTroop then
				if not troops[follower.classSpec] then
					troops[follower.classSpec]=new()
				end
				tinsert(troops[follower.classSpec],format("%d,%s",follower.durability,follower.followerID))
				numTroops=numTroops+1
			else
				tinsert(champions,follower)
				numChampions=numChampions+1
			end
		end  
	end
end
function module:GetChampions()
	if #champions == 0 then self:ParseFollowers() end
	return champions
end
function module:GetTroop(troopType,used,skipBusy)
	if #troops== 0 then self:ParseFollowers() end
	if troops[troopType] then
		for _,blob in ipairs(troops[troopType]) do
			local durability,troopId=strsplit(',',blob)
			if troopId  and not tContains(used,troopId) then
				local status=G.GetFollowerStatus(troopId)
				if not status or 
					(status~=GARRISON_FOLLOWER_IN_PARTY and not skipBusy) then
					return troopId,tonumber(durability)
				end
			end
		end
	end
	return nil,0
end
function module:GetTroopsTypes()
	if #troopTypes == 0 then self:ParseFollowers() end
	return troopTypes
end
function module:OnInitialized()
	self:RegisterEvent("GARRISON_FOLLOWER_REMOVED","Clear")
	self:RegisterEvent("GARRISON_FOLLOWER_DURABILITY_CHANGED","ClearTroops")
	addon:AddLabel(L["Matchmaking"])
	addon:AddBoolean("XP",false,"Use epic in XP mission","Try not to use Maxed followers for xp missions")
	addon:AddBoolean("SAVETROOPS",true,"Always counter kill troops","If we have troops with just one life left, we use them and ignore this flag")
	addon:AddSlider("MISSIONMIN",50,0,200,"Min mission level","If mission chance is under this value, no prefill is done")
	addon:RegisterForMenu("mission",
		"SAVETROOPS",
		"XP",
		"MISSIONMIN")
	
end
local events={stacklevel=0,frames={}} --#events
function events.hold() --#eventsholdEvents
	if events.stacklevel==0 then
		events.frames={GetFramesRegisteredForEvent('GARRISON_FOLLOWER_LIST_UPDATE')}
		for i=1,#events.frames do
			events.frames[i]:UnregisterEvent("GARRISON_FOLLOWER_LIST_UPDATE")
		end
	end
	events.stacklevel=events.stacklevel+1
end
function events.release()
	events.stacklevel=events.stacklevel-1
	assert(events.stacklevel>=0)
	if (events.stacklevel==0) then
		for i=1,#events.frames do
			events.frames[i]:RegisterEvent("GARRISON_FOLLOWER_LIST_UPDATE")
		end
		events.frames=nil
	end
end
holdEvents=events.hold
releaseEvents=events.release
local maxtime=3600*24*7
function party:GetFollowers(perc,dbg)
	if #self.candidatesIndex <1 then return
		emptyTable,perc or 0
	end
	local followers={}
	local nextAvail=maxtime
	local maxDurability=0
	for _,index in ipairs(self.candidatesIndex) do
		local candidate=self.candidates[index]
		if dbg then module:Print("Checking index",index,unpack(candidate.followers)) end
		local timeToReady=0
		local previousID
		local durability
		for _,followerID in ipairs(candidate.followers) do
			if type(followerID)=="number" then
				if dbg then print("Searching troop of type",followerID) end
				followerID,durability=module:GetTroop(followerID,followers,true)
				maxDurability=math.max(maxDurability,durability)
				if not followerID then
					if dbg then print("Troop not found") end
					break -- no available troop
				else
					if dbg then print("Troop found:",followerID) end
					previousID=followerID
				end
			end
			local status=G.GetFollowerStatus(followerID)
			if dbg then module:Print(G.GetFollowerName(followerID),status) end
			if status and status==GARRISON_FOLLOWER_ON_MISSION then
				timeToReady=math.max(timeToReady,G.GetFollowerMissionTimeLeftSeconds(followerID))
				-- busy follower
				if timeToReady <1 then
					if dbg then module:Print(G.GetFollowerName(followerID),"taken for time") end
					tinsert(followers,followerID)
				else
					if dbg then module:Print(G.GetFollowerName(followerID),"refused for time") end
				end
			elseif status then
				if dbg then module:Print(G.GetFollowerName(followerID),"refused for status") end
				timeToReady=maxtime
				break -- Inactive follower
			else
				if dbg then module:Print(G.GetFollowerName(followerID),"taken for status") end
				tinsert(followers,followerID)
			end
		end
		if timeToReady > 0 then
			nextAvail=math.min(nextAvail,timeToReady)
		end	
		if #followers==#candidate.followers then return followers,candidate.perc,timeToReady end
		wipe(followers)
	end
	return emptyTable,perc,nextAvail
end
function party:new(missionID)
	local t=setmetatable(new(),{__index=party})
	t.missionID=missionID
	local mission=addon:GetMissionData(missionID)
	t.requiredChampionCount=mission.requiredChampionCount or 1
	t.numFollowers=mission.numFollowers or 3
	t.level=mission.level
	t.iLevel=mission.iLevel
	t.effectiveLevel=mission.isMaxLevel and mission.iLevel or mission.level
	t.candidatesIndex=new()
	t.candidates=new()
	return t:Match()

end
function party:release()
	setmetatable(self,nil)
	del(self.candidatesIndex)
	del(self.candidates)
	del(self,true)
end
function party:Remove(followers,keep)
	for _,id in ipairs(followers) do
		pcall(G.RemoveFollowerFromMission,self.missionID,id)
	end
	if not keep then del(followers) end
end
function party:Build(...)
	local followers=new()
	local trueFollowers=new()
	local lastId=""
	local nTroops=0
	local nChampions=0
	local ok=true
	for i=1,self.numFollowers do
		local id,durability=select(i,...),100
		if not id then return self:Remove(followers) end
		local followerID=id
		if type(id)=="number" then -- is a troop type
			followerID,durability=module:GetTroop(id,trueFollowers)
			dprint(id,"converted to",followerID)
			nTroops=nTroops+1
			if not id then return self:Remove(followers) end
		else
			nChampions=nChampions+1
		end
		lastId=followerID
		local rc,res = pcall(G.AddFollowerToMission,self.missionID,followerID)
		ok = ok and rc and res
		if not ok then dprint("Failure adding",followerID) return self:Remove(trueFollowers) end
		tinsert(trueFollowers,followerID)
		tinsert(followers,id) -- Inside party we store the generic class for troops
	end 
	local timeImproved,chance,buffs,mechanics,xpBonus,materials,gold=select(3,G.GetPartyMissionInfo(self.missionID))
	self:Remove(trueFollowers,true)
	if chance >10 then
		mechanics.followers=followers
		mechanics.perc=chance
		mechanics.timeImproved=timeImproved
		mechanics.xpBonus=xpBonus
		mechanics.materials=materials
		mechanics.gold=gold
		self.candidates[format("%04d",1000-chance)]=mechanics
	end
--totalTimeString, totalTimeSeconds, isMissionTimeImproved, successChance, partyBuffs, counteredMechanics, xpBonus, materialMultiplier, goldMultiplier = C_Garrison.GetPartyMissionInfo(MISSION_PAGE_FRAME.missionInfo.missionID);
	
end	
function party:Reset()
	wipe(self.candidates)
end
function party:IsLowLevel(follower)
	return self.level-follower.level >4 or self.iLevel-follower.iLevel >25 
end
function party:Match()
	local start=GetTime()
	local champions=new()
	local troops=new()
	holdEvents()
	local champs=module:GetChampions()
	local totChamps=#champs
	local troopsTypes=module:GetTroopsTypes()
	for i,champ in ipairs(champs) do
		if coroutine.running() then coroutine.yield() end
		for n=i+1,totChamps do
			if n < totChamps then
				--if self:IsLowLevel(champs[n+1]) then break end
				self:Build(champ.followerID,champs[n].followerID,champs[n+1].followerID)
			end
			for _,troopType in ipairs(troopTypes) do
				self:Build(champ.followerID,champs[n].followerID,troopType)
			end
			if self.requiredChampionCount <3 then
				for n,troopType in ipairs(troopTypes) do
					self:Build(champ.followerID,champs[n].followerID,troopType)
					if self.requiredChampionCount < 2 then
						self:Build(champ.followerID,troopType,troopType)
					end
				end
			end
			if self.requiredChampionCount <2 and #troopTypes > 1 then
				self:Build(champ.followerID,troopTypes[1],troopTypes[2])
			end
		end
	end
	wipe(self.candidatesIndex)
	for k,_ in pairs(self.candidates) do
		tinsert(self.candidatesIndex,k)
	end	
	table.sort(self.candidatesIndex)
	releaseEvents()
	return self
end-- Public Interface
function addon:GetParty(...)
	return module:GetParty(...)
end
function addon:GetParties()
	return parties
end	
function addon:HoldEvents()
	return holdEvents()
end
function addon:ReleaseEvents()
	return releaseEvents()
end
