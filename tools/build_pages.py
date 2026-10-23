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
    s.node("Row/IconSlot/Icon", "TextureRect", {"mouse_filter": 2, "stretch_mode": 3})
    s.node("Row/Info", "VBoxContainer", {"size_flags_horizontal": 3, "size_flags_vertical": 4, "theme_override_constants/separation": -4})
    label(s, "Row/Info/Name", "Item", extra={"text_overrun_behavior": 3})
    label(s, "Row/Info/Details", "Details", "LabelCaption", {"text_overrun_behavior": 3})
    button(s, "Row/Secondary", "Sell", "PaperButton", {"visible": False, "size_flags_vertical": 4})
    button(s, "Row/Primary", "Buy", "PaperButton", {"size_flags_vertical": 4})
    s.save(R + "item_card.tscn")


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
    for name, text in [("EmployeesTab", "Roster"), ("RecruitmentTab", "Recruit"), ("ArmoryTab", "Armory")]:
        button(s, "Tabs/" + name, text, "ToggleButton", {"size_flags_horizontal": 3, "toggle_mode": True, "button_group": grp})
    s.save(P + "personnel_tabs.tscn")


# --- Personnel: roster ----------------------------------------------------------
def personnel_roster():
    s = page("PersonnelRosterLeft", top=36)
    header(s, C + "/Header", "Roster")
    s.node(C + "/Summary", "HBoxContainer")
    label(s, C + "/Summary/Count", "0 hired", "LabelCaption", {"size_flags_horizontal": 3})
    label(s, C + "/Summary/Payroll", "Payroll 0 G", "LabelCaption", {"tooltip_text": "What one expedition with every mercenary would cost in wages.", "mouse_filter": 1})
    s.node(C + "/List", "ScrollContainer", {"custom_minimum_size": (0, 80), "size_flags_vertical": 3, "horizontal_scroll_mode": 0})
    s.node(C + "/List/Items", "GridContainer", {"size_flags_horizontal": 3, "theme_override_constants/h_separation": 5, "theme_override_constants/v_separation": 5, "columns": 2})
    s.inst(C + "/Empty", INFO, {"visible": False, "text": "Nobody is on the payroll yet. Recruit a miner to start working Harlow Mines.", "icon_kind": "plus"})
    button(s, C + "/Recruit", "Recruit mercenaries", None, {"visible": False, "size_flags_horizontal": 4})
    s.save(P + "personnel_employed_left.tscn")

    s = page("PersonnelDossierRight")
    header(s, C + "/Header", "Dossier")
    s.node(C + "/Head", "HBoxContainer", {"theme_override_constants/separation": 8})
    s.node(C + "/Head/Portrait", "PanelContainer", {"custom_minimum_size": (58, 46), "theme_type_variation": Raw('&"SlotPanel"')})
    s.node(C + "/Head/Portrait/Bust", "TextureRect", {"mouse_filter": 2, "stretch_mode": 3})
    s.node(C + "/Head/Id", "VBoxContainer", {"size_flags_horizontal": 3, "size_flags_vertical": 4, "theme_override_constants/separation": -2})
    label(s, C + "/Head/Id/Name", "Name", "LabelTitle", {"text_overrun_behavior": 3})
    label(s, C + "/Head/Id/Title", "Title", "LabelCaption")
    s.node(C + "/Head/Id/Status", "HBoxContainer", {"theme_override_constants/separation": 4})
    s.node(C + "/Head/Id/Status/RoleIcon", "TextureRect", {"custom_minimum_size": (16, 16), "mouse_filter": 2, "stretch_mode": 3})
    label(s, C + "/Head/Id/Status/Role", "Miner")
    label(s, C + "/Head/Id/Status/State", "Ready", "LabelGood")
    s.node(C + "/Stats", "GridContainer", {"theme_override_constants/h_separation": 5, "theme_override_constants/v_separation": 5, "columns": 2})
    tile(s, C + "/Stats/Skill", "Skill", extra={"tooltip_text": "Raises expedition success. Grows with experience."})
    tile(s, C + "/Stats/Experience", "Experience", extra={"tooltip_text": "Earned on expeditions. Adds to effective skill."})
    tile(s, C + "/Stats/Wage", "Wage", extra={"tooltip_text": "Paid up front for each expedition."})
    tile(s, C + "/Stats/Share", "Share of haul", extra={"tooltip_text": "Their cut of the coin an expedition brings back."})
    s.node(C + "/Health", "HBoxContainer", {"theme_override_constants/separation": 6})
    label(s, C + "/Health/Caption", "Health", "LabelCaption")
    s.node(C + "/Health/Bar", "ProgressBar", {"custom_minimum_size": (0, 6), "size_flags_horizontal": 3, "size_flags_vertical": 4, "mouse_filter": 2, "theme_type_variation": Raw('&"GreenBar"'), "value": 100.0, "show_percentage": False})
    label(s, C + "/Health/Value", "100%")
    button(s, C + "/Health/Heal", "Treat", "PaperButton", {"tooltip_text": "Pay a healer to restore full health."})
    header(s, C + "/GearHeader", "Equipment")
    s.node(C + "/Gear", "HBoxContainer", {"theme_override_constants/separation": 6})
    for slot in ["Tool", "Armor"]:
        s.inst(C + "/Gear/%sSlot" % slot, SLOT, {"custom_minimum_size": (30, 30)})
        s.node(C + "/Gear/%sInfo" % slot, "VBoxContainer", {"size_flags_horizontal": 3, "size_flags_vertical": 4, "theme_override_constants/separation": -4})
        label(s, C + "/Gear/%sInfo/Caption" % slot, slot, "LabelCaption")
        label(s, C + "/Gear/%sInfo/Name" % slot, "Empty", None, {"text_overrun_behavior": 3})
    spacer(s, C + "/Spacer")
    s.node(C + "/Contract", "PanelContainer", {"theme_type_variation": Raw('&"InsetPanel"')})
    s.node(C + "/Contract/Body", "VBoxContainer", {"theme_override_constants/separation": 1})
    s.node(C + "/Contract/Body/Top", "HBoxContainer")
    s.node(C + "/Contract/Body/Top/Text", "VBoxContainer", {"size_flags_horizontal": 3, "theme_override_constants/separation": -3})
    label(s, C + "/Contract/Body/Top/Text/Caption", "Contract terms", "LabelCaption")
    label(s, C + "/Contract/Body/Top/Text/Name", "Balanced")
    button(s, C + "/Contract/Body/Top/Change", "Change terms", "PaperButton", {"size_flags_vertical": 4, "tooltip_text": "Cycle between Balanced, Guaranteed Wage and Profit Share."})
    label(s, C + "/Contract/Body/Explain", "", "LabelMuted", {"autowrap_mode": 3})
    s.node(C + "/Actions", "HBoxContainer", {"theme_override_constants/separation": 4, "alignment": 1})
    button(s, C + "/Actions/Armory", "Outfit in Armory  >")
    s.inst(C + "/Empty", INFO, {"visible": False, "text": "Select a mercenary to read their dossier.", "icon_kind": "home"})
    s.save(P + "personnel_employed_right.tscn")


