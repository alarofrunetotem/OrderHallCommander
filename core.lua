local __FILE__=tostring(debugstack(1,2,0):match("(.*):1:")) -- Always check line number in regexp and file
local me,ns=... 
--8<--------------------------------------------------------
local addon=ns --#Addon
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
local resolve=addon.resolve
local colors=addon.colors
local menu
function addon:OnInitialized()
	OHF:SetHeight(720)
	local menu=CreateFrame("Frame",nil,OHF,"OHCMenu")
	menu:SetPoint("TOPLEFT",OHFMissions.CombatAllyUI,"BOTTOMLEFT",0,5)
	menu:SetPoint("TOPRIGHT",OHFMissions.CombatAllyUI,"BOTTOMRIGHT",0,5)
	menu:SetPoint("BOTTOM",10,10)
	menu:SetFrameLevel(OHF:GetFrameLevel()+10)
--@debug@
	local f=menu
	f:RegisterAllEvents()
	self:RawHookScript(f,"OnEvent","ShowGarrisonEvents")
--@end-debug@
	self:AddBoolean("MOVEPANEL",true,"test","long test")
	
	OHF:EnableMouse(true)
	OHF:SetMovable(true)
	OHF:RegisterForDrag("LeftButton")
	OHF:SetScript("OnDragStart",function(frame)if self:GetBoolean('MOVEPANEL') then frame:StartMoving() end end)
	OHF:SetScript("OnDragStop",function(frame) frame:StopMovingOrSizing() end)
	self:SecureHookScript(OHFFollowerTab,"OnShow","ShowFollowerMenu")
	self:SecureHookScript(OHFMissionTab,"OnShow","ShowMissionMenu")
end
function addon:ShowFollowerMenu()
	print("Follower Menu")
end
function addon:ShowMissionMenu()
	print("Mission Menu")
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
	if(perc >90) then
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
--@debug@
local events={}
function addon:Trace(frame, method)
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
function addon:ShowGarrisonEvents(this,event,...)
	if event:find("GARRISON") then
		dprint(event,...)
		tinsert(events,{event,...})
	end
end
function addon:DumpEvents()
	return events
end
_G.OHC=addon
--@end-debug@
