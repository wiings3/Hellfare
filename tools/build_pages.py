"""Authoring script for the redesigned journal chapters (run from the project root).

It writes ordinary editor scenes into scenes/journal/. After generation, the scenes
are the source of truth: adjust them in the Godot editor. Re-running this script
overwrites them, so only re-run it deliberately.
"""
from scene_gen import Scene, Raw, Res, page, label, button, spacer, scroll, HEADER, TILE, SLOT, INFO, PIPS

P = "scenes/journal/pages/"
R = "scenes/journal/rows/"
C = "Margin/Content"
ICON = "res://assets/ui/icons/"
KIT = "res://assets/ui/kit/"


# Trade skill rows, in the order pages list them.
TRADE_LABELS = ["Logging", "Mining", "Foraging", "Fishing", "Hunting", "Farming", "Combat"]

# The Workshop's recipe filters: (node, label, tooltip).
CRAFT_GROUPS = [("All", "All", "Every blueprint you know."), ("Tools", "Tools", "Axes, picks, sickles, rods and hoes."),
                ("Weapons", "Arms", "Weapons for guards and hunters."), ("Armour", "Armour", "Armour, shields, packs and trinkets."),
                ("Supplies", "Food", "Food and potions for the next trip."), ("Materials", "Goods", "Ingots, flour, cloth and other made goods.")]

def header(s, path, text):
    s.inst(path, HEADER, {"text": text})


def tile(s, path, caption, value="0", icon=None, extra=None):
    props = {"size_flags_horizontal": 3, "caption": caption, "value": value}
    if icon:
        props["icon"] = Res(icon)
    props.update(extra or {})
    s.inst(path, TILE, props)


# --- Rows ---------------------------------------------------------------------
def item_card():
    s = Scene("ItemCard", "PanelContainer", {"theme_type_variation": Raw('&"InsetPanel"')})
    s.node("Row", "HBoxContainer", {"theme_override_constants/separation": 6})
    s.node("Row/IconSlot", "PanelContainer", {"custom_minimum_size": (24, 24), "size_flags_vertical": 4, "theme_type_variation": Raw('&"SlotPanel"')})
    s.node("Row/IconSlot/Icon", "TextureRect", {"custom_minimum_size": (16, 16), "mouse_filter": 2, "expand_mode": 1, "stretch_mode": 5})
    s.node("Row/Info", "VBoxContainer", {"size_flags_horizontal": 3, "size_flags_vertical": 4, "theme_override_constants/separation": -4})
    label(s, "Row/Info/Name", "Item", extra={"text_overrun_behavior": 3})
    label(s, "Row/Info/Details", "Details", "LabelCaption", {"text_overrun_behavior": 3})
    button(s, "Row/Tertiary", "Repair", "PaperButton", {"visible": False, "size_flags_vertical": 4})
    button(s, "Row/Secondary", "Sell", "PaperButton", {"visible": False, "size_flags_vertical": 4})
    button(s, "Row/Primary", "Buy", "PaperButton", {"size_flags_vertical": 4})
    s.save(R + "item_card.tscn")


def gear_slot():
    """A clickable equipment slot with a durability bar along the bottom."""
    s = Scene("GearSlot", "Button", {"custom_minimum_size": (34, 34), "mouse_default_cursor_shape": 2,
        "theme_type_variation": Raw('&"CardButton"'), "toggle_mode": True})
    s.inst("Slot", SLOT, {"layout_mode": 1, "anchors_preset": 8, "anchor_left": 0.5, "anchor_top": 0.5, "anchor_right": 0.5, "anchor_bottom": 0.5,
        "offset_left": -14.0, "offset_top": -16.0, "offset_right": 14.0, "offset_bottom": 12.0, "mouse_filter": 2})
    s.node("Wear", "ProgressBar", {"layout_mode": 1, "anchors_preset": 12, "anchor_top": 1.0, "anchor_right": 1.0, "anchor_bottom": 1.0,
        "offset_left": 4.0, "offset_top": -5.0, "offset_right": -4.0, "offset_bottom": -2.0, "mouse_filter": 2,
        "theme_type_variation": Raw('&"GreenBar"'), "value": 100.0, "show_percentage": False})
    s.save(R + "gear_slot.tscn")


def material_row():
    """One line of a recipe: icon, material, and how many the warehouse has of what's needed."""
    s = Scene("MaterialRow", "HBoxContainer", {"theme_override_constants/separation": 6})
    s.node("Icon", "TextureRect", {"custom_minimum_size": (16, 16), "mouse_filter": 2, "stretch_mode": 3})
    label(s, "Name", "Material", None, {"size_flags_horizontal": 3, "text_overrun_behavior": 3})
    label(s, "Have", "0 / 0", "LabelCaption")
    s.save(R + "material_row.tscn")


def portrait_card():
    s = Scene("PortraitCard", "Button", {"custom_minimum_size": (124, 82), "size_flags_horizontal": 3, "mouse_default_cursor_shape": 2,
        "theme_type_variation": Raw('&"CardButton"'), "toggle_mode": True})
    s.node("Body", "VBoxContainer", {"layout_mode": 1, "anchors_preset": 15, "anchor_right": 1.0, "anchor_bottom": 1.0,
        "offset_left": 5.0, "offset_top": 4.0, "offset_right": -5.0, "offset_bottom": -4.0, "grow_horizontal": 2, "grow_vertical": 2,
        "mouse_filter": 2, "theme_override_constants/separation": -1, "alignment": 1})
    s.node("Body/Bust", "TextureRect", {"custom_minimum_size": (49, 34), "size_flags_horizontal": 4, "mouse_filter": 2, "stretch_mode": 3})
    label(s, "Body/Name", "Name", None, {"horizontal_alignment": 1, "text_overrun_behavior": 3})
    label(s, "Body/Role", "Miner", "LabelCaption", {"horizontal_alignment": 1, "text_overrun_behavior": 3})
    s.node("Body/Health", "ProgressBar", {"custom_minimum_size": (0, 5), "mouse_filter": 2, "theme_type_variation": Raw('&"GreenBar"'), "value": 100.0, "show_percentage": False})
    s.save(R + "portrait_card.tscn")


def personnel_tabs():
    grp = None
    s = Scene("PersonnelTabs", "Control", {"layout_mode": 3, "anchors_preset": 0, "offset_right": 285.0, "offset_bottom": 34.0, "mouse_filter": 2})
    grp = s.sub("tabs", "ButtonGroup", {})
    s.node("Tabs", "HBoxContainer", {"layout_mode": 0, "offset_left": 14.0, "offset_top": 12.0, "offset_right": 271.0, "offset_bottom": 30.0, "theme_override_constants/separation": 4})
    for name, text in [("EmployeesTab", "Roster"), ("HeroesTab", "Heroes"), ("RecruitmentTab", "Recruit")]:
        button(s, "Tabs/" + name, text, "ToggleButton", {"size_flags_horizontal": 3, "toggle_mode": True, "button_group": grp})
    s.save(P + "personnel_tabs.tscn")


# --- Personnel: roster ----------------------------------------------------------
def personnel_roster():
    s = page("PersonnelRosterLeft", top=36)
    grp = s.sub("filter", "ButtonGroup", {})
    s.node(C + "/Filter", "HBoxContainer", {"theme_override_constants/separation": 3})
    for name, text in [("All", "All"), ("Ready", "Ready"), ("Out", "Out"), ("Hurt", "Hurt")]:
        button(s, C + "/Filter/" + name, text, "ToggleButton", {"size_flags_horizontal": 3, "toggle_mode": True, "button_group": grp,
                                                               "custom_minimum_size": (0, 16)})
    s.node(C + "/Summary", "HBoxContainer")
    label(s, C + "/Summary/Count", "0 hired", "LabelCaption", {"size_flags_horizontal": 3})
    label(s, C + "/Summary/Payroll", "Payroll 0 G", "LabelCaption", {"mouse_filter": 1})
    scroll(s, C + "/List", 80)
    s.inst(C + "/Empty", INFO, {"visible": False, "text": "Nobody is on the payroll yet. A woodcutter at Cinderwood pays from the first trip.", "icon_kind": "plus"})
    button(s, C + "/Recruit", "Recruit Hellfarers", None, {"visible": False, "size_flags_horizontal": 4})
    s.save(P + "personnel_employed_left.tscn")

    s = page("PersonnelDossierRight")
    grp = s.sub("view", "ButtonGroup", {})
    s.node(C + "/Head", "HBoxContainer", {"theme_override_constants/separation": 8})
    s.node(C + "/Head/Portrait", "PanelContainer", {"custom_minimum_size": (58, 46), "theme_type_variation": Raw('&"SlotPanel"')})
    s.node(C + "/Head/Portrait/Bust", "TextureRect", {"mouse_filter": 2, "stretch_mode": 3})
    s.node(C + "/Head/Id", "VBoxContainer", {"size_flags_horizontal": 3, "size_flags_vertical": 4, "theme_override_constants/separation": -2})
    label(s, C + "/Head/Id/Name", "Name", "LabelTitle", {"text_overrun_behavior": 3})
    label(s, C + "/Head/Id/Title", "Title", "LabelCaption", {"text_overrun_behavior": 3})
    s.node(C + "/Head/Id/Status", "HBoxContainer", {"theme_override_constants/separation": 4})
    s.node(C + "/Head/Id/Status/RoleIcon", "TextureRect", {"custom_minimum_size": (16, 16), "mouse_filter": 2, "stretch_mode": 3})
    label(s, C + "/Head/Id/Status/Role", "Miner")
    label(s, C + "/Head/Id/Status/State", "Ready", "LabelGood")
    s.node(C + "/View", "HBoxContainer", {"theme_override_constants/separation": 4})
    for name, text in [("Overview", "Overview"), ("Gear", "Gear")]:
        button(s, C + "/View/" + name, text, "ToggleButton", {"size_flags_horizontal": 3, "toggle_mode": True, "button_group": grp,
                                                             "custom_minimum_size": (0, 18)})
    # Overview: what they cost and what they can do.
    O = C + "/Overview"
    s.node(O, "VBoxContainer", {"size_flags_vertical": 3, "theme_override_constants/separation": 6})
    s.node(O + "/Stats", "HBoxContainer", {"theme_override_constants/separation": 4})
    tile(s, O + "/Stats/Skill", "Value", extra={"tooltip_text": "Rough market value of their contract: skills, traits and the gear they wear."})
    tile(s, O + "/Stats/Wage", "Wage", extra={"tooltip_text": "Paid up front for each expedition."})
    tile(s, O + "/Stats/Share", "Share", extra={"tooltip_text": "Their cut of the coin an expedition brings back."})
    tile(s, O + "/Stats/Kit", "Gear score", extra={"tooltip_text": "Gear score: how well equipped they are for a fight, and what crypts check at the door. Each worn piece adds its tier times the slot's weight (main hand 4, body 3, off hand 2, head, hands and feet 1; two-handers 6). Worn-out pieces count half."})
    s.node(O + "/Health", "HBoxContainer", {"theme_override_constants/separation": 6})
    label(s, O + "/Health/Caption", "Health", "LabelCaption")
    s.node(O + "/Health/Bar", "ProgressBar", {"custom_minimum_size": (0, 6), "size_flags_horizontal": 3, "size_flags_vertical": 4, "mouse_filter": 2, "theme_type_variation": Raw('&"GreenBar"'), "value": 100.0, "show_percentage": False})
    label(s, O + "/Health/Value", "100%")
    button(s, O + "/Health/Heal", "Treat", "PaperButton", {"tooltip_text": "Pay a healer to restore full health."})
    label(s, O + "/SkillsCaption", "Skills", "LabelCaption")
    s.node(O + "/Skills", "GridContainer", {"columns": 2, "theme_override_constants/h_separation": 14, "theme_override_constants/v_separation": 1, "mouse_filter": 1,
        "tooltip_text": "Trade levels rise with experience. Higher levels haul more and unlock better sites."})
    for trade in TRADE_LABELS:
        base = O + "/Skills/" + trade
        s.node(base, "VBoxContainer", {"size_flags_horizontal": 3, "theme_override_constants/separation": -1, "mouse_filter": 2})
        s.node(base + "/Top", "HBoxContainer", {"mouse_filter": 2})
        label(s, base + "/Top/Name", trade, None, {"size_flags_horizontal": 3})
        label(s, base + "/Top/Level", "1")
        s.node(base + "/Bar", "ProgressBar", {"custom_minimum_size": (0, 4), "mouse_filter": 2, "theme_type_variation": Raw('&"GoldBar"'), "show_percentage": False})
    s.node(O + "/Traits", "HBoxContainer", {"theme_override_constants/separation": 6})
    label(s, O + "/Traits/Caption", "Traits", "LabelCaption")
    label(s, O + "/Traits/List", "None", None, {"size_flags_horizontal": 3, "text_overrun_behavior": 3, "mouse_filter": 1})
    spacer(s, O + "/Spacer")
    s.node(O + "/Contract", "HBoxContainer", {"theme_override_constants/separation": 4})
    s.node(O + "/Contract/Text", "VBoxContainer", {"size_flags_horizontal": 3, "theme_override_constants/separation": -3})
    label(s, O + "/Contract/Text/Caption", "Contract", "LabelCaption")
    label(s, O + "/Contract/Text/Name", "Balanced", None, {"mouse_filter": 1})
    button(s, O + "/Contract/Change", "Change terms", "PaperButton", {"size_flags_vertical": 4, "tooltip_text": "Cycle between Balanced, Guaranteed Wage and Profit Share."})
    button(s, O + "/Contract/Sell", "Sell contract", "PaperButton", {"size_flags_vertical": 4, "tooltip_text": "Another guild buys their contract, with the gear they wear."})
    # Gear: the ten slots, the chosen slot, and what in the storeroom fits it.
    G = C + "/Gear"
    s.node(G, "VBoxContainer", {"visible": False, "size_flags_vertical": 3, "theme_override_constants/separation": 5})
    s.node(G + "/Slots", "GridContainer", {"size_flags_horizontal": 4, "theme_override_constants/h_separation": 6, "theme_override_constants/v_separation": 4, "columns": 5})
    s.node(G + "/Picked", "PanelContainer", {"theme_type_variation": Raw('&"InsetPanel"')})
    s.node(G + "/Picked/Row", "HBoxContainer", {"theme_override_constants/separation": 4})
    s.node(G + "/Picked/Row/Info", "VBoxContainer", {"size_flags_horizontal": 3, "theme_override_constants/separation": -4})
    label(s, G + "/Picked/Row/Info/Name", "Main hand: empty", None, {"text_overrun_behavior": 3})
    label(s, G + "/Picked/Row/Info/Detail", "", "LabelCaption", {"text_overrun_behavior": 3})
    button(s, G + "/Picked/Row/Repair", "Repair", "PaperButton", {"size_flags_vertical": 4})
    button(s, G + "/Picked/Row/Remove", "Unequip", "PaperButton", {"size_flags_vertical": 4})
    s.node(G + "/Foot", "HBoxContainer", {"theme_override_constants/separation": 4})
    label(s, G + "/Foot/Bonus", "", "LabelCaption", {"size_flags_horizontal": 3, "autowrap_mode": 3, "mouse_filter": 1})
    button(s, G + "/Foot/RepairAll", "Repair all", "PaperButton", {"size_flags_vertical": 4})
    label(s, G + "/FitsCaption", "Fits this slot", "LabelCaption")
    scroll(s, G + "/Fits", 60)
    label(s, G + "/FitsEmpty", "Nothing in the Warehouse fits this slot.", "LabelMuted", {"autowrap_mode": 3})
    button(s, G + "/Workshop", "Buy or craft more in the Workshop  >", "TextButton", {"size_flags_horizontal": 8})
    s.inst(C + "/Empty", INFO, {"visible": False, "text": "Select a Hellfarer to read their dossier.", "icon_kind": "home"})
    s.save(P + "personnel_employed_right.tscn")


