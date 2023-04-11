class_name TurnMachine extends Timer

signal start_game
signal end_game(player)
signal pre_init_turn(player: int)
signal init_turn(player: int)
signal main_turn(player: int)
signal end_turn(player: int)

const TURN_TIME = 5.0
const COOK_FUSION_TIME = 0.15
const COOK_ACCELR_TIME = 0.15

enum State {PRE_INIT, INIT, MAIN, END}
enum Players {A, B}

var current_player: Players = randi() % Players.size() as Players

var current_stage: State:
	set(value):
		current_stage = value
		
		match current_stage:
			State.PRE_INIT:
				await ElementEffectManager.call_effects(
						current_player as PlayerController.Players,
						ElementEffectManager.SkillType.PRE_INIT_PHASE
				)
				await get_tree().create_timer(0.2).timeout # teste
				pre_init_turn.emit(current_player)
				next_phase()
			
			State.INIT:
				await ElementEffectManager.call_effects(
						current_player as PlayerController.Players,
						ElementEffectManager.SkillType.INIT_PHASE
				)
				await cook()
				await get_tree().create_timer(0.2).timeout # teste
				init_turn.emit(current_player)
				next_phase()
			
			State.MAIN:
				await ElementEffectManager.call_effects(
						current_player as PlayerController.Players,
						ElementEffectManager.SkillType.MAIN_PHASE
				)
				start(1 if current_player == 1 else 20)
				if not timeout.is_connected(_main_phase_timeout):
					timeout.connect(_main_phase_timeout, CONNECT_ONE_SHOT)
				main_turn.emit(current_player)
			
			State.END:
				await ElementEffectManager.call_effects(
						current_player as PlayerController.Players,
						ElementEffectManager.SkillType.END_PHASE
				)
				await get_tree().create_timer(0.2).timeout # teste
				end_turn.emit(current_player)
				next_phase()


@onready var arena: Arena = $"../arena"


func _ready():
	await get_tree().create_timer(1).timeout
	start_turn()


func start_turn():
	start_game.emit()
	self.current_stage = State.PRE_INIT


func next_phase():
	if not is_stopped():
		if timeout.is_connected(_main_phase_timeout):
			timeout.disconnect(_main_phase_timeout)
		stop()
	
	if current_stage == State.END:
		current_player = (current_player + 1) % Players.size() as Players
	
	self.current_stage = (current_stage + 1) % State.size() as State


## os slots
## 8 e 10:  acler B
## 9 e 11:  fusao B
## 12 e 14: fusao A
## 13 e 15: acler A

func cook():
	var slot: int = 12 if current_player == Players.A else 9
	
	var slot_fusion_A = Vector2i(slot, 0)
	var slot_fusion_B = Vector2i(slot + 2, 0)
	
	var slot_accelr_A = Vector2i(slot, 4)
	var slot_accelr_B = Vector2i(slot + 2, 4)
	
	if arena.elements.has(slot_fusion_A) and arena.elements.has(slot_fusion_B):
		await arena.fusion_elements(slot_fusion_A, slot_fusion_B, slot, current_player as PlayerController.Players)
	
	if arena.elements.has(slot_accelr_A) and arena.elements.has(slot_accelr_B):
		await arena.accelr_elements(slot_accelr_A, slot_accelr_B, slot, current_player as PlayerController.Players)


func _main_phase_timeout():
	next_phase()


func _arena_end_game(winner):
	stop()


func _end_game(player):
	stop()
	get_tree().quit()
