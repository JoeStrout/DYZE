clear
text.row = 13; text.column = 27; print "LOADING..."

import "spriteControllers"
import "tileUtil"
import "listUtil"

env["includePaths"] = "/usr/DrYond/inc"
import "tileTypes"
import "SpriteSheet"
import "sounds"

for kv in spriteControllers
	if kv.key[0] == "_" then continue
	globals[kv.key] = @kv.value
end for

SCALE = 3

text.backColor = color.clear
text.color = color.green
text.clear
display(4).mode = displayMode.sprite
disp = display(4)  // (sprites)
display(3).mode = displayMode.sprite
overlay = display(3)
overlay.clear
display(2).mode = displayMode.text
text = display(2)
text.clear

display(5).mode = displayMode.tile
tiles = display(5)
tiles.clear
tileUtil.loadFromFile "maps/level1.txt", tiles
grid = tileUtil.sizeToXY(tiles.cellSize)
maxScroll = 120 * grid.x - 960

display(6).mode = displayMode.tile
bkgnd = display(6)
tileUtil.loadFromFile "maps/skyline.txt", bkgnd

display(7).mode = displayMode.solidColor
display(7).color = "#225588"
tiles.scrollY = 13*SCALE
disp.scrollY = tiles.scrollY
overlay.scrollY = disp.scrollY

scrollTo = function(x)
	x = round(x)
	if x < 0 then x = 0
	if x > maxScroll then x = maxScroll
	disp.scrollX = x
	overlay.scrollX = x
	tiles.scrollX = x
	bkgnd.scrollX = x/2
	text.row = 25
end function
scrollTo 0

Animated.normalScale = [SCALE, SCALE]
Animated.flippedScale = [-SCALE, SCALE]

updateables = []

UpdateableSprite = new Sprite
UpdateableSprite.update = null
UpdateableSprite.normalScale = Animated.normalScale
UpdateableSprite.flippedScale = Animated.flippedScale
UpdateableSprite.init = function(x=0, y=0, addToDisp=true)
	self.x = x
	self.y = y
	self.scale = Animated.normalScale
	if addToDisp then disp.sprites.push self
	updateables.push self
end function
UpdateableSprite.destroy = function()
	listUtil.removeVal(disp.sprites, self)
	listUtil.removeVal(updateables, self)
	printScore
end function
spriteControllers.Animated.__isa = UpdateableSprite

//----------------------------------------------------------------------
// Brain
//----------------------------------------------------------------------
Brain = new UpdateableSprite
Brain.init = function()
	super.init mouse.x, mouse.y, false
	overlay.sprites.push self	
	self.image = file.loadImage("pics/brain.png")
end function
Brain.update = function(dt)
	newX = mouse.x + disp.scrollX
	if newX > self.x + 1 then
		self.scale = self.flippedScale
	else if newX < self.x - 1 then 
		self.scale = self.normalScale
	end if
	self.x = newX
	self.y = mouse.y + disp.scrollY
	if mouse.x < 200 and disp.scrollX > 0 then
		scrollTo disp.scrollX - (200-mouse.x)/200 * 300 * dt
	else if mouse.x > 760 then
		scrollTo disp.scrollX + (mouse.x-760)/200 * 300 * dt
	end if
end if
end function
brain = new Brain
brain.init
mouse.visible = false

//----------------------------------------------------------------------
// Zombies
//----------------------------------------------------------------------
zombieSheet = SpriteSheet.load("ZombieSprites.png")

Zombie = new Platformer
Zombie.footOffset = 9 * SCALE
Zombie.jumpSpeed = 1500
Zombie.count = 0

Zombie.idleAnim = zombieSheet.anim(0, 7, 8)
Zombie.runAnim = zombieSheet.anim(0, 3, 4)
Zombie.jumpUpAnim = zombieSheet.anim(1, 5, 2)
Zombie.fallDownAnim = zombieSheet.anim(3, 6, 2)
Zombie.climbAnim = zombieSheet.anim(0, 2, 4)
Zombie.dieAnim = zombieSheet.anim(1, 4, 2)
Zombie.dieAnim.frames.push zombieSheet.frame(6, 4)
Zombie.dieAnim.frames.push zombieSheet.frame(7, 4)
Zombie.dieAnim.loop = false
Zombie.splatAnim = zombieSheet.anim(4, 2, 4)
Zombie.splatAnim.loop = false
Zombie.burnAnim = zombieSheet.anim(0, 0, 8)
Zombie.burnAnim.loop = false