# --- Personnel: recruitment -----------------------------------------------------
def personnel_recruit():
    s = page("PersonnelRecruitLeft", top=36)
    grp = s.sub("filter", "ButtonGroup", {})
    s.node(C + "/Filter", "HBoxContainer", {"theme_override_constants/separation": 2})
    for name, text, tip in [("All", "All", "Everyone looking for work."), ("Logging", "Logging", "Woodcutters."), ("Mining", "Mining", "Miners."),
                            ("Guards", "Guards", "Guards: they cut the risk for any crew."), ("Other", "Other", "Foragers, anglers, hunters and farmhands.")]:
        button(s, C + "/Filter/" + name, text, "ToggleButton", {"size_flags_horizontal": 3, "toggle_mode": True, "button_group": grp,
                                                               "custom_minimum_size": (0, 16), "tooltip_text": tip})
    s.node(C + "/Summary", "HBoxContainer")
    label(s, C + "/Summary/Refresh", "New applicants in 30m", "LabelCaption", {"size_flags_horizontal": 3})
    label(s, C + "/Summary/Standing", "Unknown", "LabelCaption", {"mouse_filter": 1,
        "tooltip_text": "Better Hellfarers apply to more reputable guilds. Reputation comes from the value your crews bring up."})
    scroll(s, C + "/List", 80)
    s.inst(C + "/Empty", INFO, {"visible": False, "text": "Nobody of this kind is looking for work. New faces arrive every half hour.", "icon_kind": "home"})
    s.save(P + "personnel_recruits_left.tscn")

    s = page("PersonnelRecruitRight")
    s.node(C + "/Head", "HBoxContainer", {"theme_override_constants/separation": 8})
    s.node(C + "/Head/Portrait", "PanelContainer", {"custom_minimum_size": (58, 46), "theme_type_variation": Raw('&"SlotPanel"')})
    s.node(C + "/Head/Portrait/Bust", "TextureRect", {"mouse_filter": 2, "stretch_mode": 3})
    s.node(C + "/Head/Id", "VBoxContainer", {"size_flags_horizontal": 3, "size_flags_vertical": 4, "theme_override_constants/separation": -2})
    label(s, C + "/Head/Id/Name", "Name", "LabelTitle", {"text_overrun_behavior": 3})
    label(s, C + "/Head/Id/Title", "Title", "LabelCaption", {"text_overrun_behavior": 3})
    s.node(C + "/Head/Id/Status", "HBoxContainer", {"theme_override_constants/separation": 4})
    s.node(C + "/Head/Id/Status/RoleIcon", "TextureRect", {"custom_minimum_size": (16, 16), "mouse_filter": 2, "stretch_mode": 3})
    label(s, C + "/Head/Id/Status/Role", "Miner", None, {"size_flags_horizontal": 3, "text_overrun_behavior": 3})
    s.node(C + "/Stats", "HBoxContainer", {"theme_override_constants/separation": 4})
    tile(s, C + "/Stats/Fee", "Signing fee", extra={"tooltip_text": "Paid once, when they sign."})
    tile(s, C + "/Stats/Wage", "Wage", extra={"tooltip_text": "Paid up front for each expedition."})
    tile(s, C + "/Stats/Share", "Share", extra={"tooltip_text": "Their cut of the coin an expedition brings back."})
    tile(s, C + "/Stats/Skill", "Value", extra={"tooltip_text": "Rough market value: skills, traits and the tool they bring."})
    label(s, C + "/SkillsCaption", "Skills", "LabelCaption")
    s.node(C + "/Skills", "GridContainer", {"columns": 2, "theme_override_constants/h_separation": 14, "theme_override_constants/v_separation": 1, "mouse_filter": 1,
        "tooltip_text": "Trade levels. Higher levels haul more and open better sites."})
    for trade in TRADE_LABELS:
        base = C + "/Skills/" + trade
        s.node(base, "VBoxContainer", {"size_flags_horizontal": 3, "theme_override_constants/separation": -1, "mouse_filter": 2})
        s.node(base + "/Top", "HBoxContainer", {"mouse_filter": 2})
        label(s, base + "/Top/Name", trade, None, {"size_flags_horizontal": 3})
        label(s, base + "/Top/Level", "1")
        s.node(base + "/Bar", "ProgressBar", {"custom_minimum_size": (0, 4), "mouse_filter": 2, "theme_type_variation": Raw('&"GoldBar"'), "show_percentage": False})
    label(s, C + "/TraitsCaption", "Traits", "LabelCaption")
    label(s, C + "/Traits", "None", None, {"autowrap_mode": 3})
    spacer(s, C + "/Spacer")
    button(s, C + "/Hire", "Hire", None, {"custom_minimum_size": (0, 26), "tooltip_text": "Traits are for life. Nobody who stays below can be rehired."})
    label(s, C + "/Reason", "", "LabelAccent", {"horizontal_alignment": 1, "autowrap_mode": 3})
    s.inst(C + "/Empty", INFO, {"visible": False, "text": "Select an applicant to see their terms.", "icon_kind": "home"})
    s.save(P + "personnel_recruits_right.tscn")


# --- Workshop: storeroom and quartermaster ------------------------------------------
WAREHOUSE_GROUPS = [("All", "All", "Everything the guild owns."), ("Materials", "Goods", "Raw goods, treasures and made materials."),
                    ("Weapons", "Arms", "Weapons, spare or carried."), ("Armour", "Armour", "Armour, shields, packs and trinkets."),
                    ("Tools", "Tools", "Axes, picks, sickles, rods and hoes."), ("Supplies", "Food", "Food and potions.")]


def workshop_store():
    """The Workshop's Warehouse: everything the guild owns (goods, spare and worn gear, food) in one
    searchable list, and the chosen thing's details with what you can do with it."""
    s = page("WorkshopStoreLeft", top=36)
    header(s, C + "/Header", "Warehouse")
    s.node(C + "/Find", "LineEdit", {"custom_minimum_size": (0, 20), "placeholder_text": "Find: ashwood, sword, draught...",
        "clear_button_enabled": True, "context_menu_enabled": False,
        "tooltip_text": "Type part of a name to find it among everything the guild owns."})
    grp = s.sub("filter", "ButtonGroup", {})
    s.node(C + "/Filter", "HBoxContainer", {"theme_override_constants/separation": 2})
    for name, text, tip in WAREHOUSE_GROUPS:
        button(s, C + "/Filter/" + name, text, "ToggleButton", {"size_flags_horizontal": 3, "toggle_mode": True, "button_group": grp,
                                                               "custom_minimum_size": (0, 16), "tooltip_text": tip})
    label(s, C + "/Summary", "", "LabelCaption", {"autowrap_mode": 3})
    scroll(s, C + "/List", 110)
    s.inst(C + "/Empty", INFO, {"visible": False, "text": "Nothing here yet. Goods your crews bring up, gear you buy or craft, and food you cook all show up here.", "icon_kind": "home"})
    s.save(P + "workshop_store_left.tscn")

    s = page("WorkshopStoreRight")
    header(s, C + "/Header", "Details")
    s.node(C + "/Head", "HBoxContainer", {"theme_override_constants/separation": 8})
    s.inst(C + "/Head/Slot", SLOT, {"custom_minimum_size": (34, 34)})
    s.node(C + "/Head/Id", "VBoxContainer", {"size_flags_horizontal": 3, "size_flags_vertical": 4, "theme_override_constants/separation": -2})
    label(s, C + "/Head/Id/Name", "Name", "LabelTitle", {"text_overrun_behavior": 3})
    label(s, C + "/Head/Id/Kind", "", "LabelCaption", {"text_overrun_behavior": 3})
    s.node(C + "/Stats", "HBoxContainer", {"theme_override_constants/separation": 5})
    tile(s, C + "/Stats/Held", "Held", "0")
    tile(s, C + "/Stats/Worth", "Worth today", "0 G", extra={"tooltip_text": "What the merchants would pay for all of it today."})
    tile(s, C + "/Stats/Third", "Condition", "-")
    label(s, C + "/Desc", "", None, {"autowrap_mode": 3})
    label(s, C + "/Where", "", "LabelMuted", {"autowrap_mode": 3})
    spacer(s, C + "/Spacer")
    s.node(C + "/Actions", "VBoxContainer", {"theme_override_constants/separation": 4})
    button(s, C + "/Actions/Primary", "Action", None, {"custom_minimum_size": (0, 24)})
    button(s, C + "/Actions/Secondary", "Action", "PaperButton", {"custom_minimum_size": (0, 22)})
    button(s, C + "/Actions/Tertiary", "Action", "PaperButton", {"custom_minimum_size": (0, 22)})
    label(s, C + "/Reason", "", "LabelAccent", {"horizontal_alignment": 1, "autowrap_mode": 3})
    s.inst(C + "/Empty", INFO, {"visible": False, "text": "Choose something on the left to see what it is and what you can do with it.", "icon_kind": "home"})
    s.save(P + "workshop_store_right.tscn")


def list_caption():
    """A small group heading inside a list (the Warehouse's Materials, Weapons, ...)."""
    s = Scene("ListCaption", "HBoxContainer", {"layout_mode": 2, "theme_override_constants/separation": 4, "mouse_filter": 2})
    label(s, "Text", "Materials", "LabelCaption")
    label(s, "Count", "", "LabelMuted", {"size_flags_horizontal": 3})
    s.save(R + "list_caption.tscn")


def workshop_shop():
    s = page("WorkshopShopLeft", top=36)
    header(s, C + "/Header", "Ready-made Gear")
    label(s, C + "/Caption", "The quartermaster's starter gear. It goes to the Warehouse.", "LabelCaption", {"autowrap_mode": 3})
    scroll(s, C + "/Gear", 80)
    s.save(P + "workshop_shop_left.tscn")

    s = page("WorkshopShopRight")
    header(s, C + "/Header", "Blueprints")
    grp = s.sub("filter", "ButtonGroup", {})
    s.node(C + "/Filter", "HBoxContainer", {"theme_override_constants/separation": 2})
    for name, text, tip in CRAFT_GROUPS:
        button(s, C + "/Filter/" + name, text, "ToggleButton", {"size_flags_horizontal": 3, "toggle_mode": True, "button_group": grp,
                                                               "custom_minimum_size": (0, 16), "tooltip_text": tip})
    label(s, C + "/Caption", "Learn a recipe once; anyone in the guild can craft it.", "LabelCaption", {"autowrap_mode": 3})
    s.node(C + "/Focus", "HBoxContainer", {"visible": False, "theme_override_constants/separation": 4})
    label(s, C + "/Focus/Text", "", "LabelAccent", {"size_flags_horizontal": 3, "text_overrun_behavior": 3})
    button(s, C + "/Focus/Clear", "Show all", "PaperButton")
    scroll(s, C + "/Blueprints", 80)
    s.inst(C + "/Empty", INFO, {"visible": False, "text": "You know every blueprint the quartermaster sells.", "icon_kind": "check"})
    s.save(P + "workshop_shop_right.tscn")


def chapter_tabs():
    """Tab strips over the left page of the Workshop and Ledger chapters."""
    for scene, names in [("WorkshopTabs", [("CraftTab", "Craft"), ("ShopTab", "Shop"), ("StoreTab", "Warehouse")]),
                         ("LedgerTabs", [("AccountsTab", "Accounts"), ("ReportsTab", "Reports")])]:
        s = Scene(scene, "Control", {"layout_mode": 3, "anchors_preset": 0, "offset_right": 285.0, "offset_bottom": 34.0, "mouse_filter": 2})
        grp = s.sub("tabs", "ButtonGroup", {})
        s.node("Tabs", "HBoxContainer", {"layout_mode": 0, "offset_left": 14.0, "offset_top": 12.0, "offset_right": 271.0, "offset_bottom": 30.0, "theme_override_constants/separation": 4})
        for name, text in names:
            button(s, "Tabs/" + name, text, "ToggleButton", {"size_flags_horizontal": 3, "toggle_mode": True, "button_group": grp})
        s.save(P + scene.lower().replace("tabs", "_tabs") + ".tscn")


# --- Personnel: workshop ----------------------------------------------------------
def personnel_workshop():
    s = page("PersonnelWorkshopLeft", top=36)
    grp = s.sub("filter", "ButtonGroup", {})
    s.node(C + "/Filter", "HBoxContainer", {"theme_override_constants/separation": 2})
    for name, text, tip in CRAFT_GROUPS:
        button(s, C + "/Filter/" + name, text, "ToggleButton", {"size_flags_horizontal": 3, "toggle_mode": True, "button_group": grp,
                                                               "custom_minimum_size": (0, 16), "tooltip_text": tip})
    label(s, C + "/Summary", "", "LabelCaption", {"autowrap_mode": 3})
    s.node(C + "/Focus", "HBoxContainer", {"visible": False, "theme_override_constants/separation": 4})
    label(s, C + "/Focus/Text", "", "LabelAccent", {"size_flags_horizontal": 3, "text_overrun_behavior": 3})
    button(s, C + "/Focus/Clear", "Show all", "PaperButton")
    scroll(s, C + "/Known", 110)
    s.inst(C + "/KnownEmpty", INFO, {"visible": False, "text": "No blueprints here yet. Buy them in the Shop; better ones turn up in the crypts.", "icon_kind": "plus"})
    button(s, C + "/ShopLink", "Blueprints for sale in the Shop  >", "TextButton", {"size_flags_horizontal": 8})
    s.save(P + "personnel_workshop_left.tscn")

    s = page("PersonnelWorkshopRight")
    header(s, C + "/Header", "Recipe")
    s.node(C + "/Head", "HBoxContainer", {"theme_override_constants/separation": 8})
    s.inst(C + "/Head/Slot", SLOT, {"custom_minimum_size": (34, 34)})
    s.node(C + "/Head/Id", "VBoxContainer", {"size_flags_horizontal": 3, "size_flags_vertical": 4, "theme_override_constants/separation": -2})
    label(s, C + "/Head/Id/Name", "Name", "LabelTitle", {"text_overrun_behavior": 3})
    label(s, C + "/Head/Id/Summary", "", "LabelCaption", {"text_overrun_behavior": 3})
    s.node(C + "/Stats", "GridContainer", {"theme_override_constants/h_separation": 5, "theme_override_constants/v_separation": 5, "columns": 2})
    tile(s, C + "/Stats/Value", "Worth", extra={"tooltip_text": "Catalog value of a common one. Finer rolls are worth more."})
    tile(s, C + "/Stats/Cost", "Materials", extra={"tooltip_text": "What the materials would fetch at today's prices."})
    header(s, C + "/MatHeader", "Materials")
    s.node(C + "/Materials", "VBoxContainer", {"theme_override_constants/separation": 2})
    label(s, C + "/Rolls", "", "LabelMuted", {"autowrap_mode": 3})
    spacer(s, C + "/Spacer")
    button(s, C + "/Craft", "Craft", None, {"custom_minimum_size": (0, 26)})
    label(s, C + "/Reason", "", "LabelAccent", {"horizontal_alignment": 1, "autowrap_mode": 3})
    s.inst(C + "/Empty", INFO, {"visible": False, "text": "Choose a blueprint to see its recipe.", "icon_kind": "home"})
    s.save(P + "personnel_workshop_right.tscn")


# --- Exchange ------------------------------------------------------------------
def exchange():
    s = page("ExchangeLeft", top=36)
    header(s, C + "/Header", "Goods")
    s.node(C + "/Summary", "HBoxContainer")
    label(s, C + "/Summary/Shift", "Prices shift in 6h", "LabelCaption", {"size_flags_horizontal": 3, "tooltip_text": "Merchants reprice every six hours. Arrows compare today's price with the usual one.", "mouse_filter": 1})
    label(s, C + "/Summary/Hint", "", "LabelCaption")
    grp = s.sub("filter", "ButtonGroup", {})
    s.node(C + "/Filter", "HBoxContainer", {"theme_override_constants/separation": 3})
    for name, text, tip in [("All", "All", "Every good the merchants trade."), ("Held", "Held", "Goods in your warehouse."),
                            ("Raw", "Raw", "What expeditions bring home."), ("Crafted", "Crafted", "Ingots, cloth, potions and other made goods."),
                            ("Food", "Food", "Meals a Hellfarer can carry on an expedition.")]:
        button(s, C + "/Filter/" + name, text, "ToggleButton", {"size_flags_horizontal": 3, "toggle_mode": True, "button_group": grp,
                                                               "custom_minimum_size": (0, 16), "tooltip_text": tip})
    s.node(C + "/Columns", "HBoxContainer", {"theme_override_constants/separation": 4})
    label(s, C + "/Columns/Good", "Good", "LabelCaption", {"size_flags_horizontal": 3})
    label(s, C + "/Columns/Held", "Held", "LabelCaption", {"custom_minimum_size": (34, 0), "horizontal_alignment": 2})
    label(s, C + "/Columns/Pays", "Pays", "LabelCaption", {"custom_minimum_size": (52, 0), "horizontal_alignment": 2})
    scroll(s, C + "/List", 80)
    s.save(P + "exchange_left.tscn")


