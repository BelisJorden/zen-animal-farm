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
- **Onderin:** Quest balk — scrollbare lijst van 3 actieve quests (elk: titel + beloningen rechts, progress bar, N/M tekst). Hoogte 204px boven BottomNav. Verborgen tijdens placing mode.
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
- Centraal: 2D Panel ei (130×190, afgeronde hoeken) — kleur past aan op geselecteerde rarity:
  - `common` → beige/wit (`EGG_COLOR_COMMON = Color(0.95, 0.93, 0.88)`)
  - `rare` → lila (`EGG_COLOR_RARE = Color(0.6, 0.4, 0.9)`) — standaard bij openen
  - `mystic` → goud (`EGG_COLOR_MYSTIC = Color(1.0, 0.75, 0.1)`) + 4 roterende "✦" labels eromheen
  - Kleurovergang via Tween (0.3s) bij wisselen; sparkle-orbit verdwijnt bij non-mystic
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
│   │   ├── fx_manager.gd         # FXManager autoload: spawn_coin_popup, spawn_coin_burst, spawn_tap_burst
│   │   ├── golden_animal_manager.gd  # GoldenAnimalManager autoload
│   │   ├── quest_manager.gd      # QuestManager autoload: 12 quests, progress tracking, rewards
│   │   └── save_system.gd        # SaveSystem autoload: ConfigFile save/load
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
signal farm_changed(farm_id: String)
signal farm_switch_bounced()

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
signal animal_coin_produced(farm_id: String, col: int, row: int, amount: int)
signal animal_tapped(animal: Node)
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
signal quest_completed(quest_id: String, reward_coins: int, reward_shards: int, reward_item: String)
signal quests_updated()
```

---

## Code conventies
- **Één script per scene**, zelfde naam: `Farm.tscn` → `farm.gd`
- **Signalen** voor communicatie tussen nodes — geen directe `get_node` buiten parent-child
- **EventBus autoload** voor cross-scene events
- **GameState autoload** voor globale data (coins, inventory, farm data)
- **AnimalRegistry autoload** — `extends Node` met `_ready()` en hardcoded `ANIMAL_PATHS`; **niet preloaden** in andere scripts — gebruik direct als singleton. Noodzakelijk voor Android (DirAccess werkt niet in APK exports)
- **FXManager autoload** — Node, beheert visuele effecten; `set_fx_root(node)` aanroepen vanuit de scene die FX wil spawnen
- **FarmManager autoload** — laadt `FarmData` .tres resources, beheert `unlocked_farms` en `active_farm_id`; `save_state`/`load_state` via ConfigFile
- **AnimalProductionManager autoload** — beheert één Timer per geplaatst dier over **alle** farms; timers leven op de autoload node zodat coins doortellen ook als de farm niet zichtbaar is. `coins_per_second: float` property altijd up-to-date. `load_all_farms(dict)` aanroepen vanuit SaveSystem na laden; `register_animal(farm_id, col, row, type)` bij nieuwe plaatsing
- **QuestManager autoload** — beheert 12 quests in volgorde van moeilijkheid; max 3 actief tegelijk; luistert naar EventBus voor progress; volgorde in project.godot: vóór SaveSystem (zodat SaveSystem save_state/load_state kan aanroepen)
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
func add_shards(amount: int)                                    # alias voor add_spirit_shards
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
- Quest state opgeslagen onder `[quests]` sectie: `active`, `completed`, `progress` — via `QuestManager.save_state(cfg)` / `load_state(cfg)`

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
| 2026-05-17 | Hatchery ei kleur per rarity: common=beige, rare=lila (standaard), mystic=goud. `_egg_style` StyleBoxFlat gedupliceeerd en overschreven via `add_theme_stylebox_override`. Kleur tween 0.3s. Mystic: 4 roterende "✦" Label nodes in orbit Control (radius 72px, 4s rotatie loop). Sparkle verdwijnt bij non-mystic. |
| 2026-05-17 | Quest systeem geïmplementeerd: QuestManager autoload (`scripts/systems/quest_manager.gd`). 12 quests in volgorde van moeilijkheid (easy/medium/hard), max 3 actief tegelijk. Types: place_animals, earn_coins, hatch_eggs, tap_animals, collect_shards. Bij voltooiing: volgende quest automatisch geactiveerd, beloningen via GameState, notificatie in HUD. |
| 2026-05-17 | EventBus: `animal_tapped(animal)` geëmit vanuit `farm.gd._anim_tap()` na elke tap animatie. `quest_completed` signature uitgebreid met reward_coins, reward_shards, reward_item. `quests_updated()` signal toegevoegd. |
| 2026-05-17 | HUD quest balk vervangen: enkelvoudige quest → scrollbare VBoxContainer (QuestList) met 3 dynamische quest cards. Elk card: titel + beloningsoverzicht (◎N ✦N) + progress bar + N/M tekst. Cards gebouwd via `_rebuild_quest_cards()` in hud.gd. |
| 2026-05-17 | collect_shards tracking: QuestManager luistert naar `shards_changed(new_total)` en berekent delta via `_last_known_shards`. Enkel stijgingen tellen (uitgeven telt niet mee). |
| 2026-05-17 | Multi-farm systeem geïmplementeerd: `FarmData` Resource (`scripts/resources/farm_data.gd`) met id, name, unlock_cost, theme, background_top/mid/bottom, island_scene. `FarmManager` autoload laadt `data/farms/farm_1.tres` (Zen Farm, gratis) en `data/farms/farm_2.tres` (Mystic Realm, ◎2000, theme="fantasy"). `FarmManager.save_state/load_state` via ConfigFile `[farm_manager]` sectie. |
| 2026-05-17 | FarmOverview overlay (`scenes/ui/FarmOverview.tscn` + `scripts/ui/farm_overview.gd`): volledig code-gebouwde overlay met horizontale scroll van farm cards. Card: gradient preview (background_mid), naam, actie-knop (current farm/visit/unlock). Knop unlock toont prijs groen als betaalbaar, grijs anders. `_refresh_all_cards()` bij `farm_unlocked` en `coins_changed`. |
| 2026-05-17 | HUD farms knop: klein "⊞" Button (44×44px) top-left (16px marge), wit afgerond, lila icon. Opent FarmOverview als overlay. Gebouwd via `_setup_farms_btn()` in hud.gd `_ready()`. |
| 2026-05-17 | Farm wissel via swipe: horizontale swipe (min 80px, dy < dx×0.7) in farm.gd `_unhandled_input` roept `FarmManager.switch_to_next/prev_farm()` aan. `_swipe_handled` flag voorkomt Android double-event. Bij slechts 1 unlocked farm: `farm_switch_bounced` geëmit (geen actie). |
| 2026-05-17 | Achtergrond gradient bij farm wissel: `farm_screen.gd._on_farm_changed()` fade-out (0.18s) → `_apply_farm_gradient(farm_data)` → fade-in (0.22s). Fantasy particles: `farm.gd._update_fantasy_particles()` spawnt 5 gekleurde "✦" Label3D nodes in langzaam roterende orbit (10s/rotatie) voor theme="fantasy". |
| 2026-05-17 | Per-farm save data: `SaveSystem.placed_animals_per_farm` Dictionary (farm_id → Array). Migratie van oud enkelvoudig formaat (`[farm]placed` → `placed_animals_per_farm["farm_1"]`). `get_placed_animals(farm_id)` voor ophalen per farm. |
| 2026-05-17 | GoldenAnimalManager crash fix bij farm wissel: `_clear_farm()` in farm.gd roept `GoldenAnimalManager.force_cleanup()` aan vóór queue_free van animals. `force_cleanup()` stopt timers, emit expired, cleant state en leegt `_placed_animals`. `_restore_meshes()` gebruikt `for key in _orig_mats.keys()` + cast ipv getypeerde loop-variabele (Android crash fix). |
| 2026-05-17 | AnimalProductionManager: coins tellen op alle farms. Timers leven op autoload (niet op dier Node3D). Bij timeout: `EventBus.coins_earned.emit(amt)` (→ GameState + QuestManager) + `EventBus.animal_coin_produced.emit(farm_id, col, row, amt)`. `farm.gd._on_coin_produced()` toont coin popup enkel als farm_id == actieve farm. Timer nodes niet meer in `_spawn_animal`. `GameState.add_placed_animal_cps()` en `_total_cps` verwijderd. |
| 2026-05-17 | coins/sec HUD fix: `AnimalProductionManager.coins_per_second` property opgeslagen bij elke `recalculate_cps()` aanroep. `hud.gd._ready()` leest de waarde direct op. `farm.gd._refresh_hud_on_load()` (call_deferred) re-emits `coins_changed`, `coins_per_second_changed` en `shards_changed` zodat HUD altijd correct is na scene load. |
| 2026-05-17 | Achtergrond gradient fix bij opstarten: `farm_screen.gd._ready()` roept `_apply_farm_gradient(FarmManager.get_active_farm())` aan zonder fade, zodat farm 2 de juiste kleuren toont bij heropstarten. `_apply_farm_gradient(farm_data)` geëxtraheerd als gedeelde functie, gebruikt door zowel init als farm wissel tween. |
| 2026-05-17 | Per-farm grid & island assets: `farm.gd._reload_grid()` laadt `farm_data.grid_scene` (Mesh/.obj) dynamisch op `$FarmGrid` node; texture afgeleid via `get_basename() + ".png"`; surface_override_material opnieuw gezet. `_spawn_island()` uitgebreid: ondersteunt PackedScene (.glb) én Mesh (.obj) — bij .obj wordt MeshInstance3D aangemaakt. Beide functies aangeroepen bij `_ready()` én `_on_farm_changed()`. farm_2.tres: grid_scene=FarmGrid2.obj, island_scene=FarmIsland2.obj. |
| 2026-05-17 | AccessoryData uitgebreid: `icon_path` (String) voor shop preview afbeelding; `icon_scale` (float, default 1.0) voor zoom binnen vaste 88px kaarthoogte. Shop._make_card(): preview panel clip_contents=true; TextureRect met symmetrische anchor-offsets (inset = (1.0-icon_scale)*40) zodat schaling gecentreerd blijft. |
| 2026-05-17 | AnimalDetailPanel farm_id fix: hardcoded `const FARM_ID = "farm_1"` vervangen door `var selected_farm_id: String` — gezet op `FarmManager.active_farm_id` in `show_panel()`. Alle drie aanroepen (get_accessory, equip, unequip) gebruiken nu de correcte farm. |
| 2026-05-17 | AnimalDetailPanel _refresh_stats(): herberekent coin output inclusief accessoire bonus (coin_bonus_percent) voor context "farm". Luistert via getypeerde lambdas naar accessory_equipped (4 args) en accessory_unequipped (3 args). Aangeroepen in show_panel() en bij elke accessoire wissel. |
| 2026-05-17 | AnimalProductionManager recalculate_cps() fix: leest per dier `GameState.get_accessory(farm_id, col, row)` en past coin_bonus_percent toe — zelfde logica als Timer callback. Luistert via getypeerde lambdas naar accessory signals zodat HUD coins/sec direct updatet bij equip/unequip. |
| 2026-05-17 | quest_manager._on_animal_tapped signature fix: was `(_animal: Node)`, nu `(_animal_id: String, _col: int, _row: int)` — matcht EventBus signal `animal_tapped(animal_id, col, row)`. |
| 2026-05-17 | golden_animal_manager._restore_meshes crash fix: `is_instance_valid(key)` geplaatst vóór `key as MeshInstance3D` cast — Godot crasht bij cast op freed object, de validatiecheck moet eerst. |
| 2026-05-17 | SaveSystem migratie fix: `cfg.get_value("farm", "placed", null)` vervangen door `cfg.has_section_key("farm", "placed")` — Godot 4 ConfigFile accepteert null niet als default en gooit een error in plaats van het te onderdrukken. |
| 2026-05-17 | GDScript typed lambda patroon: signal handlers die twee signals met verschillende ariteit afhandelen (bijv. equipped=4 args, unequipped=3 args) gebruiken aparte getypeerde lambdas per connect() — geen gedeelde functie met `= null` defaults (geeft "Variant inferred" parser error bij warnings-as-errors). |
| 2026-05-17 | AccessoryData model_scale veld toegevoegd (float, default 1.0). accessory_node.gd gebruikt `acc.model_scale` in scale berekening: `Vector3.ONE * 0.4 * acc.model_scale`. Wizard hat toegevoegd als derde accessoire in AccessoryRegistry. |
| 2026-05-17 | Cancel placing on outside tap: `farm.gd._handle_tap()` roept `_cancel_placing()` aan als col/row buiten grid valt en `_placing_mode` actief is. `_cancel_placing()` emits `EventBus.tab_changed("farm")`. |
| 2026-05-17 | AnimalDetailPanel input fix voor placing context: `mouse_filter = MOUSE_FILTER_IGNORE` op root panel en `_backdrop.mouse_filter = MOUSE_FILTER_PASS` zodat farm grid taps doorkomen. Backdrop modulate alpha = 0 (onzichtbaar). |
| 2026-05-17 | AnimalDetailPanel tile-selectie check: `_tile_selected: bool` gevolgd via EventBus.tile_selected/tile_deselected. "plaatsen" knop toont `_show_place_hint()` (oranje label, 2s fade) als geen tile geselecteerd. Panel sluit bij EventBus.tab_changed("farm") in placing context. |
| 2026-05-17 | Golden animal multi-farm systeem: GoldenAnimalManager selecteert nu uit ALLE farms via `SaveSystem.placed_animals_per_farm` (niet meer enkel `_placed_animals` Node3D van actieve farm). State: `_active_golden_farm_id/col/row/type`. `on_farm_leaving()` vervangt `force_cleanup()` bij farm wissel — ruimt 3D visuals op maar behoudt timer en sessie-state. `apply_visuals_to(node)` publieke API voor farm.gd. |
| 2026-05-17 | EventBus signal `golden_animal_spawned_on_farm(farm_id: String)` toegevoegd — altijd geëmit bij golden spawn, ook als golden farm ≠ actieve farm. `golden_animal_spawned(node, farm_id)` geëmit enkel vanuit `apply_visuals_to()` (wanneer visuals toegepast). |
| 2026-05-17 | farm.gd golden integratie: `_on_golden_animal_on_farm(farm_id)` luistert naar `golden_animal_spawned_on_farm`; `_check_apply_golden()` zoekt node via `_animal_at_tile` en roept `apply_visuals_to()` aan. Aangeroepen bij signal én na `_on_farm_changed()`. `_clear_farm()` roept `on_farm_leaving()` aan ipv `force_cleanup()`. |
| 2026-05-17 | HUD golden bar multi-farm: `_golden_icon_label` dynamisch — toont "✦ golden animal" op actieve farm, "✦ golden · [Farm Name]" op andere farm. Bar tappable via `gui_input` → opent FarmOverview als golden op andere farm. `_on_farm_changed_hud()` updatet tekst bij farm wissel. Verbonden via `golden_animal_spawned_on_farm` ipv `golden_animal_spawned`. |
| 2026-05-17 | FarmOverview golden badge: elke card heeft `badge_row` HBoxContainer (meta "badge_row"). `_on_golden_on_farm()` voegt gouden pill "✦ golden" toe; `_remove_golden_badges()` ruimt op bij collect/expire. Bij openen overlay: directe badge-check als `GoldenAnimalManager.is_active()` (niet wachten op signal). |

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

## Quest systeem (QuestManager)

### State
```gdscript
var active_quests:    Array      # max 3 quest ids tegelijk
var completed_quests: Array      # alle ooit voltooide quest ids
var quest_progress:   Dictionary # quest_id -> int (cumulatief)
```

### Quest types & EventBus triggers
| Type | Signal | Increment |
|------|--------|-----------|
| `place_animals`  | `animal_placed`   | +1 per dier |
| `earn_coins`     | `coins_earned`    | +amount |
| `hatch_eggs`     | `animal_hatched`  | +1 per ei |
| `tap_animals`    | `animal_tapped`   | +1 per tap |
| `collect_shards` | `shards_changed`  | +delta (enkel stijgingen) |

### Flow
1. `_ready()` → `_fill_active_quests()` vult tot 3 uit `ALL_QUESTS` (filtert completed + al actief)
2. EventBus signal → `_track_progress(type, amount)` → `quest_progress[id] += amount`
3. Als `progress >= target` → `_complete_quest(id)`:
   - Beloningen via `GameState.add_coins()` + `add_spirit_shards()`
   - `EventBus.quest_completed.emit(id, coins, shards, item)`
   - `_fill_active_quests()` → nieuwe quest + `EventBus.quests_updated.emit()`
4. HUD luistert naar `quests_updated` → `_rebuild_quest_cards()`; `quest_progress_updated` → live bar update

### Beschikbare quests (in volgorde)
| id | type | target | ◎ | ✦ |
|----|------|--------|---|---|
| place_3_animals | place_animals | 3 | 50 | 2 |
| earn_200_coins | earn_coins | 200 | 30 | 3 |
| hatch_1_egg | hatch_eggs | 1 | 40 | 5 |
| tap_5_animals | tap_animals | 5 | 25 | 1 |
| place_10_animals | place_animals | 10 | 150 | 5 |
| earn_1000_coins | earn_coins | 1000 | 100 | 8 |
| hatch_5_eggs | hatch_eggs | 5 | 200 | 10 |
| collect_20_shards | collect_shards | 20 | 300 | 5 |
| place_25_animals | place_animals | 25 | 500 | 15 |
| earn_5000_coins | earn_coins | 5000 | 400 | 20 |
| hatch_15_eggs | hatch_eggs | 15 | 600 | 25 |
| tap_50_animals | tap_animals | 50 | 250 | 15 |

---

## Nog te beslissen
- [ ] Exacte productiesnelheid per dier per ster
- [ ] Welke minigames?
- [ ] Farm thema's: farm_1 (Zen, lila/roze/beige) + farm_2 (Mystic/fantasy, paars) bestaan; verdere thema's (Japans, winter)?
- [ ] Monetisatie model (premium / IAP / ads-free?)
- [ ] Naam definitief: "Zen Farm" of "Zen Animal Farm"?
- [ ] Dieren combineren: UI flow en regels
