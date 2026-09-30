extends RefCounted
static var cache: Dictionary = {}

static func mesh(size: Vector3, kind: String = "box") -> Mesh:
	var key := str(size)+kind
	if cache.has(key):
		return cache[key]
	if kind == "box":
		var box := BoxMesh.new()
		box.size = size
		cache[key] = box
		return box
	var corners: Array[Vector2] = [Vector2(-0.35,-0.5),Vector2(0.35,-0.5),Vector2(0.5,-0.35),Vector2(0.5,0.35),Vector2(0.35,0.5),Vector2(-0.35,0.5),Vector2(-0.5,0.35),Vector2(-0.5,-0.35)]
	if kind in ["tube","cone"]:
		corners.clear()
		for i in range(10):
			corners.append(Vector2(cos(TAU*i/10),sin(TAU*i/10))*0.5)
	var front: Array[Vector3] = []
	var back: Array[Vector3] = []
	for point in corners:
		var taper: float = 0.45 if kind == "cone" else (0.55 if kind == "stock" else 1.0)
		front.append(Vector3(point.x*size.x*taper,point.y*size.y*taper,-size.z/2))
		back.append(Vector3(point.x*size.x,point.y*size.y,size.z/2))
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(corners.size()):
		var next: int = (i+1)%corners.size()
		triangle(surface,front[i],back[i],back[next])
		triangle(surface,front[i],back[next],front[next])
		triangle(surface,Vector3(0,0,-size.z/2),front[i],front[next])
		triangle(surface,Vector3(0,0,size.z/2),back[next],back[i])
	var result := surface.commit()
	cache[key] = result
	return result

static func triangle(surface: SurfaceTool, a: Vector3, b: Vector3, c: Vector3) -> void:
	var normal := -(b-a).cross(c-a).normalized()
	for point in [a,b,c]:
		surface.set_normal(normal)
		surface.add_vertex(point)
