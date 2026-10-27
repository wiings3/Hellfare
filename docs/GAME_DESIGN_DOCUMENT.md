# HELLFARE — Living Game Design Document

**Version:** 2.0 · **Date:** October 27, 2026 · **Engine:** Godot 4.5.1
**Genre:** 2D dark-fantasy guild management with hands-on crypt crawls, and a gold economy
**Repository:** https://github.com/wiings3/Hellfare

> **Build a fortune. Let someone else go down for it — or go down yourself.**

**One-sentence pitch:** You run a guild of Hellfarers from Last Lantern, the last town before the
Maw: crews go down into hell for timber, ore and stranger things while you trade what they bring
up, and your heroes fight through the crypts below — on their own, or with you leading them.

### How to read this document

- **DECIDED:** agreed direction for the game.
- **BUILDING:** decided and being implemented in the current update (v0.33, "Heroes").
- **VALIDATE:** decided in principle; needs a playtest before it's fixed.
- **OPEN:** not settled.
- **PARKED:** an earlier idea we are not pursuing now (kept so it isn't lost).

Numbers in this document are starting points for tuning, not commitments.

Version 1.x of this document described Money Mercs (scouts, Harlow rotations, a trading-post
feed). What still holds is carried over below; what doesn't is in §12 (Parked).

---

## 1. What we learned (October 2026) and what changed

The game had many working, connected systems — crafting, gear, wear and repair, a moving market,
an auction house, crypts, permadeath, offline crews — and a **poor first hour**:

1. **The opening was a waiting game.** A new player hired one woodcutter, sent them on a
   five-minute trip, and had nothing to do until they came back. Then they did it again. The deep
   systems sat hours away behind that loop.
2. **Gear stats meant nothing to the player.** Weapons roll crit, damage, penetration, speed; the
   crypt fight used them, but the player never saw a hit. At trade sites a guard's weapon didn't
   count at all — protection came only from how many guards were sent. Nobody could tell why a
   +10% crit sword should cost more than a +5% one.
3. **Depending on other players for the economy is the riskiest bet.** A player-run market needs
   a population a new indie game rarely has at launch.

**DECIDED answers:**

1. **Heroes** you can lead yourself through the crypts, in a turn-based side-on crawl, while your
   crews work. The wait becomes the time you spend below.
2. **Only heroes wear weapons and armour**, and you watch them fight, so every stat is visible
   in play and in every report. Classes make different stats matter to different heroes.
3. **NPC merchants stay as the floor of the economy**; real players are layered on top later
   (§9).
4. **A prologue** that shows the late game and gives the player a reason to start from nothing.
5. **A first hour designed minute by minute** (§7): short early trips, systems that open as
   answers to problems, and a hook for tomorrow.

The guardrail from 1.x still holds, revised: **Hellfare is not an action game.** The hands-on
crawl is turn-based, uses the same rules as the automatic one, and is small enough for one
developer.

---

## 2. Pillars — DECIDED

1. **Run a guild, not a character.** You hire, equip, send and trade. Even when you lead a hero
   below, you are the guild's master leading its champion.
2. **Two loops at once.** Crews earn on the trade sites in real time (also while the game is
   closed). Heroes clear crypts — led by you, or alone by their orders. Both are always possible
   at the same time.
3. **Every number shows itself.** If a stat exists, the player sees it change an outcome: on the
   crawl screen, in a forecast, or in a report.
4. **Loss is real.** Mercenaries and heroes die permanently. Their gear stays below (some of it
   for others to find) or is ruined. Nothing is replaced for free.
5. **Gold is the measure.** Everything is priced in gold; rare things are goods, not currencies.
6. **The interface is part of the game.** The book UI is the game's face; clarity and feel are
   requirements, not polish.

---

## 3. The world and the story — DECIDED

**Last Lantern** is the last town before **the Maw**, a wound in the earth that opened onto hell.
Below are five layers, each with its own light: **the Ashen Verge** (ember), **the Weeping Fens**
(blood red), **the Brimstone Reach** (fire), **the Frozen Lament** (frost) and **the Abyss**
(violet black). At the bottom, on the Throne Below, is **Death**.

**The prologue (BUILDING).** The game opens on the guild at its height: famous, rich, deep in the
Brimstone Reach. Its champion, **Ser Aldren Vane**, the Lantern's Blade, is the strongest hero in
the town's history, and the player leads him through one fight with great gear — big crits,
armour shrugging off blows. At the end of it Aldren kneels to something in the dark and
**betrays the guild**: he takes its seal, its strongroom and its charters down with him and
becomes **Death's First Blade**. The player wakes in Last Lantern with an empty hall and a few
coins.

**The long goal.** Aldren waits as one of the final bosses in the last crypt, the one before
Death himself. Rumours of him (his crew, his crest on things found below, rival crews working
for him) run through the game.

**OPEN:** whether the townsfolk's name for Death is "the Ashen King" (the name used in earlier
writing); Aldren's final name; the name the player gives their new guild.

