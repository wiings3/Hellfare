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
    tile(s, C + "/Stats/Experience", "Main trade", extra={"tooltip_text": "Level in the trade this mercenary was hired for."})
    tile(s, C + "/Stats/Wage", "Wage", extra={"tooltip_text": "Paid up front for each expedition."})
    tile(s, C + "/Stats/Share", "Share of haul", extra={"tooltip_text": "Their cut of the coin an expedition brings back."})
    s.node(C + "/Health", "HBoxContainer", {"theme_override_constants/separation": 6})
    label(s, C + "/Health/Caption", "Health", "LabelCaption")
    s.node(C + "/Health/Bar", "ProgressBar", {"custom_minimum_size": (0, 6), "size_flags_horizontal": 3, "size_flags_vertical": 4, "mouse_filter": 2, "theme_type_variation": Raw('&"GreenBar"'), "value": 100.0, "show_percentage": False})
    label(s, C + "/Health/Value", "100%")
    button(s, C + "/Health/Heal", "Treat", "PaperButton", {"tooltip_text": "Pay a healer to restore full health."})
    s.node(C + "/Skills", "HBoxContainer", {"theme_override_constants/separation": 8, "tooltip_text": "Trade levels rise with experience. Higher levels haul more and unlock better sites.", "mouse_filter": 1})
    for trade in ["Logging", "Mining", "Combat"]:
        base = C + "/Skills/" + trade
        s.node(base, "VBoxContainer", {"size_flags_horizontal": 3, "theme_override_constants/separation": 0, "mouse_filter": 2})
        label(s, base + "/Level", trade + " 1", "LabelCaption")
        s.node(base + "/Bar", "ProgressBar", {"custom_minimum_size": (0, 4), "mouse_filter": 2, "theme_type_variation": Raw('&"GoldBar"'), "show_percentage": False})
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
    s = page("ExchangeLeft", top=36)
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
    tile(s, C + "/Totals/Earned", "Haul value", extra={"tooltip_text": "Coin plus goods at the merchant price when each crew returned."})
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


def board():
    s = page("BoardLeft")
    header(s, C + "/Header", "Trades")
    label(s, C + "/Summary", "Every trade is a way to make money. Pick a site to plan a crew.", "LabelCaption", {"autowrap_mode": 3})
    scroll(s, C + "/List", 80)
    s.save(P + "board_left.tscn")

    s = page("BoardRight")
    header(s, C + "/Header", "Company Skills")
    label(s, C + "/Caption", "Your best mercenary in each trade", "LabelCaption")
    s.node(C + "/Skills", "VBoxContainer", {"theme_override_constants/separation": 4})
    for trade in ["Logging", "Mining", "Foraging", "Combat"]:
        base = C + "/Skills/" + trade
        s.node(base, "PanelContainer", {"theme_type_variation": Raw('&"InsetPanel"')})
        s.node(base + "/Row", "HBoxContainer", {"theme_override_constants/separation": 6})
        s.node(base + "/Row/Icon", "TextureRect", {"custom_minimum_size": (16, 16), "size_flags_vertical": 4, "mouse_filter": 2, "stretch_mode": 3})
        s.node(base + "/Row/Text", "VBoxContainer", {"size_flags_horizontal": 3, "theme_override_constants/separation": -3})
        label(s, base + "/Row/Text/Name", trade)
        label(s, base + "/Row/Text/Who", "Nobody trained", "LabelCaption", {"text_overrun_behavior": 3})
        s.node(base + "/Row/Level", "VBoxContainer", {"custom_minimum_size": (64, 0), "size_flags_vertical": 4, "theme_override_constants/separation": 0})
        label(s, base + "/Row/Level/Value", "Level 1", None, {"horizontal_alignment": 2})
        s.node(base + "/Row/Level/Bar", "ProgressBar", {"custom_minimum_size": (0, 4), "mouse_filter": 2, "theme_type_variation": Raw('&"GoldBar"'), "show_percentage": False})
    header(s, C + "/OtherHeader", "Other Work")
    scroll(s, C + "/Other", 40, expand=False)
    spacer(s, C + "/Spacer")
    s.inst(C + "/Tip", INFO, {"text": "New to the trade? Logging at Mossward Copse is safe work that pays from the first trip.", "icon_kind": "home"})
    s.save(P + "board_right.tscn")


