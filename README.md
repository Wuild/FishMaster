# FishMaster — Forever

FishMaster supports World of Warcraft: Forever 1.60.1 (interface 16001) exclusively. It uses Forever's native character frame, panel tabs, controls, and character background. Other WoW clients are not supported.

## Screenshots

### Fishing outfit

Save your fishing gear, preview it on your character, and equip or restore it with one click.

![FishMaster Forever fishing outfit and character preview](docs/screenshots/fishing-outfit.png)

### Settings

Configure automatic pole selection, lures, easy casting, and fishing audio.

![FishMaster Forever fishing and audio settings](docs/screenshots/settings.png)

## Features

- **Fishing Outfit:** a rotating, zoomable character preview, equipment slots, current fishing skill, and native action buttons beneath the character. The preview shows your saved-piece count; gear slots use Forever’s native paper-doll frames and saved gear labels use item quality colors. Drop gear into a slot to save it; right click to clear it. Empty saved slots leave your worn gear alone.
- **Equip and restore:** switch to a saved fishing outfit and restore the previous equipment, including slots that were originally empty. Failed restoration keeps the snapshot so you can retry.
- **Fishing toolbar:** secure click buttons for casting and applying lures. Automatic lure selection respects skill requirements and the weakest/strongest preference.
- **Catch Log:** session and lifetime catches across all zones, with quantities and item tooltips. The floating tracker shows the current zone.
- **Settings:** minimap button, automatic pole selection, lures, optional double-right-click casting, tracker filters, and temporary fishing audio settings.
- **Cast / bobber key:** choose a keyboard shortcut under Settings → Bobber interaction. With a pole equipped, press it to cast, then press the same key at the splash to use native Interact. Auto lure applies a missing lure first; press again after it finishes to cast. The key stays on Interact while fishing or while the loot window is open, then returns to casting. Clear the key or put the pole away to restore normal bindings and the previous accessibility setting. Face the bobber; WoW's Auto Loot setting controls whether the catch is collected immediately.
- WoW manages the main window placement; toolbar and tracker positions are saved per character. Existing outfits, catches, and settings are retained in `FishMasterSettings`.

## Install

