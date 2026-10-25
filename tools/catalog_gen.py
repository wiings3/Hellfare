"""Authoring script for the item catalog (run from the project root: python3 tools/catalog_gen.py).

Writes data/catalog.json: every expedition, material, piece of gear, food, potion, trinket,
crafting intermediate, stat roll and company upgrade in Money Mercs. The game and
tests/catalog_test.gd read the JSON; edit this script and re-run it to change the catalog.
Ids already used by saves (timber, copper, basic_pick, leather, ...) never change.

How the catalog is built
- Tiers 1-5. Each tier has a metal, a timber, a hide, a cloth and a gem; gear of a tier is made
  from that tier's materials, so climbing tiers means opening new expeditions.
- Weapons come in families with different shapes (fast and critical daggers, slow and heavy
  maces, two-handers that take the off-hand). Expected damage per second, counting crits, stays
  within 15% of the sword for one-handers and 5-35% above it for two-handers.
- Armour comes in three weights (light: dodge and speed, medium: balanced, heavy: armour and
  block but slower) with four pieces each (head, body, hands, feet).
- Every crafted or dropped piece rolls a rarity: Common (no extra stats), Fine (1), Superior (2)
  or Masterwork (3), drawn from its family's pool of stat rolls. Found-only pieces are fixed.
- Crafted value is about 1.4x the materials (the validator keeps it within 1.1-2.2x).
- Blueprints: the quartermaster sells tier 1-2; tier 3-5 blueprints drop in the dungeon two tiers
  below (Calder Keep -> 3, Sunken Abbey -> 4, Wyrm's Hollow -> 5) or, for trade tools, food,
  trinkets and packs, at an expedition of the same tier.
- Food and drink go in a mercenary's food slot and are eaten on the next trip; potions go in the
  potion slot. Cooking burns timber as firewood.
- Kit rating = tier x slot weight over the fighting slots (main hand 4, off hand 2, body 3,
  head, hands and feet 1; two-handers count 6). A full tier-N kit is 12N.
"""
import json, os, re

TIERS = [1, 2, 3, 4, 5]
LEVEL = {1: 0, 2: 8, 3: 18, 4: 30, 5: 45}

# ---------------------------------------------------------------- expeditions and other sources
# id: (name, kind, trade, tier, status, extra)
SOURCES = {
    # Logging
    "mossward_copse": ("Mossward Copse", "site", "logging", 1, "live", {}),
    "old_oakwood": ("Old Oakwood", "site", "logging", 2, "live", {}),
    "thornwald": ("Thornwald", "site", "logging", 3, "planned", {}),
    "blackroot_weald": ("Blackroot Weald", "site", "logging", 4, "planned", {}),
    "palewood": ("The Palewood", "site", "logging", 5, "planned", {}),
    # Mining
    "harlow": ("Harlow Mines", "site", "mining", 1, "live", {}),
    "deepdelve": ("Deepdelve", "site", "mining", 2, "live", {}),
    "cinder_shaft": ("Cinder Shaft", "site", "mining", 3, "planned", {}),
    "gloamhold": ("Gloamhold Deeps", "site", "mining", 4, "planned", {}),
    # Foraging
    "mossward_meadows": ("Mossward Meadows", "site", "foraging", 1, "live", {}),
    "fenmire": ("Fenmire", "site", "foraging", 2, "live", {}),
    "sunreach": ("Sunreach Slopes", "site", "foraging", 3, "live", {}),
    "frostvale": ("Frostvale", "site", "foraging", 4, "live", {}),
    # Fishing (deeper waters need a higher Fishing level, like every trade)
    "millbrook_pond": ("Millbrook Pond", "site", "fishing", 1, "live", {}),
    "silverrun": ("Silverrun River", "site", "fishing", 2, "live", {}),
    "glasswater": ("Glasswater Lake", "site", "fishing", 3, "live", {}),
    "greywater_coast": ("Greywater Coast", "site", "fishing", 4, "live", {}),
    "drowned_deep": ("The Drowned Deep", "site", "fishing", 5, "live", {}),
    # Hunting (hunters use weapons: bows, crossbows and spears hunt best)
    "hollow_fields": ("Hollow Fields", "site", "hunting", 1, "live", {}),
    "greyfang_hills": ("Greyfang Hills", "site", "hunting", 2, "live", {}),
    "elkmoor": ("Elkmoor", "site", "hunting", 3, "live", {}),
    "bleakridge": ("Bleakridge", "site", "hunting", 4, "live", {}),
    # Farming (company land, worked by mercenaries with hoes)
    "home_fields": ("Home Fields", "farm", "farming", 1, "live", {}),
    "tilled_acres": ("Tilled Acres", "farm", "farming", 2, "live", {"needs": "field_plots"}),
    "beehives": ("Beehives", "farm", "farming", 2, "live", {"needs": "apiary"}),
    "glasshouse": ("Glasshouse", "farm", "farming", 3, "live", {"needs": "glasshouse_build"}),
    # Dungeons
    "calder_keep": ("Calder Keep", "dungeon", "combat", 1, "planned", {}),
    "sunken_abbey": ("The Sunken Abbey", "dungeon", "combat", 2, "planned", {}),
    "wyrms_hollow": ("Wyrm's Hollow", "dungeon", "combat", 3, "planned", {}),
    # Other ways in
    "quartermaster": ("Quartermaster", "shop", "", 0, "live", {}),
    "fallen": ("Gear of the fallen", "found", "", 0, "live", {}),
    "crafting": ("Known to everyone", "craft", "", 0, "planned", {}),
}

