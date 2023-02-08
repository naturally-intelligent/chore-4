extends Node

var title = 'Chore Engine'
var subtitle = ''
var version = '1.4'
var state = ''
var release = false
var year = '2022-2023'

var demo = true
var website = "https://www.naturallyintelligent.com"

# option: manually lock in your desired pixel resolution here
@onready var pixel_width = ProjectSettings.get_setting("display/window/size/viewport_width")
@onready var pixel_height = ProjectSettings.get_setting("display/window/size/viewport_height")

var launch_menu = 'main'
var main_menu = 'main'

# OPTIONAL SAMPLE DATA
# - You don't need any of this below, it's just for fun

var default_level = 'first-level'
var last_level = default_level
var levels = {
	1: 'first-level',
}

# saved in settings but used here (diff games might have differing levels of difficulty)
enum DIFFICULTY {EASY=-1, NORMAL=0, MEDIUM=0, HARD=1}
var difficulty = DIFFICULTY.NORMAL

# dont change here, set in dev. or from settings file
var invincible = false # cant be hurt
var invisible = false # cant be seen
var intangible = false # walk through walls
var infinite = false # infinite wealth/resources
var weightless = false # not affected by gravity

var damage_multiplier = 1.0

# pointers
var nodes = {}

# current level scores
var scores = {}

# WORLD STATS + DATA
var player = {}
var scoreboard = {}
var scoreboard_sorted = {}
var strings = {
	'card': "Player Card",
}
var descriptions = {
	'card': "Play a card!",
}
var facts = {}

var current_save_file = false

func _init():
	seed(title.hash())
	randomize()

func _ready():
	on_new_game()
	data_structure()
	
func data_structure():
	pass

func sort_scoreboard():
	scoreboard_sorted = {}
	
func on_new_game():
	reset_scores()
	
func on_new_level():
	reset_scores()
	
func reset_scores():
	scores['player1'] = 0

func massage_label(label):
	label.text = label.text.replace('YEAR', year)
	label.text = label.text.replace('VER', 'v'+version)	

func word(origin):
	if origin in game.strings:
		return game.strings[origin]
	return str(origin)

func description(origin):
	if origin in game.descriptions:
		return game.descriptions[origin]
	return str(origin)

func name(word_id):
	if word_id in game.names:
		return game.names[word_id]
	return word_id

# FACTS
func fact(fact):
	if fact in facts:
		return facts[fact]
	else:
		return false

func flip_fact(fact, default=false):
	if fact in facts:
		facts[fact] = not facts[fact]
	else:
		facts[fact] = default
	return facts[fact]

func set_fact(fact, value):
	#print('set_fact(',fact,' ', value)
	facts[fact] = value

# TIME FACTOR (required by root)

func time(time):
	return time
