# Hellfare

**Version 0.33 — Heroes** (on the `heroes` branch; `main` is v0.32)

A Godot 4.5.1 guild-management and gold-economy game. You run a guild of **Hellfarers** from Last
Lantern, the last town before the Maw: mercenaries who go down into hell for what only hell has,
or to fight through its crypts toward the Ashen King. It was called Money Mercs until v0.27.

> *Build a fortune. Let someone else go down for it.*

## Play

1. Pull `main` or clone https://github.com/wiings3/Hellfare
2. Import `project.godot` in Godot **4.5.1**. Run with **F5**.
3. A new guild opens on the prologue, then a tour walks you through your first loop. It can be
   skipped, and replayed from Settings.
4. Hire workers in **Mercenaries → Recruit** and send them to sites in **Expeditions**. Take your
   hero into the crypts (**Expeditions → Crypts**) and fight it yourself, or let them handle it.
5. Crews come back up on their own, even while you're away. Sell the haul in **Market**, craft in
   **Workshop**, and read every trip in the **Ledger**. Deaths are permanent.

## V0.33 – Heroes

The first hour, rebuilt around a hero you can play (design: `docs/GAME_DESIGN_DOCUMENT.md`).

- **The prologue.** A new guild opens on the guild you used to have: the Lantern Company, at the
  Ember Gate in the Brimstone Reach. You lead Ser Aldren Vane and Mira Holt through one fight on
  the new crawl screen, coached a turn at a time. Then Aldren cuts Mira down, takes the guild,
  and walks through the gate to become Death's First Blade. Three weeks later, in a rented room in
  Last Lantern, you choose your first hero: a knight or a rogue, with a name you can reroll.
- **Heroes replace guards.** Only heroes wear weapons and armour; workers carry tools. Heroes have
  their own tab under Mercenaries, their own slots (bought like charters: 1,800, 6,000 and
  15,000 G) and don't take expedition slots, so a crew and a hero can be out together. Knights hold
  the line (more health, Guard takes most of a blow, Shield Bash stuns); rogues hit fast and hard
  (crits, dodge, Backstab). Old saves keep their people: guards become workers, and a starter
  hero joins.
- **The crawl.** Crypts are fought turn by turn: Strike, the class skill, Guard, Potion, Retreat.
  Faster fighters act more often, bosses wind up a heavy blow every third action, and every stat
  on a piece of gear shows in the fight. Lead a run yourself, or let the hero handle it by the
  same rules (you can hand over mid-run). Floors you've cleared stay open: runs can start at the
  deepest known stairs.
- **The Fallen Keep, retuned** for one hero: four skeletons in the Cellars, two cave spiders in the
  Webbed Halls, the Bone Knight above them. A starter hero clears the Cellars; the Halls want
  tier-1 gear; the Bone Knight wants it made well (`tools/crawl_sim.gd` prints the table).
- **Shorter trips.** Tier-1 trips take a minute and a half, tier 2 four minutes, deeper sites a
  few more. Per-trip wages, supplies and hauls are unchanged, so playing pays more per hour; the
  long orders (Overnight, Full Day) still count their trips at the old pace, so a guild left alone
  earns what it did before, and deeper sites' per-trip risks are cut so the risk per hour of work
  stays the same. Crypt floors left to the hero take two and a half minutes.
- **The tutorial follows the new hour:** hire a woodcutter, send them, lead your hero into the
  Cellars while they work, sell the haul, then arm the hero — the pointer walks through learning a
  blueprint from the quartermaster, crafting it and equipping it.
- The board's Guarding row is now Heroes; the header counts crews out and heroes below separately.
- **New crawl art** from Aleksandr Makarov's *Heroic Asset Series: Creature Pack* (hand-made, credit
  required: see `CREDITS.md`): an animated swordsman and hooded crossbowman for the Knight and
  Rogue, skeletons, cave spiders and a death knight for the Fallen Keep, and for the prologue a
  paladin (Aldren) who turns into his dark twin (the First Blade), imps, and a devil at the gate.
  Fighters idle, strike, use their skill, flinch and fall. Only the sprites the game uses are in the
  repository: `python3 tools/import_has.py <pack folder>` writes them.
- **New crawl backgrounds** from Firepious's *Hellwake* and *Underfire* packs (free; the publisher
  tags them AI-assisted, so a Steam release needs the AI-content disclosure): a torchlit crypt for
  the Cellars, root-choked rock for the Webbed Halls, a pillared throne hall for the Bone Knight,
  and a chained, burning cavern for the Ember Gate. Native 256×144, drawn at a whole multiple.

## V0.32 – The Descent, repainted

The map on the Company page is repainted with the expedition banners' painter
(`tools/paint_descent_map.py`, built on `tools/paint_sites.py`): a lit cutaway under Last Lantern,
the farms and town at dusk on the surface, the Maw under the lantern tower, and the five layers
below as cavern ledges that narrow as they go down, each in its own light. Every site and crypt is
a small painted scene with its name under it, and every site has its own road, so a crew walks
to the exact place they were sent. Places out of reach are softly shaded and their tooltip says
what they need; names light up on hover; grave markers show only where there's fallen gear to
find. The painter writes `tools/map_roads.json` too, and the scene is rebuilt from it with
`python3 tools/build_pages.py company_map`, so the art and the clickable spots never drift.

## V0.31 – The Warehouse

