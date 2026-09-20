# Development

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

Before every upload, check the latest release version in the CurseForge author dashboard, including pending files. Confirm the intended version is not already uploaded; local Git tags are not sufficient. If the latest version cannot be verified, ask the owner before uploading. Never choose a version based only on the changelog or retry an uncertain upload without checking the dashboard.

Publish locally with Python 3.9+ using `tools/publish.py`, following the same setup as GatherLite. Copy `.env.example` to `.env` and enter your CurseForge upload token. The file is ignored by Git. Settings default to FishMaster project `398695` and WoW Forever `1.60.1`; `CURSEFORGE_GAME_VERSION` accepts comma-separated supported game versions.

Run the development checks above, then preview or build without credentials or network access:

```sh
python tools/publish.py --version 3.0.0 --dry-run
python tools/publish.py --version 3.0.0 --package-only
```

Upload explicitly after reviewing the package:

```sh
python tools/publish.py --version 3.0.0 --changelog CHANGELOG.md
```

`--changelog` optionally supplies UTF-8 Markdown notes; otherwise the publisher generates a short release description. `--env-file` selects another configuration file. Packages and SHA-256 checksums are written to `dist/`. The package follows the TOC/XML load graph and includes runtime images, bundled libraries, README, and license; credentials and publishing tools are excluded.

The first public Forever release is `3.0.0` (see [release notes](../CHANGELOG.md)). Later versions can use `3.0.1` or `v3.0.1`. Normal versions and the plain `-forever` suffix publish as stable releases. Explicit `-alpha` or `-forever-alpha` versions publish as alpha; other prerelease versions, such as `-beta`, `-rc`, or `-forever-beta`, publish as beta. The version sets the ZIP name and is stamped into the packaged TOC without changing the source `@project-version@` placeholder. Tags and branch pushes do not publish anything. After uploading, check approval and Forever classification in the CurseForge author dashboard.

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

## HUD action-button artwork

The HUD uses the native `UI-HUD-ActionBar-IconFrame` atlases and icon mask from Forever's [ActionButtonTemplate.xml](https://github.com/Gethe/wow-ui-source/blob/70ef1b2fd78061a73f886c4a1e79dc5b5cff6d5e/Interface/AddOns/Blizzard_ActionBar/Mainline/ActionButtonTemplate.xml). This Mainline-family template is loaded by Forever's [ActionBar manifest](https://github.com/Gethe/wow-ui-source/blob/70ef1b2fd78061a73f886c4a1e79dc5b5cff6d5e/Interface/AddOns/Blizzard_ActionBar/Blizzard_ActionBar.toc). The cast button is 45px; lures are 30px with proportionally scaled borders and masks. Only the artwork is reused: FishMaster retains its own secure spell/item attributes and click handlers.

HUD buttons have 2px gaps and flat dark idle edges. The native mouseover texture stays on the HIGHLIGHT layer so it only appears under the cursor.