def market_row():
    """One good in the Market's table: icon, name, how many are held, what merchants pay."""
    s = Scene("MarketRow", "Button", {"custom_minimum_size": (0, 22), "size_flags_horizontal": 3, "mouse_default_cursor_shape": 2,
        "theme_type_variation": Raw('&"CardButton"'), "toggle_mode": True})
    s.node("Body", "HBoxContainer", {"layout_mode": 1, "anchors_preset": 15, "anchor_right": 1.0, "anchor_bottom": 1.0,
        "offset_left": 4.0, "offset_right": -6.0, "grow_horizontal": 2, "grow_vertical": 2, "mouse_filter": 2, "theme_override_constants/separation": 4})
    s.node("Body/Icon", "TextureRect", {"custom_minimum_size": (16, 16), "size_flags_vertical": 4, "mouse_filter": 2, "stretch_mode": 3})
    label(s, "Body/Name", "Good", None, {"size_flags_horizontal": 3, "size_flags_vertical": 4, "text_overrun_behavior": 3})
    label(s, "Body/Held", "", None, {"custom_minimum_size": (30, 0), "size_flags_vertical": 4, "horizontal_alignment": 2})
    # The price, with today's trend arrow right beside it.
    s.node("Body/Price", "HBoxContainer", {"custom_minimum_size": (50, 0), "mouse_filter": 2, "alignment": 2, "theme_override_constants/separation": 2})
    s.node("Body/Price/Trend", "TextureRect", {"custom_minimum_size": (7, 0), "size_flags_vertical": 4, "mouse_filter": 2, "stretch_mode": 3})
    label(s, "Body/Price/Pays", "0 G", None, {"size_flags_vertical": 4, "horizontal_alignment": 2})
    s.save(R + "market_row.tscn")

    s = page("ExchangeRight")
    header(s, C + "/Header", "Trade")
    s.node(C + "/Head", "HBoxContainer", {"theme_override_constants/separation": 8})
    s.node(C + "/Head/Slot", "PanelContainer", {"custom_minimum_size": (44, 44), "theme_type_variation": Raw('&"SlotPanel"')})
    s.node(C + "/Head/Slot/Center", "CenterContainer", {"mouse_filter": 2})
    s.node(C + "/Head/Slot/Center/Icon", "TextureRect", {"custom_minimum_size": (32, 32), "mouse_filter": 2, "expand_mode": 1})
    s.node(C + "/Head/Id", "VBoxContainer", {"size_flags_horizontal": 3, "size_flags_vertical": 4, "theme_override_constants/separation": -2})
    label(s, C + "/Head/Id/Name", "Item", "LabelTitle")
    label(s, C + "/Head/Id/Desc", "", "LabelCaption", {"autowrap_mode": 3})
    s.node(C + "/Prices", "HBoxContainer", {"theme_override_constants/separation": 4})
    tile(s, C + "/Prices/Sell", "You sell for", extra={"tooltip_text": "What a merchant pays you for one."})
    tile(s, C + "/Prices/Buy", "You buy for", extra={"tooltip_text": "What a merchant charges you for one."})
    tile(s, C + "/Prices/Owned", "Owned")
    s.node(C + "/Market", "HBoxContainer", {"theme_override_constants/separation": 4})
    s.node(C + "/Market/Trend", "TextureRect", {"size_flags_vertical": 4, "mouse_filter": 2, "stretch_mode": 3})
    label(s, C + "/Market/Text", "", "LabelMuted", {"size_flags_horizontal": 3, "autowrap_mode": 3})
    s.node(C + "/History", "PanelContainer", {"theme_type_variation": Raw('&"InsetPanel"'), "tooltip_text": "What merchants have paid for one, sampled every hour and after each trade."})
    s.node(C + "/History/Body", "VBoxContainer", {"theme_override_constants/separation": 1})
    s.node(C + "/History/Body/Top", "HBoxContainer")
    label(s, C + "/History/Body/Top/Caption", "Merchant price, last 48 samples", "LabelCaption", {"size_flags_horizontal": 3})
    label(s, C + "/History/Body/Top/Range", "", "LabelCaption")
    s.node(C + "/History/Body/Bars", "HBoxContainer", {"custom_minimum_size": (0, 30), "theme_override_constants/separation": 1, "alignment": 2})
    s.node(C + "/Desk", "PanelContainer")
    s.node(C + "/Desk/Body", "VBoxContainer", {"theme_override_constants/separation": 4})
    for kind, buttons in [("Sell", [("One", "Sell 1"), ("Ten", "Sell 10"), ("All", "Sell all")]), ("Buy", [("One", "Buy 1"), ("Ten", "Buy 10")])]:
        row = C + "/Desk/Body/%sRow" % kind
        s.node(row, "HBoxContainer", {"theme_override_constants/separation": 4})
        label(s, row + "/Caption", kind, "LabelCaption", {"custom_minimum_size": (30, 0)})
        for n, t in buttons:
            button(s, row + "/" + n, t, "PaperButton" if kind == "Buy" else None, {"size_flags_horizontal": 3})
    label(s, C + "/Desk/Body/Holding", "", "LabelCaption", {"horizontal_alignment": 1})
    spacer(s, C + "/Spacer")
    s.inst(C + "/Note", INFO, {"text": "Selling many at once floods the merchants and lowers their price; it recovers within a day.", "icon_kind": "coin"})
    s.save(P + "exchange_right.tscn")


# --- Finances ------------------------------------------------------------------
def finances():
    s = page("FinanceLeft", top=36)
    header(s, C + "/Header", "Treasury")
    s.node(C + "/Hero", "HBoxContainer", {"theme_override_constants/separation": 8})
    s.node(C + "/Hero/Slot", "PanelContainer", {"custom_minimum_size": (44, 44), "theme_type_variation": Raw('&"SlotPanel"')})
    s.node(C + "/Hero/Slot/Center", "CenterContainer", {"mouse_filter": 2})
    s.node(C + "/Hero/Slot/Center/Icon", "TextureRect", {"custom_minimum_size": (32, 32), "mouse_filter": 2, "texture": Res(ICON + "gold.png"), "expand_mode": 1})
    s.node(C + "/Hero/Text", "VBoxContainer", {"size_flags_horizontal": 3, "size_flags_vertical": 4, "theme_override_constants/separation": -2})
    label(s, C + "/Hero/Text/Caption", "Gold on hand", "LabelCaption")
    label(s, C + "/Hero/Text/Gold", "0 G", "LabelBig")
    s.node(C + "/Ledger", "PanelContainer", {"theme_type_variation": Raw('&"InsetPanel"')})
    s.node(C + "/Ledger/Rows", "VBoxContainer", {"theme_override_constants/separation": 0})
    for key, text, color in [("Coin", "Coin", "0.839216, 0.627451, 0.243137"), ("Goods", "Goods in the warehouse", "0.337255, 0.478431, 0.258824"),
                             ("Gear", "Equipment", "0.478431, 0.345098, 0.290196"), ("Debt", "Debt owed", "0.501961, 0.172549, 0.219608")]:
        row = C + "/Ledger/Rows/" + key
        s.node(row, "HBoxContainer", {"theme_override_constants/separation": 5})
        s.node(row + "/Swatch", "ColorRect", {"custom_minimum_size": (5, 5), "size_flags_vertical": 4, "mouse_filter": 2, "color": Raw("Color(%s, 1)" % color)})
        label(s, row + "/Name", text, None, {"size_flags_horizontal": 3})
        label(s, row + "/Value", "0 G", None, {"horizontal_alignment": 2})
    s.node(C + "/Ledger/Rows/Rule", "HSeparator")
    s.node(C + "/Ledger/Rows/Total", "HBoxContainer")
    label(s, C + "/Ledger/Rows/Total/Name", "Guild worth", "LabelTitle", {"size_flags_horizontal": 3})
    label(s, C + "/Ledger/Rows/Total/Value", "0 G", "LabelBig")
    header(s, C + "/OpsHeader", "Operations")
    s.node(C + "/Slots", "HBoxContainer", {"theme_override_constants/separation": 6})
    s.node(C + "/Slots/Text", "VBoxContainer", {"size_flags_horizontal": 3, "size_flags_vertical": 4, "theme_override_constants/separation": 0})
    label(s, C + "/Slots/Text/Caption", "Expedition slots", "LabelCaption")
    s.inst(C + "/Slots/Text/Pips", PIPS, {"value": 1, "max_value": 5, "gold": True})
    button(s, C + "/Slots/Expand", "Sign charter", "PaperButton", {"size_flags_vertical": 4, "tooltip_text": "A Warden's charter lets one more crew go below at the same time."})
    label(s, C + "/SlotsNote", "", "LabelCaption", {"autowrap_mode": 3})
    s.node(C + "/Costs", "HBoxContainer", {"theme_override_constants/separation": 5})
    tile(s, C + "/Costs/Payroll", "Payroll", extra={"tooltip_text": "Wages for one expedition with every Hellfarer on the roster."})
    tile(s, C + "/Costs/Reputation", "Reputation", icon=ICON + "crystal.png", extra={"tooltip_text": "Earned through successful expeditions. Unlocks contracts."})
    spacer(s, C + "/Spacer")
    s.inst(C + "/Relief", INFO, {"visible": False, "text": "", "icon_kind": "coin"})
    button(s, C + "/ReliefButton", "Request guild advance", "PaperButton", {"visible": False, "size_flags_horizontal": 4})
    s.save(P + "finance_left.tscn")

    s = page("FinanceRight")
    header(s, C + "/Header", "Recent Results")
    s.node(C + "/Chart", "PanelContainer", {"theme_type_variation": Raw('&"InsetPanel"'), "tooltip_text": "Profit or loss of each recent expedition, oldest on the left."})
    s.node(C + "/Chart/Body", "VBoxContainer", {"theme_override_constants/separation": 2})
    s.node(C + "/Chart/Body/Plot", "Control", {"custom_minimum_size": (0, 72), "mouse_filter": 2})
    s.node(C + "/Chart/Body/Plot/Midline", "ColorRect", {"layout_mode": 1, "anchors_preset": 14, "anchor_top": 0.5, "anchor_right": 1.0, "anchor_bottom": 0.5, "offset_bottom": 1.0, "grow_horizontal": 2, "grow_vertical": 2, "mouse_filter": 2, "color": Raw("Color(0.690196, 0.552941, 0.458824, 1)")})
    s.node(C + "/Chart/Body/Plot/Bars", "HBoxContainer", {"layout_mode": 1, "anchors_preset": 15, "anchor_right": 1.0, "anchor_bottom": 1.0, "grow_horizontal": 2, "grow_vertical": 2, "mouse_filter": 2, "theme_override_constants/separation": 3, "alignment": 1})
    label(s, C + "/Chart/Body/Caption", "No expeditions yet", "LabelMuted", {"horizontal_alignment": 1})
    s.node(C + "/Totals", "HBoxContainer", {"theme_override_constants/separation": 4})
    tile(s, C + "/Totals/Earned", "Haul value", extra={"tooltip_text": "Coin plus goods at the merchant price when each crew returned."})
    tile(s, C + "/Totals/Spent", "Spent")
    tile(s, C + "/Totals/Net", "Net")
    header(s, C + "/TradeHeader", "By Trade")
    scroll(s, C + "/Trades", 60)
    label(s, C + "/TradesEmpty", "No expeditions have come home yet.", "LabelMuted")
    s.save(P + "finance_right.tscn")


# --- Chronicle -------------------------------------------------------------------
def chronicle():
    s = page("ChronicleLeft", top=36)
    header(s, C + "/Header", "Reports")
    label(s, C + "/Summary", "", "LabelCaption")
    scroll(s, C + "/List", 80)
    s.inst(C + "/Empty", INFO, {"visible": False, "text": "No expedition has returned yet. Every report is kept here.", "icon_kind": "home"})
    button(s, C + "/PlanExpedition", "Plan an expedition", None, {"visible": False, "size_flags_horizontal": 4})
    s.save(P + "chronicle_left.tscn")

    s = page("ChronicleRight")
    header(s, C + "/Header", "Report")
    s.node(C + "/Head", "HBoxContainer", {"theme_override_constants/separation": 6})
    s.node(C + "/Head/Seal", "TextureRect", {"custom_minimum_size": (24, 24), "size_flags_vertical": 4, "mouse_filter": 2, "stretch_mode": 3})
    s.node(C + "/Head/Id", "VBoxContainer", {"size_flags_horizontal": 3, "size_flags_vertical": 4, "theme_override_constants/separation": -2})
    label(s, C + "/Head/Id/Place", "Place", "LabelTitle")
    label(s, C + "/Head/Id/Outcome", "Outcome", "LabelAccent")
    s.node(C + "/Money", "HBoxContainer", {"theme_override_constants/separation": 4})
    tile(s, C + "/Money/Recovered", "Haul value", extra={"tooltip_text": "Coin plus goods at the merchant price on return, after the crew's share."})
    tile(s, C + "/Money/Costs", "Costs")
    tile(s, C + "/Money/Profit", "Profit")
    label(s, C + "/LootCaption", "Goods recovered", "LabelCaption")
    s.node(C + "/Loot", "HBoxContainer", {"theme_override_constants/separation": 4})
    label(s, C + "/NoLoot", "Nothing recovered.", "LabelMuted")
    label(s, C + "/CrewCaption", "The crew", "LabelCaption")
    s.node(C + "/Crew", "VBoxContainer", {"theme_override_constants/separation": -2})
    label(s, C + "/Items", "", "LabelCaption", {"autowrap_mode": 3})
    label(s, C + "/EventsCaption", "Field notes", "LabelCaption")
    scroll(s, C + "/Events", 40)
    s.inst(C + "/Empty", INFO, {"visible": False, "text": "Select a report to read it.", "icon_kind": "home"})
    s.save(P + "chronicle_right.tscn")


# --- Regional contracts --------------------------------------------------------
def guildwork():
    s = page("GuildWorkLeft")
    header(s, C + "/Header", "Warden Work")
    s.inst(C + "/About", INFO, {"text": "Safe, small jobs from the Wardens of the Maw for guilds on hard times: watches, hauling, the gate. No risk, no equipment, modest pay.", "icon_kind": "home"})
    label(s, C + "/EligibleCaption", "Who qualifies", "LabelCaption")
    s.node(C + "/Rules", "PanelContainer", {"theme_type_variation": Raw('&"InsetPanel"')})
    s.node(C + "/Rules/Body", "VBoxContainer", {"theme_override_constants/separation": 2})
    for key in ["Cash", "Worth", "Slot"]:
        row = C + "/Rules/Body/" + key
        s.node(row, "HBoxContainer", {"theme_override_constants/separation": 4})
        s.node(row + "/Mark", "TextureRect", {"custom_minimum_size": (16, 16), "size_flags_vertical": 4, "mouse_filter": 2, "stretch_mode": 3})
        label(s, row + "/Text", key, None, {"size_flags_horizontal": 3})
    header(s, C + "/OfficeHeader", "Office Paperwork")
    s.node(C + "/Office", "PanelContainer")
    s.node(C + "/Office/Row", "HBoxContainer", {"theme_override_constants/separation": 6})
    s.node(C + "/Office/Row/IconSlot", "PanelContainer", {"custom_minimum_size": (24, 24), "size_flags_vertical": 4, "theme_type_variation": Raw('&"SlotPanel"')})
    s.node(C + "/Office/Row/IconSlot/Icon", "TextureRect", {"mouse_filter": 2, "stretch_mode": 3, "texture": Res(ICON + "book.png")})
    s.node(C + "/Office/Row/Info", "VBoxContainer", {"size_flags_horizontal": 3, "size_flags_vertical": 4, "theme_override_constants/separation": -4})
    label(s, C + "/Office/Row/Info/Name", "Ledger copying")
    label(s, C + "/Office/Row/Info/Details", "3 min  ·  9 G  ·  no worker needed", "LabelCaption")
    button(s, C + "/Office/Row/Accept", "Accept", "PaperButton", {"size_flags_vertical": 4})
    spacer(s, C + "/Spacer")
    button(s, C + "/ReturnBoard", "Back to the expedition board  >", "TextButton", {"size_flags_horizontal": 8})
    s.save(P + "guildwork_left.tscn")

    s = page("GuildWorkRight")
    header(s, C + "/Header", "Contract Labor")
    label(s, C + "/Caption", "2m 30s  ·  18 G each  ·  no injury or gear risk", "LabelCaption")
    scroll(s, C + "/List", 80)
    s.inst(C + "/Empty", INFO, {"visible": False, "text": "No Hellfarers are free for work right now.", "icon_kind": "home"})
    s.save(P + "guildwork_right.tscn")


def board():
    """The Expeditions index: the trades on the left, the chosen trade's sites on the right."""
    s = page("BoardLeft")
    header(s, C + "/Header", "Trades")
    s.node(C + "/Trades", "VBoxContainer", {"theme_override_constants/separation": 4})
    spacer(s, C + "/Spacer")
    label(s, C + "/Hint", "Crews work the sites; heroes fight the crypts. Both can be out at once.", "LabelMuted",
          {"horizontal_alignment": 1, "autowrap_mode": 3})
    s.save(P + "board_left.tscn")

    s = page("BoardRight")
    header(s, C + "/Header", "Logging")
    s.node(C + "/Open", "VBoxContainer", {"theme_override_constants/separation": 4})
    label(s, C + "/LockedCaption", "Locked", "LabelCaption")
    s.node(C + "/Locked", "VBoxContainer", {"theme_override_constants/separation": 2})
    spacer(s, C + "/Spacer")
    label(s, C + "/Hint", "Pick a site to plan a crew.", "LabelMuted", {"horizontal_alignment": 1})
    s.save(P + "board_right.tscn")


def site_card():
    """One open site on the Expeditions index."""
    s = Scene("SiteCard", "Button", {"custom_minimum_size": (0, 44), "size_flags_horizontal": 3, "mouse_default_cursor_shape": 2,
        "theme_type_variation": Raw('&"CardButton"')})
    s.node("Body", "VBoxContainer", {"layout_mode": 1, "anchors_preset": 15, "anchor_right": 1.0, "anchor_bottom": 1.0,
        "offset_left": 7.0, "offset_top": 4.0, "offset_right": -7.0, "offset_bottom": -4.0, "grow_horizontal": 2, "grow_vertical": 2,
        "mouse_filter": 2, "theme_override_constants/separation": -2})
    s.node("Body/Top", "HBoxContainer", {"mouse_filter": 2, "theme_override_constants/separation": 6})
    s.node("Body/Top/Info", "VBoxContainer", {"size_flags_horizontal": 3, "mouse_filter": 2, "theme_override_constants/separation": -4})
    label(s, "Body/Top/Info/Name", "Site", None, {"text_overrun_behavior": 3})
    label(s, "Body/Top/Info/Details", "Safe", "LabelCaption", {"text_overrun_behavior": 3})
    label(s, "Body/Top/Value", "", "LabelGood", {"size_flags_vertical": 4})
    label(s, "Body/Facts", "", "LabelCaption", {"text_overrun_behavior": 3})
    s.save(R + "site_card.tscn")


