# MONEY MERCS — Living Game Design Document

**Version:** 1.2 · **Date:** October 18, 2026 · **Engine:** Godot 4.5.1  
**Genre:** 2D, UI-first dark-fantasy mercenary management and economic simulation  
**Repository:** https://github.com/wiings3/Money-Mercs

> **Build a fortune. Let someone else risk their life.**

**One-sentence pitch:** Build a mercenary company, scout rotating dangerous locations, send specialized workers to collect valuable resources, and participate in a living market where other companies need the gear you produce—and a skilled trader can become fabulously rich without ever dispatching a team.

### How to read this document

- **DECIDED:** A direction we've explicitly agreed belongs in the intended game.
- **PLANNED / VALIDATE:** A discussed feature or approach that requires prototyping before becoming a fixed implementation.
- **OPEN:** Details such as exact timing, percentages, names, or scope that are not yet settled.
- **IMPLEMENTED v0.2:** A feature present in today's playable prototype; it may be temporary scaffolding rather than the intended final mechanic.

**Important:** Illustrative numbers, region names, scout timings, and item prices are **not final balance commitments**.

---

## 1. Game identity and design pillars

**DECIDED — UI/UX is a primary gameplay system, not a finishing step.** Because virtually every meaningful action happens through an interface, visual clarity, interaction quality, readable item comparisons, tactile trade feedback, and the presentation of risk and rewards are core to whether the game is fun. We will design and validate UI alongside every major mechanic, not postpone serious polish until the final milestone.

**DECIDED — Money Mercs is NOT an ARPG.** We are building a resource and fantasy-economy management game, not controllable dungeon combat. Adventures take place through mercenary planning, scouting, real-time expeditions, and reports. The game must stay realistic for a solo developer working in Godot.

The central objective is **accumulating wealth, measured in gold**. A brand-new player should not be able to install the game and become wealthy or fully powerful in two hours. Becoming rich should require sustained grinding, clever decisions, risk management, economic knowledge, and long-term investment.

Two core inspirations shape the design:

- **Path of Exile 2:** extremely rare and genuinely useful discoveries deliver jackpot moments and long-term aspirational loot, **without** adopting a multi-currency economy. Money Mercs' primary and universal denomination remains gold.
- **Dark and Darker's physical gold storage:** coins, filled money bags and chests make an abstract number feel like a growing hoard that actually consumes storage space.
- **Dark and Darker's ORIGINAL player Trading Post:** live classified advertisements, inspectable items, bargaining, mispriced equipment, and profitable flipping can be a complete game for someone who enjoys economics more than dungeons.

The game has three overlapping player identities, **not exclusive classes**:

| Playstyle | Main pleasure | Economic contribution |
|---|---|---|
| **Contractor** | Hire, prepare, risk and develop mercenary teams | Generates ore, valuables, and dropped gear |
| **Craftsman** | Acquire materials and produce useful specialized gear | Consumes materials and provides equipment |
| **Merchant** | Spot undervalued items, negotiate, flip, speculate | Connects buyers and sellers; provides liquidity |

**DECIDED:** A player who rarely or never sends an expedition must still be able to become wealthy through trading. Those who love expedition management must also have an entire satisfying playstyle.

**Design guardrails:** no effortless idle riches, no random meaningless currencies, no replacing gold with an elite currency as the primary pricing standard, no universal price label that gives away every bargain, no action-game scope explosion, no online economy dependent on thousands of active users.

---

## 2. The two simultaneous gameplay loops

### Active company management — DECIDED

An active session should contain meaningful decisions: hire personnel, negotiate contracts, compare equipment, plan teams, assess scouting information, choose retreat orders, sell and buy resources, craft, invest in infrastructure, appraise unusual item rolls, browse advertisements, negotiate deals and flip bargains.

**The player's own knowledge** should matter. Recognizing that an odd combination of item properties is exceptionally valuable to a mining company is a form of progression.

### Offline expeditions — DECIDED

