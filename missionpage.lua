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
local module=addon:NewSubModule('Missionpage',"AceHook-3.0","AceEvent-3.0","AceTimer-3.0")  --#Module
function addon:GetMissionpageModule() return module end
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
local GARRISON_MISSION_AVAILABILITY2=C(GARRISON_MISSION_AVAILABILITY,'Yellow') .. " %s"
local GARRISON_MISSION_ID="MissionID: %d"
function module:FillMissionPage(missionInfo)

	if type(missionInfo)=="number" then missionInfo=addon:GetMissionData(missionInfo) end
	if not missionInfo then return end
	local missionType=missionInfo.followerTypeID
	if not missionInfo.canStart then return end
	local main=OHF
	if not main then return end
	local missionpage=main:GetMissionPage()
	local stage=main.MissionTab.MissionPage.Stage
	local model=stage.MissionInfo.MissionTime
	if not stage.expires then
		stage.expires=stage:CreateFontString()
		stage.expires:SetFontObject(model:GetFontObject())
		stage.expires:SetDrawLayer(model:GetDrawLayer())
	end
	stage.expires:SetFormattedText(GARRISON_MISSION_AVAILABILITY2,missionInfo.offerTimeRemaining or "")
	stage.expires:SetTextColor(addon:GetAgeColor(missionInfo.offerEndTime))
	stage.expires:SetPoint("TOPLEFT",stage.MissionInfo,"BOTTOMLEFT")
--@debug@
	if not stage.missionid then
		stage.missionid=stage:CreateFontString()
		stage.missionid:SetFontObject(model:GetFontObject())
		stage.missionid:SetDrawLayer(model:GetDrawLayer())
		stage.missionid:SetPoint("TOPLEFT",stage.expires,"BOTTOMLEFT")
	end
	stage.missionid:SetFormattedText(GARRISON_MISSION_ID,missionInfo.missionID)
--@end-debug@
	if( IsControlKeyDown()) then self:Print("Ctrl key, ignoring mission prefill") return end
	if (addon:GetBoolean("NOFILL")) then return end
	self:FillParty(missionInfo.missionID)
end
function module:FillParty(missionID)
	--addon:HoldEvents()
	local main=OHF
	main:ClearParty()
	local party=addon:GetParties(missionID):GetSelectedParty()
	local missionPage=main:GetMissionPage()
	for i=1,#party do
		local followerID=party:Follower(i)
		if followerID then
			missionPage:AddFollower(followerID)
		end
	end
	--addon:ReleaseEvents()
end