DYING = "DYING"
zombies = []
Zombie.init = function(x=0, y=0)
zombies.push self
super.init x,y
for anim in "idleAnim runAnim jumpUpAnim fallDownAnim climbAnim dieAnim".split
	self[anim] = Zombie[anim].clone
end if
self.scale = [SCALE, SCALE]
self.runSpeed = 200 + 80 * (rnd+rnd)
self.runAccel = 1000 + 1000 * rnd
self.climbSpeed = self.runSpeed / 2
self.brainRadius = 80 + round(40*rnd)  // where we stop approaching the brain
self.timeInState = 0
self.saved = false
self.finishSetup
end function
Zombie.destroy = function()
listUtil.removeVal zombies, self
super.destroy
end function
// custom update method for when falling into a pit:
Zombie.updateFall = function(dt)
self.vy = self.vy + self.gravity * dt
self.y = self.y + self.vy * dt
self.x = self.x + self.vx * dt
if self.y < 100 then self.destroy
end function
// custom update method for when burning:
Zombie.updateBurn = function(dt)
self.curAnim.applyTo self, dt
if self.curAnim.curFrame == self.curAnim.frames.len-1 then
	self.destroy
	return
end if
self.vy = self.vy + self.gravity * dt
dx = self.vx * dt
dy = self.vy * dt
if self.vy < 0 then
	groundLevel = self.groundBelow(self.x, self.y - self.footOffset)
	if groundLevel > self.y - self.footOffset + dy then  // landed!
		self.x = self.x + dx * (groundLevel - self.y + self.footOffset) / dy
		self.y = groundLevel + self.footOffset
		self.vx = self.vx / 2
		return
	end if
end if
self.x = self.x + dx
self.y = self.y + dy
end function
Zombie.checkObstacles = function()
col = floor(self.x / grid.x)
row = floor((self.y - self.footOffset) / grid.y)
tile = tiles.cell(col, row)
if tile > 31 and tile < 64 then
	// whoops, we hit an obstacle!  Move to closest side
	if self.x % grid.x > grid.x/2 then
		self.x = (col+1) * grid.x
	else
		self.x = col * grid.x
	end if
end if
if tile == 430 and self.x%48 > 20 or tile == 431 and self.x%48 < 28 then
	// hit a pit!
	self.update = @self.updateFall
	self.vx = self.vx/2
	sounds.fall self.x
	return
end if
// While we're at it, check for windows to break
tile = tiles.cell(col, row+1)
if tile >= 201 and tile <= 203 then
	// break the window!
	tiles.setCell col, row+1, tile + 32 + 32 * (rnd>0.5)
	globals.score = score + row
	sounds.window self.x
end if
end function
Zombie.checkHazards = function()
for car in cars
	if self.isTouching(car) then
		self.enterState DYING
		sounds.death self.x
		return
	end if
end for
for f in flames
	if abs(self.x - f.x) > 32 then continue
	if self.y < f.burnY then
		// Burn!
		self.state = DYING
		self.curAnim = Zombie.burnAnim.clone
		self.update = @self.updateBurn
		sounds.burn self.x
	end if
end for
end function
Zombie.checkNPCs = function()
for npc in NPCs
	if self.isTouching(npc, 6) then
		npc.becomeZombie
	end if
end for
end function
Zombie.updateState = function(dt)
//text.row = 25; print self.state + " " * 20
self.timeInState = self.timeInState + dt
if self.state == DYING then
	self.tint = color.rgba(255,255,255,255-self.timeInState*51)
	if self.timeInState > 5 then
		self.destroy
	end if
	return
end if
if self.state == CLIMBING then
	dir = sign(brain.y - self.y)
	if self.canClimb(dir) then
		self.climb sign(brain.y - self.y), dt
	else
	if dir > 0 then self.enterState JUMPING else self.enterState IDLE
	end if
else
	super.updateState dt
