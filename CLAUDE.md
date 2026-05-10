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
- **Rechts boven:** Coin-teller (goud icoon + aantal)
- **Midden links:** Floating notificatie "+3 ✦ ready" (spirit shards klaar)
- **Onderin:** Quest/task balk — "collect 3 spirit shards · 2/3" met progress bar
- **Bottom nav (5 tabs):**
  - `farm` — hoofdscherm, isometrisch grid
  - `build` — plaatsingsmodus
  - `egg` — hatchery (actief = lila highlight)
  - `care` — dieren verzorgen / spa
  - `more` — instellingen, extras

### 3. Farm grid (`scenes/world/Farm.tscn`)
- Isometrisch 3D grid, voxel-stijl grastiles
- Dieren staan vrij op tiles (CharacterBody3D)
- Decor items (bomen, lantaarns, shrines) op aparte tiles
- Camera: orthogonal, 45° rotatie, vaste hoogte
- Touch: tap op tile → selectie; drag → pan camera

### 4. Plaatsingsmodus (`scenes/ui/PlacingUI.tscn`)
- Header: "placing · [diernaam]" + cancel knop (rood ×)
- Dier zweeft boven geselecteerde tile, lila glow indicator
- Onderin: horizontale scroll — "your animals · 7 unplaced" + filter knop
- Dier-cards: voxel preview + naam, geselecteerde heeft lila border
- Dieren: fox, crane, tanuki, cat, deer (en meer)

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
- **Grid:** 3 kolommen, items met voxel preview + naam + prijs
  - Coin-prijs: ◎ icoon + getal
  - Gem-prijs: ✦ icoon + getal (lila)
  - Gekochte items: lila border highlight
- Items (decor): fox lantern, koi tile, mossy rock, sakura tree, paper crane, shrine gate

---

## Game mechanics

### Core loop
```
Dieren op farm → genereren resources (passief) →
resources gebruiken voor: nieuwe dieren / decor / upgrades →
farm groeit → nieuwe farms ontgrendelen
```

### Valuta
- **Coins (◎):** standaard valuta, gegenereerd door dieren
- **Spirit shards (✦):** premium / zeldzame valuta, via quests/minigames

### Dieren systeem
- Dieren hebben een **ster-niveau** (1★ t/m 5★?)
- **Combineren:** 2 dieren van zelfde ster → 1 dier van volgende ster
  - Bij combineren: training gaat verloren, maar ster geeft permanente bonussen
- **Training:** dieren individueel trainen → hogere productiviteit
- **Spa:** dier naar spa sturen → tijdelijke productivity boost
- **Rarity:** common / rare / mystic (en later: legendary)

### Gacha / Hatchery
- Eieren kopen met coins of spirit shards
- Egg rarity bepaalt kans op zeldzame dieren
- "Tap to crack" mechanic — meerdere taps (5 dots progress)
- Dieren: fox, crane, tanuki, cat, deer, rabbit + legendary (dragon, unicorn, fantasy)

### Farms
- Meerdere farms ontgrendelen met resources
- Elke farm heeft andere benefits / thema?
- Potentieel: oneindig veel farms

### Minigames
- Manier om extra resources te verdienen
- Nog nader te bepalen welke

### Quests
- Dagelijkse/weekly quests → "collect 3 spirit shards · 2/3"
- Progress bar in HUD zichtbaar

---

