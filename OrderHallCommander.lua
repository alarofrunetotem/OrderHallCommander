local __FILE__=tostring(debugstack(1,2,0):match("(.*):1:")) -- Always check line number in regexp and file
local me,ns=...
local pp=print
--@debug@
LoadAddOn("Blizzard_DebugTools")
LoadAddOn("LibDebug")
if LibDebug then LibDebug() end
local dprint=print
--@end-debug@
--[===[@non-debug@
local dprint=function() end
local DevTools_Dump=function() end
--@end-non-debug@]===]
local addon --#addon
local LibInit,minor=LibStub("LibInit",true)
assert(LibInit,me .. ": Missing LibInit, please reinstall")
addon=LibStub("LibInit"):NewAddon(ns,me,{noswitch=false,profile=true,enhancedProfile=true},"AceHook-3.0","AceEvent-3.0","AceTimer-3.0","AceBucket-3.0") --#ns
print(addon)
local OHF=OrderHallMissionFrame
local missionPanel=OHF.MissionTab
local followerPanel=OHF.FollowerTab
local missionPanelMissions=OrderHallMissionFrameMissions
--[[
OHC- OrderHallMissionFrame.FollowerTab.DurabilityFrame : OnShow :  table: 0000000033557BD0
OHC- OrderHallMissionFrame.FollowerTab.QualityFrame : OnShow :  table: 0000000033557C20
OHC- OrderHallMissionFrame.FollowerTab.PortraitFrame : OnShow :  table: 0000000033557D60
OHC- OrderHallMissionFrame.FollowerTab.ModelCluster : OnShow :  table: 0000000033557F40
OHC- OrderHallMissionFrame.FollowerTab.XPBar : OnShow :  table: 00000000335585D0
--]]
local ctr=0
local function resolve(frame)
	local name
	if type(frame)=="table" and frame.GetName then
		name=frame:GetName()
		if not name then
			local parent=frame:GetParent()
			if not parent then return "UIParent" end
			for k,v in pairs(parent) do
				if v==frame then
					name=resolve(parent) .. '.'..k
					return name
				end
			end
		else
			return name
		end
		_G['UNK_'..ctr]=frame
		return 'UNK_'..ctr
	end
	return "unk"
end
function addon:Trace(frame, method)
	method=method or "OnShow"
	if not self:IsHooked(frame,method) and frame:GetObjectType()~="GameTooltip" then
		self:HookScript(frame,method,function(...)
			local name=resolve(frame)
			tinsert(dbOHCperChar,resolve(frame:GetParent())..'/'..name)
			pp(("OHC [%s] %s:%s %s %d"):format(frame:GetObjectType(),name,method,frame:GetFrameStrata(),frame:GetFrameLevel()))
			end
		)
	end
end
function addon:OnInitialized()
	_G.dbOHCperChar=_G.dbOHCperChar or {}
	self:Trace(OHF)
	local frame=EnumerateFrames()
	while frame do
		self:Trace(frame)
		frame=EnumerateFrames(frame)
	end
end