-- Retro Gadgets

local rmath = require("rg_math")
local rg3d  = require("rg_3d")

local spritesheet = gdt.ROM.User.SpriteSheets["assets/vulkan_blue.png"]
local miptexture  = gdt.ROM.User.SpriteSheets["assets/mipmap.png"]
local v = require( "assets/vulkan_blue" )

rg3d:push_perspective(
	gdt.VideoChip0.Width / gdt.VideoChip0.Height,    -- screen aspect ratio
	1.22, -- FOV (radians)
	0.5,  -- near clip
	50    -- far clip
)

local screen_width  = gdt.VideoChip0.Width
local screen_height = gdt.VideoChip0.Height

local vertex_data = {
	-- bottom quad
	rmath:vec4(-0.5, 0.0, -0.5, 1),
	rmath:vec4(-0.5, 0.0,  0.5, 1),
	rmath:vec4( 0.5, 0.0,  0.5, 1),
	rmath:vec4( 0.5, 0.0, -0.5, 1)
}

local draw_count = 40
local cam_dist = 40
print("drawing " .. tostring(3 * draw_count * draw_count) .. " faces")

local bit32 = require("RetroGadgets.bit32")

local function round_down_to_PO2(_x)
    _x = bit32.bor( _x, bit32.rshift(_x,  1) )
    _x = bit32.bor( _x, bit32.rshift(_x,  2) )
    _x = bit32.bor( _x, bit32.rshift(_x,  4) )
    _x = bit32.bor( _x, bit32.rshift(_x,  8) )
    _x = bit32.bor( _x, bit32.rshift(_x, 16) )
    return _x - bit32.rshift(_x, 1)
end

local function round_up_to_PO2(_x)
	_x = _x - 1
	_x = bit32.bor(_x, bit32.rshift(_x, 1 ))
	_x = bit32.bor(_x, bit32.rshift(_x, 2 ))
	_x = bit32.bor(_x, bit32.rshift(_x, 4 ))
	_x = bit32.bor(_x, bit32.rshift(_x, 8 ))
	_x = bit32.bor(_x, bit32.rshift(_x, 16 ))
	return _x + 1
end

local function round_to_po2(_n)
	local v = _n - 1
	v = bit32.bor(v, bit32.rshift(v, 1))
	v = bit32.bor(v, bit32.rshift(v, 2))
	v = bit32.bor(v, bit32.rshift(v, 4))
	v = bit32.bor(v, bit32.rshift(v, 8))
	v = bit32.bor(v, bit32.rshift(v, 16))
	v = v + 1 -- next power of 2

	local x = bit32.rshift(v, 1 ) -- previous power of 2

	return (math.abs(v - _n) > math.abs(_n - x)) and x or v
end

local function get_mip_height(_mip,_base_height)
	local y = 0
	local mip = 2
	while mip < _mip do
		local mp = math.pow(2,mip-1)
		local mv = 1 / mp
		y = y + _base_height * mv
		mip = mip + 1
	end
	return y
end

local function mip_func_round(_v) return math.floor(_v+0.5) end
local function mip_func_floor(_v) return math.floor(_v)     end
local function mip_func_ceil (_v) return math.ceil (_v)     end
local mip_function = mip_func_round

local function select_mip(_dval, _max, _mip_function)
	local n = _mip_function(1/_dval)

	local po2 = round_to_po2(n) -- divident power of two
	local mip = math.log(po2)/math.log(2.0) + 1 -- po2 exponent
	if mip > _max then
		mip = _max
		po2 = math.pow(2, mip-1)
	end

	return mip, po2
end

function get_mip_UVs(_p1,_p2,_p3,_p4, _base_width, _base_height, _mip_function)
	local minx = math.min(_p1.X, _p2.X, _p3.X, _p4.X)
	local maxx = math.max(_p1.X, _p2.X, _p3.X, _p4.X)

	local width = maxx-minx
	
	local mip, po2 = select_mip(width/_base_width, 15, _mip_function and _mip_function or mip_function)
	local mval = 1 / po2 -- mip width

	local w = _base_width  * mval
	local h = _base_height * mval
	
	local x = mip == 1 and 0 or _base_width
	local y = get_mip_height(mip, _base_height)
	local u = vec2(x, y)
	local v = vec2(w, h)

	return u, v
