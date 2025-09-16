class_name MapUtl


const EARTH_RADIUS = 6378137.0


static func grid_to_world(grid_pos: Vector2i, elevation: float = 0.0, cell_size: float = 1.0) -> Vector3:
	var position: Vector3 = Vector3(
		grid_pos.x * cell_size,
		elevation,
		grid_pos.y * cell_size
	)
	var half_cell: Vector3 = Vector3(cell_size/2.0, 0, cell_size/2.0)
	position += half_cell
	return position


static func meters_per_pixel(lat_deg: float, zoom: int) -> float:
	var lat_rad = deg_to_rad(lat_deg)
	var circumference = 2.0 * PI * EARTH_RADIUS
	var equator_res = circumference / (256.0 * pow(2.0, zoom))
	return equator_res * cos(lat_rad)


static func latlon_to_xyz(lat: float, lon: float, z: int) -> Vector3i:
	var lat_rad := deg_to_rad(lat)
	var n := 1 << z
	var x := int(floor((lon + 180.0) / 360.0 * n))
	var y := int(floor((1.0 - asinh(tan(lat_rad)) / PI) / 2.0 * n))
	return Vector3i(x, y, z)


static func terrarium_color_to_height_meters(color: Color) -> float:
	var R := color.r8
	var G := color.g8
	var B := color.b8
	return (R * 256.0 + G + B / 256.0) - 32768.0


#static func terrarium_height_meters_to_color(_height: float) -> Color:
	#var col: Color = Color()
	#var R := col.r8
	#var G := col.g8
	#var B := col.b8
	#return (R * 256.0 + G + B / 256.0) - 32768.0
	#return col


static func normalize(value: float, min_value: float, max_value: float) -> float:
	return (value - min_value) / max(0.000001, max_value - min_value)


static func get_min_max_from_heightmap(img: Image) -> Array[float]:
	var img_size: Vector2i = img.get_size()
	var min_height: float = INF
	var max_height: float = -INF
	for x in img_size.x:
		for y in img_size.y:
			var col: Color = img.get_pixel(x, y)
			var height: float = terrarium_color_to_height_meters(col)
			if height < min_height:
				min_height = height
			if height > max_height:
				max_height = height
	return [min_height, max_height]
