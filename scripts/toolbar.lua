local name, _FishMaster = ...;
local FM_Classic = WOW_PROJECT_CLASSIC;

FishMaster.toolbar = {}

function FishMaster.toolbar.OnLoad(frame)
    
end

function FishMaster.toolbar:OnEvent(frame, event, ...)
    if not FishMaster:CheckCombat() then
        FishMaster:ToolbarCast(frame.cast)
    end
end

function FishMaster:Toolbar()
    local parent = _G['FishMaster_Toolbar'];
	local frameCount = 0
    for key, frame in pairs(parent.lures) do
        local item = frame:GetAttribute("item")
        local lure = FishMaster:FindLure(tonumber(item));
			if item and lure then
				local count = GetItemCount(item);
				frame.count:SetText(count);
				frame.count:Show();
			securecall(function()
				if count > 0 then
					frame:SetAlpha(1)
					frame.icon:SetDesaturated(nil)
					frame:SetAttribute("type", "macro");
					frame:SetAttribute("macrotext", "/cast " .. GetSpellInfo(lure.spell));
					frame:SetAttribute("target-slot", INVSLOT_MAINHAND);
						if frameCount > 12 and WOW_PROJECT_ID == FM_Classic then
							frame:Hide();
						end
					
				else
					frame:SetAlpha(.4)
					frame.icon:SetDesaturated(1)
                    frame:SetAttribute("macrotext", nil);
						if frameCount > 12 and WOW_PROJECT_ID == FM_Classic then
							frame:Hide();
						end
				end
			end)
			
			else
				frame:SetAlpha(.4)
				frame.icon:SetDesaturated(1)
                frame:SetAttribute("macrotext", nil);
			end
			frameCount = frameCount + 1;
    end
end

function FishMaster:ToolbarCast(frame)
    local lured = FishMaster:IsLured();
    local lure = FishMaster:FindBestLure();
    local text = "";
    if not lured and lure and FishMaster.db.char.autoLure then
        text = text .. "/use " .. GetSpellInfo(lure.spell) .. ";";
    else
        text = text .. "/cast " .. PROFESSIONS_FISHING;
    end

    if _FishMaster.isCasting then
        frame.icon:SetDesaturated(1);
    else
        frame.icon:SetDesaturated(nil);
    end

    frame:SetAttribute("type", "macro");
    frame:SetAttribute("macrotext", text);
    frame:SetAttribute("target-slot", INVSLOT_MAINHAND);
end
