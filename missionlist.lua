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
local module=addon:NewSubClass("missionlist") --#Module
-- Additonal frames
local missionstats={}
local missionmembers={}
local missionids={}
function module:OnInitialized()
	for i=1,16 do
		local name="OrderHallMissionFrameMissionsListScrollFrameButton"..i
		if _G[name] then
			self:SecureHookScript(_G[name],"OnEnter","AdjustMissionTooltip")
			self:SecureHookScript(_G[name],"OnClick","PostMissionClick")
		end		
	end
	self:SecureHook("GarrisonMissionButton_SetRewards","AdjustMissionButton")
end
function module:AdjustMissionButton(frame,rewards)
	local nrewards=#rewards
	local mission=frame.info
	local missionID=mission and mission.missionID
	if not missionID then return end
	if not OHF:IsVisible() then return end
	local inProgress=OHFMissions.showInProgress
	if inProgress and missionids[frame] and missionids[frame]==missionID then return end
	missionids[frame]=missionID
	if not inProgress then
		-- Compacting mission time and level
		frame.RareText:Hide()
		frame.Level:ClearAllPoints()
		local aLevel,aIlevel=addon:GetAverageLevels()
		if mission.isMaxLevel then
			frame.Level:SetText(mission.iLevel)
			frame.Level:SetTextColor(addon:GetDifficultyColors(math.floor(aIlevel/mission.iLevel*100)))
		else
			frame.Level:SetText(mission.level)
			frame.Level:SetTextColor(addon:GetDifficultyColors(math.floor(aLevel/mission.level*100)))
		end
		frame.ItemLevel:Hide()
		frame.Level:SetPoint("LEFT",5,0)
	end
	if mission.isRare then 
		frame.Title:SetTextColor(frame.RareText:GetTextColor())
	else
		frame.Title:SetTextColor(C:White())
	end
	frame.RareText:Hide()
	-- Adding stats frame
	if not missionstats[frame] then
		missionstats[frame]=CreateFrame("Frame",nil,frame,"OHCStats")
	end
	local stats=missionstats[frame]
	stats:SetPoint("Center",frame.MissionType)
	local perc=select(4,G.GetPartyMissionInfo(missionID)) 
	local followers=(inProgress or mission.inProgress) and mission.followers or addon:GetParty(missionID):GetFollowers()
	if inProgress then
		stats.Expire:Hide()
		stats.Chance1:Hide()
		stats.Chance2:SetFormattedText(PERCENTAGE_STRING,perc)
		stats.Chance2:SetTextColor(addon:GetDifficultyColors(perc,true))		
		stats.Chance2:Show()
	else
		stats.Expire:SetFormattedText("%s\n%s",GARRISON_MISSION_AVAILABILITY,mission.offerTimeRemaining)
		stats.Expire:SetTextColor(addon:GetAgeColor(mission.offerEndTime))		
		stats.Chance1:SetFormattedText(PERCENTAGE_STRING,perc)
		stats.Chance1:SetTextColor(addon:GetDifficultyColors(perc))		
		stats.Expire:Show()
		stats.Chance1:Show()
		stats.Chance2:Hide()
	end
	if not missionmembers[frame] then
		missionmembers[frame]=CreateFrame("Frame",nil,frame,"OHCMembers")
	end
	local members=missionmembers[frame]
	members:SetPoint("RIGHT",frame.Rewards[nrewards],"LEFT",-5,0)
	if followers then
		for i=1,3 do
			if followers[i] then
				members.Champions[i]:SetFollower(followers[i])
			else
				members.Champions[i]:SetEmpty()
			end
		end
	end
	--members:Show()
	--stats:Show()
end
function module:AdjustMissionTooltip(this,...)
	local tip=GameTooltip
	tip:AddLine(me)
--@debug@
	OrderHallCommanderMixin.DumpData(tip,this.info)
--@end-debug@	
	tip:Show()
	
end
function module:PostMissionClick(this,...)
	dprint(this:GetName(),...)
end
