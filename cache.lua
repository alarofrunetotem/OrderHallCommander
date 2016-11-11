local __FILE__=tostring(debugstack(1,2,0):match("(.*):1:")) -- Always check line number in regexp and file
--*TYPE module
--*CONFIG noswitch=false,profile=true,enhancedProfile=true
--*MIXINS "AceHook-3.0","AceEvent-3.0","AceTimer-3.0"
--*MINOR 35
-- Generated on 04/11/2016 15:14:56
local me,ns=...
local addon=ns --#Addon (to keep eclipse happy)
ns=nil
local module=addon:NewSubModule('Cache',"AceHook-3.0","AceEvent-3.0","AceTimer-3.0")  --#Module
function addon:GetCache() return module end
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
local pairs,math=pairs,math
local followerType=4
--- Caches
-- 
local currency
local currencyName
local currencyTexture
local resources=0
local id2index={f={},m={}}
local avgLevel,avgIlevel=0,0
local cachedFollowers={}
local emptyTable={}
local function getCachedFollowers()
	if not cachedFollowers or #cachedFollowers==0 then
		local followers=G.GetFollowers(followerType)
		if type(followers)=="table" then
			for _,follower in ipairs(followers) do
				cachedFollowers[follower.followerID]=follower
				cachedFollowers[follower.name]=follower
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
				level=level+d.level
				ilevel=ilevel+d.iLevel
			end
		end
		avgLevel,avgIlevel=math.floor(level/tot),math.floor(ilevel/tot)
	end
	return avgLevel,avgIlevel
end
function module:GetChampionData(...)
	local id,key,defaultvalue=...
	local f=getCachedFollowers()
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
function module:GetMissionData(id,key,defaultvalue)
	local m1=OHFMissions.availableMissions
 	local m2=OHFMissions.inProgressMissions
 	local m
 	local index=id2index.m
	local i=index[id]
	if i and i >1000 then
		i=i-1000
		m=m2
	else
		m=m1
	end
	local data 
	if i and m[i] and m[i].missionID==id then
		data=m[i]
	else
		for i,d in pairs(m1) do
			if d.missionID==id then
				index[id]=i
				data=d
				break
			end
		end
		if not data then
			for i,d in pairs(m2) do
				if d.missionID==id then
					index[id]=1000+i
					data=d
					break
				end
			end
		end
	end
	if data then
		if key then
			return self:GetKey(data,key,defaultvalue)
		else
			return data
		end
	else
		return defaultvalue
	end
end
function module:GetKey(data,key,defaultvalue)
-- Some keys need to always "fresh"
	if key=="status" then
		return G.GetFollowerStatus(data.followerID)
	end
-- some keys need to be fresh only if champions is not maxed
	if not data.isMaxLevel then
		if key=="xp" then
			return G.GetFollowerXP(data.followerID)
		end
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
function module:Refresh(event,...)
	if (event == "CURRENCY_DISPLAY_UPDATE") then
		resources = select(2,GetCurrencyInfo(currency))		
	end
	local followerID
	for i=1,select('#',...) do
		local t=select(i,...)
		if type(t)=="string" and t:len()==18 and t:find("0x")==1 then
			followerID=t
			break
		end
	end 
	local follower=cachedFollowers[followerID]
	if not follower then return getCachedFollowers(true) end
	if event=="GARRISON_FOLLOWER_REMOVED" then
		if follower then
			local name=follower.name
			cachedFollowers[followerID]=nil
			cachedFollowers[name]=nil
		end
	elseif event=="GARRISON_FOLLOWER_ADDED" then
		wipe(cachedFollowers)
	elseif event=="GARRISON_FOLLOWER_XP_CHANGED" then
		follower.xp=G.GetFollowerXP(followerID)
		follower.levelXP=G.GetFollowerLevelXP(followerID)
		follower.quality=G.GetFollowerQuality(followerID)
		follower.level=G.GetFollowerLevel(followerID)
		follower.isMaxLevel=follower.levelXP==0
		follower.prettyName=G.GetFollowerLink(followerID)
		addon:PushEvent("CURRENT_FOLLOWER_XP",4,followerID,0,follower.xp,follower.level,follower.quality)
	elseif event=="GARRISON_FOLLOWER_UGRADED"then
		follower.iLevel=G.GetFollowerItemLevelAverage(followerID)
		follower.prettyName=G.GetFollowerLink(followerID)
		dprint(...)
		dprint(follower.xp,follower.quality,follower.level,follower.iLevel)
	elseif event=="GARRISON_FOLLOWER_DURABILITY_CHANGED" then
		follower.durability=select(3,...)
	end
end
function module:OnInitialized()
	self:RegisterEvent("GARRISON_FOLLOWER_REMOVED","Refresh")
	self:RegisterEvent("GARRISON_FOLLOWER_ADDED","Clear")
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
end
---- Public Interface
-- 
function addon:GetResources()
	return resources
end
function addon:GetMissionData(...)
	return module:GetMissionData(...)
end
function addon:GetChampionData(...)
	return module:GetChampionData(...)
end
function addon:GetAverageLevels(...)
	return module:GetAverageLevels(...)
end