---

## 4. Heroes — BUILDING

- **A hero is not a mercenary.** Heroes have their own page, their own slots and their own
  records. They fight; they don't gather.
- **Only heroes wear weapons and armour.** Workers wear tools (and take food and potions). This
  is what gives combat gear its value: you see it work.
- **Classes.** Two to start:

  | Class | Plays like | Wants |
  |---|---|---|
  | **Knight** | Holds the line; more health; Guard is stronger; **Shield Bash** stuns | armour, block, health |
  | **Rogue** | Strikes first and hard; **Backstab** is a heavy blow with doubled crit chance | crit, crit damage, dodge, armour piercing |

  Any hero can wear any piece, but each class gets more from its stats (a knight's block and
  armour count for more; a rogue's crit and dodge do). So the same sword is worth more to one
  hero than another, and many different swords have buyers. More classes later (OPEN: a
  priest/healer, a brute).
- **Hero slots work like the Warden's charters.** One to start; more are bought as the guild
  grows. A crypt says how many heroes it is built for: the Fallen Keep is for one; deeper crypts
  want two or three, and fights that ask for a mix of classes, not just more health.
- **Hero slots are separate from expedition slots.** A crew can be out while a hero is in a
  crypt. A hero never takes an expedition slot.
- **Heroes level up** in Combat by clearing floors, and their gear wears like everyone else's.
- **When a hero dies,** their kit stays in that crypt (the fallen-gear system already does this),
  and a later run may recover it. The hero is gone.
- **Heroes cost upkeep** (a wage per crypt run), so an idle hero is worth putting to work —
  including on automatic runs while you're away.

**Save migration (BUILDING).** Guilds from before this update keep everything. Their best-armed
fighter becomes their first hero (class from their weapon: dagger → Rogue, anything else →
Knight). Weapons and armour on other mercenaries go to the warehouse. Crypt runs already under way
finish under the old rules.

---

## 5. Crypts and the crawl — BUILDING

**The view is side-on.** Your heroes stand on the left, the monsters on the right, like a party
line. The crypt is a sequence of floors; each floor is one fight (the boss floor is the boss).

**Turns.** Everyone acts in order of speed (attack speed, with a little luck). On a hero's turn:

- **Strike** — a normal attack on the chosen foe: damage, crit, armour piercing.
- **Guard** — brace: take much less damage until your next turn (knights more so).
- **Class skill** — Knight: *Shield Bash* (a lighter hit that stuns the foe for a turn);
  Rogue: *Backstab* (a heavy hit with doubled crit chance). Each has a cooldown.
- **Potion** — drink a healing draught if the hero carries one.
- **Retreat** — leave the crypt now with what you carry.

Every hit shows its number. Crits, dodges, parries, blocks and stuns are called out. The fight
log reads like the report.

**Between floors:** the floor's coin and goods are picked up, the heroes bind their wounds, and
you choose to **push on** or **take it out**. The existing event cards (a chest with blood around
it, a stranger offering dice) still happen between fights.

**Leading or not.** When you send heroes into a crypt you choose:

- **Lead them** — the crawl opens and you play it. A led run takes as long as you play it.
- **Let them handle it** — the run goes on in real time under standing orders (how deep, when to
  turn back, safe or bold choices), exactly as crypt runs work today, and finishes while you're
  away.

**The same rules either way.** The automatic run uses the same turn engine, with the hero choosing
actions by simple rules (guard when hurt, potion below a third, skill when ready, strike the
weakest foe). So a stat behaves the same led or not, and the forecast is honest.

**Leading is better, but never required:** you choose which floors to risk, you can use skills
well, and (VALIDATE) the first clear of each floor gives a little more when you lead it. Auto
remains reliable and safe-ish.

**Reports show the fight:** per floor, the hits, crits, the biggest blow given and taken, damage
turned by armour, potions drunk, who fell.

**If the game closes mid-crawl,** the run continues automatically from where it was.

---

## 6. Crews and trade sites — DECIDED (guards change: BUILDING)

Unchanged in spirit: crews of up to three workers go to a site for a trade (logging, mining,
foraging, fishing, hunting, farming), paid a wage and a share, under standing orders (Cautious,
Balanced, Deep Push, Long Shift, Overnight, Full Day). They come back with goods, experience, worn
tools, injuries, sometimes rare finds and blueprints; sometimes they don't come back.

**Guards are retired from trade sites.** A site's threat is met by the crew's orders, their
health, their traits, food and potions. Site injury and death chances are retuned so a sensible
crew faces roughly what a guarded crew faced before. (OPEN: a hero escorting a dangerous trip
instead of going to a crypt.)

**Expedition slots** (Warden's charters) stay as they are: the number of crews out at once.

---

## 7. The first hour — BUILDING

**Rules:**

1. **Never just one timer.** At least two things are in motion and there is one thing to do by
   hand.
2. **Trips get longer as you run more at once.** Tier-1 trips take about a minute and a half;
   tier-2 about four minutes; deeper sites longer; long orders hours.
3. **Every return brings a decision:** sell or keep, craft or save, push on or turn back.
4. **Each system opens as the answer to a problem.** The game creates a need, then hands the tool.
5. **The hour ends with a hook for tomorrow:** crews out overnight, a goal for the hero, an enemy,
   and a next unlock in view.

**The hour, as planned:**

| Time | What happens | What opens |
|---|---|---|
| 0:00–0:05 | **Prologue:** Aldren in great gear, one led fight in the Brimstone Reach, the betrayal | — |
| 0:05–0:12 | **Rock bottom.** Empty hall, a few coins. Choose your first hero's class. Hire a woodcutter, send them to Cinderwood (~90 s). Lead the hero into the Fallen Keep's Cellars while they work. The crew comes back; sell the ashwood | Mercenaries, Expeditions, Heroes, Market |
| 0:12–0:25 | **The rusty sword is the problem.** The cellars drop scrap; a better sword needs a handle (ashwood) and copper (the Gatepit). Hire a miner. Two crews and a hero. Equip the new sword, go back down, watch the crits | Workshop, second worker |
| 0:25–0:40 | **The second wall.** The Webbed Halls' spiders hit hard; armour needs hides — the Hollow Fields open. Prices move; sell or keep starts to matter. First crypt choice card. First injury | Hunting, Warehouse |
| 0:40–0:55 | **The Bone Knight.** Maybe a loss, maybe a narrow win in gear you made. First rare find and blueprint. On the knight: a sign of Aldren's crew in the Drowned Abbey | Auction House, a goal |
| 0:55–1:00 | **The hook.** Overnight orders suggested; what will be ready tomorrow; the next charter and hero slot in view | Long orders, Ledger |

The tutorial card follows this, pointing at the next click throughout (as it does now). Systems
not yet needed are present but quiet (the bookmark is there, the page says what opens it), so
nothing is hidden behind menus the player can't find.

---

## 8. Gear, crafting and the market — DECIDED

- **Gold** is the money. **Goods** (ashwood, copper, spider silk, relics…) are priced in gold.
- **Gear** is crafted from goods and blueprints, found below, or bought. It **wears** with use
  (half as good until repaired) and is **lost** when its wearer dies.
- **Combat gear belongs to heroes**; **tools** to workers. Each tool or weapon rolls stats.
- **Visibility is the rule:** every stat on a piece must show up somewhere the player watches
  (the crawl, the forecast, the report). If it can't, it shouldn't exist.
- **Sinks:** wear and repair, death, supplies, wages and shares, crafting consumption,
  merchants paying less after heavy selling, auction fees.
- **The Market** (NPC merchants, moving prices) and the **Auction House** (listings and buy
  orders filled over time) are the trade surfaces today.

---

## 9. The economy with other players — DECIDED direction, later

**The economy must work without other players, and get better with them.**

- **NPC merchants stay** as a floor that always buys and sells.
- **Players are added on top** later: player listings compete with NPCs. With few players the
  NPCs carry the market; with many, players take it over by themselves.
- **NPCs follow player prices, with a spread:** they sell a little above the going player price
  and buy a little below it. A player's listing is always the better deal; the NPC is the
  always-there fallback.
- **NPC prices can't be steered:**
  1. They follow **completed sales**, never listings.
  2. They use a **slow, robust average** (the middle of many sales across many different traders
     over about a day, extremes thrown out).
  3. They **blend with a base value by volume** (thinly traded goods lean on the base value).
  4. They are **capped** (e.g. within ½× to 2× base, a few percent of movement a day).
  5. NPCs have **limited appetite** (they already pay less after heavy selling and recover over
     a day).
- **An online economy needs a server.** Gold, items, trip timers and market orders must live on
  a server, not in local saves, with accounts and anti-cheat. That is a separate project after
  the single-player game proves itself. Ship single-player first.

---

## 10. Interface — DECIDED

The game is a book: six bookmarks (Company, Expeditions, Mercenaries, Workshop, Market, Ledger),
two pages each, pixel-art at a 960×540 base. **BUILDING:** a **Heroes** section (hero records,
classes, gear, slots) and the **crawl screen** (side-on, party left, foes right, actions under the
party, a running log). The header shows crews and heroes out separately ("Crews 1/1 · Heroes
1/1").

Standards from 1.x stand: information at the point of decision, scannable state, feel matters,
consistency across pages, no clipped or dead controls, and visual checks at real window sizes —
automated tests don't prove visual quality.

---

## 11. Build plan for v0.33 "Heroes"

Built on the `heroes` branch; `main` stays the playable game until it's proven.

1. **Done.** Heroes: records, slots, classes, gear only on heroes, upkeep, save migration.
2. **Done.** The turn engine (`scripts/crawl.gd`): initiative, actions, class skills, foes' turns;
   used by the led crawl and by automatic runs and forecasts.
3. **Done.** The crawl screen, and "Lead them / Let them handle it" on the crypt planner.
4. **Done.** Guards retired from trade sites; site risks retuned.
5. **Partly done.** First-hour pacing: trips are shorter (tier 1 90 s, tier 2 4 min, tier 3 7,
   tier 4 10, tier 5 15) with per-trip wages, supplies and hauls unchanged. Decided while building:
   active play earns more per hour (the point of the hour), but long orders count trips at the old
   pace and deeper sites' per-trip risk was cut to match, so idle income and risk per hour are
   what they were (`tools/econ_sim.gd`: idle and evening players about the same at 48 h; the first
   1,000 G in under an hour instead of one to seven). **Still to do:** trips lengthening as more crews run at once (rule 2), the unlock order (quiet
   pages until they're needed) and a look at fixed prices (charters, hero slots) once real
   players have tried the faster hour.
6. **Done.** The prologue and the betrayal.
7. **Done.** The new tutorial following §7, including the gear step's learn → craft → equip.
8. Tests for each, a recorded first-hour playthrough, then a cold playtest with 3–5 people.

**Success test for this update:** someone who has never seen the game plays for 30–45 minutes
without being told anything, and says they'd play another hour.

---

## 12. Parked (from Money Mercs, v1.x)

- **Scouts and rotating deposits** (Harlow rotations, scout reports). Sites are fixed places now.
- **Physical gold** (coin stacks, bags and chests in a limited treasury).
- **A Dark-and-Darker-style trading-post feed** with haggling. (A haggle prototype exists in
  code.)
- **Simulated rival companies** as named NPC firms. (Rival crews may return as part of Aldren's
  story.)

---

## 13. Open questions

1. Death's name in town, Aldren's final name, the player's guild name.
2. Hero slot prices and how many heroes each crypt wants; when the second slot appears.
3. How much better a led run should be than an automatic one.
4. More classes, and whether heroes can change class.
5. A hero escorting a dangerous trade trip instead of a crypt run.
6. The demo's end: where it stops and what it asks of the player.
7. Online: back end, accounts, anti-cheat, and the population at which shared trading turns on.

### Final product test

> **Can someone who loves running crews, someone who loves leading heroes below, and someone who
> loves the market all find an hour that makes them want a hundred more — in the same guild?**

*This is a living document. Update it when the game changes; don't promote example numbers to
final decisions without playtesting.*