end if
self.checkObstacles
self.checkHazards
self.checkNPCs
end function
Zombie.groundBelow = function(x,y)
col = floor(x / grid.x)
row = floor(y / grid.y)
while row > 2
	tile = tiles.cell(col, row)
	if tile < 32 then return (row+0.5)*grid.y  // walkables
	if tile < 64 then return (row+1)*grid.y   // obstacles
	row = row - 1
end while
return 2*grid.y
end function
Zombie.canClimb = function(direction)
col = floor(self.x / grid.x)
row = floor((self.y - self.footOffset * (1 - 0.1*direction)) / grid.y)
tile = tiles.cell(col, row)
nextTile = tiles.cell(col, row + direction)
// ladders in column 31 of tile sheet
climbable = (tile % 32 == 31) or (nextTile % 32 == 31)
if not climbable then return false
// since we can climb, we probably are about to do so...
// so let's center ourselves horizontally on the ladder
self.x = (col + 0.5) * grid.x
return true
end function
Zombie.checkInputs = function()
if self.state == DYING then return
if self.state == JUMPING or self.state == FALLING then
	// behavior in the air
else if self.state == CLIMBING then
	// climbing
	// (NOTE: up/down is actually handled in update.
	// Here, check for jumping off the pipe.)
else
	// on the ground
	// check for exiting the level
	if self.x > maxScroll + 860 then
		self.enterState RUNRIGHT
		if not self.saved then
			self.saved = true
			globals.saved = globals.saved + 1
		else if self.x > maxScroll + 1000 then
			self.destroy
		end if
		return
	end if
	// calculate angle to the brain
	dx = brain.x - self.x
	dy = brain.y - self.y
	if dx > self.brainRadius then
		self.enterState RUNRIGHT
		if rnd < 0.01 or self.groundBelow(self.x + self.runSpeed*0.1, self.y) < self.y - 80 then
			// We're approaching a gap; jump (if brain is above us)
			if brain.y > self.y then
				self.enterState JUMPING
				self.vx = self.runSpeed * 2
			end if
		end if
	else if dx < -self.brainRadius then
		self.enterState RUNLEFT
		if rnd < 0.01 or self.groundBelow(self.x - self.runSpeed*0.1, self.y) < self.y - 80 then
			// Approaching a gap to the left; jump (if brain is above us)
			if brain.y > self.y then
				self.enterState JUMPING
				self.vx = -self.runSpeed * 2
			end if
		end if
	else if dy > 30 then
		// jump or climb up
		if self.canClimb(1) then
			self.enterState CLIMBING
		else if self.jumpAvail and rnd < 0.03 then
			self.enterState JUMPING
		else
			self.enterState IDLE
		end if
	else if dy < -50 then
		// climb down if possible
		if self.canClimb(-1) then
			self.enterState CLIMBING
		else
			self.enterState IDLE
		end if
	else
		// we're right on the brain!  Munch munch!
		// ...ToDo
		self.enterState IDLE
	end if
end if
self.jumpAvail = (self.state == IDLE)
end function
Zombie.enterState = function(newState)
if newState == self.state then return
self.timeInState = 0
if self.state == FALLING and newState == IDLE and self.vy < -2000 then
	// ker-splat!
	self.enterState DYING
	self.curAnim = Zombie.splatAnim.clone
	sounds.splat self.x
	return
else if newState == DYING then
	self.curAnim = self.dieAnim
	self.targetSpeed = 0
else if newState == JUMPING then
	sounds.jump self.x
end if
super.enterState newState
end function
Zombie.isTouching = function(sprite, halfWidth=null)
if halfWidth == null then halfWidth = sprite.image.width/2
if abs(self.x - sprite.x) > (halfWidth + 6) * SCALE then return false
if abs(self.y - sprite.y) > (halfWidth + 7) * SCALE then return false
return true
end function

//----------------------------------------------------------------------
// Cars
//----------------------------------------------------------------------
carUpImages = []
carDownImages = []
for i in range(0,2)
carUpImages.push tiles.tileSet.getImage(27*16,(i*2+1)*16,24,32)
carDownImages.push tiles.tileSet.getImage(29*16,(i*2+1)*16,24,32)
end for

