local __FILE__=tostring(debugstack(1,2,0):match("(.*):1:")) -- Always check line number in regexp and file, must be 1
--[===[@debug@
print('Loaded',__FILE__)
--@end-debug@]===]
local function pp(...) print(GetTime(),"|cff009900",__FILE__:sub(-15),strjoin(",",tostringall(...)),"|r") end
--*TYPE module
--*CONFIG profile=true,enhancedProfile=true
-- Auto Generated
local me,ns=...
if ns.die then return end
local addon=ns --#Addon (to keep eclipse happy)
ns=nil
local module=addon:NewSubModule('Data')  --#Module
function addon:GetDataModule() return module end
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
local followerType=Enum.GarrisonFollowerType.FollowerType_7_0
local garrisonType=Enum.GarrisonType.Type_7_0
local FAKE_FOLLOWERID="0x0000000000000000"
local MAX_LEVEL=50

local ShowTT=OrderHallCommanderMixin.ShowTT
local HideTT=OrderHallCommanderMixin.HideTT

local dprint=print
local ddump
--[===[@debug@
LoadAddOn("Blizzard_DebugTools")
ddump=DevTools_Dump
LoadAddOn("LibDebug")

if LibDebug then LibDebug() dprint=print end
local safeG=addon.safeG

--@end-debug@]===]
--@non-debug@
dprint=function() end
ddump=function() end
local print=function() end
--@end-non-debug@
local GARRISON_FOLLOWER_COMBAT_ALLY=GARRISON_FOLLOWER_COMBAT_ALLY
local GARRISON_FOLLOWER_ON_MISSION=GARRISON_FOLLOWER_ON_MISSION
local GARRISON_FOLLOWER_INACTIVE=GARRISON_FOLLOWER_INACTIVE
local GARRISON_FOLLOWER_IN_PARTY=GARRISON_FOLLOWER_IN_PARTY
local GARRISON_FOLLOWER_AVAILABLE=AVAILABLE
local ViragDevTool_AddData=_G.ViragDevTool_AddData
if not ViragDevTool_AddData then ViragDevTool_AddData=function() end end
local KEY_BUTTON1 = "\124TInterface\\TutorialFrame\\UI-Tutorial-Frame:12:12:0:0:512:512:10:65:228:283\124t" -- left mouse button
local KEY_BUTTON2 = "\124TInterface\\TutorialFrame\\UI-Tutorial-Frame:12:12:0:0:512:512:10:65:330:385\124t" -- right mouse button
local CTRL_KEY_TEXT,SHIFT_KEY_TEXT=CTRL_KEY_TEXT,SHIFT_KEY_TEXT
local CTRL_KEY_TEXT,SHIFT_KEY_TEXT=CTRL_KEY_TEXT,SHIFT_KEY_TEXT
local CTRL_SHIFT_KEY_TEXT=CTRL_KEY_TEXT .. '-' ..SHIFT_KEY_TEXT
local format,pcall=format,pcall
local function safeformat(mask,...)
  local rc,result=pcall(format,mask,...)
  if not rc then
    for k,v in pairs(L) do
      if v==mask then
        mask=k
        break
      end
    end
 end
  rc,result=pcall(format,mask,...)
  return rc and result or mask 
end

