# Zen Farm — Feature Ideas & Suggestions
A braindump of features worth considering, grouped by theme. Each section has a short rationale for why it would bring players back or make the game more fun.

* * *
## 1. Daily Login & Streaks
**Why:** The single most effective retention mechanic in idle/cozy games. Gives players a reason to open the app every day, even if just for 30 seconds.

- Day-1 through day-7 streak calendar with escalating rewards (coins → shards → rare egg)
  
- Streak reset if you miss a day — but a "streak shield" consumable saves it once
  
- Special **month-30 streak reward**: exclusive legendary animal (e.g. a golden koi or moon rabbit) that can't be obtained any other way
  
- Small ambient reward for just _opening_ the app on top of the streak
  

* * *
## 2. Animal Star Levels + Combining
**Why:** Already designed in the codebase (1★–5★, `exp_gain` field exists). This is the core mid-game progression loop that gives idle players something to grind toward.

- Animals start at 1★, max 5★
  
- Combining: 2 animals of the same type + same star → 1 animal of that type at the next star
  
- Each star level: +20% coin rate, slightly bigger model scale, subtle glow/aura at 4★ and 5★
  
- Dedicated **combine screen** — drag two matching cards together, flash animation, satisfying sound
  
- 5★ animals emit a unique sparkle trail while idle on the farm
  
- Limit: you can only have one 5★ of each type per farm (scarcity makes it feel special)
  

* * *
## 3. Offline Earnings
**Why:** Idle games live and die on offline earnings. Players feel "rewarded for doing nothing" which is the core feel of the genre. Without it, there's no reason to come back after a long break.

- Coins accumulate while the app is closed, capped at ~4 hours of production
  
- On next open: friendly "Welcome back!" popup showing total earned + a tappable coin bag animation
  
- Offline rate is slightly lower than online rate (80%) to incentivize active play
  
- A rare **Offline Bonus** event occasionally doubles the offline cap (push notification hook)
  

* * *
## 4. Push Notifications
**Why:** The bridge between sessions. A gentle nudge at the right moment brings players back when they'd otherwise forget.

Suggested triggers:

- "Your farm earned ◎ 450 while you were away!" (offline earnings ready)
  
- "A golden animal appeared on your Mystic Realm farm!" (golden animal spawned)
  
- "Your egg is ready to hatch!" (hatchery timer, if added)
  
- "New daily quest available!"
  
- Configurable in Settings (toggle per category)
  

* * *
## 5. Visiting / Wandering Animals
**Why:** Surprise delight moments. Similar in spirit to the golden animal but different enough to feel fresh. Creates the "just one more check" habit.

- Every 20–40 minutes, a random **visitor animal** wanders onto the farm (not placed, just walks across)
  
- Tap it before it leaves (10-second window) → earn shards or a random item
  
- Visitor animals include animals you _don't own_ — teasing what's available in the hatchery
  
- Some visitors are seasonal (e.g. a snow bunny only in December)
  
- A **visitor log** in the "more" tab shows the last 10 visitors (name + rarity + what you earned)
  

* * *
## 6. Animal Happiness / Mood
**Why:** Adds a light maintenance loop that rewards attentive players without punishing casuals. Gives the "petting" mechanic more purpose.

- Each animal has a happiness meter (full → empty over ~8 hours)
  