Everything the guild owns is in one place: **Workshop → Warehouse** (the Workshop's third tab).
It replaces the Ledger's Warehouse tab and the Workshop's Storeroom.

- **One list** of goods and materials, spare weapons, armour and tools, gear your Hellfarers are
  wearing (marked with who), and food and potions, under headings, most valuable first. Each row
  shows how many, condition, and what it's worth.
- **Find** box (type part of a name) and filters: All, Goods, Arms, Armour, Tools, Food. A summary
  line counts everything: goods, spare and worn pieces, and total worth.
- **Details** on the right for whatever is chosen: how many, worth today, condition or how many
  recipes use it, its stats or description, where it comes from (or who wears it), and what you can
  do: sell in the Market, list on the Auction House, find recipes that use it, equip on a Hellfarer
  or pack food for a trip, sell or repair gear, open a wearer's Gear page.
- Every old way in (the Guild page's Warehouse tile, the town on the map) opens it.

## V0.31 – Names and new expedition art

**Names.** Applicants now draw from 200 men's names, 200 women's names and 350 family names
(`scripts/names.gd`), about 140,000 combinations instead of 240. A name is chosen when the person
is made and saved with them, so people already in a save keep theirs.

**Expedition banners.** All 23 site and crypt banners were repainted by `tools/paint_sites.py`
(which replaces `paint_hell_sites.py` and `paint_trade_sites.py`). Each banner is built like a
stage set: a sky with drifting smoke, silhouette layers that fade into the haze with distance, lit
by the scene's lights (a rim on the edges that face them, a wash on what's near), then glowing
things (embers, lava, windows, lanterns) that light their surroundings. Lakes and pools mirror
the sky. Every scene has Hellfarers at work in it: woodcutters, miners, foragers, anglers,
hunters, a crew on the road to the Fallen Keep. The farms above ground are dusk over Last Lantern,
with the Maw's glow on the horizon. The painter reduces each picture to 48 colours with an ordered
dither, and keeps what matters between y 20 and 105, clear of the badge in the bottom-right corner.

    python3 tools/paint_sites.py                       # repaint every banner
    python3 tools/paint_sites.py sheet.png weepingwood # one banner, plus a contact sheet

## V0.30 – First-launch tutorial

A new guild gets a short tutorial: a card in the bottom right of the book walks through the first
loop. It holds the player's hand the whole way: a gold pointer bobs beside the very next thing to
click (the bookmark, then the tab, the applicant, the Hire button, the trade, the site, the crew
card, Send them down, the good, the Sell button), and a line on the card says what to do. It reads
what's on screen, so a wrong turn (another applicant, another site, the wrong filter or tab) gets
pointed back. The next clicks are worked out in `_tutorial_guide` in `scripts/book_ui.gd`, from
controls tagged with the meta `tut` where they're drawn.

1. Welcome: what the guild does (Show me).
2. Hire a Hellfarer: Mercenaries → Recruit, a woodcutter.
3. Send them down: Expeditions → Logging → Cinderwood.
4. Wait for them to come back up (five minutes; crews work while the game is closed).
5. Sell the haul in the Market, or keep it (Keep it for now).
6. What to try next: more hands, the Workshop, a Warden's charter, the Fallen Keep.

Steps move on by themselves when the player has done them (someone who hires before reading skips
ahead), Skip tutorial ends it, and the card steps aside while a crypt event needs the player.
Progress is saved with the guild; guilds from before this version that already have people or
reports never see it. Steps are data in `scripts/tutorial.gd`; the card is
`scenes/journal/widgets/tutorial_card.tscn`.

**Settings → Replay tutorial** runs it again on any guild as a guided tour, without resetting
anything: each step waits for something new (a new hire, a new crew sent, a new report, a sale) or
its Next button, and End tour stops it.

## V0.29 – Sound

The game has sound: 41 sounds (61 files) from the Hellfare sound list, wired to the moments that
need them. Sound follows the art's rule: the guild hall is warm and close, hell is far away.

- **Alerts** for what needs you: a crypt event opening (and a clock ticking its last 5 seconds),
  a crew waiting for orders, a crew back up, a death, a lost crew, an Auction House sale, a
  trade request in the Tavern, a level-up.
- **Interface:** page turns, every button (toggles click differently, disabled buttons thud),
  coins when gold moves after a click, hiring, sending a crew down, signing a charter, equipping,
  crafting, cooking, repairing, listing on the Auction House, posting in the Tavern.
- **Crypt runs:** a safe or bold choice, whether it went well or badly, a floor cleared, the boss
  down, the crew turning back, gear and blueprints found.
- **Ambience:** the hall's hearth always, the Maw rumbling under it (louder while a crew is in a
  crypt), and drips and wind on a crypt run's page.
- **Settings → Sound:** a slider per group (Alerts, Interface, Ambience, Music), 1% steps (drag, or
  click and use the arrow keys), on a perceptual curve so the quiet end has room; and whether alerts
  keep playing while the game is in the background (everything else goes quiet). Music sits 9 dB
  under the sound effects and starts at 45%.

How it works: everything plays a sound by name through `Sound.play("crew_back")`; the autoload
`scripts/sfx.gd` looks the name up in `assets/audio/sounds.json` (files, group, volume, pitch
spread). `tools/make_sounds.py` builds every file: Kenney's CC0 RPG Audio and Interface Sounds
recordings, trimmed, levelled and layered, plus synthesised bells, the Maw, wind and the hearth.
Sources are listed in `assets/audio/CREDITS.md`. Headless runs (tests, CI) record sounds without
playing them.

**Music** (synthesised placeholders, in the same script): four short pieces on a bowed string,
a hummed choir, drones and a frame drum. One plays now and then (first after 1 to 2 minutes, then
5 to 15 minutes of silence between): the guild's theme by the fire, or a choir heard through the
floor while a crew is below. A crypt piece plays when a crew enters a crypt, and a brighter theme on
the pause menu. Music dips under alerts. Still missing: the Tavern crowd loop, and three small
extras (map hover, message, hint).

## V0.28 – Fewer, bigger crypt choices

Crypt events come once or twice a floor and once on the way out (five or six a run, down from
about 36), and no event repeats within a run. Each one carries about four times the stakes: more
coin, deeper wounds, bigger heals, three times the goods. You get 30 seconds to choose instead of
15. Simulated over 150 hours (3 runs each): a keep company whose crew plays it safe makes 232k
(228k with no events); one that takes chances makes 246k, with about the same deaths.

## V0.27 – Hellfare

The game is called Hellfare now: the window, the pause menu and the repository
(github.com/wiings3/Hellfare; the old address redirects).

- **Saves carry over.** Godot keeps a game's files in a folder named after the game, so the new
  name means a new folder. The first time Hellfare looks for its save or settings and finds none,
  it copies them from the old Money Mercs folder (`GameSettings.carry_over`). It never overwrites
  a file that already exists, and the old files stay where they were.
- Internal names stay: `MoneyMercsState`, `money_mercs_save.json`, the theme file. They are never
  shown to players.

## V0.26 – Hellfare: art

- **Banners.** Every site and crypt below has a new banner in the hell palette, each layer with
  its own sky: ash and ember for the Ashen Verge, blood-dark for the Weeping Fens, fire for the
  Brimstone Reach, cold blue for the Frozen Lament, near-black for the Abyss. They fill the
  planner's frame now. Painted by `tools/paint_hell_sites.py`; the farms keep their ink art
  (`tools/paint_trade_sites.py`). Site badges name the layer ("Layer 2 · Hunting 8+").
- **The descent map.** The Company page's map is a cross-section: Last Lantern and Home Fields
  on the surface, the Maw, and five layers narrowing down to the throne. Crews walk down through
  the Maw to their site and carry the haul back up; crypt crews walk to the Fallen Keep, which is
  clickable. Painted by `tools/paint_descent_map.py`, which also writes the roads.
- **Goods icons.** The 30 goods that come up from hell are tinted to match their new names
  (ashwood grey, brimstone yellow, bloodgarnet red, soulglass violet...). `tools/tint_hell_goods.py`
  keeps the untinted icons in `tools/icon_sources/` and always tints from them. Crops, food,
  potions, gear and tools are made above and keep their colours.

## V0.25 – Hellfare: names and writing

The same game, renamed for its new setting (see the Hellfare theme sheet). Every internal id is
unchanged, so saves, recipes, prices and tests carry over; only the words players see changed.

- **Places.** Mossward is Last Lantern, in the Gatelands. Work sites moved into hell's layers:
  Cinderwood, Weepingwood, the Gatepit, the Sulphur Deeps, Ashmeadow, the Bloodfen, Ember Slopes,
  Lament's Edge, the Cinder Pool, the Styx Shallows, the Lake of Glass, the Shore of Tears,
  Houndfang Hills and Gorehorn Moor; Hollow Fields, Bleakridge and the Drowned Deep keep their
  names. Farms stay above with their warm names.
- **Crypts.** Dungeons are crypts: Calder Keep is the Fallen Keep, the Sunken Abbey is the Drowned
  Abbey and Wyrm's Hollow is the Throne Below, where the Ashen King waits.