# ---------------------------------------------------------------- materials
# id: (name, tier, group, value, sources, note). The eight goods in today's game keep their ids.
MATERIALS = {
    # Timber and sap
    "timber": ("Birch Timber", 1, "timber", 6, ["mossward_copse"], "Tier-1 handles, rods and bows; firewood for cooking."),
    "oak": ("Oak Timber", 2, "timber", 14, ["old_oakwood"], "Tier-2 handles, rods, bows and shields."),
    "yew": ("Yew Timber", 3, "timber", 30, ["thornwald"], "Tier-3 handles, longbows and frame packs."),
    "ironwood": ("Ironwood", 4, "timber", 65, ["blackroot_weald"], "Tier-4 handles and hafts."),
    "ghostwood": ("Ghostwood", 5, "timber", 150, ["palewood", "wyrms_hollow"], "Pale, light and hard; tier-5 gear."),
    "resin": ("Thornwald Resin", 3, "sap", 24, ["thornwald", "blackroot_weald"], "Varnish for tier-3+ bows and shields."),
    "amber": ("Amber", 1, "gem", 10, ["mossward_copse"], "Old sap turned to stone. Charms."),
    # Ores, metal and gems
    "copper": ("Copper Ore", 1, "ore", 20, ["harlow", "deepdelve"], "Fittings, sickles, hooks, flasks and lanterns."),
    "coal": ("Coal", 1, "ore", 8, ["harlow", "cinder_shaft"], "Fuel for smelting steel."),
    "iron": ("Iron Ore", 1, "ore", 17, ["harlow", "deepdelve", "cinder_shaft"], "Tier-1 metal and the base of steel. Harlow gives a little; Deepdelve is the main seam."),
    "silver": ("Silver", 2, "ore", 28, ["deepdelve", "gloamhold"], "Silversteel, rings and fine fittings."),
    "garnet": ("Garnet", 2, "gem", 45, ["deepdelve"], "Blood-red stones for rings of striking."),
    "crystal": ("Azure Crystal", 3, "gem", 75, ["deepdelve", "gloamhold"], "Amulets and crystal lanterns."),
    "emberstone": ("Emberstone", 4, "gem", 110, ["cinder_shaft", "gloamhold"], "Stones that never cool. Rings of fury."),
    "gloomiron": ("Gloomiron", 4, "metal", 120, ["gloamhold", "sunken_abbey"], "Dark deep-metal; tier-4 gear."),
    "wyrmbone": ("Wyrmbone", 5, "metal", 400, ["wyrms_hollow"], "Bone of the wyrm, harder than steel; tier-5 gear."),
    "wyrmscale": ("Wyrmscale", 5, "hide", 320, ["wyrms_hollow"], "Tier-5 light armour and packs."),
    # Foraged plants
    "herbs": ("Moonleaf", 1, "herb", 5, ["old_oakwood", "mossward_meadows", "fenmire"], "Healing draughts."),
    "berries": ("Hedgeberries", 1, "herb", 4, ["mossward_meadows"], "Tarts, porridge and quick draughts."),
    "bloodcap": ("Bloodcap", 2, "herb", 18, ["fenmire", "frostvale"], "Greater healing and tonics."),
    "mushrooms": ("Fen Morels", 2, "herb", 12, ["fenmire"], "Soups and tonics."),
    "nightshade": ("Nightshade", 3, "herb", 30, ["sunreach"], "Blade venom."),
    "sunpetal": ("Sunpetal", 3, "herb", 26, ["sunreach"], "Tea that sharpens the mind; fortune brews."),
    "frostbloom": ("Frostbloom", 4, "herb", 60, ["frostvale"], "Sorbets and brews."),
    # Fish
    "perch": ("Perch", 1, "fish", 5, ["millbrook_pond"], "Grilled, or pressed into fish oil."),
    "trout": ("Silver Trout", 2, "fish", 14, ["silverrun"], "Smoked trout."),
    "eel": ("River Eel", 2, "fish", 18, ["silverrun"], "Eel pie."),
    "pike": ("Glass Pike", 3, "fish", 30, ["glasswater"], "Chowder."),
    "pearl": ("Pearl", 3, "gem", 90, ["glasswater", "greywater_coast"], "Pendants and fortune brews."),
    "cod": ("Greywater Cod", 4, "fish", 45, ["greywater_coast"], "Cod suppers."),
    "crab": ("Rock Crab", 4, "fish", 50, ["greywater_coast"], "Crab boils."),
    "abyssal_eel": ("Abyssal Eel", 5, "fish", 160, ["drowned_deep"], "The Abyssal Feast."),
    "voidpearl": ("Voidpearl", 5, "gem", 600, ["drowned_deep"], "Black pearls from the deep. Amulets and lanterns."),
    # Hunting
    "game_meat": ("Game Meat", 1, "meat", 6, ["hollow_fields"], "Stews and jerky."),
    "rabbit_hide": ("Rabbit Hide", 1, "hide", 6, ["hollow_fields"], "Tier-1 light armour, satchels and grips."),
    "feathers": ("Feathers", 1, "hunt", 3, ["hollow_fields"], "Fletching for bows."),
    "bone": ("Bone", 1, "hunt", 2, ["hollow_fields", "greyfang_hills", "calder_keep"], "Charms, bone meal and tonics."),
    "boar_meat": ("Boar Meat", 2, "meat", 15, ["greyfang_hills"], "Roasts, pasties and chili."),
    "wolf_pelt": ("Wolf Pelt", 2, "hide", 22, ["greyfang_hills", "old_oakwood"], "Tier-2 light armour, packs and grips."),
    "fang": ("Wolf Fang", 2, "hunt", 12, ["greyfang_hills"], "Fang necklaces."),
    "venison": ("Venison", 3, "meat", 28, ["elkmoor"], "Steaks."),
    "elk_hide": ("Elk Hide", 3, "hide", 40, ["elkmoor"], "Tier-3 light armour and frame packs."),
    "antler": ("Elk Antler", 3, "hunt", 35, ["elkmoor"], "Hunting talismans."),
    "bear_meat": ("Direbear Meat", 4, "meat", 50, ["bleakridge"], "The Direbear Haunch."),
    "direbear_pelt": ("Direbear Pelt", 4, "hide", 85, ["bleakridge"], "Tier-4 light armour and packs."),
    # Farming
    "wheat": ("Wheat", 1, "crop", 3, ["home_fields"], "Milled into flour."),
    "cabbage": ("Cabbage", 1, "crop", 4, ["home_fields"], "Stews, soups and chowder."),
    "flax": ("Flax", 1, "crop", 4, ["home_fields"], "Spun into linen."),
    "barley": ("Barley", 2, "crop", 8, ["tilled_acres"], "Ale and porridge."),
    "potato": ("Potatoes", 2, "crop", 7, ["tilled_acres"], "Roasts, pasties, chowder and boils."),
    "honey": ("Honey", 2, "crop", 16, ["beehives"], "Cakes, ale, tea and sorbet."),
    "emberpepper": ("Emberpepper", 3, "crop", 24, ["glasshouse"], "Fiery peppers. Chili, steaks and elixirs."),
    # Fibre
    "spider_silk": ("Spider Silk", 2, "fibre", 26, ["calder_keep", "deepdelve"], "Tier 2-3 bowstrings, fishing line and linings."),
    "shadowsilk": ("Shadowsilk", 4, "fibre", 110, ["sunken_abbey"], "Tier 4-5 bowstrings, line and light armour."),
    # Treasures
    "relic": ("Ancient Relic", 4, "treasure", 550, ["old_oakwood", "calder_keep", "sunken_abbey"], "Carved idols. Collectors pay well; crafters make idols of them."),
    "sovereign": ("Sovereign Orb", 5, "treasure", 12500, ["wyrms_hollow"], "The rarest prize. Kept for a future mythic tier."),
}
SELL_ONLY = {"sovereign"}

