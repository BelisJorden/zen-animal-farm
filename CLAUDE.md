# Zen Farm — CLAUDE.md
> Godot 4 context file voor Claude Code. Altijd up-to-date houden na grote beslissingen.

---

## Project overview
- **Naam:** Zen Farm — *a quiet little world*
- **Genre:** Cozy idle / farm builder
- **Engine:** Godot 4, GDScript (geen C#)
- **Target:** Android & iOS, portrait mode (9:16)
- **Renderer:** Forward+
- **Visuele stijl:** Voxel art, isometrische camera (45°), warme pastelkleuren (lila, zacht oranje, groen)

---

## Schermen & scenes (uit wireframes)

### 1. MainMenu (`scenes/ui/MainMenu.tscn`)
- Groot Zen Farm logo (lila, bold)
- Tagline: "a quiet little world"
- Centraal: één voxel dier op een groen eiland met sparkle particles
- Knoppen: `begin` (primair, lila), `settings`, `credits` (secundair, wit)
- Achtergrond: gradient lila → zacht oranje (gebruik WorldEnvironment)

### 2. Farm / HUD (`scenes/ui/HUD.tscn`)
- **Rechts boven:** Coin-teller (◎ goud icoon + aantal) + coins/sec indicator eronder ("1.2/sec", gedimde witte tekst) — VBoxContainer, anchor right, 16px marge van rand. Geen avatar/naam/level/dag meer.
- **Midden links:** Floating notificatie "+3 ✦ ready" (spirit shards klaar)
- **Onderin:** Quest/task balk — "collect 3 spirit shards · 2/3" met progress bar
- **Bottom nav (5 tabs):**
  - `farm` — hoofdscherm, isometrisch grid
  - `build` — plaatsingsmodus
  - `egg` — hatchery (actief = lila highlight)
  - `shop` — shop overlay (was: `care`)
  - `more` — instellingen, extras (More.tscn met reset progress)
- **BottomNav altijd zichtbaar** — ook tijdens placing mode. PlacingUI BottomPanel eindigt op `offset_bottom=-125` zodat het boven de nav staat.

### 3. Farm grid (`scenes/world/Farm.tscn`)
- Isometrisch 3D grid, voxel-stijl grastiles (FarmGrid.obj uit MagicaVoxel)
- **FarmIsland:** decoratief zwevend eiland (`FarmIslandBig.glb`) geladen via `farm.gd _ready()`, `move_child(island, 0)` zodat het achter grid en dieren valt. Positie: x=0.1, y=-4.0, scale=1.0
- Dieren worden gespawnd als Node3D op AnimalLayer
- Camera: orthogonal, 45° rotatie, vaste hoogte
- Touch: tap op tile → plaatst dier (in placing mode); drag → pan camera

### 4. Plaatsingsmodus (`scenes/ui/PlacingUI.tscn`)
- Header: "placing · [diernaam]" + cancel knop (rood ×)
- Onderin: horizontale scroll — "your animals · N unplaced" + filter knop
- Dier-cards: afbeelding preview (TextureRect als `image_path` ingesteld, anders kleurblok) + naam + count, geselecteerde heeft lila border
- Tap op vrije tile → dier gespawnd; tap op bezette tile → rode puls feedback

### 5. Hatchery (`scenes/ui/Hatchery.tscn`)
- Header: "hatchery" + back knop links + spirit shard teller rechts ("✦ N" goudgeel, ShardCounter node)
- Centraal: voxel ei model (groot, shaking animatie per tap)
- Tekst: "almost there..." / "one more tap!" / "it hatched!"
- Progress: 5 dots (●●●○○ stijl), vult per tap
- Rarity selector: `common` / `rare` / `mystic` — bepaalt minimale rarity van roll + shardkosten
- Primaire knop: "tap to crack ✦ N" (N = kosten op basis van geselecteerde rarity)
- Kosten: common ✦3, rare ✦8, mystic ✦20 — afgetrokken bij eerste tap
- Achtergrond: lila → zacht roze gradient

### 6. Shop (`scenes/ui/Shop.tscn`)
- Header: "shop" + back + coin teller
- Category tabs: `decor` (actief, zwart pill) / `tiles` / `animals` / `seeds` / `bundles`
- **Featured banner:** "WEEKLY MYSTERY — shrine bundle" (lila card, grote afbeelding, prijs knop)
- **Grid:** 3 kolommen, items met preview + naam + prijs
  - Animal-cards: afbeelding (TextureRect op lichte achtergrond als `image_path` ingesteld, anders kleurblok)
  - Coin-prijs: ◎ icoon + getal
  - Gem-prijs: ✦ icoon + getal (lila)
  - Gekochte items: lila border highlight
- Items (decor): fox lantern, koi tile, mossy rock, sakura tree, paper crane, shrine gate

---

## Game mechanics

### Core loop
```
Dieren op farm → genereren coins (passief via Timer) →
coins gebruiken voor: nieuwe dieren / decor / upgrades →
farm groeit → nieuwe farms ontgrendelen
```

### Valuta
- **Coins (◎):** standaard valuta, gegenereerd door dieren via Timer in node
- **Spirit shards (✦):** premium / zeldzame valuta, via quests/minigames

### Dieren systeem
- Dieren gedefinieerd als `AnimalData` Resource (`.tres` in `data/animals/`)
- Velden: `id`, `display_name`, `scene_path`, `image_path`, `color`, `scale`, `spawn_rotation`, `price`, `rarity`, `coin_rate`, `coin_amount`, `exp_gain`
- `image_path`: optioneel pad naar UI-afbeelding (`res://assets/models/animals/...`); wordt getoond als `TextureRect` in PlacingUI en Shop; lege string → fallback kleurblok
- Dieren hebben een **ster-niveau** (1★ t/m 5★, nog niet geïmplementeerd)
- **Combineren:** 2 dieren van zelfde ster → 1 dier van volgende ster (nog niet geïmplementeerd)
- **Training:** dieren individueel trainen → hogere productiviteit (nog niet geïmplementeerd)
- **Spa:** dier naar spa sturen → tijdelijke productivity boost (nog niet geïmplementeerd)
- **Rarity:** common / rare / mystic (en later: legendary)

### Dieren plaatsen (geïmplementeerd)
Flow: **tile selecteren eerst, dan dier kiezen**

1. Speler tikt vrije tile → 2D lila ruit highlight verschijnt (TileHighlight2D) → `EventBus.tile_selected` geëmit
2. Als build menu nog dicht was → `EventBus.placing_mode_entered` → PlacingUI opent
3. Speler tikt dier-card in PlacingUI → `animal_selection_changed` → `farm.gd._on_animal_selected`
4. Tile is geselecteerd → `_place_on_selected_tile()`: inventory aftrek, tile bezet, dier spawn, highlight weg
5. Bij bezette tile tikken (buiten placing mode): tap animatie op het dier (squish/spring/settle + lila burst). In placing mode: `tile_layer.shake_tile` (rode puls, 280ms)
6. Andere tile tikken terwijl menu open: highlight verplaatst, geen plaatsing
7. Menu sluiten: `_exit_placing_mode()` → `_clear_tile_selection()` → highlight verdwijnt
8. Dier spawnt met scale-animatie (0→`animal.scale` in 0.3s, ease-out bounce) + bob loop

### Gacha / Hatchery (geïmplementeerd)
- Spirit shards betalen per ei op basis van geselecteerde rarity
- 5 taps nodig → ei kraakt → gacha roll → dier verschijnt met reveal animatie
- Reveal: dier naam (36pt) + rarity badge in rarity-kleur + image; fade-in 0.3s → 2.5s → fade-out
- `_roll_rarity()` houdt rekening met geselecteerde UI-rarity als minimum:
  - `common` geselecteerd: 70% common / 25% rare / 5% mystic
  - `rare` geselecteerd: 80% rare / 20% mystic (nooit common)
  - `mystic` geselecteerd: altijd mystic
- `_pick_animal(rarity)` kiest random uit AnimalRegistry gefilterd op rarity; fallback naar common
- Dier wordt toegevoegd aan inventory via `GameState.add_to_inventory({"name": id})`
- `EventBus.animal_hatched(animal_id, rarity)` geëmit na elk ei
- Huidige dieren: chicken (common), pig (common), sheep (rare), dragon (mystic)

### Farms
- Meerdere farms ontgrendelen met resources
- Elke farm heeft andere benefits / thema?
- Potentieel: oneindig veel farms

### Quests
- Dagelijkse/weekly quests → "collect 3 spirit shards · 2/3"
- Progress bar in HUD zichtbaar (nog niet geïmplementeerd)

---

## Mappenstructuur
```
res://
├── data/
│   └── animals/          # AnimalData .tres resources (chicken.tres, sheep.tres, ...)
├── scenes/
│   ├── ui/
│   │   ├── MainMenu.tscn
│   │   ├── HUD.tscn
│   │   ├── Shop.tscn
│   │   ├── Hatchery.tscn
│   │   ├── PlacingUI.tscn
│   │   └── components/   # Background.tscn
│   └── world/
│       ├── FarmScreen.tscn   # root scene: SubViewport + HUD + UILayer
│       ├── Farm.tscn         # 3D wereld: grid, dieren, camera
│       └── Tile.tscn         # DEPRECATED — niet meer in gebruik
├── scripts/
│   ├── ui/               # hud.gd, shop.gd, hatchery.gd, placing_ui.gd, main_menu.gd
│   ├── world/
│   │   ├── farm.gd           # hoofdlogica: input, placing, spawn
│   │   ├── farm_grid.gd      # tile-generatie, bezetting, shake-feedback
│   │   ├── farm_screen.gd    # overlay-systeem (open_overlay)
│   │   └── tile.gd           # DEPRECATED
│   ├── resources/
│   │   └── animal_data.gd    # AnimalData Resource class
│   ├── systems/
│   │   └── fx_manager.gd     # FXManager autoload: spawn_coin_popup, spawn_coin_burst, spawn_tap_burst
│   └── autoloads/
│       ├── GameState.gd      # coins, spirit_shards, inventory, add/remove
│       ├── AnimalRegistry.gd # laadt alle .tres uit data/animals/, get_animal(id)
│       └── EventBus.gd       # globale signalen
├── assets/
│   ├── models/
│   │   ├── animals/      # ChickenClaudeDesign.obj, SheepClaudeDesign.obj + .png textures
│   │   └── farm/         # FarmGrid.obj + FarmGrid.png texture
│   ├── shaders/          # gradient_background.gdshader
│   ├── audio/
│   │   ├── ambient/
│   │   └── sfx/
│   ├── fonts/
│   └── wireframes/       # referentie-afbeeldingen (ChatGPT voxel guides)
├── project.godot
└── CLAUDE.md
```

---

## Scene-hiërarchie (actief)

### FarmScreen.tscn (root scene)
```
FarmScreen (Control)
├── Background (ColorRect) — gradient shader
├── FarmContainer (SubViewportContainer, stretch=true)
│   └── Farm3D (SubViewport, physics_object_picking=true, size=650×1200)
│       └── Farm (Node3D) — farm.gd
├── HUDLayer (CanvasLayer, z=5)
│   └── HUD
└── UILayer (CanvasLayer, z=10)  — overlays via open_overlay()
```

### Farm.tscn
```
Farm (Node3D) — farm.gd
├── WorldEnvironment
├── Sun (DirectionalLight3D)
├── Camera3D (orthogonal, size=12)
├── FarmGrid (MeshInstance3D) — FarmGrid.obj, unshaded + texture
├── TileLayer (Node3D) — farm_grid.gd
├── AnimalLayer (Node3D) — gespawnde dieren
├── HighlightLayer (CanvasLayer, z=5) — 2D tile highlight overlay
│   └── TileHighlight2D (Node2D) — tile_highlight_2d.gd
└── PlacingLayer (CanvasLayer, z=2)
    └── PlacingUI
```

---

## Tile systeem

### Constanten (farm_grid.gd)
```gdscript
GRID_SIZE   = 5
TILE_SIZE   = 0.7          # world units per tile
GRID_ORIGIN = Vector3(-1.75, 0, -1.75)
```

### Tile-coördinaten
- `tile_center(col, row)` → `GRID_ORIGIN + Vector3(col*0.7 + 0.35, 0, row*0.7 + 0.35)`
- Kolommen 0–4 (links→rechts), rijen 0–4 (voor→achter)

### Area3D picking
- Elke tile is een `Area3D` met `BoxShape3D(0.63, 0.3, 0.63)` op `y=0.1`
- `input_ray_pickable=true`, verbonden met `input_event` signaal
- SubViewport heeft `physics_object_picking=true` nodig

### Fallback raycast (farm.gd `_handle_tap`)
- Berekent intersectie van camera-ray met vlak `y=0.1`
- `col = int((world.x + 1.75) / 0.7)`, idem voor row
- Emit `EventBus.tile_tapped` als col/row binnen 0–4

### Tile bezetting (farm_grid.gd)
- `_occupied: Dictionary` — key `"col,row"`, value `true`
- `is_tile_free(col, row) -> bool`
- `occupy_tile(col, row)` / `free_tile(col, row)`
- `shake_tile(col, row)` — rode BoxMesh-marker: scale puls 1→1.4→0 in 280ms

### Tile selectie highlight (tile_highlight_2d.gd + farm_grid.gd)
- **2D CanvasLayer aanpak** — Decal en MeshInstance3D werken niet betrouwbaar op alle Android GPU's met Forward+
- `TileHighlight2D` (Node2D) in `HighlightLayer` (CanvasLayer z=5) inside Farm.tscn
- Tekent een lila ruit in 2D screen space via `_draw()`: `draw_colored_polygon` (fill) + `draw_polyline` (rand)
- Positie bepaald door `Camera3D.unproject_position(_world_pos + Vector3(0, 0.1, 0))` — volgt automatisch camera pan
- `_process()` roept `queue_redraw()` aan elke frame terwijl zichtbaar — ruit beweegt mee met camera
- `select_tile(col, row)`: `_tile_highlight.show_at(tile_center(col, row))`
- `deselect_tile()`: `_tile_highlight.hide_highlight()`
- Ruit afmetingen: w=38, h=25 pixels; offset Vector2(5, -6) voor isometrische uitlijning
- `EventBus.tile_selected(col, row, world_pos)` / `EventBus.tile_deselected()` voor cross-scene communicatie

---

## Camera setup
```gdscript
# Farm camera — isometrisch orthogonaal
camera.projection   = Camera3D.PROJECTION_ORTHOGONAL
camera.size         = 12.0
camera.position     = Vector3(5.7, 6.8, 5.66)
camera.rotation_deg = Vector3(-45, 45, 0)
# Positie omhoog/terug gebracht voor meer zichtbaarheid van FarmIsland zijkanten
```

---

## EventBus signalen
```gdscript
# Farm / world
signal tile_tapped(col: int, row: int, world_pos: Vector3)
signal tile_selected(col: int, row: int, world_pos: Vector3)
signal tile_deselected()
signal animal_placed(animal: Node)
signal animal_removed(animal: Node)
signal farm_unlocked(farm_id: String)

# Resources
signal coins_earned(amount: int)
signal coins_changed(new_amount: int)
signal coins_per_second_changed(cps: float)
signal coins_collected(amount: int, world_pos: Vector3)
signal spirit_shard_collected(amount: int)
signal shards_changed(amount: int)

# UI
signal tab_changed(tab_name: String)
signal placing_mode_entered(animal_data: Dictionary)
signal placing_mode_exited()
signal inventory_changed
signal notification_requested(message: String)

# Animals
signal animal_combined(result_animal: Node)
signal animal_trained(animal: Node)
signal animal_sent_to_spa(animal: Node)
signal animal_returned_from_spa(animal: Node)

# Hatchery
signal egg_tapped(progress: int)
signal egg_hatched(animal_data: Dictionary)
signal animal_hatched(animal_id: String, rarity: String)

# Quests
signal quest_progress_updated(quest_id: String, current: int, target: int)
signal quest_completed(quest_id: String)
```

---

## Code conventies
- **Één script per scene**, zelfde naam: `Farm.tscn` → `farm.gd`
- **Signalen** voor communicatie tussen nodes — geen directe `get_node` buiten parent-child
- **EventBus autoload** voor cross-scene events
- **GameState autoload** voor globale data (coins, inventory, farm data)
- **AnimalRegistry autoload** — `extends Node` met `_ready()` en hardcoded `ANIMAL_PATHS`; **niet preloaden** in andere scripts — gebruik direct als singleton. Noodzakelijk voor Android (DirAccess werkt niet in APK exports)
- **FXManager autoload** — Node, beheert visuele effecten; `set_fx_root(node)` aanroepen vanuit de scene die FX wil spawnen
- **Tweens** voor alle animaties — geen AnimationPlayer voor code-driven animaties
- Constanten in `UPPERCASE` bovenaan elk script
- GDScript type hints waar mogelijk: `var coins: int = 0`

---

## Animaties & feel (prioriteit)
- Spawn: scale `Vector3.ZERO → Vector3.ONE * animal.scale` in 0.3s, EASE_OUT + TRANS_BACK
- Dier idle: bob ±0.03 units op/neer, 1.1s per richting, EASE_IN_OUT SINE, loopt oneindig
- Tile selectie: 2D lila ruit (TileHighlight2D) — `show_at(pos)` / `hide_highlight()`; volgt camera via `_process` + `queue_redraw()`
- Tile bezet-feedback: rode puls (scale 1→1.4→0) in 280ms, daarna verborgen
- Coin collect: Label3D "+N" stijgt 0.6 units in 0.8s, alpha fade 1→0 na 0.4s delay (via FXManager.spawn_coin_popup)
- Dier tap: squish (scaleXZ×1.2, scaleY×0.7, 0.08s) → spring omhoog (scaleXZ×0.85, scaleY×1.3, +0.12 Y, 0.12s) → settle (terug naar base scale + Y, 0.10s). 1s cooldown per dier via `tap_cooldown` meta. Overgeslagen als `is_golden` of `tap_cooldown` meta true. Lila ♥/✦ burst via FXManager.spawn_tap_burst.
- Ei crack: shake (±11px x-as, 4 stappen, 0.20s) per tap; 5e tap → scale 1→1.25→0 (0.40s) → gacha reveal overlay
- Combineren: beide dieren naar midden, flash, nieuw dier spawnt met particles (nog niet geïmplementeerd)

---

## GameState (autoload)
```gdscript
var coins: int                          # setter emit coins_changed + EventBus.coins_changed
var spirit_shards: int                  # setter emit shards_changed + EventBus.shards_changed; start 25
var unplaced_animals: Array[Dictionary] # [{"type": "chicken", "id": "123_chicken"}]
var purchased_animal_types: Array[String]

func add_to_inventory(animal_data: Dictionary)   # key "name", emit inventory_changed
func remove_from_inventory(type_name: String) -> bool
func add_coins(amount: int)
func spend_coins(amount: int) -> bool
func spend_shards(amount: int) -> bool           # alias voor spend_spirit_shards
func spend_spirit_shards(amount: int) -> bool
func add_placed_animal_cps(coin_amount: int, coin_rate: float)  # accumuleert CPS, emit coins_per_second_changed
```
Verwijderd: `player_name`, `day`, `level` — niet meer gebruikt.

---

## Navigatiesysteem
- **FarmScreen.tscn** is de root scene — nooit vernietigd
- **Farm3D** (SubViewport) draait altijd op de achtergrond
- **UILayer** (CanvasLayer z=10): overlays (Shop, Hatchery) via `farm_screen.open_overlay(path)`
  - Overlay sluit zichzelf via `queue_free()`
- **HUDLayer** (CanvasLayer z=5): HUD staat altijd zichtbaar buiten de SubViewport
- Geen `change_scene_to_file` — Farm wordt nooit opnieuw geladen

---

## Save systeem
- Gebruik Godot's `ConfigFile` (geen JSON — veiliger op mobile)
- Sla op bij: elke plaatsing, aankoop, combinatie, app minimize
- Data: coins, spirit_shards, farms[], animals[], unlocked_items[]
- **SaveSystem autoload** — `register_placed_animal(col, row, type)` bij plaatsing; `restore_farm` signal → `farm.gd._restore_placed_animals(placed: Array)` herstelt geplaatste dieren bij opstart

---

## Beslissingen log
| Datum | Beslissing |
|-------|-----------|
| 2026-05-10 | Engine: Godot 4, GDScript |
| 2026-05-10 | Portrait mode, 9:16 |
| 2026-05-10 | Valuta: coins (◎) + spirit shards (✦) |
| 2026-05-10 | Combineren = training verlies + ster bonus |
| 2026-05-10 | Save systeem: ConfigFile |
| 2026-05-10 | Navigatie: overlay systeem via UILayer (CanvasLayer z=10) in FarmScreen.tscn — geen change_scene_to_file. HUD in HUDLayer (z=5). Shop/Hatchery sluiten via queue_free(). |
| 2026-05-14 | Farm grid: enkelvoudig FarmGrid.obj mesh (MagicaVoxel export, ±1.75 world units) + unshaded material met texture |
| 2026-05-14 | Tile systeem: GRID_SIZE=5, TILE_SIZE=0.7, GRID_ORIGIN=(-1.75,0,-1.75) — Area3D tiles dynamisch gegenereerd in farm_grid.gd |
| 2026-05-14 | Camera: orthogonaal, size=11, positie=(5.66,8,5.66), rotatie=(-45°,45°,0°) |
| 2026-05-14 | SubViewport: physics_object_picking=true (noodzakelijk voor Area3D input in SubViewport) |
| 2026-05-14 | Dier-plaatsing geïmplementeerd: tile_tapped → check vrij + inventory → spawn + occupy |
| 2026-05-14 | Tile selectie flow: tap tile eerst → highlight + menu open → dier selecteren → plaatsen (niet andersom) |
| 2026-05-14 | Tile highlight: Decal node met procedurele gaussian-circle texture (64×64 RGBA), lila, fade animatie |
| 2026-05-14 | AnimalData.spawn_rotation toegevoegd (default 180.0) — chicken=90°, sheep=90°, pig=90° |
| 2026-05-14 | FXManager autoload: coin popup via Label3D (billboard, no_depth_test, goudgeel #F0A030, font_size=45) |
| 2026-05-14 | Pig dier toegevoegd (pig.tres, Pig.obj/png); start-inventory: 5 chickens + 5 sheep + 5 pigs |
| 2026-05-14 | HUD: coins/sec indicator onder coin-teller (CoinCounter → VBoxContainer met CoinRow + CpsLabel); GameState.add_placed_animal_cps() accumuleert bij spawnen |
| 2026-05-14 | AnimalData.image_path veld toegevoegd; PlacingUI en Shop tonen TextureRect als image_path ingesteld, anders fallback kleurblok |
| 2026-05-15 | AnimalDetailPanel: gedeeld bottom-sheet panel (scenes/ui/components/AnimalDetailPanel.tscn + scripts/ui/animal_detail_panel.gd). Slide-in animatie vanuit onderkant (0.22s ease-out cubic). Context "shop" toont prijs + koopknop; context "placing" toont voorraadtelling + plaatsenknop. Shop animal cards openen panel via gui_input (geen inline koopknop meer). PlacingUI cards openen panel; "plaatsen" bevestigt selectie via _select_card. Rarity kleuren: common=#888780, rare=#7B5EA7, mystic=#F0A030. |
| 2026-05-15 | Golden animal systeem: GoldenAnimalManager autoload beheert random golden spawns (3–5 min interval, max 1 actief). Gewogen selectie: common 9×, rare 3×, mystic 1×. Duur: 15 sec. Beloningen: common 50×coin_amount (10% shard), rare 100× (40% shard), mystic 200× (100% shard). Visuals via material_override goudtint + Label3D ring + countdown boven dier + pulse scale tween. Input via Area3D op dier in SubViewport (set_input_as_handled voorkomt tile-shake conflict). FXManager.spawn_coin_burst voor grote burst animatie. HUD golden indicator bar met countdown. |
| 2026-05-15 | Tap animatie op geplaatste dieren: 3-fase squish/spring/settle tween (0.30s totaal) via `_anim_tap` in farm.gd. `_animal_at_tile` dict (key "col,row") bijhoudt welk Node3D op welke tile staat. `_bob_tweens` dict pauzeert de bob tween tijdens tap en herstart daarna. `is_golden` meta (gezet door GoldenAnimalManager) voorkomt conflict. Tap werkt ook als placing mode open is. FXManager.spawn_tap_burst: 5 lila ♥/✦ Label3D particles spatten uiteen. |
| 2026-05-16 | Achtergrond gradient shader uitgebreid naar 3 kleurstops: `color_top` / `color_mid` / `color_bottom` + `vignette_strength` uniform (default 0.0). FarmScreen: lila #C4AEDD → roze-beige #DDB8C4 → beige #F0D5B8, vignette 0.25. MainMenu/Shop/Hatchery ongewijzigd (color_mid = wiskundig middenpunt, vignette_strength=0.0). |
| 2026-05-16 | FarmIsland decoratief eiland: FarmIslandBig.glb geladen via `farm.gd _ready()` (niet in .tscn — .glb is een scene, geen mesh). `move_child(island, 0)` plaatst het achter grid en dieren. Scale=1.0 (zelfde als FarmGrid), position=(0.1, -4.0, 0). |
| 2026-05-16 | Camera bijgesteld voor betere eilandzichtbaarheid: size=12.0, positie=(5.7, 6.8, 5.66). |
| 2026-05-16 | Dier spawn positie offset: `tile_pos + Vector3(0.20, 0.25, 0.12)` — dieren staan meer naar de voorkant van de tile in isometrisch perspectief. |
| 2026-05-16 | Golden tap-burst race condition gefixed: `tap_cooldown=true` gezet in `_collect()` vóór `_cleanup()` zodat tile Area3D (dat later zelfde input ontvangt) `_anim_tap` niet afmaakt. Reset via `create_timer(0.5)`. |
| 2026-05-16 | AnimalRegistry omgezet van statische RefCounted naar `extends Node` autoload met `_ready()` en hardcoded `ANIMAL_PATHS`. Reden: `DirAccess.open("res://...")` werkt niet in Android APK exports — retourneert null. Alle scripts die AnimalRegistry gebruiken verwijderen hun `const AnimalRegistry = preload(...)` regel en spreken hem direct aan als singleton. |
| 2026-05-16 | Android double-event fix: Android stuurt per tap zowel `InputEventScreenTouch` als gesimuleerde `InputEventMouseButton`. PlacingUI dier-cards: `panel.gui_input` vervangen door transparante `Button` overlay als laatste child van PanelContainer, verbonden met `button_down` signaal (Godot handelt dit correct af). |
| 2026-05-16 | AnimalDetailPanel backdrop-close verwijderd: `gui_input` op backdrop verwijderd — panel sluit alleen via expliciete "sluiten" knop. Reden: Android double-events lieten panel direct sluiten na openen. |
| 2026-05-16 | AnimalDetailPanel omhoog geschoven 100px boven BottomNav: `offset_bottom=-100`, `offset_top=-(SHEET_H+100)=-430`. Animatie: start `offset_top=-100`, tween naar `-430`; close: tween terug naar `-100`. |
| 2026-05-16 | BottomNav tab "care" hernoemd naar "shop" — opent Shop overlay via `farm_screen.open_overlay("res://scenes/ui/Shop.tscn")`. BottomNav blijft altijd zichtbaar, ook in placing mode (geen `visible=false` meer bij placing). |
| 2026-05-16 | Tile highlight vervangen: Decal (werkt niet op Android Forward+) → MeshInstance3D QuadMesh (werkt ook niet betrouwbaar) → 2D CanvasLayer met Node2D `_draw()`. `TileHighlight2D` in `HighlightLayer` (CanvasLayer z=5) tekent lila ruit via `Camera3D.unproject_position()`. `_process()` roept `queue_redraw()` elke frame aan zodat ruit camera-pan volgt. |
| 2026-05-16 | Golden animal `is_instance_valid` fix: Android double-events lieten tweede invocatie crashen op `_input_area.get_viewport()` nadat `_cleanup()` `_input_area=null` had gezet. Fix: `is_instance_valid(_input_area)` guard bovenaan de input_event lambda. |
| 2026-05-16 | HUD vereenvoudigd: TopPanel (naam, avatar, level, dag) volledig verwijderd. Vervangen door compacte CoinCounter VBoxContainer rechtsbovenin (anchor_right=1.0, offset_right=-16, offset_top=16). `_refresh_player_info()` verwijderd uit hud.gd. |
| 2026-05-16 | player_name, day, level verwijderd uit GameState en SaveSystem — nergens meer gebruikt. MainMenu onboarding (naam-invoer flow) verwijderd; begin-knop laadt save direct of past defaults toe. |
| 2026-05-16 | Hatchery gacha systeem geïmplementeerd: `_roll_rarity()` houdt rekening met UI-selectie als minimum rarity. `_pick_animal(rarity)` filtert AnimalRegistry op rarity met fallback naar common. Reveal overlay: naam + rarity badge + image, fade in/out met 2.5s zichtbaar. Shardkosten common ✦3 / rare ✦8 / mystic ✦20, afgetrokken bij eerste tap. "niet genoeg ✦" melding als saldo tekortkomt. |
| 2026-05-16 | EventBus signalen toegevoegd: `animal_hatched(animal_id, rarity)` na elk ei; `shards_changed(amount)` bij elke shard-wijziging (via spirit_shards setter in GameState). |
| 2026-05-16 | Hatchery spirit shard teller: ShardCounter (CenterContainer) in HeaderBar rechts, vervangt lege HeaderSpacer. ShardLabel toont "✦ N" in goudgeel, geupdate via EventBus.shards_changed. |
| 2026-05-16 | Dier rarity waarden expliciet gezet in .tres: chicken=common, pig=common, sheep=rare, dragon=mystic (was al correct). |

---

## Golden animal systeem (GoldenAnimalManager)

### Constanten
```gdscript
GOLDEN_DURATION = 15.0       # seconden actief
MIN_INTERVAL    = 180.0      # 3 minuten minimum wachttijd
MAX_INTERVAL    = 300.0      # 5 minuten maximum wachttijd
```

### Gewichten & beloningen
| Rarity  | Selectiekans | Coin multiplier | Shard kans |
|---------|-------------|-----------------|------------|
| common  | 9 (3× rare) | 50 × coin_amount | 10%       |
| rare    | 3 (3× mystic)| 100 × coin_amount| 40%       |
| mystic  | 1           | 200 × coin_amount| 100%      |

### Flow
1. `_spawn_timer` loopt af (3–5 min) → `_try_spawn()` → `_pick_and_spawn()`
2. Dier krijgt: goudgele material_override, Label3D ring (4× ✦ op 0.5r), countdown Label3D boven hoofd (y=1.2), pulse scale animatie, Area3D voor input (0.8×1.2×0.8 box)
3. `EventBus.golden_animal_spawned` → HUD toont golden bar met countdown
4. Aantikken: `Area3D.input_event` → `set_input_as_handled()` → `_collect()` → beloningen, coin burst, cleanup
5. Timeout: `_on_expired()` → cleanup, nieuw interval
6. Cleanup: materials herstellen, scale herstellen, children vrijmaken, timers stoppen

### Technische noten
- `node.set_meta("animal_data", animal)` gezet in `farm.gd._spawn_animal` — noodzakelijk voor rarity lookup
- `node.set_meta("base_y", node.position.y)` gezet in `farm.gd._spawn_animal` — gebruikt door `_anim_bob` en `_anim_tap`
- `node.set_meta("is_golden", true/false)` gezet door GoldenAnimalManager — voorkomt dat tap animatie conflicteert met golden state
- `EventBus.animal_placed.emit(node)` geëmit na spawnen — GoldenAnimalManager bouwt zo `_placed_animals` lijst op
- `_input_area.get_viewport()` retourneert de SubViewport (Farm3D) — correct voor `set_input_as_handled()`
- `_tick_countdown` gebruikt `_golden_animal == null` check als stopcriteria (geen aparte tween-referentie nodig)
- **Race condition fix:** `set_input_as_handled()` blokkeert `_unhandled_input` maar NIET andere Area3D `input_event` callbacks. Tile Area3D en golden Area3D ontvangen beide de tap. Als golden Area3D eerst runt → `_collect()` → `is_golden=false` → tile Area3D runt → `_anim_tap` ziet `is_golden=false` en speelt ten onrechte af. Fix: `tap_cooldown=true` zetten op het dier in `_collect()` vóór `_cleanup()`, via `create_timer(0.5)` gereset na events.

---

## Nog te beslissen
- [ ] Exacte productiesnelheid per dier per ster
- [ ] Welke minigames?
- [ ] Farm thema's (Japans, winter, fantasy?)
- [ ] Monetisatie model (premium / IAP / ads-free?)
- [ ] Naam definitief: "Zen Farm" of "Zen Animal Farm"?
- [ ] Dieren combineren: UI flow en regels
- [ ] Save systeem implementeren
