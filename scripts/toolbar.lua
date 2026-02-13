local name, _FishMaster = ...;

FishMaster.toolbar = {}

function FishMaster.toolbar:OnLoad(frame)
    if not frame then
        return
    end
    local cast = frame.cast
    if cast then
        cast:SetScript("PostClick", function(self, button)
            FishMaster:debug(
                "Toolbar cast postclick",
                button,
                "protected", self:IsProtected(),
                "enabled", self:IsEnabled(),
                "combat", InCombatLockdown(),
                "type1", self:GetAttribute("type1"),
                "macro1", self:GetAttribute("macrotext1"),
                "type2", self:GetAttribute("type2"),
                "macro2", self:GetAttribute("macrotext2"),
                "type", self:GetAttribute("type"),
                "macro", self:GetAttribute("macrotext"),
                "item", self:GetAttribute("item"),
                "bag", self:GetAttribute("bag"),
                "slot", self:GetAttribute("slot"),
                "spell", self:GetAttribute("spell")
            )
        end)
    end

    if frame.lures then
        for _, lureButton in pairs(frame.lures) do
            lureButton:SetScript("PostClick", function(self, button)
                FishMaster:debug(
                    "Toolbar lure postclick",
                    button,
                    "lureItemId", self:GetAttribute("lureItemId"),
                    "protected", self:IsProtected(),
                    "enabled", self:IsEnabled(),
                    "combat", InCombatLockdown(),
                    "type1", self:GetAttribute("type1"),
                    "macro1", self:GetAttribute("macrotext1"),
                    "type2", self:GetAttribute("type2"),
                    "macro2", self:GetAttribute("macrotext2"),
                    "type", self:GetAttribute("type"),
                    "macro", self:GetAttribute("macrotext"),
                    "item", self:GetAttribute("item"),
                    "bag", self:GetAttribute("bag"),
                    "slot", self:GetAttribute("slot"),
                    "spell", self:GetAttribute("spell")
                )
            end)
        end
    end
end

function FishMaster.toolbar:OnEvent(frame, event, ...)
    if not FishMaster:CheckCombat() then
        FishMaster:ToolbarCast(frame.cast)
    end
end

function FishMaster:Toolbar()
    local parent = _G['FishMaster_Toolbar'];
    if parent and parent.cast then
        FishMaster:ToolbarCast(parent.cast)
    end
    for key, frame in pairs(parent.lures) do
        local lureItemId = frame:GetAttribute("lureItemId")
        local lureItemNum = tonumber(lureItemId)
        local lure = FishMaster:FindLure(lureItemNum);
			if lureItemNum and lure then
				local count = GetItemCount(lureItemNum) or 0;
				frame.count:SetText(count);
				frame.count:Show();
			securecall(function()
				if count > 0 then
					local itemID, bag, slot = FishMaster:FindItemInBags(lure.item);
					frame:SetAlpha(1)
					frame.icon:SetDesaturated(nil)
					frame:SetAttribute("type1", "item");
					frame:SetAttribute("type2", "item");
					frame:SetAttribute("item", nil);
					frame:SetAttribute("bag", bag);
					frame:SetAttribute("slot", slot);
					frame:SetAttribute("target-slot", INVSLOT_MAINHAND);
					frame:SetAttribute("macrotext1", nil);
					frame:SetAttribute("macrotext2", nil);
					frame:SetAttribute("type", nil);
					frame:SetAttribute("macrotext", nil);
					frame:SetAttribute("spell", nil);
				else
					frame:SetAlpha(.4)
					frame.icon:SetDesaturated(1)
                    frame:SetAttribute("macrotext1", nil);
                    frame:SetAttribute("type1", nil);
                    frame:SetAttribute("macrotext2", nil);
                    frame:SetAttribute("type2", nil);
                    frame:SetAttribute("macrotext", nil);
                    frame:SetAttribute("type", nil);
                    frame:SetAttribute("item", nil);
                    frame:SetAttribute("bag", nil);
                    frame:SetAttribute("slot", nil);
                    frame:SetAttribute("target-slot", nil);
                    frame:SetAttribute("spell", nil);
				end
			end)
			
			else
				frame:SetAlpha(.4)
				frame.icon:SetDesaturated(1)
                frame:SetAttribute("macrotext1", nil);
                frame:SetAttribute("type1", nil);
                frame:SetAttribute("macrotext2", nil);
                frame:SetAttribute("type2", nil);
                frame:SetAttribute("macrotext", nil);
                frame:SetAttribute("type", nil);
                frame:SetAttribute("item", nil);
                frame:SetAttribute("bag", nil);
                frame:SetAttribute("slot", nil);
                frame:SetAttribute("target-slot", nil);
                frame:SetAttribute("spell", nil);
			end
    end
end

function FishMaster:ToolbarCast(frame)
    local lured = FishMaster:IsLured();
    local lure = FishMaster:FindBestLure();
    local fishingSpell = PROFESSIONS_FISHING or GetSpellInfo(7620) or "Fishing"
    if not lured and lure and FishMaster.db.char.autoLure then
        local itemID, bag, slot = FishMaster:FindItemInBags(lure.item);
        frame:SetAttribute("type1", "item");
        frame:SetAttribute("type2", "item");
        frame:SetAttribute("item", nil);
        frame:SetAttribute("bag", bag);
        frame:SetAttribute("slot", slot);
        frame:SetAttribute("target-slot", INVSLOT_MAINHAND);
        frame:SetAttribute("spell", nil);
        frame:SetAttribute("macrotext1", nil);
        frame:SetAttribute("macrotext2", nil);
    else
        frame:SetAttribute("type1", "spell");
        frame:SetAttribute("type2", "spell");
        frame:SetAttribute("spell", fishingSpell);
        frame:SetAttribute("item", nil);
        frame:SetAttribute("bag", nil);
        frame:SetAttribute("slot", nil);
        frame:SetAttribute("target-slot", nil);
        frame:SetAttribute("macrotext1", nil);
        frame:SetAttribute("macrotext2", nil);
    end
    frame:SetAttribute("type", nil);
    frame:SetAttribute("macrotext", nil);

    if _FishMaster.isCasting then
        frame.icon:SetDesaturated(1);
    else
        frame.icon:SetDesaturated(nil);
    end
end
