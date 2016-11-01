--*TYPE module
--*CONFIG noswitch=false,profile=true,enhancedProfile=true
--*MIXINS "AceHook-3.0","AceEvent-3.0","AceTimer-3.0"
--*MINOR 35
--*BEGIN
local UpgradeFrame
local UpgradeButtons={}
local pool={}
--@debug@
local debugInfo
--@end-debug@

function module:OnInitialized()
	UpgradeFrame=CreateFrame("Frame",nil,OHFFollowerTab)
	local u=UpgradeFrame
	u:SetPoint("TOPLEFT",OHFFollowerTab,"TOPLEFT",5,-72)
	u:SetPoint("BOTTOMLEFT",OHFFollowerTab,"BOTTOMLEFT",5,7)
	u:SetWidth(70)
	u:Show()
	--addon:SetBackdrop(u,C:Green())
	u:SetScript("OnShow",print)
	self:SecureHook("GarrisonMission_SetFollowerModel","RefreshUpgrades")
	self:RegisterEvent("GARRISON_FOLLOWER_UPGRADED")
--@debug@
	UpgradeFrame:EnableMouse(true)
	self:RawHookScript(UpgradeFrame,"OnEnter","ShowFollowerData")
	debugInfo=u:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	debugInfo:SetPoint("TOPLEFT",70,00)
--@end-debug@	
end
function module:ShowFollowerData(this)
	local tip=GameTooltip
	tip:SetOwner(this,"CURSOR_ANCHOR")
	tip:AddLine(me)
	OrderHallCommanderMixin.DumpData(tip,addon:GetChampionData(OHFFollowerTab.followerID))
	tip:Show()
end
function module:GARRISON_FOLLOWER_UPGRADED(event,followerType,followerId)
	if not followerId or followerType==LE_FOLLOWER_TYPE_GARRISON_7_0 then
		self:RefreshUpgrades()
	end
end
function module:RenderUpgradeButton(id,previous)
		local qt=GetItemCount(id)
		if qt== 0 then return previous end --Not rendering empty buttons
		local b=self:AcquireButton()
		if previous then
			b:SetPoint("TOPLEFT",previous,"BOTTOMLEFT",0,-8)
		else
			b:SetPoint("TOPLEFT",5,-10)
		end
		previous=b
		b.itemID=id
		b:SetAttribute("item",select(2,GetItemInfo(id)))		
		GarrisonMissionFrame_SetItemRewardDetails(b)
		b.Quantity:SetFormattedText("%d",qt)
		b.Quantity:SetTextColor(C.Yellow())
		b.Quantity:Show()
		b:Show()
		return b
end 
function module:RefreshUpgrades(model,followerID,displayID,showWeapon)
--@debug@
	debugInfo:SetText(followerID)
--@end-debug@
	if model then
		UpgradeFrame:SetFrameStrata(model:GetFrameStrata())
		UpgradeFrame:SetFrameLevel(model:GetFrameLevel()+5)
	end
	if not followerID then followerID=OHFFollowerTab.followerID end
	local follower=addon:GetChampionData(followerID)
	for i=1,#UpgradeButtons do
		self:ReleaseButton(UpgradeButtons[i])
	end
	wipe(UpgradeButtons)
	if follower.isTroop then return end
	if follower.status==GARRISON_FOLLOWER_ON_MISSION then return end
	local u=UpgradeFrame
	local previous
	if follower.iLevel <850 then
		for _,id in pairs(addon:GetData("Upgrades")) do
			previous=self:RenderUpgradeButton(id,previous)
		end	
	end
	if follower.isMaxLevel and  follower.quality ~=LE_ITEM_QUALITY_EPIC then
		for _,id in pairs(addon:GetData("Xp")) do
			previous=self:RenderUpgradeButton(id,previous)
		end	
	end
	if follower.quality >=LE_ITEM_QUALITY_RARE then
		for _,id in pairs(addon:GetData("Equipment")) do
			previous=self:RenderUpgradeButton(id,previous)
		end	
	end
end
function module:AcquireButton()
	local b=tremove(pool)
	if not b then
		b=CreateFrame("Button",nil,UpgradeFrame,"OHCUpgradeButton,SecureActionbuttonTemplate")
		b:EnableMouse(true)
		b:RegisterForClicks("LeftButtonDown")
		b:SetAttribute("type","item")
		b:SetSize(40,40)
		b.Icon:SetSize(40,40)
		b:EnableMouse(true)
		b:RegisterForClicks("LeftButtonDown")	
	end		
	tinsert(UpgradeButtons,b)
	return b
end
function module:ReleaseButton(u)
	u:Hide()
	u:ClearAllPoints()
	tinsert(pool,u)
end	
local CONFIRM1=L["Upgrading to |cff00ff00%d|r"].."\n" .. CONFIRM_GARRISON_FOLLOWER_UPGRADE
local CONFIRM2=L["Upgrading to |cff00ff00%d|r"].."\n|cffffd200 "..L["You are wasting |cffff0000%d|cffffd200 point(s)!!!"].."|r\n" .. CONFIRM_GARRISON_FOLLOWER_UPGRADE
local function DoUpgradeFollower(this)
		G.CastSpellOnFollower(this.data);
end
local function UpgradeFollower(this)
	local follower=this:GetParent()
	local followerID=follower.followerID
	local upgradelevel=this.rawlevel
	local genere=this.tipo:sub(1,1)
	local currentlevel=genere=="w" and follower.ItemWeapon.itemLevel or  follower.ItemArmor.itemLevel
	local name = ITEM_QUALITY_COLORS[G.GetFollowerQuality(followerID)].hex..G.GetFollowerName(followerID)..FONT_COLOR_CODE_CLOSE;
	local losing=false
	local upgrade=math.min(upgradelevel>600 and upgradelevel or upgradelevel+currentlevel,GARRISON_FOLLOWER_MAX_ITEM_LEVEL)
	if upgradelevel > 600 and currentlevel>600 then
		if (currentlevel > upgradelevel) then
			losing=upgradelevel - 600
		else
			losing=currentlevel -600
		end
	elseif upgrade > GARRISON_FOLLOWER_MAX_ITEM_LEVEL then
		losing=(upgrade)-GARRISON_FOLLOWER_MAX_ITEM_LEVEL
	end
	if losing then
		return module:Popup(format(CONFIRM2,upgrade,losing,name),0,DoUpgradeFollower,true,followerID,true)
	else
		if addon:GetToggle("NOCONFIRM") then
			return G.CastSpellOnFollower(followerID);
		else
			return module:Popup(format(CONFIRM1,upgrade,name),0,DoUpgradeFollower,true,followerID,true)
		end
	end
end
