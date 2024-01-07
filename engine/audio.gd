# AUDIO - Chore Engine's Audio Helper Component
extends Node

# SOUND BUS
@onready var _sound_bus_index = AudioServer.get_bus_index(settings.sound_bus_name)
@onready var _music_bus_index = AudioServer.get_bus_index(settings.music_bus_name)

var sounds := {}
var sound_dirs = settings.sound_dirs
var history := {}
var ambience_timers := {}
var file_locations := {}
var current_song := ''
var missing_files := []
var paused_sounds := {}
var music_position = false

var fade_in_music_tween: Tween
var fade_out_music_tween: Tween

const silent_db = -60

signal music_volume_changed()
signal sound_volume_changed()

func _ready():
	set_sound_volume(settings.sound_volume)
	set_music_volume(settings.music_volume)

### SOUNDS

func play_sound(sound_name: String, volume:=1.0, allow_multiple:=false, pitch:={}):
	if dev.silence: return
	# find sound resource link (res://dir/file.ext)
	var resource_link = _sound_resource(sound_name)
	if resource_link == '':
		return null
	# find a sound player
	var player: AudioStreamPlayer
	# stop prior sounds
	if not allow_multiple:
		if _stop_sound_resource(resource_link):
			player = _find_loaded_sound_player(resource_link)
	# find a sound player
	if not player:
		player = _find_empty_sound_player()
	if not player:
		return null
	var stream = load(resource_link)
	if not stream:
		debug.print('ERROR: Bad Audio Stream load failed', resource_link)
		return null
	player.set_stream(stream)
	if pitch:
		var pitch_start = pitch[0]
		var pitch_end = pitch[1]
		var pitch_step = pitch[2]
		player.pitch_scale = math.random_float_step(pitch_start, pitch_end, pitch_step)
	else:
		player.pitch_scale = 1.0
	player.volume_db = convert_percent_to_db(volume)
	player.set_meta('resource_link', resource_link)
	player.play()
	return player

func is_sound_playing(sound_name):
	var resource_link = _sound_resource(sound_name)
	return _is_sound_resource_playing(resource_link)

func is_sound_looping(sound_name):
	var resource_link = _sound_resource(sound_name)
	return _is_sound_resource_looping(resource_link)

func stop_sound(sound_name):
	var resource_link = _sound_resource(sound_name)
	_stop_sound_resource(resource_link)

func loop_sound(sound_name: String, volume:=1.0, fade_in:=false, fade_in_time:=0.5):
	if dev.silence: return
	# find sound resource link (res://dir/file.ext)
	var resource_link = _sound_resource(sound_name)
	if resource_link == '':
		return null
	# find a sound player
	var player: AudioStreamPlayer
	# stop prior sounds
	if _stop_sound_resource(resource_link):
		player = _find_loaded_sound_looper(resource_link)
	# find a sound player
	if not player:
		player = _find_empty_sound_looper()
	if not player:
		return null
	var stream = load(resource_link)
	if not stream:
		debug.print('ERROR: Bad Audio Loop load failed', resource_link)
		return null
	player.set_stream(stream)
	player.volume_db = convert_percent_to_db(volume)
	player.pitch_scale = 1.0
	player.set_meta('resource_link', resource_link)
	if not player.is_connected("finished", Callable(self,"_on_loop_sound")):
		player.connect("finished", Callable(self,"_on_loop_sound").bind(player))
	player.play()
	if fade_in:
		var desired_db = player.volume_db
		player.volume_db = silent_db
		var tween = create_tween()
		tween.set_trans(Tween.TRANS_CUBIC)
		tween.set_ease(Tween.EASE_OUT)
		tween.tween_property(player, "volume_db", desired_db, fade_in_time)
	return player

func fade_in_sound(sound_name: String, volume:=1.0, fade_in_time:=1.5):
	var player = play_sound(sound_name, volume)
	if player:
		var desired_db = player.volume_db
		player.volume_db = silent_db
		var tween = create_tween()
		tween.set_trans(Tween.TRANS_CUBIC)
		tween.set_ease(Tween.EASE_OUT)
		tween.tween_property(player, "volume_db", desired_db, fade_in_time)
	return player

func fade_in_loop_sound(sound_name: String, volume:=1.0, fade_in_time:=1.5):
	loop_sound(sound_name, volume, true, fade_in_time)