# ---------------------------------------------------------------- tier materials
METAL = {1: "iron", 2: "steel_ingot", 3: "silversteel_ingot", 4: "gloomiron", 5: "wyrmbone"}
METAL_NAME = {1: "Iron", 2: "Steel", 3: "Silversteel", 4: "Gloomiron", 5: "Wyrmbone"}
WOOD = {1: "timber", 2: "oak", 3: "yew", 4: "ironwood", 5: "ghostwood"}
WOOD_NAME = {1: "Birch", 2: "Oak", 3: "Yew", 4: "Ironwood", 5: "Ghostwood"}
HIDE = {1: "rabbit_hide", 2: "wolf_pelt", 3: "elk_hide", 4: "direbear_pelt", 5: "wyrmscale"}
CLOTH = {1: "linen", 2: "spider_silk", 3: "spider_silk", 4: "shadowsilk", 5: "shadowsilk"}
DUNGEON_FOR = {3: "calder_keep", 4: "sunken_abbey", 5: "wyrms_hollow"}

POWER = {1: 10, 2: 16, 3: 24, 4: 34, 5: 48, 4.5: 41}       # sword damage per tier
ARMOUR = {1: 30, 2: 48, 3: 72, 4: 102, 5: 144, 4.5: 123}    # a full heavy set is about 1.15x this
TOOL = {1: 1, 2: 2, 3: 3, 4: 4, 5: 6, 4.5: 5}
DURABILITY = {1: 30, 2: 40, 3: 50, 4: 60, 5: 80}
SLOT_WEIGHT = {"main_hand": 4, "off_hand": 2, "body": 3, "head": 1, "hands": 1, "feet": 1}

# ---------------------------------------------------------------- stat rolls
# id: (name, text, low, high at tier 1). Rolls scale with tier (x1, 1.3, 1.6, 2.0, 2.5).
AFFIXES = {
    "damage": ("Keen", "+{}% damage", 3, 6),
    "attack_speed": ("Swift", "+{}% attack speed", 2, 4),
    "crit_chance": ("Precise", "+{}% critical chance", 1, 3),
    "crit_damage": ("Brutal", "+{}% critical damage", 5, 12),
    "armour_pen": ("Piercing", "+{}% armour piercing", 3, 6),
    "bleed": ("Serrated", "{}% chance to cause bleeding", 2, 5),
    "stun": ("Crushing", "{}% chance to stun", 2, 4),
    "first_strike": ("Vigilant", "+{}% chance to strike first", 5, 10),
    "parry": ("Deflecting", "+{}% parry", 2, 4),
    "block": ("Bulwark", "+{}% block", 2, 5),
    "dodge": ("Nimble", "+{}% dodge", 1, 3),
    "armour": ("Reinforced", "+{} armour", 2, 4),
    "health": ("Hale", "+{} health", 4, 8),
    "injury_resist": ("Warding", "-{}% injury chance", 3, 6),
    "yield": ("Bountiful", "+{}% haul", 3, 6),
    "rare_find": ("Lucky", "+{}% rare finds", 1, 3),
    "xp": ("Studious", "+{}% experience", 2, 5),
    "carry": ("Roomy", "+{}% carrying", 3, 6),
    "speed": ("Hasty", "-{}% trip time", 2, 4),
    "sturdy": ("Durable", "+{}% durability", 10, 25),
}
AFFIX_SCALE = {1: 1.0, 2: 1.3, 3: 1.6, 4: 2.0, 5: 2.5}
RARITY = [
    {"id": "common", "name": "Common", "affixes": 0, "chance": 0.60, "value_mult": 1.0},
    {"id": "fine", "name": "Fine", "affixes": 1, "chance": 0.28, "value_mult": 1.25},
    {"id": "superior", "name": "Superior", "affixes": 2, "chance": 0.10, "value_mult": 1.6},
    {"id": "masterwork", "name": "Masterwork", "affixes": 3, "chance": 0.02, "value_mult": 2.2},
]

