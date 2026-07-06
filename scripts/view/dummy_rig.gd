class_name DummyRig
extends Node3D
## Boneco de treino de madeira construído por código: poste, corpo de palha
## amarrado com cordas, braços cruzados e alvo no peito.

var meshes: Array[MeshInstance3D] = []

var _wood := StandardMaterial3D.new()
var _straw := StandardMaterial3D.new()
var _rope := StandardMaterial3D.new()
var _target := StandardMaterial3D.new()

func _ready() -> void:
	_wood.albedo_color = Color(0.38, 0.26, 0.16)
	_wood.roughness = 0.9
	_straw.albedo_color = Color(0.72, 0.58, 0.32)
	_straw.roughness = 1.0
	_rope.albedo_color = Color(0.3, 0.24, 0.16)
	_rope.roughness = 1.0
	_target.albedo_color = Color(0.75, 0.15, 0.12)
	_target.roughness = 0.8
	_build()

func _build() -> void:
	# base cruzada + poste
	_box(Vector3(0.0, 0.06, 0.0), Vector3(0.9, 0.12, 0.18), _wood)
	_box(Vector3(0.0, 0.06, 0.0), Vector3(0.18, 0.12, 0.9), _wood)
	_cylinder(Vector3(0.0, 0.7, 0.0), 0.09, 1.3, _wood)

	# corpo de palha + cordas
	_capsule(Vector3(0.0, 1.35, 0.0), 0.34, 1.0, _straw)
	_torus(Vector3(0.0, 1.15, 0.0), 0.34, _rope)
	_torus(Vector3(0.0, 1.4, 0.0), 0.35, _rope)
	_torus(Vector3(0.0, 1.6, 0.0), 0.3, _rope)

	# braços (travessa) + cabeça
	_box(Vector3(0.0, 1.55, 0.0), Vector3(1.15, 0.11, 0.11), _wood)
	_capsule(Vector3(0.0, 1.98, 0.0), 0.17, 0.44, _straw)
	_torus(Vector3(0.0, 1.86, 0.0), 0.16, _rope)

	# alvo no peito
	var t := _cylinder(Vector3(0.0, 1.38, 0.3), 0.14, 0.03, _target)
	t.rotation_degrees.x = 90.0

func _box(pos: Vector3, size: Vector3, mat: StandardMaterial3D) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	return _add(mesh, pos, mat)

func _cylinder(pos: Vector3, radius: float, height: float, mat: StandardMaterial3D) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	return _add(mesh, pos, mat)

func _capsule(pos: Vector3, radius: float, height: float, mat: StandardMaterial3D) -> MeshInstance3D:
	var mesh := CapsuleMesh.new()
	mesh.radius = radius
	mesh.height = height
	return _add(mesh, pos, mat)

func _torus(pos: Vector3, radius: float, mat: StandardMaterial3D) -> MeshInstance3D:
	var mesh := TorusMesh.new()
	mesh.inner_radius = radius - 0.035
	mesh.outer_radius = radius + 0.035
	return _add(mesh, pos, mat)

func _add(mesh: Mesh, pos: Vector3, mat: StandardMaterial3D) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = pos
	add_child(mi)
	meshes.append(mi)
	return mi
