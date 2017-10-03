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
local module=addon:NewSubModule('Core',"AceHook-3.0","AceEvent-3.0","AceTimer-3.0")  --#Module
function addon:GetCoreModule() return module end
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

local todefault=addon:Wrap("todefault")

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
 
local fakeModule=setmetatable({},{__index=function() return function() end end})
-- Upvalued functions
local GetItemInfo=GetItemInfo
--if I then GetItemInfo=I:GetCachingGetItemInfo() end
local GetCurrencyInfo=GetCurrencyInfo
local tostring=tostring
local tostringall=tostringall
local strjoin=strjoin
local select,CreateFrame,pairs,type,todefault,math=select,CreateFrame,pairs,type,todefault,math
local QuestDifficultyColors,GameTooltip=QuestDifficultyColors,GameTooltip
local tinsert,tremove,tContains=tinsert,tremove,tContains
local format=format
local resolve=addon.resolve
local colors=addon.colors
local menu
local menuType="OHCMenu"
local menuOptions={mission={},follower={}}
local _G=_G
function addon:ApplyMOVEPANEL(value)
	OHF:EnableMouse(value)
	OHF:SetMovable(value)
end

function addon:OnInitialized()
	addon.KL=1
  _G.dbOHCperChar=_G.dbOHCperChar or {}
	menu=CreateFrame("Frame")
--@debug@
--[[
	local f=menu
	f:RegisterAllEvents()
	self:RawHookScript(f,"OnEvent","ShowGarrisonEvents")
]]--
--@end-debug@
	self:AddLabel(L["General"])
	self:AddBoolean("MOVEPANEL",true,L["Make Order Hall Mission Panel movable"],L["Position is not saved on logout"])
	self:AddBoolean("TROOPALERT",true,L["Troop ready alert"],L["Notifies you when you have troops ready to be collected"])
	self:loadHelp()
	OHF:RegisterForDrag("LeftButton")
	OHF:SetScript("OnDragStart",function(frame) if self:GetBoolean('MOVEPANEL') then frame:StartMoving() end end)
	OHF:SetScript("OnDragStop",function(frame) frame:StopMovingOrSizing() end)
	self:ApplyMOVEPANEL(self:GetBoolean('MOVEPANEL'))	
	self:RegisterEvent("ARTIFACT_UPDATE")
end
function addon:IsBlacklisted(missionID)
	return self.db.profile.blacklist[missionID]
end
function addon:ClearMenu()
	if menu.widget then 
		pcall(AceGUI.Release,AceGUI,menu.widget) 
		menu.widget=nil 
	end
	menu:Hide()
end
function addon:RegisterForMenu(menu,...)
	for i=1,select('#',...) do
		local value=(select(i,...))
		if type(value)=="table" then
			if type(value.arg)=="string" then
				value=value.arg
			elseif type(value['function'])=="string" then
				value=value['function']
			else
				value=false
			end
		end
		if value and not tContains(menuOptions[menu],value) then
			tinsert(menuOptions[menu],value)
		end
	end
end
function addon:GetRegisteredForMenu(menu)
	return menuOptions[menu]
end
do

end
function addon:ARTIFACT_UPDATE()
	local kl=C_ArtifactUI.GetArtifactKnowledgeMultiplier()
	if kl then
		addon.KL=kl
	end
end

function addon:ActivateButton(button,OnClick,Tooltiptext,persistent)
	button:SetScript("OnClick",function(...) self[OnClick](self,...) end )
	if (Tooltiptext) then
		button.tooltip=Tooltiptext
		button:SetScript("OnEnter",ShowTT)
			button:SetScript("OnLeave",HideTT)
	else
		button:SetScript("OnEnter",nil)
		button:SetScript("OnLeave",nil)
	end
end
--- Helpers
-- 
function addon:SetBackdrop(frame,r,g,b,a)
	r=r or 1
	g=g or 0
	b=b or 0
	a=a or 1
   frame:SetBackdrop({
         bgFile = "Interface/Tooltips/UI-Tooltip-Background", 
         xedgeFile = "Interface/Tooltips/UI-Tooltip-Border", 
         tile = true, tileSize = 16, edgeSize = 16, 
         insets = { left = 4, right = 4, top = 4, bottom =   4}
      }
   )	
   frame:SetBackdropColor(r,g,b,a)
end
function addon:GetDifficultyColors(...)
	local q=self:GetDifficultyColor(...)
	return q.r,q.g,q.b
end
function addon:GetDifficultyColor(perc,usePurple)
	if perc>=100 then
		return C.Green
	elseif(perc >90) then
		return QuestDifficultyColors['standard']
	elseif (perc >74) then
		return QuestDifficultyColors['difficult']
	elseif(perc>49) then
		return QuestDifficultyColors['verydifficult']
	elseif(perc >20) then
		return QuestDifficultyColors['impossible']
	else
		return not usePurple and C.Silver or C.Epic
	end
end
function addon:GetAgeColor(age)
		age=todefault(age,0)
		if age>GetTime() then age=age-GetTime() end
		if age < 0 then age=0 end
		local hours=floor(age/3600)
		local q=self:GetDifficultyColor(hours+20,true)
		return q.r,q.g,q.b
end
local function tContains(table, item)
	local index = 1;
	while table[index] do
		if ( item == table[index] ) then
			return index;
		end
		index = index + 1;
	end
	return nil;
end
local newsframes={}
function addon:MarkAsNew(obj,key,message,method)
	local db=self.db.global
	if not db.news then db.news={} end
--@debug@	
	db.news[key]=false
--@end-debug@	
	if (not db.news[key]) then
		local f=CreateFrame("Button",nil,obj,"OHCWhatsNew")
		f.tooltip=message
		f.texture:ClearAllPoints()
		f.texture:SetAllPoints()
    f:GetHighlightTexture():ClearAllPoints()		
    f:GetHighlightTexture():SetAllPoints()    
		f:SetPoint("TOPLEFT",obj,"TOPLEFT",0,32)
		f:SetFrameStrata("TOOLTIP")
		f:Show()
		if method then
			f:SetScript("OnClick",function(frame) self[method](self,frame) self:MarkAsSeen(key) end)
		else
			f:SetScript("OnClick",function(frame) self:MarkAsSeen(key) end)
		end
		newsframes[key]=f
		return true
	end
end
function addon:MarkAsSeen(key)
	local db=self.db.global
	if not db.news then db.news={} end
	db.news[key]=true
	if newsframes[key] then newsframes[key]:Hide() end
end	
function addon.GetFakeModule()
  return fakeModule
end
if not _G.OHC then
_G.OHC=addon
end
