extends Node

var sounds := {}
var sound_dirs = settings.sound_dirs
var history := {}
var ambience_timers := {}
var file_locations := {}
var current_song = false
var missing_files := []
var paused_sounds := {}
var music_position = false

var music_fadeout_tween: Tween
var music_fadein_tween: Tween

signal music_volume_changed()

func _ready():
	set_sound_volume(settings.sound_volume)
	set_music_volume(settings.music_volume)

func play_music(song_name, volume=1.0):
	if dev.silence: return
	if dev.no_music: return
	if song_name in settings.tracklist:
		var song_data = settings.tracklist[song_name]
		if typeof(song_data) == TYPE_STRING:
			song_name = song_data
			volume = 1.0
		else: # array
			song_name = song_data[0]
			volume = song_data[1]
	if music_playing(song_name): return
	debug.print('playing song: ' + song_name)
	if music_fadeout_tween and music_fadeout_tween.is_running():
		music_fadeout_tween.stop()
	stop_and_reset_music()
	var songfile = find_music_file(song_name)
	if songfile:
		var stream = load(songfile)
		if stream:
			if volume:
				set_music_volume(settings.music_volume*volume)
			$MusicPlayer.set_stream(stream)
			$MusicPlayer.stream_paused = false
			$MusicPlayer.play()
			current_song = song_name
		else:
			if not songfile in missing_files:
				debug.print("MUSIC FILE FAILED TO LOAD:",song_name,songfile)
				missing_files.append(songfile)
	else:
		if not song_name in missing_files:
			debug.print("MUSIC FILE MISSING:",song_name)
			missing_files.append(song_name)

func find_music_file(song_name):
	for dir in settings.music_dirs:
		var file_name = 'res://' + dir + '/' + song_name + settings.music_ext
		if util.file_exists(file_name) or util.file_exists(file_name+".import"):
			return file_name
	return false

func music_playing(song):
	if $MusicPlayer.is_playing() and current_song == song:
		return true
	return false

func pause_music():
	music_position = $MusicPlayer.get_playback_position()
	$MusicPlayer.stop()

func resume_music():
	$MusicPlayer.play()
	if music_position:
		$MusicPlayer.seek(music_position)

func stop_music():
	$MusicPlayer.stop()
	music_position = false
	current_song = false

func stop_and_reset_music():
	stop_music()
	set_music_volume(settings.music_volume)

func play_sound(sound_name, volume=1.0, origin=false, listener=false, allow_multiple=true):
	if dev.silence: return
	var file_name = sound_file(sound_name)
	if file_name:
		# stop already playing sounds of this
		stop_sound(file_name)
		# play the sound
		if origin and listener:
			var distance = listener.distance_to(origin)
			# todo: cleanup w/settings
			var distance_multi = distance/80
			if distance_multi < 1: distance_multi = 1
			volume /= distance_multi
			if distance > 300:
				return
		return queue_sound(file_name, volume, allow_multiple)
	else:
		if not sound_name in missing_files:
			debug.print("SOUND FILE MISSING:",sound_name)
			missing_files.append(sound_name)

func play_once(sound_name, volume=1.0):
	return play_sound(sound_name, volume, false, false, true)

func play_random_sound(sound_name, total, volume=1.0, origin=false, listener=false):
	if dev.silence: return
	var c = math.random_int(1,total)
	return play_sound(sound_name + str(c), volume, origin, listener)

func play_sound_pitched(sound_name, pitch_start=0.8, pitch_end=1.2):
	var player = play_sound(sound_name)
	if player:
		player.pitch_scale = math.random_float(pitch_start, pitch_end)

func play_ambience_sound(sound_name, total=1, origin=false, listener=false, time=0.33, random=true):
	if dev.silence: return
	if not sound_name in ambience_timers:
		var timer = Timer.new()
		timer.one_shot = true
		timer.autostart = false
		$Timers.add_child(timer)
		ambience_timers[sound_name] = timer
	var timer = ambience_timers[sound_name]
	if timer.is_stopped():
		if total == 1:
			play_sound(sound_name, 1.0, origin, listener)
		else:
			play_random_sound(sound_name, total, 1.0, origin, listener)
		if random:
			time = math.random_float(time/2,time+time/2)
		timer.start(time)

