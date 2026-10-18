# Money Mercs

> **Design reference:** [Living Game Design Document](docs/GAME_DESIGN_DOCUMENT.md) — the agreed long-term vision, decisions, open questions, and implementation roadmap. This is the reference for upcoming features; the prototype described below is v0.3.

A dark-fantasy mercenary contractor / resource economy management game built with **Godot 4.5.1**.

**Version 0.3 (Harlow Mines foundation):** A new interactive expedition dossier is available from the navigation rail. It integrates rotating ore deposits, permanent guild scouts, role-specific mining and guarding, live risk forecasts, individual casualties and persistent expedition records. Existing sites remain available under **Other Sites** using older prototype rules.

**The visual design is a work in progress.** This release is a usability/playtest baseline—not final art, an approved UI, or a complete Trading Post.

**Design update (GDD v1.2):** Gold is now the intended **primary trading currency and wealth measure**, with physical coin stacks, money bags and limited-capacity treasury chests. Rare items remain exceptionally valuable *in gold*. These storage mechanics are **planned, not yet implemented** in the v0.3 prototype; its existing gold balance is still numeric.

## Starting out

1. Clone with [GitHub Desktop](https://desktop.github.com/) or `git clone https://github.com/wiings3/Money-Mercs.git`.
2. Import `project.godot` in **Godot 4.5.1** and run **F5**.
3. In **The Office**, open **The Crew** and select **Recruitment Board**.
4. Hire Garrick (70 gold, Miner) and ideally Oswin (185 gold, Guard), then open **Harlow Mines**.
5. Dispatch your separate invulnerable guild scout (60 seconds at tier 1), read the report, then assign your miner and guard.
6. Set Cautious, Balanced, or Deep Push orders and dispatch. A successful party extracts a finite number of ore veins; underprepared workers may die and lose their gear. The expedition continues when you close the game. Read the return in **The Journal** and sell loot through **The Exchange**.

## Navigation

| Screen | Use |
|---|---|
| 01 The Office | Your company at a glance, active work, expansion and next steps |
| 02 Harlow Mines | Rotation-specific scouting, ore intel, crew assignments and expedition risk planning |
| 03 Other Sites | Legacy expedition destinations (temporary prototype rules) |
| 04 The Crew | Current roster, recruitment, equipment, injuries and negotiated agreements |
| 05 The Exchange | One resource list with your vault, unit prices and trade actions |
| 06 The Journal | After-action reports and the cost of each expedition |

Press **1–6** for the associated screen. The main work area scrolls; the detail/decision panel stays beside it.

The illustrations are procedural and drawn in Godot; there are no placeholder stock assets or external image dependencies. `scripts/main.gd` is the entirely new presentation layer, with `scripts/ui_art.gd` providing region scenery and mercenary portraits.

## Mechanical systems preserved

- 350 gold starting capital and six authored hires.
- Negotiable wage-vs-share contract structures and mercenary experience, wounds, and equipment upgrades.
- Three legacy regions with risk, specialist bonuses, reputation gates, different drop tables, and varying lengths.
- Harlow Mines with four-hour test rotations, copper/iron/silver/occasional crystal deposits, scouting, and miner/guard role composition.
- Real permadeath at Harlow: deceased mercenaries and equipped upgrade tiers are removed; reports include casualties.
- Cautious / Balanced / Deep Push orders; 1–3 crew; prepaid mission wages and provisions.
- Offline progress calculated from saved timestamps and recorded exactly once when you reopen.
- Eight collectible resources (including Copper), evolving NPC prices, merchant spread, and rare expedition-only finds.
- Three expedition slots at most, unlocked through investment.
- Auto-saved company file `user://money_mercs_save.json`.
- In debug builds only, tools to skip 15 minutes and reset the save in two steps from The Journal.

**Prototype economy caveat:** Mercenary commissions are settled in gold against the assessed gross haul, including materials retained in the stash. Gold can be negative until you've sold enough materials to cover commissions. Timers and progression are deliberately compressed for testing.

## Testing and changes

GitHub Actions verifies script import, scene boot, economy smoke tests and interactive navigation through the legacy screens, plus a dedicated Harlow Mines scouting-and-dispatch integration test. The CI-only UI test also recruits and dispatches a mercenary, simulates a return, and opens market and report views.

This remains a **single-player prototype**. Online marketplaces and competition should be server-authoritative before any actual trading between players, and can only follow playtesting the local economy.


## Harlow UI playtest goals

Judge the information hierarchy and decision-making flow, not just the calculations:

- Can you immediately find the scout action and see when its report will return?
- Once scouted, can you identify the confirmed ore and threat at a glance?
- Can you compare one miner + two guards against two miners + one guard with clearly separate extraction capacity, mission success, and per-worker casualty risk?
- Are the cost, standing orders, permanent-loss warning, and dispatch action all apparent?
- Do injury, death, resources recovered, gold earned and gear lost make sense in the post-expedition journal?

**Known limitations:** The appraised casualty risk is an estimate, not a guarantee; the simple current mining resolver favors copper before rarer ore when splitting capacity. Harlow currently uses the existing numeric gold balance; the physical coin stacks and treasury from the v1.2 design remain planned. Real desktop visual review is still required to reach the intended UI quality bar.