# ---------------------------------------------------------------- weapon families
# dmg/spd relative to the sword; crit chance; crit multiplier; extras; stat-roll pool; recipe shape.
# Recipe shape keys: M metal, W timber, H hide, C cloth, F feathers (tier 1-3), R resin (tier 3+).
FAMILIES = {
    "dagger": dict(name="Dagger", hands=1, dmg=0.62, spd=1.45, crit=0.12, critx=1.8, extra={},
                   pool=["crit_chance", "crit_damage", "attack_speed", "bleed", "sturdy"], shape={"M": 1, "W": 1, "H": 1},
                   blurb="Fast, with the best critical chance. Rolls favour crits and speed."),
    "sword": dict(name="Sword", hands=1, dmg=1.0, spd=1.0, crit=0.06, critx=1.6, extra={"parry": 0.05},
                  pool=["damage", "crit_chance", "parry", "attack_speed", "sturdy"], shape={"M": 2, "W": 1, "H": 1},
                  blurb="The all-rounder: solid damage, average speed and crits, a little parry."),
    "war_axe": dict(name="War Axe", hands=1, dmg=1.12, spd=0.88, crit=0.05, critx=1.7, extra={"armour_pen": 0.15},
                    pool=["damage", "armour_pen", "bleed", "crit_damage", "sturdy"], shape={"M": 2, "W": 2},
                    blurb="Heavier and slower than a sword; bites through armour."),
    "mace": dict(name="Mace", hands=1, dmg=1.12, spd=0.86, crit=0.04, critx=1.5, extra={"armour_pen": 0.2, "stun": 0.08},
                 pool=["damage", "stun", "armour_pen", "health", "sturdy"], shape={"M": 3, "W": 1},
                 blurb="Slow, stuns, and best of all against plate."),
    "spear": dict(name="Spear", hands=1, dmg=0.98, spd=0.98, crit=0.05, critx=1.6, extra={"first_strike": 0.15, "hunt": 1},
                  pool=["first_strike", "damage", "parry", "yield", "sturdy"], shape={"M": 1, "W": 3},
                  blurb="Reach: often strikes first. A fair hunting weapon."),
    "greatsword": dict(name="Greatsword", hands=2, dmg=1.65, spd=0.70, crit=0.06, critx=1.7, extra={},
                       pool=["damage", "crit_damage", "armour_pen", "stun", "sturdy"], shape={"M": 4, "W": 1, "H": 1},
                       blurb="Two hands, huge hits, slow swings. No shield."),
    "bow": dict(name="Bow", hands=2, dmg=1.3, spd=0.90, crit=0.07, critx=1.6, extra={"first_strike": 0.3, "hunt": 2},
                pool=["first_strike", "crit_chance", "damage", "yield", "sturdy"], shape={"W": 3, "C": 1, "F": 1, "R": 1},
                blurb="Shoots first. The best hunting weapon."),
    "crossbow": dict(name="Crossbow", hands=2, dmg=2.0, spd=0.60, crit=0.05, critx=1.7, extra={"first_strike": 0.2, "armour_pen": 0.25, "hunt": 1},
                     pool=["armour_pen", "damage", "crit_damage", "yield", "sturdy"], shape={"W": 2, "M": 1, "C": 1, "R": 1},
                     blurb="Very slow, very heavy bolts that pierce armour."),
}
BOW_NAMES = {1: "Birch Shortbow", 2: "Oak Hunting Bow", 3: "Yew Longbow", 4: "Ironwood Warbow", 5: "Ghostwood Bow"}

SHIELDS = {
    "buckler": dict(name="Buckler", armour=0.25, block=0.0, extra={"parry": 0.08}, shape={"M": 1, "H": 1},
                    pool=["parry", "dodge", "attack_speed", "health", "sturdy"], blurb="Small and quick: parry, no slowdown."),
    "kite_shield": dict(name="Kite Shield", armour=0.4, block=0.12, extra={}, shape={"W": 2, "M": 1, "H": 1, "R": 1},
                        pool=["block", "armour", "health", "injury_resist", "sturdy"], blurb="Balanced block and armour."),
    "tower_shield": dict(name="Tower Shield", armour=0.6, block=0.22, extra={"attack_speed": -0.06}, shape={"W": 3, "M": 2, "R": 1},
                         pool=["block", "armour", "health", "injury_resist", "sturdy"], blurb="A wall: the most block, slows its bearer."),
}

ARMOUR_WEIGHTS = {
    "light": dict(mult=0.5, extra={"dodge": 0.08, "attack_speed": 0.05}, pool=["dodge", "attack_speed", "crit_chance", "health", "speed"],
                  names={1: "Leather", 2: "Wolfhide", 3: "Elkhide", 4: "Direbear", 5: "Wyrmskin"},
                  pieces={"head": "Cap", "body": "Jerkin", "hands": "Gloves", "feet": "Boots"},
                  blurb="Hide and cloth: dodge and speed."),
    "medium": dict(mult=0.8, extra={"injury_resist": 0.1}, pool=["armour", "health", "injury_resist", "dodge", "carry"],
                   names={1: "Ringmail", 2: "Chainmail", 3: "Silversteel Scale", 4: "Gloomiron Brigandine", 5: "Wyrmscale"},
                   pieces={"head": "Coif", "body": "Hauberk", "hands": "Gloves", "feet": "Boots"},
                   blurb="Mail and scale: balanced, and fewer injuries."),
    "heavy": dict(mult=1.15, extra={"block": 0.06, "attack_speed": -0.08}, pool=["armour", "block", "health", "injury_resist", "sturdy"],
                  names={1: "Iron", 2: "Steel", 3: "Silversteel", 4: "Gloomiron", 5: "Wyrmbone"},
                  pieces={"head": "Helm", "body": "Cuirass", "hands": "Gauntlets", "feet": "Greaves"},
                  blurb="Plate: the most armour and some block, but slower."),
}
PIECE_SHARE = {"head": 0.2, "body": 0.45, "hands": 0.15, "feet": 0.2}
PIECE_UNITS = {"head": 1, "body": 3, "hands": 1, "feet": 1}

# Trade tools: kind -> (trade, base name, recipe shape, top tier)
TOOLS = {
    "felling_axe_kind": ("logging", "Felling Axe", {"M": 1, "W": 2}, 5),
    "pickaxe": ("mining", "Pickaxe", {"M": 2, "W": 1}, 5),
    "sickle": ("foraging", "Sickle", {"M": 1, "W": 1}, 4),
    # Rods are almost all timber, strung with the tier's cord (linen, spider silk, shadowsilk).
    "fishing_rod": ("fishing", "Rod", {"W": 4, "C": 1}, 5),
    "hoe": ("farming", "Hoe", {"M": 1, "W": 2}, 3),
}
TOOL_POOL = ["yield", "rare_find", "speed", "sturdy", "xp"]

# Items in today's game: they keep their id, name, price and a recipe priced to match.
LEGACY = {
    "hand_axe": dict(kind="felling_axe_kind", tier=1, name="Hand Axe", recipe={"iron": 1, "timber": 1}, value=26, legacy_slot="tool"),
    "felling_axe": dict(kind="felling_axe_kind", tier=2, name="Felling Axe", recipe={"iron": 3, "oak": 2}, value=98, legacy_slot="tool"),
    "basic_pick": dict(kind="pickaxe", tier=1, name="Iron Pickaxe", recipe={"iron": 1, "timber": 1}, value=28, legacy_slot="tool"),
    "reinforced_pick": dict(kind="pickaxe", tier=2, name="Reinforced Pickaxe", recipe={"iron": 3, "copper": 1, "oak": 1}, value=105, legacy_slot="tool"),
    "rusted_sword": dict(kind="sword", tier=1, name="Rusted Sword", recipe={"iron": 1, "timber": 1}, value=30, legacy_slot="tool"),
    "steel_sword": dict(kind="sword", tier=2, name="Steel Sword", recipe={"steel_ingot": 1, "copper": 1, "oak": 1}, value=125, legacy_slot="tool"),
    "leather": dict(kind="light/body", tier=1, name="Leather Armor", recipe={"rabbit_hide": 2, "linen": 1}, value=38, legacy_slot="armor"),
    "chainmail": dict(kind="medium/body", tier=2, name="Chainmail", recipe={"iron": 4, "copper": 2}, value=138, legacy_slot="armor"),
}

