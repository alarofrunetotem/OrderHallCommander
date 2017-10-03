local me,addon=...
if addon.die then return end
local C=addon:GetColorTable()
local module=addon:GetWidgetsModule()
local Type,Version,unique="OHCMissionDetails",2,0
local AceGUI = LibStub and LibStub("AceGUI-3.0", true)
if not AceGUI or (AceGUI:GetWidgetVersion(Type) or 0) >= Version then return end
local C=addon:GetColorTable()
local G=C_Garrison
local GARRISON_FOLLOWER_XP_ADDED_ZONE_SUPPORT=GARRISON_FOLLOWER_XP_ADDED_ZONE_SUPPORT:gsub('%%d',C('%%d','Yellow'))
local GARRISON_FOLLOWER_XP_ADDED_ZONE_SUPPORT_LEVEL_UP=GARRISON_FOLLOWER_XP_ADDED_ZONE_SUPPORT_LEVEL_UP:gsub('%%d',C('%%d','Green'))
local GARRISON_FOLLOWER_XP_LEFT=GARRISON_FOLLOWER_XP_LEFT:gsub('%%d',C('%%d','Orange'))
local COMBATLOG_XPGAIN_FIRSTPERSON_UNNAMED=COMBATLOG_XPGAIN_FIRSTPERSON_UNNAMED:gsub('%%d',C('%%d','Green'))
local GARRISON_FOLLOWER_XP_UPGRADE_STRING=GARRISON_FOLLOWER_XP_UPGRADE_STRING
local GARRISON_FOLLOWER_XP_STRING=GARRISON_FOLLOWER_XP_STRING
local GARRISON_FOLLOWER_DISBANDED=GARRISON_FOLLOWER_DISBANDED
local BONUS_LOOT_LABEL=C(" (".. BONUS_LOOT_LABEL .. ")","Green")
local GetItemInfo,GetItemIcon=GetItemInfo,GetItemIcon
local m={} --#Widget
function m:OnRelease()
  self.frame.info=nil
end
function m:Show()
  self.frame:Show()
end
function m:Hide()
  self.frame:Hide()
  self:ReleaseChildren()
  self:Release()
end
function m:LoadCandidates()
  addon:Print("LoadCandidates called")
  local missionID=self.frame.info.missionID
  local parties=addon:GetMissionParties(missionID)
  if not parties then addon:Print("Non trovo la missione",missionID) return end
  local obj=self.scroll
  for i=1,#parties.candidatesIndex do
    local key=parties.candidatesIndex[i]
    local party=parties.candidates[key]
    local b=AceGUI:Create("OHCMiniMissionButton")
    addon:Print(party.perc,party.reason,party[1],party[2],party[3])
    b:SetMission(self.frame.info,party.perc,party.reason,party)
    b:SetFullWidth(true)
    obj:AddChild(b)
    if coroutine.running() then coroutine.yield() end
  end
end
function m:LoadMission(missionID)
  self.frame.info=addon:GetMissionData(missionID)
  --self:LoadCandidates()
  addon.coroutineExecute(m,0.1,"LoadCandidates",false,m)

end
function m._Constructor()
  local widget=AceGUI:Create("Window")
  widget.type=Type
  widget:SetLayout("Fill")
  widget.missions={}
  local scroll = AceGUI:Create("ScrollFrame")
  scroll:SetLayout("List") -- probably?
  scroll:SetFullWidth(true)
  scroll:SetFullHeight(true)
  widget:AddChild(scroll)
  for k,v in pairs(m) do widget[k]=v end
  widget._Constructor=nil
  widget:Show()
  widget.scroll=scroll
  widget.type=Type
  return widget
end
AceGUI:RegisterWidgetType(Type,m._Constructor,Version)