- **Goods and gear.** Birch timber is ashwood, oak is weepwood, coal is brimstone, moonleaf is
  ashleaf, azure crystal is soulglass, wolf pelts are hound pelts, and so on; gear made from them
  takes the new names (Ashwood Shortbow, Houndhide Jerkin, Kingbone Sword). Gear ids still use the
  old words (`birch_shortbow`): `display()` in `tools/catalog_gen.py` maps them.
- **People.** Mercenaries are Hellfarers in the writing (the bookmarks keep their names). Death
  reads as not coming back up, with a name on the Wall at the Maw. Respected is now Trusted;
  Woodsman is Ashcutter. Contracts sell to the rival guilds: the Red Wolves, Iron Hands, Grey
  Lanterns, Black Pines, Copper Crowns and Salt Kings.
- **Town.** The Trade Hall is the Gatehouse Tavern; expedition charters are Warden's charters;
  guild relief work comes from the Wardens of the Maw.
- **Wording.** Crews are "out" rather than "in the field"; site planners send them down; crypt
  events name Hellfarers and other guilds.

## V0.24 – The Auction House

Market → **Auction House** is now the main way to trade, between Merchants (instant, at
about 75% of fair value) and the Trade Hall (haggling in chat). Three tabs:

- **Browse:** search or filter (Goods, Arms, Armour, Tools, Food); each item shows how many
  are listed and the cheapest price. Pick one to see every listing cheapest first (gear with
  its rarity and rolls) and buy 1, 10 or all of a listing. Nobody selling? Place a **buy order**:
  the gold is held and sellers fill it over time; the page says roughly how long.
- **Sell:** what you hold, with what each is going for. Set how many and the price (or one
  click to match Merchants, the Cheapest listing or the Usual price), and 12 hours, a day or
  two days. It shows roughly how long it takes to sell, the fee and cut, and what you'll get.
  If an NPC company has a buy order for it, you can sell straight into it.
- **Yours:** listings and buy orders with progress, Cancel and "Match the cheapest", and the
  last 24 hours: sold, bought, fees and a recent list.

Gold arrives as things sell, purchases go straight to the warehouse or storeroom, and whatever
is left when a listing ends comes back by itself. Listing costs 1% of the asking total, and 5%
of each sale is taken. Up to 10 listings and 10 buy orders at once. Sales run while the game
is closed, worked out in ten-minute steps, and a toast and a Today entry report them.

Until real players arrive, NPC companies keep their own listings and buy orders (refreshed
every three hours) and buy and sell against yours: a listing at the usual price sells in
hours, one at 40% over may not sell at all, and the cheapest listing sells first. Goods sold
at auction weigh on the market price like goods sold to merchants.

## V0.23 – Calder Keep, the first dungeon

Expeditions → **Dungeons** opens Calder Keep (tier 1, gear score 8 to enter, 30 G supplies plus
wages, up to three mercenaries). It is fought floor by floor, four minutes a floor; a full run with the walk out and two
check-ins takes about 20 minutes:

| Floor | Foes | Carries |
|---|---|---|
| 1 · The Cellars | 5 giant rats | 22–41 coin, bone |
| 2 · Webbed Halls | 3 cave spiders | 43–77 coin, spider silk, bone |
| 3 · The Bone Knight | the boss, armoured | 156–252 coin, bone; 8% an ancient relic, 20% a tier-3 blueprint |

- **Fights** come from what the crew carries and wears: weapon damage, attack speed, crit and
  armour piercing against the monsters; armour, dodge, parry and block against their blows. A
  healing draught is drunk when someone is badly hurt; Lucky saves one death in three. Anyone
  without a weapon comes as a **porter**: doesn't fight, carries half again as much out, and
  takes heavier blows. The crew binds wounds (+10 health) on the stairs between floors.
- **Standing orders** set how deep to go (floor 1, floor 2 or the boss) and when to turn back
  (anyone below half, someone dies, never). "Below half" also backs the crew out of a fight
  before anyone falls. The planner shows each floor's odds for the chosen crew, the chance
  someone dies under these orders, the expected haul and the time.
- **Check-ins.** After each cleared floor the crew waits two minutes at the stairs: push on or
  take it out. A toast and a Today entry say so. With no answer the crew follows its orders,
  so a run finishes on its own while the game is closed.
- **Events.** Once or twice a floor and once on the walk out (since v0.28), something comes up:
  a chest with blood around it, a wounded mercenary with a fine sword, a side passage, a
  gambler, toll men at the stairs. A card slides in over whatever page is open with two or
  three choices; a crew member with the right trait or skill (Keen eye, Tracker, Herbalist,
  Combat 15…) may read the situation and say so. Choose within 30 seconds, or the crew
  decides by a new order set in the planner, **Play it safe** or **Take chances**, using what
  it was told. Outcomes: coin, silk, bone, tier-1 gear, healing, a blessing or curse on the
  next fight, sleeping or singed monsters, a stranger who fights beside you, wounds, deaths,
  dropped loot. Over 150 simulated hours, careful crews nobody watches earn what they did
  before events; crews taking chances earn about 15% more, with fewer boss kills. Reading the
  hints yourself is meant to beat both.
- **Harsher death.** A death makes the survivors drop half of everything they carry; a wiped
  crew loses everything. The dead lose their share, and each piece they wore has a 70% chance
  to stay in the keep for others to find (otherwise it is ruined). Only what gets out counts.
- The report (Ledger → Reports) leads with the floor-by-floor account, then what was left
  behind and who fell. Survivors earn Combat XP per floor (the boss counts three times) and
  their gear takes a dungeon run's wear.

For a tier-1 trio (steel sword and chainmail, a dagger, a shortbow) the default orders (floor 2,
below half) clear two floors almost every time for about 100 G with almost no deaths; going
all the way (turn back: never) beats the boss about 87% of the time, but someone dies in about half of those runs overall.
A veteran trio clears it safely. The Sunken Abbey and Wyrm's Hollow show as coming later.

**Gear score** replaces "kit" everywhere it's shown: how well equipped a mercenary is for a
fight, and what a dungeon checks at the door. Each worn piece adds its tier times its slot's
weight (main hand 4, body 3, off hand 2, head, hands and feet 1; two-handers 6), worn-out
pieces count half. It shows on the dossier, in the Gear view's footer and on each piece's
tooltip in the Gear view.

## V0.22 – The book, reorganised

Six bookmarks, each with one job, their names printed beside them and keys 1–6 to jump:

| Bookmark | Tabs | What it's for |
|---|---|---|
| Company | – | The region map, and a Today page: crews in the field, then only what needs you (crews back, the hurt, worn gear, idle hands, guild work), each with its button |
| Expeditions | – | The trades and their sites; the planner gives choosing a crew a full page |
| Mercenaries | Roster, Recruit | A compact roster and recruit list, both with filters; each dossier has Overview and Gear (the old Armory) |
| Workshop | Craft, Shop, Storeroom | What can I make, what can I buy, what do I have; Craft and Shop share category filters |
| Market | Merchants, Trade Hall | A compact goods table, held goods first, price arrows beside the price |
| Ledger | Accounts, Reports, Warehouse | Money and profit by trade; expedition reports; the one full list of goods held |

