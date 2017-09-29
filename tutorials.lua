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
local module=addon:NewSubModule('Tutorials',"AceHook-3.0","AceEvent-3.0","AceTimer-3.0")  --#Module
function addon:GetTutorialsModule() return module end
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
local OHFButtons=OHFMissions.listScroll.buttons
local HelpPlate_TooltipHide=HelpPlate_TooltipHide
local HelpPlateTooltip=HelpPlateTooltip
local platestrata = HelpPlateTooltip:GetFrameStrata()

local currentTutorialIndex
local fcolor="Yellow"
local ncolor="Green"
--[[
  addon:AddBoolean("SAVETROOPS",false,L["Counter kill Troops"],L["Always counter kill troops (ignored if we can only use troops with just 1 durability left)"])
  addon:AddBoolean("NEVERKILLTROOPS",false,L["Never kill Troops"],L["Makes sure that no troops will be killed"])
  addon:AddBoolean("PREFERHIGH",false,L["Prefer high durability"],L["Uses troops with the highest durability instead of the ones with the lowest"])
  addon:AddBoolean("NOTROOPS",false,L["Don't use troops"],L["Only use champions even if troops are available"])
  addon:AddBoolean("BONUS",true,L["Keep extra bonus"],L["Always counter no bonus loot threat"])
  addon:AddBoolean("SPARE",false,L["Keep cost low"],L["Always counter increased resource cost"])
  addon:AddBoolean("MAKEITQUICK",true,L["Keep time short"],L["Always counter increased time"])
  addon:AddBoolean("MAKEITVERYQUICK",false,L["Keep time VERY short"],L["Only accept missions with time improved"])
  addon:AddBoolean("MAXIMIZEXP",false,L["Maximize xp gain"],L["Favours leveling follower for xp missions"])
  addon:AddRange("MAXCHAMP",3,1,3,L["Max champions"],L["Use at most this many champions"],1)
  addon:AddRange("BONUSCHANCE",100,100,200,L["Bonus Chance"],
  format(L["If %1$s is lower than this, then we try to achieve at least %2$s without going over 100%%. Ignored for elite missions."],
   L["Bonus Chance"],L["Base Chance"]),
  5)
  addon:AddRange("BASECHANCE",0,5,100,L["Base Chance"],L["When we cant achieve the requested global chance, we try to reach at least this one without overcapping"],5)
  addon:AddBoolean("USEALLY",false,L["Use combat ally"],L["Combat ally is proposed for missions so you can consider unassigning him"])
  addon:AddBoolean("IGNOREBUSY",true,L["Ignore busy followers"],L["When no free followers are available shows empty follower"])
  addon:AddBoolean("IGNOREINACTIVE",true,L["Ignore inactive followers"],L["If not checked, inactive followers are used as last chance"])

--]]
local tutorials={
  {
    text=L["Welcome to a new release of OrderHallCommander\nPlease follow this short tutorial to discover all new functionalities.\nYou will not regret it"],
    anchor="CENTER",
    parent=OHF,
    noglow=true
  },
  {
    text=function()
        local c,n=C(L["Counter Kill Troops"], fcolor),C(L["Never kill Troops"],fcolor),C(addon:GetNumber("MAXCHAMP"),ncolor)
        return format(L["With %1$s you ask to always counter the Hazard kill troop.\nThis means that OHC will try to counter it OR use a troop with just one durability left.\nThe target for this switch is to avoid wasting durability point, NOT to avoid troops' death."],
        c)
    end,
    parent=function() return module:GetMenuItem("SAVETROOPS") end,
    anchor="LEFT"
  },
  {
    text=function()
        local c,n,x=C(L["Counter Kill Troops"], fcolor),C(L["Never kill Troops"]),C(L["Prefer high durability"], fcolor)
        return format(L["With %2$s you ask to never let a troop die.\nThis not only implies %1$s and %3$s, but force OHC to never send to mission a troop which will die.\nThe target for this switch is to avoid troops' death"],
        c,n,x)
    end,
    parent=function() return module:GetMenuItem("NEVERKILLTROOPS") end,
    anchor="LEFT"
  },
  {
    text=function()
        local c=C(L["Prefer high durability"], fcolor)
        return format(L["Usually OrderHallCOmmander tries to use troops with the lowest durability in order to let you enque new troops request as soon as possible.\nChecking %1$s reverse it and OrderHallCOmmander will choose for each mission troops with the highest possible durability"],
        c)
    end,
    parent=function() return module:GetMenuItem("PREFERHIGH") end,
    anchor="LEFT"
  },
  {
    text=function()
        local c,g,n=C(L["Max champions"], fcolor),C(L["Maximize xp gain"],fcolor),C(addon:GetNumber("MAXCHAMP"),ncolor)
        return format(L["You can choose to limit how much champoins are sent together.\nRight now OHC is not using more than %3$s champions in the same mission-\n\nNote that %2$s overrides it."],
        c,g,n)
    end,
    parent=function() return module:GetMenuItem("MAXCHAMP") end,
    anchor="LEFT"
  },
  {
    text=function()
        local g,b,ng,nb=C(L["Bonus Chance"],fcolor), C(L["Base Chance"],fcolor),C(addon:GetNumber("BONUSCHANCE"),ncolor),C(addon:GetNumber("BASECHANCE"),ncolor)
        return format(L["%1$s and %2$s switches work together to customize how you want your mission filled\n\nThe value you set for %1$s (right now %3$s%%) is the minimum acceptable chance for attempting to achieve bonus while the value to set for %2$s (right now %4$s%%) is the chance you want achieve when you are forfaiting bonus (due to not enough powerful followers)"],
        g,b,ng,nb)
    end,
    parent=function() return module:GetMenuItem("BONUSCHANCE"), module:GetMenuItem("BASECHANCE") end,
    anchor="LEFT"
  },
  {
    text=function()
        local g,b=C(L["Bonus Chance"],fcolor), C(L["Base Chance"],fcolor)
        return format(L["For example, let's say a mission can reach 95%%, 130%% and 180%% success chance.\nIf %1$s is set to 170%%, the 180%% one will be choosen.\nIf %1$s is set to 200%% OHC will try to find the nearest to 100%% respecting %2$s setting\nIf for example %2$s is set to 100%%, then the 130%% one will be choosen, but if %2$s is set to 90%% then the 95%% one will be choosen"],
        g,b)
    end,
    parent=function() return module:GetMenuItem("BONUSCHANCE"), module:GetMenuItem("BASECHANCE") end,
    anchor="LEFT"
  },
  {
    text=function()
        local g,b=C(L["Bonus Chance"],fcolor), C(L["Base Chance"],fcolor)
        return format(L["If instead you just want to always see the best available mission just set %1$s to 100%% and %2$s to 0%%"],
        g,b)
    end,
    parent=function() return module:GetMenuItem("BONUSCHANCE") , module:GetMenuItem("BASECHANCE") end,
    anchor="LEFT"
  },
  {
    text="When you have locked some followers to missions, you can start the mission without going to the mission page.\nShift-Clicking this button will scan missions from top to bottom (so, sort order IS important) and start the first one with at least one locked follower",
    parent=function() return module:GetMenuItem("BUTTON1") end,    
    anchor="TOP",
    level=-1,
  },
  {
    text="You can quickly remove all locks and bans clicking here",
    parent=function() return module:GetMenuItem("BUTTON2") end,    
    anchor="TOP",
    level=-1,
  },
  {
    text="If you cant see missions filled, maybe you have a too restrictive set of switches checked on.\nClicking here reset OHC to a very permissive setup.\nTry this before filing a ticket, please :)",
    parent=function() return module:GetMenuItem("BUTTON3") end,    
    anchor="TOP",
    level=-1,
  },
  {
    text='Followers can be "locked" to a specific mission.\nWhen you lock a follower, we will not used any other mission\nLocking follower around is a way to optimize your setup, you can keep locking and unlocking followers to different missions to achieve the best overall combination',
    anchor=function() return addon:GetMembersFrame(OHFButtons[1]) and "TOP" or "CENTER" end,
    parent=function() local f=addon:GetMembersFrame(OHFButtons[1]) if f then return f.Champions[1] else return OHF end end,
    level=-1
  },
  {
    text='Slots (non the follower in it but just the slot) can be banned. When you ban a slot, that slot will not be filled for that mission.\nExploiting the fact that troops are always in the leftmost slot(s) you can achieve a nice degree of custom tailoring, reducing the overall number of followers used for a mission',
    anchor=function() return addon:GetMembersFrame(OHFButtons[1]) and "TOP" or "CENTER" end,
    parent=function() local f=addon:GetMembersFrame(OHFButtons[1]) if f then return f.Champions[1] else return OHF end end,
    level=-1
  },
}
local Clicker
local Enhancer
local function callOrUse(data)
  if type(data)=="function" then
    return data()
  else
    return data
  end    
