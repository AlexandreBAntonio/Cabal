class_name PlayerRig
extends Node3D
## Corpo articulado do Gladiador construído por código: armadura, elmo com
## crista, capa e espadão. Placeholder de alta qualidade até os modelos reais
## (Mixamo) — a view anima as juntas expostas aqui.

var body: Node3D          ## raiz do corpo (bob/respiração)
var head: Node3D
var arm_l: Node3D         ## pivôs nos ombros
var arm_r: Node3D
var leg_l: Node3D         ## pivôs no quadril
var leg_r: Node3D
var sword: Node3D

var _armor := StandardMaterial3D.new()
var _cloth := StandardMaterial3D.new()
var _cape := StandardMaterial3D.new()
var _steel := StandardMaterial3D.new()
var _skin := StandardMaterial3D.new()
var _blade := StandardMaterial3D.new()

func _ready() -> void:
	_armor.albedo_color = Color(0.30, 0.42, 0.72)
	_armor.metallic = 0.75
	_armor.roughness = 0.35
	_armor.rim_enabled = true
	_armor.rim = 0.5
	_cloth.albedo_color = Color(0.15, 0.16, 0.21)
	_cloth.roughness = 0.9
	_cape.albedo_color = Color(0.55, 0.12, 0.12)
	_cape.roughness = 0.85
	_steel.albedo_color = Color(0.8, 0.85, 0.95)
	_steel.metallic = 0.9
	_steel.roughness = 0.22
	_skin.albedo_color = Color(0.85, 0.66, 0.5)
	_skin.roughness = 0.7
	_blade.albedo_color = Color(0.85, 0.9, 1.0)
	_blade.metallic = 0.9
	_blade.roughness = 0.15
	_blade.emission_enabled = true
	_blade.emission = Color(0.4, 0.65, 1.0)
	_blade.emission_energy_multiplier = 0.5
	_build()

## Berserk: armadura incandesce em vermelho.
func set_berserk(active: bool) -> void:
	_armor.emission_enabled = true
	_armor.emission = Color(1.0, 0.15, 0.1)
	_armor.emission_energy_multiplier = 1.1 if active else 0.0

func _build() -> void:
	body = Node3D.new()
	body.name = "Body"
	add_child(body)

	# pernas (pivô no quadril, malha desce até o pé)
	leg_l = _limb(Vector3(-0.13, 0.95, 0.0), Vector3(0.15, 0.92, 0.18), _cloth)
	leg_r = _limb(Vector3(0.13, 0.95, 0.0), Vector3(0.15, 0.92, 0.18), _cloth)
	_box(leg_l, Vector3(0.0, -0.88, 0.05), Vector3(0.16, 0.1, 0.3), _armor)   # bota
	_box(leg_r, Vector3(0.0, -0.88, 0.05), Vector3(0.16, 0.1, 0.3), _armor)

	# tronco: peitoral, cinto, capa
	_box(body, Vector3(0.0, 1.28, 0.0), Vector3(0.46, 0.54, 0.28), _armor)
	_box(body, Vector3(0.0, 0.97, 0.0), Vector3(0.38, 0.14, 0.24), _cloth)
	_box(body, Vector3(0.0, 1.3, 0.2), Vector3(0.42, 0.85, 0.03), _cape)

	# ombreiras
	_sphere(body, Vector3(-0.3, 1.52, 0.0), 0.12, _armor)
	_sphere(body, Vector3(0.3, 1.52, 0.0), 0.12, _armor)

	# cabeça + elmo com crista
	head = Node3D.new()
	head.position = Vector3(0.0, 1.68, 0.0)
	body.add_child(head)
	_sphere(head, Vector3.ZERO, 0.14, _skin)
	_box(head, Vector3(0.0, 0.09, 0.0), Vector3(0.24, 0.12, 0.26), _armor)
	_box(head, Vector3(0.0, 0.2, -0.02), Vector3(0.05, 0.14, 0.3), _cape)

	# braços (pivô no ombro)
	arm_l = _limb(Vector3(-0.33, 1.48, 0.0), Vector3(0.11, 0.58, 0.13), _armor)
	arm_r = _limb(Vector3(0.33, 1.48, 0.0), Vector3(0.11, 0.58, 0.13), _armor)

	# espadão na mão direita (aponta pra baixo em repouso)
	sword = Node3D.new()
	sword.position = Vector3(0.0, -0.58, 0.0)
	arm_r.add_child(sword)
	_box(sword, Vector3(0.0, 0.02, 0.0), Vector3(0.05, 0.14, 0.05), _cloth)    # punho
	_box(sword, Vector3(0.0, -0.06, 0.0), Vector3(0.24, 0.045, 0.07), _steel)  # guarda
	_box(sword, Vector3(0.0, -0.55, 0.0), Vector3(0.08, 0.9, 0.025), _blade)   # lâmina

func _limb(pivot_pos: Vector3, size: Vector3, mat: StandardMaterial3D) -> Node3D:
	var pivot := Node3D.new()
	pivot.position = pivot_pos
	body.add_child(pivot)
	_box(pivot, Vector3(0.0, -size.y * 0.5, 0.0), size, mat)
	return pivot

func _box(parent: Node3D, pos: Vector3, size: Vector3, mat: StandardMaterial3D) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = pos
	parent.add_child(mi)
	return mi

func _sphere(parent: Node3D, pos: Vector3, radius: float, mat: StandardMaterial3D) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = pos
	parent.add_child(mi)
	return mi