**Expedition charters** are now the only way to field more crews, up to five, signed in order
from the Ledger: I (1,200 G + 40 birch + 20 iron), II (8,000 G + 40 oak + 10 steel, Known),
III (30,000 G + 60 oak + 10 silversteel, Renowned), IV (90,000 G + 80 oak + 25 silversteel +
10 crystal, Legendary). Over 600 simulated hours the second and third crews arrive when they
used to (about 3h and 10–18h), the fourth around 180–205h and the fifth around 460–525h;
companies end 7–15% richer than under the old three-slot cap.

**Item lookup.** Click any item icon (site yields, report loot, recipe materials, the
Market's trade desk, the Workshop's rows, the Warehouse) for one card: what it is, how many
you hold, what merchants pay and charge, where it comes from and what it's used for, with
buttons to trade it or open its recipes.

The Regional Contracts and Standing pages are retired; their old links open the board and the
Company page. Explanations moved into tooltips; locked sites and empty states take one line.

## V0.21 – Fishing, hunting, farming and foraging

Four new trades are live, with seventeen expedition sites between them (`scripts/sites.gd`):

| Trade | Sites, tier 1 up |
|---|---|
| Foraging | Mossward Meadows, Fenmire, Sunreach Slopes, Frostvale |
| Fishing | Millbrook Pond, Silverrun River, Glasswater Lake, Greywater Coast, The Drowned Deep |
| Hunting | Hollow Fields, Greyfang Hills, Elkmoor, Bleakridge |
| Farming | Home Fields, Tilled Acres, Beehives, Glasshouse |

- **Tools.** Each trade has a shop tool to start (copper sickle, birch rod, birch shortbow, iron
  hoe); better ones are crafted. Rods are almost all timber plus cord. Hunters use weapons:
  bows hunt at full pace, other weapons at half.
- **Farm buildings.** Tilled Acres, the Beehives and the Glasshouse open once the company
  builds Field Plots, an Apiary or a Glasshouse. The site planner's button builds it; goods
  come from the warehouse and anything missing is bought from the merchants. A farming trip
  uses one bone meal from the warehouse, if there is any, for 15% more harvest.
- **Goods.** 83 goods in all (fish, meat, hides, bone, herbs, grain, honey, flour, linen,
  potions and 23 foods), each with an icon. `tools/goods_gen.py` writes the goods tables from
  the catalog.
- **Recruits.** The board has eight applicants: green hands for logging, mining and guarding
  every half hour, a fourth for one of the new trades in turn, and four more as good as your
  reputation allows. New traits: herbalist, patient, tracker and green thumb.
- **Pages.** The region map shows a road and a label for each new trade (click one to open its
  best site). Skill bars cover all seven trades. The company page shows the goods you hold;
  the Exchange has an All / Held / Raw / Crafted / Food filter; the Trade Hall lists held goods.
- **Art.** `tools/paint_trade_sites.py` paints the seventeen site banners and
  `tools/paint_goods.py` the goods icons.
- **Simulator.** `tools/econ_sim.gd` has forager, angler, hunter and farmer strategies.

**Balance check** (300 simulated hours, one trade only, merchants only):

| Strategy | Worth at 300 h | 100k reached | Deaths |
|---|---|---|---|
| Logging (tiers 1–2 only) | 402–415k | 74–85 h | 93–111 |
| Foraging | 451–516k | 72–80 h | 119–138 |
| Fishing | 472–506k | 79–88 h | 88–95 |
| Hunting | 552–557k | 75–79 h | 145–154 |
| Farming | 567–576k | 91–97 h | 0 |

Logging trails because its tiers 3–5 aren't live yet. The first run had hunting at twice
logging: a bow made every hunter count as a guard, cutting the crew's risk on top of hunting
at full pace. Hunters on a hunt no longer double as guards. The Glasshouse now yields 3–4
emberpeppers (was 3–5), so safe farming pays a little less than risky tier-3 sites. Farming
starts slowest (buildings first) and nobody dies.

## V0.20.1 – Idle wages

- Mercenaries in town draw half their trip wage each day, charged as time passes (including
  while the game is closed), so a roster held as an investment costs something. A company with
  no gold isn't pushed into debt. The roster shows the daily total next to the payroll.
- The two unused interface scripts (`ledger_ui.gd`, `guildhall_ui.gd`) are gone.

## V0.20 – Crafting, gear and repairs

Equipment is made of catalog items now (`scripts/gear.gd`, `Gear`).

- **Ten slots:** main hand, off hand, head, body, hands, feet, trinket, back, food and potion.
  Two-handed weapons take the off hand too. The main hand sets the job: a tool for its trade, a
  weapon to stand guard (each weapon tier adds two guarding levels).
- **Gear matters at work sites:**
  - armour and dodge lower each wearer's chance of injury and death;
  - packs and "Bountiful" rolls raise the haul; lanterns and trinkets add rare finds;
  - "Hasty" rolls shorten trips.
- **Rarity:** every crafted or found piece rolls Common (60%), Fine (28%), Superior (10%) or
  Masterwork (2%), with 0–3 extra stats from its family's pool. Finer pieces are worth more.
  The quartermaster's stock is always common.
- **Wear:** each trip uses 1 durability from everything worn; long orders use 3. Worn-out gear
  works at half effect until repaired.
- **Repairs:** cost about 35% of the recipe for a full repair (rounded), always with at least one timber
  of the piece's tier (birch for tier 1, oak for tier 2). Anything missing from the warehouse is
  bought from the merchants. Found-only pieces are repaired for gold.
- **Crafting (Personnel > Workshop):**
  - Anyone can craft with the materials and the blueprint.
  - Ingots and other intermediates are known to everyone.
  - The quartermaster sells tier 1–2 blueprints (40 G and 150 G); better ones will come from
    dungeons.
  - Recipes that need goods from expeditions not open yet (fish, crops, hunting) are listed but
    marked.
- **Food and potions** go in their own slots from the warehouse. Food is eaten at the start of a
  trip for its buff; a Healing Draught (Moonleaf and copper) is drunk when its carrier is hurt.
- **New goods:**
  - Oak Timber: the Old Oakwood now yields oak instead of birch, at about the same value.
  - Coal and a little iron from Harlow.
  - Wolf pelts now and then from the Oakwood; spider silk and garnets from Deepdelve; amber from the Copse.
  - Steel and Silversteel Ingots and Healing Draughts, crafted.
- **Kit rating** (tier × slot weight) shows on the dossier and in the Armory, ready for
  dungeons.
- **Skills train half as fast** (twice the experience per level).
- **Older saves:** "tool" and "armor" become main hand and body; items become common at full
  durability.

`tests/crafting_test.gd` covers blueprints, recipes, rarity odds, slots and two-handers, wear,
repairs, armour, food, potions, kit rating and migration. New icons come from
`tools/paint_icons.py`.

## V0.19 – Mercenaries without archetypes

Nobody is hired as a Woodcutter, Miner or Guard any more (`scripts/mercs.gd`, `Mercs`).

- **Gear sets the job.** Anyone can hold any tool. An axe makes a woodcutter and a pickaxe a
  miner; a weapon stands guard. The right tool works at full pace; anything else at half pace.
  Recruits bring a basic tool for their best trade.
- **Skills and traits make the person.** Trade skills grow by working, as before. Every
  mercenary has one or two traits for life:
  - common: Frugal, Greedy, Tough, Reckless, Coward;
  - uncommon: Woodsman, Steady hands, Brawler, Quick healer;
  - rare: Strong back, Keen eye, Lucky;
  - legendary: Prodigy, Born leader, Ironhide.
