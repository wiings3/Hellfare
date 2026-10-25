"""Authoring script for the item catalog (run from the project root).

Writes data/catalog.json: every source, material, piece of gear, consumable and crafting
intermediate in Money Mercs, with tiers, values, recipes and where blueprints come from.
The game and tests/catalog_test.gd read the JSON; edit this script and re-run it to change
the catalog. Ids already used by saves (timber, copper, basic_pick, ...) never change.

Conventions
- Tiers 1-5. The quartermaster sells blueprints for tier 1-2 gear; gear of tier N+2 has its
  blueprint dropped in the tier-N dungeon (Calder Keep -> 3, Sunken Abbey -> 4, Wyrm's Hollow -> 5).
- Crafted gear is worth about 1.4x its materials; the validator keeps it within 1.1-2.2x.
- Gear stat ladder per kind: 1, 2, 3, 4, 6 by tier; found-only pieces sit at 5, between the
  crafted tier 4 and tier 5, so each one is a jackpot worth chasing.
- Durability counts uses: a work-site trip costs 1, a dungeon run 4 (about 20 trips or
  5 dungeon runs for tier-1 gear). Worn-out gear works at half effect until repaired.
- Kit rating: each piece adds 10 per tier (+5 for found-only). Dungeons need a minimum
  per mercenary: tier 1 = 10, tier 2 = 40, tier 3 = 70.
"""
import json, math

SOURCES = {
    # Work sites (live today)
    "mossward_copse": {"name": "Mossward Copse", "kind": "site", "trade": "logging", "tier": 1, "status": "live"},
    "old_oakwood": {"name": "Old Oakwood", "kind": "site", "trade": "logging", "tier": 2, "status": "live"},
    "harlow": {"name": "Harlow Mines", "kind": "site", "trade": "mining", "tier": 1, "status": "live"},
    "deepdelve": {"name": "Deepdelve", "kind": "site", "trade": "mining", "tier": 2, "status": "live"},
    # Work sites still to come
    "thornwald": {"name": "Thornwald", "kind": "site", "trade": "logging", "tier": 3, "status": "planned"},
    "blackroot_weald": {"name": "Blackroot Weald", "kind": "site", "trade": "logging", "tier": 4, "status": "planned"},
    "cinder_shaft": {"name": "Cinder Shaft", "kind": "site", "trade": "mining", "tier": 3, "status": "planned"},
    "mossward_meadows": {"name": "Mossward Meadows", "kind": "site", "trade": "foraging", "tier": 1, "status": "planned"},
    "fenmire": {"name": "Fenmire", "kind": "site", "trade": "foraging", "tier": 2, "status": "planned"},
    # Dungeons
    "calder_keep": {"name": "Calder Keep", "kind": "dungeon", "trade": "combat", "tier": 1, "status": "planned"},
    "sunken_abbey": {"name": "The Sunken Abbey", "kind": "dungeon", "trade": "combat", "tier": 2, "status": "planned"},
    "wyrms_hollow": {"name": "Wyrm's Hollow", "kind": "dungeon", "trade": "combat", "tier": 3, "status": "planned"},
    # Other ways in
    "quartermaster": {"name": "Quartermaster", "kind": "shop", "trade": "", "tier": 0, "status": "live"},
    "fallen": {"name": "Gear of the fallen", "kind": "found", "trade": "", "tier": 0, "status": "live"},
    "crafting": {"name": "Crafting", "kind": "craft", "trade": "", "tier": 0, "status": "planned"},
}

