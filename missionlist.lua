local __FILE__=tostring(debugstack(1,2,0):match("(.*):1:")) -- Always check line number in regexp and file
local function pp(...) print("|cffff9900",__FILE__:sub(-15),strjoin(",",tostringall(...)),"|r") end
--*TYPE module
--*CONFIG noswitch=false,profile=true,enhancedProfile=true
--*MIXINS "AceHook-3.0","AceEvent-3.0","AceTimer-3.0"
--*MINOR 35
-- Generated on 04/12/2016 11:15:56
local me,ns=...
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
local followerType=LE_FOLLOWER_TYPE_GARRISON_7_0
local garrisonType=LE_GARRISON_TYPE_7_0
local FAKE_FOLLOWERID="0x0000000000000000"
local MAXLEVEL=110
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
-- Additonal frames
local GARRISON_MISSION_AVAILABILITY2=GARRISON_MISSION_AVAILABILITY .. " %s"
local GARRISON_MISSION_ID="MissionID: %d"
local missionstats=setmetatable({}, {__mode = "k"})
local missionmembers=setmetatable({}, {__mode = "k"})
local missionthreats=setmetatable({}, {__mode = "k"})
local missionids=setmetatable({}, {__mode = "k"})
local spinners=setmetatable({}, {__mode = "k"})
local parties=setmetatable({}, {__mode = "k"})
local buttonlist={}
local oGarrison_SortMissions=Garrison_SortMissions
local function nop() end
local Current_Sorter
local sorters={
		Garrison_SortMissions_Original=oGarrison_SortMissions,
		Garrison_SortMissions_Chance=function(a,b) 
			local aparty=addon:GetParties(a.missionID):GetSelectedParty() 
			local bparty=addon:GetParties(b.missionID):GetSelectedParty()
			return aparty.perc>bparty.perc 
		end,
		Garrison_SortMissions_Level=function(a,b) return a.level==b.level and a.iLevel<b.iLevel or a.level <b.level end,
		Garrison_SortMissions_Age=function(a,b) return (a.offerEndTime or 0) < (b.offerEndTime or 0) end,
		Garrison_SortMissions_Xp=function(a,b) 
			local aparty=addon:GetParties(a.missionID):GetSelectedParty() 
			local bparty=addon:GetParties(b.missionID):GetSelectedParty()
			return aparty.perc>bparty.perc 
		end,
		Garrison_SortMissions_Duration=function(a,b) 
			local aparty=addon:GetParties(a.missionID):GetSelectedParty() 
			local bparty=addon:GetParties(b.missionID):GetSelectedParty()
			return aparty.timeseconds<bparty.timeseconds 
		end,
		Garrison_SortMissions_Class=function(a,b)
			local aclass=addon:reward2class(a) 
			local bclass=addon:reward2class(b) 
			return aclass>bclass
		end,
}
function module:OnInitialized()
	addon:AddSelect("SORTMISSION","Garrison_SortMissions_Original",
	{
		Garrison_SortMissions_Original=L["Original method"],
		Garrison_SortMissions_Chance=L["Success Chance"],
		Garrison_SortMissions_Level=L["Level"],
		Garrison_SortMissions_Age=L["Expiration Time"],
		Garrison_SortMissions_Xp=L["Global approx. xp reward"],
		Garrison_SortMissions_Duration=L["Duration Time"],
		Garrison_SortMissions_Class=L["Reward type"],
	},
	L["Sort missions by:"],L["Changes the sort order of missions in Mission panel"])

	addon:RegisterForMenu("mission","SORTMISSION")
	self:LoadButtons(OHFMissions.listScroll.scrollChild:GetChildren())	

	self:SecureHookScript(OHF--[[MissionTab--]],"OnShow","InitialSetup")
end
function module:Print(...)
	print(...)
end
function module:LoadButtons(...)
--	for i=1,select('#',...) do
--		local button=select(i,...)
	local buttons=OHFMissions.listScroll.buttons
	for i=1,#buttons do
		local button=buttons[i]	
		self:SecureHookScript(button,"OnEnter","AdjustMissionTooltip")
		self:SecureHookScript(button,"OnClick","PostMissionClick")
		tinsert(buttonlist,button)
	end