- **Earned titles:** "Veteran Miner · Mining 31", worked out from the tool in their hands and
  their skill.
- **Reputation:** comes from the value crews deliver (5 per 100 G), no longer from trip count,
  and a crew wiped out costs a little. The tiers are Unknown, Known (500), Respected (5,000),
  Renowned (25,000) and Legendary (75,000). Simulated full-time play reaches them after about
  10, 50, 200 and 600 hours.
- **The recruit board follows reputation.**
  - Three green applicants (one per trade) are always there and cheap.
  - Four more can be as skilled as the tier allows: up to level 5 / 10 / 20 / 30 / 40.
  - Rare and legendary traits appear at the design's odds.
  - Named mercenaries (Garrick, Oswin, Bram, Serah) turn up once you're reputable enough for
    them.
- **The contract market:**
  - Known companies see contracts other guilds are selling, refreshed every 4 hours. Each is
    priced above its value plus a 10% transfer fee.
  - A bought mercenary settles in for 3 days before they can be sold on.
  - Any mercenary can be sold to another guild for half their shown value, with their gear.
    Each sale costs 2% of your reputation (at least 5).
  - Mercenaries won't join a company below their reputation tier.
- **Older saves:** each mercenary's old role becomes a background line, they keep their skills,
  and they gain one common or uncommon trait.

`tests/mercs_test.gd` covers the board, jobs, titles, traits, value, reputation, contracts and
migration.

## V0.18 – The item catalog

Everything the game will have lives in one data file, `data/catalog.json`, read by
`scripts/catalog.gd` (`Catalog`). It is generated by `tools/catalog_gen.py`: edit the script and
re-run it (`python3 tools/catalog_gen.py`).

- **Expeditions:** 29 across six trades (logging, mining, foraging, fishing, hunting, farming) plus
  three dungeons. Each tier opens at a higher skill level; the better farmland needs building.
- **Materials:** 56. Each tier has its own metal, timber, hide, cloth and gem, plus fish, meat,
  crops, herbs and treasures.
- **Weapons:** eight families at every tier, each with its own shape. Daggers are fast and crit
  most; swords are the all-rounder; war axes and maces hit harder, slower and through armour;
  spears strike first. Greatswords, bows and crossbows take both hands.
- **Armour:** light (dodge, speed), medium (balanced, fewer injuries) and heavy (armour, block,
  slower). Each weight has head, body, hands and feet at every tier.
- **Also:** bucklers, kite and tower shields; tools for every trade; lanterns, trinkets and packs;
  23 dishes and 7 potions.
- **Stat rolls:** every crafted or dropped piece rolls Common, Fine, Superior or Masterwork, with
  0–3 extra stats drawn from its family's pool. Daggers roll crits and speed, maces roll stuns.
- **Food:** sits in a mercenary's food slot for the next trip. Cooking burns timber as firewood,
  and fishing rods are mostly timber.
- **Found-only pieces:** eleven, fixed rolls, between tier 4 and tier 5.
- **Company upgrades:** charters, field plots, an apiary and a glasshouse, paid for
  in materials.

`tests/catalog_test.gd` fails the build if any of these break:
- every material has a source and a use;
- every expedition yields something;
- every item can be obtained, priced at 1.1–2.2× its materials, with no inputs above its tier;
- every tier has every weapon family, shield and armour piece, and every trade has a tool;
- one-handed damage per second, counting crits, stays within 15% of the sword's, and two-handers
  sit 5–35% above it;
- armour runs heavy > medium > light, and gear gets stronger with tier;
- found-only pieces sit between tier 4 and tier 5;
- today's items and goods keep their ids, names, slots and prices.

Nothing in play changes yet. The shop, prices and gear in today's game are as before. Crafting,
stat rolls, food, wear and kit rating will read from the catalog when they are built.

## V0.17 – More ways to get rich

Measured with the 1,000-hour simulator (`tools/econ_sim.gd`, median of three runs).

- **Overnight (8 h) and Full Day (20 h) orders** at every site: half or 55% of the hourly haul for a quarter or a fifth of the wages and supplies, at lower risk. Once-a-day players went from 149k to about 740k at 1,000 hours, and three-check-ins-a-day players from 100k to about 695k (casual: about 1.0M).
- **Mining career:** Harlow Mines, the first mining expedition from the MVP, is now an ordinary tier-1 site like Mossward Copse, and Deepdelve (Mining 8, cave crawlers) is mining's Old Oakwood. Harlow's old scouting and rotating deposits are retired; they only finish trips and saves made before the change. A mining company reaches about 1.25M, level with logging.
- **Trade Hall:** guild contractors post big orders above fair value for up to an hour, and bargain sellers go deeper. Pure trading with no crew still doesn't pay; it needs its own mechanic.
- Long trips average several dice rolls and scale rare finds with their length; injury and death are capped.
- **Healing:** mercenaries resting in town recover 20 health an hour for free, counted from when they got home, so they heal while the game is closed. Treatment costs 0.6 G per missing point (5 G minimum), down from 1.5 G (12 G minimum). Healing went from about 7% of a full-time company's sales to about 3%.
- The recruitment board no longer empties after many deaths. That bug ended full-time companies around hour 550.

## V0.16 – Gear of the fallen

- When a mercenary dies at a site, there's a 40% chance 1–3 pieces of their gear stay where they fell. Items last 24 hours.
- Each company can find only its own small share of a site's pool (about 1 in 80 items). The share reshuffles every 24 hours. Grave markers on the map show your share at each site; hover one to see what you could find.
- Every trip rolls up to two finds from the share: 9% Cautious, 12% Balanced, 18% Deep Push, 45% Long Shift. A find counts only if the finder gets home. If they die, it drops back into the pool for someone else. A carrier shows a glint on the map.
- Four rare pieces can only be found, never bought: Dwarven Pickaxe (900), Warden's Axe (800), Knight's Blade (1,100) and Gilded Plate (1,500).
- Until real players arrive, NPC companies dying at the sites fill the pools (Copse ~145, Oakwood ~340, Harlow ~600). `FallenGear` keeps one interface (share, size, drop, claim) so a server can replace it.
- Mossward Copse supplies are down from 6 G to 2 G. A lone new woodcutter was breaking even or losing money whenever timber was cheap.
- Harlow's old 15% "abandoned pickaxe or sword" find is replaced by the pool.

## V0.15 – The living map (mockup)

- The Company chapter now opens on a **Region** map. Each expedition's real timer moves its crew: they walk the road out for the first 20% of the trip, work at the site (axes in the woods, picks at the mine) for the middle 60%, and carry the haul home for the last 20%. Idle mercenaries wander around Mossward, and smoke rises from the chimneys.
- Click a site name to plan an expedition there. Locked sites show the level they need. Click Mossward to see the company's standing.
- The old overview moved to the **Standing** tab, unchanged.
- Art: `tools/paint_map.py` paints `assets/ui/art/region_map.png`, the crew frames and the road guides. The roads are the hidden `Line2D` nodes under `Map/Roads` in `company_map.tscn`, so you can re-route them in the editor.
- Preview: `xvfb-run godot --path . --rendering-method gl_compatibility --resolution 1440x900 --script res://tools/capture_map.gd -- out=/tmp/map frames=90 step=3` records frames without touching the save.