# --- Personnel: recruitment -----------------------------------------------------
def personnel_recruit():
    s = page("PersonnelRecruitLeft", top=36)
    header(s, C + "/Header", "Applicants")
    s.node(C + "/Summary", "HBoxContainer")
    label(s, C + "/Summary/Refresh", "New applicants in 30m", "LabelCaption", {"size_flags_horizontal": 3})
    label(s, C + "/Summary/Count", "0 waiting", "LabelCaption")
    scroll(s, C + "/List", 80)
    s.inst(C + "/Empty", INFO, {"visible": False, "text": "No applicants today. New faces arrive every half hour.", "icon_kind": "home"})
    s.save(P + "personnel_recruits_left.tscn")

    s = page("PersonnelRecruitRight")
    header(s, C + "/Header", "Applicant")
    s.node(C + "/Head", "HBoxContainer", {"theme_override_constants/separation": 8})
    s.node(C + "/Head/Portrait", "PanelContainer", {"custom_minimum_size": (58, 46), "theme_type_variation": Raw('&"SlotPanel"')})
    s.node(C + "/Head/Portrait/Bust", "TextureRect", {"mouse_filter": 2, "stretch_mode": 3})
    s.node(C + "/Head/Id", "VBoxContainer", {"size_flags_horizontal": 3, "size_flags_vertical": 4, "theme_override_constants/separation": -2})
    label(s, C + "/Head/Id/Name", "Name", "LabelTitle", {"text_overrun_behavior": 3})
    label(s, C + "/Head/Id/Title", "Title", "LabelCaption")
    s.node(C + "/Head/Id/Status", "HBoxContainer", {"theme_override_constants/separation": 4})
    s.node(C + "/Head/Id/Status/RoleIcon", "TextureRect", {"custom_minimum_size": (16, 16), "mouse_filter": 2, "stretch_mode": 3})
    label(s, C + "/Head/Id/Status/Role", "Miner")
    s.node(C + "/Stats", "GridContainer", {"theme_override_constants/h_separation": 5, "theme_override_constants/v_separation": 5, "columns": 2})
    tile(s, C + "/Stats/Skill", "Skill")
    tile(s, C + "/Stats/Fee", "Signing fee", icon=ICON + "gold.png", extra={"tooltip_text": "Paid once, when they sign."})
    tile(s, C + "/Stats/Wage", "Wage", extra={"tooltip_text": "Paid up front for each expedition."})
    tile(s, C + "/Stats/Share", "Share of haul")
    s.inst(C + "/RoleNote", INFO, {"text": "Role", "icon_kind": "alert"})
    spacer(s, C + "/Spacer")
    button(s, C + "/Hire", "Hire", None, {"custom_minimum_size": (0, 26)})
    label(s, C + "/Reason", "", "LabelAccent", {"horizontal_alignment": 1, "autowrap_mode": 3})
    label(s, C + "/Footer", "The fallen cannot be rehired.", "LabelMuted", {"horizontal_alignment": 1})
    s.inst(C + "/Empty", INFO, {"visible": False, "text": "Select an applicant to see their terms.", "icon_kind": "home"})
    s.save(P + "personnel_recruits_right.tscn")


