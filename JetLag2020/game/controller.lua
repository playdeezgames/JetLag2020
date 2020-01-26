local controller = {}

local CELL_COLUMNS = 40
local CELL_ROWS = 30
local FRAME_TIME = 0.1
local TAIL_LENGTH = 6
local TAIL_OFFSET = CELL_ROWS - TAIL_LENGTH
local tileMapUrl = "#screen"
local tileMapBackgroundLayer = "background"
local tileMapForegroundLayer = "foreground"
local blocks = {}
local tail = {}
local frameTimer = 0
local score = 0
local inPlay = false
local runCounter = 0
local direction = 1

local resetBlocks = function ()
	blocks = {}
	while #blocks<CELL_ROWS do
		table.insert(blocks, 1)
	end
end

local resetTail = function ()
	tail = {}
	while #tail < TAIL_LENGTH do
		table.insert(tail, math.floor(CELL_COLUMNS / 2))
	end
end

local reset = function ()
	resetBlocks()
	resetTail()
	frameTimer=0
	score=0
	runCounter=0
	direction = 1
end

local getTileFromColorAndAscii = function (color,ascii)
	return color * 256 + ascii + 1
end

local updateCellBackground = function (x,y,background)
	tilemap.set_tile(tileMapUrl, tileMapBackgroundLayer, x, y, background)
end

local updateCellForeground = function (x,y,foreground)
	tilemap.set_tile(tileMapUrl, tileMapForegroundLayer, x, y, foreground)
end

local scrollBlocks = function ()
	for row = CELL_ROWS,2,-1 do
		blocks[row]=blocks[row-1]
	end
	blocks[1]=math.random(2,CELL_COLUMNS-1)
end

local scrollTail = function ()
	for row = TAIL_LENGTH,2,-1 do
		tail[row]=tail[row-1]
	end
	tail[1]=tail[1]+direction
end

local addFrameTime = function (dt)
	if inPlay then
		frameTimer = frameTimer + dt
		if frameTimer > FRAME_TIME then
			frameTimer = frameTimer - FRAME_TIME
			runCounter=runCounter+1
			scrollBlocks()
			scrollTail()
			if tail[1]==blocks[1+TAIL_OFFSET] or tail[1]== 1 or tail[1] == CELL_COLUMNS then
				inPlay = false
			end
		end
	end
end

local updateScore = function ()
	local x = 2
	local y = 30
	local temp = score
	while temp>9 do
		x = x + 1
		temp = math.floor(temp/10)
	end
	temp = score
	while x>1 do
		local digit = temp % 10
		temp = math.floor(temp/10)
		updateCellForeground(x,y,getTileFromColorAndAscii(2,digit+48))
		x = x - 1
	end
end

local writeText = function (x,y,color,text)
	for index = 1,string.len(text) do
		updateCellForeground(x,y,getTileFromColorAndAscii(color,string.byte(text,index)))
		x = x + 1
	end
end

local updateScreen = function ()
	for row = 1,CELL_ROWS do
		for column = 1,CELL_COLUMNS do
			updateCellBackground(column,row,getTileFromColorAndAscii(0,0xdb))
			if column == blocks[row] and column>1 then
				updateCellForeground(column,row,getTileFromColorAndAscii(15,0xdb))
			elseif row>TAIL_OFFSET and column==tail[row-TAIL_OFFSET] then
				if row-TAIL_OFFSET==1 then
					updateCellForeground(column,row,getTileFromColorAndAscii(4,0xdb))
				else
					updateCellForeground(column,row,getTileFromColorAndAscii(14,0xdb))
				end
			elseif column ==1 or column ==CELL_COLUMNS then
				updateCellForeground(column,row,getTileFromColorAndAscii(1,0xdb))
			else
				updateCellForeground(column,row,0)
			end
		end
	end
	updateScore()
	if not inPlay then
		writeText(math.floor((CELL_COLUMNS-12)/2),5,5,"'Z' to Start")
		writeText(math.floor((CELL_COLUMNS-20)/2),4,5,"Controls: Arrow Keys")
		end
end

local setDirection = function (d)
	direction  = d
end

local sendCommand = function (command)
	if inPlay then
		if command=="left" and direction~=-1 then
			score = score + runCounter * (runCounter+1) / 2
			runCounter=0
			direction = -1
		elseif command=="right" and direction~=1 then
			score = score + runCounter * (runCounter+1) / 2
			runCounter=0
			direction = 1
		end
	else
		if command=="green" then
			reset()
			inPlay=true
		end
	end
end

controller.addFrameTime = addFrameTime
controller.updateScreen = updateScreen
controller.sendCommand = sendCommand

reset()

return controller