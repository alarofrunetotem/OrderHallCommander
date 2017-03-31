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
local OHF=OrderHallMissionFrame
local OHFMissionTab=OrderHallMissionFrame.MissionTab --Container for mission list and single mission
local OHFMissions=OrderHallMissionFrame.MissionTab.MissionList -- same as OrderHallMissionFrameMissions Call Update on this to refresh Mission Listing
local OHFFollowerTab=OrderHallMissionFrame.FollowerTab -- Contains model view
local OHFFollowerList=OrderHallMissionFrame.FollowerList -- Contains follower list (visible in both follower and mission mode)
local OHFFollowers=OrderHallMissionFrameFollowers -- Contains scroll list
local OHFMissionPage=OrderHallMissionFrame.MissionTab.MissionPage -- Contains mission description and party setup 
local OHFMapTab=OrderHallMissionFrame.MapTab -- Contains quest map
local OHFCompleteDialog=OrderHallMissionFrameMissions.CompleteDialog
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

-- End Template - DO NOT MODIFY ANYTHING BEFORE THIS LINE
--*BEGIN 
--local missionPanelMissionList=OrderHallMissionFrameMissions
--[[
Su OrderHallMissionFrameMissions viene chiamato Update() per aggiornare le missioni
.listScroll = padre della scrolllist delle missioni
<code>
	local scrollFrame = self.listScroll;
	local offset = HybridScrollFrame_GetOffset(scrollFrame);
</code>
--]]
--[[
OHC- OrderHallMissionFrame.FollowerTab.DurabilityFrame : OnShow :  table: 0000000033557BD0
OHC- OrderHallMissionFrame.FollowerTab.QualityFrame : OnShow :  table: 0000000033557C20
OHC- OrderHallMissionFrame.FollowerTab.PortraitFrame : OnShow :  table: 0000000033557D60
OHC- OrderHallMissionFrame.FollowerTab.ModelCluster : OnShow :  table: 0000000033557F40
OHC- OrderHallMissionFrame.FollowerTab.XPBar : OnShow :  table: 00000000335585D0
--]]
-- Upvalued functions
--local I=LibStub("LibItemUpgradeInfo-1.0",true)
local GetItemInfo=GetItemInfo
--if I then GetItemInfo=I:GetCachingGetItemInfo() end
local select,CreateFrame,pairs,type,tonumber,math=select,CreateFrame,pairs,type,tonumber,math
local QuestDifficultyColors,GameTooltip=QuestDifficultyColors,GameTooltip
local tinsert,tremove,tContains=tinsert,tremove,tContains
local format=format
local resolve=addon.resolve
local colors=addon.colors
local menu
local menuType="OHCMenu"
local menuOptions={mission={},follower={}}
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
-- my implementation of tonumber which accounts for nan and inf
function addon:tonumber(value,default)
	if value~=value then return default
	elseif value==math.huge then return default
	else return tonumber(value) or default
	end
end
-- my implementation of type which accounts for nan and inf
function addon:type(value)
	if value~=value then return nil
	elseif value==math.huge then return nil
	else return type(value)
	end
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
		age=tonumber(age) or 0
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
local emptyTable={}
local cachedClassSortInfo=CreateObjectPool(
	function(obj) return {class="none",classWeight=0,value=0} end,
	function(obj,tbl) tbl.class="none" tbl.classWeight=0 tbl.value=0 end
)
local classSort={
	[MONEY]=11,
	Artifact=12,
	Equipment=13,
	Quest=14,
	Upgrades=15,
	Reputation=16,
	PlayerXP=17,
	FollowerXP=18,
	Generic=19
}
local rewardCache={}
local function Reward2Class(self,mission)	
	local GetCurrencyInfo=GetCurrencyInfo
	local tostring=tostring
	if type(mission)=="number" then mission=addon:GetMissionData(mission) end
	if not mission then return "Generic",0,0 end
	local overReward=mission.overmaxRewards
	if not overReward then overReward=mission.OverRewards end
	local reward=mission.rewards
	if not reward then reward=mission.Rewards end
	if not overReward or not reward then
		return "Generic",0
	end
	overReward=overReward[1]
	reward=reward[1]
	if not reward then return "Generic",0 end
	if not overReward then overReward = emptyTable end
	if reward.currencyID then
		local name=GetCurrencyInfo(reward.currencyID)
		if name=="" then name = MONEY end
		return name,reward.quantity/10000
	elseif reward.followerXP then
			return "FollowerXp",reward.followerXP
	elseif type(reward.itemID) == "number" then
		local stringID=tostring(reward.itemID)
		local artifact=self.allArtifactPower[stringID]
		if artifact then
			return "Artifact",artifact.Power or 0
		elseif overReward.itemID==1447868 then
			return "PlayerXP",0
		elseif overReward.itemID==141344 then
			return "Reputation",0
		elseif tContains(self:GetData('Equipment'),reward.itemID) then
			return "Equipment",0
		elseif tContains(self:GetData("Upgrades"),reward.itemID) then
			return "Upgrades",0
		else
			local class,subclass=select(12,GetItemInfo(reward.itemID))
			class=class or -1
			if class==12 then
				return "Quest",0
			elseif class==7 then
				return "Reagent",reward.quantity or 1
			end
		end
	end
	return "Generic",reward.quantity or 1
