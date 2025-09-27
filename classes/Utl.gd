# static class with utility functions
class_name Utl


static func range_circle_points(
			radius: float,
			ellipse_ratio := 1.0,
			offset := Vector2(),
			res: int = 50
		) -> Array[Vector2]:
	var points: Array[Vector2] = []
	for i in res+1:
		var a = i/float(res) * 2*PI
		var p := Vector2.RIGHT.rotated(a) * radius
		p.y *= ellipse_ratio
		p += offset
		points.append(p)
	return points


static func select_from_weights(weights: PackedFloat32Array, select_range: float) -> int:
	var sum_weights: float = 0
	for w: float in weights:
		sum_weights += w
	
	var threshold: float = sum_weights * select_range
	var tot: float = 0
	for i: int in weights.size():
		var w: float = weights[i]
		tot += w
		if tot > threshold:
			return i
	return -1


static func vec_to_string(vec) -> String:
	if typeof(vec) == TYPE_VECTOR2:
		return "%.2f, %.2f" % [vec.x, vec.y]
	elif typeof(vec) == TYPE_VECTOR2I:
		return "%d, %d" % [vec.x, vec.y]
	elif typeof(vec) == TYPE_VECTOR3:
		return "%.2f, %.2f, %.2f" % [vec.x, vec.y, vec.z]
	elif typeof(vec) == TYPE_VECTOR3I:
		return "%d, %d, %d" % [vec.x, vec.y, vec.z]
	return ""