cars = []
Car = new UpdateableSprite
Car.init = function(up)
self.up = up
self.pickImage
self.scale = 3
self.speed = 100
disp.sprites.insert 0, self
updateables.push self
cars.push self
end function
Car.pickImage = function()
if self.up then 
	self.image = carUpImages[rnd * carUpImages.len] 
else 
	self.image = carDownImages[rnd * carDownImages.len]
end if	
end function
Car.update = function(dt)
if self.up then
	self.y = self.y + self.speed * dt
	if self.y > 300 then
		self.y = -100
		self.pickImage
	end if
else
	self.y = self.y - self.speed * dt
	if self.y < -20 then
		self.y = 300
		self.pickImage
	end if
end if
end function
addCarPark = function(x, y)
carEntrance = new Sprite
carEntrance.image = tiles.tileSet.getImage(21*16,5*16,6*16,4*16)
carEntrance.scale = 3
disp.sprites.insert 0, carEntrance
carEntrance.x = x*grid.x
carEntrance.y = 6*grid.y

carUp = new Car
carUp.init true
carDown = new Car
carDown.init false
carUp.x = carEntrance.x - 70; carUp.y = carEntrance.y - 50
carDown.x = carEntrance.x + 70; carDown.y = carUp.y
end function

//----------------------------------------------------------------------
// Flame hazard
//----------------------------------------------------------------------
flames = []
HoleCover = new Sprite
HoleCover.image = file.loadImage("pics/HoleCover.png")
HoleCover.scale = 3
Flame = new UpdateableSprite
Flame.anim = SpriteSheet.load("FireSprite.png").anim(0,0, 16)
Flame.init = function(x, y)
self.anim = Flame.anim.clone
super.init x + 4, y
self.basey = y
flames.push self
cover = new HoleCover
cover.x = x
cover.y = y - 76
cover.scale = SCALE
overlay.sprites.insert 0, cover
end function
Flame.update = function(dt)
self.anim.applyTo self, dt
self.y = self.basey + - 8 + self.anim.curFrame * 5
end function
burnHeights = [0,190,205,220,230,240,250,270,290,310,320,320,320,320,320,0,0]
Flame.burnY = function()
return burnHeights[self.anim.curFrame]
end function
addFlame = function(x, y)
noob = new Flame
noob.init (x + 1) * grid.x, (y + 1.2) * grid.y
end function

//----------------------------------------------------------------------
// NPCs
//----------------------------------------------------------------------

conversionSprite = new UpdateableSprite
conversionSprite.anim = SpriteSheet.load("Conversion.png").anim(0,0, 8)
conversionSprite.anim.loop = false
conversionSprite.shown = false
updateables.push conversionSprite
conversionSprite.show = function(x, y)
self.x = x
self.y = y
listUtil.removeVal disp.sprites, self
disp.sprites.push self
self.anim.curFrame = -1
end function
conversionSprite.update = function(dt)
self.anim.applyTo self, dt
end function

NPCs = []
NPC = new UpdateableSprite
NPC.idleAnim = null
NPC.attackAnim = null
NPC.curAnim = null
NPC.attacking = false
NPC.init = function(x, y)
if self.idleAnim != null then self.idleAnim = self.idleAnim.clone
if self.attackAnim != null then
	self.attackAnim = self.attackAnim.clone
	self.attackAnim.loop = false
end if
self.curAnim = self.idleAnim
super.init x, y + round(15*rnd)
NPCs.push self
end function
NPC.destroy = function()
super.destroy
listUtil.removeVal NPCs, self
end function
NPC.attackRange = 36*SCALE
NPC.attackSound = @sounds.attack
NPC.update = function(dt)
self.curAnim.applyTo self, dt
// every now and then, face the other way:
if rnd < 0.005 then self.scale = [-self.scale[0], SCALE]
// and if a zombie is close in view, attack
if self.curAnim == self.idleAnim and self.attackAnim != null then
	// if there is a zombie nearby, then attack
	for zom in zombies
		if zom.state == DYING or abs(zom.y - self.y) > 30*SCALE then continue
		dx = zom.x - self.x
		if abs(dx) < self.attackRange then
			self.scale = [sign(dx) * SCALE, SCALE]
			self.curAnim = self.attackAnim
			self.curAnim.curFrame = -1
			self.attacking = true	
			self.attackSound	
			break
		end if
	end for