# --- Personnel: armory ------------------------------------------------------------
def personnel_armory():
    s = page("PersonnelArmoryLeft", top=36)
    header(s, C + "/Header", "Outfitting")
    label(s, C + "/Caption", "Choose who to equip", "LabelCaption")
    scroll(s, C + "/Crew", 33, expand=False)
    header(s, C + "/LoadoutHeader", "Loadout")
    s.node(C + "/Loadout", "PanelContainer")
    s.node(C + "/Loadout/Body", "VBoxContainer", {"theme_override_constants/separation": 4})
    label(s, C + "/Loadout/Body/Who", "Nobody selected", "LabelTitle")
    for slot in ["Tool", "Armor"]:
        base = C + "/Loadout/Body/%sRow" % slot
        s.node(base, "HBoxContainer", {"theme_override_constants/separation": 6})
        s.inst(base + "/Slot", SLOT, {"custom_minimum_size": (30, 30)})
        s.node(base + "/Info", "VBoxContainer", {"size_flags_horizontal": 3, "size_flags_vertical": 4, "theme_override_constants/separation": -4})
        label(s, base + "/Info/Caption", slot, "LabelCaption")
        label(s, base + "/Info/Name", "Empty", None, {"text_overrun_behavior": 3})
        button(s, base + "/Remove", "Unequip", "PaperButton", {"size_flags_vertical": 4})
    label(s, C + "/Loadout/Body/Bonus", "", "LabelCaption", {"tooltip_text": "Mining adds haul, guard protects the crew, protection lowers each wearer's risk.", "mouse_filter": 1})
    s.inst(C + "/Empty", INFO, {"visible": False, "text": "Hire a mercenary before buying equipment for them.", "icon_kind": "plus"})
    spacer(s, C + "/Spacer")
    s.inst(C + "/Tip", INFO, {"text": "Gear is company property. If its wearer dies in the field, the gear is lost with them.", "icon_kind": "alert"})
    s.save(P + "personnel_armory_left.tscn")

    s = page("PersonnelArmoryRight")
    header(s, C + "/StoreHeader", "Storeroom")
    label(s, C + "/StoreCaption", "Owned gear not being worn", "LabelCaption")
    scroll(s, C + "/Store", 96, expand=False)
    label(s, C + "/StoreEmpty", "Nothing in storage.", "LabelMuted")
    header(s, C + "/ShopHeader", "Quartermaster")
    scroll(s, C + "/Shop", 80)
    s.save(P + "personnel_armory_right.tscn")


