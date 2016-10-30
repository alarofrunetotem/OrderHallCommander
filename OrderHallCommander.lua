local __FILE__=tostring(debugstack(1,2,0):match("(.*):1:")) -- Always check line number in regexp and file
local me,ns=... 
local addon=ns --#addon
local LibInit,minor=LibStub("LibInit",true)
assert(LibInit,me .. ": Missing LibInit, please reinstall")
addon=LibStub("LibInit"):NewAddon(addon,me,{noswitch=false,profile=true,enhancedProfile=true},"AceHook-3.0","AceEvent-3.0","AceTimer-3.0") --#ns
--8<--------------------------------------------------------
local G=C_Garrison
local _
local _G=_G
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
	if LibDebug then LibDebug() end
	dprint=print
end
encapsulate()
--@end-debug@
--[===[@non-debug@
dprint=function() end
ddump=function() end
local print=function() end
--@end-non-debug@]===]
--8<-------------------------------------------------------
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
do 
local O=OrderHallCommanderMixin --#Mixin_panel
function O:ShowTT()
	local tip=GameTooltip
	tip:SetOwner(self, "ANCHOR_TOPRIGHT")
	tip:SetText(self.tooltip)
	tip:Show()
end
function O:HideTT()
	GameTooltip:Hide()
end
function O:MembersOnLoad()
	for i=1,2 do
		if self.Champions[i] then
			self.Champions[1]:SetPoint("RIGHT")
		else
			self.Champions[i]=CreateFrame("Frame",nil,self,"OHCFollowerIcon")
			self.Champions[i]:SetPoint("RIGHT",self.Champions[i-1],"LEFT",-5,0)
		end
		self.Champions[i]:Show()
	end
end
function O:Dump(tip)
	if not tip then
		tip=GameTooltip
		GameTooltip_SetDefaultAnchor(tip,UIParent)
	end
	tip:AddLine(self:GetName(),C:Green())
	for k,v in kpairs(self) do
		local color="Silver"
		if type(v)=="number" then color="Blue" 
		elseif type(v)=="string" then color="Yellow" 
		elseif type(v)=="boolean" then v=v and'True' or 'False' color="Purple" 
		elseif type(v)=="table" then color="Green" if v.GetObjectType then v=v:GetObjectType() else v=tostring(v) end
		end
		if k=="description" then v =v:sub(1,10) end
		tip:AddDoubleLine(k,v,colors("Orange",color))
	end
	tip:Show()
end
end
_G.OrderHallCommanderMixinFollowerIcon={}
do
local O= _G.OrderHallCommanderMixinFollowerIcon
function O:SetFollower(followerID)
end
function O:SetEmpty(followerID)
end
end