# id: name, tier, group, value, sources, note. Ids of the eight goods in today's game are kept.
MATERIALS = {
    # Timber: each forest gives its own grade; handles and repairs need the matching grade.
    "timber": ("Birch Timber", 1, "timber", 6, ["mossward_copse"], "Handles for basic tools and weapons."),
    "oak": ("Oak Timber", 2, "timber", 14, ["old_oakwood"], "Handles for tier-2 gear, clubs and hunting bows."),
    "yew": ("Yew Timber", 3, "timber", 30, ["thornwald"], "Longbows and tier-3 handles."),
    "ironwood": ("Ironwood", 4, "timber", 65, ["blackroot_weald"], "Tier-4 handles and hafts."),
    "ghostwood": ("Ghostwood", 5, "timber", 150, ["wyrms_hollow"], "Pale wood from the wyrm's lair; tier-5 gear."),
    # Ores, fuel and metal
    "copper": ("Copper Ore", 1, "ore", 20, ["harlow"], "Rivets, fittings, sickles."),
    "coal": ("Coal", 1, "ore", 8, ["harlow", "cinder_shaft"], "Fuel for smelting steel."),
    "iron": ("Iron Ore", 1, "ore", 17, ["harlow", "deepdelve", "cinder_shaft"], "Tools, blades, mail and most repairs. Harlow gives a little as a side find; Deepdelve is the main seam."),
    "silver": ("Silver", 2, "ore", 28, ["deepdelve"], "Fine fittings, blades and healing draughts."),
    "crystal": ("Azure Crystal", 3, "gem", 75, ["deepdelve", "cinder_shaft"], "Focus stones for tier-4 and tier-5 gear."),
    "gloomiron": ("Gloomiron", 4, "dungeon", 120, ["sunken_abbey"], "Dark deep-metal; tier-4 gear."),
    "wyrmbone": ("Wyrmbone", 5, "dungeon", 400, ["wyrms_hollow"], "Bone of the wyrm; tier-5 gear."),
    # Plants, hides and fibre
    "herbs": ("Moonleaf", 1, "herb", 5, ["old_oakwood", "mossward_meadows"], "Healing draughts and tanning."),
    "bloodcap": ("Bloodcap", 2, "herb", 18, ["fenmire"], "Greater healing draughts."),
    "wolf_pelt": ("Wolf Pelt", 2, "hide", 22, ["old_oakwood"], "Hardened leather armour."),
    "spider_silk": ("Spider Silk", 2, "fibre", 26, ["calder_keep", "deepdelve"], "Bowstrings and padded linings."),
    # Treasures: collectors' prizes, also the rarest crafting inputs
    "relic": ("Ancient Relic", 4, "treasure", 550, ["old_oakwood", "calder_keep", "sunken_abbey"], "Carved idols; tier-5 gear needs one."),
    "sovereign": ("Sovereign Orb", 5, "treasure", 12500, ["wyrms_hollow"], "The rarest prize. Reserved for a future mythic tier."),
}
# Materials that may have no crafting use yet (sold to collectors and merchants).
SELL_ONLY = {"sovereign"}

STAT = {1: 1, 2: 2, 3: 3, 4: 4, 5: 6}
DURABILITY = {1: 30, 2: 40, 3: 50, 4: 60, 5: 80}
FOUND = {"durability": 100, "stat": 5, "tier": 4}