end
-- This method is called also when overing on tooltips
-- keeps a reference to the mission currently bound to this button
local missionIDS={}
function module:OnUpdate(this)
	print("OnUpdate")
	for _,frame in pairs(buttonlist) do
		if frame:IsVisible() then
			self:AdjustPosition(frame)
			if frame.info.missionID ~= missionIDS[frame] then
				self:AdjustMissionButton(frame)
				missionIDS[frame]=frame.info.missionIDS
			end
		end
	end
end
-- called when needed a full upodate (reload mission data)
function module:OnUpdateMissions(...)
	if OHFMissions:IsVisible() then
		print("OnUpdateMissions")
		self:SortMissions()
		OHFMissions:Update()
		for _,frame in pairs(buttonlist) do
			if frame:IsVisible() then
				self:AdjustMissionButton(frame,frame.info.rewards)
			end
		end
	end
end
local function sortfunc1(a,b)
	return a.timeLeftSeconds < b.timeLeftSeconds
end
function module:SortMissions()
	if OHFMissions:IsVisible() then
		UpdateAddOnMemoryUsage()
		local pre=GetAddOnMemoryUsage(me)
		local path="available"
		if OHFMissions.inProgress then
			table.sort(OHFMissions.inProgressMissions,sortfunc1)
			pat="inProgress"
		else
			table.sort(OHFMissions.availableMissions,sorters[Current_Sorter])
		end
		UpdateAddOnMemoryUsage()
		local post=GetAddOnMemoryUsage(me)
		print("Called sortmissions for",path,"memory from",pre,"to",post)
	end
end
function addon:ApplySORTMISSION(value)
	Current_Sorter=value
	addon:RefreshMissions()
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
function module:InitialSetup(this)
	local previous
	menu=CreateFrame("Frame",nil,OHFMissionTab,"OHCMenu")
	close=menu.CloseButton
	button=CreateFrame("Button",nil,OHFMissionTab,"OHCPin")
	button.tooltip=L["Show/hide OrderHallCommander mission menu"]
	close:SetScript("OnClick",CloseMenu)
	button:SetScript("OnClick",OpenMenu)
	button:GetNormalTexture():SetRotation(math.rad(270))
	button:GetHighlightTexture():SetRotation(math.rad(270))
	if addon.db.profile.showmenu then OpenMenu() else CloseMenu() end
	local factory=addon:GetFactory()
	for _,v in pairs(addon:GetRegisteredForMenu("mission")) do
		local flag,icon=strsplit(',',v)
		--local f=addon:CreateOption(flag,menu)
		local f=factory:Option(addon,menu,flag)
		if type(f)=="table" and f.GetObjectType then
			if previous then 
				f:SetPoint("TOPLEFT",previous,"BOTTOMLEFT",0,-15)
			else
				f:SetPoint("TOPLEFT",menu,"TOPLEFT",32,-25)
			end
			previous=f
		end
	end 
	addon.MAXLEVEL=OHF.followerMaxLevel
	addon.MAXQUALITY=OHF.followerMaxQuality
	addon.MAXQLEVEL=addon.MAXLEVEL+addon.MAXQUALITY
	self:Unhook(this,"OnShow")
	self:SecureHookScript(this,"OnShow","MainOnShow")	
	self:SecureHookScript(this,"OnHide","MainOnHide")	
	self:MainOnShow()
end
function module:MainOnShow()
	self:SecureHook(OHFMissions,"UpdateMissions","OnUpdateMissions")
	self:SecureHook(OHFMissions,"Update","OnUpdate")
	addon:ApplySORTMISSION(addon:GetString("SORTMISSION"))
end
function module:MainOnHide()
	self:Unhook(OHFMissions,"UpdateMissions")
	self:Unhook(OHFMissions,"Update")
	self:Unhook("Garrison_SortMissions")	
end
function module:AdjustPosition(frame)
	local mission=frame.info
	frame.Title:ClearAllPoints()
	if  mission.isResult then
		frame.Title:SetPoint("TOPLEFT",165,15)
	elseif  mission.inProgress then
		--frame.Title:SetPoint("TOPLEFT",165,-10)
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
	
