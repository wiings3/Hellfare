# Itch.io page: Hellfare demo

Copy for the itch.io page, plus the settings to choose when uploading. Keep it in step with the
game: when a feature changes, change it here.

## Settings on the itch.io edit page

- **Kind of project:** HTML for the browser build, plus downloadable files. Upload
  `hellfare-web.zip` and tick *This file will be played in the browser*. Upload the Windows and
  Linux zips and tag them with their platform.
- **Embed options:** viewport **1280 × 720**, *Mobile friendly* off, *Fullscreen button* on,
  *Automatically start on page load* off. The browser build needs no SharedArrayBuffer setting
  (it's single-threaded).
- **Classification:** Game. **Release status:** In development. **Genre:** Strategy (or
  Simulation).
- **Tags:** guild management, idle, incremental, dungeon crawler, turn-based, pixel art,
  dark fantasy, economy, crafting, singleplayer.
- **AI generation disclosure:** **Yes**. The crypt backgrounds (Hellwake and Underfire by
  Firepious) are AI-assisted, and so is the code (it's written with Claude). Itch asks
  for this when you edit the page. Be upfront: players who find out later take it worse than
  players who were told.
- **Community:** turn on *Comments* so feedback lands on the page. Once the page exists, put its
  address in `project.godot` (`hellfare/feedback_url`): the pause menu then shows **Send
  feedback**, which opens it.

## Short description (the one-liner under the title)

Run a guild of mercenaries from the last town before hell. Send crews down for what only hell
has, and lead your hero through its crypts yourself.

## Page text

**Build a fortune. Let someone else go down for it.**

Twelve years ago you ran the greatest guild in Last Lantern, until your champion sold you out to
Death. Now you have a rented room, a few coins and the right to call yourself a guild. Start
again.

**Hellfare** is a guild-management game about a town that lives off hell. Below Last Lantern the
Maw drops through five layers of hell, each richer and deadlier than the last.

- **Send crews down.** Hire woodcutters, miners, fishers and hunters and send them to work the
  layers. They come back on their own, even while you're away, carrying whatever they could
  get. Sometimes they don't come back.
- **Lead your hero through the crypts.** Turn-based fights where every monster shows what it will
  do next. Your weapon decides your moves, and your lantern is a resource: specials burn its
  light, and in the dark monsters hit harder and more of them come.
- **Feed the crawl.** Your crews bring up the timber, ore, fish and silk; your workshop turns
  them into the gear, food and lantern oil your hero needs to go deeper.
- **Run the books.** Trade in the market, take long contracts, keep your people fed and your
  gear repaired.

**Death is permanent.** A Hellfarer who dies is gone. Your guild, its gold and its stores carry
on, and so do the crews still working. What the dead were carrying stays down there, and
other crews might bring it back.

### This is an early demo

It's a work in progress, and I'd love to hear what you think: what confused you, what
felt slow, what you wanted more of. Leave a comment here (the pause menu's **Send feedback**
button opens this page).

- Your guild is saved automatically. In the browser it's saved in that browser, so clearing the
  site's data clears your guild. The download versions keep it in your user folder.
- The market's other traders and the Auction House are simulated: there are no other players.
- Press **Esc** for the menu: settings, credits, and starting a new guild.

### Credits

- Fighters and portraits: *Heroic Asset Series: Creature Pack* by Aleksandr Makarov
  (iknowkingrabbit).
- Crypt backgrounds: *Hellwake* and *Underfire* by Firepious (AI-assisted, per the publisher).
- Sound: Kenney's *RPG Audio* and *Interface Sounds* (CC0); the rest is synthesised for the game.
- Type: Jersey 10, 15 and 20 by The Soft Type Project (SIL Open Font License).
- Made with Godot Engine. Written with Claude.

## Screenshots to take

The page needs three to five. In this order:
1. A crypt fight with monster intents showing (the Fallen Keep, mid-fight).
2. The board with crews out across the layers.
3. The prologue's choice screen (*Who will lead your guild below?*).
4. The workshop or the market.
