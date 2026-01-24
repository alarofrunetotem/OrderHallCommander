---------------------------------------------------------------------------------
--- OrderHallClassSpecCategory                                                     ---
---------------------------------------------------------------------------------

OrderHallClassSpecCategory = { }

function OrderHallClassSpecCategory:OnEnter()
	if (self.name) then
		GameTooltip:SetOwner(self, "ANCHOR_PRESERVE");
		GameTooltip:ClearAllPoints();
		GameTooltip:SetPoint("TOPLEFT", self.Count, "BOTTOMRIGHT", -20, -20);
		GameTooltip:AddLine(self.name);
		if (self.description) then
			GameTooltip:AddLine(self.description, 1, 1, 1, true);
		end
		GameTooltip:Show();
	end
end

function OrderHallClassSpecCategory:OnLeave()
	GameTooltip:Hide();
end

