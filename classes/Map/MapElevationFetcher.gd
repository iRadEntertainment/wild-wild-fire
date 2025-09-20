@tool
extends Node
class_name MapElevationFetcher


const TERRARIUM_URL := "https://s3.amazonaws.com/elevation-tiles-prod/terrarium/{z}/{x}/{y}.png"
const WORLD_IMAGERY_URL := "https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}"


var http_request_satellite: HTTPRequest
var http_request_heightmap: HTTPRequest
var img_elevation: Image
var img_satellite: Image
var min_height: float
var max_height: float

signal heightmap_fetched
signal satellite_fetched


#region Init
func _enter_tree() -> void:
	if not Engine.is_editor_hint():
		return
	
	if not is_instance_valid(http_request_heightmap):
		http_request_heightmap = HTTPRequest.new()
		http_request_heightmap.name = "MapFetcherHTTPRequest"
		add_child(http_request_heightmap)
		# Keep it editor-only so it doesn’t end up in exported builds by accident
		http_request_heightmap.owner = null
	
	if http_request_heightmap.request_completed.is_connected(_on_request_heightmap_completed):
		http_request_heightmap.request_completed.disconnect(_on_request_heightmap_completed)
	
	http_request_heightmap.request_completed.connect(_on_request_heightmap_completed)
	
	if not is_instance_valid(http_request_satellite):
		http_request_satellite = HTTPRequest.new()
		http_request_satellite.name = "MapFetcherHTTPRequestSat"
		add_child(http_request_satellite)
		# Keep it editor-only so it doesn’t end up in exported builds by accident
		http_request_satellite.owner = null
	
	if http_request_satellite.request_completed.is_connected(_on_request_satellite_completed):
		http_request_satellite.request_completed.disconnect(_on_request_satellite_completed)
	
	http_request_satellite.request_completed.connect(_on_request_satellite_completed)
#endregion


#region Fetch
func _fetch_tile(coord_latitude: float, coord_longitude: float, zoom: int) -> void:
	if not Engine.is_editor_hint():
		return
	if not is_instance_valid(http_request_heightmap):
		push_warning("No HTTPRequest available. Please assign one in the Inspector or re-select the node.")
		return
	
	var xyz := MapUtl.latlon_to_xyz(coord_latitude, coord_longitude, zoom)
	var x := xyz.x
	var y := xyz.y
	var z := xyz.z
	
	var url_heightmap := TERRARIUM_URL.format({ "z": z, "x": x, "y": y })
	http_request_heightmap.request(url_heightmap)
	var url_satellite := WORLD_IMAGERY_URL.format({ "z": z, "x": x, "y": y })
	http_request_satellite.request(url_satellite)


func _on_request_heightmap_completed(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	if not Engine.is_editor_hint():
		return
	if result != HTTPRequest.RESULT_SUCCESS or response_code < 200 or response_code >= 300:
		push_error("HTTP error. result=%s, code=%s" % [result, response_code])
		return

	var img := Image.new()
	var load_err := img.load_png_from_buffer(body)
	if load_err != OK:
		push_error("Failed to decode PNG. Code: %s" % load_err)
		return
	
	img_elevation = img
	var min_max: Array[float] = MapUtl.get_min_max_from_heightmap(img)
	min_height = min_max[0]
	max_height = min_max[1]
	heightmap_fetched.emit()


func _on_request_satellite_completed(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	if not Engine.is_editor_hint():
		return
	if result != HTTPRequest.RESULT_SUCCESS or response_code < 200 or response_code >= 300:
		push_error("HTTP error. result=%s, code=%s" % [result, response_code])
		return

	var img := Image.new()
	var load_err := img.load_jpg_from_buffer(body)
	if load_err != OK:
		push_error("Failed to decode PNG. Code: %s" % load_err)
		return
	
	img_satellite = img
	satellite_fetched.emit()
#endregion


#region Utilities
func compute_min_max() -> Vector2:
	if img_elevation == null or img_elevation.is_empty():
		return Vector2.ZERO
	var w := img_elevation.get_width()
	var h := img_elevation.get_height()
	var min_value := INF
	var max_value := -INF
	for y in h:
		for x in w:
			var c := img_elevation.get_pixel(x, y)
			var e := MapUtl.terrarium_color_to_height_meters(c)
			min_value = min(min_value, e)
			max_value = max(max_value, e)
	return Vector2(min_value, max_value)
#endregion