# Gear: id -> (name, kind, slot, tier, stat key, recipe, blueprint sources, extra)
# blueprint sources: "quartermaster" = bought for gold; dungeon ids = dropped there.
GEAR = [
    # Axes (logging)
    ("hand_axe", "Hand Axe", "axe", "tool", 1, "logging", {"iron": 1, "timber": 1}, ["quartermaster"], {"legacy_cost": 26}),
    ("felling_axe", "Felling Axe", "axe", "tool", 2, "logging", {"iron": 3, "oak": 2}, ["quartermaster"], {"legacy_cost": 98}),
    ("steel_felling_axe", "Steel Felling Axe", "axe", "tool", 3, "logging", {"steel_ingot": 3, "yew": 2}, ["calder_keep"], {}),
    ("gloomiron_axe", "Gloomiron Axe", "axe", "tool", 4, "logging", {"gloomiron": 2, "ironwood": 2, "steel_ingot": 1}, ["sunken_abbey"], {}),
    ("wyrmbone_axe", "Wyrmbone Axe", "axe", "tool", 5, "logging", {"wyrmbone": 2, "ghostwood": 2, "relic": 1}, ["wyrms_hollow"], {}),
    # Pickaxes (mining)
    ("basic_pick", "Iron Pickaxe", "pickaxe", "tool", 1, "mining", {"iron": 1, "timber": 1}, ["quartermaster"], {"legacy_cost": 28}),
    ("reinforced_pick", "Reinforced Pickaxe", "pickaxe", "tool", 2, "mining", {"iron": 3, "copper": 1, "oak": 1}, ["quartermaster"], {"legacy_cost": 105}),
    ("steel_pick", "Steel Pickaxe", "pickaxe", "tool", 3, "mining", {"steel_ingot": 3, "yew": 2}, ["calder_keep"], {}),
    ("gloomiron_pick", "Gloomiron Pickaxe", "pickaxe", "tool", 4, "mining", {"gloomiron": 2, "ironwood": 2, "crystal": 1}, ["sunken_abbey"], {}),
    ("wyrmbone_pick", "Wyrmbone Pickaxe", "pickaxe", "tool", 5, "mining", {"wyrmbone": 2, "ghostwood": 2, "relic": 1}, ["wyrms_hollow"], {}),
    # Sickles (foraging)
    ("copper_sickle", "Copper Sickle", "sickle", "tool", 1, "foraging", {"copper": 1, "timber": 1}, ["quartermaster"], {}),
    ("iron_sickle", "Iron Sickle", "sickle", "tool", 2, "foraging", {"iron": 2, "oak": 1}, ["quartermaster"], {}),
    ("silver_sickle", "Silver Sickle", "sickle", "tool", 3, "foraging", {"silver": 3, "yew": 1, "steel_ingot": 1}, ["calder_keep"], {}),
    # Swords (combat)
    ("rusted_sword", "Rusted Sword", "sword", "tool", 1, "guard", {"iron": 1, "timber": 1}, ["quartermaster"], {"legacy_cost": 30}),
    ("steel_sword", "Steel Sword", "sword", "tool", 2, "guard", {"steel_ingot": 1, "copper": 1, "oak": 1}, ["quartermaster"], {"legacy_cost": 125, "stat": 3}),
    ("longsword", "Longsword", "sword", "tool", 3, "guard", {"steel_ingot": 3, "silver": 1, "yew": 1}, ["calder_keep"], {"stat": 4}),
    ("gloomiron_blade", "Gloomiron Blade", "sword", "tool", 4, "guard", {"gloomiron": 2, "steel_ingot": 1, "ironwood": 1}, ["sunken_abbey"], {"stat": 6}),
    ("wyrmbone_greatsword", "Wyrmbone Greatsword", "sword", "tool", 5, "guard", {"wyrmbone": 2, "crystal": 2, "ghostwood": 1, "relic": 1}, ["wyrms_hollow"], {"stat": 8}),
    # Clubs and bows: weapons that are mostly timber
    ("oak_club", "Oak Club", "club", "tool", 2, "guard", {"oak": 2, "copper": 1}, ["quartermaster"], {}),
    ("hunting_bow", "Hunting Bow", "bow", "tool", 2, "guard", {"oak": 3, "spider_silk": 1}, ["quartermaster"], {"stat": 2, "perk": "Strikes first when hunting rival crews."}),
    ("yew_longbow", "Yew Longbow", "bow", "tool", 3, "guard", {"yew": 3, "spider_silk": 2}, ["calder_keep"], {"stat": 4, "perk": "Strikes first when hunting rival crews."}),
    ("ghostwood_bow", "Ghostwood Bow", "bow", "tool", 5, "guard", {"ghostwood": 3, "spider_silk": 2, "wyrmbone": 1}, ["wyrms_hollow"], {"stat": 7, "perk": "Strikes first when hunting rival crews."}),
    # Armour
    ("leather", "Leather Armor", "armour", "armor", 1, "protection", {"herbs": 2, "copper": 1}, ["quartermaster"], {"legacy_cost": 38}),
    ("hardened_leather", "Hardened Leather", "armour", "armor", 2, "protection", {"wolf_pelt": 3, "herbs": 2, "copper": 1}, ["quartermaster"], {}),
    ("chainmail", "Chainmail", "armour", "armor", 2, "protection", {"iron": 4, "copper": 2}, ["quartermaster"], {"legacy_cost": 138, "stat": 3}),
    ("steel_plate", "Steel Plate", "armour", "armor", 3, "protection", {"steel_ingot": 4, "wolf_pelt": 1}, ["calder_keep"], {"stat": 4}),
    ("gloomiron_plate", "Gloomiron Plate", "armour", "armor", 4, "protection", {"gloomiron": 3, "steel_ingot": 2, "spider_silk": 1}, ["sunken_abbey"], {"stat": 6}),
    ("wyrmscale_armour", "Wyrmscale Armour", "armour", "armor", 5, "protection", {"wyrmbone": 3, "spider_silk": 2, "relic": 1}, ["wyrms_hollow"], {"stat": 8}),
]

