# stroke_utils.gd
# Utilities to convert raw stroke points into a compact, invariant representation.
# Usage:
#   var sig = StrokeUtils.process_stroke(raw_points,
#                resample_count = 32, simplify_eps = 0.01, keep_aspect = true)

extends Node

class_name StrokeUtils

# --------------------------
# Basic geometry helpers
# --------------------------
static func _dist(a: Vector2, b: Vector2) -> float:
	return a.distance_to(b)

static func _path_length(points: Array) -> float:
	var L = 0.0
	for i in range(points.size() - 1):
		L += _dist(points[i], points[i+1])
	return L

# --------------------------
# Resample along arc-length to N points
# --------------------------
static func resample_points(points: Array, n: int) -> Array:
	if points.is_empty():
		return []

	if n <= 2:
		return [points.front(), points.back()]

	# compute distances
	var seg_len := []
	for i in range(points.size() - 1):
		seg_len.append(_dist(points[i], points[i+1]))
	var total := 0.0
	for d in seg_len:
		total += d
	if total == 0:
		# all points equal
		var total_out := []
		for i in range(n):
			total_out.append(points[0])
		return total_out

	# cumulative
	var cum := [0.0]
	for d in seg_len:
		cum.append(cum.back() + d)

	var out := []
	var step := total / float(n - 1)
	var t := 0.0
	var idx := 0
	for i in range(n):
		t = step * i
		# find segment containing t
		while idx < cum.size() - 1 and t > cum[idx+1]:
			idx += 1
		# clamp
		if idx >= points.size() - 1:
			out.append(points[points.size()-1])
			continue
		var dseg: float = cum[idx+1] - cum[idx]
		var frac := 0.0
		if dseg > 1e-8:
			frac = (t - cum[idx]) / dseg
		var p: Vector2 = points[idx].lerp(points[idx + 1], frac)
		out.append(p)
	return out

# --------------------------
# Normalize: translate and scale into [0,1] box
# keep_aspect: if true keep original aspect ratio (scale both axes uniformly)
# returns normalized_points, bbox (Rect2), scale_used (Vector2)
# --------------------------
static func normalize_points(points: Array, keep_aspect: bool = true) -> Dictionary:
	if points.is_empty():
		return {"points": [], "bbox": Rect2(), "scale": Vector2(1,1)}
	var min_x = points[0].x
	var max_x = points[0].x
	var min_y = points[0].y
	var max_y = points[0].y
	for p in points:
		if p.x < min_x: min_x = p.x
		if p.x > max_x: max_x = p.x
		if p.y < min_y: min_y = p.y
		if p.y > max_y: max_y = p.y
	var w = max_x - min_x
	var h = max_y - min_y
	# avoid zero dims
	if w < 1e-8: w = 1.0
	if h < 1e-8: h = 1.0
	var sx = 1.0 / w
	var sy = 1.0 / h
	if keep_aspect:
		var s = min(sx, sy)
		sx = s
		sy = s
	var out := []
	for p in points:
		var nx = (p.x - min_x) * sx
		var ny = (p.y - min_y) * sy
		out.append(Vector2(nx, ny))
	return {"points": out, "bbox": Rect2(min_x, min_y, w, h), "scale": Vector2(sx, sy)}

# --------------------------
# Ramer–Douglas–Peucker (RDP) simplification
# points : Array of Vector2
# eps : float (in normalized units, e.g., 0.01)
# --------------------------
static func _perp_distance(pt: Vector2, a: Vector2, b: Vector2) -> float:
	# distance from pt to segment ab
	var ab = b - a
	var ap = pt - a
	var denom = ab.length_squared()
	if denom <= 1e-12:
		return ap.length()
	var t = clamp(ab.dot(ap) / denom, 0.0, 1.0)
	var proj = a + ab * t
	return pt.distance_to(proj)

static func rdp_simplify(points: Array, eps: float) -> Array:
	if points.size() < 3:
		return points.duplicate()
	# find max perpendicular distance
	var max_d = -1.0
	var idx = -1
	for i in range(1, points.size() - 1):
		var d = _perp_distance(points[i], points[0], points[points.size()-1])
		if d > max_d:
			max_d = d
			idx = i
	if max_d > eps:
		var left = rdp_simplify(points.slice(0, idx+1), eps)
		var right = rdp_simplify(points.slice(idx, points.size()), eps)
		# join, avoid duplication of middle
		left.pop_back()
		return left + right
	else:
		# keep endpoints only
		return [points[0], points[points.size()-1]]

