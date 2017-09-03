local __FILE__=tostring(debugstack(1,2,0):match("(.*):1:")) -- Always check line number in regexp and file, must be 1
--@debug@
print('Loaded',__FILE__)
--@end-debug@
local function pp(...) print(GetTime(),"|cff009900",__FILE__:sub(-15),strjoin(",",tostringall(...)),"|r") end
--*TYPE module
--*CONFIG noswitch=false,profile=true,enhancedProfile=true
--*MIXINS "AceHook-3.0","AceEvent-3.0","AceTimer-3.0"
--*MINOR 35
-- Auto Generated
local me,ns=...
if ns.die then return end
local addon=ns --#Addon (to keep eclipse happy)
ns=nil
local module=addon:NewSubModule('Autopilot',"AceHook-3.0","AceEvent-3.0","AceTimer-3.0")  --#Module
function addon:GetAutopilotModule() return module end
-- Template
local G=C_Garrison
local _
local AceGUI=LibStub("AceGUI-3.0")
local C=addon:GetColorTable()
local L=addon:GetLocale()
local new=addon:Wrap("NewTable")
local del=addon:Wrap("DelTable")
local kpairs=addon:Wrap("Kpairs")
local empty=addon:Wrap("Empty")
local tonumber=tonumber
local type=type
local OHF=OrderHallMissionFrame
local OHFMissionTab=OrderHallMissionFrame.MissionTab --Container for mission list and single mission
local OHFMissions=OrderHallMissionFrame.MissionTab.MissionList -- same as OrderHallMissionFrameMissions Call Update on this to refresh Mission Listing
local OHFFollowerTab=OrderHallMissionFrame.FollowerTab -- Contains model view
local OHFFollowerList=OrderHallMissionFrame.FollowerList -- Contains follower list (visible in both follower and mission mode)
local OHFFollowers=OrderHallMissionFrameFollowers -- Contains scroll list
local OHFMissionPage=OrderHallMissionFrame.MissionTab.MissionPage -- Contains mission description and party setup 
local OHFMapTab=OrderHallMissionFrame.MapTab -- Contains quest map
local OHFCompleteDialog=OrderHallMissionFrameMissions.CompleteDialog
local OHFMissionScroll=OrderHallMissionFrameMissionsListScrollFrame
local OHFMissionScrollChild=OrderHallMissionFrameMissionsListScrollFrameScrollChild
local followerType=LE_FOLLOWER_TYPE_GARRISON_7_0
local garrisonType=LE_GARRISON_TYPE_7_0
local FAKE_FOLLOWERID="0x0000000000000000"
local MAX_LEVEL=110

local ShowTT=OrderHallCommanderMixin.ShowTT
local HideTT=OrderHallCommanderMixin.HideTT

local dprint=print
local ddump
--@debug@
LoadAddOn("Blizzard_DebugTools")
ddump=DevTools_Dump
LoadAddOn("LibDebug")

local todefault=addon:Wrap("todefault")
if LibDebug then LibDebug() dprint=print end
local safeG=addon.safeG

--@end-debug@
--[===[@non-debug@
dprint=function() end
ddump=function() end
local print=function() end
--@end-non-debug@]===]
local LE_FOLLOWER_TYPE_GARRISON_7_0=LE_FOLLOWER_TYPE_GARRISON_7_0
local LE_GARRISON_TYPE_7_0=LE_GARRISON_TYPE_7_0
local GARRISON_FOLLOWER_COMBAT_ALLY=GARRISON_FOLLOWER_COMBAT_ALLY
local GARRISON_FOLLOWER_ON_MISSION=GARRISON_FOLLOWER_ON_MISSION
local GARRISON_FOLLOWER_INACTIVE=GARRISON_FOLLOWER_INACTIVE
local ViragDevTool_AddData=_G.ViragDevTool_AddData
if not ViragDevTool_AddData then ViragDevTool_AddData=function() end end
local KEY_BUTTON1 = "\124TInterface\\TutorialFrame\\UI-Tutorial-Frame:12:12:0:0:512:512:10:65:228:283\124t" -- left mouse button
local KEY_BUTTON2 = "\124TInterface\\TutorialFrame\\UI-Tutorial-Frame:12:12:0:0:512:512:10:65:330:385\124t" -- right mouse button
local CTRL_KEY_TEXT,SHIFT_KEY_TEXT=CTRL_KEY_TEXT,SHIFT_KEY_TEXT


-- End Template - DO NOT MODIFY ANYTHING BEFORE THIS LINE
--*BEGIN 
local wipe,pcall,pairs,IsShiftKeyDown,IsControlKeyDown=wipe,pcall,pairs,IsShiftKeyDown,IsControlKeyDown
local PlaySound,SOUNDKIT=PlaySound,SOUNDKIT
local OHFButtons=OHFMissions.listScroll.buttons

local safeguard={}
function module:Cleanup()
	for followerID,missionID in pairs(safeguard) do
		pcall(G.RemoveFollowerFromMission,missionID,followerID)
	end
	wipe(safeguard)
end
function module:GARRISON_MISSION_STARTED(event,missionType,missionID)
	if missionType == LE_FOLLOWER_TYPE_GARRISON_7_0 then
		--@debug@
		print("Event fired",event,missionType,missionID)
		--@end-debug@
		self:UnregisterEvent("GARRISON_MISSION_STARTED")
		self:Cleanup()
	end
end
function module:RunMission(missionKEYS,missionmembers)
	local baseChance=addon:GetNumber('BASECHANCE')
	wipe(safeguard)
	for _,frame in pairs(OHFButtons) do
		local mission=frame.info
		local missionID=mission and mission.missionID
		if missionID then
			if not addon:IsBlacklisted(missionID) then
				local key=missionKEYS[mission.missionID]
				local party=addon:GetMissionParties(mission.missionID):GetSelectedParty(key)
				local members = missionmembers[frame] 
				if party.perc >= baseChance then
					local info=""
					local truerun=IsShiftKeyDown()
					for _,member in pairs(members.Champions) do
						local followerID=member:GetFollower()
						if followerID then
							safeguard[followerID]=missionID
							local rc,res = pcall(G.AddFollowerToMission,missionID,member:GetFollower())
							info=info .. G.GetFollowerName(followerID)
						end
					end
					local timestring,timeseconds,timeImproved,chance,buffs,missionEffects,xpBonus,materials,gold=G.GetPartyMissionInfo(self.missionID)
					if party.perc < chance then
						self:Print("Could not fulfill mission, aborting")
						self:Cleanup()
						break
					end
					if truerun then
						self:RegisterEvent("GARRISON_MISSION_STARTED")
						G.StartMission(missionID)
						OHF:UpdateMissions();
						OHF.FollowerList:UpdateFollowers();							
						PlaySound(SOUNDKIT.UI_GARRISON_COMMAND_TABLE_MISSION_START)
						--@debug@
						print("Start done")
						--@end-debug@
					else
						addon:Print("Autostarting ",mission.name," with ",info)
						addon:Print("Shift-Click to actually start mission")
						--@debug@
						DevTools_Dump({party.perc,G.GetPartyMissionInfo(missionID)})
						--@end-debug@
						self:ScheduleTimer("GARRISON_MISSION_STARTED",0.2)
					end
					break
				end
			end
		end
	end
end

