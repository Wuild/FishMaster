local name, _FishMaster = ...;
local L = LibStub("AceLocale-3.0"):NewLocale(_FishMaster.name, "deDE")
if not L then
    return
end
L["fishing"] = "Angeln"
L["fishing.bobber"] = "Schwimmer"

L["minimap.left_click"] = "Linksklick"
L["minimap.left_click_text"] = "wechsel Ausrüstung"
L["minimap.right_click"] = "Rechstklick"
L["minimap.right_click_text"] = "Einstellungen öffnen"

L["button.left_click_text"] = "Angel auswerfen"
L["button.right_click_text"] = "Automatisch ködern"

L["settings.autoLure"] = "Automatisch ködern"
L["settings.lowestLure"] = "geringster zuerst"
L["settings.autoGear"] = "Automatisch beste Ausrüstung"
L["settings.tracker.show"] = "zeige Tracker"
L["settings.tracker.session"] = "Nur aktuele Sitzung anzeigen"
L["settings.tracker.trash"] = "Verstecke Müll"
L["settings.sound.enhance"] = "Angelgeräusch verbessern"
L["settings.sound.force"] = "Ton erzwingen"
L["settings.sound.volume"] = "Lautstärke - %s%%"

L["mode.session"] = "Diese Sitzung: %s"
L["mode.lifetime"] = "Gesammt: %s"