def site_pages():
    s = page("SiteLeft")
    header(s, C + "/Header", "The Site")
    s.node(C + "/Site", "PanelContainer", {"custom_minimum_size": (0, 132), "theme_type_variation": Raw('&"SlotPanel"')})
    s.node(C + "/Site/Art", "TextureRect", {"mouse_filter": 2, "stretch_mode": 3})
    s.node(C + "/Site/Badge", "PanelContainer", {"size_flags_horizontal": 8, "size_flags_vertical": 8, "theme_type_variation": Raw('&"GoldPanel"')})
    label(s, C + "/Site/Badge/Text", "Logging 1+")
    label(s, C + "/Tagline", "", "LabelCaption", {"autowrap_mode": 3})
    s.node(C + "/Intel", "HBoxContainer", {"theme_override_constants/separation": 6})
    s.node(C + "/Intel/Yields", "VBoxContainer", {"theme_override_constants/separation": 1})
    label(s, C + "/Intel/Yields/Caption", "Each worker brings back", "LabelCaption")
    s.node(C + "/Intel/Yields/Slots", "HBoxContainer", {"theme_override_constants/separation": 4})
    s.node(C + "/Intel/Threat", "PanelContainer", {"size_flags_horizontal": 3, "theme_type_variation": Raw('&"InsetPanel"')})
    s.node(C + "/Intel/Threat/Body", "VBoxContainer", {"theme_override_constants/separation": 0})
    label(s, C + "/Intel/Threat/Body/Caption", "Threat", "LabelCaption")
    label(s, C + "/Intel/Threat/Body/Name", "None", "LabelAccent", {"text_overrun_behavior": 3})
    s.inst(C + "/Intel/Threat/Body/Danger", PIPS, {"value": 0, "max_value": 4, "tooltip_text": "Danger level"})
    label(s, C + "/Notes", "", "LabelMuted", {"autowrap_mode": 3})
    s.node(C + "/Facts", "HBoxContainer", {"theme_override_constants/separation": 4})
    tile(s, C + "/Facts/Duration", "Trip", extra={"tooltip_text": "Under Balanced orders. Cautious takes longer, Deep Push is quicker."})
    tile(s, C + "/Facts/Supplies", "Supplies", extra={"tooltip_text": "Paid up front on top of wages."})
    tile(s, C + "/Facts/Xp", "Experience", extra={"tooltip_text": "Trade experience each worker earns per trip."})
    spacer(s, C + "/Spacer")
    s.node(C + "/Footer", "HBoxContainer")
    button(s, C + "/Footer/Back", "<  All expeditions", "TextButton")
    s.save(P + "site_left.tscn")

    s = page("SiteRight")
    grp = s.sub("orders", "ButtonGroup", {})
    header(s, C + "/Header", "Expedition")
    s.inst(C + "/InField", "res://scenes/journal/rows/expedition_row.tscn", {"visible": False})
    s.node(C + "/Planning", "VBoxContainer", {"size_flags_vertical": 3, "theme_override_constants/separation": 6})
    s.node(C + "/Planning/CrewCaption", "HBoxContainer")
    label(s, C + "/Planning/CrewCaption/Label", "Crew  (up to 3)", "LabelCaption", {"size_flags_horizontal": 3})
    label(s, C + "/Planning/CrewCaption/Best", "", "LabelMuted")
    s.node(C + "/Planning/Slots", "HBoxContainer", {"theme_override_constants/separation": 4})
    for i in range(3):
        s.inst(C + "/Planning/Slots/Slot%d" % i, "res://scenes/journal/rows/crew_slot.tscn", {})
    label(s, C + "/Planning/RosterCaption", "Available  -  click to assign", "LabelCaption")
    s.node(C + "/Planning/Roster", "ScrollContainer", {"custom_minimum_size": (0, 62), "size_flags_vertical": 3, "horizontal_scroll_mode": 0})
    s.node(C + "/Planning/Roster/Items", "VBoxContainer", {"size_flags_horizontal": 3, "theme_override_constants/separation": 3})
    s.inst(C + "/Planning/NoCrew", INFO, {"visible": False, "text": "No mercenaries are free. Hire a woodcutter in Personnel.", "icon_kind": "plus"})
    button(s, C + "/Planning/Hire", "Hire in Personnel  >", "PaperButton", {"visible": False, "size_flags_horizontal": 4})
    s.node(C + "/Planning/Orders", "HBoxContainer", {"theme_override_constants/separation": 4})
    label(s, C + "/Planning/Orders/Caption", "Orders", "LabelCaption", {"custom_minimum_size": (38, 0)})
    for name, text, tip in [("Cautious", "Cautious", "Cautious: safer and slower, a smaller haul."), ("Balanced", "Balanced", "Balanced: a steady haul at the site's normal risk."), ("DeepPush", "Deep Push", "Deep Push: work harder for a bigger haul, at more risk."), ("LongShift", "Long Shift", "Long Shift: one long trip, six times as long. 80% of the hourly haul for four times the wages and supplies. For when you won't be back for a while.")]:
        button(s, C + "/Planning/Orders/" + name, text, "ToggleButton", {"size_flags_horizontal": 3, "toggle_mode": True, "button_group": grp, "tooltip_text": tip})
    s.node(C + "/Planning/Forecast", "HBoxContainer", {"theme_override_constants/separation": 4})
    tile(s, C + "/Planning/Forecast/Haul", "Expected haul", extra={"tooltip_text": "Average goods brought home after the crew's share."})
    tile(s, C + "/Planning/Forecast/Profit", "Expected profit", extra={"tooltip_text": "Value of the haul at today's merchant price, minus wages and supplies."})
    tile(s, C + "/Planning/Forecast/Risk", "Risk", extra={"tooltip_text": "Chance each worker is injured, and killed."})
    button(s, C + "/Fund", "Fund expedition", None, {"custom_minimum_size": (0, 26)})
    label(s, C + "/Reason", "", "LabelAccent", {"horizontal_alignment": 1, "autowrap_mode": 3})
    label(s, C + "/Warning", "Deaths and lost gear are permanent.", "LabelMuted", {"horizontal_alignment": 1})
    s.save(P + "site_right.tscn")


