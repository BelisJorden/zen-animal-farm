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
- **Links boven:** Speler avatar + naam (bv. "Yumi") + level + dag-teller
- **Rechts boven:** Coin-teller (goud icoon + aantal) + coins/sec indicator eronder ("1.2/sec", gedimde witte tekst)
- **Midden links:** Floating notificatie "+3 ✦ ready" (spirit shards klaar)
- **Onderin:** Quest/task balk — "collect 3 spirit shards · 2/3" met progress bar
- **Bottom nav (5 tabs):**
  - `farm` — hoofdscherm, isometrisch grid
  - `build` — plaatsingsmodus
  - `egg` — hatchery (actief = lila highlight)
  - `care` — dieren verzorgen / spa
  - `more` — instellingen, extras

### 3. Farm grid (`scenes/world/Farm.tscn`)
- Isometrisch 3D grid, voxel-stijl grastiles (FarmGrid.obj uit MagicaVoxel)
- Dieren worden gespawnd als Node3D op AnimalLayer
- Camera: orthogonal, 45° rotatie, vaste hoogte
- Touch: tap op tile → plaatst dier (in placing mode); drag → pan camera

### 4. Plaatsingsmodus (`scenes/ui/PlacingUI.tscn`)
- Header: "placing · [diernaam]" + cancel knop (rood ×)
- Onderin: horizontale scroll — "your animals · N unplaced" + filter knop
- Dier-cards: afbeelding preview (TextureRect als `image_path` ingesteld, anders kleurblok) + naam + count, geselecteerde heeft lila border
- Tap op vrije tile → dier gespawnd; tap op bezette tile → rode puls feedback

### 5. Hatchery (`scenes/ui/Hatchery.tscn`)
- Header: "hatchery" + back knop
- Centraal: voxel ei model (groot, roterend)
- Tekst: "almost there..." / "tap × tap × tap"
- Progress: 5 dots (●●●○○ stijl)
- Rarity selector: `common` / `rare` (actief, lila) / `mystic`
- Primaire knop: "tap to crack ✦ 3"
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

1. Speler tikt vrije tile → Decal highlight verschijnt → `EventBus.tile_selected` geëmit
2. Als build menu nog dicht was → `EventBus.placing_mode_entered` → PlacingUI opent
3. Speler tikt dier-card in PlacingUI → `animal_selection_changed` → `farm.gd._on_animal_selected`
4. Tile is geselecteerd → `_place_on_selected_tile()`: inventory aftrek, tile bezet, dier spawn, highlight weg
5. Bij bezette tile tikken: `tile_layer.shake_tile` (rode puls, 280ms), selectie ongewijzigd
6. Andere tile tikken terwijl menu open: highlight verplaatst, geen plaatsing
7. Menu sluiten: `_exit_placing_mode()` → `_clear_tile_selection()` → highlight verdwijnt
8. Dier spawnt met scale-animatie (0→`animal.scale` in 0.3s, ease-out bounce) + bob loop

### Gacha / Hatchery
- Eieren kopen met coins of spirit shards
- Egg rarity bepaalt kans op zeldzame dieren
- "Tap to crack" mechanic — meerdere taps (5 dots progress)
- Dieren: chicken, sheep, pig + later fox, crane, tanuki, cat, deer, rabbit, legendary

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
│   │   └── fx_manager.gd     # FXManager autoload: visuele effecten (coin popup)
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
├── Camera3D (orthogonal, size=11)
├── FarmGrid (MeshInstance3D) — FarmGrid.obj, unshaded + texture
├── TileLayer (Node3D) — farm_grid.gd
├── AnimalLayer (Node3D) — gespawnde dieren
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