else if self.curAnim == self.attackAnim then
	if self.attacking and self.curAnim.curFrame > 2 then
		// attack is active; if a zombie is in range, kill it
		for zom in zombies
			if zom.state == DYING or abs(zom.y - self.y) > 12*SCALE then continue
			dx = zom.x - self.x
			if sign(dx) == sign(self.scale[0]) and abs(dx) < 24*SCALE then
				zom.enterState DYING
				sounds.death zom.x
				self.attacking = false
				break
			end if
		end for
	end if
	if self.curAnim.curFrame == self.curAnim.frames.len - 1 then
		self.curAnim = self.idleAnim
		self.attackDone
	end if
end if
end function
NPC.attackDone = null
NPC.becomeZombie = function(dt)
sounds.convert self.x
zom = new Zombie
zom.init self.x, self.y+10
self.destroy
globals.score = score + 100
conversionSprite.show self.x, self.y
end function

innKeeperSheet = SpriteSheet.load("InnkeeperSprites.png")
Innkeeper = new NPC
Innkeeper.idleAnim = innKeeperSheet.anim(0, 9, 10)

builderSheet = SpriteSheet.load("BuilderSprites.png")
Builder = new NPC
Builder.idleAnim = builderSheet.anim(0, 4, 4)
Builder.attackAnim = builderSheet.anim(0, 2, 8)

blacksmithSheet = SpriteSheet.load("BlacksmithSprites.png")
Blacksmith = new NPC
Blacksmith.idleAnim = blacksmithSheet.anim(0, 4, 4)
Blacksmith.attackAnim = blacksmithSheet.anim(0, 2, 7)

boySheet = SpriteSheet.load("BoySprites.png")
Boy = new NPC
Boy.idleAnim = boySheet.anim(0, 4, 16)

farmerSheet = SpriteSheet.load("FarmerSprites.png")
Farmer = new NPC
Farmer.idleAnim = farmerSheet.anim(0, 5, 4)
Farmer.attackAnim = farmerSheet.anim(0, 4, 8)

girlSheet = SpriteSheet.load("GirlSprites.png")
Girl = new NPC
Girl.idleAnim = boySheet.anim(0, 4, 4)

minerSheet = SpriteSheet.load("MinerSprites.png")
Miner = new NPC
Miner.idleAnim = minerSheet.anim(0, 4, 4)
Miner.attackAnim = minerSheet.anim(0, 2, 5)

dancerSheet = SpriteSheet.load("DancerSprites.png")
Dancer = new NPC
Dancer.idleAnim = dancerSheet.anim(0, 4, 4)

oldManSheet = SpriteSheet.load("OldManSprites.png")
OldMan = new NPC
OldMan.idleAnim = oldManSheet.anim(0, 4, 15)
OldMan.attackAnim = oldManSheet.anim(0, 2, 10)

villagerSheet = SpriteSheet.load("VillagerFemaleSprites.png")
VillagerFemale = new NPC
VillagerFemale.idleAnim = villagerSheet.anim(0, 4, 8)

oldLadySheet = SpriteSheet.load("OldLadySprites.png")
OldLady = new NPC
OldLady.idleAnim = oldLadySheet.anim(0, 5, 4)
OldLady.attackAnim = oldLadySheet.anim(0, 1, 4)
OldLady.attackRange = 650
OldLady.attackSound = @sounds.hadouken
OldLady.attackDone = function()
proj = new Projectile
proj.init self
end function

Projectile = new UpdateableSprite
Projectile.anim = oldLadySheet.anim(0, 0, 3)
Projectile.speed = 300
Projectile.range = 700
Projectile.init = function(attacker)
self.scale = attacker.scale
facing = sign(self.scale[0])
self.x = attacker.x + facing * 8 * SCALE
self.y = attacker.y - 20
self.rangeLeft = self.range
updateables.push self
disp.sprites.push self
end function
Projectile.update = function(dt)
self.anim.applyTo self
dx = self.speed * dt
self.x = self.x + dx * sign(self.scale[0])
self.rangeLeft = self.rangeLeft - dx

