extends Node

class_name UpgradeManager

var upgrades = {
	"Purple Laser": {
		"descriptions": [
			"+1 Projectile Count.",
			"+10 Damage.\n+10 Speed.",
			"+1 Projectile Count.\n+10 Damage.\n+20 Speed.",
			"+10 Damage.\n+20 Speed.",
			"+1 Projectile Count."
		],
		"max_level": 5
	},
	"Damage": {
		"descriptions": [
			"Increases player damage by 10.",
			"Increases player damage by 10.",
			"Increases player damage by 10.",
			"Increases player damage by 10.",
			"Increases player damage by 10."
		],
		"max_level": 5
	},
	"Health": {
		"descriptions": [
			"Increases player max health by 20.",
			"Increases player max health by 20.",
			"Increases player max health by 20.",
			"Increases player max health by 20.",
			"Increases player max health by 20."
		],
		"max_level": 5
	},
	"Shuriken": {
		"descriptions": [
			"Unlocks the Shuriken.",
			"+1 Projectile Count.",
			"+1 Projectile Count.",
			"+1 Projectile Count.\nIncreased rotation speed.",
			"+1 Projectile Count.\nIncreased rotation speed."
		],
		"max_level": 5
	},
	"Move Speed": {
		"descriptions": [
			"+10 Move Speed.",
			"+10 Move Speed.",
			"+10 Move Speed.",
			"+10 Move Speed.",
			"+10 Move Speed."
		],
		"max_level": 5
	},
	"Fireball": {
		"descriptions": [
			"Unlocks the Fireball.",
			"+10 Damage.\n+30 Projectile Speed.",
			"+1 Projectile Count.\n+10 Damage.\n+50 Projectile Speed.",
			"+10 Damage.\n+50 Projectile Speed.",
			"+1 Projectile Count.\n+10 Damage.\n+50 Projectile Speed."
		],
		"max_level": 5
	},
	"Health Regen": {
		"descriptions": [
			"Increases player health regeneration by 0.1.",
			"Increases player health regeneration by 0.1.",
			"Increases player health regeneration by 0.1.",
			"Increases player health regeneration by 0.1.",
			"Increases player health regeneration by 0.1."
		],
		"max_level": 5
	},
	"Attack Speed": {
		"descriptions": [
			"Increases player attack speed.",
			"Increases player attack speed.",
			"Increases player attack speed.",
			"Increases player attack speed.",
			"Increases player attack speed."
		],
		"max_level": 5
	},
	"Knife": {
		"descriptions": [
			"Unlocks the Knife.",
			"+1 Projectile Count.\nIncreased projectile speed.\n+5 Damage",
			"+1 Projectile Count.\nIncreased projectile speed.\n+5 Damage",
			"+1 Projectile Count.\nIncreased projectile speed.\n+5 Damage",						
			"+1 Projectile Count.\nIncreased projectile speed.\n+5 Damage",
		],
		"max_level": 5
	},
}

func get_description(upgrade_name: String, level: int) -> String:
	if upgrades.has(upgrade_name):
		var descriptions = upgrades[upgrade_name].descriptions
		return descriptions[min(level, descriptions.size() - 1)]
	return "Unknown upgrade"

func get_max_level(upgrade_name: String) -> int:
	if upgrades.has(upgrade_name):
		return upgrades[upgrade_name].max_level
	return 1
