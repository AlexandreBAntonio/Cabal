class_name SkillData
extends Resource
## Definição de skill como Resource (.tres). Nada de skill hardcoded em script
## de personagem: o GladiatorSim executa qualquer SkillData genericamente.

enum Type { MELEE_SINGLE, MELEE_AOE, BUFF, DASH }

@export var display_name := ""
@export var type: Type = Type.MELEE_SINGLE
@export var damage := 0.0
@export var hits := 1                     ## nº de hits (Whirlwind = 3)
@export var mp_cost := 0.0
@export var cooldown := 1.0
@export var reach := 3.0                  ## alcance p/ single-target e dash
@export var aoe_radius := 0.0
@export var aoe_forward_offset := 0.0     ## Earthquake: centro da área à frente
@export var cast_time := 0.4              ## zerado quando encadeada em combo
@export var duration := 0.0               ## Whirlwind (canal) / Berserk (buff)
@export var stun_duration := 0.0          ## stun/stagger aplicado ao(s) alvo(s)
@export var dash_distance := 0.0
@export var buff_damage_mult := 1.0
@export var buff_attack_speed_mult := 1.0
@export var heavy_hit := false            ## hit stop maior + screen shake
