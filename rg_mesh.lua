local lib = {}

local obj_loader = require "obj_loader"

function lib:parse_obj(_path)
	local asset = obj_loader.load(_path)
	local mesh = {}
	
	for i = 1, #asset.f do
		local face = {}
		local face_str = "  { "
		for f = 1, #asset.f[i] do
			local vert = asset.v[asset.f[i][f].v]
			face[#face+1] = vec3(vert.x, vert.y, vert.z)
		end
		mesh[#mesh+1] = face
	end
	
	return mesh	
end

local function vec3_str(_vec)
	return tostring(_vec.X) .. "," 
        .. tostring(_vec.Y) .. "," 
        .. tostring(_vec.Z)
end

function lib:export_mesh(_mesh)
	local file_str = "return {\n"

	for i = 1, #_mesh do
		local face_str = "  { "
		for f = 1, #_mesh[i] do
			-- string
			face_str = face_str .. "vec3(" .. vec3_str(_mesh[i][f]) .. ")"
			if f ~= #_mesh[i] then
				face_str = face_str .. ", "
			end
		end
		
		-- string
		face_str = face_str .. " }"
		if i ~= #_mesh then
			face_str = face_str .. ", "
		end
		face_str = face_str .. "\n"
		
		file_str = file_str .. face_str
	end
	
	file_str = file_str .. "}\n"
	
	--local success, message = love.filesystem.write( "D:/Dev/rg_libs/export/torus_obj.lua", file_str)
	--if success then 
	--	print ('file created')
	--else 
	--	print ('file not created: '..message)
	--end
	
	local file = io.open("torus_obj.lua", "w")
	if file then
		file:write(file_str)
		file:close()
	end
	
end

return lib