end

function mip_test(_p1,_p2,_p3,_p4)

	local minx = math.min(_p1.X, _p2.X, _p3.X, _p4.X)
	local miny = math.min(_p1.Y, _p2.Y, _p3.Y, _p4.Y)
	local u, v = get_mip_UVs(_p1, _p2, _p3, _p4, 200, 200, mip_func_floor)

	local base_width = 200
	local base_height = 200

	local full_width = 300
	local full_height = 200
	
	local tl = vec2(minx,miny)

	gdt.VideoChip0:DrawCustomSprite(tl, miptexture, vec2(0,0), vec2(full_width,full_height), color.white, color.clear )
	
	gdt.VideoChip0:DrawRect(tl + u, tl + u + v, color.black)
	gdt.VideoChip0:RasterCustomSprite(_p1,_p2,_p3,_p4,miptexture,u,v,color.white,color.clear)
	gdt.VideoChip0:RasterCustomSprite(
		vec2(0,base_height) + tl,
		vec2(0,base_height) + tl+vec2(base_width, 0),
		vec2(0,base_height) + tl+vec2(base_width,base_height),
		vec2(0,base_height) + tl+vec2( 0,base_height),
		miptexture,
		u,v,
		color.white,color.clear)
end

local cam_pos = vec3(10,10,10)
local cam_pitch = 0
local cam_yaw   = rmath.const.PI
local cam_dir = vec3(0,0,-1)

local function rot_to_dir(_pitch, _yaw)
	return vec3(
		math.cos(_yaw)*math.cos(_pitch),
		math.sin(_pitch),
		math.sin(_yaw)*math.cos(_pitch)
	)
end

local function update_dir(_v)
	local wish_pitch = 0
	local wish_yaw   = 0

	if love.keyboard.isDown("left")  then wish_yaw = wish_yaw - 1 end
	if love.keyboard.isDown("right") then wish_yaw = wish_yaw + 1 end

	if love.keyboard.isDown("up")   then wish_pitch = wish_pitch + 1 end
	if love.keyboard.isDown("down") then wish_pitch = wish_pitch - 1 end

	cam_pitch = cam_pitch + wish_pitch * _v
	cam_yaw   = cam_yaw   + wish_yaw   * _v
	cam_pitch = math.min(cam_pitch,  rmath:radians(85))
	cam_pitch = math.max(cam_pitch, -rmath:radians(85))
	cam_dir = rot_to_dir(cam_pitch, cam_yaw)
end

local function get_move_wish()
	local move_input = vec3(0,0,0)
	
	if love.keyboard.isDown('w') then move_input = move_input + vec3(0,0, 1) end
	if love.keyboard.isDown('s') then move_input = move_input + vec3(0,0,-1) end

	if love.keyboard.isDown('a') then move_input = move_input + vec3(-1,0,0) end
	if love.keyboard.isDown('d') then move_input = move_input + vec3( 1,0,0) end

	if love.keyboard.isDown("space")  then move_input = move_input + vec3(0, 1,0) end
	if love.keyboard.isDown("lshift") then move_input = move_input + vec3(0,-1,0) end

	local up      = vec3(0,1,0)
	local right   = rot_to_dir(0, cam_yaw + rmath:radians(90))
	local forward = rot_to_dir(cam_pitch, cam_yaw)

	local move_wish = right   * move_input.X + 
	                  up      * move_input.Y + 
	                  forward * move_input.Z

	return rmath:vec3_normalize(move_wish)
end

local function raster_quad(_p1,_p2,_p3,_p4)
	gdt.VideoChip0:FillTriangle( _p1, _p2, _p3, color.blue )
	gdt.VideoChip0:FillTriangle( _p1, _p3, _p4, color.blue )
