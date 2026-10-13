extends Node3D
## User's earlier Alpha 4 tactile table, but TRUE Jolt-contact-driven.
## Dense visual-only textile skin. The real StaticBody3D remains unchanged.
const LIFE_SECONDS := 0.25
const MIN_IMPACT_SPEED := 0.16
const MAX_VISUAL_AMPLITUDE := 0.012

var impact_count := 0
var active := false
var last_impact_world := Vector3.ZERO
var last_contact_speed := 0.0
var _surface_width := 6.42
var _surface_length := 10.42
var _age := LIFE_SECONDS
var _skin: MeshInstance3D
var _material: ShaderMaterial
var _felt_albedo: Texture2D
var _felt_normal: Texture2D

func configure(width: float, length: float, albedo: Texture2D, normal: Texture2D) -> void:
    _surface_width = width
    _surface_length = length
    _felt_albedo = albedo
    _felt_normal = normal

func _ready() -> void:
    _skin = MeshInstance3D.new()
    _skin.name = "VisualOnlyTessellatedFelt"
    var plane := PlaneMesh.new()
    plane.size = Vector2(_surface_width, _surface_length)
    plane.subdivide_width = 64
    plane.subdivide_depth = 92
    plane.material = null
    _skin.mesh = plane
    _skin.position.y = -0.039
    _skin.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    _material = ShaderMaterial.new()
    _material.shader = preload("res://src/visual/velvet_contact.gdshader")
    _material.set_shader_parameter("felt_albedo",_felt_albedo)
    _material.set_shader_parameter("felt_normal",_felt_normal)
    _material.set_shader_parameter("impact_progress",1.0)
    _material.set_shader_parameter("impact_strength",0.0)
    _skin.material_override = _material
    add_child(_skin)
    set_process(false)

func register_impact(point: Vector3, speed: float, mass: float) -> bool:
    # A no-contact idle timer has no access to this method. The main/pool
    # calls it ONLY from a RigidBody3D body_entered("VelvetTable") signal.
    if not is_inside_tree() or speed < MIN_IMPACT_SPEED or mass <= 0.0:
        return false
    if absf(point.x) > _surface_width * 0.5 or absf(point.z) > _surface_length * 0.5:
        return false
    if _material == null:
        return false
    impact_count += 1
    last_impact_world = point
    last_contact_speed = speed
    _age = 0.0
    active = true
    _material.set_shader_parameter("contact_center",Vector2(point.x,point.z))
    # A bounded speed*mass response, not a fixed cosmetic loop.
    _material.set_shader_parameter("impact_strength",clampf(speed * mass * 6.0,0.18,0.95))
    _material.set_shader_parameter("impact_progress",0.0)
    set_process(true)
    return true

func _process(delta: float) -> void:
    if not active:
        return
    _age = minf(_age + delta,LIFE_SECONDS)
    _material.set_shader_parameter("impact_progress",_age / LIFE_SECONDS)
    if _age >= LIFE_SECONDS:
        active = false
        _material.set_shader_parameter("impact_strength",0.0)
        set_process(false)