def locked_row():
    """A site the guild can't work yet: one quiet line."""
    s = Scene("LockedRow", "Button", {"custom_minimum_size": (0, 20), "size_flags_horizontal": 3, "mouse_default_cursor_shape": 2,
        "theme_type_variation": Raw('&"TextButton"')})
    s.node("Body", "HBoxContainer", {"layout_mode": 1, "anchors_preset": 15, "anchor_right": 1.0, "anchor_bottom": 1.0,
        "offset_left": 7.0, "offset_right": -7.0, "grow_horizontal": 2, "grow_vertical": 2, "mouse_filter": 2})
    label(s, "Body/Name", "Site", "LabelMuted", {"size_flags_horizontal": 3, "size_flags_vertical": 4, "text_overrun_behavior": 3})
    label(s, "Body/Need", "Level 8", "LabelMuted", {"size_flags_vertical": 4})
    s.save(R + "locked_row.tscn")


def site_pages():
    """The expedition planner: the crew on the left, the site, orders and forecast on the right."""
    s = page("SiteLeft")
    grp = s.sub("filter", "ButtonGroup", {})
    header(s, C + "/Header", "Choose a Crew")
    s.node(C + "/Filter", "HBoxContainer", {"theme_override_constants/separation": 4})
    for name, text, tip in [("Trade", "Workers", "Hellfarers with the right tool for this site."),
                            ("Guards", "Guards", "Guards cut the risk for the whole crew but gather at half pace."),
                            ("All", "Everyone", "Everyone free, best at this trade first.")]:
        button(s, C + "/Filter/" + name, text, "ToggleButton", {"size_flags_horizontal": 3, "toggle_mode": True, "button_group": grp,
                                                               "custom_minimum_size": (0, 18), "tooltip_text": tip})
    label(s, C + "/Caption", "Up to 3. Click to add or remove.", "LabelCaption")
    scroll(s, C + "/Roster", 80)
    s.inst(C + "/NoCrew", INFO, {"visible": False, "text": "No Hellfarers are free. Hire one in Mercenaries.", "icon_kind": "plus"})
    button(s, C + "/Hire", "Hire in Mercenaries  >", "PaperButton", {"visible": False, "size_flags_horizontal": 4})
    s.node(C + "/Footer", "HBoxContainer")
    button(s, C + "/Footer/Back", "<  All sites", "TextButton")
    s.save(P + "site_left.tscn")

    s = page("SiteRight")
    grp = s.sub("orders", "ButtonGroup", {})
    s.node(C + "/Site", "PanelContainer", {"custom_minimum_size": (0, 100), "theme_type_variation": Raw('&"SlotPanel"')})
    s.node(C + "/Site/Art", "TextureRect", {"mouse_filter": 2, "expand_mode": 1, "stretch_mode": 6})
    s.node(C + "/Site/Badge", "PanelContainer", {"size_flags_horizontal": 8, "size_flags_vertical": 8, "theme_type_variation": Raw('&"GoldPanel"')})
    label(s, C + "/Site/Badge/Text", "Logging 1+")
    s.node(C + "/Intel", "HBoxContainer", {"theme_override_constants/separation": 4})
    s.node(C + "/Intel/Yields", "HBoxContainer", {"size_flags_horizontal": 3, "theme_override_constants/separation": 3})
    s.node(C + "/Intel/Threat", "VBoxContainer", {"size_flags_vertical": 4, "theme_override_constants/separation": -2})
    label(s, C + "/Intel/Threat/Name", "Safe", "LabelGood", {"horizontal_alignment": 2})
    s.inst(C + "/Intel/Threat/Danger", PIPS, {"value": 0, "max_value": 4, "size_flags_horizontal": 8, "tooltip_text": "Danger level"})
    label(s, C + "/Facts", "", "LabelCaption", {"autowrap_mode": 3})
    s.inst(C + "/InField", "res://scenes/journal/rows/expedition_row.tscn", {"visible": False})
    label(s, C + "/Crew", "No crew chosen yet.", "LabelMuted", {"autowrap_mode": 3})
    s.node(C + "/Orders", "HBoxContainer", {"theme_override_constants/separation": 4})
    label(s, C + "/Orders/Caption", "Orders", "LabelCaption", {"custom_minimum_size": (38, 0)})
    for name, text, tip in [("Cautious", "Cautious", "Cautious: safer and slower, a smaller haul."), ("Balanced", "Balanced", "Balanced: a steady haul at the site's normal risk."), ("DeepPush", "Deep Push", "Deep Push: work harder for a bigger haul, at more risk.")]:
        button(s, C + "/Orders/" + name, text, "ToggleButton", {"size_flags_horizontal": 3, "toggle_mode": True, "button_group": grp, "tooltip_text": tip})
    s.node(C + "/Away", "HBoxContainer", {"theme_override_constants/separation": 4})
    label(s, C + "/Away/Caption", "Away", "LabelCaption", {"custom_minimum_size": (38, 0)})
    for name, text, tip in [("LongShift", "Long Shift", "Long Shift: one long trip, six times as long. 80% of the hourly haul for four times the wages and supplies. For when you won't be back for a while."),
                            ("Overnight", "Overnight", "Overnight: an eight-hour trip at any site. Half the hourly haul for a quarter of the wages and supplies, at lower risk. Send it before bed."),
                            ("FullDay", "Full Day", "Full Day: a 20-hour trip at any site, back before the same time tomorrow. 55% of the hourly haul for a fifth of the wages and supplies, at lower risk.")]:
        button(s, C + "/Away/" + name, text, "ToggleButton", {"size_flags_horizontal": 3, "toggle_mode": True, "button_group": grp, "tooltip_text": tip})
    s.node(C + "/Forecast", "HBoxContainer", {"theme_override_constants/separation": 4})
    tile(s, C + "/Forecast/Haul", "Haul", extra={"tooltip_text": "Average goods brought home after the crew's share."})
    tile(s, C + "/Forecast/Profit", "Profit", extra={"tooltip_text": "Value of the haul at today's merchant price, minus wages and supplies."})
    tile(s, C + "/Forecast/Risk", "Risk each", extra={"tooltip_text": "Chance each worker is injured, and killed."})
    spacer(s, C + "/Spacer")
    button(s, C + "/Fund", "Send them down", None, {"custom_minimum_size": (0, 26), "tooltip_text": "Deaths and lost gear are permanent."})
    label(s, C + "/Reason", "", "LabelAccent", {"horizontal_alignment": 1, "autowrap_mode": 3})
    s.save(P + "site_right.tscn")


def dungeon_pages():
    """A dungeon: the planner (fighters left; floors, orders and forecast right) and the run
    (the crew's health and haul left; the floor track and the check-in right)."""
    s = page("DungeonLeft")
    grp = s.sub("filter", "ButtonGroup", {})
    header(s, C + "/Header", "Choose Heroes")
    s.node(C + "/Filter", "HBoxContainer", {"theme_override_constants/separation": 4})
    for name, text, tip in [("Fighters", "Knights", "Knights: more health; armour and block count for more; Guard turns most of a blow."),
                            ("Porters", "Rogues", "Rogues: fast; crit, dodge and armour piercing count for more."),
                            ("All", "All heroes", "Every hero, rested first.")]:
        button(s, C + "/Filter/" + name, text, "ToggleButton", {"size_flags_horizontal": 3, "toggle_mode": True, "button_group": grp,
                                                               "custom_minimum_size": (0, 18), "tooltip_text": tip})
    label(s, C + "/Caption", "Heroes go into the crypts; your crews keep working meanwhile.", "LabelCaption", {"autowrap_mode": 3})
    scroll(s, C + "/Roster", 80)
    s.inst(C + "/NoCrew", INFO, {"visible": False, "text": "No heroes yet. Take one on in Mercenaries, Heroes.", "icon_kind": "plus"})
    s.node(C + "/Footer", "HBoxContainer")
    button(s, C + "/Footer/Back", "<  All crypts", "TextButton")
    s.save(P + "dungeon_left.tscn")

    s = page("DungeonRight")
    depth = s.sub("depth", "ButtonGroup", {})
    back = s.sub("back", "ButtonGroup", {})
    s.node(C + "/Site", "PanelContainer", {"custom_minimum_size": (0, 66), "theme_type_variation": Raw('&"SlotPanel"')})
    s.node(C + "/Site/Art", "TextureRect", {"mouse_filter": 2, "expand_mode": 1, "stretch_mode": 6})
    s.node(C + "/Site/Badge", "PanelContainer", {"size_flags_horizontal": 8, "size_flags_vertical": 8, "theme_type_variation": Raw('&"GoldPanel"')})
    label(s, C + "/Site/Badge/Text", "Tier 1  ·  gear score 8+")
    label(s, C + "/FloorsCaption", "Floors  ·  your heroes' chance to clear, by their own rules", "LabelCaption")
    s.node(C + "/Floors", "HBoxContainer", {"theme_override_constants/separation": 3})
    for i in range(3):
        f = C + "/Floors/F%d" % i
        s.node(f, "PanelContainer", {"size_flags_horizontal": 3, "theme_type_variation": Raw('&"InsetPanel"')})
        s.node(f + "/Body", "VBoxContainer", {"theme_override_constants/separation": -3})
        label(s, f + "/Body/When", "Floor %d" % (i + 1), "LabelCaption")
        label(s, f + "/Body/Name", "Floor", None, {"text_overrun_behavior": 3})
        label(s, f + "/Body/Foe", "Foes", "LabelCaption", {"text_overrun_behavior": 3})
        label(s, f + "/Body/Odds", "-", "LabelGood")
    label(s, C + "/Crew", "No heroes chosen yet.", "LabelMuted", {"autowrap_mode": 3})
    start = s.sub("start", "ButtonGroup", {})
    s.node(C + "/Start", "HBoxContainer", {"theme_override_constants/separation": 3})
    label(s, C + "/Start/Caption", "Start at", "LabelCaption", {"custom_minimum_size": (52, 0)})
    for i, (name, text) in enumerate([("S1", "Floor 1"), ("S2", "Floor 2"), ("S3", "The boss")]):
        button(s, C + "/Start/" + name, text, "ToggleButton", {"size_flags_horizontal": 3, "toggle_mode": True, "button_group": start,
            "tooltip_text": "Every floor you clear stays open: later runs can start at its stairs."})
    label(s, C + "/OrdersCaption", "Standing orders  ·  when they go without you", "LabelCaption")
    s.node(C + "/Depth", "HBoxContainer", {"theme_override_constants/separation": 3})
    label(s, C + "/Depth/Caption", "As deep as", "LabelCaption", {"custom_minimum_size": (52, 0)})
    for i, (name, text) in enumerate([("D1", "Floor 1"), ("D2", "Floor 2"), ("D3", "The boss")]):
        button(s, C + "/Depth/" + name, text, "ToggleButton", {"size_flags_horizontal": 3, "toggle_mode": True, "button_group": depth,
                                                              "tooltip_text": "Standing orders: come out after this floor, unless you push on at a check-in."})
    s.node(C + "/Back", "HBoxContainer", {"theme_override_constants/separation": 3})
    label(s, C + "/Back/Caption", "Turn back", "LabelCaption", {"custom_minimum_size": (52, 0)})
    for name, text, tip in [("Half", "Below half", "Come out when anyone is below half health, and back out of a fight before anyone falls."),
                            ("Death", "Someone dies", "Keep going until someone dies."),
                            ("Never", "Never", "Go all the way to the planned depth, whatever happens.")]:
        button(s, C + "/Back/" + name, text, "ToggleButton", {"size_flags_horizontal": 3, "toggle_mode": True, "button_group": back, "tooltip_text": tip})
    risk = s.sub("risk", "ButtonGroup", {})
    s.node(C + "/Risk", "HBoxContainer", {"theme_override_constants/separation": 3})
    label(s, C + "/Risk/Caption", "If unsure", "LabelCaption", {"custom_minimum_size": (52, 0),
        "tooltip_text": "Things happen about every 20 seconds. You choose; if you don't within 15 seconds, the crew does, this way."})
    for name, text, tip in [("Safe", "Play it safe", "The crew takes the careful choice when nobody answers."),
                            ("Bold", "Take chances", "The crew takes the risky choice when nobody answers.")]:
        button(s, C + "/Risk/" + name, text, "ToggleButton", {"size_flags_horizontal": 3, "toggle_mode": True, "button_group": risk, "tooltip_text": tip})
    s.node(C + "/Forecast", "HBoxContainer", {"theme_override_constants/separation": 4})
    tile(s, C + "/Forecast/Haul", "Haul out", extra={"tooltip_text": "Average coin and goods carried out under these orders, after the crew's share."})
    tile(s, C + "/Forecast/Death", "Someone dies", extra={"tooltip_text": "Chance at least one of the crew dies under these orders."})
    tile(s, C + "/Forecast/Time", "Back in", extra={"tooltip_text": "Time down and back under these orders, check-ins included."})
    tile(s, C + "/Forecast/Rations", "Rations", extra={"tooltip_text": "Each hero eats one cooked meal a floor. Cook meals in the Workshop."})
    label(s, C + "/Rule", "A death makes the heroes drop half of what they carry. If they all fall, everything stays below.", "LabelCaption", {"autowrap_mode": 3})
    spacer(s, C + "/Spacer")
    s.node(C + "/Go", "HBoxContainer", {"theme_override_constants/separation": 4})
    button(s, C + "/Go/Lead", "Lead them in", None, {"custom_minimum_size": (0, 26), "size_flags_horizontal": 3, "size_flags_stretch_ratio": 1.4,
        "tooltip_text": "Go down with them: you choose every action in every fight, and when to come back up. Deaths and lost gear are permanent."})
    button(s, C + "/Go/Enter", "Let them handle it", None, {"custom_minimum_size": (0, 26), "size_flags_horizontal": 3,
        "tooltip_text": "They go by the standing orders above and come back on their own, even while the game is closed."})
    label(s, C + "/Reason", "", "LabelAccent", {"horizontal_alignment": 1, "autowrap_mode": 3})
    s.save(P + "dungeon_right.tscn")

    s = page("RunLeft")
    header(s, C + "/Header", "The Crew")
    s.node(C + "/Crew", "VBoxContainer", {"theme_override_constants/separation": 3})
    label(s, C + "/CarryCaption", "Carrying", "LabelCaption", {"autowrap_mode": 3})
    s.node(C + "/Carry", "HBoxContainer", {"theme_override_constants/separation": 3})
    label(s, C + "/NoCarry", "Nothing yet.", "LabelMuted")
    label(s, C + "/Found", "", "LabelCaption", {"autowrap_mode": 3})
    label(s, C + "/EventsCaption", "Along the way", "LabelCaption", {"visible": False})
    s.node(C + "/Events", "VBoxContainer", {"theme_override_constants/separation": 1})
    label(s, C + "/DroppedCaption", "Left below", "LabelCaption")
    s.node(C + "/Dropped", "HBoxContainer", {"theme_override_constants/separation": 3})
    spacer(s, C + "/Spacer")
    label(s, C + "/Walk", "", "LabelMuted", {"horizontal_alignment": 1, "autowrap_mode": 3})
    s.node(C + "/Footer", "HBoxContainer")
    button(s, C + "/Footer/Back", "<  All crypts", "TextButton")
    s.save(P + "run_left.tscn")

    s = page("RunRight")
    header(s, C + "/Header", "The Run")
    s.node(C + "/Track", "VBoxContainer", {"theme_override_constants/separation": 4})
    for i in range(3):
        f = C + "/Track/F%d" % i
        s.node(f, "HBoxContainer", {"theme_override_constants/separation": 6})
        s.node(f + "/Dot", "TextureRect", {"custom_minimum_size": (16, 16), "size_flags_vertical": 0, "mouse_filter": 2, "stretch_mode": 3})
        s.node(f + "/Text", "VBoxContainer", {"size_flags_horizontal": 3, "theme_override_constants/separation": -3})
        label(s, f + "/Text/Name", "Floor %d" % (i + 1))
        label(s, f + "/Text/Note", "Ahead.", "LabelCaption", {"autowrap_mode": 3})
    s.node(C + "/Prompt", "PanelContainer", {"visible": False, "theme_type_variation": Raw('&"GoldPanel"')})
    s.node(C + "/Prompt/Body", "VBoxContainer", {"theme_override_constants/separation": 3})
    label(s, C + "/Prompt/Body/Title", "Floor cleared.", None, {"autowrap_mode": 3})
    label(s, C + "/Prompt/Body/Text", "", "LabelCaption", {"autowrap_mode": 3})
    s.node(C + "/Prompt/Body/Buttons", "HBoxContainer", {"theme_override_constants/separation": 4})
    button(s, C + "/Prompt/Body/Buttons/Push", "Push on", "PaperButton", {"size_flags_horizontal": 3})
    button(s, C + "/Prompt/Body/Buttons/Out", "Take it out", None, {"size_flags_horizontal": 3})
    label(s, C + "/Prompt/Body/Timer", "", "LabelCaption", {"horizontal_alignment": 1})
    spacer(s, C + "/Spacer")
    label(s, C + "/Note", "Away from the game? The crew follows its orders and you read the report later.", "LabelMuted", {"horizontal_alignment": 1, "autowrap_mode": 3})
    s.save(P + "run_right.tscn")