# --- Exchange ------------------------------------------------------------------
def exchange():
    s = page("ExchangeLeft")
    header(s, C + "/Header", "Goods")
    s.node(C + "/Summary", "HBoxContainer")
    label(s, C + "/Summary/Shift", "Prices shift in 6h", "LabelCaption", {"size_flags_horizontal": 3, "tooltip_text": "Merchants reprice every six hours. Arrows compare today's price with the usual one.", "mouse_filter": 1})
    label(s, C + "/Summary/Hint", "Merchant pays", "LabelCaption")
    scroll(s, C + "/List", 80)
    s.save(P + "exchange_left.tscn")

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
    s.inst(C + "/Note", INFO, {"text": "Sales go straight to the treasury. Rare goods are worth holding when prices dip.", "icon_kind": "coin"})
    s.save(P + "exchange_right.tscn")


# --- Finances ------------------------------------------------------------------
def finances():
    s = page("FinanceLeft")
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
    label(s, C + "/Ledger/Rows/Total/Name", "Company worth", "LabelTitle", {"size_flags_horizontal": 3})
    label(s, C + "/Ledger/Rows/Total/Value", "0 G", "LabelBig")
    header(s, C + "/OpsHeader", "Operations")
    s.node(C + "/Slots", "HBoxContainer", {"theme_override_constants/separation": 6})
    s.node(C + "/Slots/Text", "VBoxContainer", {"size_flags_horizontal": 3, "size_flags_vertical": 4, "theme_override_constants/separation": 0})
    label(s, C + "/Slots/Text/Caption", "Expedition slots", "LabelCaption")
    s.inst(C + "/Slots/Text/Pips", PIPS, {"value": 1, "max_value": 3, "gold": True})
    button(s, C + "/Slots/Expand", "Expand", "PaperButton", {"size_flags_vertical": 4, "tooltip_text": "Run more expeditions at the same time."})
    s.node(C + "/Costs", "HBoxContainer", {"theme_override_constants/separation": 5})
    tile(s, C + "/Costs/Payroll", "Payroll", extra={"tooltip_text": "Wages for one expedition with every mercenary on the roster."})
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
    tile(s, C + "/Totals/Earned", "Recovered")
    tile(s, C + "/Totals/Spent", "Spent")
    tile(s, C + "/Totals/Net", "Net")
    header(s, C + "/StoreHeader", "Warehouse Value")
    scroll(s, C + "/Stores", 60)
    label(s, C + "/StoresEmpty", "Nothing stored in the warehouse.", "LabelMuted")
    s.save(P + "finance_right.tscn")


