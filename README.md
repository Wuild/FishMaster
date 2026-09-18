# FishMaster — Forever

The `forever` branch rewrites FishMaster for World of Warcraft: Forever 1.60.1 (interface 16001). It uses the native Retail-style character frame, panel tabs, controls, and character background provided by Forever. The original Classic implementation remains on `master`.

## Features

- **Fishing Outfit:** a rotating, zoomable character preview, equipment slots, current fishing skill, and an outfit summary. Drop gear into a slot to save it; right click to clear it. Empty saved slots leave your worn gear alone.
- **Equip and restore:** switch to a saved fishing outfit and restore the previous equipment, including slots that were originally empty. Failed restoration keeps the snapshot so you can retry.
- **Fishing toolbar:** secure click buttons for casting and applying lures. Automatic lure selection respects skill requirements and the weakest/strongest preference.
- **Catch Log:** session and lifetime catches across all zones, with quantities and item tooltips. The floating tracker shows the current zone.
- **Settings:** minimap button, automatic pole selection, lures, optional double-right-click casting, tracker filters, and temporary fishing audio settings.
- Window, toolbar, and tracker positions are saved per character. Existing outfits, catches, and settings are retained in `FishMasterSettings`.

## Install

Build with `python tools/package.py`, or use the generated `dist/FishMaster-2.0.0-forever.1.zip`. Extract its `FishMaster` folder into the Forever client's `Interface/AddOns` directory and run `/reload`.

| Command | Action |
| --- | --- |
| `/fishmaster` or `/fmaster` | Equip or restore the fishing outfit |
| `/fishmaster config` | Open the character window |
| `/fishmaster loot` | Open the Catch Log |

Left click the minimap button to equip/restore; right click to open the window. Drag the character preview to rotate and use the mouse wheel to zoom. Drag a floating panel's background to move it.

## Development

Application modules load explicitly from `FishMaster.toc`; the former Classic XML templates are removed. `scripts/api.lua` contains client API access, `methods.lua` contains fishing and saved-data behavior, and the UI is built by `ui.lua`, `equipment.lua`, `toolbar.lua`, and `tracker.lua`. Only the Ace components used by the addon are loaded.

Run from the repository root with Lua 5.1:

```sh
lua5.1 tests/profession_info.lua
lua5.1 tests/ui_smoke.lua
python tools/package.py
```

The UI smoke suite also runs the core regression suite. It checks startup, template types, tab selection, settings, drag/drop, secure attributes, double-click timing, equipment restoration, audio restoration, lure selection, catch aggregation, duplicate loot events, and migration. It deliberately omits legacy item/spell globals.

API and template references:
- [Forever character frame](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_UIPanels_Game/Mainline/CharacterFrame.xml)
- [Forever paper-doll APIs](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_APIDocumentationGenerated/PaperDollInfoDocumentation.lua)
- [Forever secure action buttons](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_FrameXML/SecureTemplates.lua)

## In-game validation

This is a development build. Automated checks use mocked client APIs; they cannot validate rendering, protected actions, or server inventory timing. Before release on Forever build 69913:

1. Open all three tabs; check the portrait, model, gear icons, tooltips, rotation, and zoom.
2. Drag gear from bags and worn slots, clear a slot, equip, and restore. Include a two-handed pole, off-hand weapon, duplicate rings, and full bags.
3. Cast, apply a lure, and try Auto lure and Easy cast. Confirm normal right-click behavior returns afterward.
4. Catch fish with auto-loot on and off. Check each catch is counted once; compare session, lifetime, zone, and trash filters.
5. Enter/leave combat with the panels open and confirm no blocked-action or taint errors.
6. Reload and relog to check saved outfits, window positions, historical catches, and audio restoration.

Existing translations are retained. New interface text currently falls back to English.