Players **explicitly fund and send** expeditions. Missions continue to run against real time after the game closes and obey their preselected standing orders. They settle exactly once and produce reports on return. Offline play does **not** generate unlimited resources without assignments, funds or supplies, and staying online is not required to hit a retreat button.

**PLANNED:** Several concurrent teams, production queues, and a balanced cadence of short and long operations. **OPEN:** how much active play should outperform passive collection without turning the game into compulsory micromanagement.

---

## 3. Rotating expedition locations

**DECIDED:** Each region has a permanent thematic identity, but the specific resources, amounts, threats, hazards and possible loot **rotate**. Harlow Mines remains a mine; it could contain mostly copper one rotation, iron and silver another, or an uncommon crystal seam another. Appropriate goblins, wolves, spiders or dangerous underground monsters may appear in changing combinations.

**DECIDED:** Resources are **finite during a rotation**. If a location has six known copper veins and your crew extracts three, those veins are depleted for that company's current rotation. Additional unknown deposits may exist.

**DECIDED:** Reports belong to particular rotations and become stale when conditions change; a new rotation can require new scouting. Already-dispatched expeditions keep a snapshot of the conditions in which they began.

**PLANNED:** Shared timed world rotations with **per-company finite deposits** at first, so the earliest players online cannot empty every public mine for everyone else.

**OPEN:** duration and specifics. A **4–6-hour rotation** was floated, not locked. Regional resource weights, rarity, public versus private sites, exact expedition size, and reset behavior need testing.

### Illustrative Harlow Mines rotation

| Rotation | Possible findings | Example threats |
|---|---|---|
| A | 6+ copper veins | Sleeping Dire Wolf |
| B | Iron and limited silver veins | Goblin raiders |
| C | Abundant copper | Cave spiders |
| D | Iron and a rare crystal seam | Cave Troll |

These are examples of themed variation, not finalized generated tables.

---

## 4. Scouting as an independent system

**DECIDED:** Scouts are **not mercenaries**. They are permanent company assets that **cannot die**, do **not harvest resources**, and **always return with some useful intelligence**. They are upgradeable for **faster return times** and **better/more information**.

**DECIDED:** You do not initially know a rotation's exact deposit count and dangers. You can send a scout—or skip scouting and deliberately accept more uncertainty.

**Canonical example:**

> **Harlow Mines — Scouting Report**  
> At least **6 copper ore veins** observed.  
> **Sleeping Dire Wolf** seen near the eastern tunnel.  
> Additional passages remain unexplored.

**At least six** is not an omniscient promise that only six exist. Better scouts may find additional veins, hazards, enemy counts, approximate threat level, or rare-find clues. The scout must always return with something.

**PLANNED / VALIDATE:** Basic scout return in roughly **60 seconds**, upgrades to shorter times (e.g. 40, then 25 seconds) and richer intelligence. **OPEN:** exact levels, costs, concurrency, whether intel can be traded.

Scouting should create a distinct decision: *Is additional information worth delaying this deployment?*

---

## 5. Mercenary specializations & party composition

**DECIDED:** Mercenaries are **functional specialists**, not equivalent blobs of combat power.

**Miners** determine how much ore a team can extract. **Guards** protect against combat and reduce the risks faced by miners. Initially, prove the game with just these roles; other mercenary professions should exist only if they introduce additional genuine decisions.

**Core Harlow Mines trade-off (illustrative, not universal odds):**

| Crew | Potential copper extraction | Example full-success estimate |
|---|---:|---:|
| **2 miners, 1 guard** | Up to 6 veins | 60% |
| **1 miner, 2 guards** | Up to 3 veins | 90% |

A bigger mining party can return more ore, but exposes expensive people and equipment. More guards increase safety at the cost of work capacity. Neither strategy should be universally correct.

**DECIDED:** Individual mercenaries can develop experience, wear equipment, become injured, and require treatment. Gear and skills have real effects on their ability to gather, protect and survive.

**PLANNED / VALIDATE:** Wage + negotiated loot-share contracts. Different workers may value guaranteed salary differently from a high percentage of recovered value; veterans may demand better compensation. Keep the mechanic economically meaningful instead of making negotiation a repetitive click minigame.

