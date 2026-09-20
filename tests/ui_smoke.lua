-- A strict UI API mock checks wiring and startup; it does not render the game.
local ns = dofile("tests/core.lua")
local methods = {}
local function node(kind, name, parent)
    local value = setmetatable({ kind = kind, name = name, parent = parent, scripts = {},
        attributes = {}, shown = true, width = 100, height = 30, children = {} }, { __index = methods })
    if name then assert(not _G[name], "Duplicate frame " .. name); _G[name] = value end
    if parent then table.insert(parent.children, value) end
    return value
end
local noopMethods = { "SetJustifyH", "SetFontObject", "SetWordWrap", "SetTextColor", "SetAllPoints",
    "SetColorTexture", "SetAtlas", "SetTexCoord", "SetVertexColor", "SetDesaturated", "SetAlpha",
    "SetHitRectInsets", "SetClampedToScreen", "SetMovable", "SetToplevel", "EnableMouse", "EnableMouseWheel",
    "RegisterForDrag", "RegisterForClicks", "SetStatusBarTexture", "SetStatusBarColor",
    "SetFrameStrata", "StartMoving", "StopMovingOrSizing", "SetUnit", "Dress", "TryOn",
    "SetFacing", "SetPortraitZoom", "SetPortraitToAsset", "SetTitle", "SetMinMaxValues",
    "EnableKeyboard", "SetPropagateKeyboardInput" }
