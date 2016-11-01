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
--upvalues
local module=addon:NewSubClass('matchmaker') --# module
local assert,pairs,wipe,GetFramesRegisteredForEvent=assert,pairs,wipe,GetFramesRegisteredForEvent
local parties={}
local party={} --#Party Metatable for party managementy
local emptyTable={}
local holdEvents,releaseEvents
function party:GetFollowers()
	return emptyTable
end
function party:new(missionID)
	local t=setmetatable(new(),{__index=party})
	return t:Match(missionID)
	
end
function party:release()
	setmetatable(self,nil)
	del(self)
end
function party:Match(missionID)
	holdEvents()
	local champions=new()
	local troops=new()
	for i,follower in pairs(addon:GetChampionData()) do
		if follower.isCollected then
			if follower.isTroop then
				if not troops[follower.name] then
					troops[follower.name]=follower.followerID
				end					
			else
				tinsert(champions,follower)
			end
		end  
	end
	releaseEvents()	
	return self
end
function addon:GetMatchMaker()
	return module
end

function module:Clear(event,...)
	if next(parties) then
		for k,v in pairs(parties) do
			parties[k]:release()
		end
		wipe(parties)
	end
end
function module:GetParty(missionID)
	if not parties[missionID] then
		parties[missionID]=party:new(missionID)
	end
	return parties[missionID]
end
function module:OnInitialized()
	self:RegisterEvent("GARRISON_FOLLOWER_LIST_UPDATE","Clear")
	self:RegisterEvent("GARRISON_MISSION_STARTED","Clear")
	self:RegisterEvent("GARRISON_MISSION_FINISHED","Clear")
	self:RegisterEvent("GARRISON_MISSION_BONUS_ROLL_COMPLETE","Clear")
	self:RegisterEvent("GARRISON_MISSION_BONUS_ROLL_LOOT","Clear")
	self:RegisterEvent("GARRISON_MISSION_COMPLETE_RESPONSE","Clear")
	addon:AddLabel(L["Matchmaking"])
	addon:AddBoolean("OPT1",true,"test1","long test1")
	addon:AddBoolean("OPT2",true,"test2","long test2")
	addon:AddBoolean("OPT3",true,"test3","long test3")
	addon:AddBoolean("OPT4",true,"test4","long test4")
	addon:RegisterForMenu("mission","OPT1","OPT2","OPT3","OPT4")
	
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
-- Public Interface
function addon:GetParty(...)
	return module:GetParty(...)
end