**OPEN:** exact contract terms, how to settle commissions on indivisible rare items, and how to avoid negative cash/debt trapping a small company. The v0.2 accounting rule is not automatically the final design.

---

## 6. Expeditions, standing orders & permanent death

### Permanent loss — DECIDED

**Mercenaries absolutely can die, permanently.** If an under-skilled mercenary enters a dungeon beyond their capabilities, death should be a real possibility. A dead mercenary's **equipped gear is permanently lost**, as is that person's future experience and usefulness. There is **no automatic replacement** or guaranteed gear recovery.

Preparation must meaningfully affect the risk. Well-prepared high-level mercenaries should not routinely die in trivial encounters due to arbitrary hidden rolls. If a player dispatches someone woefully unprepared, they should be allowed to make that mistake **with an understandable warning**.

### Separate success, survival and capacity — DECIDED

An expedition is **not** a simple success/failure coin flip. Separately calculate:

- How much work the party can perform (miners, tools, time, deposits).
- Threat encounters, ability to retreat, and whether the objective is completed.
- Each mercenary's survival, injury or death.
- Which resources were actually extracted and carried home.
- Gold found, commission/wages/supplies spent, damaged or lost gear, and net result.

A team can **win the objective but lose money** because it lost a veteran and expensive equipment. A failed objective may still see survivors return with a partial haul.

### Standing orders — DECIDED IN PRINCIPLE

A set of clear orders governs teams **online and offline**:

| Example policy | Strategy |
|---|---|
| **Preserve the crew** | Withdraw quickly, sacrifice potential yield to protect people |
| **Balanced** | Attempt the job but avoid escalating danger |
| **Whatever it takes** | Push for more resources, accept far higher loss risk |

The three names and effect sizes are provisional; distinct loot, casualty and retreat consequences are the real requirement.

**PLANNED:** A company memorial recording the names, service histories and locations where workers died. **OPEN:** exact death odds, individual encounter modeling, salvage as an extremely rare exception, and full economic balance.

### Reports — DECIDED

After each dispatch, report: rotation, discovered resources and enemies, vein depletion, objective outcome, every crew member's survival/injury/death, equipment lost, gross haul, actual **liquid gold**, wages, commissions, treatment/repair, and **net economic result**. Avoid conflating cash with stash-appraised value.

**Recovery rule:** never create an irreversible financial softlock. Inexpensive workers, lower-risk work and basic recovery options must always exist.

---

## 7. Gold, physical wealth, rarity, itemization & crafting

### Gold is the economy's primary measure — DECIDED (revised v1.1)

**Gold is the primary, universal money of Money Mercs.** Hire mercenaries with gold, pay expedition expenses in gold, negotiate prices in gold, and measure company fortunes in gold. We are **not** designing a Path of Exile-style alternative high-tier currency standard. We want to look at a treasury or ledger and immediately understand how rich someone is.

**Very rare equipment, relics, and crafting materials still exist** and can be obscenely valuable, but they are **goods priced in gold**, not an obligatory alternative denomination. Their excitement comes from scarce supply and real use. The prototype's **Sovereign Orb** is a placeholder rare crafting ingredient; its current “top-tier currency” label is superseded by this decision, and we may rename or repurpose it during itemization work.

A player can be asset-rich but short on spendable gold: an extraordinary sword worth an estimated 30,000 gold is not the same thing as actually having 30,000 gold to pay wages. Keep this distinction visible.

### Gold physically occupies storage — DECIDED

**Gold is a tangible item resource, not merely a weightless on-screen number.** Coins are grouped into stacks, money bags and eventually chests, with **finite storage space**. The fantasy is opening your treasury and seeing money bags pile up, as in Dark and Darker. Wealth growth should have a visual and logistical footprint.

The core intended experience:

