local lib = {}

local obj_loader = require "obj_loader"

function lib:parse_obj(_path)
	local asset = obj_loader.load(_path)
	local mesh = {}
	
	for i = 1, #asset.f do
		local face = {verts={},normals={}}

		for f = 1, #asset.f[i] do		
			local v_index  = asset.f[i][f].v
			local vn_index = asset.f[i][f].vn
			
			local vert   = asset.v[v_index]
			local normal = asset.vn[vn_index]

			table.insert(face.verts, vec3(vert.x, vert.y, vert.z))

			if normal then
				table.insert(face.normals, vec3(normal.x, normal.y, normal.z))
			else
				table.insert(face.normals, vec3(1,0,0))
			end

		end

		table.insert(mesh, face)

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
		local face_str = "  { verts={"
		for f = 1, #_mesh[i].verts do
			-- string
			face_str = face_str .. "vec3(" .. vec3_str(_mesh[i].verts[f]) .. ")"
			if f ~= #_mesh[i].verts then
				face_str = face_str .. ", "
			end
		end

		face_str = face_str .. "}, normals={"
		for f = 1, #_mesh[i].normals do
			-- string
			face_str = face_str .. "vec3(" .. vec3_str(_mesh[i].normals[f]) .. ")"
			if f ~= #_mesh[i].normals then
				face_str = face_str .. ", "
			end
		end
		
		-- string
		face_str = face_str .. " }}"
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