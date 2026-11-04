extends RefCounted
## Auto-generated from ROBOT.obj (see characters/reza_robot). Rigid parts, pivots in metres.

const HIP_Y := 1.0230
const PIVOTS := {
	"arm_r": Vector3(-0.2585, 0.4840, 0.0055),
	"arm_l": Vector3(0.2585, 0.4840, 0.0055),
	"leg_r": Vector3(-0.1650, 1.0230, 0.0000),
	"leg_l": Vector3(0.1650, 1.0230, 0.0000),
}

# [bone, material, file]
const PARTS := [
	["torso", "BODY", "res://characters/reza_robot/torso__BODY.obj"],
	["leg_l", "BODY", "res://characters/reza_robot/leg_l__BODY.obj"],
	["leg_r", "BODY", "res://characters/reza_robot/leg_r__BODY.obj"],
	["torso", "BODY2", "res://characters/reza_robot/torso__BODY2.obj"],
	["arm_l", "BODY2", "res://characters/reza_robot/arm_l__BODY2.obj"],
	["leg_l", "BODY2", "res://characters/reza_robot/leg_l__BODY2.obj"],
	["arm_r", "BODY2", "res://characters/reza_robot/arm_r__BODY2.obj"],
	["leg_r", "BODY2", "res://characters/reza_robot/leg_r__BODY2.obj"],
	["arm_r", "BODY", "res://characters/reza_robot/arm_r__BODY.obj"],
	["arm_l", "BODY", "res://characters/reza_robot/arm_l__BODY.obj"],
	["torso", "JACKET.002", "res://characters/reza_robot/torso__JACKET_002.obj"],
	["arm_r", "JACKET.002", "res://characters/reza_robot/arm_r__JACKET_002.obj"],
	["arm_l", "JACKET.002", "res://characters/reza_robot/arm_l__JACKET_002.obj"],
	["torso", "LOGO.002", "res://characters/reza_robot/torso__LOGO_002.obj"],
	["arm_r", "LOGO", "res://characters/reza_robot/arm_r__LOGO.obj"],
	["arm_l", "LOGO", "res://characters/reza_robot/arm_l__LOGO.obj"],
	["torso", "GLOW", "res://characters/reza_robot/torso__GLOW.obj"],
	["torso", "METAL", "res://characters/reza_robot/torso__METAL.obj"],
]