- Starting companies have a small stash and limited space for gold, equipment and materials.
- Gold accumulates in **physical stacks/bags** occupying inventory or treasury slots; a larger bag may hold more coins per slot.
- **Money bags and treasury chests** are valuable infrastructure upgrades, not just decorative icons. Storage-efficient containers become meaningful expenditures.
- Players can open the treasury, inspect actual stored cash, move/organize money bags, and visually appreciate growing wealth.
- Trading, wages and other payouts consume **actual available gold** and must not duplicate it; the UI displays gold totals as a convenience **derived from the real stored stacks/containers**.
- UI should separately show **spendable gold**, **estimated value of other assets**, **total estimated net worth**, and **vault capacity/usage**. Net worth is a gold-denominated estimate rather than guaranteed liquidation proceeds.

**Critical usability principle:** physical gold should feel satisfying to manage, **not** force a tedious coin-by-coin process. Automatically stack incoming coins and make ordinary payments convenient; reserve intentional packing, expansion, inventory organization and large-value transport for meaningful decisions.

**PLANNED / VALIDATE:** Multiple sizes of coin stack, bags and storage chests; treasury upgrade paths; a clear money-bag/chest visualization; potential trading or transportation consequences of bulky sums.

**OPEN:** exact stack capacities, bag/chest sizes, whether bags can be bought or crafted, if money and equipment share all storage, how the player handles overflow, and whether remote trade settlement uses a secure treasury/escrow system. Rewards must never be silently deleted just because storage is full; consider a claim queue or arrivals depot while testing. The player should not be able to bypass storage through an unrestricted invisible wallet.

### Rare loot, itemization and crafting

The overriding loot rule is unchanged: rare gear should still create jackpot moments, and rare consumables should still be demanded by players. **All normal trade prices are denominated in gold.**

**DECIDED:** Equipment matters because of the work it enables. Different buyers value different stat combinations. A mining specialist might prize a tool with ore yield, mining speed, rare-find chance and expedition-duration bonuses; a ruins company may value it far less. This imperfect price discovery makes underpriced items possible.

**PLANNED:** Collect raw materials, craft and modify equipment, and consume useful currencies/materials through upgrades and production. High-value items should require real investment and have reasons to disappear from circulation (at minimum, mercenary death).

**OPEN:** equipment slots, exact affix pools, rarity tiers, crafting outcomes, durability outside death, identification and high-end currency names.

**No premature power spike:** Day-one resources and early drops should not let anyone leap straight to endgame. Working capital and risk should matter across many sessions.

---

## 8. The original-style Trading Post

**DECIDED DIRECTION:** Market play is a centerpiece, inspired particularly by the **original pre-redesign Dark and Darker Trading Post**, not just a faceless instant-buy auction board.

Experience goals:

1. Observe a live scroll/feed of offers (potentially categorized channels).
2. Inspect a seller's individual gear and all meaningful modifiers.
3. Recognize a valuable combination or an underpriced listing.
4. Initiate a direct offer or bargain with the seller.
5. Exchange **physically owned gold** and items with explicit, secure confirmation; the UI can draw payment from the treasury without tedious manual coin dragging.
6. Resell, supply the correct buyer, or keep the item for company use.

A trader can make a fortune without personally going on expeditions. **Large flips are especially important** to the desired feeling, while repeated smaller trades remain a viable approach.

**DECIDED:** Negotiated prices and asking prices use **gold**. Do not show a perfect authoritative valuation on every listing. Appraisal knowledge is the skill: someone's low ask can be a great opportunity because the true buyer value depends on use cases and demand.

**PLANNED / VALIDATE:** Trade channels, linking items in messages, offers, fees, basic sorting/filtering, saved searches, market trends and price research. Avoid automation, perfect price estimates or instant execution tools that remove human price discovery.

**Safety and fairness when multiplayer arrives:** trade locks and atomic confirmation, no item-switch trickery, anti-duplication rules, anti-bot controls and meaningful access for newer participants.

---

## 9. Why the economy exists: production, consumption & item sinks

The merchant fantasy only works if *other participants are generating items and actually need them*.

