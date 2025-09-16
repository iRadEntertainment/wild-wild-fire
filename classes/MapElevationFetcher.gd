@tool
extends Node
class_name MapElevationFetcher

@export_category("Fetch Controls")
@export var coord_latitude: float = 37.7749
@export var coord_longitude: float = -122.4194
@export_range(0, 19, 1) var zoom: int = 10


@warning_ignore("unused_private_class_variable")
@export_tool_button("Fetch elevation Image", "Button") var _fetch_now_btn: Callable = _fetch_now
func _fetch_now() -> void:
	if Engine.is_editor_hint():
		_fetch_tile()

@export var http_request: HTTPRequest

@export_category("Result")
@export var result_texture: Texture2D
var result_image: Image

@export_category("Source")
## Choose source; Mapbox needs a token. Terrarium works without one.
@export_enum("Terrarium", "Mapbox Terrain-RGB") var source: int = 0
@export var mapbox_access_token: String = "" # only used if source == 1

# ---------- Constants ----------
const TERRARIUM_URL := "https://s3.amazonaws.com/elevation-tiles-prod/terrarium/{z}/{x}/{y}.png"
const MAPBOX_URL := "https://api.mapbox.com/v4/mapbox.terrain-rgb/{z}/{x}/{y}.pngraw?access_token={token}"

signal tile_fetched


func _enter_tree() -> void:
	if not Engine.is_editor_hint():
		return
	if not is_instance_valid(http_request):
		http_request = HTTPRequest.new()
		http_request.name = "MapFetcherHTTPRequest"
		add_child(http_request)
		# Keep it editor-only so it doesn’t end up in exported builds by accident
		http_request.owner = null
	# (Re)connect signal safely
	if http_request.is_connected("request_completed", Callable(self, "_on_request_completed")):
		http_request.disconnect("request_completed", Callable(self, "_on_request_completed"))
	
	http_request.request_completed.connect(_on_request_completed)


static func latlon_to_xyz(lat: float, lon: float, z: int) -> Vector3i:
	var lat_rad := deg_to_rad(lat)
	var n := 1 << z
	var x := int(floor((lon + 180.0) / 360.0 * n))
	var y := int(floor((1.0 - asinh(tan(lat_rad)) / PI) / 2.0 * n))
	return Vector3i(x, y, z)


static func terrarium_to_meters(color: Color) -> float:
	var R := color.r8
	var G := color.g8
	var B := color.b8
	return (R * 256.0 + G + B / 256.0) - 32768.0


static func terrainrgb_to_meters(color: Color) -> float:
	var R := color.r8
	var G := color.g8
	var B := color.b8
	return -10000.0 + (R * 256.0 * 256.0 + G * 256.0 + B) * 0.1


func _fetch_tile() -> void:
	if not Engine.is_editor_hint():
		return
	if not is_instance_valid(http_request):
		push_warning("No HTTPRequest available. Please assign one in the Inspector or re-select the node.")
		return

	var xyz := latlon_to_xyz(coord_latitude, coord_longitude, zoom)
	var x := xyz.x
	var y := xyz.y
	var z := xyz.z

	var url := ""
	match source:
		0: # Terrarium
			url = TERRARIUM_URL.format({ "z": z, "x": x, "y": y })
		1: # Mapbox Terrain-RGB
			if mapbox_access_token.is_empty():
				push_error("Mapbox source selected but access token is empty.")
				return
			url = MAPBOX_URL.format({ "z": z, "x": x, "y": y, "token": mapbox_access_token })
		_:
			push_error("Unknown source.")
			return

	# request
	var err := http_request.request(url)
	if err != OK:
		push_error("HTTPRequest failed to start. Code: %s" % err)


func _on_request_completed(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
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
	
	result_image = img
	
	# Create/replace preview texture for the Inspector
	var tex := ImageTexture.create_from_image(img)
	result_texture = tex
	tile_fetched.emit()


# ---------- Convenience: sample an elevation from the last fetch ----------
## Returns elevation (meters) at a pixel (Terrarium or Terrain-RGB decoding).
func sample_elevation_at(px: int, py: int) -> float:
	if result_image == null or result_image.is_empty():
		return NAN
	var c := result_image.get_pixel(px, py)
	return terrarium_to_meters(c) if source == 0 else terrainrgb_to_meters(c)


# ---------- Optional: normalize helpers ----------
static func normalize(value: float, mn: float, mx: float) -> float:
	return (value - mn) / max(0.000001, mx - mn)


func compute_min_max() -> Vector2:
	if result_image == null or result_image.is_empty():
		return Vector2.ZERO
	var w := result_image.get_width()
	var h := result_image.get_height()
	var mn := INF
	var mx := -INF
	for y in h:
		for x in w:
			var c := result_image.get_pixel(x, y)
			var e := terrarium_to_meters(c) if source == 0 else terrainrgb_to_meters(c)
			mn = min(mn, e)
			mx = max(mx, e)
	return Vector2(mn, mx)