## V0.14 — Economy rebalance from the simulator

The economy simulator (`tools/econ_sim.gd`) played 150-hour runs of each strategy; these changes fix what it found. Active play now lands on the targets: 1,000 G at about 2–3 h, 10,000 G at about 15–25 h, 100,000 G at about 85–110 h.

- **No more bankruptcy soft-lock.** Guild work and relief are judged on cash, goods and spare gear (`liquid_worth()`), not gear the crew is wearing.
- **Merchants:** saturation can move a price at most 50% (was 60%) and fades with an 8-hour half-life (was 12). Timber's market depth is 100.
- **Old Oakwood** pays about 1.3–1.5x the copse per hour with half the old death rate (8–11 timber, 20 G supplies, 0.6% death). **Mossward Copse:** 5-minute trips, 3–5 timber, 6 G supplies.
- **Orders:** Deep Push is 1.25x yield at normal length (no longer shorter). New **Long Shift**: one trip six times as long, 80% of the hourly haul, four times the wages and supplies, for players who check in now and then.
- **Trade levels** add 3% yield each (was 5%). **Expedition slots** cost 1,500 G and 9,000 G.
- **Harlow Mines:** hourly rotations with 25–40 copper and 10–22 iron, 6 ore per miner, 5-minute trips, about half the old death risk.
- **Trade Hall:** NPC buyers have a per-good demand pool that refills over 4 hours; when it runs low they say they are stocked up.
- **Regional contracts** are off the Expeditions board (they bankrupted every simulated company).

## V0.13 — The Trade Hall as a real trade chat

Replaces the listings (V0.11) and the whisper page (V0.12). NPC traders stand in for players until the game goes online; the chat, messages and trade window stay the same.

