pico-8 cartridge // http://www.pico-8.com
version 32
__lua__
-- balloon fight
-- andrew stephens
-- july 2021
-- version 0.1

debug=true
debug_messages={}
test_mode=true
ticks=0
left=0
right=1

-- physics/speeds
gravity=0.1
force=gravity*2
bounce=force*10
aspeed=0.1
aspeed_max=3
gspeed=0.1
gspeed_max=2

-- change game mode
function change_mode(mode_name)
	modes[mode_name]:init()
end

-- check for collisions
function collision(rect1,rect2)
	return rect1.x < rect2.x + rect2.width and
   rect1.x + rect1.width > rect2.x and
   rect1.y < rect2.y + rect2.height and
   rect1.y + rect1.height > rect2.y
end

-- lerp
function lerp(a, b, t)
	return a+(b-a)*t
end

-- get map loc based on x,y
maploc=function(x,y)
 local col=flr((x+7)/8)
 local row=flr((y+7)/8)
 return {
 	col=col,
 	row=row
 }
end

-- pad with zeros
function pad(value,length)
	local string=tostr(value)
 if (#string==length) return string
 return "0"..pad(string, length-1)
end

-- print centered on x axis
function printc(text,y,x1,x2,c)
	x1=x1 or 0
	x2=x2 or 127
	c=c or 7
	local width=#text*4
	local x=(x2-x1)/2+x1-width/2
	print(text,x,y,c)
end

-- wrap at edge of screen
function wrap(char)
	if char.x<-8 then
		char.x=127-8
	elseif char.x>127-8 then
		char.x=-8
	end
end

-------------------------------
-- pico-8 callbacks
-------------------------------

-- pico-8 _init
function _init()
	palt(0,false)
	palt(1,true)
	change_mode('menu')
end

-->8
-- modes

-------------------------------
-- menu
-------------------------------
menu_mode={
	selected=1,
	items={
		{text='game start',mode='play'},
		{text='balloon trip',mode='trip'}
	}
}
function menu_mode:init()
	_draw=self.draw
	_update=self.update
end
function menu_mode:draw()
	self=self or menu_mode
	cls(0)
	local start_y=16
	spr(192,16,start_y+8,12,2)
	spr(224,40,start_y+25,9,2)
	for i,item in ipairs(self.items) do
		local y=(i-1)*10+start_y+50
		if self.selected==i then
			rectfill(16,y-2,112,y+6,8)
		end
		printc(item.text,y,nil,nil,7)
	end	
end
function menu_mode:update()
	self=self or menu_mode
	if btnp(⬆️) then
		self.selected-=1
	end
	if btnp(⬇️) then
		self.selected+=1
	end
	self.selected=mid(1,self.selected,2)
	if btnp(4) or btnp(5) then
		local item=self.items[self.selected]
		change_mode(item.mode)		
	end
end

-------------------------------
-- play
-------------------------------
play_mode={}
function play_mode:init()
 bgstars:init()
 level:get()
 player.x=32
 player.y=90
	_update=self.update
	_draw=self.draw
end
function play_mode:update()
	ticks=ticks+1
 bgstars:update()
 enemies:update()
 player:update()
 debug:update()
end
function play_mode:draw()
 cls(1)
 bgstars:draw()
 level:draw()
 osd:draw()
 enemies:draw()
 player:draw()
	debug:draw()
end

-------------------------------
-- bonus
-------------------------------
bonus_mode={
	balloons={},
	balloon_max=20,
	delay=30,
	pipes={
		{col=2,row=13},
		{col=5,row=12},
		{col=10,row=14},
		{col=13,row=13}
	}
}
function bonus_mode:init()
	self.timer=0
	self.counter=0
	self.collected=0
	bgstars:init()
	level:get(0)
	player.balloons=2
	player.x=56
	player.y=127
	_update=self.update
	_draw=self.draw
end
function bonus_mode:draw()
	self=self or bonus_mode
 cls(1)
 bgstars:draw()
	for ball in all(self.balloons) do
		spr(30,ball.x,ball.y)
	end
 level:draw()
 osd:draw()
 player:draw()
	debug:draw()
end
function bonus_mode:new_balloon()
	local n=flr(rnd(4))+1
	local pipe=self.pipes[n]
	local anchor_x=pipe.col*8
	balloon={
		anchor_x=anchor_x,
		x=anchor_x,
		y=pipe.row*8,
		sine=0
	}
	add(self.balloons,balloon)
	self.counter+=1
end
function bonus_mode:update()
	self=self or bonus_mode
	ticks=ticks+1
	self.timer+=1
	if self.timer>self.delay then
		if self.counter>
				self.balloon_max then
			if count(self.balloons)==0 then
				change_mode('tally')
			end
		else
			self:new_balloon()
		end
		self.timer=0
	end
 bgstars:update()
 for ball in all(self.balloons) do
		ball.y-=1
		ball.sine+=0.01
		ball.x=ball.anchor_x+sin(ball.sine)*5
		ball.body={
			y=ball.y,
			x=ball.x,
			width=8,
			height=8
		}
		if ball.y<-8 then
			del(self.balloons,ball)
		end
		if collision(player.body,
				ball.body) then
			self.collected+=1
			del(self.balloons,ball)
		end
	end
 player:update()
 debug:update()
end

-------------------------------
-- tally
-------------------------------
tally_mode={
	step=20,
	value=300,
	super=10000
}
function tally_mode:init()
	self.timer=0
	self.state=1
	self.total=0
	self.state='init'
	if bonus_mode.collected then
		self.total=bonus_mode.collected*self.value
	end
	_draw=self.draw
	_update=self.update
end
function tally_mode:draw()
	self=self or tally_mode
	cls(1)
	osd:draw()
	local x=8
	local y=40
	spr(96,x,y,2,2,true)
	if self.timer<=self.step*2 then
		spr(30,x+20,y+4)
	else
		print('300',x+20,y+6)
	end
	local text=''
	if self.timer>self.step then
		text..='x '..tostr(bonus_mode.collected)
	end
	if self.timer>self.step*2 then
		text..=' = '..tostr(self.total)..' pts.'
	end
	if self.timer>self.step*3 then
		printc('p e r f e c t !!!',y+40,nil,nil,9)
		printc('super bonus  '..self.super..'pts!',y+50,nil,nil,9)
	end
	print(text,x+36,y+6,7)
end
function tally_mode:update()
	self=self or tally_mode
	if self.timer==self.step*2 then

	end
	if self.timer==self.step*3 then
		if bonus_mode.collected==bonus_mode.balloon_max then
			--sfx
			player.score+=self.super
		end
	end
	if self.state=='init' then
		self.timer+=1
		if self.timer>self.step*4 then
			self.state='countdown'
		end
	elseif self.state=='countdown' then
		if self.total<=0 then
			self.state='complete'
		else
			player.score+=100
			self.total-=100
		end
	else
		self.timer+=1
		if self.timer>self.step*5 then
			level:get(level.current+1)
			change_mode('play')
		end
	end
end

-------------------------------
-- trip
-------------------------------

-------------------------------
-- modes references
-------------------------------
modes={
	menu=menu_mode,
	play=play_mode,
	bonus=bonus_mode,
	tally=tally_mode,
	trip=trip_mode
}

-->8
-- bgstars

bgstars={}

function bgstars:init()
 for i=1,25 do
  local bgstar={
   x=flr(rnd(128)),
   y=flr(rnd(128))
  }
  add(self,bgstar)
 end
end
 
function bgstars:update()
 for bgstar in all(self) do
  if flr(rnd(100)) == 0 then
   bgstar.x=flr(rnd(128))
   bgstar.y=flr(rnd(128))
  end
 end
end
 
function bgstars:draw()
 for bgstar in all(self) do
  pset(bgstar.x,bgstar.y,13) 
 end
end

-->8
-- input

input={}

function input:get()
 self.x=0
 self.y=0
 self.b=false
 if btn(⬅️) and btn(➡️)==false then
  self.x=-1
 elseif btn(➡️) and btn(⬅️)==false then
  self.x=1
 else
  self.x=0
 end
 self.b4=btn(4,0)
 self.b5=btn(5,0)
end
-->8
-- level

level={
	current=10,
	celx=0,
	cely=0
}

-- draw level
function level:draw()
 map(self.celx,self.cely,0,0,16,16)
end
 
-- load map blocks
function level:get(n)
	self.current=n or self.current
	self.celx=self.current%10*16
	self.cely=flr(self.current/10)*16
end

function level:collision(rect1)
	for x=0,15 do
		for y=0,15 do
			local sprite=mget(self.celx+x,self.cely+y)
			local flag=fget(sprite,0)
			local rect2={
				x=x*8,y=y*8,width=8,height=8
			}
			if flag and collision(rect1,rect2) then
				return rect2
			end
		end
	end
	return false
end


-->8
-- player

player={
 x=0,
 y=0,
 width=16,
 height=16,
 anim=1,
 balloons=1,
 ball_anim=1,
 direction=right,
 lives=2,
 score=0,
 sprites={
 	floating=0,
  flapping={2,4,2,6},
  standing={32,34,32,36},
  running={38,40,38,42},
  dying={8,10,12,10}
 },
 vel={x=0,y=0},
 body={
 	x=0,y=0,width=8,height=16
 },
 ball_body={
		x=0,y=0,width=8,height=8
 }
}
 
-- process animation
function player:animate()
 
 if ticks%3==0 then
  self.anim+=1
  if self.anim>4 then
   self.anim=1
  end
 end
 
 if ticks%30==0 then
  self.ball_anim+=1
  if self.ball_anim>4 then
   self.ball_anim=1
  end
 end
 
 -- if we're dead
 if self.balloons==0 then
 	self.sprite=self.sprites.dying[self.anim]

	-- if we're not dead
	else
	 -- if on ground
	 if self.grounded then
	 	-- running
	 	if input.x~=0 then
				self.sprite=self.sprites.running[self.anim] 		
			-- standing still
	 	else
				self.sprite=self.sprites.standing[self.ball_anim]
	 	end
	 -- if flapping
	 elseif input.b4 or input.b5 then
			self.sprite=self.sprites.flapping[self.anim]
		--	if floating
		else
			self.sprite=self.sprites.floating
	 end
	 -- if we have 2 balloons
	 if self.balloons==2 then
			self.sprite=self.sprite+64
	 end
	 
	end

	 
end
 
-- draw player
function player:draw()
 local flip_x=false
 if self.direction==right then
  flip_x=true
 end
 spr(
 		self.sprite,
 		self.x,
 		self.y,
 		2,
 		2,
 		flip_x
	)
 rect(
 		self.body.x,
 		self.body.y,
 		self.body.x+
 				self.body.width,
 		self.body.y+
 				self.body.height,
 		10
 )
 rect(
 		self.ball_body.x,
 		self.ball_body.y,
 		self.ball_body.x+
 				self.ball_body.width,
			self.ball_body.y+
					self.ball_body.height,
			12
	)
end

-- update player movement
function player:update()

 -- add gravity
	self.vel.y+=gravity
 
	-- if we're dead
 if self.balloons==0 then
		-- *** maybe go up first
 	self.y+=self.vel.y
  
	-- if we're still alive
 else
 
 	-- are too high on screen?
	 if self.y<0 then
			self.vel.y=bounce
	 end
	 
	 -- get input from player
	 input:get()
	
	 -- set facing direction
	 if input.x<0 then
	 	self.direction=left
	 elseif input.x>0 then
	 	self.direction=right
	 end
	 
		-- propulsion (lift)
	 if input.b4 or input.b5 then
			self.vel.y-=force
			self.grounded=false
		end
	 
	 -- move while grounded
	 if self.grounded then
	 	if input.x==0 then
		 	self.vel.x=lerp(
		 			0,self.vel.x,0.5)
		 else
		 	self.vel.x+=input.x
		 			*gspeed
	 		self.vel.x=mid(
	 				-gspeed_max,
	 				self.vel.x,
	 				gspeed_max)
	 	end
	 	
		-- air move when flapping
	 else
	 	if input.b4 or input.b5 then
	 		self.vel.x+=input.x
	 				*aspeed
	 		self.vel.x=mid(
	 				-aspeed_max,
	 				self.vel.x,
	 				aspeed_max)
	 	end
	 	
	 end
	 
		local test_body={}
		test_body.width=self.body.width
		test_body.height=self.body.height
	 
	 -- y collisions (level) first
		test_body.x=self.body.x
		test_body.y=self.body.y
	 test_body.y+=self.vel.y
		local v_coll=level:collision(test_body)
		if v_coll then
			if self.vel.y<0 then
				self.vel.y=bounce
			elseif self.vel.y>0 then
				self.grounded=true
				self.vel.y=0
				self.y=v_coll.y-16
			end
		else
			self.grounded=false
		end
		
		-- check x collisions (level)
		test_body.x=self.body.x
		test_body.y=self.body.y
		test_body.x+=self.vel.x
		local h_coll=level:collision(test_body)
		if h_coll then
			self.vel.x=0
		end
								
		-- move for real		
		self.y+=self.vel.y
		self.x+=self.vel.x
		
		-- wrap at edges
		wrap(self)
		 
		-- update body position
		self.body.x=self.x+3
		if self.direction==right then
			self.body.x+=1
		end
		self.body.y=self.y
		
		-- update ball_body position
		self.ball_body.x=self.body.x
		self.ball_body.y=self.body.y
		
	end
	
	-- pick appropriate sprite	
	self:animate()
	
	debug.message=self.grounded

end

-->8
-- debug

poke(0x5f2d, 0x1)

debug={}

function debug:draw()
	print(self.message,0,0,7)
end

function debug:input()
	local key=stat(31)
	
	if key=='b' then
		player.balloons+=1
		if player.balloons>2 then
			player.balloons=1
		end
	end
	
	if key=='d' then
		player.balloons=0
	end
	
	if key=='e' then
		enemies:new(64,64)
	end
	
	if key=='l' then
		player.lives+=1
		if player.lives>2 then
			player.lives=0
		end
	end
	
	if key=='f' then
		balloons:new()
	end
	
	if key=='s' then
		player.score+=1
	end
	
end

function debug:update()
	--[[
	self.messages={
		'grnd:'..(player.grounded and '1' or '0'),
		'vely:'..player.vel.y,
		'velx:'..player.vel.x
	}
	self:input()
	]]
	self:input()
end
-->8
-- osd

osd={}

function osd:draw()

	-- score
	print('i-',8,2,8)
	print(pad(player.score,6),16,2,7)

	-- lives
	if player.lives>0 then
		local x=56
		spr(13+player.lives,x,0)
	end

	-- top
	print('top-',79,2,9)
	print('000000',95,2,7)

end

-->8
-- enemies

enemies={}

-- create new enemy
function enemies:new(x,y)

	local enemy={
		x=x,
		y=y,
		balloon=true,
		ball_body={
			x=x,
			y=y,
			width=8,
			height=8
		},
		body={
			x=x,
			y=y,
			width=8,
			height=16
		},
		vel={
			x=0,
			y=0
		},
		sprite=72
	}
	
	-- animate one enemy
	function enemy:animate()
		if self.grounded then
			self.sprite=1
		else
			self.sprite=72
		end
	end
	
	-- draw one enemy
	function enemy:draw()
		spr(
				self.sprite,
				self.x,
				self.y,
				2,
				2
		)
	end
	
	-- update one enemy
	function enemy:update()
		self.vel.y+=gravity
		self.y+=self.vel.y
		self.body.x=self.x+4
		self.body.y=self.y
		local test_body={}
		test_body.width=self.body.width
		test_body.height=self.body.height	 
	 -- y collisions (level) first
		test_body.x=self.body.x
		test_body.y=self.body.y
	 test_body.y+=self.vel.y
		local v_coll=level:collision(test_body)
		if v_coll then
			if self.vel.y<0 then
				self.vel.y=bounce
			elseif self.vel.y>0 then
				self.grounded=true
				self.vel.y=0
				self.y=v_coll.y-16
			end
		else
			self.grounded=false
		end		
		-- check x collisions (level)
		test_body.x=self.body.x
		test_body.y=self.body.y
		test_body.x+=self.vel.x
		local h_coll=level:collision(test_body)
		if h_coll then
			self.vel.x=0
		end			
		-- move for real		
		self.y+=self.vel.y
		self.x+=self.vel.x
		-- wrap at edges
		wrap(self)
		-- update body position
		self.body.x=self.x+3
		if self.direction==right then
			self.body.x+=1
		end
		self.body.y=self.y
		
	end

	add(self,enemy)

end

-- draw all enemies
function enemies:draw()
	for enemy in all(self) do
		enemy:draw()
	end
end

-- update all enemies
function enemies:update()
	for enemy in all(self) do
		enemy:update()
	end
end

__gfx__
11111088011111111111108801111111111110880111111111111088011111111111111111111111111111111111111111111111111111111111111111111111
11110887801111111111088780111111111108878011111111110887801111111111111111111111111111111111111111111111111111111111111111111111
11108888780111111110888878011111111088887801111111108888780111111111111111111111111111111111111111111111111111111118711118711871
1110888888011111111088888801111111108888880111111110888888011111111110ccc0111111111110ccc0111111111110ccc01111111118811118811881
1111088880111111111108888011111111110888801111111111088880111111110f0cfffc0f011111110cfffc01111111110cfffc0111111111711111711171
111110880111111111111088011111111111108801111111111110880111111110ff0cfffc0ff01111110cfffc01111111110cfffc0111111117111117111711
11111070111111111111107011111111111110701111111111111070111111111110c0fff0c01111111110fff0111111111110fff01111111111111111111111
11110ccc0111111111110ccc0111111111110ccc00f0111111110ccc0111111111110c888c01111110ffcc888ccff01111110c888c0111111111111111111111
11110ffcc011111111110ffcc011111111110ffcc0ff011111110ffcc01111111111088788011111110f0887880f01111110c88788c01111110bb01111088011
1110fffcc01111111110fffcc0ff01111110fffcc0c011111110fffcc0111111111108888801111111110888880111111110ff888ff0111110bb7b0110887801
11110ffc0111111111110ffc8ccf011111110ffc8c01111111110ffc880111111110c88088c011111110c88088c011111110f88088f011110bbbb7b008888780
1110f188c011111111111087880111111111108788011111111110878c01111111110c010c01111111110c010c01111111110c010c0111110bbbbbb008888880
11110878fc011111111111088801111111111108880111111111110888cf011111111111111111111111111111111111111111111111111110bbbb0110888801
110c8888ff011111111110cc80111111111110cc80111111111110cc80ff0111111111111111111111111111111111111111111111111111110bb01111088011
1110c801111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111110701111107011
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111107011111070111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111088011111111111111111111111111111111111111111111111088011111111111108801111111111110880111111111111111111111111111111111111
11110887801111111111108801111111111110880111111111111110887801111111111088780111111111108878011111111111111111111111111111111111
11108888780111111111088780111111111108878011111111111108888780111111110888878011111111088887801111111111111111111111111111111111
11108888880111111110888878011111111088887801111111111108888880111111110888888011111111088888801111111111111111111111111111111111
11110888801111111110888888011111111088888801111111111110888801111111111088880111111111108888011111111111111111111111111111111111
11111088011111111111088880111111111108888011111111111111088011111111111108801111111111110880111111111111111111111111111111111111
111110ccc0111111111110ccc0111111111110ccc01111111110ccc0070111111110ccc0070111111110ccc00701111111111111111111111111111111111111
111110ffcc011111111110ffcc011111111110ffcc0111111110ffcc701111111110ffcc701111111110ffcc7011111111111111111111111111111111111111
11110fffcc01111111110fffcc01111111110fffcc011111110fffcc01111111110fffcc01111111110fffcc0111111111111111111111111111111111111111
111110ffc0111111111110ffc0111111111110ffc01111111110ffc0111111111110ffc0cf0111111110ffc01111111111111111111111111111111111111111
11110c888c01111111110c888c01111111110c888c0111111111088c011111111110c88cff011111110ff8c80111111111111111111111111111111111111111
1110fc878fc011111110fc878fc011111110fc878fc01111111088fc01111111110f888011111111110ffc880111111111111111111111111111111111111111
1110f8888ff011111110f8888ff011111110f8888ff01111110f88ff0111111110c888880111111111108888c011111111111111111111111111111111111111
111108808801111111110880880111111111088088011111110cc08801111111110c0088c0111111111108088c01111111111111111111111111111111111111
1110cc010cc011111110cc010cc011111110cc010cc0111111110cc0111111111111110cc01111111110cc011111111111111111111111111111111111111111
1111108800880111111110880088011111111088008801111111108800880111111110bb01111111111110bb01111111111110bb011111111111111111111111
111108878287801111110887828780111111088782878011111108878287801111110bb7b011111111110bb7b011111111110bb7b01111111111111111111111
11108888782878011110888878287801111088887828780111108888782878011110bbbb7b0111111110bbbb7b0111111110bbbb7b0111111111111111111111
11108888882888011110888888288801111088888828880111108888882888011110bbbbbb0111111110bbbbbb0111111110bbbbbb0111111111111111111111
111108888288801111110888828880111111088882888011111108888288801111110bbbb011111111110bbbb011111111110bbbb01111111111111111111111
1111108800880111111110880088011111111088008801111111108800880111111110bb01111111111110bb01111111111110bb011111111111110d01111111
111110700701111111111070070111111111107007011111111110700701111111111070d011111111111070d011111111111070d01111111111044d01111111
11110ccc7011111111110ccc7011111111110ccc70f0111111110ccc7011111111110444d040111111110444d011111111110444d01111111110b7444dd01111
11110ffcc011111111110ffcc011111111110ffcc0ff011111110ffcc01111111110b744404401111110b744401111111110b744401111111044444bbddd0111
1110fffcc01111111110fffcc0ff01111110fffcc0c011111110fffcc01111111044444bb0b011111044444bb04401111044444bb011111110400bbbddddd011
11110ffc0111111111110ffc8ccf011111110ffc8c01111111110ffc8801111111110bbbdb01111111110bbbdbb4011111110bbbdd011111111110ddbbddd011
1110f088c011111111111087880111111111108788011111111110878c011111111110dddd011111111110dddd011111111110dddb0111111111110bbdd4d011
11110878fc011111111111088801111111111108880111111111110888cf01111111110ddd0111111111110ddd0111111111110dddb401111111110440044011
110c8888ff011111111110cc80111111111110cc80111111111110cc80ff011111111044d011111111111044d011111111111044d04401111111110401104011
1110c801111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11110880088011111111088011111111111111110880111111111088008801111111108800880111111110880088011111111111111111111111111111111111
111088782878011111108878288011111111088088f801111111088f828f80111111088f828f80111111088f828f801111111111111111111111111111111111
11088887828780111108888782780111111088f8288f801111108888f828f80111108888f828f80111108888f828f80111111111111111111111111111111111
110888888288801111088888828780111108888f8288801111108888882888011110888888288801111088888828880111111111111111111111111111111111
11108888288801111110888828888011110888888288011111110888828880111111088882888011111108888288801111111111111111111111111111111111
11110880088011111111088088880111111088882880111111111088008801111111108800880111111110880088011111111111111111111111111111111111
1111107ccc7011111111107ccc8011111111088ccc01111111110ccc0070111111110ccc0070111111110ccc0070111111111111111111111111111111111111
1111110ffcc011111111110ffcc011111111110ffcc0111111110ffcc701111111110ffcc701111111110ffcc701111111111111111111111111111111111111
111110fffcc01111111110fffcc01111111110fffcc011111110fffcc01111111110fffcc01111111110fffcc011111111111111111111111111111111111111
1111110ffc0111111111110ffc0111111111110ffc01111111110ffc0111111111110ffc0cf0111111110ffc0111111111111111111111111111111111111111
111110c888c01111111110c888c01111111110c888c0111111111088c011111111110c88cff011111110ff8c8011111111111111111111111111111111111111
11110fc878fc011111110fc878fc011111110fc878fc01111111088fc01111111110f888011111111110ffc88011111111111111111111111111111111111111
11110f8888ff011111110f8888ff011111110f8888ff01111110f88ff0111111110c888880111111111108888c01111111111111111111111111111111111111
1111108808801111111110880880111111111088088011111110cc08801111111110c0088c0111111111108088c0111111111111111111111111111111111111
11110cc010cc011111110cc010cc011111110cc010cc0111111110cc0111111111111110cc01111111110cc01111111111111111111111111111111111111111
11033b3333b33b3333b3301111111111065556701065670111111111111111111111111111111111111111111111111111111111111111111111111111111111
103bbb3bb33bbb3bb33bbb0111111111065556701065670111766711766711111111111111111111111111111111111111111111111111111111111111111111
0bb3bbbbbbb3bbbbbbb3bbb011111111065556701065670117666677666671111111111111111111111111111111111111111111111111111111111111111111
03444b3443444b3443444b3011111111065556701065670117666666666671111111111111111111111111111111111111111111111111111111111111111111
c76677ccc76677ccc76677ccc76677cc106567011065670117666666666666711111111111111111111111111111111111111111111111111111111111111111
76cc667776cc667776cc667776cc6677106567011065670176666666666666671111111111111111111111111111111111111111111111111111111111111111
6ccccc666ccccc666ccccc666ccccc66106567011065670176666666666666671111111111111111111111111111111111111111111111111111111111111111
cccccccccccccccccccccccccccccccc106567011065670176666666666666671111111111111111111111111111111111111111111111111111111111111111
03b33b3333b33b3333b33b3011111111104444011044440176666666666666671111111111111111111111111111111111111111111111111111111111111111
033bbb3bb33bbb3bb33bbb3011111111049999400499994076666666666666671111111111111111111111111111111111111111111111111111111111111111
0bb3bbbbbbb3bbbbbbb3bbb011111111049999400499994017666666666666711111111111111111111111111111111111111111111111111111111111111111
03444b3443444b3443444b3011111111049999400499994011176666666666711111111111111111111111111111111111111111111111111111111111111111
04999449949994499499944011111111049999401049940111176666776666711111111111111111111111111111111111111111111111111111111111111111
04999999999999999999940111111111049999401049940111117667117667111111111111111111111111111111111111111111111111111111111111111111
10499999999999999999401111111111049999401104401111111111111111111111111111111111111111111111111111111111111111111111111111111111
11044444444444444444011111111111104444011104401111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11999999999991111199999999999111119911111199111111999999999991111199999999999111119991111111911111111111111111111111111111111111
19999999999779111999999999977911199791111997911119999999999779111999999999977911199779111119791111111111111111111111111111111111
99999999999997919999999999999791999791119997911199999999999997919999999999999791999997911119979111111111111111111111111111111111
99999119999997919999911999999791999991119999911199999119999997919999911999999791999997911119979111111111111111111111111111111111
99991111999999919999111199999991999991119999911199991111999999919999111199999991999999991199999111111111111111111111111111111111
99991111999999919999111199999991999991119999911199991111999999919999111199999991999999999999999111111111111111111111111111111111
99999119999999119999911999999991999991119999911199999119999999919999911999999991999999999999999111111111111111111111111111111111
99999999999991119999999999999991999991119999911199999999999999919999999999999991999999999999999111111111111111111111111111111111
99999999999979119999999999999991999991119999911199999999999999919999999999999991999999999999999111111111111111111111111111111111
99999119999997919999911999999991999991119999911199999999999999919999999999999991999999999999999111111111111111111111111111111111
99991111999997919999111199999991999991119999911199999999999999919999999999999991999991199999999111111111111111111111111111111111
99991111999999919999111199999991999991119999911199999999999999919999999999999991999911119999999111111111111111111111111111111111
99999119999999919999111199999991999979119999791199999999999999919999999999999991999911119999999111111111111111111111111111111111
99999999999999919999111199999991999997919999979199999999999999919999999999999991999911119999999111111111111111111111111111111111
19999999999999111999111119999911199999911999999119999999999999111999999999999911199911111999991111111111111111111111111111111111
11999999999991111191111111999111119999111199991111999999999991111199999999999111119111111199911111111111111111111111111111111111
11999999999991111177111111999999999991111191111111999111119999999999911111111111111111111111111111111111111111111111111111111111
19999999999779111999711119999999999779111979111119977911199999999997791111111111111111111111111111111111111111111111111111111111
99999999999997919999711199999999999997919979111199999791999999999999979111111111111111111111111111111111111111111111111111111111
99999999999999119999911199999119999997919999111199999791199999999999991111111111111111111111111111111111111111111111111111111111
99999999999991119999911199991111199999119999911999999991119999999999911111111111111111111111111111111111111111111111111111111111
99999991111111119999911199991111111991119999999999999991111199999911111111111111111111111111111111111111111111111111111111111111
99999911111111119999911199991111111111119999999999999991111199999911111111111111111111111111111111111111111111111111111111111111
99999911111111119999911199991111111111119999999999999991111199999911111111111111111111111111111111111111111111111111111111111111
99999999999999119999911199991999999991119999999999999991111199999911111111111111111111111111111111111111111111111111111111111111
99999999999977919999911199991999999779119999999999999991111199999911111111111111111111111111111111111111111111111111111111111111
99999999999999119999911199991199999997919999999999999991111199999911111111111111111111111111111111111111111111111111111111111111
99999911111111119999911199991111999997919999911999999991111199999911111111111111111111111111111111111111111111111111111111111111
99999911111111119999911199991111999999919999111199999991111199999911111111111111111111111111111111111111111111111111111111111111
99999911111111119999911199999119999999919999111199999991111199999911111111111111111111111111111111111111111111111111111111111111
19999111111111111999911119999999199999111999111119999911111119999111111111111111111111111111111111111111111111111111111111111111
11991111111111111199111111999991119991111191111111999111111111991111111111111111111111111111111111111111111111111111111111111111
__gff__
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101010204040000000000000000000001010101010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
bfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbf
bfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbf
bfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff00ff9092ff0000ffffffff90919200bfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbf
bfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff00ffffffffffffffffffffff94ff00bfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbf
bfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfffffffffffffffff8687ffffffffffffffffffffffffffffbfbfff91919191ffff00ffffffffffbfbfbfffffff95ff00bfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbf
bfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfffffffffffffffff9697ffffffffffffff9191919191ffffbfbfffffffffffffff00ffffffffff909192ffffffffff00bfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbf
bfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfffffffffffffffffffffffffffffffffffffffffffffffffffffffff8687ffffff00ffffffffffff94ffffffffffff00bfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbf
bfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfffffffffffffffffffffffffffffffffffffffffffffffffffffffff9697ffffff00ffffffffffff95ffffffffffff00bfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbf
bfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfffffffffffffffbfffffffffffffffff8687ffffffffffbfffffffffffffffffff00909192ffbfffffffffffffffff00bfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbf
bfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfffffffffbfbfbfbfbfbfffbfbfffffff9697ffffbfbfbfbfbfbfffbfbfffffffff00ff94bfbfbfbfbfffbfbfffffff00bfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbf
bfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbf9091919191919192ffffffffbfbfbfbf9091919191919192ffffffffbfbfbf95bfffffffffffffffffffffffbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbf
bfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffbfffffffffffffffffffffbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbf
bfbfbfbfbf84bfbfbfbfbfbfbfbfbfbfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff909192ffffffffffffbfbfbfbfbf84bfbfbfbfbfbfbfbfbfbfbfbfbfbfbf84bfbfbfbfbfbfbfbfbfbfbfbfbfbfbf84bfbfbfbfbfbfbfbfbfbfbfbfbfbfbf84bfbfbfbfbfbfbfbfbfbf
bfbf84bfbf85bfbfbfbfbfbfbf84bfbfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffbfbf84bfbf85bfbfbfbfbfbfbf84bfbfbfbf84bfbf85bfbfbfbfbfbfbf84bfbfbfbf84bfbf85bfbfbfbfbfbfbf84bfbfbfbf84bfbf85bfbfbfbfbfbfbf84bfbf
bfbf85bfbf85bfbfbfbf84bfbf85bfbfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffbfbf85bfbf85bfbfbfbf84bfbf85bfbfbfbf85bfbf85bfbfbfbf84bfbf85bfbfbfbf85bfbf85bfbfbfbf84bfbf85bfbfbfbf85bfbf85bfbfbfbf84bfbf85bfbf
9191919191919191919191919191919181818182838383838383838380818181818181828383838383838383808181818181818283838383838383838081818191919191919191919191919191919191919191919191919191919191919191919191919191919191919191919191919191919191919191919191919191919191
bfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbf
bfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbf
bfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbf
bfbf949494949494bfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbf
bfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbf
bfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbf
bfbfbfbfbfffbfbfffffffbfbfbfbfbfbfbfbfbf1fbfbfbf1fbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbf
bfbfbfbfbfffbfbfffbfffbfbfbfbfbfbfbfbfbf1fbfbfbf1fbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbf
bfbfbfbfbfffbfbfffbfffbfbfbfbfbfbfbfbfbf1fbfbfbf1fbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbf
bfbfbfbfbfffbfbfffffffbfbfbfbfbfbfbfbfbf1fbfbfbf1fbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbf
bfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbf
ffbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbf
ffbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbf84bfbfbfbfbfbfbfbfbfbfbfbfbfbfbf84bfbfbfbfbfbfbfbfbfbfbfbfbfbfbf84bfbfbfbfbfbfbfbfbfbfbfbfbfbfbf84bfbfbfbfbfbfbfbfbfbfbfbfbfbfbf84bfbfbfbfbfbfbfbfbfbfbfbfbfbfbf84bfbfbfbfbfbfbfbfbfbf
ffbfbf94bfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbf84bfbfbfbf84bfbf85bfbfbfbfbfbfbf84bfbfbfbf84bfbf85bfbfbfbfbfbfbf84bfbfbfbf84bfbf85bfbfbfbfbfbfbf84bfbfbfbf84bfbf85bfbfbfbfbfbfbf84bfbfbfbf84bfbf85bfbfbfbfbfbfbf84bfbfbfbf84bfbf85bfbfbfbfbfbfbf84bfbf
ffbfbf94bfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbf85bfbfbfbf85bfbf85bfbfbfbf84bfbf85bfbfbfbf85bfbf85bfbfbfbf84bfbf85bfbfbfbf85bfbf85bfbfbfbf84bfbf85bfbfbfbf85bfbf85bfbfbfbf84bfbf85bfbfbfbf85bfbf85bfbfbfbf84bfbf85bfbfbfbf85bfbf85bfbfbfbf84bfbf85bfbf
9191919191919191919191919191919191919191919191919191919191919191919191919191919191919191919191919191919191919191919191919191919191919191919191919191919191919191919191919191919191919191919191919191919191919191919191919191919191919191919191919191919191919191