**DECIDED:** Contractors generate supply by taking risks, craftsmen consume resources to produce useful gear, and both purchase equipment to improve their operations. Mercenary death removes equipment from circulation and creates **replacement demand**. The market is not just a group of people passing the same item around forever.

An illustrative trade journey:

- A mining tool is discovered by a ruin-focused contractor.
- They need cash to finance wages, so they list it below its likely value.
- A knowledgeable merchant buys it and later resells it for more.
- A mining-focused buyer pays for it because it raises expected mine productivity.
- It eventually leaves circulation through equipment loss, sustaining demand for replacements.

**PLANNED / VALIDATE:** More sinks through crafting consumption, upgrades, wear and supply costs if needed. Avoid inflation, mass saturation and a small set of merchants permanently controlling all opportunities.

---

## 10. Simulated companies & asynchronous multiplayer

### The chicken-and-egg problem — DECIDED

A functioning player-driven economy normally requires a large population performing expeditions, crafting, buying and using gear. We cannot assume this game launches with that population.

**DECIDED DIRECTION:** Simulate a believable market using **identifiable NPC companies** from the start. They are not bots masquerading as real users. Give them funds, inventory, specializations, expedition activity, equipment needs, production costs, and urgent reasons to buy/sell.

| NPC company type | Main economic role | Why a deal could appear |
|---|---|---|
| Mining company | Sells ore, buys tools and guards | Needs operating cash now |
| Ruin expedition company | Finds artifacts and miscellaneous gear | Doesn't recognize mining-tool demand |
| Forge | Consumes ore and rare materials; produces gear | Needs to clear inventory to buy inputs |
| High-risk delving company | Finds uncommon loot, burns expensive gear | Sells surplus after costly losses |

**PLANNED:** The NPC market should produce imperfect pricing and bargaining opportunities without providing an endlessly repeatable guaranteed exploit. Demand, supply and item destruction should follow from these companies' simulated actions.

**PLANNED:** Eventually connect real players in an **asynchronous shared trading economy**; their market actions and equipment consumption shape demand. Possible later indirect competition: public contracts, bids, prestige, rankings and specialist business strategies. These optional competitive systems are **not locked**.

**Technical constraint:** Shared item ownership, trade settlement, expedition results, clocks, currency and rotation snapshots must be **server-authoritative**. The existing Godot local saves are only for prototyping.

---

## 11. User experience & visual direction

**DECIDED:** A 2D UI-first dark-fantasy contractor-management presentation. The player's decision process should be simple to understand even when the underlying economy becomes deep.

Core intended areas:

1. **The Office** — treasury, cash flow, recent outcomes, teams waiting for instructions.
2. **Regional board** — rotations, scouted intel, unknown hazards, finite deposits and availability.
3. **Scout desk** — scout upgrades, send scout, compare reports and rotation freshness.
4. **Mercenaries** — recruit, equip, treat, negotiate, assign, memorialize losses.
5. **Expedition planner** — miner capacity versus guard protection, cost, timing, distinct success and survival estimates, standing orders, gear at risk.
6. **Trading Post / Vault / Treasury** — inspect unique equipment and modifiers; trade-feed, haggle and settle in gold; store physical coin stacks, money bags, chests and other inventory in limited space; show spendable gold versus estimated net worth.
7. **Journal** — after-action reports, casualties, economic results, and history.

### UI excellence is a product requirement — DECIDED

The interface should aim for an exceptional, cohesive experience from the first interactive build. No one can guarantee a universally "perfect" interface in advance; the standard is to **keep iterating based on real use until both appearance and usability are excellent**. A feature is not finished if it works internally but feels clumsy to operate.

**Experience principles:**