func queue_sound(file_name, volume=1.0, allow_multiple=true):
	if dev.silence: return
	var player = false
	if not allow_multiple:
		for check in $SoundPlayers.get_children():
			if check.playing and check.name == file_name:
				return
	for test in $SoundPlayers.get_children():
		if not test.playing:
			player = test
			break
	if not player:
		player = $SoundPlayers/SoundPlayer1
	var stream = load(file_name)
	if stream:
		player.volume_db = convert_percent_to_db(volume*settings.sound_volume)
		player.set_stream(stream)
		player.stream_paused = false
		player.play()
		player.pitch_scale = 1.0
		history[player.name] = file_name
		paused_sounds.erase(player)
		return player

func stop_sound(sound_name):
	var file_name = sound_file(sound_name)
	for player in $SoundPlayers.get_children():
		if player.playing:
			if player.name in history:
				if history[player.name] == file_name:
					player.stream_paused = true
					player.stop()
					player.playing = false
					#player.set_stream(null)
					history.erase(player.name)
					paused_sounds.erase(player)
				elif history[player.name] == sound_name:
					player.stream_paused = true
					player.stop()
					player.playing = false
					#player.set_stream(null)
					history.erase(player.name)
					paused_sounds.erase(player)
				elif player.name == sound_name:
					player.stream_paused = true
					player.stop()
					player.playing = false
					#player.set_stream(null)
					history.erase(player.name)
					paused_sounds.erase(player)
	for player in $SoundLoopers.get_children():
		if player.playing:
			if player.name in history:
				if history[player.name] == file_name:
					player.stream_paused = true
					player.stop()
					player.playing = false
					player.set_stream(null)
					history.erase(player.name)
					paused_sounds.erase(player)
				elif history[player.name] == sound_name:
					player.stream_paused = true
					player.stop()
					player.playing = false
					player.set_stream(null)
					history.erase(player.name)
					paused_sounds.erase(player)
				elif player.name == sound_name:
					player.stream_paused = true
					player.stop()
					player.playing = false
					player.set_stream(null)
					history.erase(player.name)
					paused_sounds.erase(player)

func sound_file(sound_name):
	if util.file_exists(sound_name):
		return sound_name
	if sound_name in file_locations:
		return file_locations[sound_name]
	var file_name = find_sound_file(sound_name)
	if file_name:
		file_locations[sound_name] = file_name
		return file_name
	if sound_name in settings.sound_alias:
		var alias_name = settings.sound_alias[sound_name]
		if alias_name:
			var file_name2 = find_sound_file(alias_name)
			if file_name2:
				file_locations[sound_name] = file_name2
			return file_name2
	return false

func find_sound_file(sound_name):
	for dir in settings.sound_dirs:
		var file_name = 'res://' + dir + '/' + sound_name + settings.sound_ext
		if util.file_exists(file_name) or util.file_exists(file_name+".import"):
			return file_name
	return false

func loop_sound(sound_name, volume=1.0):
	if dev.silence: return
	var file_name = sound_file(sound_name)
	if file_name:
		# stop already playing sounds of this
		stop_sound(file_name)
		var player = false
		for test in $SoundLoopers.get_children():
			if not test.playing:
				player = test
				break
		if not player:
			player = $SoundLoopers/SoundLooper1
		var stream = load(file_name)
		if stream:
			player.volume_db = convert_percent_to_db(volume*settings.sound_volume)
			player.set_stream(stream)
			player.stream_paused = false
			player.play()
			if not player.is_connected("finished",Callable(self,"on_loop_sound")):
				player.connect("finished",Callable(self,"on_loop_sound").bind(player))
			history[player.name] = file_name

