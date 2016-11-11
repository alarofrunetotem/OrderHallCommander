local __FILE__=tostring(debugstack(1,2,0):match("(.*):1:")) -- Always check line number in regexp and file
--*TYPE module
--*CONFIG noswitch=false,profile=true,enhancedProfile=true
--*MIXINS "AceHook-3.0","AceEvent-3.0","AceTimer-3.0"
--*MINOR 35
-- Generated on 04/11/2016 15:14:56
local me,ns=...
local addon=ns --#Addon (to keep eclipse happy)
ns=nil
local module=addon:NewSubModule('Missionlist',"AceHook-3.0","AceEvent-3.0","AceTimer-3.0")  --#Module
function addon:GetMissionlist() return module end
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
local OHFMissions=OrderHallMissionFrame.MissionTab.MissionList -- same as OrderHallMissionFrameMissions 
local OHFFollowerTab=OrderHallMissionFrame.FollowerTab -- Contains model view
local OHFFollowerList=OrderHallMissionFrame.FollowerList -- Contains follower list (visibe in both follower and mission mode)
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
--*end-if-non-addon*
--[===[*if-addon*
-- Addon Build, we need to create globals the easy way
local function encapsulate()
if LibDebug then LibDebug() dprint=print end
end
encapsulate()
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
local missionstats={}
local missionmembers={}
local missionthreats={}
local missionids={}
function module:OnInitialized()
	addon:AddSelect("SORTMISSION","Garrison_SortMissions_Original",
	{
		Garrison_SortMissions_Original=L["Original method"],
		Garrison_SortMissions_Chance=L["Success Chance"],
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
			s:SetPoint("BOTTOMLEFT",32,0)
		elseif (info.type=="execute") then
		elseif (info.type=="range") then
			f=CreateFrame("Frame",nil,parent or UIParent,"OHCTab")
			local s=self:GetFactory():Slider(f,info.min,info.max,ToggleGet(flag,info.type),info)
			s:SetWidth(200)
			s:SetPoint("BOTTOMLEFT",32,0)
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
		local f=factory:Option(addon,menu,flag)
		if type(f)=="table" and f.GetObjectType then
			if previous then 
				f:SetPoint("TOPLEFT",previous,"BOTTOMLEFT",0,-15)
			else
				f:SetPoint("TOPLEFT",menu,"TOPLEFT",0,-25)
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
	if mission.cost > addon:GetResources() then
		frame.Title:SetTextColor(C:Red())
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
	stats:SetPoint("LEFT",48,0)
	local perc=select(4,G.GetPartyMissionInfo(missionID)) 
	local followers=mission.followers
	if not followers or #mission.followers<1 then
		followers,perc= addon:GetParty(missionID):GetFollowers(perc)
	end
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
	stats.Chance:SetFormattedText(PERCENTAGE_STRING,perc)
	stats.Chance:SetTextColor(addon:GetDifficultyColors(perc))		
	stats.Expire:Show()
	stats.Chance:Show()
	if not missionmembers[frame] then
		missionmembers[frame]=CreateFrame("Frame",nil,frame,"OHCMembers")
	end
	-- Adding members frame
	local members=missionmembers[frame]
	members:SetPoint("RIGHT",frame.Rewards[nrewards],"LEFT",-5,0)
	if followers then
		for i=1,3 do
			if followers[i] then
				members.Champions[i]:SetFollower(followers[i])
			else
				members.Champions[i]:SetEmpty()
			end
		end
		if #followers==0 then
			stats.Chance:SetText("N/A")
		end
	end
	self:FillCounterFrame(frame,missionID,followers)
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
		tip:AddDoubleLine(id,G.GetFollowerName(id))
	end
	tip:AddLine("Rewards")
	for i,d in pairs(info.rewards) do
		tip:AddLine(i)
		OrderHallCommanderMixin.DumpData(tip,info.rewards[i])
	end
	tip:AddLine("OverRewards")
	for i,d in pairs(info.overmaxRewards) do
		tip:AddLine(i)
		OrderHallCommanderMixin.DumpData(tip,info.overmaxRewards[i])
	end
--@end-debug@	
	tip:Show()
end
local pippo=0
function module:FillCounterFrame(frame,missionID,followers)
	if not missionthreats[frame] then
		missionthreats[frame]=CreateFrame("Frame",nil,frame,"OHCThreats")
		pippo=pippo+1
	end
	local threats=missionthreats[frame]
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
   for _,followerID in pairs(followers) do
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
   threats:AddIcons(mechanics)
   if missionID==1203 then
   	DevTools_Dump(mechanics)
   	DevTools_Dump(counters)
   end
   --del(mechanics)
   del(counters)
end
function module:AdjustMissionTooltip(this,...)
	local tip=GameTooltip
	tip:AddLine(me)
--@debug@
	OrderHallCommanderMixin.DumpData(tip,this)
--@end-debug@	
	tip:Show()
	
end
function module:PostMissionClick(this,...)
	dprint(this:GetName(),this.info)
	self:FillMissionPage(this.info)
end
function module:FillMissionPage(missionInfo)

	if type(missionInfo)=="number" then missionInfo=addon:GetMissionData(missionInfo) end
	if not missionInfo then return end
	local missionType=missionInfo.followerTypeID
	if missionType==LE_FOLLOWER_TYPE_SHIPYARD_6_2 or missionType==LE_FOLLOWER_TYPE_GARRISON_7_0 then
		if not missionInfo.canStart then return end
	end
	local main=OHF
	if not main then return end
	local missionpage=main.MissionTab.MissionPage
	local stage=main.MissionTab.MissionPage.Stage
	local missionenv=stage.MissionInfo.MissionTime
	if not stage.MissionSeen then
		if not stage.expires then
			stage.expires=stage:CreateFontString()
			stage.expires:SetFontObject(missionenv:GetFontObject())
			stage.expires:SetDrawLayer(missionenv:GetDrawLayer())
			stage.expires:SetPoint("TOPLEFT",missionenv,"BOTTOMLEFT")
		end
		stage.expires:SetFormattedText(GARRISON_MISSION_AVAILABILITY2,missionInfo.offerTimeRemaining or "")
		stage.expires:SetTextColor(addon:GetAgeColor(missionInfo.offerEndTime))
	else
		stage.expires=stage.MissionSeen -- In order to anchor missionId
	end
--@debug@
	if not stage.missionid then
		stage.missionid=stage:CreateFontString()
		stage.missionid:SetFontObject(missionenv:GetFontObject())
		stage.missionid:SetDrawLayer(missionenv:GetDrawLayer())
		stage.missionid:SetPoint("TOPLEFT",stage.expires,"BOTTOMLEFT")
	end
	stage.missionid:SetFormattedText(GARRISON_MISSION_ID,missionInfo.missionID)
--@end-debug@
	if( IsControlKeyDown()) then self:Print("Ctrl key, ignoring mission prefill") return end
	if (addon:GetBoolean("NOFILL")) then return end
	local missionID=missionInfo.missionID
	addon:HoldEvents()
	main:ClearParty()
	local followers=addon:GetParty(missionID):GetFollowers()
	for i=1,missionInfo.numFollowers do
		local followerframe=missionpage.Followers[i]
		local followerID=followers[i]
		if (followerID) then
			main:AssignFollowerToMission(followerframe,addon:GetChampionData(followerID))
		end
	end
	main:UpdateMissionParty(main.MissionTab.MissionPage.Followers)
	main:UpdateMissionData(main.MissionTab.MissionPage)
	--self:Dump(GMF.MissionTab.MissionPage.Followers,"Selected followers")
	--GarrisonMissionPage_UpdateEmptyString()
	addon:ReleaseEvents()
end