# --- Exchange tabs and the Trade Hall ------------------------------------------------
def exchange_tabs():
    s = Scene("ExchangeTabs", "Control", {"layout_mode": 3, "anchors_preset": 0, "offset_right": 285.0, "offset_bottom": 34.0, "mouse_filter": 2})
    grp = s.sub("tabs", "ButtonGroup", {})
    s.node("Tabs", "HBoxContainer", {"layout_mode": 0, "offset_left": 14.0, "offset_top": 12.0, "offset_right": 271.0, "offset_bottom": 30.0, "theme_override_constants/separation": 4})
    for name, text in [("MerchantsTab", "Merchants"), ("HallTab", "Trade Hall")]:
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


def trade_hall():
    s = page("HallLeft", top=36)
    header(s, C + "/Header", "Trade Chat")
    s.node(C + "/Summary", "HBoxContainer")
    label(s, C + "/Summary/Online", "14 traders online", "LabelCaption", {"size_flags_horizontal": 3})
    label(s, C + "/Summary/Fees", "Trade tax 3%", "LabelCaption", {"tooltip_text": "A 3% tax comes off gold you receive in a trade.", "mouse_filter": 1})
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
    s.node(C + "/Goods", "GridContainer", {"columns": 8, "theme_override_constants/h_separation": 3, "theme_override_constants/v_separation": 3})
    header(s, C + "/GearHeader", "Spare gear")
    s.node(C + "/GearScroll", "ScrollContainer", {"custom_minimum_size": (0, 31), "horizontal_scroll_mode": 0})
    s.node(C + "/GearScroll/Gear", "GridContainer", {"size_flags_horizontal": 3, "columns": 8, "theme_override_constants/h_separation": 3, "theme_override_constants/v_separation": 3})
    label(s, C + "/GearEmpty", "No spare gear. Gear in the armory storeroom shows here.", "LabelMuted", {"autowrap_mode": 3})
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
def company_tabs():
    s = Scene("CompanyTabs", "Control", {"layout_mode": 3, "anchors_preset": 0, "offset_right": 285.0, "offset_bottom": 34.0, "mouse_filter": 2})
    grp = s.sub("tabs", "ButtonGroup", {})
    s.node("Tabs", "HBoxContainer", {"layout_mode": 0, "offset_left": 14.0, "offset_top": 12.0, "offset_right": 271.0, "offset_bottom": 30.0, "theme_override_constants/separation": 4})
    for name, text in [("MapTab", "Region"), ("StandingTab", "Standing")]:
        button(s, "Tabs/" + name, text, "ToggleButton", {"size_flags_horizontal": 3, "toggle_mode": True, "button_group": grp})
    s.save(P + "company_tabs.tscn")


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
    label(s, "Margin/Body/Title", "Fallen gear", "LabelTitle")
    label(s, "Margin/Body/Summary", "", "LabelCaption", {"autowrap_mode": 3, "custom_minimum_size": (164, 0)})
    s.node("Margin/Body/Rows", "VBoxContainer", {"mouse_filter": 2, "theme_override_constants/separation": 2})
    label(s, "Margin/Body/Empty", "Nothing within your reach today.", "LabelMuted", {"visible": False, "horizontal_alignment": 1})
    label(s, "Margin/Body/Hint", "", "LabelMuted", {"autowrap_mode": 3, "custom_minimum_size": (164, 0)})
    s.save("scenes/journal/widgets/fallen_card.tscn")


