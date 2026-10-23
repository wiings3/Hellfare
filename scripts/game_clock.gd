extends RefCounted
class_name GameClock
## The one place game rules read the time. In play it is the real clock. The economy
## simulator (tools/econ_sim.gd) sets `fixed` to fast-forward hours of play in seconds.

## When 0 or more, the time every game rule sees; -1 means the real clock.
static var fixed: int = -1

static func now() -> int:
	return fixed if fixed >= 0 else int(Time.get_unix_time_from_system())
