
SpriteSheet = {}

SpriteSheet.frame = function(column, row)
	return self.image.getImage(self.cellWidth*column, self.cellHeight*row, self.cellWidth, self.cellHeight)
end function	

SpriteSheet.anim = function(column, row, count)
	frames = []
	for i in range(column, column+count-1)
		frames.push self.frame(i, row)
	end for
	return newAnimation(frames)
end function

// factory method to create a SpriteSheet from an image path:
load = function(name, cellWidth=32, cellHeight=32)
	noob = new SpriteSheet
	noob.image = file.loadImage("pics/" + name)
	if noob.image == null then
		print "Unable to load image: pics/" + name
		exit
	end if
	noob.cellWidth = cellWidth
	noob.cellHeight = cellHeight
	return noob
end function