def auction_pages():
    """The Auction House: Browse (buy), Sell (post a listing) and Yours (listings, orders and
    what happened), each a two-page spread under the Market's tabs."""
    def sub(s):
        grp = s.sub("sub", "ButtonGroup", {})
        s.node(C + "/Sub", "HBoxContainer", {"theme_override_constants/separation": 4})
        for name, text in [("Browse", "Browse"), ("Sell", "Sell"), ("Yours", "Yours")]:
            button(s, C + "/Sub/" + name, text, "ToggleButton", {"size_flags_horizontal": 3, "toggle_mode": True, "button_group": grp, "custom_minimum_size": (0, 18)})

    def filters(s, names):
        grp = s.sub("filter", "ButtonGroup", {})
        s.node(C + "/Filter", "HBoxContainer", {"theme_override_constants/separation": 3})
        for name, text in names:
            button(s, C + "/Filter/" + name, text, "ToggleButton", {"size_flags_horizontal": 3, "toggle_mode": True, "button_group": grp, "custom_minimum_size": (0, 18)})

    def columns(s, a, b, c):
        s.node(C + "/Columns", "HBoxContainer", {"theme_override_constants/separation": 6})
        label(s, C + "/Columns/Item", a, "LabelCaption", {"size_flags_horizontal": 3})
        label(s, C + "/Columns/Count", b, "LabelCaption", {"custom_minimum_size": (34, 0), "horizontal_alignment": 2})
        label(s, C + "/Columns/Price", c, "LabelCaption", {"custom_minimum_size": (52, 0), "horizontal_alignment": 2})

    def head(s):
        s.node(C + "/Head", "HBoxContainer", {"theme_override_constants/separation": 8})
        s.node(C + "/Head/Slot", "PanelContainer", {"custom_minimum_size": (34, 34), "theme_type_variation": Raw('&"SlotPanel"')})
        s.node(C + "/Head/Slot/Icon", "TextureRect", {"mouse_filter": 2, "stretch_mode": 3})
        s.node(C + "/Head/Id", "VBoxContainer", {"size_flags_horizontal": 3, "size_flags_vertical": 4, "theme_override_constants/separation": -3})
        label(s, C + "/Head/Id/Name", "Item", "LabelTitle", {"text_overrun_behavior": 3})
        label(s, C + "/Head/Id/Desc", "", "LabelCaption", {"autowrap_mode": 3})

    def stepper(s, path, caption, extra=None):
        s.node(path, "HBoxContainer", {"theme_override_constants/separation": 3})
        label(s, path + "/Caption", caption, "LabelCaption", {"custom_minimum_size": (52, 0)})
        button(s, path + "/Minus", "-", "PaperButton", {"custom_minimum_size": (18, 18)})
        s.node(path + "/Value", "LineEdit", {"custom_minimum_size": (0, 18), "size_flags_horizontal": 3, "context_menu_enabled": False, "max_length": 7})
        button(s, path + "/Plus", "+", "PaperButton", {"custom_minimum_size": (18, 18)})
        if extra:
            button(s, path + "/" + extra[0], extra[1], "PaperButton", {"custom_minimum_size": (28, 18)})

    def durations(s, path, grp):
        s.node(path, "HBoxContainer", {"theme_override_constants/separation": 3})
        label(s, path + "/Caption", "Up for", "LabelCaption", {"custom_minimum_size": (52, 0)})
        for name, text in [("H12", "12 hours"), ("D1", "1 day"), ("D2", "2 days")]:
            button(s, path + "/" + name, text, "ToggleButton", {"size_flags_horizontal": 3, "toggle_mode": True, "button_group": grp, "custom_minimum_size": (0, 18)})

    # Browse
    s = page("AuctionBrowseLeft", top=36)
    sub(s)
    s.node(C + "/Search", "LineEdit", {"custom_minimum_size": (0, 20), "placeholder_text": "Search: sword, timber, spider silk...",
        "clear_button_enabled": True, "context_menu_enabled": False, "max_length": 40})
    filters(s, [("All", "All"), ("Goods", "Goods"), ("Arms", "Arms"), ("Armour", "Armour"), ("Tools", "Tools"), ("Food", "Food")])
    columns(s, "Item", "Listed", "From")
    scroll(s, C + "/List", 80)
    label(s, C + "/Empty", "Nothing listed matches. Search by name to post a buy order for anything.", "LabelMuted", {"visible": False, "autowrap_mode": 3, "horizontal_alignment": 1})
    label(s, C + "/Hint", "Prices are each. Search to find things nobody is selling right now.", "LabelMuted", {"autowrap_mode": 3, "horizontal_alignment": 1})
    s.save(P + "auction_browse_left.tscn")

    s = page("AuctionBrowseRight")
    head(s)
    header(s, C + "/SaleHeader", "For Sale")
    s.node(C + "/BuyQty", "HBoxContainer", {"theme_override_constants/separation": 3})
    label(s, C + "/BuyQty/Caption", "Buy", "LabelCaption", {"custom_minimum_size": (52, 0)})
    grp = s.sub("qty", "ButtonGroup", {})
    for name, text in [("One", "1"), ("Ten", "10"), ("All", "All of it")]:
        button(s, C + "/BuyQty/" + name, text, "ToggleButton", {"size_flags_horizontal": 3, "toggle_mode": True, "button_group": grp, "custom_minimum_size": (0, 18)})
    scroll(s, C + "/Listings", 60)
    label(s, C + "/NoListings", "Nobody is selling one right now. Post a buy order below and sellers come to you.", "LabelMuted", {"visible": False, "autowrap_mode": 3})
    header(s, C + "/OrderHeader", "Buy Order")
    stepper(s, C + "/OrderQty", "How many")
    stepper(s, C + "/OrderPrice", "Price each")
    durations(s, C + "/OrderTime", s.sub("otime", "ButtonGroup", {}))
    label(s, C + "/OrderNote", "", "LabelCaption", {"autowrap_mode": 3})
    button(s, C + "/Place", "Place buy order", None, {"custom_minimum_size": (0, 22)})
    s.inst(C + "/Empty", INFO, {"visible": False, "text": "Pick an item on the left.", "icon_kind": "home"})
    s.save(P + "auction_browse_right.tscn")

    # Sell
    s = page("AuctionSellLeft", top=36)
    sub(s)
    filters(s, [("All", "All"), ("Goods", "Goods"), ("Gear", "Gear")])
    columns(s, "Item", "Held", "Going for")
    scroll(s, C + "/List", 80)
    label(s, C + "/Empty", "Nothing to sell yet. Goods your crews bring home and spare gear show here.", "LabelMuted", {"visible": False, "autowrap_mode": 3, "horizontal_alignment": 1})
    label(s, C + "/Hint", "\"Going for\" is the cheapest listing right now.", "LabelMuted", {"autowrap_mode": 3, "horizontal_alignment": 1})
    s.save(P + "auction_sell_left.tscn")

    s = page("AuctionSellRight")
    head(s)
    s.node(C + "/Order", "PanelContainer", {"visible": False, "theme_type_variation": Raw('&"GoldPanel"')})
    s.node(C + "/Order/Row", "HBoxContainer", {"theme_override_constants/separation": 6})
    label(s, C + "/Order/Row/Text", "", None, {"size_flags_horizontal": 3, "autowrap_mode": 3})
    button(s, C + "/Order/Row/Fill", "Sell", None, {"size_flags_vertical": 4})
    header(s, C + "/PostHeader", "Post a Listing")
    stepper(s, C + "/Qty", "How many", ("All", "All"))
    stepper(s, C + "/Price", "Price each")
    s.node(C + "/Marks", "HBoxContainer", {"theme_override_constants/separation": 3})
    label(s, C + "/Marks/Caption", "Set to", "LabelCaption", {"custom_minimum_size": (52, 0)})
    for name, text, tip in [("Merchant", "Merchants", "What merchants pay you now: sells at once, but for less."),
                            ("Cheapest", "Cheapest", "Match the cheapest listing: buyers take the cheapest first."),
                            ("Usual", "Usual", "The usual price for it lately.")]:
        button(s, C + "/Marks/" + name, text, "PaperButton", {"size_flags_horizontal": 3, "custom_minimum_size": (0, 18), "tooltip_text": tip})
    durations(s, C + "/Time", s.sub("time", "ButtonGroup", {}))
    s.node(C + "/Forecast", "HBoxContainer", {"theme_override_constants/separation": 4})
    tile(s, C + "/Forecast/Sells", "Sells in", extra={"tooltip_text": "Roughly how long until it all sells at this price."})
    tile(s, C + "/Forecast/Fee", "Fee  ·  cut", extra={"tooltip_text": "1% of the asking total when posting (kept even if it doesn't sell), and 5% of each sale."})
    tile(s, C + "/Forecast/Take", "You get", extra={"tooltip_text": "If it all sells: the sales less the cut and the fee."})
    label(s, C + "/Advice", "", "LabelCaption", {"autowrap_mode": 3})
    spacer(s, C + "/Spacer")
    button(s, C + "/Post", "Post listing", None, {"custom_minimum_size": (0, 24)})
    label(s, C + "/Reason", "Gold arrives as it sells. Whatever's left when it ends comes back.", "LabelMuted", {"horizontal_alignment": 1, "autowrap_mode": 3})
    s.inst(C + "/Empty", INFO, {"visible": False, "text": "Pick something to sell on the left.", "icon_kind": "home"})
    s.save(P + "auction_sell_right.tscn")

    # Yours
    s = page("AuctionYoursLeft", top=36)
    sub(s)
    header(s, C + "/ListingsHeader", "Listings")
    scroll(s, C + "/Listings", 50)
    label(s, C + "/NoListings", "Nothing listed. Post from the Sell tab.", "LabelMuted", {"visible": False})
    header(s, C + "/OrdersHeader", "Buy Orders")
    scroll(s, C + "/Orders", 40)
    label(s, C + "/NoOrders", "No buy orders. Place one from Browse.", "LabelMuted", {"visible": False})
    label(s, C + "/Limits", "Up to 10 listings and 10 buy orders at once.", "LabelMuted", {"horizontal_alignment": 1})
    s.save(P + "auction_yours_left.tscn")

    s = page("AuctionYoursRight")
    header(s, C + "/Header", "Last 24 Hours")
    s.node(C + "/Totals", "HBoxContainer", {"theme_override_constants/separation": 4})
    tile(s, C + "/Totals/Sold", "Sold")
    tile(s, C + "/Totals/Bought", "Bought")
    tile(s, C + "/Totals/Fees", "Fees and cut")
    label(s, C + "/RecentCaption", "Recent", "LabelCaption")
    scroll(s, C + "/Log", 80)
    label(s, C + "/NoLog", "Nothing has sold or arrived yet.", "LabelMuted", {"visible": False, "horizontal_alignment": 1})
    s.save(P + "auction_yours_right.tscn")


def event_card():
    """Something happening in a dungeon: the card that slides in over any page, with the choices."""
    s = Scene("EventCard", "Control", {"visible": False, "layout_mode": 3, "anchors_preset": 15, "anchor_right": 1.0, "anchor_bottom": 1.0,
        "grow_horizontal": 2, "grow_vertical": 2, "mouse_filter": 2})
    s.node("Card", "PanelContainer", {"layout_mode": 1, "anchors_preset": 3, "anchor_left": 1.0, "anchor_top": 1.0, "anchor_right": 1.0, "anchor_bottom": 1.0,
        "offset_left": -262.0, "offset_top": -190.0, "offset_right": -16.0, "offset_bottom": -14.0, "grow_horizontal": 0, "grow_vertical": 0,
        "theme_type_variation": Raw('&"InsetPanel"')})
    s.node("Card/Margin", "MarginContainer", {"theme_override_constants/margin_left": 8, "theme_override_constants/margin_top": 6,
        "theme_override_constants/margin_right": 8, "theme_override_constants/margin_bottom": 6})
    B = "Card/Margin/Body"
    s.node(B, "VBoxContainer", {"theme_override_constants/separation": 3})
    s.node(B + "/Head", "HBoxContainer", {"theme_override_constants/separation": 4})
    s.node(B + "/Head/Icon", "TextureRect", {"custom_minimum_size": (14, 14), "size_flags_vertical": 4, "mouse_filter": 2, "stretch_mode": 3,
        "texture": Res("res://assets/ui/icons/relic.png")})
    label(s, B + "/Head/Title", "The Fallen Keep  ·  Floor 1", "LabelCaption", {"size_flags_horizontal": 3})
    button(s, B + "/Head/Open", "Run  >", "TextButton", {"tooltip_text": "Open the run."})
    label(s, B + "/Text", "", None, {"custom_minimum_size": (230, 0), "autowrap_mode": 3})
    label(s, B + "/Hint", "", "LabelGood", {"autowrap_mode": 3})
    s.node(B + "/Choices", "VBoxContainer", {"theme_override_constants/separation": 3})
    for i in range(3):
        button(s, B + "/Choices/C%d" % i, "Choice", "PaperButton", {"custom_minimum_size": (0, 20)})
    label(s, B + "/Result", "", None, {"visible": False, "autowrap_mode": 3})
    s.node(B + "/Timer", "ProgressBar", {"custom_minimum_size": (0, 4), "theme_type_variation": Raw('&"GoldBar"'), "max_value": 100.0, "value": 100.0, "show_percentage": False})
    label(s, B + "/TimerText", "", "LabelCaption")
    s.save("scenes/journal/widgets/event_card.tscn")


def tutorial_card():
    """The first-launch tutorial: a card bottom right, and a gold pointer for the bookmark to open."""
    s = Scene("TutorialCard", "Control", {"visible": False, "layout_mode": 3, "anchors_preset": 15, "anchor_right": 1.0, "anchor_bottom": 1.0,
        "grow_horizontal": 2, "grow_vertical": 2, "mouse_filter": 2})
    s.node("Pointer", "TextureRect", {"layout_mode": 0, "offset_right": 24.0, "offset_bottom": 22.0, "mouse_filter": 2,
        "texture": Res("res://assets/ui/kit/pointer.png"), "expand_mode": 1, "stretch_mode": 0})
    s.node("Card", "PanelContainer", {"layout_mode": 1, "anchors_preset": 3, "anchor_left": 1.0, "anchor_top": 1.0, "anchor_right": 1.0, "anchor_bottom": 1.0,
        "offset_left": -262.0, "offset_top": -150.0, "offset_right": -16.0, "offset_bottom": -14.0, "grow_horizontal": 0, "grow_vertical": 0,
        "theme_type_variation": Raw('&"InsetPanel"')})
    s.node("Card/Margin", "MarginContainer", {"theme_override_constants/margin_left": 8, "theme_override_constants/margin_top": 6,
        "theme_override_constants/margin_right": 8, "theme_override_constants/margin_bottom": 6})
    B = "Card/Margin/Body"
    s.node(B, "VBoxContainer", {"theme_override_constants/separation": 4})
    s.node(B + "/Head", "HBoxContainer", {"theme_override_constants/separation": 4})
    s.node(B + "/Head/Icon", "TextureRect", {"custom_minimum_size": (13, 14), "size_flags_vertical": 4, "mouse_filter": 2, "stretch_mode": 5,
        "texture": Res("res://assets/ui/art/crest.png"), "expand_mode": 1})
    label(s, B + "/Head/Step", "Step 1 of 4", "LabelCaption", {"size_flags_horizontal": 3})
    button(s, B + "/Head/Skip", "Skip tutorial", "TextButton", {"tooltip_text": "Hide the tutorial for this guild."})
    label(s, B + "/Title", "Welcome to Last Lantern", "LabelAccent", {"autowrap_mode": 3})
    label(s, B + "/Text", "", None, {"custom_minimum_size": (230, 0), "autowrap_mode": 3})
    s.node(B + "/Do", "HBoxContainer", {"theme_override_constants/separation": 4})
    s.node(B + "/Do/Arrow", "TextureRect", {"custom_minimum_size": (10, 9), "size_flags_vertical": 4, "mouse_filter": 2,
        "texture": Res("res://assets/ui/kit/pointer.png"), "expand_mode": 1, "stretch_mode": 5})
    label(s, B + "/Do/Text", "", "LabelAccent", {"size_flags_horizontal": 3, "autowrap_mode": 3})
    button(s, B + "/Next", "Show me", None, {"custom_minimum_size": (0, 22)})
    s.save("scenes/journal/widgets/tutorial_card.tscn")


def crawl_fighter():
    """One fighter on the crawl screen: name, health, status and the sprite (3x)."""
    s = Scene("CrawlFighter", "VBoxContainer", {"custom_minimum_size": (110, 0), "mouse_filter": 0, "alignment": 2,
        "theme_override_constants/separation": 1})
    label(s, "Mark", "Target", "DeskCaption", {"horizontal_alignment": 1, "modulate": Raw("Color(1, 0.8, 0.4, 1)"), "visible": False})
    label(s, "Name", "Name", "DeskLabel", {"horizontal_alignment": 1, "clip_text": True, "custom_minimum_size": (110, 0)})
    s.node("Bar", "ProgressBar", {"custom_minimum_size": (72, 6), "size_flags_horizontal": 4, "show_percentage": False,
        "theme_type_variation": Raw('&"GreenBar"'), "value": 100.0})
    label(s, "HP", "100 / 100", "DeskCaption", {"horizontal_alignment": 1})
    label(s, "Status", "", "DeskCaption", {"horizontal_alignment": 1, "modulate": Raw("Color(1, 0.75, 0.45, 1)")})
    s.node("Sprite", "TextureRect", {"custom_minimum_size": (48, 48), "size_flags_horizontal": 4, "mouse_filter": 2,
        "expand_mode": 1, "stretch_mode": 5, "script": Res("res://scripts/ui/crawl_sprite.gd", "Script")})
    s.save(R + "crawl_fighter.tscn")


