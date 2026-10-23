extends RefCounted
class_name ChatParse
## Reads trade-chat messages the way a trader skims them: is this selling or buying,
## what is the price, how many, and is it a yes or a no. Used by NPC traders to react to
## what the player types. Deliberately forgiving: "WTS [Timber]x40 6g ea", "selling
## [Steel Sword] 150", "20 for 110g?", "1.5k", "deal" all read the way a person means them.

static var _re_money := RegEx.create_from_string("(?<![x\\d.%+])(\\d+(?:\\.\\d+)?)\\s*(k)?\\s*(g\\b|gold\\b|gp\\b)?\\s*(each|ea\\b|per\\b|apiece|/ea|/each|a piece)?(?!\\s*%)(?!\\s*x\\b)(?!\\d)")
static var _re_qty_x := RegEx.create_from_string("(?:\\]\\s*x\\s*|\\bx\\s*)(\\d+)|(\\d+)\\s*x\\b")
static var _re_for := RegEx.create_from_string("(\\d+)\\s*(?:for|of them for|@)\\s*(\\d+(?:\\.\\d+)?)\\s*(k)?")
static var _re_sell := RegEx.create_from_string("\\b(wts|selling|sell|s>|for sale|fs)\\b")
static var _re_buy := RegEx.create_from_string("\\b(wtb|buying|buy|b>|lf|looking for|want)\\b")
static var _re_yes := RegEx.create_from_string("\\b(deal|ok|okay|sure|yes|yep|yeah|accept|accepted|agreed|done|fine|sounds good|i'?ll take it|i'?ll take|let'?s do it|works)\\b")
static var _re_no := RegEx.create_from_string("\\b(no thanks|no thank you|nah|pass|never ?mind|nvm|not interested|forget it|no deal)\\b")
static var _re_trade := RegEx.create_from_string("\\b(trade|inv|invite|send it|send the trade)\\b")
static var _re_ask := RegEx.create_from_string("(\\?|\\bhow much\\b|\\bprice\\b|\\bstill (have|got|available|up)\\b|\\bavailable\\b|\\bpc\\b)")
static var _re_all := RegEx.create_from_string("\\b(all|everything|the lot|whole lot)\\b")

## "sell", "buy", or "" when the message does not say.
static func intent(text: String) -> String:
	var t: String = text.to_lower()
	var s: RegExMatch = _re_sell.search(t)
	var b: RegExMatch = _re_buy.search(t)
	if s != null and (b == null or s.get_start() < b.get_start()):
		return "sell"
	if b != null:
		return "buy"
	return ""

## Every money figure in the text, in order: {"value": gold, "each": bool, "at": index}.
## Item names inside [brackets] and quantities like x40 are skipped.
static func money(text: String) -> Array:
	var t: String = _strip_links(text.to_lower())
	var found: Array = []
	for m in _re_money.search_all(t):
		var value: float = float(m.get_string(1))
		if m.get_string(2) == "k":
			value *= 1000.0
		found.append({"value": int(round(value)), "each": m.get_string(4) != "", "at": m.get_start(), "gold": m.get_string(3) != "" or m.get_string(2) == "k"})
	return found

## A quantity ("x40", "40x", "40 for 200g"), or -1.
static func quantity(text: String) -> int:
	var t: String = text.to_lower()
	var f: RegExMatch = _re_for.search(_strip_links(t))
	if f != null:
		return int(f.get_string(1))
	var m: RegExMatch = _re_qty_x.search(t)
	if m != null:
		return int(m.get_string(1) if m.get_string(1) != "" else m.get_string(2))
	return -1

## "N for M" read as a quantity and a total, or {} when the text has no such phrase.
static func lot(text: String) -> Dictionary:
	var f: RegExMatch = _re_for.search(_strip_links(text.to_lower()))
	if f == null:
		return {}
	var total: float = float(f.get_string(2)) * (1000.0 if f.get_string(3) == "k" else 1.0)
	return {"qty": int(f.get_string(1)), "total": int(round(total))}

static func says_yes(text: String) -> bool:
	return _re_yes.search(text.to_lower()) != null and not says_no(text)

static func says_no(text: String) -> bool:
	return _re_no.search(text.to_lower()) != null

static func wants_trade(text: String) -> bool:
	return _re_trade.search(text.to_lower()) != null

static func asks(text: String) -> bool:
	return _re_ask.search(text.to_lower()) != null

static func wants_all(text: String) -> bool:
	return _re_all.search(text.to_lower()) != null

## Turn a figure into a total for `qty`. Unmarked figures are read as "each" when they
## are close to the unit value and as a total otherwise, the way a trader would.
static func total_for(figure: Dictionary, qty: int, unit_value: float) -> int:
	var value: int = int(figure["value"])
	if qty <= 1:
		return value
	if bool(figure["each"]):
		return value * qty
	if float(value) <= unit_value * 2.5:
		return value * qty
	return value

## The price the player put on the item linked at `link_index` in a post: the first money
## figure after that link (or the only one). Returns {} when there is none.
static func price_after_link(text: String, link_name: String) -> Dictionary:
	var lower: String = text.to_lower()
	var at: int = lower.find("[" + link_name.to_lower() + "]")
	var figures: Array = money(text)
	if figures.is_empty():
		return {}
	if at < 0:
		return figures[0]
	for f in figures:
		if int(f["at"]) > at:
			return f
	return figures.back()

## The quantity written right after a link ("[Timber]x40"), or -1.
static func qty_after_link(text: String, link_name: String) -> int:
	var lower: String = text.to_lower()
	var token: String = "[" + link_name.to_lower() + "]"
	var at: int = lower.find(token)
	if at < 0:
		return -1
	var rest: String = lower.substr(at + token.length(), 8)
	var m: RegExMatch = RegEx.create_from_string("^\\s*x\\s*(\\d+)").search(rest)
	return int(m.get_string(1)) if m != null else -1

## Replace [Item Name] tokens with spaces of the same length so their digits are ignored.
static func _strip_links(text: String) -> String:
	var out: String = text
	var re := RegEx.create_from_string("\\[[^\\]]*\\](\\s*x\\s*\\d+)?")
	for m in re.search_all(text):
		out = out.substr(0, m.get_start()) + " ".repeat(m.get_end() - m.get_start()) + out.substr(m.get_end())
	return out
