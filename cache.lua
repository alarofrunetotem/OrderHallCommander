local __FILE__=tostring(debugstack(1,2,0):match("(.*):1:")) -- Always check line number in regexp and file
local me,addon=... 
--8<--------------------------------------------------------
local G=C_Garrison
local _
local AceGUI=LibStub("AceGUI-3.0")
local C=addon:GetColorTable()
local L=addon:GetLocale()
local new=function() return addon:NewTable() end
local del=function(tb) return addon:DelTable(tb) end
local OHF=OrderHallMissionFrame
local OHFMissionTab=OrderHallMissionFrame.MissionTab --Container for mission list and single mission
local OHFMissions=OrderHallMissionFrame.MissionTab.MissionList -- same as OrderHallMissionFrameMissions 
local OHFFollowerTab=OrderHallMissionFrame.FollowerTab -- Contains model view
local OHFFollowers=OrderHallMissionFrameFollowers -- Contains scroll list
local OHFMissionPage=OrderHallMissionFrame.MissionTab.MissionPage -- Contains mission description and party setup 
local dprint
local ddump
--@debug@
LoadAddOn("Blizzard_DebugTools")
ddump=DevTools_Dump
LoadAddOn("LibDebug")
local function encapsulate() 
	if LibDebug then LibDebug() dprint=print end
end
--@end-debug@
--[===[@non-debug@
dprint=function() end
ddump=function() end
local print=function() end
--@end-non-debug@]===]
--8<-------------------------------------------------------
--- Caches
local module=addon:NewSubClass('cache') --# module 
local id2index={f={},m={}}
local avgLevel,avgIlevel=0,0
function module:GetAverageLevels(cached)
	if avgLevel==0 or not cached then
		local level,ilevel,tot=0,0,0
		local f=OrderHallMissionFrameFollowers.followers
		if not f then
			return 0,0
		end
		wipe(id2index.f)
		for i,d in pairs(f) do
			if d.isCollected then
				id2index.f[d.followerID]=i
				tot=tot+1
				level=level+d.level
				ilevel=ilevel+d.iLevel
			end
		end
		avgLevel,avgIlevel=math.floor(level/tot),math.floor(ilevel/tot)
	end
	return avgLevel,avgIlevel
end
function module:GetChampionData(id,key,defaultvalue)
	local i=id2index.f[id]
	local data 
	local f=OrderHallMissionFrameFollowers.followers
	if not f then
		data = G.GetFollowerInfo(id)
	else
		if i and f[i] and f[i].followerID==id then
			data=f[i]
		else
			for i,d in pairs(f) do
				if d.followerID==id then
					id2index.f[id]=i
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
function module:GetMissionData(id,key,defaultvalue)
	local m1=OHFMissions.availableMissions
 	local m2=OHFMissions.inProgressMissions
 	local m
	local i=id2index.m[id]
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
				id2index.m[id]=i
				data=d
				break
			end
		end
		if not data then
			for i,d in pairs(m2) do
				if d.missionID==id then
					id2index[id].m=1000+i
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
	if data[key] then return data[key] end
	-- pseudokeys 
	if key=="qlevel" then 
		return data.isMaxLevel and data.iLevel or data.level
	end
end
function module:GetParty(missionID)
	local mission=self:GetMission(missionID)
	return {}
end
---- Public Interface
-- 
function addon:GetParty(...)
	return module:GetParty(...)
end
function addon:GetMission(...)
	return module:GetMissionData(...)
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