# Found only on the fallen (never sold or crafted). Between tiers 4 and 5, with fixed rolls.
FOUND = [
    ("dwarven_pick", "Dwarven Pickaxe", "pickaxe", 900, {"yield": 12, "rare_find": 5}, "tool"),
    ("wardens_axe", "Warden's Axe", "felling_axe_kind", 800, {"yield": 12, "speed": 6}, "tool"),
    ("knights_blade", "Knight's Blade", "sword", 1100, {"damage": 10, "parry": 6}, "tool"),
    ("gilded_plate", "Gilded Plate", "heavy/body", 1500, {"armour": 8, "health": 15}, "armor"),
    ("nightfang", "Nightfang", "dagger", 1000, {"crit_chance": 6, "bleed": 8}, None),
    ("graveward_maul", "Graveward Maul", "mace", 1050, {"stun": 7, "health": 15}, None),
    ("huntmasters_spear", "Huntmaster's Spear", "spear", 950, {"first_strike": 15, "yield": 12}, None),
    ("stormstring", "Stormstring", "bow", 1200, {"first_strike": 15, "crit_chance": 5}, None),
    ("widowmaker", "Widowmaker", "crossbow", 1250, {"armour_pen": 12, "crit_damage": 25}, None),
    ("wanderers_rod", "Old Wanderer's Rod", "fishing_rod", 850, {"yield": 12, "rare_find": 6}, None),
    ("veil_of_ashes", "Veil of Ashes", "light/head", 900, {"dodge": 5, "crit_chance": 4}, None),
]

# ---------------------------------------------------------------- food, drink and potions
BUFFS = {
    "yield": "+{}% haul on any trip", "yield_logging": "+{}% logging haul", "yield_mining": "+{}% mining haul",
    "yield_foraging": "+{}% foraging haul", "yield_fishing": "+{}% fishing haul", "yield_hunting": "+{}% hunting haul",
    "yield_farming": "+{}% harvest", "injury": "{:+}% injury chance", "xp": "+{}% experience", "duration": "{:+}% trip time",
    "rare_find": "+{}% rare finds", "find_fallen": "+{}% chance to find gear of the fallen", "damage": "+{}% damage",
    "attack_speed": "+{}% attack speed", "crit_chance": "+{}% critical chance", "crit_damage": "+{}% critical damage",
    "armour": "+{}% armour", "health": "+{}% health", "heal": "Heals {} health", "poison": "Blade venom: +{}% damage as poison",
}
# id: (name, tier, recipe, buffs, blueprint sources, note)
FOOD = {
    "grilled_perch": ("Grilled Perch", 1, {"perch": 2, "timber": 1}, {"yield": 5}, ["quartermaster"], ""),
    "rabbit_stew": ("Rabbit Stew", 1, {"game_meat": 1, "cabbage": 1, "timber": 1}, {"injury": -10}, ["quartermaster"], ""),
    "brown_bread": ("Brown Bread", 1, {"flour": 1, "timber": 1}, {"xp": 8}, ["quartermaster"], ""),
    "berry_tart": ("Hedgeberry Tart", 1, {"berries": 2, "flour": 1}, {"duration": -5}, ["quartermaster"], ""),
    "hunters_jerky": ("Hunter's Jerky", 1, {"game_meat": 2, "timber": 1}, {"yield_hunting": 12}, ["quartermaster"], ""),
    "smoked_trout": ("Smoked Trout", 2, {"trout": 2, "oak": 1}, {"yield_fishing": 12}, ["quartermaster"], ""),
    "boar_roast": ("Boar Roast", 2, {"boar_meat": 1, "potato": 1, "oak": 1}, {"damage": 8}, ["quartermaster"], ""),
    "eel_pie": ("Eel Pie", 2, {"eel": 1, "flour": 1, "oak": 1}, {"rare_find": 10}, ["quartermaster"], ""),
    "honey_cakes": ("Honey Cakes", 2, {"honey": 1, "flour": 1}, {"attack_speed": 6}, ["quartermaster"], ""),
    "barley_ale": ("Barley Ale", 2, {"barley": 2, "honey": 1}, {"xp": 15, "injury": 5}, ["quartermaster"], "Strong stuff: they learn faster and fall over more."),
    "miners_pasty": ("Miner's Pasty", 2, {"boar_meat": 1, "potato": 1, "flour": 1}, {"yield_mining": 12}, ["quartermaster"], ""),
    "woodsmans_porridge": ("Woodsman's Porridge", 2, {"barley": 1, "honey": 1, "berries": 1}, {"yield_logging": 12}, ["quartermaster"], ""),
    "morel_soup": ("Morel Soup", 2, {"mushrooms": 2, "cabbage": 1, "oak": 1}, {"yield_foraging": 12}, ["quartermaster"], ""),
    "harvest_loaf": ("Harvest Loaf", 2, {"flour": 2, "honey": 1, "oak": 1}, {"yield_farming": 12}, ["quartermaster"], ""),
    "venison_steak": ("Peppered Venison", 3, {"venison": 1, "emberpepper": 1, "oak": 1}, {"damage": 12}, ["elkmoor"], ""),
    "pike_chowder": ("Pike Chowder", 3, {"pike": 1, "potato": 1, "cabbage": 1}, {"injury": -20}, ["glasswater"], ""),
    "sunpetal_tea": ("Sunpetal Tea", 3, {"sunpetal": 2, "honey": 1}, {"xp": 20}, ["sunreach"], ""),
    "ember_chili": ("Emberpepper Chili", 3, {"emberpepper": 2, "boar_meat": 1, "oak": 1}, {"crit_chance": 5}, ["glasshouse"], ""),
    "crab_boil": ("Greywater Crab Boil", 4, {"crab": 2, "potato": 1, "yew": 1}, {"yield": 12}, ["greywater_coast"], ""),
    "cod_supper": ("Cod Supper", 4, {"cod": 1, "potato": 1, "flour": 1}, {"duration": -10}, ["greywater_coast"], ""),
    "direbear_haunch": ("Direbear Haunch", 4, {"bear_meat": 1, "emberpepper": 1, "yew": 1}, {"health": 20}, ["bleakridge"], ""),
    "frostbloom_sorbet": ("Frostbloom Sorbet", 4, {"frostbloom": 1, "honey": 1, "berries": 1}, {"crit_damage": 20}, ["frostvale"], ""),
    "abyssal_feast": ("The Abyssal Feast", 5, {"abyssal_eel": 1, "emberpepper": 1, "flour": 1, "ironwood": 1}, {"rare_find": 20, "find_fallen": 15}, ["drowned_deep"], "A feast before a deep run."),
}
POTIONS = {
    "healing_draught": ("Healing Draught", 1, {"herbs": 3, "copper": 1}, {"heal": 40}, ["quartermaster"], "Drunk when hurt, in the field or mid-dungeon."),
    "swiftfoot_draught": ("Swiftfoot Draught", 2, {"berries": 2, "honey": 1, "mushrooms": 1}, {"duration": -10}, ["quartermaster"], ""),
    "ironskin_tonic": ("Ironskin Tonic", 2, {"bloodcap": 1, "mushrooms": 1, "bone": 2}, {"armour": 10}, ["quartermaster"], ""),
    "greater_draught": ("Greater Draught", 3, {"bloodcap": 2, "herbs": 2, "silver": 1}, {"heal": 100}, ["calder_keep"], "Drunk when hurt; heals fully."),
    "nightshade_venom": ("Nightshade Venom", 3, {"nightshade": 2, "fish_oil": 1}, {"poison": 12}, ["sunreach"], "Coats the blade for one run."),
    "fortunes_brew": ("Fortune's Brew", 4, {"frostbloom": 1, "pearl": 1, "sunpetal": 1}, {"rare_find": 15}, ["frostvale"], ""),
    "elixir_of_fury": ("Elixir of Fury", 4, {"emberpepper": 2, "bloodcap": 1, "emberstone": 1}, {"crit_damage": 25}, ["sunken_abbey"], ""),
}

