-- Retro Gadgets

local rmath = require("rg_math")
local rg3d  = require("rg_3d")

local function debug_triangle(_p1,_p2,_p3)
	gdt.VideoChip0:DrawLine(_p1,_p2,color.red)
	gdt.VideoChip0:DrawLine(_p2,_p3,color.red)
	gdt.VideoChip0:DrawLine(_p3,_p1,color.red)
end

local function draw_triangle(_p1,_p2,_p3)
	debug_triangle(_p1,_p2,_p3)
end

rg3d:push_perspective(
	gdt.VideoChip0.Width / gdt.VideoChip0.Height,    -- screen aspect ratio
	1.23, -- FOV (radians)
	0.1,  -- near clip
	10    -- far clip
)

local screen_width  = gdt.VideoChip0.Width
local screen_height = gdt.VideoChip0.Height

print(       vec2( 1.2, 3.4           ) )
print( rmath:vec4( 1.2, 3.4, 5.6, 7.8 ) )

local function line_intersect_plane(_start, _end, _plane_pos, _plane_normal )
	_plane_normal = rmath:vec3_normalize(_plane_normal)
	local plane_d = -rmath:vec3_dot(_plane_normal,_plane_pos)
	local ad = rmath:vec3_dot(_start, _plane_normal)
	local bd = rmath:vec3_dot(_end, _plane_normal)
	local t = (-plane_d - ad) / (bd - ad)
	
	if t < 0 or t > 1 then return nil end
	
	local start_to_end = _end - _start
	local line_to_intersect = start_to_end * t
	
	return _start + line_to_intersect
end

-- update function is repeated every time tick
function update()
	gdt.VideoChip0:Clear(color.black)


	-- draw triangles
	do
		-- in world space
		local vertex_data = {
			-- bottom quad
			rmath:vec4(-0.5, -0.5, 0.0, 1),
			rmath:vec4(-0.5,  0.5, 0.0, 1),
			rmath:vec4( 0.5, -0.5, 0.0, 1),
	
			rmath:vec4(-0.5,  0.5, 0.0, 1),
			rmath:vec4( 0.5,  0.5, 0.0, 1),
			rmath:vec4( 0.5, -0.5, 0.0, 1),
	
			-- top quad
			rmath:vec4(-0.5, -0.5 + 1, 0.0, 1),
			rmath:vec4(-0.5,  0.5 + 1, 0.0, 1),
			rmath:vec4( 0.5, -0.5 + 1, 0.0, 1),
	
			rmath:vec4(-0.5,  0.5 + 1, 0.0, 1),
			rmath:vec4( 0.5,  0.5 + 1, 0.0, 1),
			rmath:vec4( 0.5, -0.5 + 1, 0.0, 1)
		}
		
		local s = math.sin(gdt.CPU0.Time * 0.3)
		rg3d:push_look_at(vec3(1.5,0,2), vec3(0,s*3,0), vec3(0,1,0))
		
		-- raster
		local p1, p2, p3
		for i = 1, #vertex_data, 3 do
			p1 = vertex_data[i]
			p2 = vertex_data[i + 1]
			p3 = vertex_data[i + 2]
			rg3d:raster_triangle({p1,p2,p3},screen_width,screen_height)
		end
	end

	-- line intersect test
	do
		local lineX = math.cos(gdt.CPU0.Time * 3) * 50 + 60
		local lineY = math.sin(gdt.CPU0.Time * 3) * 70 + 80
		local lineA = vec3(0,0,0)
		local lineB = vec3(lineX,lineY,0)
		local plane = vec3(50,0,0)
		local plane_n = vec3(1,0,0)
		local intersect = line_intersect_plane(lineA,lineB,plane,plane_n)

		local last_pos = lineB
		local trail_segments = 20
		local trail_len = 0.5
		for i=0,trail_segments do
			local t = gdt.CPU0.Time - (i / trail_segments * trail_len)
			local pX = math.cos(t * 3) * 50 + 60
			local pY = math.sin(t * 3) * 70 + 80
			local pos = vec2(pX,pY)
			gdt.VideoChip0:DrawLine(last_pos, pos, color.white)
			last_pos = pos
		end

		gdt.VideoChip0:DrawLine(lineA,lineB, color.red)
		gdt.VideoChip0:DrawLine(vec2(50,0),vec2(50,screen_height), color.green)
		if intersect ~= nil then
			gdt.VideoChip0:FillCircle(intersect,3,color.black)
			gdt.VideoChip0:DrawCircle(intersect,3,color.white)
		end
	end
end