func convert_percent_to_db(amount):
	return 12.5 * log(amount)

func set_sound_volume(amount):
	var db = convert_percent_to_db(amount)
	#var db = linear_to_db(amount)
	for player in $SoundPlayers.get_children():
		player.volume_db = db
		#player.volume_db = (1.0-amount) * -80.0
	for player in $SoundLoopers.get_children():
		player.volume_db = db
		#player.volume_db = (1.0-amount) * -80.0

func set_music_volume(amount):
	var db = convert_percent_to_db(amount)
	$MusicPlayer.volume_db = db
	emit_signal("music_volume_changed", db)
	#$MusicPlayer.volume_db = (1.0-amount) * -80.0

func fade_in_music(music_name, _time, _ease_method=Tween.EASE_IN):
	set_music_volume(0)
	play_music(music_name, false)
	if music_fadein_tween and music_fadein_tween.is_running():
		music_fadeout_tween.stop()
	var db = convert_percent_to_db(settings.music_volume)
	#$MusicFadeIn.tween_property($MusicPlayer, "volume_db", -80, db, time, Tween.TRANS_SINE, ease_method, 0)
	#$MusicFadeIn.start()

func fade_out_music(_time=1.0, _ease_method=Tween.EASE_IN):
	if $MusicPlayer.playing:
		if music_fadeout_tween and not music_fadeout_tween.is_running():
			pass
			#$MusicFadeOut.tween_property($MusicPlayer, "volume_db", 0, -80, time, Tween.TRANS_SINE, ease_method, 0)
			#broken: $MusicFadeOut.tween_property($MusicPlayer, "volume_db", $MusicPlayer.volume_db, convert_percent_to_db(0), time, Tween.TRANS_SINE, ease_method, 0)
			#$MusicFadeOut.connect("finished",Callable(self,"stop_and_reset_music"))
			#$MusicFadeOut.start()

func button_sounds(button, hover_sound, press_sound):
	button.connect("mouse_entered",Callable(self,"play_sound").bind(hover_sound))
	button.connect("pressed",Callable(self,"play_sound").bind(press_sound))

func button_hover_sounds(button, focus_sound, unfocus_sound=false):
	button.connect("mouse_entered",Callable(self,"play_sound").bind(focus_sound))
	#button.connect("focus_entered",Callable(self,"play_sound").bind(focus_sound))
	if unfocus_sound:
		button.connect("mouse_exited",Callable(self,"play_sound").bind(unfocus_sound))
		#button.connect("focus_exited",Callable(self,"play_sound").bind(unfocus_sound))

func calm_button_hover_sounds(button, focus_sound, unfocus_sound=false):
	button.connect("on_hover_state",Callable(self,"play_sound").bind(focus_sound))
	if unfocus_sound:
		button.connect("on_normal_state",Callable(self,"play_sound").bind(unfocus_sound))

func delayed_sound(sound_name, time, volume=1.0):
	if dev.silence: return
	# todo: more timers
	if $Timers/DelayedTimer1.is_connected("timeout",Callable(self,"play_sound")):
		$Timers/DelayedTimer1.disconnect("timeout",Callable(self,"play_sound"))
	$Timers/DelayedTimer1.connect("timeout",Callable(self,"play_sound").bind(sound_name, volume))
	$Timers/DelayedTimer1.wait_time = time
	$Timers/DelayedTimer1.start()

func on_loop_sound(player):
	player.stream_paused = false
	player.play()

func stop_all_sounds():
	for sound in $SoundPlayers.get_children():
		sound.stop()
		sound.playing = false
	for looper in $SoundLoopers.get_children():
		if not dev.silence:
			if looper.is_connected("finished",Callable(self,"on_loop_sound")):
				looper.disconnect("finished",Callable(self,"on_loop_sound"))
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

# plays a sound if not already playing
# todo: add within last time played
func play_sound_if_not(sound_name, volume=1.0):
	play_sound(sound_name, volume, false, false, false)