# --------------------------
# Compute directions and curvature
# directions: normalized vectors between successive resampled points
# curvature: change in angle between successive segments
# Also returns direction histogram (8 bins)
# --------------------------
static func compute_direction_curvature(points: Array) -> Dictionary:
	var dirs := []
	for i in range(points.size() - 1):
		var d = (points[i+1] - points[i])
		var ln = d.length()
		if ln > 1e-8:
			dirs.append(d / ln)
		else:
			dirs.append(Vector2.ZERO)
	# curvature: angle change in radians
	var curv := []
	for i in range(dirs.size() - 1):
		var a = dirs[i].angle()
		var b = dirs[i+1].angle()
		var da = wrapf(b - a, -PI, PI) # signed small angle
		curv.append(da)
	# direction histogram: 8 bins (N, NE, E, SE, S, SW, W, NW)
	var bins = PackedFloat32Array([0,0,0,0,0,0,0,0])
	for d in dirs:
		if d == Vector2.ZERO:
			continue
		var ang = fmod(atan2(d.y, d.x) + TAU, TAU)
		var bin = int(floor(ang / (TAU / 8.0))) % 8
		bins[bin] += 1
	# normalize histogram
	var total = 0
	for b in bins:
		total += b
	if total > 0:
		for i in range(bins.size()):
			bins[i] /= total
	return {"dirs": dirs, "curvature": curv, "dir_hist": bins}

# --------------------------
# Main pipeline for a single stroke
# raw_points: Array of Vector2 in screen pixels (or raw input coords)
# resample_count: how many points to resample (e.g., 32)
# simplify_eps: RDP epsilon in normalized units (e.g., 0.02)
# keep_aspect: whether to keep aspect on normalization
# --------------------------
static func process_stroke(raw_points: Array, resample_count: int = 32, simplify_eps: float = 0.02, keep_aspect: bool = true) -> Dictionary:
	# defensive
	if raw_points.size() == 0:
		return {}

	# 1) optionally simplify noisy input first (tiny epsilon in pixels)
	# (this step can be toggled/adjusted if you get pen jitter)
	# We'll skip pre-simplify here to keep things predictable.

	# 2) resample in raw space to a moderate number to remove speed variation
	var resampled_raw : Array = resample_points(raw_points, resample_count)

	# 3) normalize to unit box
	var norm_res = normalize_points(resampled_raw, keep_aspect)
	var normalized : Array = norm_res["points"]

	# 4) simplified keypoints using RDP on normalized points
	var keypoints : Array = rdp_simplify(normalized, simplify_eps)

	# 5) compute mid (approx center on arc-length)
	var mid_idx = int(floor((normalized.size() - 1) / 2.0))
	var start_pt = normalized[0]
	var mid_pt = normalized[mid_idx]
	var end_pt = normalized[normalized.size() - 1]

	# 6) compute directions, curvature, histogram
	var geom = compute_direction_curvature(normalized)

	# 7) features summary
	var bbox = Rect2()
	# bounding box in normalized coords
	var minx = 1e9
	var maxx = -1e9
	var miny = 1e9
	var maxy = -1e9
	for p in normalized:
		if p.x < minx: minx = p.x
		if p.x > maxx: maxx = p.x
		if p.y < miny: miny = p.y
		if p.y > maxy: maxy = p.y
	bbox.position = Vector2(minx, miny)
	bbox.size = Vector2(maxx - minx, maxy - miny)

	var signature = {
		"resampled": normalized,        # Array<Vector2> fixed length
		"keypoints": keypoints,         # Array<Vector2> small
		"start": start_pt,
		"mid": mid_pt,
		"end": end_pt,
		"dir_hist": geom["dir_hist"],   # PoolRealArray normalized to sum=1
		"curvature": geom["curvature"], # Array of small angles (radians)
		"bbox": bbox,
		"raw_bbox": norm_res["bbox"],   # original pixel bbox (for reference)
		"scale": norm_res["scale"]      # scale used for normalization
	}
	return signature

