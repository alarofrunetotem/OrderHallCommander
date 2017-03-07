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
local module=addon:NewSubModule('Missionlist',"AceHook-3.0","AceEvent-3.0","AceTimer-3.0")  --#Module
function addon:GetMissionlistModule() return module end
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

-- End Template - DO NOT MODIFY ANYTHING BEFORE THIS LINE
--*BEGIN 
local Dialog = LibStub("LibDialog-1.0")

local wipe=wipe
local GetTime=GetTime
local ENCOUNTER_JOURNAL_SECTION_FLAG4=ENCOUNTER_JOURNAL_SECTION_FLAG4
local RESURRECT=RESURRECT
local LOOT=LOOT
local nobonusloot=G.GetFollowerAbilityDescription(471)
local increasedcost=G.GetFollowerAbilityDescription(472)
local increasedduration=G.GetFollowerAbilityDescription(428)
local killtroops=G.GetFollowerAbilityDescription(437)
local debugprofilestop=debugprofilestop

local GARRISON_MISSION_AVAILABILITY2=GARRISON_MISSION_AVAILABILITY .. " %s"
local GARRISON_MISSION_ID="MissionID: %d"
local missionstats=setmetatable({}, {__mode = "v"})
local missionmembers=setmetatable({}, {__mode = "v"})
local missionthreats=setmetatable({}, {__mode = "v"})
local missionIDS={}
local spinners=setmetatable({}, {__mode = "v"})
local parties=setmetatable({}, {__mode = "v"})
local buttonlist={}
local oGarrison_SortMissions=Garrison_SortMissions
local function nop() end
local Current_Sorter
local sorters={
		Garrison_SortMissions_Original=nop,
		Garrison_SortMissions_Chance=function(a,b) 
			local aparty=addon:GetMissionParties(a.missionID) 
			local bparty=addon:GetMissionParties(b.missionID)
			return aparty.bestChance>bparty.bestChance 
		end,
		Garrison_SortMissions_Level=function(a,b) return a.level==b.level and a.iLevel>b.iLevel or a.level >b.level end,
		Garrison_SortMissions_Age=function(a,b) return (a.offerEndTime or 0) < (b.offerEndTime or 0) end,
		Garrison_SortMissions_Xp=function(a,b) 
			local aparty=addon:GetMissionParties(a.missionID) 
			local bparty=addon:GetMissionParties(b.missionID)
			return aparty.totalXP>bparty.totalXP 
		end,
		Garrison_SortMissions_Duration=function(a,b) 
			local aparty=addon:GetMissionParties(a.missionID) 
			local bparty=addon:GetMissionParties(b.missionID)
			return aparty.bestTimeseconds<bparty.bestTimeseconds 
		end,
		Garrison_SortMissions_Class=function(a,b)
			local a=addon:GetMissionData(a.missionID) 
			local b=addon:GetMissionData(b.missionID)
			return (a.missionSort or 0)>(b.missionSort or 0)
		end,
}
--@debug@
local function Garrison_SortMissions_PostHook()
   print("Riordino le missioni")
   table.sort(OrderHallMissionFrame.MissionTab.MissionList.availableMissions,function(a,b) return a.name < b.name end)
end
--@end-debug@
local function InProgress(mission,frame)
	return (mission and mission.inProgress) or OHFMissions.showInProgress or (frame and frame.IsCustom)
