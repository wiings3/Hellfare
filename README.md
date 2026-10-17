# Money Mercs

A dark-fantasy mercenary contractor / resource economy management game built with **Godot 4.5.1**.

**Version 0.2** rebuilds the entire presentation layer. The economic model and save data stay intact.

## Starting out

1. Clone with [GitHub Desktop](https://desktop.github.com/) or `git clone https://github.com/wiings3/Money-Mercs.git`.
2. Import `project.godot` in **Godot 4.5.1** and run **F5**.
3. In **The Office**, open **The Crew** and select **Recruitment Board**.
4. Hire Garrick (70 gold), then open **Expeditions**.
5. Select **Mossward Lowlands**; choose Garrick in the fixed right-side briefing panel and dispatch him.
6. The expedition continues when you close the game. Read the return in **The Journal** and sell loot through **The Exchange**.

## Navigation

| Screen | Use |
|---|---|
| 01 The Office | Your company at a glance, active work, expansion and next steps |
| 02 Expeditions | Illustrated region cards, active timers, contextual crew planner |
| 03 The Crew | Current roster, recruitment, equipment, injuries and negotiated agreements |
| 04 The Exchange | One resource list with your vault, unit prices and trade actions |
| 05 The Journal | After-action reports and the cost of each expedition |

Press **1–5** for the associated screen. The main work area scrolls; the detail/decision panel stays beside it.

The illustrations are procedural and drawn in Godot; there are no placeholder stock assets or external image dependencies. `scripts/main.gd` is the entirely new presentation layer, with `scripts/ui_art.gd` providing region scenery and mercenary portraits.

## Mechanical systems preserved

- 350 gold starting capital and six authored hires.
- Negotiable wage-vs-share contract structures and mercenary experience, wounds, and equipment upgrades.
- Three regions with risk, specialist bonuses, reputation gates, different drop tables, and varying lengths.
- Cautious / Balanced / Deep Push orders; 1–3 crew; prepaid mission wages and provisions.
- Offline progress calculated from saved timestamps and recorded exactly once when you reopen.
- Seven collectible resources, evolving NPC prices, merchant spread, and rare expedition-only finds.
- Three expedition slots at most, unlocked through investment.
- Auto-saved company file `user://money_mercs_save.json`.
- In debug builds only, tools to skip 15 minutes and reset the save in two steps from The Journal.

**Prototype economy caveat:** Mercenary commissions are settled in gold against the assessed gross haul, including materials retained in the stash. Gold can be negative until you've sold enough materials to cover commissions. Timers and progression are deliberately compressed for testing.

## Testing and changes

GitHub Actions verifies script import, scene boot, economy smoke tests and interactive navigation through all five main screens. The CI-only UI test also recruits and dispatches a mercenary, simulates a return, and opens market and report views.

This remains a **single-player prototype**. Online marketplaces and competition should be server-authoritative before any actual trading between players, and can only follow playtesting the local economy.