# ---------------------------------------------------------------- trinkets, packs, lanterns
TRINKETS = {
    "amber_charm": ("Amber Charm", 1, {"amber": 1, "copper": 1}, {"xp": 5}, ["quartermaster"]),
    "bone_charm": ("Bone Charm", 1, {"bone": 3, "linen": 1}, {"injury_resist": 5}, ["quartermaster"]),
    "fang_necklace": ("Fang Necklace", 2, {"fang": 3, "linen": 1}, {"crit_chance": 3}, ["quartermaster"]),
    "garnet_ring": ("Garnet Ring", 2, {"garnet": 1, "silver": 1}, {"crit_damage": 15}, ["quartermaster"]),
    "pearl_pendant": ("Pearl Pendant", 3, {"pearl": 1, "silver": 1}, {"rare_find": 5}, ["glasswater"]),
    "antler_talisman": ("Antler Talisman", 3, {"antler": 2, "elk_hide": 1}, {"yield": 12}, ["elkmoor"]),
    "crystal_amulet": ("Crystal Amulet", 3, {"crystal": 1, "silver": 2}, {"rare_find": 8}, ["calder_keep"]),
    "emberstone_ring": ("Emberstone Ring", 4, {"emberstone": 1, "silversteel_ingot": 1}, {"damage": 8}, ["gloamhold"]),
    "relic_idol": ("Relic Idol", 4, {"relic": 1, "ironwood": 1}, {"xp": 15}, ["sunken_abbey"]),
    "voidpearl_amulet": ("Voidpearl Amulet", 5, {"voidpearl": 1, "silversteel_ingot": 1, "shadowsilk": 1}, {"rare_find": 15}, ["drowned_deep"]),
}
TRINKET_POOL = ["xp", "rare_find", "crit_chance", "crit_damage", "health", "injury_resist", "yield"]
PACKS = {
    "linen_satchel": ("Linen Satchel", 1, {"linen": 2, "rabbit_hide": 1}, 10, ["quartermaster"]),
    "leather_pack": ("Wolfhide Pack", 2, {"wolf_pelt": 2, "linen": 1, "copper": 1}, 15, ["quartermaster"]),
    "frame_pack": ("Yew Frame Pack", 3, {"yew": 2, "elk_hide": 2}, 20, ["thornwald"]),
    "ironwood_frame": ("Ironwood Frame Pack", 4, {"ironwood": 2, "direbear_pelt": 1, "shadowsilk": 1}, 25, ["blackroot_weald"]),
    "ghostwood_frame": ("Ghostwood Frame Pack", 5, {"ghostwood": 2, "wyrmscale": 1, "shadowsilk": 1}, 30, ["palewood"]),
}
PACK_POOL = ["carry", "speed", "sturdy"]
LANTERNS = {
    "copper_lantern": ("Copper Lantern", 1, {"copper": 2, "fish_oil": 1}, 3, ["quartermaster"]),
    "crystal_lantern": ("Crystal Lantern", 3, {"silver": 1, "crystal": 1, "fish_oil": 1}, 6, ["cinder_shaft"]),
    "voidpearl_lantern": ("Voidpearl Lantern", 5, {"silversteel_ingot": 1, "voidpearl": 1}, 10, ["wyrms_hollow"]),
}
LANTERN_POOL = ["rare_find", "xp", "sturdy"]

INTERMEDIATES = {
    "steel_ingot": ("Steel Ingot", 2, {"iron": 2, "coal": 1}, "Smelted iron. Tier-2 metal and the base of silversteel."),
    "silversteel_ingot": ("Silversteel Ingot", 3, {"steel_ingot": 1, "silver": 1, "coal": 1}, "Tier-3 metal."),
    "linen": ("Linen", 1, {"flax": 3}, "Cloth for tier-1 armour, satchels, line and bowstrings."),
    "flour": ("Flour", 1, {"wheat": 2}, "Bread, pies and cakes."),
    "fish_oil": ("Fish Oil", 1, {"perch": 2}, "Lantern oil and blade venom."),
    "bone_meal": ("Bone Meal", 1, {"bone": 3}, "Spread on the fields: +15% harvest on the next farming trip."),
}