end
local function plate(self,tutorial)
  local text
  if type(tutorial)=="table" then
    text = callOrUse(tutorial.text)
    local a1=callOrUse(tutorial.anchor)
    local o,o2=callOrUse(tutorial.parent)
    self:Hide()
    local arrow="ArrowRIGHT"
    local glow="ArrowGlowRIGHT"
    local x=20
    local y=0
    local a2="RIGHT"
    if a1=="RIGHT" then
      a2="LEFT"
      arrow="ArrowLEFT"
      glow="ArrowGlowLEFT"
      x=-20
      y=0
    elseif a1 =="BOTTOM" then
      a2="TOP"
      arrow="ArrowUP"
      glow="ArrowGlowUP"
      x= 0
      y=20
    elseif a1 =="TOP" then
      a2="BOTTOM"
      arrow="ArrowDOWN"
      glow="ArrowGlowDOWN"
      x= 0
      y= -20
    elseif a1 == "CENTER" then
      a2="CENTER"
      arrow=false
      glow=false
      x=0
      y=0
    end
    platestrata=HelpPlateTooltip:GetFrameStrata()
    HelpPlateTooltip.HookedByOHC=true
    if arrow then HelpPlateTooltip[arrow]:Show() end
    if glow then HelpPlateTooltip[glow]:Show() end
    HelpPlateTooltip:SetPoint(a1, o, a2, x, y)
    HelpPlateTooltip:SetParent(o)
    HelpPlateTooltip:SetFrameStrata("TOOLTIP")
    Clicker:SetParent(HelpPlateTooltip)
    Clicker:Show()
    if tutorial.noglow then
      Enhancer:Hide()
    else
      Enhancer:SetParent(o)
      Enhancer:ClearAllPoints()
      if o2 then
        addon:Print(o:GetTop(),o2:GetTop(),o:GetLeft(),o2:GetLeft())
        if o2:GetTop() >= o:GetTop() and o2:GetLeft() <= o:GetLeft() then
          Enhancer:SetPoint("TOPLEFT",o,"TOPLEFT")
          Enhancer:SetPoint("BOTTOMRIGHT",o2,"BOTTOMRIGHT")
        elseif o2:GetTop() <= o:GetTop() and o2:GetLeft() >= o:GetLeft() then
          Enhancer:SetPoint("TOPLEFT",o,"TOPLEFT")
          Enhancer:SetPoint("BOTTOMRIGHT",o2,"BOTTOMRIGHT")
        else
          Enhancer:SetAllPoints()
        end
      else  
        Enhancer:SetAllPoints()
      end
      Enhancer:SetFrameStrata(o:GetFrameStrata())
      if tutorial.level then
        Enhancer:SetFrameLevel(o:GetFrameLevel() + (tutorial.level))
      end
      Enhancer:Show()
    end
  else
    text=tutorial
  end
  HelpPlateTooltip.Text:SetText(C(me .. ' ' .. addon.version,'Green') .. "\n" .. text .. "\n\n" )
  HelpPlateTooltip:Show()  
  
  --HelpPlateTooltip:SetScript("OnMouseDown",function(this) this:SetScript("OnMouseDown",this.oldClick) HelpPlate_TooltipHide() end)
