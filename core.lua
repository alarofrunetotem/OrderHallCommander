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
local module=addon:NewSubModule('Core',"AceHook-3.0","AceEvent-3.0","AceTimer-3.0")  --#Module
function addon:GetCoreModule() return module end
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
local select,CreateFrame,pairs,type,tonumber,math=select,CreateFrame,pairs,type,tonumber,math
local QuestDifficultyColors,GameTooltip=QuestDifficultyColors,GameTooltip
local tinsert,tremove,tContains=tinsert,tremove,tContains
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
	menu=CreateFrame("Frame")
--@debug@
	local f=menu
	f:RegisterAllEvents()
	self:RawHookScript(f,"OnEvent","ShowGarrisonEvents")
--@end-debug@
	self:AddLabel(L["General"])
	self:AddBoolean("MOVEPANEL",true,"test","long test")
	OHF:RegisterForDrag("LeftButton")
	OHF:SetScript("OnDragStart",function(frame) if self:GetBoolean('MOVEPANEL') then frame:StartMoving() end end)
	OHF:SetScript("OnDragStop",function(frame) frame:StopMovingOrSizing() end)
	self:ApplyMOVEPANEL(self:GetBoolean('MOVEPANEL'))	
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
		if not tContains(menuOptions[menu],value) then
			tinsert(menuOptions[menu],value)
		end
	end
end
function addon:GetRegisteredForMenu(menu)
	return menuOptions[menu]
end
function addon:ShowFollowerMenu()
	print("Follower Tab")
	addon:CreateOptionsLayer(menu,"MOVEPANEL",unpack(menuOptions.follower))
	menu:Show()
end
function addon:ShowMissionMenu()
	print("Mission Tab")
	addon:CreateOptionsLayer(menu,"MOVEPANEL",unpack(menuOptions.mission))
	menu:Show()
end
do
local timer
function addon:RefreshMissions()
	if timer then self:CancelTimer(timer) end 
	print("Scheduling refresh in",0.02)
	timer=self:ScheduleTimer("EffectiveRefresh",0.02)
end
function addon:EffectiveRefresh()
	timer=nil
	addon:GetMatchmakerModule():ResetParties()
	OHFMissions:UpdateMissions()
end
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
function addon:SetBackdrop(frame,r,g,b)
	r=r or 1
	g=g or 0
	b=b or 0
   frame:SetBackdrop({
         bgFile = "Interface/Tooltips/UI-Tooltip-Background", 
         edgeFile = "Interface/Tooltips/UI-Tooltip-Border", 
         tile = true, tileSize = 16, edgeSize = 16, 
         insets = { left = 4, right = 4, top = 4, bottom =   4}
      }
   )	
   frame:SetBackdropColor(r,g,b,1)
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
		return not usePurple and C.Silver or C.Fuchsia
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
local widgetsForKey={}
function addon:CreateOptionsLayer(frame,...)
	if frame.widget then
		frame.widget.frame:SetParent(nil)
		AceGUI:Release(frame.widget)
	end
	local o=AceGUI:Create(menuType) -- a transparent frame
	o:SetLayout("Flow")
	o:SetCallback("OnClose",function(widget) print("Close called") widget:Release() end)
	local totsize=0
	wipe(widgetsForKey)
	for i=1,select('#',...) do
		totsize=totsize+self:AddOptionToOptionsLayer(o,select(i,...))
	end
	--o.frame:SetParent(frame)
	o:ClearAllPoints()
	o:SetPoint("TOPLEFT",frame,5,-5)
	o:SetPoint("BOTTOMRIGHT",frame,-5,5)
	o.frame:Show()
	frame.widget=o
	return o,totsize
end
function addon:AddOptionToOptionsLayer(o,flag,maxsize)
	maxsize=tonumber(maxsize) or 160
	if (not flag) then return 0 end
	local info=addon:GetVarInfo(flag)
	if (info) then
		local data={option=info}
		local widget
		if (info.type=="toggle") then
			widget=AceGUI:Create("CheckBox")
			local value=addon:GetBoolean(flag)
			widget:SetValue(value)
			local color=value and "Green" or "Silver"
			widget:SetLabel(C(info.name,color))
			widget:SetWidth(min(widget.text:GetStringWidth()+40,maxsize))
		elseif(info.type=="select") then
			widget=AceGUI:Create("Dropdown")
			widget:SetValue(addon:GetVar(flag))
			widget:SetLabel(info.name)
			widget:SetText(info.values[self:GetVar(flag)])
			widget:SetList(info.values)
			widget:SetWidth(maxsize)
		elseif (info.type=="execute") then
			widget=AceGUI:Create("Button")
			widget:SetText(info.name)
			widget:SetWidth(maxsize)
			widget:SetCallback("OnClick",function(widget,event,value)
				self[info.func](self,data,value)
			end)
		elseif (info.type=="range") then
			local value=addon:GetNumber(flag)
			widget=AceGUI:Create("Slider")
			widget:SetLabel(info.name)
			widget:SetValue(value)
			widget:SetSliderValues(info.min,info.max,info.step)
			widget:SetWidth(maxsize)
			widget:SetCallback("OnClick",function(widget,event,value)
				self[info.func](self,data,value)
			end)
		else
			widget=AceGUI:Create("Label")
			widget:SetText(info.name)
			widget:SetWidth(maxsize)
		end
		widget:SetCallback("OnValueChanged",function(widget,event,value)
			if (type(value=='boolean')) then
				local color=value and "Green" or "Silver"
				widget:SetLabel(C(info.name,color))
			end
			self[info.set](self,data,value)
		end)
		widget:SetCallback("OnEnter",function(widget)
			GameTooltip:SetOwner(widget.frame,"ANCHOR_CURSOR")
			GameTooltip:AddLine(info.desc)
			GameTooltip:Show()
		end)
		widget:SetCallback("OnLeave",function(widget)
			GameTooltip:FadeOut()
		end)
		o:AddChildren(widget)
		widgetsForKey[flag]=widget
	end
	return maxsize
end

--@debug@
local events={}
function addon:Trace(frame, method)
	if true then return end
	method=method or "OnShow"
	if type(frame)=="string" then frame=_G[frame] end
	if not frame then return end
	if not self:IsHooked(frame,method) and frame:GetObjectType()~="GameTooltip" then
		self:HookScript(frame,method,function(...)
			local name=resolve(frame)
			tinsert(dbOHCperChar,resolve(frame:GetParent())..'/'..name)
			print(("OHC [%s] %s:%s %s %d"):format(frame:GetObjectType(),name,method,frame:GetFrameStrata(),frame:GetFrameLevel()))
			end
		)
	end
end
local lastevent=""
function addon:ShowGarrisonEvents(this,event,...)
	if event:find("GARRISON") then
		if event=="GARRISON_MISSION_LIST_UPDATE" and event==lastevent then
			return
		end
		if event=="GARRISON_MISSION_COMPLETE_RESPONSE" then
			local _,_,_,followers=...
			if type(followers)=="table" then
				tinsert(dbOHCperChar,followers)			
				DevTools_Dump(followers)
			end
		end
		lastevent=event
		tinsert(events,{event,...})
		return self:PushEvent(event,...)
	end
end
function addon:PushEvent(event,...)
	tinsert(dbOHCperChar,event.. ' ' .. strjoin(tostringall(' ',...)))
end
function addon:DumpEvents()
	return events
end
_G.OHC=addon
--@end-debug@
