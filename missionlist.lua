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
local pp=print
if LibDebug then LibDebug() end
dprint=print
local print=pp
--@end-debug@
--[===[@non-debug@
dprint=function() end
ddump=function() end
local print=function() end
--@end-non-debug@]===]
--8<-------------------------------------------------------
-- Additonal frames
local missionstats={}
local missionmembers={}
function addon:AdjustMissionButton(frame,rewards)
	local nrewards=#rewards
	local mission=frame.info
	local missionID=mission and mission.missionID
	if not missionID then return end
	local name="Mission".. mission.name:gsub(' ','')
	local key=frame:GetName()
	_G[name]=frame.info
	dprint(frame:GetName(),name,frame:GetID())
	-- Compacting mission time and level
	frame.MissionType:ClearAllPoints()
	frame.MissionType:SetPoint("LEFT",frame,5,0)
	frame.RareText:Hide()
	frame.Level:ClearAllPoints()
	local aLevel,aIlevel=self:GetAverageLevels()
	if mission.isMaxLevel then
		frame.Level:SetText(mission.iLevel..'/'..tostring(aIlevel))
		frame.Level:SetTextColor(self:GetDifficultyColor(aIlevel/mission.iLevel*100))
	else
		frame.Level:SetText(mission.level..'/'..tostring(aLevel))
		frame.Level:SetTextColor(self:GetDifficultyColor(aLevel/mission.level*100))
	end
	frame.ItemLevel:Hide()
	frame.Level:SetPoint("CENTER",frame.MissionType)
	if mission.isRare then 
		frame.Title:SetTextColor(frame.RareText:GetTextColor())
	else
		frame.Level:SetTextColor(C:White())
	end
	frame.RareText:Hide()
	-- Adding stats frame
	if not missionstats[frame] then
		missionstats[frame]=CreateFrame("Frame",nil,frame,"OHCStats")
	end
	local stats=missionstats[frame]
	stats:SetPoint("LEFT",frame.Level,"RIGHT",0,0)
	stats.Expire:SetFormattedText("%s\n%s",GARRISON_MISSION_AVAILABILITY,mission.offerTimeRemaining)
	stats.Chance:SetFormattedText(PERCENTAGE_STRING,100)
	if not missionmembers[frame] then
		missionmembers[frame]=CreateFrame("Frame",nil,frame,"OHCMembers")
	end
	local members=missionmembers[frame]
	members:SetPoint("RIGHT",-100*nrewards,0)
	members:Show()
	self:SetBackdrop(members,C:Blue())
	
	--stats:Show()
end
function addon:AdjustMissionTooltip(this,...)
	local tip=GameTooltip
	tip:AddLine(me)
--@debug@
	local scanned=this.info
	if IsShiftKeyDown() then print("shift") scanned=this end
--@end-debug@	
	GameTooltip:Show()
	
end
function addon:PostMissionClick(this,...)
	dprint(this:GetName(),...)
end
