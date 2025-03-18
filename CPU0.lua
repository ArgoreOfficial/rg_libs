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
	rmath:vec4( 0.5, 0.0, -0.5, 1),

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

local function inl_if(_condition,_a,_b)
	return _condition and _a or _b
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

local function select_mip(_dval, _max)
	local n = mip_function(1 / _dval)

	local po2 = round_to_po2(n) -- divident power of two
	local mip = math.log(po2)/math.log(2.0) + 1 -- po2 exponent
	if mip > _max then
		mip = _max
		po2 = math.pow(2, mip-1)
	end

	return mip, po2
end

local last_mip = 0
function mip_test(_p1,_p2,_p3,_p4)

	local minx = math.min(_p1.X, _p2.X, _p3.X, _p4.X)
	local miny = math.min(_p1.Y, _p2.Y, _p3.Y, _p4.Y)
	local maxx = math.max(_p1.X, _p2.X, _p3.X, _p4.X)
	local maxy = math.max(_p1.Y, _p2.Y, _p3.Y, _p4.Y)

	local width = maxx-minx
	local height = maxy-miny

	local base_width = 200
	local base_height = 200

	local full_width = 300
	local full_height = 200

	local mip, po2 = select_mip(width/base_width, 4)
	local mval = 1 / po2 -- mip width

	local w = base_width  * mval
	local h = base_height * mval
	
	local x = inl_if(mip == 1, 0, base_width)
	local y = get_mip_height(mip, base_height)
	
	local u = vec2(x, y)
	local v = u + vec2(w,h)

	local tl = vec2(minx,miny)

	gdt.VideoChip0:DrawCustomSprite(tl, miptexture, vec2(0,0), vec2(full_width,full_height), color.white, color.clear )
	
	gdt.VideoChip0:DrawRect(tl + u, tl + v, color.black)
	gdt.VideoChip0:RasterCustomSprite(_p1,_p2,_p3,_p4,miptexture,u,vec2(w,h),color.white,color.clear)
	gdt.VideoChip0:RasterCustomSprite(
		vec2(0,base_height) + tl,
		vec2(0,base_height) + tl+vec2(base_width, 0),
		vec2(0,base_height) + tl+vec2(base_width,base_height),
		vec2(0,base_height) + tl+vec2( 0,base_height),
		miptexture,
		u,vec2(w,h),
		color.white,color.clear)
end

-- update function is repeated every time tick
function update()
	gdt.VideoChip0:RenderOnBuffer(1)
	gdt.VideoChip0:Clear(color.blue)
	local t = gdt.CPU0.Time

	cam_dist = math.sin(t * 1.7) * 20 + 30
	local s  = math.sin(t * 0.7)
	local c  = math.cos(t * 0.7)
	rg3d:push_look_at(
		vec3(c * cam_dist, c * cam_dist * 0.75, s * cam_dist), 
		vec3(0,0,0),
		vec3(0,1,0))
	
	-- draw faces
	local p1, p2, p3
	
	local hcount = draw_count/2
	for y=-hcount,hcount do
		for x=-hcount,hcount do
			for tri = 1, #vertex_data, 3 do
				p1 = vertex_data[tri    ] + rmath:vec4(-x,0,y,0)
				p2 = vertex_data[tri + 1] + rmath:vec4(-x,0,y,0)
				p3 = vertex_data[tri + 2] + rmath:vec4(-x,0,y,0)
				rg3d:raster_triangle({p1,p2,p3},screen_width,screen_height)
			end
		end
	end

	gdt.VideoChip0:RenderOnScreen()
	gdt.VideoChip0:Clear(color.black)
	
	local size = math.sin(t * 0.3) * 90 + 100

	local p1 = vec2(10,  10)
	local p2 = vec2(size, 10)
	local p3 = vec2(size, size)
	local p4 = vec2(10,size)

	local rb1 = gdt.VideoChip0.RenderBuffers[1]
	gdt.VideoChip0:DrawRenderBuffer(vec2(0,0),rb1,rb1.Width,rb1.Height)
	gdt.VideoChip0:RasterRenderBuffer(p1,p2,p3,p4,rb1)

	mip_test(p1,p2,p3,p4)
end