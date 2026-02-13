local CallbackHandler = LibStub("CallbackHandler-1.0")

local MAJOR, MINOR = "FishEvents-1.0", 1
local FishEvents = LibStub:NewLibrary(MAJOR, MINOR)

if not FishEvents then
    return
end

FishEvents.embeds = FishEvents.embeds or {}

if not FishEvents.events then
    FishEvents.events = CallbackHandler:New(FishEvents, "On", "Off", "OffAll")
    function FishEvents:Trigger(event, ...)
        FishEvents.events:Fire(event, ...)
        if self.SendMessage then
            self:SendMessage(event, ...)
        end
    end
end

local mixins = { "On", "Off", "OffAll", "Trigger" }

function FishEvents:Embed(target)
    for k, v in pairs(mixins) do
        target[v] = self[v]
    end
    self.embeds[target] = true
    return target
end

function FishEvents:OnEmbedDisable(target)
    target:OffAll()
end

for target, v in pairs(FishEvents.embeds) do
    FishEvents:Embed(target)
end