### Tile selectie highlight (farm_grid.gd)
- Één herbruikbare `Decal` node, child van TileLayer, standaard `visible=false`
- Texture: procedureel aangemaakt — 64×64 RGBA Image, gaussian-achtige soft circle (`exp(-d²×2.5)`), lila `Color(0.78, 0.60, 0.95)`
- `select_tile(col, row)`: verplaats Decal naar tile center (Y=0.5), fade in `modulate.a` 0→0.85 in 0.15s; als al zichtbaar → directe positie-update
- `deselect_tile()`: fade out `modulate.a` 0.85→0 in 0.10s, daarna `visible=false`
- `EventBus.tile_selected(col, row, world_pos)` / `EventBus.tile_deselected()` voor cross-scene communicatie
- Decal size: `Vector3(TILE_SIZE*0.85, 1.0, TILE_SIZE*0.85)` — let op: werkt alleen als FarmGrid `shading_mode=0` (PER_PIXEL) heeft

---

## Camera setup
```gdscript
# Farm camera — isometrisch orthogonaal
camera.projection   = Camera3D.PROJECTION_ORTHOGONAL
camera.size         = 11.0
camera.position     = Vector3(5.66, 8, 5.66)
camera.rotation_deg = Vector3(-45, 45, 0)
# Kijkt exact naar (0, 0, 0) = center van het grid
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
- **AnimalRegistry autoload** — statische klasse (geen Node), preload in scripts die hem nodig hebben
- **FXManager autoload** — Node, beheert visuele effecten; `set_fx_root(node)` aanroepen vanuit de scene die FX wil spawnen
- **Tweens** voor alle animaties — geen AnimationPlayer voor code-driven animaties
- Constanten in `UPPERCASE` bovenaan elk script
- GDScript type hints waar mogelijk: `var coins: int = 0`

---

## Animaties & feel (prioriteit)
- Spawn: scale `Vector3.ZERO → Vector3.ONE * animal.scale` in 0.3s, EASE_OUT + TRANS_BACK
- Dier idle: bob ±0.03 units op/neer, 1.1s per richting, EASE_IN_OUT SINE, loopt oneindig
- Tile selectie: Decal fade in `modulate.a` 0→0.85 in 0.15s; deselect fade uit in 0.10s
- Tile bezet-feedback: rode puls (scale 1→1.4→0) in 280ms, daarna verborgen
- Coin collect: Label3D "+N" stijgt 0.6 units in 0.8s, alpha fade 1→0 na 0.4s delay (via FXManager.spawn_coin_popup)
- Ei crack: shake + particles bij elke tap (nog niet geïmplementeerd)
- Combineren: beide dieren naar midden, flash, nieuw dier spawnt met particles (nog niet geïmplementeerd)

---

## GameState (autoload)
```gdscript
var coins: int                          # setter emit coins_changed
var spirit_shards: int
var player_name: String = "Yumi"
var day: int = 1
var level: int = 1
var unplaced_animals: Array[Dictionary] # [{"type": "chicken", "id": "123_chicken"}]
var purchased_animal_types: Array[String]

func add_to_inventory(animal_data: Dictionary)   # key "name"
func remove_from_inventory(type_name: String) -> bool
func add_coins(amount: int)
func spend_coins(amount: int) -> bool
func add_placed_animal_cps(coin_amount: int, coin_rate: float)  # accumuleert CPS, emit coins_per_second_changed
```

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
- **Nog niet geïmplementeerd**

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
- `EventBus.animal_placed.emit(node)` geëmit na spawnen — GoldenAnimalManager bouwt zo `_placed_animals` lijst op
- `_input_area.get_viewport()` retourneert de SubViewport (Farm3D) — correct voor `set_input_as_handled()`
- `_tick_countdown` gebruikt `_golden_animal == null` check als stopcriteria (geen aparte tween-referentie nodig)

---

## Nog te beslissen
- [ ] Exacte productiesnelheid per dier per ster
- [ ] Welke minigames?
- [ ] Farm thema's (Japans, winter, fantasy?)
- [ ] Monetisatie model (premium / IAP / ads-free?)
- [ ] Naam definitief: "Zen Farm" of "Zen Animal Farm"?
- [ ] Dieren combineren: UI flow en regels
- [ ] Save systeem implementeren