# ---------------------------------------------------------------- company upgrades
UPGRADES = {
    "charter_1": ("Expedition Charter I", {"timber": 40, "iron": 20}, "A second crew in the field", []),
    "charter_2": ("Expedition Charter II", {"oak": 40, "steel_ingot": 10}, "A third crew in the field", []),
    "charter_3": ("Expedition Charter III", {"oak": 60, "silversteel_ingot": 10}, "A fourth crew in the field", []),
    "charter_4": ("Expedition Charter IV", {"oak": 80, "silversteel_ingot": 25, "crystal": 10}, "A fifth crew in the field", []),
    "field_plots": ("Field Plots", {"timber": 30, "iron": 6}, "Opens the Tilled Acres (barley, potatoes)", ["tilled_acres"]),
    "apiary": ("Apiary", {"timber": 20, "linen": 4}, "Opens the Beehives (honey)", ["beehives"]),
    "glasshouse_build": ("Glasshouse", {"oak": 30, "crystal": 2, "iron": 8}, "Opens the Glasshouse (emberpepper)", ["glasshouse"]),
}

# Expedition charters are the only way to field more crews: gold plus materials, and from the
# third crew on, a reputation tier. charter_N opens slot N+1, in order.
CHARTERS = {"charter_1": {"gold": 1200, "rep": 0}, "charter_2": {"gold": 8000, "rep": 5000},
            "charter_3": {"gold": 30000, "rep": 25000}, "charter_4": {"gold": 90000, "rep": 75000}}

CRAFT_MARKUP = 1.4
BLUEPRINT_PRICE = {1: 40, 2: 150}


def slug(s):
    return re.sub(r"[^a-z0-9]+", "_", s.lower()).strip("_")


