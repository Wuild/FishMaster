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
    "SetClampedToScreen", "SetMovable", "SetToplevel", "EnableMouse", "EnableMouseWheel",
    "RegisterForDrag", "RegisterForClicks", "SetStatusBarTexture", "SetStatusBarColor",
    "SetFrameStrata", "StartMoving", "StopMovingOrSizing", "SetUnit", "Dress", "TryOn",
    "SetFacing", "SetPortraitZoom", "SetPortraitToAsset", "SetTitle", "SetMinMaxValues" }
for _, key in ipairs(noopMethods) do methods[key] = function() end end
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
function methods:SetTexture(value) self.texture = value end
function methods:CreateFontString(name) return node("FontString", name, self) end
function methods:CreateTexture(name) return node("Texture", name, self) end
function methods:SetNormalTexture(path) self.normal = self:CreateTexture(); self.normal:SetTexture(path) end
function methods:GetNormalTexture() return self.normal end
function methods:SetPushedTexture(path) self.pushed = path end
function methods:SetHighlightTexture(path) self.highlight = path end
function methods:SetScript(event, fn) self.scripts[event] = fn end
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
ClearOverrideBindings = function() end
local bindings = 0
SetOverrideBindingClick = function() bindings = bindings + 1 end

for _, file in ipairs({"methods", "ui", "equipment/ItemSlot", "equipment", "tracker", "toolbar", "main"}) do
    assert(loadfile("scripts/" .. file .. ".lua"))("FishMaster", ns)
end
FishMaster:OnInitialize()
FishMaster:OnEnable()
FishMaster:GatherSlash("config")
assert(FishMaster.equipment.frame:IsShown())
assert(FishMaster.equipment.frame:GetWidth() == 800)
assert(FishMaster.equipment.slots.MainHandSlot and not FishMaster.equipment.slots.AmmoSlot)
for index = 1, 3 do
    FishMaster.equipment:SelectTab(index)
    for key, page in ipairs(FishMaster.equipment.frame.pages) do assert(page:IsShown() == (index == key)) end
end
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
FishMaster:Refresh()
assert(FishMaster.toolbar.frame:IsShown())
assert(FishMaster.toolbar.cast:GetAttribute("type1") == "item")
assert(FishMaster.toolbar.cast:GetAttribute("target-slot1") == 16)
C_PaperDollInfo.GetTemporaryEnchantmentInfo = function() return { remainingTimeMs = 60000 } end
FishMaster.toolbar:Refresh()
assert(FishMaster.toolbar.cast:GetAttribute("type1") == "spell")
assert(FishMaster.toolbar.cast:GetAttribute("target-slot1") == nil)
local time = 10
GetTime = function() return time end
FishMaster.db.char.easyCast = true
FishMaster.toolbar:OnWorldMouseDown(WorldFrame, "RightButton")
assert(bindings == 0)
time = 10.2
FishMaster.toolbar:OnWorldMouseDown(WorldFrame, "RightButton")
assert(bindings == 1)
time = 11
FishMaster.toolbar:Tick()
assert(FishMaster.toolbar.overrideUntil == nil)

for _, callback in ipairs(timers) do callback() end
FishMaster:OnDisable()
assert(not FishMaster.equipment.frame:IsShown())
print("UI startup, native template types, tabs, settings, drag/drop, secure attributes, and easy-cast checks passed")
