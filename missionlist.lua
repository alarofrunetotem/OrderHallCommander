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
local function nop() end
local Current_Sorter
local sorters={
		Garrison_SortMissions_Original=nop,
		Garrison_SortMissions_Chance=function(a,b) 
			local achance=addon:GetParties(a.missionID):GetSelectedParty() 
			local bchance=addon:GetParties(b.missionID):GetSelectedParty()
			return achance.perc>bchance.perc 
		end,
		Garrison_SortMissions_Level=function(a,b) return a.level==b.level and a.iLevel<b.iLevel or a.level <b.level end,
		Garrison_SortMissions_Age=function(a,b) print(a.name) return a.offerEndTime < b.offerEndTime end,
		Garrison_SortMissions_Xp=nop,
		Garrison_SortMissions_Duration=nop,
		Garrison_SortMissions_Class=nop
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
	for i=1,16 do
		local name="OrderHallMissionFrameMissionsListScrollFrameButton"..i
		if _G[name] then
			self:SecureHookScript(_G[name],"OnEnter","AdjustMissionTooltip")
			self:SecureHookScript(_G[name],"OnClick","PostMissionClick")
		end		
	end
	self:SecureHook("GarrisonMissionButton_SetRewards","AdjustMissionButton")
	self:SecureHookScript(OHFMissionTab,"OnShow","InitialSetup")
	self:SecureHook(OHFMissions,"UpdateMissions","MissionDataRefresh")
	self:SecureHook("Garrison_SortMissions","SortMissions")	
	addon:ApplySORTMISSION(addon:GetString("SORTMISSION"))
end
function module:MissionDataRefresh(...)
	print("Called UpdateMissions",...)
end
function module:SortMissions(missionsList)
	if OHFMissions:IsVisible() then
		if OHFMissions.inProgress then
			table.sort(missionsList,function(a,b) return a.timeLeftSeconds < b.timeLeftSeconds end)
		else
			table.sort(missionsList,sorters[Current_Sorter])
		end
	end
end
function addon:ApplySORTMISSION(value)
	Current_Sorter=value
	local this=OHFMissions
	if (this.showInProgress) then
		module:SortMissions(this.inProgressMissions)
	else
		module:SortMissions(this.availableMissions)
	end
	print("Sorting by",value)
	OHFMissions:Update()
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
function addon:CreateOption(flag,parent)
	if (not flag) then return 0 end
	local info=self:GetVarInfo(flag)
	local f
	if (info) then
		dprint("Create Option",flag,info.type,parent)
		if (info.type=="toggle") then
			f=CreateFrame("CheckButton",nil,parent or UIParent,"OHCTab")
			f:SetChecked(ToggleGet(flag,info.type))	
			f:SetScript("OnClick",PreToggleSet)	
		elseif( info.type=="select") then
		--factory:Dropdown(father,current,list,message,tooltip)
			f=CreateFrame("Frame",nil,parent or UIParent,"OHCTab")
			local s=self:GetFactory():DropDown(f,ToggleGet(flag,info.type),info.values,info)			
			s:SetWidth(200)
		elseif (info.type=="execute") then
		elseif (info.type=="range") then
			f=CreateFrame("Frame",nil,parent or UIParent,"OHCTab")
			local s=self:GetFactory():Slider(f,info.min,info.max,ToggleGet(flag,info.type),info)
			s:SetWidth(200)
		else
		end
		if f then
			f.flag=flag
			f.tipo=info.type
			f.OnChange=ToggleSet
			f.tooltip=C(info.name,"Orange") .. ":" .. info.desc
			f:Show()
		end
	end
	return f
end
function module:InitialSetup(this)
	local previous
	local menu=CreateFrame("Frame",nil,OHFMissionTab,"OHCMenu")
	local factory=addon:GetFactory()
	for _,v in pairs(addon:GetRegisteredForMenu("mission")) do
		local flag,icon=strsplit(',',v)
		--local f=addon:CreateOption(flag,menu)
		local f=factory:Option(addon,menu.Anchor,flag)
		if type(f)=="table" and f.GetObjectType then
			if previous then 
				f:SetPoint("TOPLEFT",previous,"BOTTOMLEFT",0,-15)
			else
				f:SetPoint("TOPLEFT",menu,"TOPLEFT",32,-25)
			end
			previous=f
		end
	end 
	self:Unhook(this,"OnShow")
	
end
function module:AdjustMissionButton(frame,rewards)
	if not frame:IsVisible() then return end
	local nrewards=#rewards
	local mission=frame.info
	local missionID=mission and mission.missionID
	if not missionID then return end
	if not OHF:IsVisible() then return end
	local anchor,frame,refAnchor,x,y=frame.Title:GetPoint(1)
	frame.Title:SetPoint(anchor,frame,refAnchor,x,y+20)
	missionids[frame]=missionID
	-- Common setup
	if mission.isRare then 
		frame.Title:SetTextColor(frame.RareText:GetTextColor())
	else
		frame.Title:SetTextColor(C:White())
	end
	frame.RareText:Hide()
	-- Adding stats frame (expiration date and chance)
	if not missionstats[frame] then
		missionstats[frame]=CreateFrame("Frame",nil,frame,"OHCStats")
--@debug@
		self:RawHookScript(missionstats[frame],"OnEnter","MissionTip")
--@end-debug@		
	end
	local stats=missionstats[frame]
	-- Compacting mission time and level
	frame.RareText:Hide()
	frame.Level:ClearAllPoints()
	frame.MissionType:ClearAllPoints()
	local aLevel,aIlevel=addon:GetAverageLevels()
	if mission.isMaxLevel then
		frame.Level:SetText(mission.iLevel)
		frame.Level:SetTextColor(addon:GetDifficultyColors(math.floor((aIlevel-750)/(mission.iLevel-750)*100)))
	else
		frame.Level:SetText(mission.level)
		frame.Level:SetTextColor(addon:GetDifficultyColors(math.floor(aLevel/mission.level*100)))
	end
	frame.ItemLevel:Hide()
	frame.Level:SetPoint("LEFT",5,0)
	frame.MissionType:SetPoint("LEFT",5,0)		
	stats.Expire:SetFormattedText("%s\n%s",GARRISON_MISSION_AVAILABILITY,mission.offerTimeRemaining)
	stats.Expire:SetTextColor(addon:GetAgeColor(mission.offerEndTime))		
	if mission.inProgress then
		stats:SetPoint("LEFT",48,30)
		stats.Expire:Hide()
	else
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
	self:AddMembers(frame,rewards)
end
function module:AddMembers(frame,rewards)
	local start=GetTime()
	local nrewards=#rewards
	local mission=frame.info
	local missionID=mission and mission.missionID
	local followers=mission.followers
	local party=addon:GetParties(missionID):GetSelectedParty(mission)
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
   local baseCost, cost = party.baseCost or 0,party.cost or 0
	if cost<baseCost then
		color="Green"
	elseif cost>baseCost then
		color="Red"
	end
	if frame.IsCustom or OHFMissions.showInProgress then
		cost=-1
	end
   threats:AddIconsAndCost(mechanics,cost,color,cost > addon:GetResources())
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
--@end-debug@	
	tip:Show()
end
function module:AdjustMissionTooltip(this,...)
	if this.info.inProgress or this.info.completed then return end
	local tip=GameTooltip
	tip:AddLine(me)
	local party=parties[this]
--@debug@
	if party then
		OrderHallCommanderMixin.DumpData(tip,party)
	end
--@end-debug@	
	tip:Show()
	
end
function module:PostMissionClick(this,...)
	addon:GetMissionpageModule():FillMissionPage(this.info)
end