func fade_out_sound(sound_name: String, fade_out_time:=1.0):
	var resource_link = _sound_resource(sound_name)
	if resource_link == '':
		return false
	var containers = [$SoundPlayers, $SoundLoopers]
	for container in containers:
		for player in container.get_children():
			if player.playing and player.get_meta('resource_link') == resource_link:
				if player.has_meta('fading'):
					continue
				player.set_meta('fading', true)
				call_deferred("_fade_out_sound_player", player, fade_out_time)

### SOUNDS - INTERNAL CALLS

func _sound_resource(sound_name: String) -> String:
	if sound_name in file_locations:
		return file_locations[sound_name]
	if util.file_exists(sound_name):
		return sound_name
	var file_name = _find_sound_file(sound_name)
	if file_name:
		file_locations[sound_name] = file_name
		return file_name
	if sound_name in settings.sound_alias:
		var alias_name = settings.sound_alias[sound_name]
		if alias_name:
			var file_name2 = _find_sound_file(alias_name)
			if file_name2:
				file_locations[sound_name] = file_name2
			return file_name2
	if not sound_name in missing_files:
		debug.print("SOUND FILE MISSING:",sound_name)
		missing_files.append(sound_name)
	return ''

func _find_sound_file(sound_name):
	for dir in settings.sound_dirs:
		var file_name = 'res://' + dir + '/' + sound_name + settings.sound_ext
		if util.file_exists(file_name) or util.file_exists(file_name+".import"):
			return file_name
	return ''

func _find_empty_sound_player():
	for child in $SoundPlayers.get_children():
		var player: AudioStreamPlayer = child
		if not player.playing:
			return player
	return $SoundPlayers/SoundPlayer1

func _find_loaded_sound_player(resource_link):
	for child in $SoundPlayers.get_children():
		if child.has_meta('resource_link') and child.get_meta('resource_link') == resource_link:
			return child
	return null

func _is_sound_resource_playing(resource_link):
	for child in $SoundPlayers.get_children():
		var player: AudioStreamPlayer = child
		if player.playing and player.has_meta('resource_link') and player.get_meta('resource_link') == resource_link:
			return true
	for child in $SoundLoopers.get_children():
		var player: AudioStreamPlayer = child
		if player.playing and player.has_meta('resource_link') and player.get_meta('resource_link') == resource_link:
			return true
	return false

func _find_empty_sound_looper():
	for child in $SoundLoopers.get_children():
		var player: AudioStreamPlayer = child
		if not player.playing:
			return player
	return $SoundLoopers/SoundPlayer1

func _find_loaded_sound_looper(resource_link):
	for child in $SoundLoopers.get_children():
		if child.has_meta('resource_link') and child.get_meta('resource_link') == resource_link:
			return child
	return null

func _is_sound_resource_looping(resource_link):
	for child in $SoundLoopers.get_children():
		var player: AudioStreamPlayer = child
		if player.playing and player.get_meta('resource_link') == resource_link:
			return true
	return false

func _stop_sound_resource(resource_link):
	var stopped = false
	var containers = [$SoundPlayers, $SoundLoopers]
	for container in containers:
		for player in container.get_children():
			if player.playing and player.get_meta('resource_link') == resource_link:
				player.stream_paused = true
				player.stop()
				stopped = true
				paused_sounds.erase(player)
	return stopped

func _fade_out_sound_player(player, fade_out_time):
	var tween = create_tween()
	tween.set_ease(Tween.EASE_IN)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(player, "volume_db", silent_db, fade_out_time)
	await tween.finished
	player.playing = false
	player.remove_meta('fading')

func _on_loop_sound(player):
	player.stream_paused = false
	player.play()

### SOUND ADDITONAL

func play_distant_sound(sound_name: String, base_volume:float, origin:Vector2, listener:Vector2):
	var volume = base_volume
	var distance = listener.distance_to(origin)
	# todo: cleanup in settings
	var distance_multi = distance/80
	if distance_multi < 1: distance_multi = 1
	volume /= distance_multi
	if distance > 300:
		return
	play_sound(sound_name, volume)

func play_once(sound_name, volume=1.0):
	return play_sound(sound_name, volume, true)

