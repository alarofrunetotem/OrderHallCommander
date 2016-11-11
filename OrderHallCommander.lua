local __FILE__=tostring(debugstack(1,2,0):match("(.*):1:")) -- Always check line number in regexp and file
--*TYPE addon
--*CONFIG noswitch=false,profile=true,enhancedProfile=true
--*MIXINS "AceHook-3.0","AceEvent-3.0","AceTimer-3.0"
--*MINOR 35
-- Generated on 04/11/2016 15:14:56
local me,ns=...
local LibInit,minor=LibStub("LibInit",true)
assert(LibInit,me .. ": Missing LibInit, please reinstall")
assert(minor>=35,me ..': Need at least Libinit version 35')
local addon=LibInit:NewAddon(ns,me,{noswitch=false,profile=true,enhancedProfile=true},"AceHook-3.0","AceEvent-3.0","AceTimer-3.0") --#Addon
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
local OHFMissions=OrderHallMissionFrame.MissionTab.MissionList -- same as OrderHallMissionFrameMissions 
local OHFFollowerTab=OrderHallMissionFrame.FollowerTab -- Contains model view
local OHFFollowerList=OrderHallMissionFrame.FollowerList -- Contains follower list (visibe in both follower and mission mode)
local OHFFollowers=OrderHallMissionFrameFollowers -- Contains scroll list
local OHFMissionPage=OrderHallMissionFrame.MissionTab.MissionPage -- Contains mission description and party setup 
local OHFMapTab=OrderHallMissionFrame.MapTab -- Contains quest map
--[===[*if-non-addon*
local ShowTT=OrderHallCommanderMixin.ShowTT
local HideTT=OrderHallCommanderMixin.HideTT
--*end-if-non-addon*]===]
local dprint=print
local ddump
--@debug@
LoadAddOn("Blizzard_DebugTools")
ddump=DevTools_Dump
LoadAddOn("LibDebug")
--[===[*if-non-addon*
if LibDebug then LibDebug() dprint=print end
--*end-if-non-addon*]===]
--*if-addon*
-- Addon Build, we need to create globals the easy way
local function encapsulate()
if LibDebug then LibDebug() dprint=print end
end
encapsulate()
--*end-if-addon*
--@end-debug@
--[===[@non-debug@
dprint=function() end
ddump=function() end
local print=function() end
--@end-non-debug@]===]

-- End Template
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
function addon:ColorFromBias(followerBias)
		if ( followerBias == -1 ) then
			--return 1, 0.1, 0.1
			return C:Red()
		elseif ( followerBias < 0 ) then
			--return 1, 0.5, 0.25
			return C:Orange()
		else
			--return 1, 1, 1
			return C:Green()
		end
end
local colors=addon.colors
_G.OrderHallCommanderMixin={}
local Mixin=OrderHallCommanderMixin --#Mixin
function Mixin:ShowTT()
	if not self.tooltip then return end
	local tip=GameTooltip
	tip:SetOwner(self, "ANCHOR_TOPRIGHT")
	tip:SetText(self.tooltip)
	tip:Show()
end
function Mixin:HideTT()
	GameTooltip:Hide()
end
function Mixin:Dump()
	local	tip=GameTooltip
	tip:SetOwner(self,"ANCHOR_CURSOR")
	tip:AddLine(self:GetName(),C:Green())
	self.DumpData(tip,self)
	tip:Show()
end
function Mixin.DumpData(tip,data)
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
local threatPool
OrderHallCommanderMixinThreats={}
local MixinThreats=OrderHallCommanderMixinThreats --#MixinThreats
function MixinThreats:OnLoad()
	if not threatPool then threatPool=CreateFramePool("Frame",UIParent,"OHCThreatsCounters") end
	self.usedPool={}
	
end
function MixinThreats:ShowCounter()
	local	tip=GameTooltip
	tip:SetOwner(self,"ANCHOR_TOPRIGHT")
	tip:AddLine("Counter list",C:Green())
	for index,mechanic in pairs(self.mechanics) do
		tip:AddLine(mechanic.name,C:Red())
		Mixin.DumpData(tip,mechanic.ability)
		Mixin.DumpData(tip,mechanic)
	end
	tip:Show()
end
function MixinThreats:AddIcons(mechanics)
	for i=1,#self.usedPool do
		threatPool:Release(self.usedPool[i])
	end
	self.mechanics=mechanics
	wipe(self.usedPool)
	local previous
	local icons=OHF.abilityCountersForMechanicTypes
	if not icons then return end
	for index,mechanic in pairs(mechanics) do
		local th=threatPool:Acquire()
		tinsert(self.usedPool,th)
		th.Icon:SetTexture(icons[mechanic.id].icon)
		th.Name=mechanic.name
		th.Description=mechanic.description
		th:SetParent(self)
		th:SetFrameStrata(self:GetFrameStrata())
		th:SetFrameLevel(self:GetFrameLevel()+1)
		if not previous then
			th:SetPoint("BOTTOMLEFT",0,0)
			previous=th
		else
			th:SetPoint("BOTTOMLEFT",previous,"BOTTOMRIGHT",5,0)
			previous=th
		end
		th.Border:SetVertexColor(addon:ColorFromBias(mechanic.bias))
		th:Show()
	end
end

OrderHallCommanderMixinFollowerIcon={} 
local MixinFollowerIcon= OrderHallCommanderMixinFollowerIcon --#MixinFollowerIcon
function MixinFollowerIcon:SetFollower(followerID)
	local info=addon:GetChampionData(followerID)
	self:SetupPortrait(info)
	if info.isMaxLevel then
		self:SetILevel(info.iLevel)
	else
		self:SetLevel(info.level)
	end
end
function MixinFollowerIcon:SetEmpty()
	self:SetNoLevel()
	self:SetPortraitIcon()
	self:SetQuality(1)
end
OrderHallCommanderMixinMembers={}
local MixinMembers= OrderHallCommanderMixinMembers --#MixinMembers
function MixinMembers:OnLoad()
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
OrderHallMixinMenu={}
local MixinMenu=OrderHallMixinMenu --#MixinMenu
function MixinMenu:OnLoad()
	self.Top:SetAtlas("_StoneFrameTile-Top", true);
	self.Bottom:SetAtlas("_StoneFrameTile-Bottom", true);
	self.Left:SetAtlas("!StoneFrameTile-Left", true);
	self.Right:SetAtlas("!StoneFrameTile-Left", true);
	self.GarrCorners.TopLeftGarrCorner:SetAtlas("StoneFrameCorner-TopLeft", true);
	self.GarrCorners.TopRightGarrCorner:SetAtlas("StoneFrameCorner-TopLeft", true);
	self.GarrCorners.BottomLeftGarrCorner:SetAtlas("StoneFrameCorner-TopLeft", true);
	self.GarrCorners.BottomRightGarrCorner:SetAtlas("StoneFrameCorner-TopLeft", true);
	self.CloseButton:Hide()
	self.CloseButton:SetScript("OnClick",nil)
	self.Pin:SetAllPoints(self.CloseButton)
end	
function MixinMenu:OnClick()
	print("Cliccato pin")
end