end
function module:Refresh()
  if HelpPlateTooltip.HookedByOHC then
    local tutorial=tutorials[currentTutorialIndex]
    if tutorial then
      local text = type(tutorial.text)=="function" and tutorial.text() or tutorial.text
      plate(self,text)
      return
    end
  end
end
function module:Hide(this)
  HelpPlateTooltip.HookedByOHC=nil
  HelpPlateTooltip:SetFrameStrata(platestrata)
  HelpPlate_TooltipHide()
  HelpPlateTooltip:SetParent(UIParent)
  Clicker:SetParent(nil)
  Clicker:Hide()
  Enhancer:SetParent(nil)
  Enhancer:Hide()
end
function module:Backward()
  currentTutorialIndex=math.max(currentTutorialIndex-1,1)
  self:Show()
end  
function module:Forward()
  currentTutorialIndex=currentTutorialIndex+1
  self:Show()
end  
function module:Home()
  currentTutorialIndex=1
  self:Show()
end  
function module:HasReadTutorial()
  return addon.db.global.tutorialStep[addon.version] and addon.db.global.tutorialStep[addon.version] >= #tutorials
end
function module:Show()
  HelpPlateTooltip.HookedByOHC=nil
  if not currentTutorialIndex then currentTutorialIndex=addon.db.global.tutorialStep[addon.version] or 1 end
  local tutorial=tutorials[currentTutorialIndex]
  if tutorial then
    addon.db.global.tutorialStep[addon.version]=currentTutorialIndex
    plate(self,tutorial)
    if currentTutorialIndex < #tutorials then Clicker.Forward:Show() else Clicker.Forward:Hide() end
    if currentTutorialIndex > 1 then 
      Clicker.Backward:Show() 
      Clicker.Home:Show() 
    else 
      Clicker.Backward:Hide() 
      Clicker.Home:Hide() 
    end
    return
  else
    addon.db.global.tutorialStep[addon.version]=nil
  end
end
function module:OnInitialized()
  if not Clicker then
    Clicker=CreateFrame("Frame",nil,HelpPlateTooltip,"OHCNavigator")
    Clicker:SetAllPoints()
    self:RawHookScript(Clicker.Forward,"OnClick","Forward")
    self:RawHookScript(Clicker.Backward,"OnClick","Backward")
    self:RawHookScript(Clicker.Close,"OnClick","Hide")
    self:RawHookScript(Clicker.Home,"OnClick","Home")
    Clicker.Home.tooltip=L["Restart the tutorial"]
    Clicker.Close.tooltip=L["Terminate the tutorial. You can resume it anytime clicking on the info icon in the side menu"]
  end
  if not Enhancer then
    Enhancer = CreateFrame("Frame",nil,nil,"GlowBoxTemplate")
  end
end
function module:GetMenuItem(flag)
  return addon:GetMissionlistModule():GetMenuItem(flag)
end