1. **Information at the point of decision:** Scouting reports show confirmed findings and uncertainty; expedition planning shows mining capacity, guard coverage, expected yield, survival risk, gold at risk and consequences together. No hunting across unrelated screens.
2. **Immediate visual comprehension:** Make status, rarity, risk, profit, loss, affordances and resource capacity scannable at a glance. Layer advanced details behind deliberate inspection, not walls of explanatory copy.
3. **Feel matters:** A rare item discovery, a winning flip, an arriving money bag, a returning scout and a fatality should have different, high-quality interaction feedback (visual state changes, animation, appropriate sound and clear reports). Tactile feedback should be restrained, not distracting.
4. **The market is a first-class interface:** Fast linked-item inspection, side-by-side modifier comparisons, readable live advertisements, negotiation and secure confirmation should be satisfying for someone who spends hours trading.
5. **A real treasury:** Distinctive coins, bags, chests, stash arrangement and capacity visualization make gold feel physically owned. Keep routine payment automatic; avoid tedious manual micromanagement.
6. **Professional visual system:** Consistent typography, spacing, color semantics, iconography, item art, layouts, hover/focus/disabled states, transitions and tooltips. A strong dark-fantasy aesthetic must never compromise legibility.
7. **Accessible and robust:** No clipped menus, tiny click targets, unreadable text, ambiguous color-only status or accidental destructive actions. Test different supported window sizes and scales, and keyboard/mouse workflows.
8. **Consistency across screens:** Keep navigation, back paths, notifications, selection state and money figures trustworthy. Changing tabs should not silently discard plans or obscure critical context.

**Development standard for each gameplay slice:** First define the player's goals and the information needed; sketch/wireframe the interaction; establish the visual states; build the interface *with* the mechanic; test real tasks in Godot at target sizes; revise until it feels good. Treat visual and usability review as a requirement for acceptance, not an optional art pass. Do not do endless speculative redesigns detached from actual playtesting.

**Quality gates for the initial Harlow Mines interface:**

- A first-time player can locate the scout action, recognize a current versus stale report, and understand what information is unknown.
- The 2-miner/1-guard versus 1-miner/2-guard tradeoff is legible **without opening several screens**; percentages are clearly labeled (objective success is not mercenary survival).
- The player knows the exact upfront gold cost, equipment exposed to loss, remaining deposit capacity, order selection and dispatch confirmation.
- Returning reports distinguish collected resources, casualties, lost items, remaining veins, cash flow and appraised net results.
- Loading, empty, busy, unaffordable, locked, expired and error states are deliberately designed; no dead buttons, broken scroll, clipping or layout collisions.
- Screens are visually inspected at the intended desktop window size and at a smaller supported size. Automated headless tests alone do not prove visual quality.

**IMPLEMENTED v0.2:** A first replacement management interface exists, but its presentation is **not approved as final**. Future UI work should be evaluated against the principles above. We do not have to freeze the current interface to make progress on mechanics.

---

## 12. The defining vertical slice: Harlow Mines

**Goal:** demonstrate why this is a *management game*, not a disguised timer game.

1. A new rotation changes Harlow's actual ore veins and encounter risk.
2. The player sends a safe scout, which returns with *at least* six copper veins and a dangerous Dire Wolf sighting.
3. The player compares **2 miners + 1 guard** versus **1 miner + 2 guards**.
4. The first can extract more but has a sample **60%** full-success chance. The second works fewer veins but has a sample **90%** chance.
5. The player accounts for wages, expensive gear, probability of individual death, and expected net proceeds.
6. They set standing orders and dispatch. No manual intervention is required while offline.
7. The report states who lived, who died, what equipment was lost, how much was mined, how much remains, and whether the operation was actually profitable.
8. Recovered copper/gear may be sold, crafted into useful equipment, or hoarded for future operations.

**Caution:** 60/90 percent, six/three veins, and 60-second scout timings are **illustrative scenario numbers**, not final mechanical constants.

**Milestone passes if:** more miners versus more guards is a situationally difficult, financially grounded decision with real casualties and limited resources—not a solved rule every player uses every time.

---

## 13. Roadmap (priority, not release deadlines)