end
function module:OnInitialized()
-- Dunno why but every attempt of changing sort starts a memory leak
	local sorters={
		Garrison_SortMissions_Original=L["Original method"],
		Garrison_SortMissions_Chance=L["Success Chance"],
		Garrison_SortMissions_Level=L["Level"],
		Garrison_SortMissions_Age=L["Expiration Time"],
		Garrison_SortMissions_Xp=L["Global approx. xp reward"],
		Garrison_SortMissions_Duration=L["Duration Time"],
		Garrison_SortMissions_Class=L["Reward type"],
	}
	addon:AddSelect("SORTMISSION","Garrison_SortMissions_Original",sorters,	L["Sort missions by:"],L["Changes the sort order of missions in Mission panel"])
	addon:RegisterForMenu("mission","SORTMISSION")
	self:LoadButtons()
	self:RegisterEvent("GARRISON_MISSION_STARTED",function() wipe(missionIDS) wipe(parties) end)	
	Current_Sorter=addon:GetString("SORTMISSION")
	self:SecureHookScript(OHF--[[MissionTab--]],"OnShow","InitialSetup")
	--@debug@
	pp("Current sorter",Current_Sorter)
	--@end-debug@
	--hooksecurefunc("Garrison_SortMissions",Garrison_SortMissions_PostHook)--function(missions) module:SortMissions(missions) end)
	--self:SecureHook("Garrison_SortMissions",function(missionlist) print("Sorting",#missionlist,"missions") end)
	--function(missions) module:SortMissions(missions) end)
	--self:SecureHookScript(OrderHallMissionFrameMissionsTab1,"OnClick","SortMissions")
	--self:SecureHookScript(OrderHallMissionFrameMissionsTab2,"OnClick","SortMissions")
		Dialog:Register("OHCUrlCopy", {
			text = L["URL Copy"],
			width = 500,
			editboxes = {
				{ width = 484,
				  on_escape_pressed = function(self, data) self:GetParent():Hide() end,
				},
			},
			on_show = function(self, data) 
				self.editboxes[1]:SetText(data.url)
				self.editboxes[1]:HighlightText()
				self.editboxes[1]:SetFocus()
			end,
			buttons = {
				{ text = CLOSE, },
			},
			show_while_dead = true,
			hide_on_escape = true,
		})	
end
function addon:Apply(flag,value)
	self:RefreshMissions()
end
function module:Print(...)
	print(...)
end
function module:LoadButtons(...)
	buttonlist=OHFMissions.listScroll.buttons
	for i=1,#buttonlist do
		local b=buttonlist[i]	
		self:SecureHookScript(b,"OnEnter","AdjustMissionTooltip")
		self:SecureHookScript(b,"OnClick","PostMissionClick")
		b:RegisterForClicks("AnyDown")
		local scale=0.8
		local f,h,s=b.Title:GetFont()
		b.Title:SetFont(f,h*scale,s)
		local f,h,s=b.Summary:GetFont()
		b.Summary:SetFont(f,h*scale,s)		
		self:SecureHookScript(b.Rewards[1],"OnMouseUp","printLink")
		self:SecureHookScript(b.Rewards[1],"OnEnter","rwWarning")
	end
end
local tb={url=""}
function module:rwWarning(this)
	if this.itemID  then
		local tip=GameTooltip
		if addon.allArtifactPower[tostring(this.itemID)] then
			tip:AddLine(L["Artifact shown value is the base value without considering knowledge multiplier"],C.Artifact())
		end
		tip:AddLine("Shift-Click for a wowhead link popup")
		tip:Show()
	end
end
function module:printLink(this)
	if this.itemID and IsShiftKeyDown() then
		if Dialog:ActiveDialog("OHCUrlCopy") then
			Dialog:Dismiss("OHCUrlCopy")
		end
		tb.url="http://www.wowhead.com/item=" ..this.itemID
		Dialog:Spawn("OHCUrlCopy", tb)		
	end
end
local UpdateShow=true
--- Paints scollframe buttons
-- uses in progress or available missions based on .showInProgress flag
-- DO NOT Sort missions
-- Only paints visible buttons
function module:OnUpdate()
	UpdateShow = OHFMissions:IsVisible() and not OHFCompleteDialog:IsVisible()	
	self.hooks[OHFMissions].Update(OHFMissions)
end

--- Full mission panel refresh.
-- Reloads cached mission inProgressMissions and availableMissions.
-- Updates combat ally data
-- Sorts missions
-- Updates top tabs (available/in progress)
-- calls Update
function module:OnUpdateMissions()
	--if true then return self.hooks[OHFMissions].UpdateMissions(OHFMissions) end

--@debug@
	local start=debugprofilestop()
	addon:Print(C("OnUpdateMissions","Green"),OHFMissions:IsVisible(),OHFCompleteDialog:IsVisible())
--@end-debug@	
	addon.lastChange=GetTime()
	self:SecureHook("Garrison_SortMissions","SortMissions")
	self.hooks[OHFMissions].UpdateMissions(OHFMissions)
	self:Unhook("Garrison_SortMissions","SortMissions")
--@debug@
	addon:Print(C("OnPostUpdateMissions","Blue"),debugprofilestop()-start)
--@end-debug@	
end

function module:OnSingleUpdate(frame)
	if UpdateShow then
		self:AdjustPosition(frame)
		if frame.info.missionID ~= missionIDS[frame] then
			
			self:AdjustMissionButton(frame)
			missionIDS[frame]=frame.info.missionID
		end
	end
	local class,value=addon:GetMissionData(frame.info.missionID,'class')
	if class and class=="Artifact" then
		local rw=frame.Rewards[1]
		rw.Quantity:SetText(value .. "*")
		rw.Quantity:Show()
	end
	
end
local function sortfunc1(a,b)
	return a.timeLeftSeconds < b.timeLeftSeconds
end
local pcall=pcall
local sort=table.sort
function module:SortMissions()
--@debug@
	addon:Print(C("SortMissions","Orange"))
--@end-debug@
	if OHFMissions.inProgress then
		pcall(sort,OHFMissions.inProgressMissions,sortfunc1)
	else
		pcall(sort,OHFMissions.availableMissions,sorters[Current_Sorter])
	end
end
function addon:ApplySORTMISSION(value)
	Current_Sorter=value
	OHFMissions:UpdateMissions()
end
function addon:RefreshMissions()
	wipe(missionIDS)
	OHFMissions:UpdateMissions()
end
local function ToggleSet(this,value)
	return addon:ToggleSet(this.flag,this.tipo,value)
end
local function ToggleGet(this)
	return addon:ToggleGet(this.flag,this.tipo)
	
end
local function PreToggleSet(this)
	return ToggleSet(this,this:GetChecked())
end
local pin
local close
local menu
local button
local function OpenMenu()
	addon.db.profile.showmenu=true
	button:Hide()
	menu:Show()		
end
local function CloseMenu()
	addon.db.profile.showmenu=false
	button:Show()
	menu:Hide()		
end
function module:Menu()
	local previous
--@alpha@	
	local frame=CreateFrame("Frame",nil,menu)
	frame.label=frame:CreateFontString(nil,"ARTWORK","GameFontNormalSmall")
	frame.label:SetAllPoints(frame)
	frame:SetPoint("TOPLEFT",menu,32,-30)
	frame:SetPoint("TOPRIGHT",menu,-32,-30)
	frame.label:SetJustifyV("TOP")
	frame.label:SetText("You are using an\r|cffff0000ALPHA VERSION|r.\n Code is NOT optimized and OHC could run REALLY slow.\n I appreciate if you test it and raise issues but if you dont like bugs please revert to a stable version :)")
	frame:SetHeight(100)
	previous=frame
--@end-alpha@	
	local factory=addon:GetFactory()
	for _,v in pairs(addon:GetRegisteredForMenu("mission")) do
		local flag,icon=strsplit(',',v)
		local f=factory:Option(addon,menu,flag)
		if type(f)=="table" and f.GetObjectType then
			if flag=="MAXCHAMP" then f:SetStep(1) end
			if previous then 
				f:SetPoint("TOPLEFT",previous,"BOTTOMLEFT",0,-10)
			else
				f:SetPoint("TOPLEFT",menu,"TOPLEFT",32,-30)
			end
			previous=f
		end
	end 
	self.Menu=function() addon:Print("Should not call this again") end
end

function module:InitialSetup(this)
	if type(addon.db.global.warn01_seen)~="number" then	addon.db.global.warn01_seen =0 end
	if type(addon.db.global.warn02_seen)~="number" then	addon.db.global.warn02_seen =0 end
	if GetAddOnEnableState(UnitName("player"),"GarrisonCommander") > 0 then
		if addon.db.global.warn02_seen  < 3 then
			addon.db.global.warn02_seen=addon.db.global.warn02_seen+1
			addon:Popup(L["OrderHallCommander overrides GarrisonCommander for Order Hall Management.\n You can revert to GarrisonCommander simply disabling OrderhallCommander.\nIf instead you like OrderHallCommander remember to add it to Curse client and keep it updated"],20)
		end
	end 
	menu=CreateFrame("Frame",nil,OHFMissionTab,"OHCMenu")
	menu.Title:SetText(me .. ' ' .. addon.version)
	menu.Title:SetTextColor(C:Yellow())
	close=menu.CloseButton
	button=CreateFrame("Button",nil,OHFMissionTab,"OHCPin")
	button.tooltip=L["Show/hide OrderHallCommander mission menu"]
	close:SetScript("OnClick",CloseMenu)
	button:SetScript("OnClick",OpenMenu)
	button:GetNormalTexture():SetRotation(math.rad(270))
	button:GetHighlightTexture():SetRotation(math.rad(270))
	self:Menu()
	if addon.db.profile.showmenu then OpenMenu() else CloseMenu() end
	self:Unhook(this,"OnShow")
	self:SecureHookScript(this,"OnShow","MainOnShow")	
	self:SecureHookScript(this,"OnHide","MainOnHide")
	OHF.FollowerStatusInfo=OHF:CreateFontString(nil,"OVERLAY","GameFontNormalSmall")
	OHF.FollowerStatusInfo:SetPoint("TOPRIGHT",-45,-5)
	OHF.FollowerStatusInfo:SetText("")
	for _,mission in pairs(addon:GetMissionData()) do
		addon:GetSelectedParty(mission.missionID)
	end
	self:MainOnShow()
	addon:UpdateStop()
end
function module:MainOnShow()
--@debug@
	addon:Print("OnShow")
--@end-debug@
	--self:RawHook(OHFMissions,"Update","OnUpdate",true)
	self:RawHook(OHFMissions,"UpdateMissions","OnUpdateMissions",true)
	self:SecureHook("GarrisonMissionButton_SetRewards","OnSingleUpdate")
	addon:RefreshFollowerStatus()
	addon:ParseFollowers()
	addon.lastChange=GetTime()
	addon:ApplySORTMISSION(addon:GetString("SORTMISSION"))
end
function module:MainOnHide()
	addon:Print("OnHide")
	self:Unhook(OHFMissions,"UpdateMissions")
	--self:Unhook(OHFMissions,"Update")
	self:Unhook("GarrisonMissionButton_SetRewards")	
end
function module:AdjustPosition(frame)
	local mission=frame.info
	frame.Title:ClearAllPoints()
	if  mission.isResult then
		frame.Title:SetPoint("TOPLEFT",165,15)
	elseif  mission.inProgress then
		frame.Title:SetPoint("TOPLEFT",165,-10)
	else
		frame.Title:SetPoint("TOPLEFT",165,-7)
	end
	if mission.isRare then 
		frame.Title:SetTextColor(frame.RareText:GetTextColor())
	else
		frame.Title:SetTextColor(C:White())
	end
	frame.RareText:Hide()
	-- Compacting mission time and level
	frame.RareText:Hide()
	frame.Level:ClearAllPoints()
	frame.MissionType:ClearAllPoints()
	frame.ItemLevel:Hide()
	frame.Level:SetPoint("LEFT",5,0)
	frame.MissionType:SetPoint("LEFT",5,0)		
	if mission.isMaxLevel then
		frame.Level:SetText(mission.iLevel)
	else
		frame.Level:SetText(mission.level)
	end
	local missionID=mission.missionID
end

function module:AdjustMissionButton(frame)
	if not OHF:IsVisible() then return end
	local mission=frame.info
	local missionID=mission and mission.missionID
	if not missionID then return end
	missionIDS[frame]=missionID
	-- Adding stats frame (expiration date and chance)
	if not missionstats[frame] then
		missionstats[frame]=CreateFrame("Frame",nil,frame,"OHCStats")
--@debug@
		self:RawHookScript(missionstats[frame],"OnEnter","MissionTip")
--@end-debug@		
	end
	local stats=missionstats[frame]
	local aLevel,aIlevel=addon:GetAverageLevels()
	if mission.isMaxLevel then
		frame.Level:SetText(mission.iLevel)
		frame.Level:SetTextColor(addon:GetDifficultyColors(math.floor((aIlevel-750)/(mission.iLevel-750)*100)))
	else
		frame.Level:SetText(mission.level)
		frame.Level:SetTextColor(addon:GetDifficultyColors(math.floor(aLevel/mission.level*100)))
	end
	if mission.inProgress then
		stats:SetPoint("LEFT",48,14)
		stats.Expire:Hide()
		addon:GetCacheModule():SetMissionStatus(missionID,'inProgress')
	else
		stats.Expire:SetFormattedText("%s\n%s",GARRISON_MISSION_AVAILABILITY,mission.offerTimeRemaining)
		stats.Expire:SetTextColor(addon:GetAgeColor(mission.offerEndTime))		
		stats:SetPoint("LEFT",48,0)
		stats.Expire:Show()
	end
	stats.Chance:Show()
	if not missionmembers[frame] then
		missionmembers[frame]=CreateFrame("Frame",nil,frame,"OHCMembers")
	end
	if not missionthreats[frame] then
		missionthreats[frame]=CreateFrame("Frame",nil,frame,"OHCThreats")
	end
	self:AddMembers(frame)
end
function module:AddMembers(frame)
	local start=GetTime()
	local mission=frame.info
	local nrewards=#mission.rewards
	local missionID=mission and mission.missionID
	local followers=mission.followers
	local members=missionmembers[frame]
	local stats=missionstats[frame]
	local threats=missionthreats[frame]
	members:SetNotReady()
	members:SetPoint("RIGHT",frame.Rewards[nrewards],"LEFT",-5,0)
	if InProgress(frame.info,frame) then
		for i,followerID in ipairs(frame.info.followers) do
			members.Champions[i]:SetFollower(followerID,false)
		end
		frame.Overlay:SetFrameLevel(20)
		threats:Hide()
		local perc=select(4,G.GetPartyMissionInfo(missionID))
		stats.Chance:SetFormattedText(PERCENTAGE_STRING,perc)
		stats.Chance:SetTextColor(addon:GetDifficultyColors(perc,true))
		return
	end
		
	local party,key=addon:GetSelectedParty(missionID,mission)
	local perc=party.perc or 0
	stats.Chance:SetFormattedText(PERCENTAGE_STRING,perc)
	stats.Chance:SetTextColor(addon:GetDifficultyColors(perc,true))
	parties[missionID]=key
	for i=1,mission.numFollowers do
		if party:Follower(i) then
			if members.Champions[i]:SetFollower(party:Follower(i),true) then
				stats.Chance:SetTextColor(C.Grey())
			end
		else
			members.Champions[i]:SetEmpty()
			stats.Chance:SetTextColor(C.Grey())
		end
		members.Champions[i]:Show()
	end
	for i=mission.numFollowers+1,3 do
			members.Champions[i]:Hide()
	end
		
	return self:AddThreats(frame,threats,party,missionID)
end	
local function goodColor(good,bad)
	if type(bad)=="nil" then bad=not good end
	if good then return "green" 
	elseif bad then return "red" else
	return "tear" end
	
end
local timeIcon="Interface/ICONS/INV_Misc_PocketWatch_01"
local killIcon="Interface/TARGETINGFRAME/UI-RaidTargetingIcon_8"
local lootIcon="Interface/TARGETINGFRAME/UI-RaidTargetingIcon_7"
local resurrectIcon="Interface/ICONS/Spell_Holy_GuardianSpirit"
function module:AddThreats(frame,threats,party,missionID)
	threats:SetPoint("TOPLEFT",frame.Title,"BOTTOMLEFT",0,-5)
	local enemies=addon:GetMissionData(missionID,'enemies')
	if type(enemies)~="table" then 
		enemies=select(8,G.GetMissionInfo(missionID))
	end
	local mechanics=new()
	local counters=new()
	local biases=new()
	for _,enemy in pairs(enemies) do
		if type(enemy.mechanics)=="table" then
		   for mechanicID,mechanic in pairs(enemy.mechanics) do
	   	-- icon=enemy.mechanics[id].icon
	   		mechanic.id=mechanicID
	   		mechanic.bias=-1
				tinsert(mechanics,mechanic)
	   	end
   	end
   end
   for _,followerID in party:IterateFollowers() do
   	if not G.GetFollowerIsTroop(followerID) then
		   local followerBias = G.GetFollowerBiasForMission(missionID,followerID)
		   tinsert(counters,("%04d,%s,%s,%f"):format(1000-(followerBias*100),followerID,G.GetFollowerName(followerID),followerBias))
	   end
   end
   table.sort(counters)
   for _,data in pairs(counters) do
   	local _,followerID,_,bias=strsplit(",",data)
      local abilities=G.GetFollowerAbilities(followerID)
      for _,ability in pairs(abilities) do
         for counter,info in pairs(ability.counters) do
         	for _,mechanic in pairs(mechanics) do
         		if mechanic.id==counter and not biases[mechanic] then
         			biases[mechanic]=tonumber(bias)
         			break
         		end
         	end
         end
		end
   end
--@debug@
   tinsert(mechanics,false) -- separator
   local r,n,i=addon:GetResources()
   local baseCost, cost = party.baseCost or 0 ,party.cost or 0
   -- nobonusloot
	-- increasedcost
	-- increasedduration
	-- killtroops
	if cost>baseCost then
   	tinsert(mechanics,new({icon=i,color="red",name=n,description=increasedcost}))
   end
	if cost<baseCost then
   	tinsert(mechanics,new({icon=i,color="green",name=n,description=L["Cost reduced"]}))
   end
   if party.timeImproved then
   	tinsert(mechanics,new({icon=timeIcon,color="green",name="Time",description=L["Mission duration reduced"]}))
  	end
  	if party.hasMissionTimeNegativeEffect then
   	tinsert(mechanics,new({icon=timeIcon,color="red",name="Time",description=increasedduration}))
   end
   if party.hasKillTroopsEffect then
   	tinsert(mechanics,new({icon=killIcon,color="red",name=ENCOUNTER_JOURNAL_SECTION_FLAG4,description=killtroops}))
   end
   if party.hasResurrectTroopsEffect then
   	tinsert(mechanics,new({icon=resurrectIcon,color="green",name=RESURRECT,description=L["Resurrect troops effect"]}))
   end
   if party.hasBonusLootNegativeEffect then
   	tinsert(mechanics,new({icon=lootIcon,color="red",name=LOOT,description=nobonusloot}))
   end
--@end-debug@
	threats:AddIcons(mechanics,biases)
	threats.Cost:Show()
	threats.Cost:SetFormattedText(addon.resourceFormat,cost)
   local color=goodColor(cost>=r)
	if cost>r then
		threats.Cost:SetTextColor(C:Red())
	else
		threats.Cost:SetTextColor(C:Green())
	end
	threats.Cost:ClearAllPoints()
	threats.Cost:SetPoint("LEFT",frame.Summary,"RIGHT",5,0)
	threats.HighCost:Hide()
   del(mechanics)
   del(counters)
   del(biases)
end
function module:MissionTip(this)
	local tip=GameTooltip
	tip:SetOwner(this,"ANCHOR_CURSOR")	
	tip:AddLine(me)
	tip:AddDoubleLine(addon:GetAverageLevels())
--@debug@
	local info=this:GetParent().info
	OrderHallCommanderMixin.DumpData(tip,info)
	tip:AddLine("Followers")
	for i,id in ipairs(info.followers) do
		tip:AddDoubleLine(id,pcall(G.GetFollowerName,id))
	end
	tip:AddLine("Rewards")
	for i,d in pairs(info.rewards) do
		tip:AddLine('['..i..']')
		OrderHallCommanderMixin.DumpData(tip,info.rewards[i])
	end
	tip:AddLine("OverRewards")
	for i,d in pairs(info.overmaxRewards) do
		tip:AddLine('['..i..']')
		OrderHallCommanderMixin.DumpData(tip,info.overmaxRewards[i])
	end
	tip:AddDoubleLine("MissionID",info.missionID)
	local mission=addon:GetMissionData(info.missionID)
	tip:AddDoubleLine("MissionClass",mission.missionClass)
	tip:AddDoubleLine("MissionValue",mission.missionValue)
	tip:AddDoubleLine("MissionSort",mission.missionSort)
	
--@end-debug@	
	tip:Show()
end
local bestTimes={}
local bestTimesIndex={}
function module:AdjustMissionTooltip(this,...)
	local tip=GameTooltip
	local missionID=this.info.missionID
--@debug@
	tip:AddDoubleLine("MissionID",missionID)
--@end-debug@	
	if this.info.inProgress or this.info.completed then return end
	if not this.info.isRare then
		tip:AddLine(GARRISON_MISSION_AVAILABILITY);
		tip:AddLine(this.info.offerTimeRemaining, 1, 1, 1);
	end

	local party=addon:GetMissionParties(missionID)
	local key=parties[missionID]
	if party then
--@debug@
		print(party)
--@end-debug@	
		local candidate =party:GetSelectedParty(key)
		if candidate then
			if candidate.hasBonusLootNegativeEffect then
				tip:AddLine(nobonusloot,C:Red())
			end
			if candidate.hasKillTroopsEffect then
				tip:AddLine(killtroops,C:Red())
			end
			if candidate.hasResurrectTroopsEffect then
				tip:AddLine(L["Resurrect troops effect"],C:Green())
			end
			if candidate.cost > candidate.baseCost then
				tip:AddLine(increasedcost,C:Red())
			end
			if candidate.hasMissionTimeNegativeEffect then
				tip:AddLine(increasedduration,C:Red())
			end
			if candidate.timeImproved then
				tip:AddLine(L["Duration reduced"],C:Green())
			end
		   local r,n,i=addon:GetResources()
			if candidate.cost > r then
				tip:AddLine(GARRISON_NOT_ENOUGH_MATERIALS_TOOLTIP,C:Red())
			end			
			-- Not important enough to be specifically shown
			-- hasSuccessChanceNegativeEffect
			-- hasUncounterableSuccessChanceNegativeEffect
		end
	end
	-- Mostrare per ogni tempo di attesa solo la percentuale migliore
	wipe(bestTimes)
	wipe(bestTimesIndex)
	key=key or "999999999999999999999"
	if key then
		for _,otherkey in party:IterateIndex() do
			if otherkey < key then
				local candidate=party:GetSelectedParty(otherkey)
				local duration=math.max((candidate.busyUntil or 0)-GetTime(),0)
				if duration > 0 then
					if not bestTimes[duration] or bestTimes[duration] < candidate.perc then
						bestTimes[duration]=candidate.perc
					end
				end
			end
		end
		for t,p in pairs(bestTimes) do
			tinsert(bestTimesIndex,t)
		end
		if #bestTimesIndex > 0 then
			tip:AddLine(me)
			tip:AddLine(L["Better parties available in next future"])
			table.sort(bestTimesIndex)
			local bestChance=0
			for i=1,#bestTimesIndex do
				local key=bestTimesIndex[i]
				if bestTimes[key] > bestChance then
					bestChance=bestTimes[key]
					tip:AddDoubleLine(SecondsToTime(key),GARRISON_MISSION_PERCENT_CHANCE:format(bestChance),C.Orange.r,C.Orange.g,C.Orange.b,addon:GetDifficultyColors(bestChance))
				end
			end
		end
--@debug@
		tip:AddLine("-----------------------------------------------")
		OrderHallCommanderMixin.DumpData(tip,addon:GetMissionParties(this.info.missionID):GetSelectedParty(key))
--@end-debug@
	end
	tip:Show()
	
end
function module:PostMissionClick(this,button)
	local mission=this.info or this.missionInfo -- callable also from mission page
--@debug@
	addon:Print(button)
	if button=="MiddleButton" then
		addon:TestParty(mission.missionID)
		return
	end
--@end-debug@
	addon:GetMissionpageModule():FillMissionPage(mission,parties[mission.missionID])
end
do

end

