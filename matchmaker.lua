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
local stacklevel=0
local frames
function addon:GetMatchMaker()
	return module
end
local function holdEvents()
	if stacklevel==0 then
		frames={GetFramesRegisteredForEvent('GARRISON_FOLLOWER_LIST_UPDATE')}
		for i=1,#frames do
			frames[i]:UnregisterEvent("GARRISON_FOLLOWER_LIST_UPDATE")
		end
	end
	stacklevel=stacklevel+1
end
local function releaseEvents()
	stacklevel=stacklevel-1
	assert(stacklevel>=0)
	if (stacklevel==0) then
		for i=1,#frames do
			frames[i]:RegisterEvent("GARRISON_FOLLOWER_LIST_UPDATE")
		end
		frames=nil
	end
end
function module:Clear(event,...)
	print("Clear",event,...)
	for k,v in pairs(parties) do
		del(parties[k])
	end
	wipe(parties)
end
function module:GetParty(missionID)
	if (parties[missionID]) then
		return parties[missionID]
	else
		parties[missionID]=setmetatable(new(),party)
	end
end
function module:OnInitialized()
	self:RegisterEvent("GARRISON_FOLLOWER_LIST_UPDATE","Clear")
	self:RegisterEvent("GARRISON_MISSION_STARTED","Clear")
	self:RegisterEvent("GARRISON_MISSION_FINISHED","Clear")
	self:RegisterEvent("GARRISON_MISSION_BONUS_ROLL_COMPLETE","Clear")
	self:RegisterEvent("GARRISON_MISSION_BONUS_ROLL_LOOT","Clear")
	self:RegisterEvent("GARRISON_MISSION_COMPLETE_RESPONSE","Clear")
end