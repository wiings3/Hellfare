# Money Mercs

**Version 0.21 — Fishing, hunting, farming and foraging**

Money Mercs is a Godot 4.5.1 fantasy mercenary-company and gold-economy management game. Its first interactive vertical slice is **Harlow Mines**.

> *Build a fortune. Let someone else risk their life.*

## Play

1. Pull `main` or clone https://github.com/wiings3/Money-Mercs
2. Import `project.godot` in Godot **4.5.1**. Run with **F5**.
3. Visit **Mercenaries**; hire Garrick (Miner) and ideally Oswin (Guard). The recruitment board refreshes with replacement applicants every 30 minutes.
4. Open **Mercenaries → The Armory** to buy tools and armor, select a worker, and equip their loadout. Then open **Harlow Mines** and send the scout (about 60 seconds).
5. Read the current rotation's findings, select miners/guards, choose standing orders, then fund the expedition.
6. Gathered ore and discovered equipment enter company inventory. Dead workers permanently lose their personal gear; surviving workers may be injured. The **Chronicle** shows encounter events and financial results.

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