end
function addon:Reward2Class(mission)
	local missionID=type(mission)=="table" and mission.missionID or mission
	if not missionID then return "generic",0 end
	local cached=rewardCache[missionID]
	if cached then return cached.class,cached.value,classSort[cached.class] or 0 end
	local class,value=Reward2Class(self,mission)
	rewardCache[missionID]={class=class,value=value}
	return class,value,classSort[class] or 0
end	
--@do-not-package@

local gamu=GetAddOnMemoryUsage
local uamu=UpdateAddOnMemoryUsage
local redpattern="c|FFFF0000%dM|r"
local greenpattern="%dM"
local function wrap(obj,func)
	addon:Print("Hook func",func)
	local old=obj[func]
	obj[func] = function(...)
		local r1,r2,r3,r4,r5,r6,r7,r8,r9=old(...)
		local m2=gamu(me)
		addon:Print("Called",func,format(greenpattern,m2/1024))
		return r1,r2,r3,r4,r5,r6,r7,r8,r9
	end
end
local profile={}
local min=5
function addon:LoadProfileData(obj,objname)
	for name,func in pairs(obj) do
		if type(func)=="function" then
			local total,times=GetFunctionCPUUsage(func,true)
			if times >= min then
				local average=total/(times>0 and times or 1)
				profile[format("%06d.%s:%s",999999-average*1000,objname,name)]={total=total,times=times,average=average}
			end
		end
	end
end
function addon:ProfileStats(newmin)
	if newmin then min = newmin end
	wipe(profile)
	local profiling=GetCVarBool("scriptProfile")
	if not profiling then
		SetCVar("scriptProfile",true)
		ReloadUI()
	end
	for name,module in self:IterateModules() do
		self:LoadProfileData(module,name)
		if module.ProfileStats then
			module:ProfileStats()
		end
	end
	self:LoadProfileData(self,"MAIN")
	if ViragDevTool_AddData then
		ViragDevTool_AddData(profile,"OHC_PROFILE")
	end
end
function addon:Resolve(frame) 
	local name
	if type(frame)=="table" and frame.GetName then
		name=frame:GetName()
		if not name then
			local parent=frame:GetParent()
			if not parent then return "UIParent" end
			for k,v in pairs(parent) do
				if v==frame then
					name=self:Resolve(parent) .. '.'..k
					return name
				end
			end
			return tostring(frame)
		else
			return name
		end
	end
	return "unk"
end
local newsframes={}
function addon:MarkAsNew(obj,key,message,method)
	local db=self.db.global
	if not db.news then db.news={} end
	--@debug@
	db.news[key]=false
	--@end-debug@
	if (not db.news[key]) then
		local f=CreateFrame("Button",nil,obj,"OrderHallCommanderWhatsNew")
		f.tooltip=message
		f.texture:ClearAllPoints()
		f.texture:SetAllPoints()
		f:SetPoint("TOPLEFT",obj,"TOPRIGHT")
		f:SetFrameStrata("HIGH")
		f:Show()
		if method then
			f:SetScript("OnClick",function(frame) self[method](self,frame) self:MarkAsSeen(key) end)
		else
			f:SetScript("OnClick",function(frame) self:MarkAsSeen(key) end)
		end
		newsframes[key]=f
	end
end
function addon:MarkAsSeen(key)
	local db=self.db.global
	if not db.news then db.news={} end
	db.news[key]=true
	if newsframes[key] then newsframes[key]:Hide() end
end

_G.OHC=addon
--@end-do-not-package@