# --------------------------
# OPTIONAL: DTW for resampled point comparison (direction sensitive)
# resampled points should be normalized already.
# returns total_cost and average_cost
# --------------------------
static func dtw_cost(points_a: Array, points_b: Array) -> Dictionary:
	var na = points_a.size()
	var nb = points_b.size()
	if na == 0 or nb == 0:
		return {"total": INF, "avg": INF}
	var D = []
	# initialize with INF
	for i in range(na+1):
		D.append([])
		for j in range(nb+1):
			D[i].append(INF)
	D[0][0] = 0.0
	for i in range(1, na+1):
		for j in range(1, nb+1):
			var ca = points_a[i-1]
			var cb = points_b[j-1]
			var cost = ca.distance_to(cb)
			D[i][j] = cost + min(min(D[i-1][j], D[i][j-1]), D[i-1][j-1])
	var total = D[na][nb]
	var avg = total / float(na + nb) # rough normalization
	return {"total": total, "avg": avg}

# --------------------------
# Helper: compare two signatures (stroke-level)
# returns a score 0..1
# Options:
#  - use_dtw: true => use DTW on resampled points (robust to local timing)
#  - max_point_deviation: if any resampled point deviates more than this -> fail
# --------------------------
static func compare_strokes(sig_a: Dictionary, sig_b: Dictionary, use_dtw: bool = true, max_point_deviation: float = 0.25) -> float:
	# require direction sensitivity => do not check reversed sequences
	if sig_a.is_empty() or sig_b.is_empty():
		return 0.0

	var a_pts = sig_a["resampled"]
	var b_pts = sig_b["resampled"]
	# quick bbox-check: if bounding boxes totally different shape, early fail? optional
	# Compute per-point distances
	var max_dev = 0.0
	var sum_dev = 0.0
	for i in range(min(a_pts.size(), b_pts.size())):
		var d = a_pts[i].distance_to(b_pts[i])
		sum_dev += d
		if d > max_dev: max_dev = d
	var mean_dev = sum_dev / float(min(a_pts.size(), b_pts.size()))
	if max_dev > max_point_deviation:
		return 1.0

	if use_dtw:
		var dtw = dtw_cost(a_pts, b_pts)
		# convert avg cost into 0..1 score (simple)
		var score = max(0.0, 1.0 - clamp(dtw["avg"], 0.0, 1.0))
		return score
	else:
		# simple average-based score
		var score2 = max(0.0, 1.0 - clamp(mean_dev, 0.0, 1.0))
		return score2

static func compare_strokes2(sig_a: Dictionary, sig_b: Dictionary, use_dtw: bool = true, max_point_deviation: float = 0.25) -> float:
	# 0.0 = identical, 1.0 = very different
	if sig_a.is_empty() or sig_b.is_empty():
		return 1.0

	var a_pts: Array = sig_a.get("resampled", [])
	var b_pts: Array = sig_b.get("resampled", [])
	if a_pts.is_empty() or b_pts.is_empty():
		return 1.0

	var n :int= min(a_pts.size(), b_pts.size())
	if n <= 0:
		return 1.0

	# Direct (index-aligned) distances
	var sum_direct := 0.0
	var max_direct := 0.0
	for i in range(n):
		var d: float = (a_pts[i] as Vector2).distance_to(b_pts[i] as Vector2)
		sum_direct += d
		if d > max_direct:
			max_direct = d
	var mean_direct := sum_direct / float(n)

	# Optional DTW (elastic alignment)
	var avg_cost := mean_direct
	if use_dtw:
		var dtw := dtw_cost(a_pts, b_pts)
		var dtw_avg: float = dtw["avg"]
		# Be generous: take the lower cost between DTW and direct
		avg_cost = min(mean_direct, dtw_avg)

	# Outlier handling: push cost up if any point deviates a lot
	if max_direct > max_point_deviation:
		avg_cost = max(avg_cost, max_direct)

	# Normalize to 0..1 by the maximum distance possible in the unit box (diagonal = sqrt(2))
	var max_possible := sqrt(2.0)
	var dissimilarity :float= clamp(avg_cost / max_possible, 0.0, 1.0)
	return dissimilarity