def crawl_view():
    """The crypt crawl: heroes on the left, monsters on the right, the player's actions below."""
    s = Scene("CrawlView", "Control", {"visible": False, "layout_mode": 3, "anchors_preset": 15, "anchor_right": 1.0, "anchor_bottom": 1.0,
        "grow_horizontal": 2, "grow_vertical": 2, "script": Res("res://scripts/ui/crawl_view.gd")})
    s.node("Dim", "ColorRect", {"layout_mode": 1, "anchors_preset": 15, "anchor_right": 1.0, "anchor_bottom": 1.0, "grow_horizontal": 2,
        "grow_vertical": 2, "color": Raw("Color(0.04, 0.02, 0.02, 0.88)")})
    s.node("Frame", "PanelContainer", {"layout_mode": 1, "anchors_preset": 8, "anchor_left": 0.5, "anchor_top": 0.5, "anchor_right": 0.5,
        "anchor_bottom": 0.5, "offset_left": -392.0, "offset_top": -256.0, "offset_right": 392.0, "offset_bottom": 256.0,
        "grow_horizontal": 2, "grow_vertical": 2, "theme_type_variation": Raw('&"DeskPanel"')})
    s.node("Frame/Margin", "MarginContainer", {"theme_override_constants/margin_left": 8, "theme_override_constants/margin_top": 6,
        "theme_override_constants/margin_right": 8, "theme_override_constants/margin_bottom": 8})
    B = "Frame/Margin/Body"
    s.node(B, "VBoxContainer", {"theme_override_constants/separation": 6})
    s.node(B + "/Head", "HBoxContainer", {"theme_override_constants/separation": 8})
    label(s, B + "/Head/Title", "The Fallen Keep  ·  Floor 1 of 3  ·  The Cellars", "DeskTitle", {"size_flags_horizontal": 3})
    label(s, B + "/Head/Round", "Round 1", "DeskLabel", {"size_flags_vertical": 4})
    button(s, B + "/Head/Release", "Let them handle it", None, {"custom_minimum_size": (0, 22), "tooltip_text":
        "Stop leading. The heroes play this fight and the rest of the run by their standing orders, and come back on their own."})
    s.node(B + "/Arena", "Control", {"custom_minimum_size": (768, 300), "size_flags_vertical": 3, "clip_contents": True, "mouse_filter": 2})
    s.node(B + "/Arena/Back", "TextureRect", {"layout_mode": 1, "anchors_preset": 15, "anchor_right": 1.0, "anchor_bottom": 1.0,
        "grow_horizontal": 2, "grow_vertical": 2, "mouse_filter": 2, "expand_mode": 1, "stretch_mode": 6})
    s.node(B + "/Arena/Floor", "ColorRect", {"layout_mode": 1, "anchors_preset": 12, "anchor_top": 1.0, "anchor_right": 1.0, "anchor_bottom": 1.0,
        "offset_top": -26.0, "grow_horizontal": 2, "grow_vertical": 0, "mouse_filter": 2, "color": Raw("Color(0.05, 0.03, 0.03, 0.55)")})
    s.node(B + "/Arena/Party", "HBoxContainer", {"layout_mode": 1, "anchors_preset": 2, "anchor_top": 1.0, "anchor_bottom": 1.0,
        "offset_left": 24.0, "offset_top": -270.0, "offset_right": 380.0, "offset_bottom": -12.0, "grow_vertical": 0,
        "theme_override_constants/separation": 6, "alignment": 0})
    s.node(B + "/Arena/Foes", "HBoxContainer", {"layout_mode": 1, "anchors_preset": 3, "anchor_left": 1.0, "anchor_top": 1.0,
        "anchor_right": 1.0, "anchor_bottom": 1.0, "offset_left": -560.0, "offset_top": -270.0, "offset_right": -16.0, "offset_bottom": -12.0,
        "grow_horizontal": 0, "grow_vertical": 0, "theme_override_constants/separation": 2, "alignment": 2})
    s.node(B + "/Arena/Floaters", "Control", {"layout_mode": 1, "anchors_preset": 15, "anchor_right": 1.0, "anchor_bottom": 1.0,
        "grow_horizontal": 2, "grow_vertical": 2, "mouse_filter": 2})
    label(s, B + "/Arena/Callout", "", "DeskTitle", {"layout_mode": 1, "anchors_preset": 10, "anchor_right": 1.0, "offset_top": 12.0,
        "offset_bottom": 44.0, "grow_horizontal": 2, "horizontal_alignment": 1, "theme_override_colors/font_color": Raw("Color(1, 0.86, 0.58, 1)"),
        "theme_override_colors/font_outline_color": Raw("Color(0.08, 0.04, 0.03, 1)"), "theme_override_constants/outline_size": 4,
        "theme_override_font_sizes/font_size": 24})
    # Below the arena: the hero's choices and the log; or the stairs between floors; or the end.
    s.node(B + "/Turn", "HBoxContainer", {"custom_minimum_size": (0, 112), "theme_override_constants/separation": 8})
    s.node(B + "/Turn/Left", "VBoxContainer", {"size_flags_horizontal": 3, "theme_override_constants/separation": 5})
    label(s, B + "/Turn/Left/Prompt", "Your turn.", "DeskLabel", {"autowrap_mode": 3})
    s.node(B + "/Turn/Left/Actions", "HBoxContainer", {"theme_override_constants/separation": 4})
    # The moves come from the hero's gear (crawl.gd): the book fills in names, costs and tips.
    for name in ["Strike", "Special", "Skill", "Guard", "Potion", "Oil", "Retreat"]:
        button(s, B + "/Turn/Left/Actions/" + name, name, None, {"custom_minimum_size": (0, 26), "size_flags_horizontal": 3})
    label(s, B + "/Turn/Left/Hint", "Click a monster to choose who to hit.", "DeskCaption", {"autowrap_mode": 3})
    s.node(B + "/Turn/Log", "PanelContainer", {"custom_minimum_size": (330, 0), "theme_type_variation": Raw('&"InsetPanel"')})
    s.node(B + "/Turn/Log/Margin", "MarginContainer", {"theme_override_constants/margin_left": 6, "theme_override_constants/margin_top": 4,
        "theme_override_constants/margin_right": 6, "theme_override_constants/margin_bottom": 4})
    s.node(B + "/Turn/Log/Margin/Text", "RichTextLabel", {"bbcode_enabled": True, "scroll_following": True, "fit_content": False,
        "size_flags_vertical": 3, "theme_override_colors/default_color": Raw("Color(0.239, 0.157, 0.141, 1)")})
    s.node(B + "/Stairs", "PanelContainer", {"visible": False, "custom_minimum_size": (0, 112), "theme_type_variation": Raw('&"InsetPanel"')})
    s.node(B + "/Stairs/Margin", "MarginContainer", {"theme_override_constants/margin_left": 10, "theme_override_constants/margin_top": 8,
        "theme_override_constants/margin_right": 10, "theme_override_constants/margin_bottom": 8})
    S2 = B + "/Stairs/Margin/Body"
    s.node(S2, "VBoxContainer", {"theme_override_constants/separation": 5})
    label(s, S2 + "/Title", "The Cellars cleared", "LabelTitle")
    label(s, S2 + "/Text", "", None, {"autowrap_mode": 3})
    s.node(S2 + "/Carry", "HBoxContainer", {"theme_override_constants/separation": 4})
    s.node(S2 + "/Buttons", "HBoxContainer", {"theme_override_constants/separation": 6})
    button(s, S2 + "/Buttons/Push", "Go down", None, {"custom_minimum_size": (0, 26), "size_flags_horizontal": 3})
    button(s, S2 + "/Buttons/Leave", "Take it out", None, {"custom_minimum_size": (0, 26), "size_flags_horizontal": 3})
    s.save("scenes/journal/widgets/crawl_view.tscn")


def prologue_view():
    """The prologue: story cards over a dark screen, and the choice of the guild's first hero."""
    s = Scene("PrologueView", "Control", {"visible": False, "layout_mode": 3, "anchors_preset": 15, "anchor_right": 1.0, "anchor_bottom": 1.0,
        "grow_horizontal": 2, "grow_vertical": 2, "script": Res("res://scripts/ui/prologue.gd")})
    s.node("Veil", "ColorRect", {"layout_mode": 1, "anchors_preset": 15, "anchor_right": 1.0, "anchor_bottom": 1.0, "grow_horizontal": 2,
        "grow_vertical": 2, "color": Raw("Color(0.02, 0.01, 0.01, 1)")})
    s.node("Card", "PanelContainer", {"layout_mode": 1, "anchors_preset": 8, "anchor_left": 0.5, "anchor_top": 0.5, "anchor_right": 0.5,
        "anchor_bottom": 0.5, "offset_left": -250.0, "offset_top": -110.0, "offset_right": 250.0, "offset_bottom": 110.0,
        "grow_horizontal": 2, "grow_vertical": 2, "theme_type_variation": Raw('&"DeskPanel"')})
    s.node("Card/Margin", "MarginContainer", {"theme_override_constants/margin_left": 18, "theme_override_constants/margin_top": 14,
        "theme_override_constants/margin_right": 18, "theme_override_constants/margin_bottom": 14})
    B = "Card/Margin/Body"
    s.node(B, "VBoxContainer", {"theme_override_constants/separation": 8})
    label(s, B + "/Kicker", "Prologue", "DeskCaption", {"horizontal_alignment": 1})
    label(s, B + "/Title", "The Lantern Company", "DeskTitle", {"horizontal_alignment": 1, "theme_override_font_sizes/font_size": 22})
    label(s, B + "/Text", "", "DeskLabel", {"autowrap_mode": 3, "custom_minimum_size": (460, 0)})
    s.node(B + "/Buttons", "HBoxContainer", {"alignment": 1, "theme_override_constants/separation": 8})
    button(s, B + "/Buttons/Next", "Go down", None, {"custom_minimum_size": (160, 26)})
    button(s, B + "/Buttons/Skip", "Skip the prologue", "TextButton", {"tooltip_text": "Straight to Last Lantern and your new guild."})
    s.node("Choice", "VBoxContainer", {"visible": False, "layout_mode": 1, "anchors_preset": 8, "anchor_left": 0.5, "anchor_top": 0.5,
        "anchor_right": 0.5, "anchor_bottom": 0.5, "offset_left": -300.0, "offset_top": -200.0, "offset_right": 300.0, "offset_bottom": 200.0,
        "grow_horizontal": 2, "grow_vertical": 2, "theme_override_constants/separation": 10, "alignment": 1})
    label(s, "Choice/Title", "Who will lead your guild below?", "DeskTitle", {"horizontal_alignment": 1, "theme_override_font_sizes/font_size": 22})
    label(s, "Choice/Sub", "Your hero goes into the crypts; your crews work the sites. You can take on more heroes later.", "DeskLabel",
        {"horizontal_alignment": 1, "autowrap_mode": 3})
    s.node("Choice/Options", "HBoxContainer", {"alignment": 1, "theme_override_constants/separation": 14})
    for cls in ["Knight", "Rogue"]:
        o = "Choice/Options/" + cls
        s.node(o, "PanelContainer", {"custom_minimum_size": (250, 0), "theme_type_variation": Raw('&"InsetPanel"')})
        s.node(o + "/Margin", "MarginContainer", {"theme_override_constants/margin_left": 10, "theme_override_constants/margin_top": 8,
            "theme_override_constants/margin_right": 10, "theme_override_constants/margin_bottom": 10})
        s.node(o + "/Margin/Body", "VBoxContainer", {"theme_override_constants/separation": 5})
        s.node(o + "/Margin/Body/Sprite", "TextureRect", {"custom_minimum_size": (48, 48), "size_flags_horizontal": 4, "expand_mode": 1,
            "stretch_mode": 5, "texture": Res("res://assets/ui/crawl/%s.png" % cls.lower())})
        label(s, o + "/Margin/Body/Name", cls, "LabelTitle", {"horizontal_alignment": 1})
        label(s, o + "/Margin/Body/Blurb", "", None, {"autowrap_mode": 3, "custom_minimum_size": (228, 0)})
        label(s, o + "/Margin/Body/Skill", "", "LabelAccent", {"autowrap_mode": 3})
        label(s, o + "/Margin/Body/Wants", "", "LabelCaption", {"autowrap_mode": 3})
        button(s, o + "/Margin/Body/Choose", "Choose the " + cls.lower(), None, {"custom_minimum_size": (0, 26)})
    s.node("Choice/GuildRow", "HBoxContainer", {"alignment": 1, "theme_override_constants/separation": 8})
    label(s, "Choice/GuildRow/Caption", "Your new guild:", "DeskCaption", {"size_flags_vertical": 4})
    s.node("Choice/GuildRow/Name", "LineEdit", {"custom_minimum_size": (200, 22), "max_length": 28, "placeholder_text": "Name your guild",
        "tooltip_text": "What Last Lantern will call you. You can change it later in Settings."})
    button(s, "Choice/GuildRow/Another", "Another name", "TextButton")
    s.node("Choice/NameRow", "HBoxContainer", {"alignment": 1, "theme_override_constants/separation": 8})
    label(s, "Choice/NameRow/Caption", "Their name:", "DeskCaption", {"size_flags_vertical": 4})
    label(s, "Choice/NameRow/Name", "Brannoc Ashby", "DeskLabel", {"size_flags_vertical": 4})
    button(s, "Choice/NameRow/Another", "Another name", "TextButton")
    s.save("scenes/journal/widgets/prologue_view.tscn")


def exchange_tabs():
    s = Scene("ExchangeTabs", "Control", {"layout_mode": 3, "anchors_preset": 0, "offset_right": 285.0, "offset_bottom": 34.0, "mouse_filter": 2})
    grp = s.sub("tabs", "ButtonGroup", {})
    s.node("Tabs", "HBoxContainer", {"layout_mode": 0, "offset_left": 14.0, "offset_top": 12.0, "offset_right": 271.0, "offset_bottom": 30.0, "theme_override_constants/separation": 4})
    for name, text in [("MerchantsTab", "Merchants"), ("AuctionTab", "Auction House"), ("HallTab", "Tavern")]:
        button(s, "Tabs/" + name, text, "ToggleButton", {"size_flags_horizontal": 3, "toggle_mode": True, "button_group": grp})
    s.save(P + "exchange_tabs.tscn")


def chat_line():
    s = Scene("ChatLine", "RichTextLabel", {"layout_mode": 2, "size_flags_horizontal": 3, "mouse_filter": 1,
        "bbcode_enabled": True, "fit_content": True, "scroll_active": False, "autowrap_mode": 3,
        "meta_underlined": False, "text": "[color=#7a584a]12:00[/color]  Trader: WTS [Timber]x40 6g each"})
    s.save(R + "chat_line.tscn")


def link_card():
    """Floating item card shown when hovering an item link in the trade chat."""
    s = Scene("LinkCard", "PanelContainer", {"visible": False, "custom_minimum_size": (176, 0), "mouse_filter": 2})
    s.node("Margin", "MarginContainer", {"mouse_filter": 2, "theme_override_constants/margin_left": 2, "theme_override_constants/margin_top": 2,
        "theme_override_constants/margin_right": 2, "theme_override_constants/margin_bottom": 2})
    s.node("Margin/Body", "VBoxContainer", {"mouse_filter": 2, "theme_override_constants/separation": 3})
    s.node("Margin/Body/Head", "HBoxContainer", {"mouse_filter": 2, "theme_override_constants/separation": 6})
    s.node("Margin/Body/Head/Slot", "PanelContainer", {"custom_minimum_size": (28, 28), "mouse_filter": 2, "theme_type_variation": Raw('&"SlotPanel"')})
    s.node("Margin/Body/Head/Slot/Icon", "TextureRect", {"mouse_filter": 2, "stretch_mode": 3})
    s.node("Margin/Body/Head/Id", "VBoxContainer", {"size_flags_horizontal": 3, "size_flags_vertical": 4, "mouse_filter": 2, "theme_override_constants/separation": -3})
    label(s, "Margin/Body/Head/Id/Name", "Item", "LabelTitle")
    label(s, "Margin/Body/Head/Id/Rarity", "Common", "LabelCaption")
    label(s, "Margin/Body/Desc", "", "LabelMuted", {"autowrap_mode": 3, "custom_minimum_size": (172, 0)})
    s.node("Margin/Body/Rows", "GridContainer", {"mouse_filter": 2, "columns": 2, "theme_override_constants/h_separation": 8, "theme_override_constants/v_separation": 0})
    for name, caption in [("Fair", "Fair value"), ("MerchantBuys", "Merchants pay"), ("MerchantSells", "Merchants sell"), ("HallAsk", "Lowest ask in chat"), ("HallBid", "Highest bid in chat"), ("Owned", "In your warehouse")]:
        label(s, "Margin/Body/Rows/%sCaption" % name, caption, "LabelCaption", {"size_flags_horizontal": 3})
        label(s, "Margin/Body/Rows/%s" % name, "-", None, {"horizontal_alignment": 2})
    label(s, "Margin/Body/Hint", "Shift+click to link it in a message.", "LabelMuted", {"horizontal_alignment": 1})
    s.save("scenes/journal/widgets/link_card.tscn")