| Milestone | Features | Proof of success |
|---|---|---|
| **A0. Harlow UI foundation** | Visual direction, component styles and interaction prototype for scout reports, expedition planning, crew selection, loss warnings and results | Information is beautiful, legible and immediately actionable; tested in a real Godot window |
| **A1. Harlow vertical slice** | Implement rotations, finite ore, upgradeable scouts, miners, guards, dangerous encounters, permadeath, gear loss and offline reports through that interface | Interesting crew composition, comprehensible risk decisions and excellent interaction flow |
| **B. Real item economy + tangible gold** | Unique equipment, modifiers, crafting and sinks; coin stacks, money bags, treasury slots and gold-only pricing | Valuable goods have buyers and wealth feels physical, measurable and limited by storage |
| **C. Simulated trading world** | NPC firms with budgets and inventory, production/consumption, bargaining feed and profitable flipping | Market-only play is fun with one human player |
| **D. Online shared market** | Server-authoritative items and transactions, real players, safe P2P settlement | Economy functions at small and large populations |
| **E. Depth & longevity** | More regions, firms, roles, gold/resource sinks and specialized contracts; continued UI refinement | Days/weeks of meaningful earned progression without sacrificing presentation quality |

**UI/UX quality is a cross-cutting requirement for every milestone above, not a phase reserved for the end.** Keep the build small enough for one developer. Expanding content before validating the earlier loop is explicitly **not** the plan.

---

## 14. Current implementation versus intended systems

**Already implemented in v0.3:** Godot management UI and an interactive **Harlow Mines dossier**: rotation-specific copper/iron/silver/occasional crystal deposits, a separate persistent guild scout with three upgrade levels, scout reports that expire on rotation, miner/guard team selection, role-based ore capacity and success forecasts, dangerous encounters, individual injuries/permanent deaths with gear loss, stored expedition reports and offline resolution. The original three static regions still use v0.2's older simple expedition system. Recruitment, itemless equipment tiers, basic contracts, NPC trading, local saves and journal remain in place.

**NOT yet built / still immature:** full-scale multi-region rotation, multi-resource targeting, deeper scout-report ambiguity, polished itemized equipment, physical gold stacks/bags/chests, a limited-capacity treasury, crafting as a true economy, simulated economic competitors, original-style trading, any real player marketplace, and approved finished visual/interaction quality. Harlow's **first** scouting, finite-mining, composition, and casualty implementation is playable but requires rigorous balancing and UX refinement.

**The v0.3 prototype still uses a numeric, effectively weightless gold balance and labels a Sovereign Orb as currency; those are legacy implementations, not the intended design.** Treat existing prototype timers, market prices, resources, and fixed success calculations as **scaffolding**, not established balance rules.

---

## 15. Decisions still open

1. **Scouting:** permanent single scout versus multiple scouts; upgrade cap, exact time, information clarity and reporting UI.
2. **Rotations:** exact schedule, shared versus instanced scarcity, deposit regeneration, public contracts.
3. **Expeditions:** precise capacity and encounter formula, partial success, individual death rates, injury, retreats, loot protection.
4. **Contracts:** fair wage/share negotiation and commissions on very rare indivisible finds.
5. **Items:** equipment slots, prefixes/suffixes, crafting breadth, modifier synergies, identification, durability and any recovery.
6. **Economy:** gold sinks and money supply, drop rates, consumptive demand, item sinks, market fees, valuations and trading UX; **gold remains the primary money**.
7. **NPC firms:** budgets, business objectives, urgency, imperfect knowledge, liquidity and anti-exploit design.
8. **Online:** back-end provider, trade/chat rules, bot protections and population scaling.
9. **Active versus offline:** sufficient on-demand decisions without mandatory login cadence.
10. **Gold storage:** stack/bag/chest capacities, upgrades, overflow handling, whether shared stash space is used, and how to keep high-volume market trades convenient and safe.
11. **Scope:** exact number of regions, professions, recipes and firms for first public release.

### Final product test

> **Can one person love running expeditions, another love crafting useful equipment, and a third become incredibly wealthy by spotting an underpriced item—because all three are operating inside the same believable economy?**

**That is Money Mercs — with every hard-earned fortune counted in gold and visible in a real, space-limited treasury.**

*This is a living design reference. Commit and update it as the game changes; do not promote example numbers to final decisions without playtesting.*