- **Type your own posts.** The left page is the trade chat with a message box. Shift+click an item in your inventory (right page: warehouse goods and spare gear) to link it as a hoverable `[Item]`, then write what you like, e.g. `WTS [Steel Sword] +20% CRIT, 150g`. Enter or Send posts; an 8-second cooldown and a repeat check stop spam. Enter on the page jumps into the box; Escape leaves it.
- **Right-click (or click) a name** for Message / Trade / Block. The message window also has a Trade button. A trader accepts a trade request once you've agreed a price; before that they ask you to settle the price first. Blocked traders' posts and messages are hidden; the block list is saved.
- **Private messages** open in a small draggable window with a tab per conversation. NPC traders read what you write (`ChatParse`: prices like `6g ea`, `150`, `1.5k`, lots like `20 for 110g`, quantities, yes / no, "trade") and haggle with the rules in `scripts/haggle.gd`. They may be slow, may not answer at all, and their posts sell out whether or not you message.
- **Your posts get answers.** NPCs skim your post and may message you if the price interests them (or ask "How much for the [Timber]?" if you gave none).
- **Trade window.** Once you agree a price the trader sends a trade request. Put your side in yourself (click goods or gear in the inventory, set the gold). Two-step confirm against last-second swaps: each side **locks** its offer (a locked side can't be edited), then once both are locked and a 2-second pause has passed, both **accept**. Any change, including unlocking, clears both locks. The trader locks only when your side covers the deal. 3% tax on gold you receive. Gear can be bought and sold this way.
- Old saves: goods sitting in V0.11 listings go back to the warehouse on load.
- Code: `scripts/trade_hall.gd` (chat, NPC behaviour), `scripts/chat_parse.gd`, `scripts/haggle.gd`, `scripts/trade_session.gd`, `scripts/hall_view.gd` (page and window bindings), scenes `pages/hall_left|right.tscn`, `widgets/pm_window.tscn`, `widgets/trade_window.tscn`, `NamePopup` in the shell.

## V0.12 — Trade Hall stage 2: whispers and haggling

- Click or right-click a trader's name in the chat to whisper them about that post. The right page becomes the whisper: their kind and patience pips, the post, the conversation, and a quantity and whole-lot offer ("30 for 503g?").
- Each trader has a hidden walk-away price and limited patience (`scripts/haggle.gd`). Hagglers give up to about 16% and hear five offers; bargain sellers barely move and hear two. Counters close part of the gap each time; lowball offers (25% or more past their limit) cost double patience; when patience runs out they walk away.
- Taking their price, or an offer they accept, settles at once (the trade window arrives in stage 3). You can now buy from WTS posts; selling into WTB posts pays the 3% tax. Traded-out posts show as sold.
- Buyers whisper offers on your listings priced above fair value ("Would you take 185g for 40 of your [Timber]?"). Accepting sells straight from the listing.
- Replies arrive after a short "typing" pause. Whispers are not saved; a reload ends open conversations.

## V0.11 — The Trade Hall (stage 1) and the pause menu

- **Trade Hall** (Exchange chapter, second tab): a trade chat in the style of Dark and Darker's first trade channel. Fourteen NPC traders of six kinds (hawker, quartermaster, collector, flipper, bargain seller, haggler) post `WTS [Timber]x40 6g each` / `WTB` lines priced around each good's fair value.
- Hover an item link for its item card (fair value, merchant prices, best ask and bid in chat, warehouse count). Click it to price your own listing.
- **Your stall**: list goods from the warehouse (held in escrow), pay a 2 G post fee, and NPC buyers take fairly priced listings; a 3% tax comes off each sale. Up to 5 listings, 12 hours each; unsold goods return. Sales continue while the game is closed (up to a day of catch-up).
- Fair value = the market's reference price x merchant saturation, so the Hall and the merchants stay linked. Model: `scripts/trade_hall.gd`.
- **Pause menu**: Escape closes the journal onto its back cover with Resume, Settings (fullscreen, vsync, book animations) and Save and Quit. Settings are stored in `user://settings.cfg`.

## V0.10 — Trades, skills and a living market

- **Market model** (`scripts/market.gd`): each good has a reference price (base price, six-hour drift, demand events with news). NPC merchants buy at about 75% and sell at about 130% of it. Selling floods them and lowers their price; buying makes goods scarce. The effect fades with a 12-hour half-life. Prices are sampled hourly and after each trade, and the Exchange shows the history, saturation and the day's news.
- **Trade skills** (`scripts/skills.gd`): every mercenary has Logging, Mining, Foraging and Combat levels (1 to 50) that grow with experience. Hiring role sets the starting speciality. Older saves are migrated automatically.
- **Sites** (`scripts/sites.gd`): expedition sites are data. Logging launches with Mossward Copse (level 1, safe) and Old Oakwood (level 8, wolves, rare relic). Harlow Mines is listed as the first mining site. The planner shows expected haul, expected profit and risk before you commit.
- **Expeditions chapter**: a board of every trade and site plus the company's best level in each trade, and a site spread modelled on Harlow. Woodcutters, hand axes and felling axes join the recruitment board and armory.
- Expedition profit now counts the goods brought home at the merchant price, not just loose coin.
- `tools/balance_logging.gd` simulates hundreds of trips per crew and order type (it resets the save, so it requires `MM_ALLOW_RESET=1`).

## V0.9 — Logbook UI redesign

The interface now renders as crisp pixel art at a **960x540 base resolution** (exactly 2x at 1080p). The book is drawn at one art pixel per stage unit, and all text uses two bundled pixel fonts (SIL Open Font License, in `assets/fonts/`): **Jersey 15 and 20** for titles and **Jersey 10** for body text. Nothing depends on the player's installed fonts any more.

- **Theme:** `assets/ui/theme/money_mercs.tres` is the project theme. Buttons (with real hover, pressed and disabled states), panels, slots, bars and label styles are theme type variations such as `PaperButton`, `ToggleButton`, `CardButton`, `SlotPanel`, `InsetPanel`, `LabelCaption`, `LabelBig` and `LabelTitle`. Pick them from the *Theme Type Variation* field in the inspector.
- **Art:** `assets/ui/book/` holds the BookUI sheets pre-recoloured to oxblood (the old runtime shader darkened the parchment). `assets/ui/kit/` holds the nine-patch frames, slots, bars and pips; `assets/ui/icons/` the item and role icons; `assets/ui/portraits/` placeholder busts. `tools/make_kit.py` and `tools/recolor.py` regenerate them.
- **Widgets** (`scenes/journal/widgets/`): `section_header`, `stat_tile`, `item_slot`, `info_box`, `pip_row`, with inspector properties (`text`, `caption`, `value`, `icon`, `count`…) so they can be edited in the editor.
- **Chapters:**
  - *Company*: worth breakdown, crew/reputation/debt/equipment, warehouse slots, a guildmaster's note with the next step, teams in the field with live timers, and the latest report.
  - *Harlow Mines*: site art and survey state, ore and threat intel, scout card, crew slots, roster cards, standing-order toggles, forecast, and a fund button that explains itself.
  - *Personnel*: roster of portrait cards with a full dossier (stats, health and treatment, equipment, contract terms); recruitment with applicant details; armory with loadout, storeroom and quartermaster.
  - *Exchange*: goods list with price trends, a trade desk with 1/10/all buttons, and advice on today's price.
  - *Finances*: treasury ledger, company worth, expedition-slot expansion, payroll, guild advances when broke, a profit chart of recent expeditions, and warehouse valuation.
  - *Chronicle*: every report with outcome seals, then recovered coin, costs, loot, each crew member's fate and field notes.
  - *Regional Contracts* and *Guild Work*: contract cards with requirements and possible finds; guild eligibility checklist with paperwork and labour jobs.
- Layouts for the non-Harlow chapters were authored with `tools/build_pages.py` (using `tools/scene_gen.py`); the generated `.tscn` files are ordinary editor scenes and are now the source of truth.

## V0.8 — The Guildmaster's Logbook (BookUI)

The primary game interface is now a **literal open company ledger** built around the complete two-page book, desk, six chapter tabs, icon-free tab variants, dark red button shapes, and frame-by-frame page-turn sprites from the user's licensed `assets/BookUI/Pocket Inventory Series #7 Gems of Status v1.1/` pack.

Every main function has its own live book spread: Overview, Harlow Mines scouting and dispatch, regional contracts, Mercenaries, recruitment, quartermaster/armory, commodity exchange, financial ledger, safe guild work, and after-action Chronicle. Each page is a working native Godot interface over existing sprites, not a flattened illustration.

Six hand-pixeled 24×24 transparent PNGs in `assets/ui/tab_icons/` provide the company shield, expeditions compass/map, personnel helmet, exchange scales, treasury pouch, and chronicle quill. `book_shell.gd` renders them at 40×40 stage pixels with nearest-neighbor filtering above the page-turn animation, without changing the licensed book artwork.

Navigation uses the pack's actual tab art and flip animations. Pixel art is nearest-filtered, cropped without distorted stretching; desktop sizes retain the same book aspect ratio. Controls display live game state and preserve existing save files. Screen captures are generated by Godot in CI at desktop and widescreen sizes.

**Actual screenshots:** [Open Book](docs/ui_office_wide_preview.jpg), [Harlow Dossier](docs/ui_harlow_wide_preview.jpg), [Exchange](docs/ui_trading_wide_preview.jpg), [Personnel](docs/ui_mercenaries_preview.jpg), [Armory](docs/ui_armory_preview.jpg), [Chronicle](docs/ui_journal_preview.jpg).

The earlier `scripts/guildhall_ui.gd` and `scripts/ledger_ui.gd` interfaces were removed in V0.20.1; nothing loaded them. The journal (`scripts/book_ui.gd`) is the only interface.

## Editor-node UI migration

The fixed Guildmaster's Journal is editable in `scenes/journal/journal_shell.tscn`, instanced by `scenes/main.tscn`. Its desk, book, title/status labels, six clickable tabs, icon positions, page-turn layer and content regions are saved Godot nodes—not built in GDScript. Open the journal scene directly to move those controls.

Reusable UI elements are also editor scenes in `scenes/journal/widgets/`: label, divider, highlight, book button, text button, scroll list and record row. Dynamic content instantiates these scenes so their styles can be changed in the editor without adjusting code.

**Migration status: completed for the active journal.** The fixed journal shell, seven shared widget types, and **every active journal spread** are editor scenes under `scenes/journal/pages/`: Company, Harlow, Personnel (Employees, Recruitment, Armory), Exchange, Finances, Guild Work, Chronicle and regional Expeditions. The page scenes contain the actual fixed labels, field positions, scroll areas, headings and buttons, editable in the Godot editor. Scripts now bind game values, connect buttons and update visibility. Variable-length lists are made from **15 editable row scenes** under `scenes/journal/rows/` (recruitment cards, armory stock, market goods, reports, Harlow crews, etc.), with text and action buttons all placed in the editor. Only the number of rows and their live text/callbacks are determined by GDScript. The visual layout of every active UI element is in an editor scene.

To customize the UI: open `scenes/journal/journal_shell.tscn` for the book, icons, header and tabs; `scenes/journal/pages/` for each spread; `scenes/journal/rows/` for repeated cards; and `scenes/journal/widgets/` for reusable controls. To change behavior, edit `scripts/book_ui.gd` or the simulation scripts.

## Where to make changes (current architecture)

The game intentionally uses a small number of focused scripts rather than a framework:

| File | Responsibility |
| --- | --- |
| `scripts/book_ui.gd` | Dynamic content and interactions of the current journal pages |
| `scripts/book_shell.gd` | Node lookups, tab callbacks, page flips and editor widget instancing; positions of fixed controls belong in `journal_shell.tscn` |
| `scripts/game_actions.gd` | Buttons-to-gameplay actions, selection state and game clock |
| `scripts/game_state.gd` | Harlow mine scouting, dispatch, rotation and resolution (public `MoneyMercsState`) |
| `scripts/company_state_base.gd` | Company state, saves, employees, equipment, money, trading, other jobs |
| `scripts/v05_rules.gd` | Data-only equipment and party calculations |

Active presentation inheritance: `BookUI → BookShell → GameActions → Control`. Active game state: `MoneyMercsState → CompanyStateBase → RefCounted`.

**Practical rules:** keep new page drawing in `book_ui.gd`, common book controls in `book_shell.gd`, gameplay callbacks in `game_actions.gd`, and gameplay mechanics in the state scripts. Don't put economy or expedition rules inside UI scripts. Don't change save keys casually: `user://money_mercs_save.json` still uses version 1.

**Checks:** the GitHub Actions workflow in `.github/workflows/ci.yml` imports Godot 4.5.1 and runs the existing smoke/regression tests. Tests that reset the company are CI-only and should not be run on personal save data.

## V0.7 — Guild Operations interface

- The previous ornate panel-heavy guildhall UI has been replaced with a calmer, reference-led operations interface informed by the management structure of *Battle Brothers* and the scan-friendly item hierarchy of *Dark and Darker*.
- The painted guildhall remains the atmospheric background. Content uses a reusable walnut-and-brass control kit: left navigation, functional cards, high-contrast typography, clearly differentiated primary and secondary actions, and a context panel.
- Screens rebuilt together: Overview, Harlow scouting and dispatch, Mercenaries, Recruitment, Armory, Trading Post, Ledger, Guild Work, regional contracts, and Chronicle.
- Images use aspect-preserving, explicitly bounded controls instead of distorted full artwork. Source textures, UI labels and data are separate.
- Persistent saves, asynchronous expeditions, scouting, equipment purchases, mercenary death, guild work, trading, and risk math continue to use the existing gameplay implementation.
- Verification: Godot 4.5.1 gameplay regression suite, UI flows at standard desktop and 1280×720, and native rendering at 1440×900 and 1920×1080. Actual screenshots: [Overview](docs/ui_office_wide_preview.jpg), [Contracts](docs/ui_harlow_wide_preview.jpg), [Trading Post](docs/ui_trading_wide_preview.jpg), [Company Ledger](docs/ui_finance_wide_preview.jpg).

## V0.6 — Guildmaster's Desk UI

Money Mercs now launches into a **functional rustic guildhall interface**, not the old flat admin dashboard. Original art assets depict a timber-and-stone guildhall, carved signage, treasury plaques, wax seals, parchment contracts, a sketched mine and the guildmaster's desk.

The redesigned Overview, Harlow scouting/dispatch dossier, Mercenary recruitment/armory, Trading Post, regional contracts, safe Guild Work, finances and Chronicle are interactive **native Godot controls** wired to live data and existing game saves. V0.5.1 mechanics, permanent casualties, injuries, item ownership, offline missions and recovery work remain unchanged.

Main scene at the time: `scripts/guildhall_ui.gd` (removed in V0.20.1). Art: `assets/ui/guildhall_desk.svg`, `skin_parchment.svg`, `skin_wood.svg`, `skin_burgundy.svg`, `skin_wax_seal.svg`, `harlow_ink_sketch.svg`. The UI is scalable from a 1600×900 design canvas.

**Actual in-game screenshots:** [Overview](docs/ui_office_preview.jpg) · [Harlow](docs/ui_harlow_preview.jpg) · [Mercenaries](docs/ui_mercenaries_preview.jpg) · [Armory](docs/ui_armory_preview.jpg) · [Trading Post](docs/ui_trading_preview.jpg).

## What's fixed in 0.5.1

### Bad-luck protection without reversing death

Players who lose their opening guard or miner need a repeatable, **risk-free path back into the expedition economy**. The Guild Office now offers **Guild Work Orders**:

| Assignment | Requirements | Duration | Guaranteed gold |
| --- | --- | --- | --- |
| Routine contract labor | Any available mercenary; no equipment or deposit | 2m 30s | 18 G |
| Office paperwork | No workers, entry fee, or gear required | 3m | 9 G |

Work orders do not kill or injure anyone, require no fee, save as missions, use an operation slot, and finish even while the game is closed. **They are recovery jobs, not a superior money farm:** only companies with less than 120 spendable gold **and** less than 250 estimated net worth can start new ones. An active job still pays if the company crosses those thresholds during its timer.

The Harlow dispatch warrant provides a link back to the Guild for companies without a guard or enough wages. Copper and iron merchant values were also raised slightly so successful guarded expeditions can more consistently cover wages. Real permadeath remains unchanged.

An automated regression test now forces the starter guard to die, reduces company cash to zero, and demonstrates that the lone miner can work safely until another guard can be recruited. A second test verifies recovery from **zero gold, zero mercenaries, and maximum outstanding loan debt**.

## What's new in 0.5

### Recruitment and real equipment

- **Repeatable hiring board:** Six generated applicants rotate every 30 minutes, with entry-level miners and guards always represented. Existing named mercenaries and saves remain valid.
- **The Armory:** Buy six actual items (mining picks, swords and armor), store them as individually identified objects, choose an employee, equip or swap items by slot, unequip, or resell unused gear.
- **Meaningful roles:** Mining tools increase extraction capacity; guard weapons improve the protection offered by guards; armor reduces individual fatality risk.
- **Permanent stakes:** Equipped items and legacy upgrade investment are lost along with a killed mercenary. Surviving workers keep their actual loadouts.
- **Rescue mechanism:** Cash-strapped companies without an active expedition can request a limited 90-gold guild advance. The 110-gold debt is repaid gradually from profitable activity while preserving minimum working capital.

### Harlow Mines / expedition loop

- Reported ore, threat clues and precision improve with scout training; scouting remains safe and offline-capable.
- Orders, skills, tools and guards affect objective success and **per-worker mortality estimates** independently.
- The simulation resolves contact with the threat, deaths/injuries, mining and return separately.
- **Failed objectives can still recover partial ore**, as long as a miner survives.
- Deposits are consumed exactly once across competing team assignments for the same rotation, even when operations finish after the rotation changes.
- Rarely, teams recover useable equipment as an expedition find.
- The Chronicle now records **actual events**, deaths, injuries, found gear, lost gear and the difference between appraised haul and spendable coins.

### Early economy and compatibility

- Early copper and iron prices were retuned to help a company finance basic jobs without making expensive teams automatically profitable.
- Commissions for V0.5 Harlow missions are provisionally assessed against **gold found**, not the value of unsold resources. This prevents a single item drop from producing an instant negative cash balance; full contract compensation and physical currency are for later economy work.
- **Old v0.4 save files load without conversion by the player.** Legacy tier equipment continues to provide a limited compatibility bonus. Expeditions already underway resolve under their old rule set.
- Other Contracts remain under the old simplified rules while Harlow serves as the economic simulation testbed.

### QA

- Godot 4.5.1 CI checks importing/loading scenes, basic economy, UI interactions, Harlow scouting, recruitment, equipment loss, item uniqueness, partial returns, debt recovery, and save migration.
- Graphical CI saves actual screen previews to `docs/ui_*_preview.png`, including the Armory and Journal.

## Guild Ledger interface

**V0.4's visual design remains in place**, with gameplay-driven screens added to the Mercenary and Chronicle pages. See the latest [Harlow screenshot](docs/ui_harlow_preview.jpg), [Armory screenshot](docs/ui_armory_preview.jpg), and [Journal screenshot](docs/ui_journal_preview.jpg). These are rendered by Godot, not mockups.

## Controls

Use the top tab bar or shortcuts **1–6**. Saved progress lives at `user://money_mercs_save.json`. Developer builds have a two-step company reset and time-skip action under The Chronicle.

## Design & boundaries

The complete agreed game design is [docs/GAME_DESIGN_DOCUMENT.md](docs/GAME_DESIGN_DOCUMENT.md).

**Not in v0.5:** physical coin storage, player-to-player trading, NPC-company economic simulation, random equipment affixes, deep crafting, and detailed multi-location rotations. Their absence is deliberate: the current release validates the expedition management economy first.

**Balance is provisional.** We still need real playtesting to learn whether hiring, tool upgrades, wages, and permanent losses make for a rewarding slow grind.