end

local function raster_quad_sprite(_p1,_p2,_p3,_p4)
	local z = math.max(_p1.Z, _p2.Z, _p3.Z, _p4.Z)
	local c = 1 - (z / 50) -- z / g_far
	local col = ColorRGBA(255 * c, 255 * c, 255 * c, 255 * c)

	gdt.VideoChip0:RasterCustomSprite(_p1,_p2,_p3,_p4,miptexture,vec2(0,0),vec2(200,200),col,color.clear)
end

local function raster_quad_sprite_mipped(_p1,_p2,_p3,_p4)
	local u, v = get_mip_UVs(_p1, _p2, _p3, _p4, 200, 200)

	local z = math.max(_p1.Z, _p2.Z, _p3.Z, _p4.Z)
	local c = 1 - (z / 50) -- z / g_far
	local col = ColorRGBA(255*c, 255*c, 255*c, 255*c)

	gdt.VideoChip0:RasterCustomSprite(_p1,_p2,_p3,_p4,miptexture,u,v,col,color.clear)
end

local function raster_tri_sprite(_p1,_p2,_p3)
	gdt.VideoChip0:DrawTriangle(_p1,_p2,_p3,color.white)
end

-- update function is repeated every time tick
function update()
	gdt.VideoChip0:RenderOnBuffer(1)
	gdt.VideoChip0:Clear(color.cyan)
	local t = gdt.CPU0.Time
	local dt = gdt.CPU0.DeltaTime

	update_dir(dt)
	local speed = 5
	if love.keyboard.isDown("lctrl") then speed = speed * 4 end
	cam_pos = cam_pos + get_move_wish() * dt * speed
	
	rg3d:push_look_at(
		cam_pos, 
		cam_pos + cam_dir,
		vec3(0,1,0))
	
	-- draw faces
	local p1, p2, p3, p4
	
	rg3d:set_quad_func(nil)
	rg3d:set_tri_func(nil)

	local hcount = draw_count/2
	for y=-hcount,hcount do
		if y < 0 then
			rg3d:set_quad_func(raster_quad_sprite_mipped)
		else
			rg3d:set_quad_func(raster_quad_sprite)
		end
		for x=-hcount,hcount do
			for tri = 1, #vertex_data, 4 do
				p1 = vertex_data[tri    ] + rmath:vec4(-x,0,y,0)
				p2 = vertex_data[tri + 1] + rmath:vec4(-x,0,y,0)
				p3 = vertex_data[tri + 2] + rmath:vec4(-x,0,y,0)
				p4 = vertex_data[tri + 3] + rmath:vec4(-x,0,y,0)
				rg3d:raster_quad({p1,p2,p3,p4},screen_width,screen_height)
			end
		end
	end

	rg3d:set_quad_func(raster_quad_sprite) -- set to custom
	rg3d:set_tri_func(raster_tri_sprite) -- set to custom

	rg3d:raster_quad({
		rmath:vec4(0.0, 1.0, 0.0, 1),
		rmath:vec4(1.0, 1.0, 0.0, 1),
		rmath:vec4(1.0, 1.0, 1.0, 1),
		rmath:vec4(0.0, 1.0, 1.0, 1)
	}, screen_width, screen_height)

	gdt.VideoChip0:RenderOnScreen()
	gdt.VideoChip0:Clear(color.black)
	
	local size = math.sin(t * 0.3) * 90 + 100

	local p1 = vec2(10,  10)
	local p2 = vec2(size, 10)
	local p3 = vec2(size, size)
	local p4 = vec2(10,size)

	local rb1 = gdt.VideoChip0.RenderBuffers[1]
	gdt.VideoChip0:DrawRenderBuffer(vec2(0,0),rb1,rb1.Width,rb1.Height)
	--gdt.VideoChip0:RasterRenderBuffer(p1,p2,p3,p4,rb1)

	--mip_test(p1,p2,p3,p4)
end