func play_random_sound(sound_name, total, volume=1.0, pitch={}):
	if dev.silence: return
	var c = math.random_int(1,total)
	return play_sound(sound_name + str(c), volume, false, pitch)

func play_sound_pitched(sound_name, pitch_start=0.8, pitch_end=1.2, pitch_step:=0.02):
	var player = play_sound(sound_name)
	if player:
		player.pitch_scale = math.random_float_step(pitch_start, pitch_end, pitch_step)

func play_ambience_sound(sound_name, total=1, origin=false, listener=false, time=0.33, random=true):
	if dev.silence: return
	var timer: Timer
	if not sound_name in ambience_timers:
		timer = Timer.new()
		timer.one_shot = true
		timer.autostart = false
		$Timers.add_child(timer)
		ambience_timers[sound_name] = timer
	else:
		timer = ambience_timers[sound_name]
	if timer.is_stopped():
		if total == 1:
			play_sound(sound_name, 1.0)
		else:
			play_random_sound(sound_name, total, 1.0)
		if random:
			time = math.random_float(time/2,time+time/2)
		timer.start(time)

func play_sound_if_not(sound_name, volume=1.0):
	if not is_sound_playing(sound_name):
		play_sound(sound_name, volume, false)

func delayed_sound(sound_name, time, volume=1.0):
	if dev.silence: return
	# todo: more timers
	if $Timers/DelayedTimer1.is_connected("timeout",Callable(self,"play_sound")):
		$Timers/DelayedTimer1.disconnect("timeout",Callable(self,"play_sound"))
	$Timers/DelayedTimer1.connect("timeout",Callable(self,"play_sound").bind(sound_name, volume))
	$Timers/DelayedTimer1.wait_time = time
	$Timers/DelayedTimer1.start()

func stop_all_sounds():
	for sound in $SoundPlayers.get_children():
		sound.stop()
		sound.playing = false
	for looper in $SoundLoopers.get_children():
		if not dev.silence:
			if looper.is_connected("finished",Callable(self,"_on_loop_sound")):
				looper.disconnect("finished",Callable(self,"_on_loop_sound"))
		looper.stop()
		looper.playing = false
	history = {}
	paused_sounds = {}

func pause_sounds():
	for sound in $SoundPlayers.get_children():
		if sound.playing:
			paused_sounds[sound] = sound.get_playback_position()
			sound.stop()
			sound.playing = false
	for looper in $SoundLoopers.get_children():
		if looper.playing:
			paused_sounds[looper] = looper.get_playback_position()
			looper.stop()
			looper.playing = false

func resume_sounds():
	for sound in paused_sounds:
		var seek = paused_sounds[sound]
		sound.play()
		sound.seek(seek)
	paused_sounds = {}

func rogue(player, load_with_sound_name=''):
	# play a rogue sound from an external player, with help from this class
	if dev.silence: return
	# load with sound from settings?
	if load_with_sound_name != '':
		var resource_link = _sound_resource(load_with_sound_name)
		if not player.has_meta('resource_link') or player.get_meta('resource_link') != resource_link:
			player.set_meta('resource_link', resource_link)
			var stream = load(resource_link)
			if not stream:
				debug.print('ERROR: Bad Audio Stream external load failed', resource_link)
				return false
			player.set_stream(stream)
	player.play()
	return true

func play_random_node(player, sound_name, total):
	if dev.silence: return
	var c = math.random_int(1,total)
	return rogue(player, sound_name + str(c))

###
### MUSIC
###

