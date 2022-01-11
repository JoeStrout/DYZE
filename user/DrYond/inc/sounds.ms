_burn = file.loadSound("sounds/burn.wav")
_death = file.loadSound("sounds/death.wav")
_music = file.loadSound("sounds/DrYond-music.ogg")
_fall = file.loadSound("sounds/fall.wav")
_jump = file.loadSound("sounds/jump.wav")
_splat = file.loadSound("sounds/splat.wav")
_convert = file.loadSound("sounds/conversion.wav")
_attack = file.loadSound("sounds/attack.wav")
_hadouken = file.loadSound("sounds/hadouken.wav")
_window = file.loadSound("sounds/window.wav")

pan = function(x)
	if x == null then return 0
	return (x - disp.scrollX - 480) / 480
end function

death = function(x)
	_death.play 1, pan(x)
end function

burn = function(x)
	_burn.play 1, pan(x)
end function

jump = function(x)
	_jump.play 0.2, pan(x), 0.9 + 0.2*rnd
end function

fall = function(x)
	_fall.play 1, pan(x)
end function

splat = function(x)
	_splat.play 1, pan(x)
end function

attack = function(x)
	_attack.play 1, pan(x)
end function

hadouken = function(x)
	_hadouken.play 1, pan(x)
end function

window = function(x)
	_window.play 0.5, pan(x), 0.9 + 0.2*rnd
end function

convert = function(x)
	_convert.play 1, pan(x), 0.9 + 0.2*rnd
end function

startMusic = function(x)
	_music.stop
	_music.play 0.5
end function

stopMusic = function(x)
	_music.stop
end function
