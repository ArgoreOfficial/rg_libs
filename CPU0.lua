-- Retro Gadgets

local rmath = require("rg_math")
local rg3d  = require("rg_3d")

local miptexture  = gdt.ROM.User.SpriteSheets["mipmap64.png"]
local miptexture_vis  = gdt.ROM.User.SpriteSheets["mipmap64_vis.png"]
local current_mip_texture = miptexture
local rb1 = gdt.VideoChip0.RenderBuffers[1]

gdt.VideoChip0:SetRenderBufferSize(1, gdt.VideoChip0.Width, gdt.VideoChip0.Height)
-- this has to be grabbed after because of love2d stuff

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
	vec3(-0.5, 0.0, -0.5),
	vec3(-0.5, 0.0,  0.5),
	vec3( 0.5, 0.0,  0.5),
	vec3( 0.5, 0.0, -0.5)
}

local draw_count = 40
print("drawing " .. tostring(3 * draw_count * draw_count) .. " faces")

local cam_pos   = vec3(10,10,10)
local cam_pitch = 0
local cam_yaw   = rmath.const.PI
local cam_dir   = vec3(0,0,-1)

local function rot_to_dir(_pitch, _yaw)
	return vec3(
		math.cos(_yaw)*math.cos(_pitch),
		math.sin(_pitch),
		math.sin(_yaw)*math.cos(_pitch)
	)
end

local rinput = {}
function eventChannel1(_sender,_event)
	rinput[_event.InputName] = _event.ButtonDown
end

local function update_dir(_v)
	local wish_pitch = 0
	local wish_yaw   = 0

	if rinput["LeftArrow"] then wish_yaw = wish_yaw - 1 end
	if rinput["RightArrow"] then wish_yaw = wish_yaw + 1 end

	if rinput["UpArrow"]   then wish_pitch = wish_pitch + 1 end
	if rinput["DownArrow"] then wish_pitch = wish_pitch - 1 end

	cam_pitch = cam_pitch + wish_pitch * _v
	cam_yaw   = cam_yaw   + wish_yaw   * _v
	cam_pitch = math.min(cam_pitch,  rmath:radians(85))
	cam_pitch = math.max(cam_pitch, -rmath:radians(85))
	cam_dir = rot_to_dir(cam_pitch, cam_yaw)
end

local function get_move_wish()
	local move_input = vec3(0,0,0)
	
	if rinput["W"] then move_input = move_input + vec3(0,0, 1) end
	if rinput["S"] then move_input = move_input + vec3(0,0,-1) end

	if rinput["A"] then move_input = move_input + vec3(-1,0,0) end
	if rinput["D"] then move_input = move_input + vec3( 1,0,0) end

	if rinput["E"] then move_input = move_input + vec3(0, 1,0) end
	if rinput["Q"] then move_input = move_input + vec3(0,-1,0) end

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

	gdt.VideoChip0:RasterCustomSprite(_p1,_p2,_p3,_p4, current_mip_texture, vec2(0,0), vec2(64,64), color.white, color.clear)
end

--[[

-- TODO:
RasterCustomSpriteTriangle(_p1,_p2,_p3, current_mip_texture, vec2(0,0), vec3(64,0), vec3(0,64), color.white, color.clear)

]]

local function raster_quad_sprite_mipped(_p1,_p2,_p3,_p4)
	local u, v = rg3d:get_mip_UVs(_p1, _p2, _p3, _p4, 64, 64)
	local z = math.max(_p1.Z, _p2.Z, _p3.Z, _p4.Z)
	local c = (1 - (z / 50))*255 -- z / g_far
	local fog = Color(c, c, c)
	gdt.VideoChip0:RasterCustomSprite(_p1,_p2,_p3,_p4, current_mip_texture, u, v, fog, color.clear)
end

local function raster_quad_sprite_blend_mipped(_p1,_p2,_p3,_p4)
	local u, v, fraction = rg3d:get_mip_UVs(_p1, _p2, _p3, _p4, 64, 64, rg3d.mip_func_floor)
	local mip = rg3d:get_mip_level(_p1, _p2, _p3, _p4, 64, 64, rg3d.mip_func_floor)

	local z = math.max(_p1.Z, _p2.Z, _p3.Z, _p4.Z)
	local c = (1 - (z / 50))*255 -- z / g_far
	local fog = Color(c, c, c)
	local mip0col = ColorRGBA(fog.R, fog.G, fog.B, (1-fraction) * 255)
	
	local u2, v2 = rg3d:get_mip_level_UVs(mip+1, 64, 64)
	
	gdt.VideoChip0:RasterCustomSprite(_p1, _p2, _p3, _p4, current_mip_texture, u2, v2,     fog, color.clear)
	gdt.VideoChip0:RasterCustomSprite(_p1, _p2, _p3, _p4, current_mip_texture,  u,  v, mip0col, color.clear)
end

local function raster_tri_sprite(_p1,_p2,_p3)
	gdt.VideoChip0:DrawTriangle(_p1,_p2,_p3,color.green)
end

local mip_toggle = false
local mip_n = 1

-- update function is repeated every time tick
function update()
	gdt.VideoChip0:RenderOnBuffer(1)
	gdt.VideoChip0:Clear(color.cyan)
	rg3d:set_quad_func(nil) -- reset
	rg3d:set_tri_func(nil)

	local dt = gdt.CPU0.DeltaTime

	if rinput["M"] and not mip_toggle then 
		if mip_n == 1 then 
			current_mip_texture = miptexture
			mip_n = 0 
		elseif mip_n == 0 then
			current_mip_texture = miptexture_vis
			mip_n = 1 
		end
	end
	mip_toggle = rinput["M"]

	update_dir(dt)
	local speed = 5
	if rinput["LeftShift"] then speed = speed * 4 end
	cam_pos = cam_pos + get_move_wish() * dt * speed
	
	rg3d:push_look_at(
		cam_pos, 
		cam_pos + cam_dir,
		vec3(0,1,0))
	
	-- draw faces
	local p1, p2, p3, p4
	
	local hcount = draw_count/2
	for y=-hcount,hcount do
		local o = 0
		if y < 0 then
			o = -1 
			rg3d:set_quad_func(raster_quad_sprite_mipped)
		else
			o = 1
			rg3d:set_quad_func(raster_quad_sprite_blend_mipped)
		end
		for x=-hcount,hcount do
			for tri = 1, #vertex_data, 4 do
				p1 = vertex_data[tri    ] + rmath:vec4(-x,0,y + o,0)
				p2 = vertex_data[tri + 1] + rmath:vec4(-x,0,y + o,0)
				p3 = vertex_data[tri + 2] + rmath:vec4(-x,0,y + o,0)
				p4 = vertex_data[tri + 3] + rmath:vec4(-x,0,y + o,0)
				rg3d:raster_quad({p1,p2,p3,p4},screen_width,screen_height)
			end
		end
	end

	rg3d:set_quad_func(nil) -- set to custom
	rg3d:set_tri_func(raster_tri_sprite) -- set to custom

	rg3d:raster_quad({
		vec3(0.0, 1.0, 0.0),
		vec3(1.0, 1.0, 0.0),
		vec3(1.0, 1.0, 1.0),
		vec3(0.0, 1.0, 1.0)
	}, screen_width, screen_height)

	gdt.VideoChip0:RenderOnScreen()
	gdt.VideoChip0:Clear(color.black)

	gdt.VideoChip0:DrawRenderBuffer(vec2(0,0),rb1,rb1.Width,rb1.Height)
end