Install the published addon from [CurseForge](https://www.curseforge.com/wow/addons/fishmaster) into the Forever client's `Interface/AddOns` directory and run `/reload`. For local development, use this source checkout as the `FishMaster` addon folder; no ZIP is needed.

| Command | Action |
| --- | --- |
| `/fishmaster` or `/fmaster` | Equip or restore the fishing outfit |
| `/fishmaster config` | Open the character window |
| `/fishmaster loot` | Open the Catch Log |

Left click the minimap button to equip/restore; right click to open the window. Drag the character preview to rotate and use the mouse wheel to zoom. Drag a floating panel's header or empty space to move it. The floating toolbar and tracker have transparent, borderless backgrounds.

Equipment changes run one slot at a time and wait for inventory updates and item locks. The off-hand is stowed before a two-handed pole. Leave room in a general-purpose bag. If a change fails, the original outfit remains saved; use Restore before trying again. Repeated clicks during a swap do not overwrite it.

Fishing mode and enhanced audio follow the pole you actually have equipped, including manual weapon changes during combat. Removing the pole restores your sound settings; the next toggle equips the fishing outfit again. A failed swap keeps a separate recovery state so Restore can finish even after the pole is gone. If you equip a pole manually without a saved previous outfit, toggling off puts the pole in your bags.

Easy cast requires two quick right clicks in the world while idle and holding a pole. Camera drags, active casts, and open loot windows do not arm it. With Auto lure enabled, the first double click applies a missing lure; double click again once the lure finishes to cast.

## Development

The `master` branch targets WoW Forever only.

Application modules load explicitly from `FishMaster.toc`. `scripts/api.lua` contains client API access, `methods.lua` contains fishing and saved-data behavior, and the UI is built by `ui.lua`, `equipment.lua`, `toolbar.lua`, and `tracker.lua`. Only the Ace components used by the addon are loaded.

Run from the repository root with Lua 5.1:

```sh
lua5.1 tests/profession_info.lua
lua5.1 tests/acedb_region.lua
lua5.1 tests/ui_smoke.lua
lua5.1 tests/locales.lua
python -B tests/release.py
python -B tools/test_publish.py
python tools/package.py
```

`python tools/package.py` only validates the TOC/XML load graph and required files. Local checks do not generate ZIPs or upload build artifacts. GitHub Actions workflows have been removed; run these checks before publishing.

## Publishing

Publish locally with Python 3.9+ using `tools/publish.py`, following the same setup as GatherLite. Copy `.env.example` to `.env` and enter your CurseForge upload token. The file is ignored by Git. Settings default to FishMaster project `398695` and WoW Forever `1.60.1`; `CURSEFORGE_GAME_VERSION` accepts comma-separated supported game versions.

Run the development checks above, then preview or build without credentials or network access:

```sh
python tools/publish.py --version 2.0.0-forever --dry-run
python tools/publish.py --version 2.0.0-forever --package-only
```

Upload explicitly after reviewing the package:

```sh
python tools/publish.py --version 2.0.0-forever --changelog CHANGELOG.md
```

`--changelog` optionally supplies UTF-8 Markdown notes; otherwise the publisher generates a short release description. `--env-file` selects another configuration file. Packages and SHA-256 checksums are written to `dist/`. The package follows the TOC/XML load graph and includes runtime images, bundled libraries, README, and license; credentials and publishing tools are excluded.

The first public Forever release is `2.0.0-forever` (see [release notes](CHANGELOG.md)). Later versions can use `2.0.1` or `v2.0.1`. Normal versions and the plain `-forever` suffix publish as stable releases. Explicit `-alpha` or `-forever-alpha` versions publish as alpha; other prerelease versions, such as `-beta`, `-rc`, or `-forever-beta`, publish as beta. The version sets the ZIP name and is stamped into the packaged TOC without changing the source `@project-version@` placeholder. Tags and branch pushes do not publish anything. After uploading, check approval and Forever classification in the CurseForge author dashboard.

The UI smoke suite also runs the core regression suite. It checks startup, template types, tab selection, settings, drag/drop, secure attributes, mouse press/release binding lifetime, delayed inventory updates, locked and duplicate items, full bags, equipment restoration, bobber binding capture and cleanup, accessibility and audio restoration, lure selection, catch aggregation, duplicate loot events, and migration. It deliberately omits legacy item/spell globals.

API and template references:
- [Forever paper-doll slots, pinned to build 69913](https://github.com/Gethe/wow-ui-source/blob/70ef1b2fd78061a73f886c4a1e79dc5b5cff6d5e/Interface/AddOns/Blizzard_UIPanels_Game/Camelot/PaperDollFrame.xml) — use the Camelot files, not the Mainline files in the same branch.
- [Forever character frame](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_UIPanels_Game/Camelot/CharacterFrame.xml)
- [Forever paper-doll APIs](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_APIDocumentationGenerated/PaperDollInfoDocumentation.lua)
- [Forever secure action buttons](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_FrameXML/SecureTemplates.lua)
- [Forever equipment swapping](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_FrameXML/Mainline/EquipmentManager.lua)
- [Forever native interaction binding](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_FrameXML/Bindings_Camelot.xml)

## In-game validation

This is a development build. Automated checks use mocked client APIs; they cannot validate rendering, protected actions, or server inventory timing. Before release on Forever build 69913:

1. Open all three tabs; check the portrait, model, gear icons, tooltips, rotation, and zoom.
2. Drag gear from bags and worn slots, clear a slot, equip, and restore. Include a two-handed pole, off-hand weapon, duplicate rings, and full bags.
3. Cast, apply a lure, and try Auto lure and Easy cast. Confirm normal right-click behavior returns afterward.
4. Catch fish with auto-loot on and off. Check each catch is counted once; compare session, lifetime, zone, and trash filters.
5. Enter/leave combat with the panels open and confirm no blocked-action or taint errors.
6. Reload and relog to check saved outfits, window positions, historical catches, and audio restoration.
7. Set a cast / bobber key, use it to cast, and press it again at the splash. Check Auto lure, Auto Loot on/off, interrupted casts, no extra cast on key release after looting, Escape to cancel key capture, Clear, and restoration of the key's normal action and accessibility setting when putting the pole away.

All interface strings are provided in English, German, French, Spanish, Italian, Russian, and Simplified Chinese. Locale checks require complete coverage and matching formatting placeholders. Translations still benefit from native-speaker review in game.

Release tests inspect an in-memory archive without writing a ZIP. Catch tracking retries unresolved loot slots while the window is open and records each slot once. The Catch Log follows the trash filter. Outfit swap and recovery messages appear above the weapon row.

The character preview updates only when worn gear, saved gear, or resolved preview item links change. Routine status and bag updates preserve the model, rotation, and zoom.
