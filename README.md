# Money Mercs

**Version 0.5 — The Price of Profit**

Money Mercs is a Godot 4.5.1 fantasy mercenary-company and gold-economy management game. Its first interactive vertical slice is **Harlow Mines**.

> *Build a fortune. Let someone else risk their life.*

## Play

1. Pull `main` or clone https://github.com/wiings3/Money-Mercs
2. Import `project.godot` in Godot **4.5.1**. Run with **F5**.
3. Visit **Mercenaries**; hire Garrick (Miner) and ideally Oswin (Guard). The recruitment board refreshes with replacement applicants every 30 minutes.
4. Open **Mercenaries → The Armory** to buy tools and armor, select a worker, and equip their loadout. Then open **Harlow Mines** and send the scout (about 60 seconds).
5. Read the current rotation's findings, select miners/guards, choose standing orders, then fund the expedition.
6. Gathered ore and discovered equipment enter company inventory. Dead workers permanently lose their personal gear; surviving workers may be injured. The **Chronicle** shows encounter events and financial results.

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

**V0.4's visual design remains in place**, with gameplay-driven screens added to the Mercenary and Chronicle pages. See the latest [Harlow screenshot](docs/ui_harlow_preview.png), [Armory screenshot](docs/ui_armory_preview.png), and [Journal screenshot](docs/ui_journal_preview.png). These are rendered by Godot, not mockups.

## Controls

Use the top tab bar or shortcuts **1–6**. Saved progress lives at `user://money_mercs_save.json`. Developer builds have a two-step company reset and time-skip action under The Chronicle.

## Design & boundaries

The complete agreed game design is [docs/GAME_DESIGN_DOCUMENT.md](docs/GAME_DESIGN_DOCUMENT.md).

**Not in v0.5:** physical coin storage, player-to-player trading, NPC-company economic simulation, random equipment affixes, deep crafting, and detailed multi-location rotations. Their absence is deliberate: the current release validates the expedition management economy first.

**Balance is provisional.** We still need real playtesting to learn whether hiring, tool upgrades, wages, and permanent losses make for a rewarding slow grind.
