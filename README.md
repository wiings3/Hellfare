# MONEY / MERCS
*A contractor gets rich. Mercenaries take the risks.*

A **Godot 4.5.1** UI-first prototype for a hybrid management/resource game. Hire mercenaries, negotiate their contract type, send them on timed expeditions, sell or stockpile the proceeds, and expand the company.

## Open and play

1. Clone this repository via **GitHub Desktop** (or `git clone https://github.com/wiings3/Money-Mercs.git`).
2. In **Godot 4.5.1**, import `project.godot`.
3. Run the project with **F6** while viewing the main scene, or **F5** for the project.

**First profitable expedition:** Start with 350 gold. Visit Mercenaries, hire Garrick (70 gold) and optionally Mara (110 gold), then open Expeditions, select Mossward Lowlands, assign the crew, and choose standing orders. Wages and supplies are charged upfront. The operation will return after its timer expires. Check your vault, ledger, and the marketplace for earnings; you'll often need to sell resources to turn them into spendable gold.

### Implemented in v0.1

- Headquarters dashboard showing liquid cash, estimated total company value, reputation and operations capacity.
- Six authored mercenary candidates; hiring, distinct roles, experience, injury/treatment and four equipment upgrades.
- Three contract structures: balanced, guaranteed wages, and higher profit share.
- Three regions, each with its own resource yield, length, threat, gates, and rare-drop table.
- One-to-three-person dispatch planning, risk strategy, payout forecast and standing orders.
- Resolves stored missions on return to the game using wall-clock finish times. Expired missions are settled once and generate a durable report.
- Inventory vault with seven distinct resources; basic NPC merchant prices that vary every six hours, with a buy/sell spread.
- Resource and gold sinks: hiring, operations slots, expedition funding, medical treatment, gear upgrades.
- A very rare Sovereign Orb that has actual endgame use: mythical-tier equipment requires one.
- Automatic JSON save under `user://money_mercs_save.json` after each meaningful action.
- Developer debug-build menu in Company Ledger: advance missions by 15 minutes for testing; optional two-click reset.

### Design notes / caveats

This is a playable **economy test**, not a finished game. No multiplayer, art production, or fully simulated competing contractors yet.

- Real time is respected even with the window closed. Expeditions must be explicitly dispatched: idle time alone never prints money.
- The mercenaries are paid **cash wages upfront** and a **percentage of the appraised entire haul** when returning. Rare whole-item finds are kept by the company, but the crew's commission is charged in gold. Your balance may temporarily go negative; sell resources to cover it.
- Mission length (75 seconds to 12 minutes) and reputation gates are intentionally compressed for the first feedback sessions. Long-term progression should be tuned only after testing.
- Offline simulation is **local and client-trusting** for the prototype. Before adding online trade/leaderboards, migrate accounts, expedition rolls, clocks and all monetary transactions to a server-authoritative backend.
- NPC merchants always buy resources at a discount; crafting consumes materials and can be more profitable than immediately selling. Rare relics and Sovereign Orbs cannot be purchased from NPCs in this prototype.
- Wealth figures are **estimates**, not an exploitable bank balance or score.

## File structure

```
project.godot              Godot 4.5.1 project configuration
scenes/main.tscn          Root game scene
scripts/main.gd           Responsive UI and player interactions
scripts/game_state.gd     Economy rules, RNG, persistence, expeditions
assets/icon.svg           Project icon
tests/smoke_test.gd       Non-destructive-on-local-machine smoke test (CI only)
.github/workflows/ci.yml  Godot headless parser and smoke test
```

## What's next

First we playtest whether the expedition decisions and profits feel fair. Next: meaningful item crafting, market supply/demand, automated rival contractors, better tooltips, and an authored 2D visual identity. Online competition comes **after** the offline game is compelling.