for zom in zombies
	if zom.state == DYING then continue
	if abs(zom.x - self.x) > 24 or abs(zom.y - self.y) > 15 then continue
	zom.enterState DYING
	sounds.death zom.x
	self.destroy
	return
end for
if self.rangeLeft < 0 then self.destroy
end function

analyzeLevel = function()
for x in range(0, tiles.extent[0]-1)
	for y in range(0, tiles.extent[1]-1)
		name = tileTypes.get(tiles.cell(x,y))
		if not name then continue
		noob = null
		if name == "Zombie" then
			noob = new Zombie
		else if name == "CarPark" then
			addCarPark x, y
		else if name == "FlameHole" then
			addFlame x, y
			continue
		else if globals.hasIndex(name) then
			noob = new globals[name]
		end if
		if noob != null then noob.init (x+0.5) * grid.x, (y+1.2) * grid.y
		tiles.setCell x, y, tiles.cell(x+1, y)
	end for
end for
end function

analyzeLevel

timeLeft = function()
tl = 90 - floor(time - startTime)
if tl < 0 then tl = 0
return tl
end function

printScore = function()
text.row = 25; text.column = 1
print ("00000" + score)[-5:]
text.row = 25; text.column = 32
print char(57872) + zombies.len + "  "
if saved > 0 then
	print char(18) + saved
end if
text.row = 25; text.column = 62
print "T:" + ("   " + timeLeft)[-3:]
end function

//----------------------------------------------------------------------
// Main Program
//----------------------------------------------------------------------
gameOver = false
score = 0
saved = 0
startTime = time
text.color = "#AAFFAA"
text.delimiter = ""
printScore
printCentered = function(s, width=23)
if s.len < width then
	pad = " " * ceil((width-s.len)/2)
	s = (pad + s + pad)[:width]
end if
text.column = 34 - s.len/2
print s
end function
checkGameOver = function()
if gameOver then
	if mouse.button then
		if saved == 0 then
			sounds.stopMusic
			run 
		else 
			doCredits
		end if
	end if
else if not zombies or timeLeft <= 0 then
	text.delimiter = char(13)
	text.backColor = color.black
	text.row = 17
	printCentered " "
	if saved == 0 then
		printCentered "EXPERIMENT FAILED"
		printCentered " "
		printCentered "Click to try again."
	else
		printCentered "SUCCESS!"
		printCentered " "		
		printCentered "Zombie army: " + saved
		bonus = saved * 50
		printCentered "Bonus: " + bonus
		score = score + bonus
		printCentered " "
		printCentered "Click to continue."
	end if		
	printCentered " "
	text.backColor = color.clear
	printScore
	globals.gameOver = true
end if
end function
doCredits = function()
sounds.stopMusic
clear
text.color = color.orange
text.row = 23
mouse.visible = true
printCentered "Dr. Yond's Zombie Experiment"
print
printCentered "Written in August 2019 for the"
printCentered """Mouse Movement"" Game Jam."
print
printCentered "Coding: Joe Strout"
printCentered "Tiles: ""Roguelike City Tiles"" by Kenney"
printCentered "Character sprites: Elthen"
printCentered "Custom Artwork: Derrick Moore"
print
text.delimiter = ""
text.column = 19; print "Written in "
text.color = color.aqua; print "Mini Micro"
text.color = color.orange; text.delimiter = char(13)
print ", a fun,"
printCentered "free neo-retro virtual come computer."
print
printCentered "Check it out at:"
text.color = color.blue
printCentered "https://miniscript.org"
text.color = color.orange
print
print
print
wait
while mouse.button; end while
printCentered "Click anywhere to play again."
while not mouse.button; end while
run
end function

update = function(dt=0.1)
for u in updateables
	u.update dt
end for
end function

lastTime = time
nextScoreUpdate = 0
sounds.startMusic

while not key.pressed("escape")
dt = time - lastTime
lastTime = time
update dt
if lastTime > nextScoreUpdate and not gameOver then
	printScore
	nextScoreUpdate = lastTime + 0.25
end if
checkGameOver
yield
end while

key.clear
mouse.visible = true
text.delimiter = char(13)
sounds.stopMusic