- Tapping an animal fills its happiness by ~8%, but with a **3-tap daily cap per animal** (resets at midnight){>>How do you suggest to implement this. How much should tapping fill the happiness meter? There needs to be a balance, it can't be too easy because then sending them to the spa would be meaningless<<}{id="c2" by="user" at="2026-05-20T21:02:04.165Z"}{>>Suggested balance: 8% per tap, max 3 taps/day per animal. Attentive players can slow the decline but never fully restore by tapping alone — the spa is the only way to get from low → full instantly AND get the 2× coin boost. Tapping delays the decline; the spa reverses it.<<}{id="c3" by="AI" at="2026-05-20T21:15:00.000Z" re="c2"}
  
- Sending it to the **Spa** (already planned) fully restores happiness _instantly_ + grants a temporary 2× coin boost — the only way to fully recover happiness
  
- Happy animals (>75%) produce at full rate; unhappy animals (<25%) produce at 70%
  
- Visual cue: a small "zzz" cloud floats above sad animals, hearts appear above happy ones
  
- Keeps the tap interaction meaningful even after the novelty of placing wears off
  

* * *
## 7. Spa
**Why:** Already in the design. A dedicated "send animal away, wait, get it back boosted" mechanic adds time-gated progression that feels rewarding without being pay-to-skip.

- 1 spa slot (expandable to 3 via upgrades)
  
- Send any animal to the spa → unavailable for 2 hours → returns with +50% coin rate for 4 hours + happiness fully restored
  
- Spa has a warm visual: steamy pastel hot spring tile on the farm or as a side panel
  
- You can watch a short idle animation of the animal relaxing (good for social sharing)
  

* * *
## 8. Collection Book / Bestiary
**Why:** Completionists are a huge player segment. A "gotta catch 'em all" system gives long-term players a visible goal and a reason to keep hatching.

- Grid of all discoverable animals, silhouetted until obtained
  
- Each entry shows: name, rarity, lore blurb (one cozy sentence), best coin rate achieved
  
- Completion milestones reward shards: 25% → 50% → 75% → 100% complete
  
- "Seen but not owned" state: if a visitor animal walked by, it shows dimly — tantalizing
  
- A subtle **% complete** shown on the hatchery tab icon as a secondary stat
  

* * *
## 9. Seasonal Events
**Why:** Time-limited content is the strongest single driver of return visits in mobile games. Players open the app specifically because "this thing won't be here next week."

Ideas for events:

- **Cherry Blossom Festival** (spring): pink petal particles everywhere, exclusive pink rabbit, blossom decor
  
- **Harvest Moon** (autumn): golden fields background, moon-bear visitor, pumpkin decor
  
- **Winter Solstice** (December): snow layer on the farm island, snow-deer visitor, ice crystal accessories
  
- **Zen Anniversary** (yearly): original golden koi returns, special hatchery skin
  

Each event: 2-week window, event-specific quests, 1 exclusive animal only available via event hatchery rolls.

* * *
## 10. Farm Upgrades / Expansion
**Why:** Gives something to spend coins on at mid-to-late game when the basic loop has been mastered. Expands the farm from 5×5 toward larger grids.

- **Grid expansion**: unlock extra rows/columns with coins (5×5 → 5×6 → 6×6 → 6×7)
  
- **Decorative slots**: a separate layer where you can place decor items (lantern, shrine gate, koi pond) that _also_ provide passive buffs to nearby tiles (+5% coins for adjacent animals)
  
- **Landmark buildings**: a small Shrine (unlocked at ◎5000) that passively generates 1 spirit shard per hour
  
- Grid expansion gives a satisfying "my farm is growing" feeling without changing core mechanics
  

* * *
## 11. Crafting / Accessory Recipes
**Why:** Gives players something to do with excess resources and makes accessories feel earned rather than just bought.

- Combine 3 common accessories + ◎500 → rare accessory
  
- Some accessories only obtainable via crafting (not in shop)
  
- Simple UI: a crafting table in the "more" tab or as a farm building
  
- Recipes are discovered (first time you have the right ingredients, a hint appears)
  
- Keeps the economy balanced: more coin sinks, more reasons to hatch (need duplicate animals for star combining)
  

* * *
## 12. Achievement System
**Why:** Different from quests (which rotate). Achievements are permanent milestones that reward long-term play and give players a "trophy case" to look back on.

- Categories: Hatchery (hatch 1/10/50/100 eggs), Collector (discover 5/10/all animals), Farmer (place 25/50/100 animals), Coins (earn 1k/10k/100k coins), Streaks (7/30/100-day login streak)
  
- Achievements show in a dedicated tab in "more"
  
- Some achievements award exclusive cosmetics (farm border, special tile skin) not obtainable elsewhere
  
- A small badge counter on the "more" nav icon when new achievements unlock
  

* * *
## 13. Mini-Games{>>I really like this. It adds something to do besides just waiting untill animals generate coins. Can you give me some more ideas for simple mini-games like this<<}{id="c1" by="user" at="2026-05-20T20:59:11.991Z"}{>>Glad you like it! Added 5 more mini-game ideas below, all following the same rule: 15–30 seconds, fully optional, no penalty for skipping, scales with farm progress.<<}{id="c4" by="AI" at="2026-05-20T21:15:00.000Z" re="c1"}
**Why:** Short active-session mini-games add skill-based variety to the passive loop — players who want to engage can, casuals can skip. All mini-games share the same design rule: **15–30 seconds, fully optional, no penalty for ignoring, scales to give better rewards as the farm grows.**
### {==Coin Shower==}{>>Heb dit geimplementeerd en werk goed! Nog wel een opmerking/bedenking. Hoe gaan we dit schalend houden met de progressie van de player. Op elk moment moet de beloning (aantal coins) goed voelen en meaningfull zijn. Dus er moet een soort progressie zijn in het aantal coins dat de player verdient.<<}{id="c5" by="user" at="2026-05-20T21:35:21.618Z"}{>>Voorstel: elke gevangen coin = 30 seconden passieve productie. Formule: `per_coin = max(10, int(cps * 30))`, beloning = `score × per_coin`. Zo schaalt de beloning mee met de farm: beginner (CPS=2) verdient ~60 coins/coin, mid-game (CPS=20) ~600, late-game (CPS=100) ~3000. De minigame voelt altijd zinvol omdat het altijd "N minuten gratis passief inkomen" geeft, ongeacht hoe groot de farm is. Implementatie: in `coin_shower_game.gd` `_show_result()`, vervang `_score * 10` door `_score * maxi(10, int(AnimalProductionManager.coins_per_second * 30.0))`. Spirit shower blijft fixed (score × 2 shards) — shards zijn sowieso altijd schaars.<<}{id="c6" by="AI" at="2026-05-20T21:40:00.000Z" re="c5"}
- A rain cloud button appears every ~30 min → 15-second minigame where coins fall from the sky
  
- Tap as many falling coins as you can → bonus coins on top of passive earnings
  
- Difficulty scales with farm level: more coins fall, faster
  
- Unlock a **Spirit Shower** variant later where ✦ shards fall instead
  
### Animal Parade
- A line of animals marches across the screen; the top banner calls out "tap the sheep! tap the dragon!"
  
- Each correct tap within 10 seconds = bonus coins; tests recognition of your own animals
  
- Gets harder as you own more animal types
  
### Memory Match
- 6 face-down cards — flip pairs to match animals; 30-second time limit
  
- Matches award shards; full completion gives a bonus
  
- Works great as a "spa waiting room" mini-game while an animal is away
  
### Shard Harvest
- A spirit shard crystal slowly grows on the farm over time; when large enough, a tap-and-hold minigame plays
  
- Hold your finger, a ring fills — release at the right moment (fishing-style) to shatter it and collect ✦ shards
  
- Miss the window and get fewer shards; nail it for a bonus
  
### Animal Feeding
- A bowl appears on a random tile; drag food items from a tray at the bottom onto it before the timer runs out
  
- Correctly fed animal produces double coins for 10 minutes
  
- Simple drag-and-drop, very tactile on mobile
  
### Firefly Chase
- At night (ties into a time-of-day system if added), glowing fireflies drift across the farm screen
  
- Tap them before they drift off the edges; each caught = a small spirit shard
  
- Peaceful and zen — fits the game mood perfectly; no fail state, just catch as many as you can
  

* * *
## Priority Suggestion (rough order)
| Priority | Feature | Impact | Effort |
| --- | --- | --- | --- |
| 1   | Offline Earnings | Very High | Medium |
| 2   | Animal Star Levels + Combining | Very High | High |
| 3   | Daily Login / Streaks | High | Low |
| 4   | Push Notifications | High | Medium |
| 5   | Animal Happiness + Spa | Medium | Medium |
| 6   | Visiting Animals | Medium | Low |
| 7   | Collection Book | Medium | Low |
| 8   | Farm Grid Expansion | Medium | Medium |
| 9   | Seasonal Events | High (long-term) | High |
| 10  | Achievement System | Medium | Low |
| 11  | Crafting / Accessory Recipes | Low-Medium | Medium |
| 12  | Mini-Game: Coin Shower | Low-Medium | Medium |

* * *

_Written 2026-05-20. Open for review — add comments, cross things out, suggest changes._