def company_map():
    import json
    roads = json.load(open("tools/map_roads.json"))
    s = page("CompanyMapLeft", top=36)
    M = C + "/Map"
    s.node(M, "Control", {"custom_minimum_size": (257, 280), "size_flags_horizontal": 4, "mouse_filter": 2,
        "script": Res("res://scripts/ui/region_map.gd")})
    s.node(M + "/Ground", "TextureRect", {"layout_mode": 0, "offset_right": 257.0, "offset_bottom": 280.0, "mouse_filter": 2,
        "texture": Res("res://assets/ui/art/region_map.png"), "stretch_mode": 0})
    # Roads the crews walk, from town to each site (hidden guides; edit the points to re-route).
    s.node(M + "/Roads", "Node2D", {"visible": False})
    chimneys = roads.pop("_chimneys", [])
    for site, pts in roads.items():
        flat = ", ".join("%s, %s" % (x, y) for x, y in pts)
        s.node(M + "/Roads/" + site, "Line2D", {"points": Raw("PackedVector2Array(%s)" % flat), "width": 1.0})
    # Chimneys in town: smoke rises from each marker.
    s.node(M + "/Chimneys", "Node2D", {})
    for i, (x, y) in enumerate(chimneys):
        s.node(M + "/Chimneys/Chimney%d" % (i + 1), "Marker2D", {"position": (float(x), float(y)), "gizmo_extents": 3.0})
    # Unsurveyed lands.
    for name, text, x, y, w in [("Ruins", "Unsurveyed", 112, 18, 52), ("Fenmire", "Unsurveyed", 198, 248, 56)]:
        label(s, M + "/" + name, text, "MapLabel", {"layout_mode": 0, "offset_left": float(x), "offset_top": float(y),
            "offset_right": float(x + w), "offset_bottom": float(y + 12), "horizontal_alignment": 1, "mouse_filter": 1,
            "tooltip_text": "Not yet surveyed. New work sites will open here."})
    # Site names: click one to plan an expedition there.
    s.node(M + "/Sites", "Control", {"layout_mode": 1, "anchors_preset": 15, "anchor_right": 1.0, "anchor_bottom": 1.0, "mouse_filter": 2})
    for site, text, x, y, w in [("mossward_copse", "Mossward Copse", 14, 190, 76), ("old_oakwood", "Old Oakwood", 8, 24, 104),
                                ("harlow", "Harlow Mines", 174, 98, 66), ("town", "Mossward", 104, 222, 40)]:
        button(s, M + "/Sites/" + site, text, "MapButton", {"layout_mode": 0, "offset_left": float(x), "offset_top": float(y),
            "offset_right": float(x + w), "offset_bottom": float(y + 13)})
    # Grave markers: gear of the fallen this company could find at each site.
    s.node(M + "/Fallen", "Control", {"layout_mode": 1, "anchors_preset": 15, "anchor_right": 1.0, "anchor_bottom": 1.0, "mouse_filter": 2})
    for site, x, y in [("mossward_copse", 40, 203), ("old_oakwood", 30, 37), ("harlow", 192, 111)]:
        button(s, M + "/Fallen/" + site, "0", "MapButton", {"layout_mode": 0, "offset_left": float(x), "offset_top": float(y),
            "offset_right": float(x + 22), "offset_bottom": float(y + 12), "icon": Res("res://assets/ui/art/crew/grave.png")})
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
    personnel_armory()
    exchange()
    finances()
    chronicle()
    regions()
    guildwork()
    board()
    site_pages()
    print("pages written")