func play_music(song_name:String, volume:=1.0, resume_if_previous:=true, and_stop_music:=true, loop:=true):
	if dev.silence: return
	if dev.no_music: return
	if dev.skip_first_song:
		dev.skip_first_song = false
		return
	#debug.print('play_music', song_name)
	var resource_link = _music_resource(song_name)
	if resource_link == '':
		if not song_name in missing_files:
			debug.print("MUSIC FILE FAILED TO LOAD:",song_name)
			missing_files.append(song_name)
		return false
	# volume in settings
	if volume == 1.0:
		volume = _get_volume_for_song(song_name)
	# check if already loaded same song
	if current_song != '' and $MusicPlayer.has_meta('resource_link'):
		if $MusicPlayer.get_meta('resource_link') == resource_link:
			#debug.print("resuming song")
			current_song = song_name
			if resume_if_previous:
				if $MusicPlayer.is_playing() and not $MusicPlayer.stream_paused:
					return true
				$MusicPlayer.play($MusicPlayer.get_playback_position())
			else:
				$MusicPlayer.seek(0)
				$MusicPlayer.play(0)
			#$MusicPlayer.seek($MusicPlayer.get_stream().get_length()-3)
			$MusicPlayer.volume_db = convert_percent_to_db(volume)
			$MusicPlayer.stream_paused = false
			return true
	# stop
	if and_stop_music:
		stop_and_reset_music()
	# load stream
	var stream = load(resource_link)
	if stream:
		$MusicPlayer.volume_db = convert_percent_to_db(volume)
		$MusicPlayer.set_stream(stream)
		$MusicPlayer.stream_paused = false
		$MusicPlayer.play()
		#$MusicPlayer.seek(stream.get_length()-3)
		$MusicPlayer.set_meta("resource_link", resource_link)
		current_song = song_name
		return true
	else:
		if not resource_link in missing_files:
			debug.print("ERROR Loading Music Stream:",resource_link)
			missing_files.append(resource_link)
	return false

func force_music(song_name:String, volume:=1.0):
	play_music(song_name, volume, false)

func is_music_playing(song_name=''):
	if song_name == '':
		return $MusicPlayer.is_playing() and not $MusicPlayer.stream_paused
	else:
		var resource_link = _music_resource(song_name)
		if $MusicPlayer.is_playing() and $MusicPlayer.get_meta('resource_link') == resource_link:
			return not $MusicPlayer.stream_paused
	return false

func pause_music():
	#debug.print('pause_music')
	stop_music_animations()
	if $MusicPlayer.is_playing():
		music_position = $MusicPlayer.get_playback_position()
		$MusicPlayer.stream_paused = true

func resume_music(fade_in=false):
	if dev.no_music: return
	#debug.print('resume_music')
	if current_song != '' and $MusicPlayer.stream_paused:
		stop_music_animations()
		$MusicPlayer.stream_paused = false
		#if music_position:
		#	$MusicPlayer.seek(music_position)
		if fade_in:
			fade_in_music(current_song, 1.0, false)

func stop_music():
	#debug.print('stop_music')
	stop_music_animations()
	$MusicPlayer.stop()
	$MusicPlayer.stream_paused = false
	$MusicPlayer.set_stream(null)
	$MusicPlayer.set_meta('resource_link', '')
	music_position = false
	current_song = ''

func stop_and_reset_music():
	stop_music()
	set_music_volume(settings.music_volume)

func stop_music_animations():
	if fade_in_music_tween:
		fade_in_music_tween.kill()
	if fade_out_music_tween:
		fade_out_music_tween.kill()

func fade_in_music(song_name, _fade_in_time:=1.0, _do_play:=true, _stop_music:=true):
	if dev.no_music: return
	#debug.print('fade_in_music')
	if _do_play:
		if _stop_music:
			stop_and_reset_music()
		play_music(song_name, 1.0, false, _stop_music)
	var target_volume = _get_volume_for_song(song_name)
	var target_db = convert_percent_to_db(target_volume)
	$MusicPlayer.volume_db = silent_db
	if _stop_music:
		stop_music_animations()
	fade_in_music_tween = create_tween()
	fade_in_music_tween.set_ease(Tween.EASE_OUT)
	fade_in_music_tween.set_trans(Tween.TRANS_CUBIC)
	fade_in_music_tween.tween_property($MusicPlayer, "volume_db", target_db, _fade_in_time)

func fade_out_music(_fade_out_time:=0.5):
	#debug.print('fade_out_music')
	if not is_music_playing():
		return
	# TWEEN STYLE
	stop_music_animations()
	fade_out_music_tween = create_tween()
	fade_out_music_tween.set_ease(Tween.EASE_IN)
	fade_out_music_tween.set_trans(Tween.TRANS_CUBIC)
	fade_out_music_tween.tween_property($MusicPlayer, "volume_db", silent_db, _fade_out_time)
	await fade_out_music_tween.finished
	#debug.print('faded_out_music')
	stop_music()

