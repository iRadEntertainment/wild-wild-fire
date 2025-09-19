extends RefCounted
class_name GameStats


class LevelStats extends RefCounted:
	var level_num: int
	var scores: int
	var time_elapsed: int = 0
	
	func _init(_level_num: int) -> void:
		level_num = _level_num
	
	func to_json() -> Dictionary:
		var d: Dictionary = {}
		d["level_num"] = level_num
		d["scores"] = scores
		d["time_elapsed"] = time_elapsed
		return d
	
	static func from_json(d: Dictionary) -> LevelStats:
		var new_stats := LevelStats.new(d.get("level_num", 0))
		new_stats.scores = d.get("scores", 0)
		new_stats.time_elapsed = d.get("time_elapsed", 0)
		return new_stats


var _all: Dictionary[int, LevelStats] = {}
var game_t_start: int
var level_n: int
var level_stats: LevelStats:
	get: return _all[level_n]

signal score_updated



func new_level(_game: Game) -> void:
	level_n = _game.level_n
	game_t_start = _game.t_start
	_all[level_n] = LevelStats.new(level_n)
	_game.game_lost.connect(_on_game_end)
	_game.game_won.connect(_on_game_end)


func increase_score(partial_scores: int) -> void:
	level_stats.scores += partial_scores
	score_updated.emit()


func _on_game_end() -> void:
	level_stats.time_elapsed = Time.get_ticks_msec() - game_t_start



#region Getters
func get_global_scores() -> int:
	var tot_scores: int = 0
	for l_stats: LevelStats in _all.values():
		tot_scores += l_stats.scores
	return tot_scores
func get_total_time() -> int:
	var tot_time: int = 0
	for l_stats: LevelStats in _all.values():
		tot_time += l_stats.time_elapsed
	return tot_time
#endregion


#region Serialization
func to_json() -> Dictionary:
	var d: Dictionary = {}
	d["_all"] = {}
	for _level_num: int in _all.keys():
		var _level_stats: LevelStats = _all[_level_num]
		var game_dict: Dictionary = _level_stats.to_json()
		d["_all"][str(_level_num)] = game_dict
	d["game_t_start"] = game_t_start
	d["level_n"] = level_n
	return d


static func from_json(d: Dictionary) -> GameStats:
	var new_level_stats := GameStats.new()
	var stats_dict: Dictionary = d.get("_all", {})
	for _level_n_str: String in stats_dict.keys():
		var _level_n: int = int(_level_n_str)
		var _level_stats: LevelStats = LevelStats.from_json(stats_dict[_level_n_str])
		new_level_stats._all[_level_n] = _level_stats
	new_level_stats.game_t_start = d.get("game_t_start", 0)
	new_level_stats.level_n = d.get("level_n", 0)
	return new_level_stats
#endregion


#region Utilities
static func t_msec_to_string(msecs: int) -> String:
	@warning_ignore("integer_division")
	var usecs: int = msecs / 1000
	var fract: int = msecs % 1000
	var t_dict: Dictionary = Time.get_time_dict_from_unix_time(usecs)
	
	if t_dict["hour"] > 0:
		return "%d:%02d%02d" % [t_dict["hour"], t_dict["minute"], t_dict["second"]]
	
	return "%02d:%02d.%03d" % [t_dict["minute"], t_dict["second"], fract]
#endregion