-- End Template - DO NOT MODIFY ANYTHING BEFORE THIS LINE
--*BEGIN
local fake={}
local data={
	ArtifactNotes={
		146745
	},
	U850={
		136412, -- Heavy Armor Set +5 (capped 850)
		137207, -- Fortified Armor Set +10 (capped 850)
		137208, -- Indestructible Armor Set +15 (capped 850)

	},
	U880={
		153005, -- Relinquished Armor Set 800
	},
	U900={
    147348, -- Bulky Armor Set +5 (capped 900(
    147349, -- Spiked Armor Set +10 (capped 900)
    147350, -- Invincible Armor Set +15 (capped 900)
    151842, -- Krokul Armor Set 900
	},
	U925={
	 151843, -- Mac'Aree Armor Set 925
	},
	U950={
		151844, -- Xenedar Armor Set 950
	},
	Buffs={
		140749, -- Horn of Winter Increases Chance
		143852, -- Lucky Rabbit's Foot Increases Chance
		139419, -- Golden Banana Increases Chance
		140760, -- Libram of Truth Increases Chance
		140156, -- Blessing of the Order Increases Chance
		139428, -- A Master Plan Increases Chance
		143605, -- Strange Ball of Energy Increases Chance
		139177, -- Shattered Soul +1 vitality 
		139420, -- Wild Mushroom +1 vitality
		138883, -- Meryl's Conjured Refreshment +1 vitality
		139376, -- Healing Well +1 vitality
		139418, -- Healing Stream Totem +1 vitality
		138412, -- Iresoul's Healthstone +1 vitality
		--140922, -- Imp Pact Summon
		--139670, -- Scream of the Dead Summon
    --143849, -- Summon Royal Guard Summon
    --143850, -- Summon Grimtotem Warrior Summon
		--142209, -- Dinner Invitation Summon
	},
	Xp={
		141028, -- Grimoire of Knowledge
	},
	Krokuls={
	 152095, -- Krokul Ridgestalke
   152096, -- Void-Purged Krokul
   152097, -- Lightforged Bulwark
	},
	ANY={
	 143605, -- Strange Ball of Energy
	 142209, --  Dinner Invitation
	},
	DEATHKNIGHT={
	 140767, -- Pile of Bits and Bones
	 140749, -- Horn of Winter
	},
	DEMONHUNTER={
	 143849, -- Summon Royal Guard
	 139177, -- Shattered Soul
	},
	DRUID={
	 139420, --  Wild Mushroom
	},
	HUNTER={
	},
	MAGE={
	 138883, --  Meryl's Conjured Refreshment
	 143852, -- Lucky Rabbit's Foo
	},
	MONK={
	 139419, -- Golden Banana
	},
	PALADIN={
	 140760, -- Libram of Truth 
	 140929, -- Squire's Oath
	},
	PRIEST={
	 139376, -- Healing Well
	 140156, -- Blessing of the order
	},
	ROGUE={
	 139428, -- A Master Plan 
	 140931, -- Bandit wanted poster
	},
	SHAMAN={
	 143850, -- Summon Grimtotem Warrior
	 139418, -- Healing Stream Totem
	 140932, -- Earthen Mark
	},
	WARLOCK={
	 138412, -- Iresoul's Healthstone
   140922, -- Imp Pact 
	},
	WARRIOR={
	 139670, --  Scream of the Dead
	},
	Class={},
	Equipments={}
}
local icon2item={}
local itemquality={}
function addon:GetData(key)
	key=key or "none"
	return data[key] or fake
end
local tickle
function module:OnInitialized()
  data.Equipments=addon.allEquipments
  local cs=data[select(2,UnitClass("player"))]
  if cs then
    data.Class=cs
  end
  for _,i in ipairs(data.ANY) do
    tinsert(data.Class,i)
  end
	--[===[@debug@
	DevTools_Dump(data.Class)
	addon:Print("Starting coroutine")
	--@end-debug@]===]
	addon.coroutineExecute(module,0.1,"TickleServer")
end
local GetItemIcon=GetItemIcon
local GetItemInfo=GetItemInfo
local pcall=pcall
function module:AddItem(itemID)

end
function addon:GetItemIdByIcon(iconid)
  if not icon2item[iconid] then icon2item[iconid] = select(2,pcall,GetItemIcon,iconid) end 
	return icon2item[iconid]
end
function addon:GetItemQuality(itemid)
  if not itemquality[itemid] then itemquality[itemid] = select(4,pcall,GetItemInfo,itemid) end
	return itemquality[itemid]
end

do
  local pairs=pairs
  local type=type
  local GetItemIcon=GetItemIcon
  local GetItemInfo=GetItemInfo
  local coroutine=coroutine
  local pcall=pcall
  local i=0
  local debugprofilestop=debugprofilestop
  local start=0
  local function tickle(category,useleft)
    for left,right in pairs(category) do
      local itemid=useleft and left or right
  		if type(itemid)=="number" and itemid > 10 then
  			if not itemquality[itemid] then
  				local rc,name,link,quality=pcall(GetItemInfo,itemid)
  				if rc and name then
  					itemquality[itemid]=quality
  					icon2item[GetItemIcon(itemid)]=itemid
  					i=i+1
  --[===[@debug@
  					if i % 100 == 0 then
  						addon:Print(format("Precached %d items in %.3f so far",i,(debugprofilestop()-start)))
  					end
  --@end-debug@]===]
  				end
  				if coroutine.running() then coroutine.yield() end
  			end
  		end
  	end
  end
  function module:TickleServer()
  	start=debugprofilestop()
  	tickle(data.Equipments)
    tickle(addon.allArtifactPower,true)
  	--[===[@debug@
  	addon:Print(format("Precached %d items in %.3f seconds",i,(debugprofilestop()-start)/1000))
  	--@end-debug@]===]
  end
end