# Found only on the fallen: never sold, never crafted. One per kind, between tier 4 and 5.
FOUND_GEAR = [
    ("dwarven_pick", "Dwarven Pickaxe", "pickaxe", "tool", "mining", 900),
    ("wardens_axe", "Warden's Axe", "axe", "tool", "logging", 800),
    ("knights_blade", "Knight's Blade", "sword", "tool", "guard", 1100, 7),
    ("gilded_plate", "Gilded Plate", "armour", "armor", "protection", 1500, 7),
]

# Consumables and intermediates
OTHER = [
    ("steel_ingot", "Steel Ingot", "intermediate", 2, {"iron": 2, "coal": 1}, ["crafting"], "Smelted from iron and coal; most tier-3 and tier-4 gear needs it."),
    ("healing_draught", "Healing Draught", "consumable", 1, {"herbs": 3, "copper": 1}, ["quartermaster"], "Restores 40 health, in town or mid-dungeon."),
    ("greater_draught", "Greater Draught", "consumable", 3, {"bloodcap": 2, "herbs": 2, "silver": 1}, ["calder_keep"], "Restores full health, in town or mid-dungeon."),
]
CRAFT_MARKUP = 1.4
BLUEPRINT_PRICE = {1: 40, 2: 150, 3: 450}  # quartermaster prices; dungeon blueprints are loot


def build():
    mats = {}
    for k, (name, tier, group, value, sources, note) in MATERIALS.items():
        mats[k] = {"name": name, "tier": tier, "group": group, "value": value, "sources": sources, "note": note,
                   "sell_only": k in SELL_ONLY}
    items = {}
    # Intermediates first, so gear recipes can price them.
    for (k, name, kind, tier, recipe, bp, note) in OTHER:
        items[k] = {"name": name, "kind": kind, "slot": "none", "tier": tier, "recipe": recipe, "blueprint": bp, "note": note}

    def material_cost(recipe):
        total = 0.0
        for m, q in recipe.items():
            total += q * (mats[m]["value"] if m in mats else items[m]["value"])
        return total

    for k in [x[0] for x in OTHER]:
        items[k]["value"] = int(round(material_cost(items[k]["recipe"]) * CRAFT_MARKUP))
    for (k, name, kind, slot, tier, stat, recipe, bp, extra) in GEAR:
        value = extra.get("legacy_cost") or int(round(material_cost(recipe) * CRAFT_MARKUP))
        item = {"name": name, "kind": kind, "slot": slot, "tier": tier,
                "stats": {stat: extra.get("stat", STAT[tier])}, "durability": DURABILITY[tier], "kit": tier * 10,
                "recipe": recipe, "blueprint": bp, "value": value, "found_only": False}
        if bp == ["quartermaster"]:
            item["blueprint_price"] = BLUEPRINT_PRICE.get(tier, 450)
        if "perk" in extra:
            item["perk"] = extra["perk"]
        items[k] = item
    for row in FOUND_GEAR:
        k, name, kind, slot, stat, value = row[:6]
        items[k] = {"name": name, "kind": kind, "slot": slot, "tier": FOUND["tier"], "stats": {stat: row[6] if len(row) > 6 else FOUND["stat"]},
                    "durability": FOUND["durability"], "kit": FOUND["tier"] * 10 + 5, "recipe": None, "blueprint": [],
                    "value": value, "found_only": True}
    return {"version": 1, "sources": SOURCES, "materials": mats, "items": items,
            "rules": {"craft_markup": CRAFT_MARKUP, "kit_per_tier": 10, "found_kit_bonus": 5,
                      "dungeon_min_kit": {"1": 10, "2": 40, "3": 70},
                      "wear": {"site_trip": 1, "dungeon_run": 4}, "worn_effect": 0.5}}


if __name__ == "__main__":
    import os
    os.makedirs("data", exist_ok=True)
    cat = build()
    with open("data/catalog.json", "w") as f:
        json.dump(cat, f, indent=1)
    gear = [k for k, v in cat["items"].items() if v.get("slot") != "none"]
    print("catalog: %d sources, %d materials, %d items (%d gear)" % (len(cat["sources"]), len(cat["materials"]), len(cat["items"]), len(gear)))