def lookup_card():
    """Item lookup: click any item icon to see what it is, where it comes from and what it's for."""
    s = Scene("ItemLookup", "Control", {"visible": False, "layout_mode": 3, "anchors_preset": 15, "anchor_right": 1.0, "anchor_bottom": 1.0,
        "grow_horizontal": 2, "grow_vertical": 2})
    # Clicking anywhere outside the card closes it.
    s.node("Dim", "ColorRect", {"layout_mode": 1, "anchors_preset": 15, "anchor_right": 1.0, "anchor_bottom": 1.0, "grow_horizontal": 2, "grow_vertical": 2,
        "color": Raw("Color(0.08, 0.05, 0.04, 0.45)")})
    s.node("Card", "PanelContainer", {"layout_mode": 1, "anchors_preset": 8, "anchor_left": 0.5, "anchor_top": 0.5, "anchor_right": 0.5, "anchor_bottom": 0.5,
        "offset_left": -120.0, "offset_top": -120.0, "offset_right": 120.0, "offset_bottom": 120.0, "grow_horizontal": 2, "grow_vertical": 2,
        "theme_type_variation": Raw('&"InsetPanel"')})
    B = "Card/Margin/Body"
    s.node("Card/Margin", "MarginContainer", {"theme_override_constants/margin_left": 8, "theme_override_constants/margin_top": 6,
        "theme_override_constants/margin_right": 8, "theme_override_constants/margin_bottom": 6})
    s.node(B, "VBoxContainer", {"theme_override_constants/separation": 4})
    s.node(B + "/Head", "HBoxContainer", {"theme_override_constants/separation": 6})
    s.inst(B + "/Head/Slot", SLOT, {"custom_minimum_size": (30, 30)})
    s.node(B + "/Head/Id", "VBoxContainer", {"size_flags_horizontal": 3, "size_flags_vertical": 4, "theme_override_constants/separation": -3})
    label(s, B + "/Head/Id/Name", "Item", "LabelTitle", {"text_overrun_behavior": 3})
    label(s, B + "/Head/Id/Kind", "", "LabelCaption", {"text_overrun_behavior": 3})
    button(s, B + "/Head/Close", "x", "TextButton", {"size_flags_vertical": 0, "tooltip_text": "Close (Esc)"})
    label(s, B + "/Desc", "", "LabelMuted", {"autowrap_mode": 3, "custom_minimum_size": (224, 0)})
    s.node(B + "/Rows", "GridContainer", {"columns": 2, "theme_override_constants/h_separation": 8, "theme_override_constants/v_separation": 0})
    for name, caption in [("Held", "You hold"), ("Pays", "Merchants pay"), ("Sells", "Merchants sell")]:
        label(s, B + "/Rows/%sCaption" % name, caption, "LabelCaption", {"size_flags_horizontal": 3})
        label(s, B + "/Rows/%s" % name, "-", None, {"horizontal_alignment": 2})
    label(s, B + "/FromCaption", "Where it comes from", "LabelCaption")
    label(s, B + "/From", "", None, {"autowrap_mode": 3, "custom_minimum_size": (224, 0)})
    label(s, B + "/UsesCaption", "What it's used for", "LabelCaption")
    label(s, B + "/Uses", "", None, {"autowrap_mode": 3, "custom_minimum_size": (224, 0)})
    s.node(B + "/Actions", "HBoxContainer", {"theme_override_constants/separation": 4, "alignment": 1})
    button(s, B + "/Actions/Trade", "Trade it  >", "PaperButton")
    button(s, B + "/Actions/Craft", "Recipes  >", "PaperButton")
    s.save("scenes/journal/widgets/item_lookup.tscn")


def trade_hall():
    s = page("HallLeft", top=36)
    header(s, C + "/Header", "Trade Chat")
    s.node(C + "/Summary", "HBoxContainer")
    label(s, C + "/Summary/Online", "14 traders online", "LabelCaption", {"size_flags_horizontal": 3})
    label(s, C + "/Summary/Fees", "Trade tax 3%", "LabelCaption", {"tooltip_text": "A 3% tax comes off gold you receive in a trade.", "mouse_filter": 1})
    side = s.sub("side", "ButtonGroup", {})
    s.node(C + "/Filter", "HBoxContainer", {"theme_override_constants/separation": 3})
    for name, text, tip in [("All", "All", "Show buying and selling."), ("Selling", "WTS", "Show only people selling."), ("Buying", "WTB", "Show only people buying.")]:
        button(s, C + "/Filter/" + name, text, "ToggleButton", {"toggle_mode": True, "button_group": side, "custom_minimum_size": (30, 18), "tooltip_text": tip})
    s.node(C + "/Filter/Find", "LineEdit", {"custom_minimum_size": (0, 18), "size_flags_horizontal": 3, "placeholder_text": "Filter by item...",
        "clear_button_enabled": True, "context_menu_enabled": False, "max_length": 40,
        "tooltip_text": "Type an item's name and pick it to see only messages about it. Add several to see any of them."})
    s.node(C + "/Suggest", "HFlowContainer", {"visible": False, "theme_override_constants/h_separation": 3, "theme_override_constants/v_separation": 2})
    s.node(C + "/Chips", "HFlowContainer", {"visible": False, "theme_override_constants/h_separation": 3, "theme_override_constants/v_separation": 2})
    s.node(C + "/Chat", "PanelContainer", {"size_flags_vertical": 3, "theme_type_variation": Raw('&"InsetPanel"')})
    s.node(C + "/Chat/Scroll", "ScrollContainer", {"custom_minimum_size": (0, 60), "horizontal_scroll_mode": 0})
    s.node(C + "/Chat/Scroll/Lines", "VBoxContainer", {"size_flags_horizontal": 3, "theme_override_constants/separation": 2})
    s.node(C + "/Composer", "VBoxContainer", {"theme_override_constants/separation": 2})
    s.node(C + "/Composer/Preview", "RichTextLabel", {"visible": False, "mouse_filter": 1, "bbcode_enabled": True, "fit_content": True,
        "scroll_active": False, "autowrap_mode": 3, "meta_underlined": False, "text": ""})
    s.node(C + "/Composer/Row", "HBoxContainer", {"theme_override_constants/separation": 3})
    s.node(C + "/Composer/Row/Input", "LineEdit", {"custom_minimum_size": (0, 20), "size_flags_horizontal": 3,
        "placeholder_text": "Say something in trade chat...", "max_length": 120, "context_menu_enabled": False, "caret_blink": True})
    button(s, C + "/Composer/Row/Send", "Send", None, {"custom_minimum_size": (44, 20)})
    label(s, C + "/Footer", "Shift+click items to link them. Right-click a name to message.", "LabelMuted", {"horizontal_alignment": 1, "autowrap_mode": 3})
    s.save(P + "hall_left.tscn")

    s = page("HallRight")
    header(s, C + "/Header", "Inventory")
    label(s, C + "/Caption", "Shift+click to link an item in chat. During a trade, click to put it in.", "LabelCaption", {"autowrap_mode": 3})
    s.node(C + "/Find", "LineEdit", {"custom_minimum_size": (0, 20), "placeholder_text": "Link anything: type an item's name...",
        "clear_button_enabled": True, "context_menu_enabled": False, "max_length": 40,
        "tooltip_text": "Find any item or good, even one you don't own, and click it to link it in chat. Handy for WTB."})
    label(s, C + "/FoundCaption", "Matches  ·  click one to link it", "LabelCaption", {"visible": False})
    s.node(C + "/FoundScroll", "ScrollContainer", {"visible": False, "custom_minimum_size": (0, 62), "horizontal_scroll_mode": 0})
    s.node(C + "/FoundScroll/Found", "GridContainer", {"size_flags_horizontal": 3, "columns": 8, "theme_override_constants/h_separation": 3, "theme_override_constants/v_separation": 3})
    label(s, C + "/FoundNone", "Nothing by that name.", "LabelMuted", {"visible": False})
    header(s, C + "/GoodsHeader", "Warehouse")
    s.node(C + "/GoodsScroll", "ScrollContainer", {"custom_minimum_size": (0, 64), "horizontal_scroll_mode": 0})
    s.node(C + "/GoodsScroll/Goods", "GridContainer", {"size_flags_horizontal": 3, "columns": 8, "theme_override_constants/h_separation": 3, "theme_override_constants/v_separation": 3})
    label(s, C + "/GoodsEmpty", "The warehouse is empty. Goods your crews bring home show here.", "LabelMuted", {"autowrap_mode": 3})
    header(s, C + "/GearHeader", "Spare gear")
    s.node(C + "/GearScroll", "ScrollContainer", {"custom_minimum_size": (0, 31), "horizontal_scroll_mode": 0})
    s.node(C + "/GearScroll/Gear", "GridContainer", {"size_flags_horizontal": 3, "columns": 8, "theme_override_constants/h_separation": 3, "theme_override_constants/v_separation": 3})
    label(s, C + "/GearEmpty", "No spare gear. Spare gear in the Warehouse shows here.", "LabelMuted", {"autowrap_mode": 3})
    header(s, C + "/MessagesHeader", "Messages")
    scroll(s, C + "/Messages", 40)
    label(s, C + "/MessagesEmpty", "No conversations yet. Right-click a name in the chat to message a trader.", "LabelMuted", {"horizontal_alignment": 1, "autowrap_mode": 3})
    s.node(C + "/Blocked", "HBoxContainer", {"visible": False})
    label(s, C + "/Blocked/Text", "Blocked: 0", "LabelCaption", {"size_flags_horizontal": 3, "size_flags_vertical": 4, "text_overrun_behavior": 3})
    button(s, C + "/Blocked/Unblock", "Unblock all", "PaperButton")
    s.save(P + "hall_right.tscn")


def inventory_slot():
    s = Scene("InventorySlot", "Button", {"custom_minimum_size": (29, 29), "mouse_default_cursor_shape": 2, "theme_type_variation": Raw('&"SlotButton"'), "toggle_mode": True})
    s.node("Icon", "TextureRect", {"layout_mode": 1, "anchors_preset": 8, "anchor_left": 0.5, "anchor_top": 0.5, "anchor_right": 0.5, "anchor_bottom": 0.5,
        "offset_left": -8.0, "offset_top": -8.0, "offset_right": 8.0, "offset_bottom": 8.0, "grow_horizontal": 2, "grow_vertical": 2, "mouse_filter": 2, "stretch_mode": 3})
    label(s, "Count", "", "SlotCount", {"layout_mode": 1, "anchors_preset": 3, "anchor_left": 1.0, "anchor_top": 1.0, "anchor_right": 1.0, "anchor_bottom": 1.0,
        "offset_left": -24.0, "offset_top": -11.0, "offset_right": -2.0, "offset_bottom": 1.0, "grow_horizontal": 0, "grow_vertical": 0, "horizontal_alignment": 2, "mouse_filter": 2})
    s.save(R + "inventory_slot.tscn")


def chat_tab():
    s = Scene("ChatTab", "Button", {"custom_minimum_size": (0, 16), "mouse_default_cursor_shape": 2, "theme_type_variation": Raw('&"ToggleButton"'), "toggle_mode": True, "text": "Name", "text_overrun_behavior": 3})
    s.save(R + "chat_tab.tscn")


def trade_row():
    s = Scene("TradeRow", "HBoxContainer", {"theme_override_constants/separation": 3})
    s.node("Slot", "PanelContainer", {"custom_minimum_size": (20, 20), "theme_type_variation": Raw('&"SlotPanel"')})
    s.node("Slot/Icon", "TextureRect", {"mouse_filter": 2, "stretch_mode": 3, "expand_mode": 1, "custom_minimum_size": (14, 14)})
    label(s, "Name", "Item", None, {"size_flags_horizontal": 3, "size_flags_vertical": 4, "text_overrun_behavior": 3})
    for name, text in [("Less10", "-10"), ("Less1", "-1")]:
        button(s, name, text, "PaperButton", {"custom_minimum_size": (20, 16), "size_flags_vertical": 4})
    label(s, "Qty", "x1", None, {"custom_minimum_size": (24, 0), "horizontal_alignment": 1, "size_flags_vertical": 4})
    for name, text in [("More1", "+1"), ("More10", "+10")]:
        button(s, name, text, "PaperButton", {"custom_minimum_size": (20, 16), "size_flags_vertical": 4})
    button(s, "Remove", "x", "PaperButton", {"custom_minimum_size": (16, 16), "size_flags_vertical": 4, "tooltip_text": "Take it back out."})
    s.save(R + "trade_row.tscn")


def pm_window():
    """Floating private-message window (lives in the journal shell)."""
    s = Scene("PMWindow", "PanelContainer", {"visible": False, "layout_mode": 3, "anchors_preset": 0, "offset_left": 560.0, "offset_top": 262.0, "offset_right": 820.0, "offset_bottom": 486.0, "script": Res("res://scripts/ui/floating_window.gd")})
    s.node("Margin", "MarginContainer", {"theme_override_constants/margin_left": 2, "theme_override_constants/margin_top": 0, "theme_override_constants/margin_right": 2, "theme_override_constants/margin_bottom": 2})
    s.node("Margin/Body", "VBoxContainer", {"theme_override_constants/separation": 3})
    s.node("Margin/Body/TitleBar", "HBoxContainer", {"mouse_filter": 0, "mouse_default_cursor_shape": 13, "theme_override_constants/separation": 4})
    label(s, "Margin/Body/TitleBar/Title", "Messages", "LabelTitle", {"size_flags_horizontal": 3, "mouse_filter": 2})
    label(s, "Margin/Body/TitleBar/Kind", "", "LabelCaption", {"size_flags_vertical": 4, "mouse_filter": 2})
    button(s, "Margin/Body/TitleBar/Trade", "Trade", "PaperButton", {"custom_minimum_size": (34, 16), "size_flags_vertical": 4, "tooltip_text": "Send a trade request. Agree on a price first."})
    button(s, "Margin/Body/TitleBar/Close", "x", "PaperButton", {"custom_minimum_size": (16, 16), "size_flags_vertical": 4, "tooltip_text": "Close. Conversations are kept."})
    s.node("Margin/Body/Tabs", "HBoxContainer", {"theme_override_constants/separation": 2})
    s.node("Margin/Body/Log", "PanelContainer", {"size_flags_vertical": 3, "theme_type_variation": Raw('&"InsetPanel"')})
    s.node("Margin/Body/Log/Scroll", "ScrollContainer", {"custom_minimum_size": (0, 40), "horizontal_scroll_mode": 0})
    s.node("Margin/Body/Log/Scroll/Lines", "VBoxContainer", {"size_flags_horizontal": 3, "theme_override_constants/separation": 2})
    label(s, "Margin/Body/Status", "", "LabelMuted", {"autowrap_mode": 3})
    s.node("Margin/Body/Preview", "RichTextLabel", {"visible": False, "mouse_filter": 1, "bbcode_enabled": True, "fit_content": True,
        "scroll_active": False, "autowrap_mode": 3, "meta_underlined": False, "text": ""})
    s.node("Margin/Body/Row", "HBoxContainer", {"theme_override_constants/separation": 3})
    s.node("Margin/Body/Row/Input", "LineEdit", {"custom_minimum_size": (0, 20), "size_flags_horizontal": 3,
        "placeholder_text": "Message...", "max_length": 160, "context_menu_enabled": False, "caret_blink": True})
    button(s, "Margin/Body/Row/Send", "Send", None, {"custom_minimum_size": (40, 20)})
    s.save("scenes/journal/widgets/pm_window.tscn")