## Mappenstructuur
```
res://
├── scenes/
│   ├── animals/          # Fox.tscn, Deer.tscn, Dragon.tscn, ...
│   ├── decor/            # SakuraTree.tscn, ShrineGate.tscn, ...
│   ├── ui/
│   │   ├── MainMenu.tscn
│   │   ├── HUD.tscn
│   │   ├── Shop.tscn
│   │   ├── Hatchery.tscn
│   │   ├── PlacingUI.tscn
│   │   └── components/   # CoinCounter.tscn, AnimalCard.tscn, TabBar.tscn
│   └── world/
│       ├── Farm.tscn
│       ├── Grid.tscn
│       └── Tile.tscn
├── scripts/
│   ├── animals/          # animal_base.gd, fox.gd, ...
│   ├── ui/               # hud.gd, shop.gd, hatchery.gd, placing_ui.gd
│   ├── world/            # farm.gd, grid.gd
│   ├── systems/
│   │   ├── resource_manager.gd   # coins, spirit shards
│   │   ├── animal_manager.gd     # spawn, combine, train
│   │   ├── save_system.gd        # ConfigFile based
│   │   └── gacha_system.gd       # rarity rolls
│   └── autoloads/
│       ├── GameState.gd          # globale game state (autoload)
│       └── EventBus.gd           # globale signalen (autoload)
├── assets/
│   ├── models/           # .glb exports uit MagicaVoxel
│   │   ├── animals/
│   │   └── decor/
│   ├── audio/
│   │   ├── ambient/      # rustgevende achtergrondmuziek
│   │   └── sfx/          # tap, spawn, combineer geluiden
│   └── fonts/            # game font (rounded, friendly)
├── project.godot
└── CLAUDE.md
```

---

## Code conventies
- **Één script per scene**, zelfde naam: `Farm.tscn` → `farm.gd`
- **Signalen** voor communicatie tussen nodes — geen directe `get_node` referenties buiten parent-child
- **EventBus autoload** voor cross-scene events (bv. `EventBus.animal_placed.emit(animal)`)
- **GameState autoload** voor globale data (coins, unlocked animals, farm data)
- **Tweens** voor alle animaties — geen AnimationPlayer voor code-driven animaties
- Constanten in `UPPERCASE` bovenaan elk script
- GDScript type hints waar mogelijk: `var coins: int = 0`

---

## Animaties & feel (prioriteit)
- Spawn: scale van `Vector3.ZERO` naar `Vector3.ONE` in 0.3s, ease out bounce
- Tap/select: kleine squish (1.1 scale, terug naar 1.0)
- Coin collect: float omhoog + fade out
- Ei crack: shake + particles bij elke tap
- Dier idle: subtiele bob animatie (0.05 units op/neer, 2s loop)
- Combineren: beide dieren naar midden, flash, nieuw dier spawnt met particles

---

## Camera setup
```gdscript
# Farm camera — isometrisch
camera.projection = Camera3D.PROJECTION_ORTHOGONAL
camera.rotation_degrees = Vector3(-45, 45, 0)
camera.size = 10.0  # aanpassen op basis van grid grootte
```

---

## Save systeem
- Gebruik Godot's `ConfigFile` (geen JSON — veiliger op mobile)
- Sla op bij: elke plaatsing, aankoop, combinatie, app minimize
- Data: coins, spirit_shards, farms[], animals[], unlocked_items[]

---

## Beslissingen log
| Datum | Beslissing |
|-------|-----------|
| 2026-05-10 | Engine: Godot 4, GDScript |
| 2026-05-10 | Portrait mode, 9:16 |
| 2026-05-10 | Valuta: coins (◎) + spirit shards (✦) |
| 2026-05-10 | Combineren = training verlies + ster bonus |
| 2026-05-10 | Save systeem: ConfigFile |
| 2026-05-10 | Navigatie: overlay systeem via UILayer (CanvasLayer z=10) in FarmScreen.tscn — geen change_scene_to_file zodat Farm nooit vernietigd wordt. HUD in HUDLayer (z=5) ook in FarmScreen.tscn (buiten SubViewport). Shop/Hatchery sluiten zichzelf via queue_free(). |

---

## Nog te beslissen
- [ ] Tile grootte (1.0 units? 1.5?)
- [ ] Max grid grootte per farm
- [ ] Exacte productiesnelheid per dier per ster
- [ ] Welke minigames?
- [ ] Farm thema's (Japans, winter, fantasy?)
- [ ] Monetisatie model (premium / IAP / ads-free?)
- [ ] Naam definitief: "Zen Farm" of "Zen Animal Farm"?