func fade_out_in_music(song_name, _fade_out_time:=0.5, _fade_in_time:=1.0):
	#debug.print('fade_out_in_music')
	if is_music_playing():
		fade_out_music(_fade_out_time)
		await fade_out_music_tween.finished
	fade_in_music(song_name, _fade_in_time, true, false)

func is_playing_music_pool(pool_name):
	if not pool_name in settings.music_pools:
		debug.print("WARNING: Missing Music Pool:", pool_name)
		return false
	for track_name in settings.music_pools[pool_name]:
		if current_song == track_name:
			return true
		if is_music_playing(track_name):
			return true
	return false

func get_music_player():
	return $MusicPlayer

func get_song_alias(song_name):
	if song_name in settings.tracklist:
		if typeof(settings.tracklist[song_name]) == TYPE_STRING:
			song_name = settings.tracklist[song_name]
	return song_name

func seek_music(time: float):
	if $MusicPlayer.is_playing():
		$MusicPlayer.seek(time)

### MUSIC - INTERNAL

func _get_volume_for_song(song_name):
	var volume = 1.0
	if song_name in settings.tracklist:
		if typeof(settings.tracklist[song_name]) == TYPE_STRING:
			song_name = settings.tracklist[song_name]
	if song_name in settings.music_alias:
		song_name = settings.music_alias[song_name]
	return volume

func _music_resource(song_name: String) -> String:
	if song_name in file_locations:
		return file_locations[song_name]
	if util.file_exists(song_name):
		return song_name
	if song_name in settings.tracklist:
		if typeof(settings.tracklist[song_name]) == TYPE_STRING:
			song_name = settings.tracklist[song_name]
		elif typeof(settings.tracklist[song_name]) == TYPE_ARRAY: # random selection
			song_name = util.random_array(settings.tracklist[song_name])
	if song_name in settings.music_alias:
		song_name = settings.music_alias[song_name]
	for dir in settings.music_dirs:
		var file_name_ext = 'res://' + dir + '/' + song_name + settings.music_ext
		if util.file_exists(file_name_ext) or util.file_exists(file_name_ext+".import"):
			return file_name_ext
		var file_name = 'res://' + dir + '/' + song_name
		if util.file_exists(file_name) or util.file_exists(file_name+".import"):
			return file_name
	return ''

# VOLUMES

func convert_percent_to_db(amount):
	return 12.5 * log(amount)

func set_sound_volume(amount):
	if dev.silence: amount = 0.0
	var db = convert_percent_to_db(amount)
	AudioServer.set_bus_volume_db(_sound_bus_index, db)
	emit_signal("sound_volume_changed", db)

func set_music_volume(amount):
	if dev.silence: amount = 0.0
	var db = convert_percent_to_db(amount)
	AudioServer.set_bus_volume_db(_music_bus_index, db)
	emit_signal("music_volume_changed", db)

# BUTTON SOUND MAPPERS

func play_sound_if_ready(sound_name: String):
	if not root.switching_scene:
		play_sound(sound_name)

func play_slider_sound(slider_value, sound_name):
	play_sound(sound_name)

func button_sounds(button, hover_sound='menu-hover', press_sound='menu-press'):
	button.connect("mouse_entered",Callable(self,"play_sound_if_ready").bind(hover_sound))
	button.connect("focus_entered",Callable(self,"play_sound_if_ready").bind(hover_sound))
	if button.has_signal("pressed"):
		button.connect("pressed",Callable(self,"play_sound").bind(press_sound))
	if button.has_signal("value_changed"):
		button.connect("value_changed",Callable(self,"play_slider_sound").bind(press_sound))

func button_hover_sounds(button, focus_sound='menu-hover', unfocus_sound=''):
	button.connect("mouse_entered",Callable(self,"play_sound_if_ready").bind(focus_sound))
	button.connect("focus_entered",Callable(self,"play_sound_if_ready").bind(focus_sound))
	if unfocus_sound:
		button.connect("mouse_exited",Callable(self,"play_sound").bind(unfocus_sound))
		button.connect("focus_exited",Callable(self,"play_sound").bind(unfocus_sound))

func calm_button_hover_sounds(button, focus_sound='menu-hover', unfocus_sound=''):
	button.connect("on_hover_state",Callable(self,"play_sound_if_ready").bind(focus_sound))
	if unfocus_sound:
		button.connect("on_normal_state",Callable(self,"play_sound").bind(unfocus_sound))
