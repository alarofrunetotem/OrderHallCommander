local __FILE__=tostring(debugstack(1,2,0):match("(.*):1:")) -- Always check line number in regexp and file
local function pp(...) print(__FILE__:sub(-15),...) end
--*TYPE module
--*CONFIG noswitch=false,profile=true,enhancedProfile=true
--*MIXINS "AceHook-3.0","AceEvent-3.0","AceTimer-3.0"
--*MINOR 35
-- Generated on 20/11/2016 11:08:08
local me,ns=...
local addon=ns --#Addon (to keep eclipse happy)
ns=nil
local module=addon:NewSubModule('Cache',"AceHook-3.0","AceEvent-3.0","AceTimer-3.0")  --#Module
function addon:GetCacheModule() return module end
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
local OHFMissions=OrderHallMissionFrame.MissionTab.MissionList -- same as OrderHallMissionFrameMissions Call Update on this to refresh Mission Listing
local OHFFollowerTab=OrderHallMissionFrame.FollowerTab -- Contains model view
local OHFFollowerList=OrderHallMissionFrame.FollowerList -- Contains follower list (visible in both follower and mission mode)
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
local safeG=addon.safeG
--*end-if-non-addon*
--[===[*if-addon*
-- Addon Build, we need to create globals the easy way
local function encapsulate()
if LibDebug then LibDebug() dprint=print end
end
encapsulate()
local pcall=pcall
local function parse(default,rc,...)
	if rc then return default else return ... end
end
	
addon.safeG=setmetatable({},{
	__index=function(table,key)
		rawset(table,key,
			function(default,...)
				return parse(default,pcall(G[key],...))
			end
		) 
		return table[key]
	end
})

--*end-if-addon*[===]
--@end-debug@
--[===[@non-debug@
dprint=function() end
ddump=function() end
local print=function() end
--@end-non-debug@]===]

-- End Template
--*BEGIN 
local pairs,math=pairs,math
local followerType=4
local volatile={
xp=G.GetFollowerXP,
levelXP=G.GetFollowerLevelXP,
quality=G.GetFollowerQuality,
level=G.GetFollowerLevel,
isMaxLevel=function(followerID)	return G.GetFollowerLevelXP(followerID)==0 end,
prettyName=G.GetFollowerLink,
iLevel=G.GetFollowerItemLevelAverage
}--- Caches
-- 
local currency
local currencyName
local currencyTexture
local resources=0
local id2index={f={},m={}}
local avgLevel,avgIlevel=0,0
local cachedFollowers={}
local cachedMissions={}
local categoryInfo
local emptyTable={}
local methods={available='GetAvailableMissions',inProgress='GetInProgressMissions',completed='GetCompleteMissions'}
local catPool={}
local troopTypes={}
local wipe,tinsert=wipe,tinsert
local function getCachedMissions()
	if not next(cachedMissions) then
--@debug@
		OHCDebug:Bump("Missions")
--@end-debug@	
		for property,method in pairs(methods) do
			local missions=G[method](followerType)
			for _,mission in ipairs(missions) do
				mission[property]=true
				cachedMissions[mission.missionID]=mission
			end
		end
	end
	return cachedMissions
end	
local function getCachedFollowers()
	if not next(cachedFollowers) then
--@debug@
		OHCDebug:Bump("Followers")
--@end-debug@	
		local followers=G.GetFollowers(followerType)
		if type(followers)=="table" then
			for _,follower in ipairs(followers) do
				if follower.isCollected and follower.status ~= GARRISON_FOLLOWER_INACTIVE then
					cachedFollowers[follower.followerID]=follower
				end
			end
		end
	end
	return cachedFollowers 
end 
function module:GetAverageLevels(cached)
	if avgLevel==0 or not cached then
		local level,ilevel,tot=0,0,0
		local f=getCachedFollowers()
		for i,d in pairs(f) do
			if d.isCollected and not d.isTroop then
				tot=tot+1
				level=level+self:GetKey(d,'level',0)
				ilevel=ilevel+self:GetKey(d,'iLevel',0)
			end
		end
		avgLevel,avgIlevel=math.floor(level/tot),math.floor(ilevel/tot)
	end
	return avgLevel,avgIlevel
end
function module:GetFollowerData(...)
	local id,key,defaultvalue=...
	local f=getCachedFollowers()
	if not id then
		self:GetKey(f,'status')
		for key,_ in pairs(volatile) do
			self:GetKey(f,key)	
		end
		return f
	end
	local data=f[id] 
	if data then
		if key then
			return self:GetKey(data,key,defaultvalue)
		else
			return data
		end
	else
		if select('#',...) > 2 then
			return defaultvalue
		else
			return emptyTable
		end
	end
end
function module:GetMissionData(...)
	local id,key,defaultvalue=...
	local f=getCachedMissions()
	if not id then
		return f
	end
	local data=f[id] 
	if data then
		if key then
			return self:GetKey(data,key,defaultvalue)
		else
			return data
		end
	else
		if select('#',...) > 2 then
			return defaultvalue
		else
			return emptyTable
		end
	end
end


function module:GetKey(data,key,defaultvalue)
-- some keys need to be fresh only if champions is not maxed
	
	if volatile[key] and not data[key] then
		data[key]=volatile[key](data.followerID)
	end
	if key=='status' and data.status=="refresh" then
		data.status=G.GetFollowerStatus(data.followerID)
	end
	if data[key] then return data[key] end
	-- pseudokeys 
	if key=="qLevel" then 
		return data.isMaxLevel and data.quality+data.level or data.level
	end
	assert("Invalid pseudo key " .. tostring(key))
	return defaultvalue
end
function module:Clear()
	wipe(cachedFollowers)
end
function module:ParseFollowers()
	categoryInfo = C_Garrison.GetClassSpecCategoryInfo(LE_FOLLOWER_TYPE_GARRISON_7_0);
	local numCategories = #categoryInfo;
	local prevCategory, firstCategory;
	local xSpacing = 20;	-- space between categories
	wipe(troopTypes)
	for _, category in ipairs(categoryInfo) do
		local index=category.classSpec
		tinsert(troopTypes,index)
		if not catPool[index] then
			catPool[index]=CreateFrame("Frame","FollowerIcon",OHF,"OrderHallClassSpecCategoryTemplate")
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
end

function module:Refresh(event,...)
--@debug@
	OHCDebug.CacheRefresh:SetText(event:sub(10))
--@end-debug@
	if (event == "CURRENCY_DISPLAY_UPDATE") then
		resources = select(2,GetCurrencyInfo(currency))		
	end
	local followerID
	local follower
	for i=1,select('#',...) do
		local t=select(i,...)
		if type(t)=="string" and t:len()==18 and t:find("0x")==1 then
			followerID=t
			break
		end
	end 
	if followerID then
		follower=cachedFollowers[followerID]
		if not follower then return getCachedFollowers(true) end
	end
	
	if event=="GARRISON_FOLLOWER_REMOVED" then
		if follower then
			cachedFollowers[followerID]=nil
		end
	elseif event=="GARRISON_FOLLOWER_CATEGORIES_UPDATED" then
		self:ParseFollowers()
	elseif event=="GARRISON_FOLLOWER_ADDED" then
		local type=...
		if type==followerType then	wipe(cachedFollowers)end
	elseif event=="GARRISON_FOLLOWER_XP_CHANGED"  then
		local type,id,xp=...
		if type==followerType and xp > 0 then 
			for k,_ in pairs(volatile) do
				follower[k]=nil
			end
			addon:PushEvent("CURRENT_FOLLOWER_XP",4,followerID,0,follower.xp,follower.level,follower.quality)
		end
	elseif event=="GARRISON_FOLLOWER_UPGRADED"then
		for k,_ in pairs(volatile) do
			follower[k]=nil
		end
	elseif event=="GARRISON_FOLLOWER_DURABILITY_CHANGED" then
		follower.durability=select(3,...)
		if follower.durability==0 then
			cachedFollowers[followerID]=nil
		end
	elseif event=="GARRISON_FOLLOWER_LIST_UPDATE" then
		local currentFollowerType=...
		if followerType==currentFollowerType then
			wipe(cachedFollowers)
		end
	elseif event=="GARRISON_MISSION_STARTED" or event=="GARRISON_MISSION_FINISHED" or event=="GARRISON_MISSION_COMPLETE_RESPONSE" then
		for _,follower in pairs(getCachedFollowers()) do
			--@debug@
			if not follower.isTroop then
				print("Old status",follower.status,"New status",G.GetFollowerStatus(follower.followerID))
			end
			--@end-debug@
			follower.status='refresh'
		end
		getCachedMissions(true)
	end
end
function module:OnInitialized()
	self:RegisterEvent("GARRISON_FOLLOWER_REMOVED","Refresh")
	self:RegisterEvent("GARRISON_FOLLOWER_LIST_UPDATE","Refresh")
	self:RegisterEvent("GARRISON_FOLLOWER_ADDED","Refresh")
	self:RegisterEvent("GARRISON_FOLLOWER_LIST_UPDATE","Refresh")
	self:RegisterEvent("GARRISON_FOLLOWER_CATEGORIES_UPDATED","Refresh") 
	self:RegisterEvent("GARRISON_FOLLOWER_XP_CHANGED","Refresh")
	self:RegisterEvent("GARRISON_MISSION_STARTED","Refresh")
	self:RegisterEvent("GARRISON_MISSION_FINISHED","Refresh")
	self:RegisterEvent("GARRISON_MISSION_COMPLETE_RESPONSE","Refresh")	
	self:RegisterEvent("GARRISON_FOLLOWER_DURABILITY_CHANGED","Refresh")
	self:RegisterEvent("CURRENCY_DISPLAY_UPDATE","Refresh")
	currency, _ = C_Garrison.GetCurrencyTypes(LE_GARRISON_TYPE_7_0);
	currencyName, resources, currencyTexture = GetCurrencyInfo(currency);
	addon.resourceFormat=COSTS_LABEL .." %d " .. currencyName
end
---- Public Interface
-- 
function addon:GetResources()
	return resources,currencyName
end
function addon:GetMissionData(...)
	return module:GetMissionData(...)
end
function addon:GetFollowerData(...)
	return module:GetFollowerData(...)
end
function addon:GetAllChampions(table)
	for _,follower in pairs(getCachedFollowers()) do
		if not follower.isTroop then
			tinsert(table,follower)
		end
	end
end
function addon:GetAllTroops(table)
	for _,follower in pairs(getCachedFollowers()) do
		if follower.isTroop then
			tinsert(table,follower)
		end
	end
end
local function isInParty(followerID)
	return G.GetFollowerStatus(followerID)==GARRISON_FOLLOWER_IN_PARTY
end
local troops={}
function addon:GetTroop(troopType,qt,skipBusy)
	if type(qt)=="boolean" then skipBusy=qt qt=1 end
	qt=self:tonumber(qt,1)
	local found=0
	wipe(troops)
	for _,follower in pairs(getCachedFollowers()) do
		if follower.isTroop and follower.classSpec==troopType and (not skipBusy or not follower.status) then
			tinsert(troops,follower)
			found=found+1
			if found>=qt then
				break
			end
		end
	end
	return unpack(troops)
	
end
function addon:GetTroopTypes()
	return troopTypes
end

function addon:GetAverageLevels(...)
	return module:GetAverageLevels(...)
end