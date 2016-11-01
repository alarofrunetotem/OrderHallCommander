local __FILE__=tostring(debugstack(1,2,0):match("(.*):1:")) -- Always check line number in regexp and file
--*TYPE addon
--*CONFIG noswitch=false,profile=true,enhancedProfile=true
--*MIXINS "AceHook-3.0","AceEvent-3.0","AceTimer-3.0"
--*MINOR 35
local me,ns=...
ns=addon --#Addon (keeps eclipse happy)
local LibInit,minor=LibStub("LibInit",true)
assert(LibInit,me .. ": Missing LibInit, please reinstall")
assert(minor>=35,me ..': Need at least Libinit version 35')
addon=LibInit:NewAddon(addon,me,{noswitch=false,profile=true,enhancedProfile=true},"AceHook-3.0","AceEvent-3.0","AceTimer-3.0")--[[OrderHallCommander--]]
local __FILE__=tostring(debugstack(1,2,0):match("(.*):1:")) -- Always check line number in regexp and file
local me=...
local addon=select(2,...) --#addon
local G=C_Garrison
local _
local AceGUI=LibStub("AceGUI-3.0")
local C=addon:GetColorTable()
local L=addon:GetLocale()
local new=addon.NewTable
local del=addon.Deltable
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
--*BEGIN
local ctr=0
function addon.resolve(frame) 
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
function addon.colors(c1,c2)
	return C[c1].r,C[c1].g,C[c1].b,C[c2].r,C[c2].g,C[c2].b
end
local colors=addon.colors
_G.OrderHallCommanderMixin={}
local O1=OrderHallCommanderMixin --#Mixin_panel
function O1:ShowTT()
	local tip=GameTooltip
	tip:SetOwner(self, "ANCHOR_TOPRIGHT")
	tip:SetText(self.tooltip)
	tip:Show()
end
function O1:HideTT()
	GameTooltip:Hide()
end
function O1:Dump()
	local	tip=GameTooltip
	tip:SetOwner(self,"ANCHOR_CURSOR")
	tip:AddLine(self:GetName(),C:Green())
	self.DumpData(tip,self)
	tip:Show()
end
function O1.DumpData(tip,data)
	for k,v in kpairs(data) do
		local color="Silver"
		if type(v)=="number" then color="Cyan" 
		elseif type(v)=="string" then color="Yellow" v=v:sub(1,30)
		elseif type(v)=="boolean" then v=v and 'True' or 'False' color="White" 
		elseif type(v)=="table" then color="Green" if v.GetObjectType then v=v:GetObjectType() else v=tostring(v) end
		else v=type(v) color="Blue"
		end
		if k=="description" then v =v:sub(1,10) end
		tip:AddDoubleLine(k,v,colors("Orange",color))
	end
end
_G.OrderHallCommanderMixinFollowerIcon={} 
local O2= _G.OrderHallCommanderMixinFollowerIcon --#Mixin_FollowerIcon
function O2:SetFollower(followerID)
	local info=addon:GetChampionData(followerID)
	self:SetupPortrait(info)
end
function O2:SetEmpty()
	self:SetNoLevel()
	self:SetPortraitIcon()
	self:SetQuality(1)
end
_G.OrderHallCommanderMixinMembers={}
local O3= _G.OrderHallCommanderMixinMembers --#Mixin_Members
function O3:OnLoad()
	dprint("Loading members")
	for i=1,3 do
		if self.Champions[i] then
			self.Champions[1]:SetPoint("RIGHT")
		else
			self.Champions[i]=CreateFrame("Frame",nil,self,"OHCFollowerIcon")
			self.Champions[i]:SetPoint("RIGHT",self.Champions[i-1],"LEFT",-5,0)
		end
		self.Champions[i]:SetFrameLevel(self:GetFrameLevel()+10)
		self.Champions[i]:Show()
		self.Champions[i]:SetEmpty()
	end
end