def build():
    mats = {k: {"name": n, "tier": t, "group": g, "value": v, "sources": s, "note": note, "sell_only": k in SELL_ONLY}
            for k, (n, t, g, v, s, note) in MATERIALS.items()}
    items = {}

    def value_of(k):
        return mats[k]["value"] if k in mats else items[k]["value"]

    def cost(recipe):
        return sum(q * value_of(m) for m, q in recipe.items())

    def recipe_for(shape, t):
        r = {}
        for key, q in shape.items():
            if key == "R" and t < 3:
                continue
            if key == "F" and t > 3:
                continue
            m = {"M": METAL.get(t), "W": WOOD.get(t), "H": HIDE.get(t), "C": CLOTH.get(t), "F": "feathers", "R": "resin"}.get(key, key)
            r[m] = r.get(m, 0) + q
        return r

    def blueprints(t, local=None):
        if t <= 2:
            return ["quartermaster"]
        return ([local] if local else []) + [DUNGEON_FOR[t]]

    def add(k, item, legacy=None):
        assert k not in items and k not in mats, k
        if legacy:
            item["name"] = legacy["name"]
            item["recipe"] = legacy["recipe"]
            item["value"] = legacy["value"]
            item["legacy_slot"] = legacy["legacy_slot"]
        elif item.get("recipe") is not None and "value" not in item:
            item["value"] = int(round(cost(item["recipe"]) * CRAFT_MARKUP))
        if item.get("blueprint") == ["quartermaster"]:
            item["blueprint_price"] = BLUEPRINT_PRICE.get(item["tier"], 150)
        items[k] = item

    legacy_by = {(v["kind"], v["tier"]): (k, v) for k, v in LEGACY.items()}

    for k, (n, t, r, note) in INTERMEDIATES.items():
        add(k, {"name": n, "category": "material", "kind": "consumable" if k == "bone_meal" else "intermediate", "slot": "none",
                "tier": t, "recipe": r, "blueprint": ["crafting"], "note": note})

    def gear(k, name, category, kind, slot, t, stats, pool, recipe, bp, extra=None, hands=1):
        weight = SLOT_WEIGHT.get(slot, 0) * (1.5 if hands == 2 else 1)
        item = {"name": name, "category": category, "kind": kind, "slot": slot, "tier": t, "stats": stats,
                "rolls": pool, "durability": DURABILITY[t], "kit": int(round(t * weight)), "recipe": recipe,
                "blueprint": bp, "found_only": False}
        if hands == 2:
            item["hands"] = 2
        if extra:
            item.update(extra)
        lg = legacy_by.get((kind, t))
        if lg:
            add(lg[0], item, lg[1])
        else:
            add(k, item)

    def weapon_stats(fam, t):
        f = FAMILIES[fam]
        s = {"damage": int(round(POWER[t] * f["dmg"])), "attack_speed": f["spd"], "crit_chance": f["crit"], "crit_damage": f["critx"]}
        s.update(f["extra"])
        return s

    def armour_stats(weight, piece, t):
        a = ARMOUR_WEIGHTS[weight]
        share = PIECE_SHARE[piece]
        stats = {"armour": int(round(ARMOUR[t] * a["mult"] * share))}
        for sk, sv in a["extra"].items():
            stats[sk] = round(sv * share, 3)
        return stats

    for t in TIERS:
        for fam, f in FAMILIES.items():
            if fam == "bow":
                name = BOW_NAMES[t]
            elif fam == "crossbow":
                name = "%s Crossbow" % WOOD_NAME[t]
            else:
                name = "%s %s" % (METAL_NAME[t], f["name"])
            gear(slug(name), name, "weapon", fam, "main_hand", t, weapon_stats(fam, t), f["pool"],
                 recipe_for(f["shape"], t), blueprints(t), hands=f["hands"])
        for kind, s in SHIELDS.items():
            name = "%s %s" % (METAL_NAME[t], s["name"])
            stats = {"armour": int(round(ARMOUR[t] * s["armour"])), "block": s["block"]}
            stats.update(s["extra"])
            gear(slug(name), name, "shield", kind, "off_hand", t, stats, s["pool"], recipe_for(s["shape"], t), blueprints(t))
        for weight, a in ARMOUR_WEIGHTS.items():
            for piece in PIECE_SHARE:
                name = "%s %s" % (a["names"][t], a["pieces"][piece])
                u = PIECE_UNITS[piece]
                if weight == "light":
                    recipe = {HIDE[t]: u, CLOTH[t]: 1}
                elif weight == "medium":
                    recipe = {METAL[t]: u, HIDE[t]: 1}
                else:
                    recipe = {METAL[t]: u + 1, HIDE[t]: 1}
                gear(slug(name), name, "armour", "%s/%s" % (weight, piece), piece, t, armour_stats(weight, piece, t),
                     a["pool"], recipe, blueprints(t), {"weight": weight})
        for kind, (trade, base, shape, top) in TOOLS.items():
            if t > top:
                continue
            if kind == "fishing_rod":
                name = "%s %s" % (WOOD_NAME[t], base)
            elif kind == "sickle" and t == 1:
                name = "Copper Sickle"
            else:
                name = "%s %s" % (METAL_NAME[t], base)
            recipe = recipe_for(shape, t)
            if kind == "sickle" and t == 1:
                recipe = {"copper": 1, "timber": 1}
            local = next((k for k, s in SOURCES.items() if s[2] == trade and s[3] == t), None)
            gear(slug(name), name, "tool", kind, "main_hand", t, {trade: TOOL[t]}, TOOL_POOL, recipe, blueprints(t, local),
                 {"trade": trade})

    for k, (n, t, r, find, bp) in LANTERNS.items():
        add(k, {"name": n, "category": "lantern", "kind": "lantern", "slot": "off_hand", "tier": t, "stats": {"rare_find": find},
                "rolls": LANTERN_POOL, "durability": DURABILITY[t], "kit": 0, "recipe": r, "blueprint": bp, "found_only": False,
                "note": "Lights the way in mines and dungeons: more rare finds, but no armour."})
    for k, (n, t, r, stats, bp) in TRINKETS.items():
        add(k, {"name": n, "category": "trinket", "kind": "trinket", "slot": "trinket", "tier": t, "stats": stats,
                "rolls": TRINKET_POOL, "durability": None, "kit": 0, "recipe": r, "blueprint": bp, "found_only": False})
    for k, (n, t, r, carry, bp) in PACKS.items():
        add(k, {"name": n, "category": "pack", "kind": "pack", "slot": "back", "tier": t, "stats": {"carry": carry},
                "rolls": PACK_POOL, "durability": DURABILITY[t], "kit": 0, "recipe": r, "blueprint": bp, "found_only": False,
                "note": "Carries more home from gathering trips."})
    for k, (n, t, r, buffs, bp, note) in FOOD.items():
        add(k, {"name": n, "category": "food", "kind": "food", "slot": "food", "tier": t, "buffs": buffs, "recipe": r,
                "blueprint": bp, "note": note or "Eaten on the next trip."})
    for k, (n, t, r, buffs, bp, note) in POTIONS.items():
        add(k, {"name": n, "category": "potion", "kind": "potion", "slot": "potion", "tier": t, "buffs": buffs, "recipe": r,
                "blueprint": bp, "note": note or "Drunk at the start of the next trip."})

    for k, n, kind, value, rolls, lslot in FOUND:
        t = 4.5
        if kind in FAMILIES:
            stats, cat, slot, hands = weapon_stats(kind, t), "weapon", "main_hand", FAMILIES[kind]["hands"]
        elif kind in TOOLS:
            stats, cat, slot, hands = {TOOLS[kind][0]: TOOL[t]}, "tool", "main_hand", 1
        else:
            weight, piece = kind.split("/")
            stats, cat, slot, hands = armour_stats(weight, piece, t), "armour", piece, 1
        w = SLOT_WEIGHT.get(slot, 0) * (1.5 if hands == 2 else 1)
        item = {"name": n, "category": cat, "kind": kind, "slot": slot, "tier": 4, "stats": stats, "fixed_rolls": rolls,
                "durability": 100, "kit": int(round(4.5 * w)), "recipe": None, "blueprint": [], "value": value, "found_only": True}
        if hands == 2:
            item["hands"] = 2
        if kind in TOOLS:
            item["trade"] = TOOLS[kind][0]
        if "/" in kind:
            item["weight"] = kind.split("/")[0]
        if lslot:
            item["legacy_slot"] = lslot
        items[k] = item

    sources = {}
    for k, (n, kind, trade, t, status, extra) in SOURCES.items():
        s = {"name": n, "kind": kind, "trade": trade, "tier": t, "status": status}
        if kind in ("site", "farm"):
            s["level"] = LEVEL[t]
        s.update(extra)
        sources[k] = s

    return {
        "version": 2, "sources": sources, "materials": mats, "items": items,
        "affixes": {k: {"name": n, "text": txt, "low": lo, "high": hi} for k, (n, txt, lo, hi) in AFFIXES.items()},
        "rarity": RARITY,
        "families": {**{k: {"name": f["name"], "hands": f["hands"], "blurb": f["blurb"]} for k, f in FAMILIES.items()},
                     **{k: {"name": s["name"], "hands": 1, "blurb": s["blurb"]} for k, s in SHIELDS.items()}},
        "armour_weights": {k: {"blurb": a["blurb"]} for k, a in ARMOUR_WEIGHTS.items()},
        "buffs": BUFFS,
        "upgrades": {k: dict({"name": n, "cost": c, "effect": e, "unlocks": u}, **CHARTERS.get(k, {})) for k, (n, c, e, u) in UPGRADES.items()},
        "rules": {"craft_markup": CRAFT_MARKUP, "affix_scale": {str(k): v for k, v in AFFIX_SCALE.items()},
                  "slot_weight": SLOT_WEIGHT, "two_hand_weight": 6, "dungeon_min_kit": {"1": 8, "2": 24, "3": 36},
                  "wear": {"site_trip": 1, "dungeon_run": 4}, "worn_effect": 0.5},
    }


if __name__ == "__main__":
    os.makedirs("data", exist_ok=True)
    cat = build()
    with open("data/catalog.json", "w") as f:
        json.dump(cat, f, indent=1)
    by = {}
    for v in cat["items"].values():
        by[v["category"]] = by.get(v["category"], 0) + 1
    print("catalog: %d sources, %d materials, %d items %s, %d stat rolls, %d upgrades" % (
        len(cat["sources"]), len(cat["materials"]), len(cat["items"]), by, len(cat["affixes"]), len(cat["upgrades"])))