end
function module:AdjustMissionButton(frame)
	if not OHF:IsVisible() then return end
	local mission=frame.info
	local missionID=mission and mission.missionID
	if not missionID then return end
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
	local party,key=addon:GetParties(missionID):GetSelectedParty(mission)
	parties[missionID]=key
	local members=missionmembers[frame]
	local stats=missionstats[frame]
	members:SetPoint("RIGHT",frame.Rewards[nrewards],"LEFT",-5,0)
	for i=1,3 do
		if party:Follower(i) then
			members.Champions[i]:SetFollower(party:Follower(i))
		else
			members.Champions[i]:SetEmpty()
		end
	end
	local perc=party.perc or 0
	if perc==0 then
		stats.Chance:SetText("N/A")
	else
		stats.Chance:SetFormattedText(PERCENTAGE_STRING,perc)
	end		
	stats.Chance:SetTextColor(addon:GetDifficultyColors(perc))
	if party then
		if party.timeimproved then	
			frame.Summary:SetTextColor(C:Green())
		elseif party.hasMissionTimeNegativeEffect then
			frame.Summary:SetTextColor(C:Red())
		end
	end		
	local threats=missionthreats[frame]
	if frame.info.inProgress then
		frame.Overlay:SetFrameLevel(20)
		threats:Hide()
		return
	else
		threats:Show()
	end
	threats:SetPoint("TOPLEFT",frame.Title,"BOTTOMLEFT",0,-5)
	local enemies=select(8,G.GetMissionInfo(missionID))
	if type(enemies)~="table" then print("No enemies loaded") return end
	local mechanics=new()
	local counters=new()
	for _,enemy in pairs(enemies) do
	   for mechanicID,mechanic in pairs(enemy.mechanics) do
   	-- icon=enemy.mechanics[id].icon
   		mechanic.id=mechanicID
   		mechanic.bias=-1
			tinsert(mechanics,mechanic)
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
   	local bias,followerID=strsplit(",",data)
      local abilities=G.GetFollowerAbilities(followerID)
      for _,ability in pairs(abilities) do
         for counter,info in pairs(ability.counters) do
         	for _,mechanic in pairs(mechanics) do
         		if mechanic.id==counter and not mechanic.countered then
         			mechanic.countered=true
         			mechanic.bias=tonumber(bias)
         			break
         		end
         	end
         end
		end
   end
   local color="Yellow"
   local baseCost, cost = party.baseCost ,party.cost
	if cost<baseCost then
		color="Green"
	elseif cost>baseCost then
		color="Red"
	end
	if frame.IsCustom or OHFMissions.showInProgress then
		cost=-1
	end
   if not threats:AddIconsAndCost(mechanics,cost,color,cost > addon:GetResources()) then
   	addon:RefreshMissions()
   end
   del(mechanics)
   del(counters)
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
	tip:AddDoubleLine("Type",addon:reward2class(info))
--@end-debug@	
	tip:Show()
end
local bestTimes={}
local bestTimesIndex={}
function module:AdjustMissionTooltip(this,...)
	if this.info.inProgress or this.info.completed then return end
	local missionID=this.info.missionID
	local tip=GameTooltip
	if not this.info.isRare then
		GameTooltip:AddLine(GARRISON_MISSION_AVAILABILITY);
		GameTooltip:AddLine(this.info.offerTimeRemaining, 1, 1, 1);
	end
--@debug@
	tip:AddDoubleLine("MissionID",missionID)
--@end-debug@	
	local party=addon:GetParties(missionID)
	local key=parties[missionID]
	-- Mostrare per ogni tempo di attesa solo la percentuale migliore
	wipe(bestTimes)
	wipe(bestTimesIndex)
	if key then
		for _,otherkey in party:IterateIndex() do
			if otherkey < key then
				local candidate=party:GetSelectedParty(otherkey)
				local duration=(candidate.busyUntil or 0)-GetTime()
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
					tip:AddDoubleLine(SecondsToTime(key),GARRISON_MISSION_PERCENT_CHANCE:format(bestChance))
				end
			end
		end
--@debug@
		tip:AddLine("-----------------------------------------------")
		OrderHallCommanderMixin.DumpData(tip,addon:GetParties(this.info.missionID):GetSelectedParty(key))
	end
--@end-debug@	
	tip:Show()
	
end
function module:PostMissionClick(this,...)
	local mission=this.info or this.missionInfo -- callable also from mission page
	addon:GetMissionpageModule():FillMissionPage(mission,parties[mission.missionID])
end