def trade_window():
    """Floating trade window (lives in the journal shell)."""
    s = Scene("TradeWindow", "PanelContainer", {"visible": False, "layout_mode": 3, "anchors_preset": 0, "offset_left": 196.0, "offset_top": 118.0, "offset_right": 486.0, "offset_bottom": 398.0, "script": Res("res://scripts/ui/floating_window.gd")})
    s.node("Margin", "MarginContainer", {"theme_override_constants/margin_left": 2, "theme_override_constants/margin_top": 0, "theme_override_constants/margin_right": 2, "theme_override_constants/margin_bottom": 2})
    s.node("Margin/Body", "VBoxContainer", {"theme_override_constants/separation": 4})
    s.node("Margin/Body/TitleBar", "HBoxContainer", {"mouse_filter": 0, "mouse_default_cursor_shape": 13})
    label(s, "Margin/Body/TitleBar/Title", "Trade", "LabelTitle", {"size_flags_horizontal": 3, "mouse_filter": 2})
    label(s, "Margin/Body/Deal", "", "LabelCaption", {"autowrap_mode": 3})
    for side, title in [("Mine", "You give"), ("Theirs", "They give")]:
        base = "Margin/Body/%s" % side
        s.node(base, "PanelContainer", {"size_flags_vertical": 3, "theme_type_variation": Raw('&"InsetPanel"')})
        s.node(base + "/Body", "VBoxContainer", {"theme_override_constants/separation": 2})
        s.node(base + "/Body/Head", "HBoxContainer")
        label(s, base + "/Body/Head/Title", title, "LabelAccent", {"size_flags_horizontal": 3})
        label(s, base + "/Body/Head/Ready", "Not locked", "LabelMuted")
        s.node(base + "/Body/Items", "VBoxContainer", {"theme_override_constants/separation": 2})
        label(s, base + "/Body/Empty", "Nothing yet.", "LabelMuted")
        s.node(base + "/Body/Gold", "HBoxContainer", {"theme_override_constants/separation": 3})
        s.node(base + "/Body/Gold/Coin", "TextureRect", {"texture": Res("res://assets/ui/icons/gold.png"), "custom_minimum_size": (14, 14), "expand_mode": 1, "stretch_mode": 5, "size_flags_vertical": 4})
        label(s, base + "/Body/Gold/Caption", "Gold", "LabelCaption", {"size_flags_vertical": 4})
        if side == "Mine":
            for name, text in [("Less", "-10")]:
                button(s, base + "/Body/Gold/" + name, text, "PaperButton", {"custom_minimum_size": (22, 16), "size_flags_vertical": 4})
            s.node(base + "/Body/Gold/Amount", "LineEdit", {"custom_minimum_size": (56, 18), "size_flags_horizontal": 3, "text": "0", "placeholder_text": "0", "max_length": 7, "context_menu_enabled": False, "alignment": 2})
            for name, text in [("More", "+10")]:
                button(s, base + "/Body/Gold/" + name, text, "PaperButton", {"custom_minimum_size": (22, 16), "size_flags_vertical": 4})
        else:
            label(s, base + "/Body/Gold/Amount", "0", None, {"size_flags_horizontal": 3, "horizontal_alignment": 2})
    label(s, "Margin/Body/Hint", "Click goods or gear in your inventory to put them in. Lock your side, then both accept. Any change unlocks both.", "LabelMuted", {"autowrap_mode": 3})
    s.node("Margin/Body/Actions", "HBoxContainer", {"theme_override_constants/separation": 4})
    button(s, "Margin/Body/Actions/Lock", "Lock offer", "PaperButton", {"custom_minimum_size": (0, 22), "size_flags_horizontal": 3,
        "tooltip_text": "Lock your side so it can't change. Unlocking clears both locks."})
    button(s, "Margin/Body/Actions/Accept", "Accept", None, {"custom_minimum_size": (0, 22), "size_flags_horizontal": 3,
        "tooltip_text": "Opens once both sides are locked. The trade goes through when both accept."})
    button(s, "Margin/Body/Actions/Cancel", "Cancel", "PaperButton", {"custom_minimum_size": (0, 22)})
    s.save("scenes/journal/widgets/trade_window.tscn")


# --- Company chapter: the living map --------------------------------------------------
def company_today():
    """The Company home's right page: crews in the field, then only what needs the player."""
    s = page("CompanyRight")
    header(s, C + "/Header", "Today")
    label(s, C + "/FieldCaption", "Out", "LabelCaption")
    s.node(C + "/Expeditions", "VBoxContainer", {"theme_override_constants/separation": 4})
    label(s, C + "/NeedsCaption", "Needs you", "LabelCaption")
    s.node(C + "/Needs", "VBoxContainer", {"theme_override_constants/separation": 4})
    label(s, C + "/AllClear", "Nothing needs you. Crews come home on their own, even while the game is closed.", "LabelMuted",
          {"visible": False, "autowrap_mode": 3})
    spacer(s, C + "/Spacer")
    s.node(C + "/Tiles", "HBoxContainer", {"theme_override_constants/separation": 4})
    tile(s, C + "/Tiles/Reputation", "Reputation", "Unknown", extra={"tooltip_text": "Earned by bringing goods up. Better applicants join a better-known guild."})
    tile(s, C + "/Tiles/Warehouse", "Warehouse", "Empty", extra={"tooltip_text": "Goods waiting to be sold or crafted. The Exchange sells them."})
    s.save(P + "company_right.tscn")


def need_row():
    """One thing on the Company page that needs the player, with the button that deals with it."""
    s = Scene("NeedRow", "PanelContainer", {"theme_type_variation": Raw('&"InsetPanel"')})
    s.node("Row", "HBoxContainer", {"theme_override_constants/separation": 6})
    s.node("Row/IconSlot", "PanelContainer", {"custom_minimum_size": (24, 24), "size_flags_vertical": 4, "theme_type_variation": Raw('&"SlotPanel"')})
    s.node("Row/IconSlot/Icon", "TextureRect", {"custom_minimum_size": (16, 16), "mouse_filter": 2, "expand_mode": 1, "stretch_mode": 5})
    s.node("Row/Info", "VBoxContainer", {"size_flags_horizontal": 3, "size_flags_vertical": 4, "theme_override_constants/separation": -4})
    label(s, "Row/Info/Name", "Something", None, {"text_overrun_behavior": 3})
    label(s, "Row/Info/Details", "Details", "LabelCaption", {"text_overrun_behavior": 3})
    label(s, "Row/Value", "", "LabelGood", {"visible": False, "size_flags_vertical": 4})
    button(s, "Row/Action", "Open", "PaperButton", {"size_flags_vertical": 4})
    s.save(R + "need_row.tscn")

def map_crew():
    s = Scene("MapCrew", "TextureRect", {"offset_right": 9.0, "offset_bottom": 11.0, "mouse_filter": 1,
        "texture": Res("res://assets/ui/art/crew/walk_0.png"), "stretch_mode": 0})
    # Sparkles over whoever carries something found among the fallen.
    s.node("Glint", "TextureRect", {"visible": False, "layout_mode": 0, "offset_left": 5.0, "offset_top": -5.0, "offset_right": 10.0,
        "offset_bottom": 0.0, "mouse_filter": 2, "texture": Res("res://assets/ui/art/crew/glint_0.png")})
    s.save(R + "map_crew.tscn")


def fallen_row():
    s = Scene("FallenRow", "HBoxContainer", {"mouse_filter": 2, "theme_override_constants/separation": 5})
    s.node("Slot", "PanelContainer", {"custom_minimum_size": (20, 20), "mouse_filter": 2, "theme_type_variation": Raw('&"SlotPanel"')})
    s.node("Slot/Icon", "TextureRect", {"mouse_filter": 2, "stretch_mode": 3})
    s.node("Info", "VBoxContainer", {"size_flags_horizontal": 3, "size_flags_vertical": 4, "mouse_filter": 2, "theme_override_constants/separation": -4})
    label(s, "Info/Name", "Item", None, {"text_overrun_behavior": 3})
    label(s, "Info/From", "", "LabelCaption", {"text_overrun_behavior": 3})
    s.node("Side", "VBoxContainer", {"size_flags_vertical": 4, "mouse_filter": 2, "theme_override_constants/separation": -4})
    label(s, "Side/Value", "0 G", None, {"horizontal_alignment": 2})
    label(s, "Side/Left", "", "LabelCaption", {"horizontal_alignment": 2})
    s.save(R + "fallen_row.tscn")


def fallen_card():
    """Shown when hovering a site's grave marker on the map: this company's share of the pool."""
    s = Scene("FallenCard", "PanelContainer", {"visible": False, "custom_minimum_size": (168, 0), "mouse_filter": 2})
    s.node("Margin", "MarginContainer", {"mouse_filter": 2, "theme_override_constants/margin_left": 2, "theme_override_constants/margin_top": 2,
        "theme_override_constants/margin_right": 2, "theme_override_constants/margin_bottom": 2})
    s.node("Margin/Body", "VBoxContainer", {"mouse_filter": 2, "theme_override_constants/separation": 3})
    label(s, "Margin/Body/Title", "Left below", "LabelTitle")
    label(s, "Margin/Body/Summary", "", "LabelCaption", {"autowrap_mode": 3, "custom_minimum_size": (164, 0)})
    s.node("Margin/Body/Rows", "VBoxContainer", {"mouse_filter": 2, "theme_override_constants/separation": 2})
    label(s, "Margin/Body/Empty", "Nothing within your reach today.", "LabelMuted", {"visible": False, "horizontal_alignment": 1})
    label(s, "Margin/Body/Hint", "", "LabelMuted", {"autowrap_mode": 3, "custom_minimum_size": (164, 0)})
    s.save("scenes/journal/widgets/fallen_card.tscn")


## How wide each place's name is in the body font (px), for sizing its spot on the map.
MAP_NAME_W = {
    "Cinderwood": 41, "Weepingwood": 48, "Gatepit": 25, "Sulphur Deeps": 50, "Ashmeadow": 41, "Bloodfen": 31,
    "Ember Slopes": 47, "Lament's Edge": 50, "Cinder Pool": 39, "Styx Shallows": 48, "Lake of Glass": 46,
    "Shore of Tears": 53, "Drowned Deep": 50, "Hollow Fields": 43, "Houndfang Hills": 52, "Gorehorn Moor": 53,
    "Bleakridge": 36, "Home Fields": 40, "Tilled Acres": 39, "Beehives": 31, "Glasshouse": 39, "Fallen Keep": 39,
    "Last Lantern": 43,
}
MAP_NAMES = {
    "mossward_copse": "Cinderwood", "old_oakwood": "Weepingwood", "harlow": "Gatepit", "deepdelve": "Sulphur Deeps",
    "mossward_meadows": "Ashmeadow", "fenmire": "Bloodfen", "sunreach": "Ember Slopes", "frostvale": "Lament's Edge",
    "millbrook_pond": "Cinder Pool", "silverrun": "Styx Shallows", "glasswater": "Lake of Glass",
    "greywater_coast": "Shore of Tears", "drowned_deep": "Drowned Deep", "hollow_fields": "Hollow Fields",
    "greyfang_hills": "Houndfang Hills", "elkmoor": "Gorehorn Moor", "bleakridge": "Bleakridge",
    "home_fields": "Home Fields", "tilled_acres": "Tilled Acres", "beehives": "Beehives", "glasshouse": "Glasshouse",
    "calder_keep": "Fallen Keep",
}


def company_map():
    """The Descent: a painted cutaway (tools/paint_descent_map.py), with a clickable spot for every
    site and crypt, layer badges, grave markers and the roads crews walk, all placed from
    tools/map_roads.json so the art and the scene stay in step."""
    import json
    data = json.load(open("tools/map_roads.json"))
    mw, mh = data["_size"]
    s = page("CompanyMapLeft")
    for i, (name, type_, parent, props, inst) in enumerate(s.nodes):
        if name == "Content" and parent == "Margin":
            props["theme_override_constants/separation"] = 3
    header(s, C + "/Header", "The Descent")
    M = C + "/Map"
    s.node(M, "Control", {"custom_minimum_size": (mw, mh), "size_flags_horizontal": 4, "mouse_filter": 2,
        "script": Res("res://scripts/ui/region_map.gd")})
    s.node(M + "/Ground", "TextureRect", {"layout_mode": 0, "offset_right": float(mw), "offset_bottom": float(mh), "mouse_filter": 2,
        "texture": Res("res://assets/ui/art/region_map.png"), "stretch_mode": 0})
    # Roads the crews walk, from town to each site (hidden guides; repaint the map to re-route).
    s.node(M + "/Roads", "Node2D", {"visible": False})
    for site, pts in data.items():
        if site.startswith("_"):
            continue
        flat = ", ".join("%s, %s" % (x, y) for x, y in pts)
        s.node(M + "/Roads/" + site, "Line2D", {"points": Raw("PackedVector2Array(%s)" % flat), "width": 1.0})
    s.node(M + "/Chimneys", "Node2D", {})
    for i, (x, y) in enumerate(data["_chimneys"]):
        s.node(M + "/Chimneys/Chimney%d" % (i + 1), "Marker2D", {"position": (float(x), float(y)), "gizmo_extents": 3.0})
    # Layer badges on the rock wall, with the layer's name and what lives there.
    s.node(M + "/Layers", "Control", {"layout_mode": 1, "anchors_preset": 15, "anchor_right": 1.0, "anchor_bottom": 1.0, "mouse_filter": 2})
    for layer in data["_layers"]:
        x, y = float(max(3, layer["left"] - 13)), float(layer["y0"] + 1)
        label(s, M + "/Layers/Layer%d" % layer["id"], str(layer["id"]), "MapLayer", {"layout_mode": 0,
            "offset_left": x, "offset_top": y, "offset_right": x + 9.0, "offset_bottom": y + 12.0,
            "horizontal_alignment": 1, "mouse_filter": 0, "tooltip_text": layer["tip"]})
    # Every place: a spot over its little scene, its name under it, a veil while it's out of reach.
    S = M + "/Sites"
    s.node(S, "Control", {"layout_mode": 1, "anchors_preset": 15, "anchor_right": 1.0, "anchor_bottom": 1.0, "mouse_filter": 2})
    for site, spot in data["_spots"].items():
        name = MAP_NAMES[site]
        w = max(34, MAP_NAME_W[name] + 4)
        x0, y0 = spot["x"] - w / 2.0, spot["y"] - 10.0
        button(s, S + "/" + site, "", "MapSpot", {"layout_mode": 0, "offset_left": x0, "offset_top": y0,
            "offset_right": x0 + w, "offset_bottom": y0 + 30.0})
        s.node(S + "/" + site + "/Veil", "TextureRect", {"visible": False, "layout_mode": 0, "offset_left": w / 2.0 - 20.0, "offset_top": -1.0,
            "offset_right": w / 2.0 + 20.0, "offset_bottom": 21.0, "mouse_filter": 2, "texture": Res("res://assets/ui/kit/map_veil.png"),
            "stretch_mode": 0})
        label(s, S + "/" + site + "/Name", name, "MapName", {"layout_mode": 0, "offset_left": 0.0, "offset_top": 17.0,
            "offset_right": w, "offset_bottom": 29.0, "horizontal_alignment": 1, "mouse_filter": 2})
    # The town: rest, and the warehouse.
    button(s, S + "/town", "", "MapSpot", {"layout_mode": 0, "offset_left": 90.0, "offset_top": 2.0, "offset_right": 168.0, "offset_bottom": 46.0})
    label(s, S + "/town/Name", "Last Lantern", "MapName", {"layout_mode": 0, "offset_left": -16.0, "offset_top": 10.0,
        "offset_right": 30.0, "offset_bottom": 22.0, "horizontal_alignment": 1, "mouse_filter": 2})
    # Crypts not open yet: painted in, named on hover.
    s.node(M + "/Planned", "Control", {"layout_mode": 1, "anchors_preset": 15, "anchor_right": 1.0, "anchor_bottom": 1.0, "mouse_filter": 2})
    for crypt, x, y, w, h, tip in [("sunken_abbey", 112, 120, 32, 24, "The Drowned Abbey\nA crypt not open yet. Rival crews have been seen going in."),
                                   ("wyrms_hollow", 144, 274, 32, 30, "The Throne Below\nThe bottom of everything. Not open yet.")]:
        s.node(M + "/Planned/" + crypt, "Control", {"layout_mode": 0, "offset_left": float(x), "offset_top": float(y),
            "offset_right": float(x + w), "offset_bottom": float(y + h), "tooltip_text": tip})
    # Grave markers: what the dead left below that this guild could find (shown when there is some).
    s.node(M + "/Fallen", "Control", {"layout_mode": 1, "anchors_preset": 15, "anchor_right": 1.0, "anchor_bottom": 1.0, "mouse_filter": 2})
    for site, spot in data["_spots"].items():
        if spot["layer"] == 0:
            continue
        x, y = float(spot["x"] + 9), float(spot["y"] - 12)
        button(s, M + "/Fallen/" + site, "0", "MapButton", {"layout_mode": 0, "offset_left": x, "offset_top": y,
            "offset_right": x + 22.0, "offset_bottom": y + 12.0, "icon": Res("res://assets/ui/art/crew/grave.png")})
    # Crew figures are added here while expeditions run.
    s.node(M + "/Crews", "Control", {"layout_mode": 1, "anchors_preset": 15, "anchor_right": 1.0, "anchor_bottom": 1.0, "mouse_filter": 2})
    s.inst(M + "/FallenCard", "res://scenes/journal/widgets/fallen_card.tscn", {"layout_mode": 0, "offset_right": 172.0, "offset_bottom": 40.0})
    label(s, C + "/Status", "", "LabelCaption", {"horizontal_alignment": 1, "autowrap_mode": 3})
    s.save(P + "company_map.tscn")


if __name__ == "__main__":
    import sys
    if len(sys.argv) > 1:
        # Generate only the named builders, e.g.: python3 tools/build_pages.py trade_hall
        for name in sys.argv[1:]:
            globals()[name]()
        print("generated", ", ".join(sys.argv[1:]))
        raise SystemExit
    item_card()
    portrait_card()
    personnel_tabs()
    personnel_roster()
    personnel_recruit()
    workshop_store()
    list_caption()
    workshop_shop()
    chapter_tabs()
    personnel_workshop()
    gear_slot()
    material_row()
    exchange()
    market_row()
    finances()
    chronicle()
    guildwork()
    board()
    site_card()
    locked_row()
    site_pages()
    dungeon_pages()
    auction_pages()
    print("pages written")