for _, key in ipairs(noopMethods) do methods[key] = function() end end
function methods:SetUnit(unit) self.unit = unit; self.modelLoads = (self.modelLoads or 0) + 1 end
function methods:Dress() self.dressCalls = (self.dressCalls or 0) + 1 end
function methods:SetFacing(value) self.facing = value end
function methods:SetPortraitZoom(value) self.portraitZoom = value end
function methods:SetSize(w, h) self.width, self.height = w, h end
function methods:SetWidth(w) self.width = w end
function methods:SetHeight(h) self.height = h end
function methods:GetHeight() return self.height end
function methods:GetWidth() return self.width end
function methods:SetPoint(...) table.insert(self.points or {}, { ... }); self.point = { ... } end
function methods:ClearAllPoints() self.point = nil end
function methods:GetPoint() return unpack(self.point) end
function methods:GetName() return self.name end
function methods:GetParent() return self.parent end
function methods:SetID(id) self.id = id end
function methods:GetID() return self.id end
function methods:SetText(text) self.text = tostring(text) end
function methods:GetText() return self.text end
function methods:GetStringHeight() return math.ceil(#(self.text or "") / 60) * 12 end
function methods:SetAtlas(atlas, useAtlasSize) self.atlas, self.useAtlasSize = atlas, useAtlasSize end
function methods:SetDrawLayer(layer) self.drawLayer = layer end
function methods:SetDesaturated(value) self.desaturated = value end
function methods:SetVertexColor(r, g, b) self.vertexColor = { r, g, b } end
function methods:SetTexture(value) self.texture = value end
function methods:CreateFontString(name) return node("FontString", name, self) end
function methods:CreateTexture(name, layer, template)
    if template then
        assert(template == "Char-LeftSlot" or template == "Char-RightSlot" or template == "Char-BottomSlot" or template == "Char-Slot-Bottom-Left" or template == "Char-Slot-Bottom-Right")
    end
    local texture = node("Texture", name, self)
    texture.template = template
    return texture
end
function methods:SetNormalTexture(path) self.normal = self:CreateTexture(); self.normal:SetTexture(path) end
function methods:GetNormalTexture() return self.normal end
function methods:CreateMaskTexture() return node("MaskTexture", nil, self) end
function methods:AddMaskTexture(mask) self.mask = mask end
function methods:SetAlpha(alpha) self.alpha = alpha end
function methods:SetNormalAtlas(atlas) self.normal = self:CreateTexture(); self.normal:SetAtlas(atlas) end
function methods:SetPushedAtlas(atlas) self.pushed = self:CreateTexture(); self.pushed:SetAtlas(atlas) end
function methods:SetHighlightAtlas(atlas) self.highlight = self:CreateTexture(); self.highlight:SetAtlas(atlas) end
function methods:GetPushedTexture() return self.pushed end
function methods:GetHighlightTexture() return self.highlight end
function methods:SetPushedTexture(path) self.pushed = path end
function methods:SetHighlightTexture(path) self.highlight = path end
function methods:EnableMouse(enabled) self.mouseEnabled = enabled end
function methods:EnableKeyboard(enabled) self.keyboardEnabled = enabled end
function methods:SetPropagateKeyboardInput(propagate) self.propagateKeyboard = propagate end
function methods:SetScript(event, fn)
    self.scripts[event] = fn
    -- Installing keyboard handlers can enable input: model this ordering hazard.
    if event == "OnKeyDown" and fn then self.keyboardEnabled = true end
end
function methods:HookScript(event, fn) self.scripts[event] = fn end
function methods:Show()
    local wasShown = self.shown
    self.shown = true
    if not wasShown and self.scripts.OnShow then self.scripts.OnShow(self) end
end
function methods:Hide() self.shown = false end
function methods:SetShown(value) if value then self:Show() else self:Hide() end end
function methods:IsShown() return self.shown end
function methods:IsVisible() return self.shown and (not self.parent or self.parent:IsVisible()) end
function methods:SetChecked(value) self.checked = value end
function methods:GetChecked() return self.checked end
function methods:SetEnabled(value) self.enabled = value end
function methods:SetAttribute(key, value) self.attributes[key] = value end
function methods:GetAttribute(key) return self.attributes[key] end
function methods:GetFrameLevel() return self.level or 1 end
function methods:SetFrameLevel(level) self.level = level end
function methods:SetValue(value) self.value = value end
function methods:SetBackdrop() assert(self.template == "BackdropTemplate") end
function methods:SetScrollChild(child) self.content = child end
function methods:GetVerticalScroll() return self.scroll or 0 end
function methods:SetVerticalScroll(value) self.scroll = value end
function methods:GetVerticalScrollRange() return math.max(0, self.content.height - self.height) end
function methods:Init(value) assert(self.kind == "Frame"); self.value = value end
function methods:RegisterCallback(event, fn, owner) self.callback = function(value) fn(owner, value) end end
local templates = {
    ButtonFrameTemplate = "Frame", PanelTabButtonTemplate = "Button", UIPanelButtonTemplate = "Button",
    CheckboxWithLabelTemplate = "CheckButton", MinimalSliderWithSteppersTemplate = "Frame",
    UIPanelScrollFrameTemplate = "ScrollFrame", SecureActionButtonTemplate = "Button", BackdropTemplate = "Frame",
}
function CreateFrame(kind, name, parent, template)
    if template then assert(templates[template] == kind, "Unknown/mismatched native template " .. template) end
    local frame = node(kind, name, parent)
    frame.template = template
    if template == "ButtonFrameTemplate" then
        frame.Inset = node("Frame", nil, frame)
        frame.CloseButton = node("Button", nil, frame)
    elseif template == "CheckboxWithLabelTemplate" then
        frame.Text = node("FontString", nil, frame)
    elseif template == "PanelTabButtonTemplate" then
        parent.Tabs = parent.Tabs or {}
        table.insert(parent.Tabs, frame)
    end
    return frame
end
UIParent = node("Frame")
WorldFrame = node("Frame")
UISpecialFrames = {}
local panelRegistrations, panelShows, panelHides = {}, 0, 0
function RegisterUIPanel(frame, attributes) panelRegistrations[frame] = attributes end
function ShowUIPanel(frame)
    assert(panelRegistrations[frame], "Window must be registered before opening")
    panelShows = panelShows + 1
    frame:Show()
end
function HideUIPanel(frame)
    assert(panelRegistrations[frame], "Window must be registered before closing")
    panelHides = panelHides + 1
    frame:Hide()
end
C_Texture = { GetAtlasInfo = function() return {} end }
ITEM_QUALITY_COLORS = { [0] = {r=.6,g=.6,b=.6}, [1] = {r=1,g=1,b=1} }
MinimalSliderWithSteppersMixin = { Label = { Right = 1 } }
ButtonFrameTemplate_HideButtonBar = function() end
PanelTemplates_TabResize = function() end
PanelTemplates_SetNumTabs = function(frame, n) assert(#frame.Tabs == n); frame.numTabs = n end
PanelTemplates_SetTab = function(frame, index) assert(frame.Tabs[index]); frame.selectedTab = index end
UnitName = function() return "Test Angler" end
GetCursorPosition = function() return 0, 0 end
C_PaperDollInfo.GetInventorySlotInfo = function(name)
    for _, slot in ipairs(ns.slots) do if slot.name == name then return slot.id, 123 end end
end
C_PaperDollInfo.IsInventorySlotEnabled = function(name) return name ~= "AmmoSlot" end
C_PaperDollInfo.CursorCanGoInSlot = function(slot) return slot == 1 end
C_Item.GetItemIconByID = function() return 123 end
GameTooltip = node("GameTooltip")
for _, key in ipairs({"SetOwner", "SetText", "SetItemByID", "SetHyperlink", "AddLine"}) do
    GameTooltip[key] = function() end
end
local minimap = { Register=function() end, Show=function() end, Hide=function() end }
local oldLib = LibStub
LibStub = function(library)
    if library == "AceDB-3.0" then return { New = function() return FishMaster.db end } end
    if library == "LibDBIcon-1.0" then return minimap end
    if library == "LibDataBroker-1.1" then return { NewDataObject = function(_, _, object) return object end } end
    return oldLib(library)
end
local eventHandlers, timers = {}, {}
function FishMaster:RegisterEvent(event, handler)
    if type(handler) == "string" then assert(type(self[handler]) == "function", handler) end
    eventHandlers[event] = handler
end
function FishMaster:RegisterBucketEvent(event, _, handler) self:RegisterEvent(event, handler) end
function FishMaster:RegisterChatCommand(_, handler) assert(self[handler]) end
function FishMaster:IsHooked() return false end
function FishMaster:SecureHookScript() end
function FishMaster:ScheduleRepeatingTimer(callback) table.insert(timers, callback); return #timers end
function FishMaster:ScheduleTimer(callback) table.insert(timers, callback); return #timers end
for _, key in ipairs({"CancelAllTimers", "UnregisterAllEvents", "UnregisterAllBuckets", "UnhookAll"}) do
    FishMaster[key] = function() end
end
local overrides = {}
ClearOverrideBindings = function(owner) assert(owner); overrides[owner] = nil end
local bindings = 0
SetOverrideBindingClick = function(owner, _, key, name, button)
    bindings = bindings + 1
    overrides[owner] = { key = key, target = _G[name], button = button }
end
SetOverrideBinding = function(owner, _, key, action) overrides[owner] = { key = key, action = action } end
GetBindingText = function(key) return key end
IsShiftKeyDown = function() return false end
IsControlKeyDown = function() return false end
IsAltKeyDown = function() return false end

for _, file in ipairs({"methods", "ui", "equipment/ItemSlot", "equipment", "tracker", "toolbar", "interaction", "main"}) do
    assert(loadfile("scripts/" .. file .. ".lua"))("FishMaster", ns)
end
FishMaster:OnInitialize()
FishMaster:OnEnable()
FishMaster:GatherSlash("config")
assert(FishMaster.equipment.frame:IsShown())
assert(panelRegistrations[FishMaster.equipment.frame].area == "left")
assert(panelShows == 1)
FishMaster.equipment.frame.CloseButton.scripts.OnClick()
assert(not FishMaster.equipment.frame:IsShown() and panelHides == 1)
FishMaster.equipment:Toggle()
assert(FishMaster.equipment.frame:IsShown() and panelShows == 2)
assert(FishMaster.equipment.frame:GetWidth() == 540)
assert(FishMaster.equipment.frame.mouseEnabled == true)
assert(not FishMaster.equipment.frame.keyboardEnabled)
assert(FishMaster.equipment.slots.MainHandSlot and not FishMaster.equipment.slots.AmmoSlot)
-- Camelot gear-slot atlases must not regress to the Mainline Char-* textures.
for _, button in pairs(FishMaster.equipment.slots) do
    assert(button.icon.drawLayer == "BORDER")
    assert(button.slotFrame.atlas == "UI-Character-Info-GearSlot" and button.slotFrame.useAtlasSize)
    local normal = button:GetNormalTexture()
    assert(normal and normal:GetWidth() == 64 and normal:GetHeight() == 64)
    assert(normal.texture == "Interface\\Buttons\\UI-Quickslot2")
    assert(normal.point[1] == "CENTER" and normal.point[3] == -1)
end
-- HUD visuals must use Forever's actionbar atlases without changing secure actions.
local cast = FishMaster.toolbar.cast
assert(cast:GetWidth() == 45 and cast.template == "SecureActionButtonTemplate")
local actionButtons = { cast }
local previousAction = cast
for _, button in ipairs(FishMaster.toolbar.lures) do
    assert(button:GetWidth() == 30 and button:GetWidth() < cast:GetWidth())
    assert(button.point[2] == previousAction and button.point[4] == 2)
    previousAction = button
    assert(button.template == "SecureActionButtonTemplate")
    assert(button.alpha == nil, "Unavailable lures must not fade their actionbar frames")
    table.insert(actionButtons, button)
end
for _, button in ipairs(actionButtons) do
    assert(button:GetNormalTexture().atlas == "UI-HUD-ActionBar-IconFrame")
    assert(button:GetPushedTexture().atlas == "UI-HUD-ActionBar-IconFrame-Down")
    assert(button:GetHighlightTexture().atlas == "UI-HUD-ActionBar-IconFrame-Mouseover")
    assert(button:GetHighlightTexture().drawLayer == "HIGHLIGHT", "Hover artwork must not render as a permanent overlay")
    assert(button:GetNormalTexture().drawLayer == "OVERLAY")
    assert(button:GetNormalTexture().alpha == 0)
    assert(button.slotArt.alpha == 0)
    assert(not button:GetHighlightTexture().desaturated)
    assert(button.slotArt.desaturated == true)
    assert(button.icon.mask == button.iconMask)
    assert(button.iconMask.atlas == "UI-HUD-ActionBar-IconFrame-Mask")
    assert(button.iconMask:GetWidth() == button:GetWidth() * 1.5)
end
for index = 1, 3 do
    FishMaster.equipment:SelectTab(index)
    assert(FishMaster.equipment.frame:GetWidth() == 540)
    for key, page in ipairs(FishMaster.equipment.frame.pages) do assert(page:IsShown() == (index == key)) end
end
-- Settings overflow inside their scroll frame, with controls on its content.
local settingsScroll = FishMaster.equipment.settingsScroll
assert(settingsScroll.content:GetHeight() > 1100)
for _, entry in ipairs(FishMaster.equipment.checks) do
    assert(entry.description and #entry.description:GetText() > 30)
end
assert(FishMaster.equipment.bobberKey:GetParent() == settingsScroll.content)
settingsScroll:SetHeight(480)
settingsScroll.scripts.OnMouseWheel(settingsScroll, -100)
assert(settingsScroll:GetVerticalScroll() == settingsScroll.content:GetHeight() - 480)
settingsScroll.scripts.OnMouseWheel(settingsScroll, 100)
assert(settingsScroll:GetVerticalScroll() == 0)
local ammoPreview = FishMaster.ItemSlot:Create(UIParent, { id = 0, name = "AmmoSlot", side = "bottom" })
assert(ammoPreview.slotFrame.atlas == "UI-Character-Info-GearSlotSmall" and ammoPreview.slotFrame.useAtlasSize)
ammoPreview:Hide()

-- Unrelated refreshes must not reload the model or interrupt its view.
FishMaster.equipment:SelectTab(1)
local preview = FishMaster.equipment.model
preview.rotation, preview.zoom = .7, .4
preview:SetFacing(.7)
preview:SetPortraitZoom(.4)
local loads, dresses = preview.modelLoads, preview.dressCalls
for _ = 1, 5 do FishMaster:Refresh() end
assert(preview.modelLoads == loads and preview.dressCalls == dresses)
assert(preview.facing == .7 and preview.portraitZoom == .4)
local previousHat = FishMaster.db.char.outfit.HeadSlot
FishMaster.db.char.outfit.HeadSlot = 777
FishMaster.equipment:Refresh()
assert(preview.modelLoads == loads + 1)
assert(preview.facing == .7 and preview.portraitZoom == .4)
FishMaster.equipment:Refresh()
assert(preview.modelLoads == loads + 1)
FishMaster.db.char.outfit.HeadSlot = previousHat
FishMaster.equipment:Refresh()
local currentInventory = GetInventoryItemID
local baseline = preview.modelLoads
GetInventoryItemID = function(unit, slot) if slot == 1 then return 888 end; return currentInventory(unit, slot) end
FishMaster.equipment:Refresh()
assert(preview.modelLoads == baseline + 1)
FishMaster.equipment:Refresh()
assert(preview.modelLoads == baseline + 1)
GetInventoryItemID = currentInventory
FishMaster.equipment:Refresh()

-- Saved items can exist before the client has cached their display data.
FishMaster.equipment:SelectTab(1)
local savedPole = FishMaster.db.char.outfit.MainHandSlot
local itemInfo = ns.API.ItemInfo
FishMaster.db.char.outfit.MainHandSlot = 999999
ns.API.ItemInfo = function() return nil end
FishMaster.equipment:Refresh()
local unresolvedLoads = preview.modelLoads
FishMaster.equipment:Refresh()
assert(preview.modelLoads == unresolvedLoads)
ns.API.ItemInfo = itemInfo
FishMaster.equipment:Refresh()
assert(preview.modelLoads == unresolvedLoads + 1)
FishMaster.equipment:Refresh()
assert(preview.modelLoads == unresolvedLoads + 1)
FishMaster.db.char.outfit.MainHandSlot = savedPole
local oldSession = ns.session
ns.session = { { item = "Fish", itemID = 1, quantity = 2, quality = 1 },
    { item = "Trash", itemID = 2, quantity = 3, quality = 0 } }
for _, hideTrash in ipairs({ true, false }) do
    FishMaster.db.char.tracker.hideTrash = hideTrash
    local expected = hideTrash and 2 or 5
    FishMaster.equipment.logSession = true
    FishMaster.equipment:SelectTab(3)
    assert(FishMaster.equipment.logTotal:GetText() == FishMaster:translate("log.total", expected))
end
ns.session = oldSession
FishMaster.db.char.tracker.hideTrash = true
ns.lootRecorded, ns.lootPending = { [1] = true }, true
eventHandlers.LOOT_CLOSED()
assert(not ns.lootRecorded and not ns.lootPending)

FishMaster.equipment.volume.callback(35)
assert(FishMaster.db.char.audio.volume == .35)
local check = FishMaster.equipment.checks[1]
check.control:SetChecked(false)
check.control.scripts.OnClick(check.control)
assert(FishMaster.db.profile.minimap.hide == true)
FishMaster:GatherSlash("  LOOT  ")
assert(FishMaster.equipment.frame.selectedTab == 3)

-- Drop a cursor item using Forever's namespaced cursor API (no old global).
GetCursorInfo = function() return "item", 222 end
ClearCursor = function() end
FishMaster.ItemSlot:Receive(FishMaster.equipment.slots.HeadSlot)
assert(FishMaster.db.char.outfit.HeadSlot == 222)
GetCursorInfo = function() return "item", 333 end
FishMaster.ItemSlot:Receive(FishMaster.equipment.slots.FeetSlot)
assert(FishMaster.db.char.outfit.FeetSlot ~= 333)

-- Force a pole for secure-button wiring; no spell is executed by the mock.
local oldInventory = GetInventoryItemID
GetInventoryItemID = function(unit, slot) if slot == 16 then return 6256 end; return oldInventory(unit, slot) end
local function equipmentChanged()
    local handler = eventHandlers.PLAYER_EQUIPMENT_CHANGED
    assert(type(handler) == "string")
    FishMaster[handler](FishMaster, "PLAYER_EQUIPMENT_CHANGED", 16)
end
local originalVolume = C_CVar.GetCVar("Sound_MasterVolume")
FishMaster.db.char.audio.enabled = true
equipmentChanged()
assert(FishMaster.db.char.enabled and C_CVar.GetCVar("Sound_MasterVolume") == "0.35")
assert(FishMaster.toolbar.frame:IsShown())
assert(FishMaster.toolbar.cast:GetAttribute("type1") == "item")
for _, button in ipairs(FishMaster.toolbar.lures) do
    assert(button.alpha == nil, "Lure borders must remain visible when unavailable")
    local usable = ns.API.ItemCount(button.lure.item) > 0
        and FishMaster:GetProfessionLevel(ns.API.FishingName()) >= button.lure.skill
    assert(button.icon.alpha == (usable and 1 or .4))
end
assert(FishMaster.toolbar.cast:GetAttribute("target-slot1") == 16)
C_PaperDollInfo.GetTemporaryEnchantmentInfo = function() return { remainingTimeMs = 60000 } end
FishMaster.toolbar:Refresh()
assert(FishMaster.toolbar.cast:GetAttribute("type1") == "spell")
assert(FishMaster.toolbar.cast:GetAttribute("target-slot1") == nil)
local time = 10
GetTime = function() return time end
local mouselooking, cameraStops = false, 0
IsMouselooking = function() return mouselooking end
MouselookStop = function() mouselooking = false; cameraStops = cameraStops + 1 end
FishMaster.db.char.easyCast = true
mouselooking = true
FishMaster.toolbar:OnWorldMouseDown(WorldFrame, "RightButton")
assert(bindings == 0 and mouselooking)
FishMaster.toolbar:OnWorldMouseUp(WorldFrame, "RightButton")
assert(bindings == 1 and not mouselooking and cameraStops == 1)
time = 10.2
-- The second physical press must already have a route. The binding must survive
-- the down phase and its timeout, so the native up action can run exactly once.
local route = overrides[FishMaster.toolbar.cast]
assert(route.key == "BUTTON2" and route.target == FishMaster.toolbar.cast)
mouselooking = true
route.target.scripts.PreClick(route.target, route.button, true)
assert(not mouselooking and cameraStops == 2)
route.target.scripts.PostClick(route.target, route.button, true)
time = 10.7
FishMaster.toolbar:Tick()
assert(overrides[FishMaster.toolbar.cast] == route)
assert(route.target:GetAttribute("type1") == "spell" and route.target:GetAttribute("useOnKeyDown") == false)
mouselooking = true
route.target.scripts.PreClick(route.target, route.button, false)
assert(not mouselooking and cameraStops == 3)
route.target.scripts.PostClick(route.target, route.button, false)
assert(overrides[FishMaster.toolbar.cast] == nil and not mouselooking)
time = 11
FishMaster.toolbar:OnWorldMouseDown(WorldFrame, "RightButton")
FishMaster.toolbar:OnWorldMouseUp(WorldFrame, "RightButton")
time = 11.5
FishMaster.toolbar:Tick()
assert(FishMaster.toolbar.overrideUntil == nil)
-- Holding the camera button must not arm a second click.
mouselooking = true
local stopsBeforeDrag = cameraStops
FishMaster.toolbar:OnWorldMouseDown(WorldFrame, "RightButton")
time = 12
FishMaster.toolbar:OnWorldMouseUp(WorldFrame, "RightButton")
assert(FishMaster.toolbar.overrideUntil == nil and cameraStops == stopsBeforeDrag and mouselooking)
mouselooking = false -- the normal world release ends the drag
-- Cancelling a second click also releases camera control, even without PostClick.
time = 13
FishMaster.toolbar:OnWorldMouseDown(WorldFrame, "RightButton")
FishMaster.toolbar:OnWorldMouseUp(WorldFrame, "RightButton")
FishMaster.toolbar.cast.scripts.PreClick(FishMaster.toolbar.cast, "LeftButton", true)
mouselooking = true
FishMaster.toolbar:ClearOverride()
assert(not mouselooking and overrides[FishMaster.toolbar.cast] == nil)
-- Clicking the toolbar normally must not take over unrelated camera control.
mouselooking = true
local stopsBeforeToolbar = cameraStops
FishMaster.toolbar.cast.scripts.PreClick(FishMaster.toolbar.cast, "LeftButton", true)
FishMaster.toolbar.cast.scripts.PostClick(FishMaster.toolbar.cast, "LeftButton", true)
FishMaster.toolbar.cast.scripts.PreClick(FishMaster.toolbar.cast, "LeftButton", false)
FishMaster.toolbar.cast.scripts.PostClick(FishMaster.toolbar.cast, "LeftButton", false)
assert(mouselooking and cameraStops == stopsBeforeToolbar)
mouselooking = false

C_CVar.SetCVar("softTargetInteract", "1")
local keyButton = FishMaster.equipment.bobberKey
assert(not keyButton.keyboardEnabled and keyButton.propagateKeyboard and not keyButton.scripts.OnKeyDown)
FishMaster.equipment:SelectTab(2)
assert(not keyButton.keyboardEnabled and not keyButton.scripts.OnKeyDown)
keyButton.scripts.OnClick(keyButton)
assert(keyButton.keyboardEnabled and not keyButton.propagateKeyboard)
assert(keyButton.listening)
keyButton.scripts.OnKeyDown(keyButton, "F8")
assert(FishMaster.db.char.bobberKey == "F8" and not keyButton.listening)
assert(not keyButton.keyboardEnabled and keyButton.propagateKeyboard and not keyButton.scripts.OnKeyDown)
local interaction = FishMaster.interaction
assert(overrides[interaction.owner].target == interaction.owner)
assert(interaction.owner:GetAttribute("type") == "spell")
assert(interaction.owner:GetAttribute("spell") == "Fishing")
assert(interaction.owner:GetAttribute("useOnKeyDown") == true)
assert(C_CVar.GetCVar("softTargetInteract") == "3")
local channel, casting
UnitChannelInfo = function() return channel end
UnitCastingInfo = function() return casting end
local function spellEvent(event, spellID, unit)
    local handler = eventHandlers[event]
    FishMaster[handler](FishMaster, event, unit or "player", "test-cast", spellID or 7620)
end
channel = "Fishing"
spellEvent("UNIT_SPELLCAST_CHANNEL_START")
assert(overrides[interaction.owner].action == "INTERACTTARGET")
-- Ending the channel while manual loot is open must not bind a new cast yet.
LootFrame = node("Frame")
channel = nil
spellEvent("UNIT_SPELLCAST_CHANNEL_STOP")
assert(overrides[interaction.owner].action == "INTERACTTARGET")
LootFrame:Hide()
eventHandlers.LOOT_CLOSED()
assert(overrides[interaction.owner].target == interaction.owner)
-- The newly installed cast action is key-down only. The release belonging to
-- the preceding Interact press must do nothing, including no refresh timer.
local timerCount = #timers
interaction.owner.scripts.PostClick(interaction.owner, "LeftButton", false)
assert(#timers == timerCount and interaction.owner:GetAttribute("useOnKeyDown"))
casting = "Fishing"
spellEvent("UNIT_SPELLCAST_START")
assert(overrides[interaction.owner].action == "INTERACTTARGET")
casting = nil
spellEvent("UNIT_SPELLCAST_INTERRUPTED")
assert(overrides[interaction.owner].target == interaction.owner)
-- Other spells must not turn the key into an interaction binding.
casting = "Other spell"
spellEvent("UNIT_SPELLCAST_START", 999)
assert(overrides[interaction.owner].target == interaction.owner)
casting = nil
spellEvent("UNIT_SPELLCAST_STOP", 999)
C_PaperDollInfo.GetTemporaryEnchantmentInfo = function() return nil end
FishMaster:Refresh()
assert(interaction.owner:GetAttribute("type") == "item")
assert(interaction.owner:GetAttribute("target-slot") == 16)
C_PaperDollInfo.GetTemporaryEnchantmentInfo = function() return { remainingTimeMs = 60000 } end
FishMaster:Refresh()
assert(interaction.owner:GetAttribute("type") == "spell" and interaction.owner:GetAttribute("item") == nil)
assert(interaction.owner:GetAttribute("target-slot") == nil)
-- A late client channel update is also reconciled by the existing timer.
channel = "Fishing"
timers[FishMaster.tick]()
assert(overrides[interaction.owner].action == "INTERACTTARGET")
channel = nil
timers[FishMaster.tick]()
assert(overrides[interaction.owner].target == interaction.owner)
keyButton.scripts.OnClick(keyButton)
assert(overrides[interaction.owner] == nil)
keyButton.scripts.OnKeyDown(keyButton, "ESCAPE")
assert(FishMaster.db.char.bobberKey == "F8" and overrides[interaction.owner])
assert(not keyButton.keyboardEnabled and keyButton.propagateKeyboard and not keyButton.scripts.OnKeyDown)
keyButton.scripts.OnClick(keyButton)
keyButton.scripts.OnHide(keyButton)
assert(not keyButton.listening and not keyButton.keyboardEnabled and keyButton.propagateKeyboard)
assert(not keyButton.scripts.OnKeyDown and not interaction.suspended)
assert(FishMaster.db.char.bobberKey == "F8" and overrides[interaction.owner])
GetInventoryItemID = oldInventory
equipmentChanged()
assert(not FishMaster.db.char.enabled and C_CVar.GetCVar("Sound_MasterVolume") == originalVolume)
assert(overrides[interaction.owner] == nil and C_CVar.GetCVar("softTargetInteract") == "1")
GetInventoryItemID = function(unit, slot) if slot == 16 then return 6256 end; return oldInventory(unit, slot) end
FishMaster:Refresh()
assert(overrides[interaction.owner])
C_CVar.SetCVar("softTargetInteract", "0")
interaction:SetKey(nil)
assert(C_CVar.GetCVar("softTargetInteract") == "0" and overrides[interaction.owner] == nil)
interaction:SetKey("F8")

for _, callback in ipairs(timers) do callback() end
FishMaster:OnDisable()
assert(not FishMaster.equipment.frame:IsShown())
assert(overrides[interaction.owner] == nil and C_CVar.GetCVar("softTargetInteract") == "0")
print("UI startup, native template types, tabs, settings, drag/drop, secure attributes, and easy-cast checks passed")