# --- Chronicle -------------------------------------------------------------------
def chronicle():
    s = page("ChronicleLeft")
    header(s, C + "/Header", "Reports")
    label(s, C + "/Summary", "", "LabelCaption")
    scroll(s, C + "/List", 80)
    s.inst(C + "/Empty", INFO, {"visible": False, "text": "No expedition has returned yet. Every report is kept here.", "icon_kind": "home"})
    button(s, C + "/GoHarlow", "Plan an expedition", None, {"visible": False, "size_flags_horizontal": 4})
    s.save(P + "chronicle_left.tscn")

    s = page("ChronicleRight")
    header(s, C + "/Header", "Report")
    s.node(C + "/Head", "HBoxContainer", {"theme_override_constants/separation": 6})
    s.node(C + "/Head/Seal", "TextureRect", {"custom_minimum_size": (24, 24), "size_flags_vertical": 4, "mouse_filter": 2, "stretch_mode": 3})
    s.node(C + "/Head/Id", "VBoxContainer", {"size_flags_horizontal": 3, "size_flags_vertical": 4, "theme_override_constants/separation": -2})
    label(s, C + "/Head/Id/Place", "Place", "LabelTitle")
    label(s, C + "/Head/Id/Outcome", "Outcome", "LabelAccent")
    s.node(C + "/Money", "HBoxContainer", {"theme_override_constants/separation": 4})
    tile(s, C + "/Money/Recovered", "Recovered", extra={"tooltip_text": "Coin brought back after the crew's share."})
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
def regions():
    s = page("RegionsLeft")
    header(s, C + "/Header", "Contracts")
    label(s, C + "/Summary", "Choose a destination for your crew.", "LabelCaption")
    scroll(s, C + "/List", 80)
    s.save(P + "regions_left.tscn")

    s = page("RegionsRight")
    header(s, C + "/Header", "Contract")
    label(s, C + "/Name", "Region", "LabelTitle")
    label(s, C + "/Tagline", "", "LabelCaption", {"autowrap_mode": 3})
    s.node(C + "/Stats", "GridContainer", {"theme_override_constants/h_separation": 5, "theme_override_constants/v_separation": 5, "columns": 2})
    tile(s, C + "/Stats/Threat", "Threat", extra={"tooltip_text": "Higher threat means a stronger crew is needed."})
    tile(s, C + "/Stats/Duration", "Duration")
    tile(s, C + "/Stats/Supplies", "Supplies", icon=ICON + "gold.png", extra={"tooltip_text": "Paid up front, on top of wages."})
    tile(s, C + "/Stats/Reputation", "Reputation needed", icon=ICON + "crystal.png")
    label(s, C + "/LootCaption", "Possible finds", "LabelCaption")
    s.node(C + "/Loot", "HBoxContainer", {"theme_override_constants/separation": 4})
    label(s, C + "/Finds", "", "LabelCaption", {"autowrap_mode": 3})
    label(s, C + "/Focus", "", "LabelMuted", {"autowrap_mode": 3})
    spacer(s, C + "/Spacer")
    label(s, C + "/Team", "", "LabelCaption", {"autowrap_mode": 3, "horizontal_alignment": 1})
    button(s, C + "/Dispatch", "Dispatch crew", None, {"custom_minimum_size": (0, 26)})
    label(s, C + "/Reason", "", "LabelAccent", {"horizontal_alignment": 1, "autowrap_mode": 3})
    button(s, C + "/GoHarlow", "Open Harlow Mines  >", "PaperButton", {"visible": False, "size_flags_horizontal": 4})
    s.save(P + "regions_right.tscn")


# --- Guild work -------------------------------------------------------------------
def guildwork():
    s = page("GuildWorkLeft")
    header(s, C + "/Header", "Guild Work")
    s.inst(C + "/About", INFO, {"text": "Safe, small jobs from the guild for companies that have fallen on hard times. No risk, no equipment, modest pay.", "icon_kind": "home"})
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
    button(s, C + "/ReturnHarlow", "Back to Harlow Mines  >", "TextButton", {"size_flags_horizontal": 8})
    s.save(P + "guildwork_left.tscn")

    s = page("GuildWorkRight")
    header(s, C + "/Header", "Contract Labor")
    label(s, C + "/Caption", "2m 30s  ·  18 G each  ·  no injury or gear risk", "LabelCaption")
    scroll(s, C + "/List", 80)
    s.inst(C + "/Empty", INFO, {"visible": False, "text": "No mercenaries are free for labor right now.", "icon_kind": "home"})
    s.save(P + "guildwork_right.tscn")


if __name__ == "__main__":
    item_card()
    portrait_card()
    personnel_tabs()
    personnel_roster()
    personnel_recruit()
    personnel_armory()
    exchange()
    finances()
    chronicle()
    regions()
    guildwork()
    print("pages written")
