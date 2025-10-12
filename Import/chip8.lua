local emu = {}

-- Helpers

local function clamp8(_value)  return bit32.band(_value, 0xFF) end
local function clamp16(_value) return bit32.band(_value, 0xFFFF) end

local function malloc(_size) return 0 end

local function get_ram(_byte) return emu.RAM[_byte+1] end
local function set_ram(_byte, _value) emu.RAM[_byte+1] = _value end

local function get_reg(_register) 
	return emu.registers[_register+1] 
end

local function set_reg(_register, _value) 
	emu.registers[_register+1] = _value 
end

local function add_reg(_register, _value)
	emu.registers[_register+1] = bit32.band((emu.registers[_register+1] + _value), 0xFF)
end

local function pull4(_bits) return bit32.extract(_bits, 0, 4) end
local function pull8(_bits) return bit32.extract(_bits, 0, 8) end
local function pull12(_bits) return bit32.extract(_bits, 0, 12) end

local function assemble8(_a, _b)
	return bit32.bor( 
		bit32.lshift(_a, 4),
		_b
	)
end

local function assemble16(_a, _b, _c)
	return bit32.bor(
		bit32.lshift(_a, 8),
		bit32.lshift(_b, 4),
		_c
	)
end

local function fetch(_byte0, _byte1)
	return {
		bit32.extract(_byte0, 4, 4), -- 0xX___
		bit32.extract(_byte0, 0, 4), -- 0x_X__
		bit32.extract(_byte1, 4, 4), -- 0x__X_
		bit32.extract(_byte1, 0, 4)  -- 0x___X
	}
end

local function create_buffer(_length, _varsize)
	local buf = {}
	for i = 1, _length do
		buf[#buf+1] = malloc(_varsize)
	end
	return buf
end

local function write_table_to_ram(_at, _table)
	for i = 1, #_table do
		emu.RAM[_at + i] = clamp8(_table[ i ])
	end
end

local DISPLAY_WIDTH  = 64
local DISPLAY_HEIGHT = 32

-- Specifications
emu.display = PixelData.new(DISPLAY_WIDTH, DISPLAY_HEIGHT, color.black)
emu.RAM = create_buffer(4096, 1)
emu.registers = { -- 16 8-bit registers
	malloc(1), 
	malloc(1), 
	malloc(1), 
	malloc(1), 
	malloc(1), 
	malloc(1), 
	malloc(1), 
	malloc(1), 
	malloc(1), 
	malloc(1), 
	malloc(1), 
	malloc(1), 
	malloc(1), 
	malloc(1), 
	malloc(1), 
	malloc(1)
}
emu.DT = malloc(1) -- 8 bit
emu.ST = malloc(1) -- 8 bit
emu.I  = malloc(2) -- 16 bit
emu.PC = malloc(2) -- program counter, 16-bit
emu.SP = malloc(1) -- stack pointer, 8-bit
emu.stack = {}

-- Instructions 

-- 00E0
function CLS()
	for y = 1, 32 do
		for x = 1, 64 do
			emu.display:SetPixel(x, y, color.black)
		end
	end
end

-- 00EE
function RET()
	emu.SP = emu.SP - 1
	emu.PC = emu.stack[emu.SP]
end

-- 1NNN
function JMP_NNN(_bits) 
	emu.PC = bit32.extract(_bits, 0, 12)
end

-- 6XNN
function LD_VX_NN(_bits, _vx)
	set_reg(_vx, pull8(_bits))
end

-- 7XNN
function ADD_VX_NN(_bits, _vx)
	add_reg(_vx, pull8(_bits))
end

-- ANNN
function LD_I_NNN(_bits)
	emu.I = bit32.extract(_bits, 0, 12)
end

-- 3XNN
function SE_VX_NN(_bits, _vx)
	if get_reg(_vx) == pull8(_bits) then
		emu.PC = emu.PC + 2
	end
end

-- 4XNN
function SNE_VX_NN(_bits, _vx)
	if get_reg(_vx) ~= pull8(_bits) then
		emu.PC = emu.PC + 2
	end
end

-- 5XY0
function SE_VX_VY(_bits, _vx, _vy)
	if get_reg(_vx) == get_reg(_vy) then
		emu.PC = emu.PC + 2
	end
end

-- DXYN
function DRW_VX_VY_N(_bits, _vx, _vy, _n)
	local xcoord = get_reg(_vx) % DISPLAY_WIDTH
	local ycoord = get_reg(_vy) % DISPLAY_HEIGHT
	set_reg(0xF, 0)

	for row = 0, _n-1 do
		local bits = get_ram(clamp16(emu.I + row))
		local cy = ycoord + row

		for col = 0, 7 do
			local cx = xcoord + col
			local bit = bit32.extract(bits, 7 - col)
			
			if bit > 0 then 
				local v = emu.display:GetPixel(cx+1, cy+1) == color.white 
				if v then 
					set_reg(0xF, 1) 
					emu.display:SetPixel(cx+1, cy+1, color.black)
				else
					emu.display:SetPixel(cx+1, cy+1, color.white)
				end
			end

			if cx == DISPLAY_WIDTH - 1 then 
				break 
			end
		end

		if cy == DISPLAY_HEIGHT - 1 then 
			break 
		end
	end
end

local opcodes = {
	[0x0] = {[0x0] = {[0xE] = {
		[0x0] = CLS, 
		[0xE] = RET
	}}},

	[0x1] = JMP_NNN,
	[0x3] = SE_VX_NN,
	[0x4] = SNE_VX_NN,
	[0x5] = SE_VX_VY,
	[0x6] = LD_VX_NN,
	[0x7] = ADD_VX_NN,
	[0xA] = LD_I_NNN,
	[0xD] = DRW_VX_VY_N	
}

local function run_op(_a, _b, _c, _d, _16bits)
	local a = opcodes[_a]
	if type(a) == "function" then a(_16bits, _b, _c, _d); return end
	
	local b = a[_b]
	if type(b) == "function" then b(_16bits, _c, _d); return end
	
	local c = b[_c]
	if type(c) == "function" then c(_16bits, _d); return end
	
	local d = c[_d]
	if type(d) == "function" then d(); return end
end

-- Initialization

-- Setup stack
for i = 1, 255 do 
	emu.stack[#emu.stack+1] = malloc(2)
end

-- Setup font data
write_table_to_ram(0x00, {
	0xF0, 0x90, 0x90, 0x90, 0xF0, -- 0
    0x20, 0x60, 0x20, 0x20, 0x70, -- 1
    0xF0, 0x10, 0xF0, 0x80, 0xF0, -- 2
    0xF0, 0x10, 0xF0, 0x10, 0xF0, -- 3
    0x90, 0x90, 0xF0, 0x10, 0x10, -- 4
    0xF0, 0x80, 0xF0, 0x10, 0xF0, -- 5
    0xF0, 0x80, 0xF0, 0x90, 0xF0, -- 6
    0xF0, 0x10, 0x20, 0x40, 0x40, -- 7
    0xF0, 0x90, 0xF0, 0x90, 0xF0, -- 8
    0xF0, 0x90, 0xF0, 0x10, 0xF0, -- 9
    0xF0, 0x90, 0xF0, 0x90, 0x90, -- A
    0xE0, 0x90, 0xE0, 0x90, 0xE0, -- B
    0xF0, 0x80, 0x80, 0x80, 0xF0, -- C
    0xE0, 0x90, 0x90, 0x90, 0xE0, -- D
    0xF0, 0x80, 0xF0, 0x80, 0xF0, -- E
    0xF0, 0x80, 0xF0, 0x80, 0x80  -- F
})

-- Load program
write_table_to_ram(0x200, { 
  0x00, 0xe0, 0xa2, 0x2a, 0x60, 0x0c, 0x61, 0x08, 
  0xd0, 0x1f, 0x70, 0x09, 0xa2, 0x39, 0xd0, 0x1f, 
  0xa2, 0x48, 0x70, 0x08, 0xd0, 0x1f, 0x70, 0x04, 
  0xa2, 0x57, 0xd0, 0x1f, 0x70, 0x08, 0xa2, 0x66, 
  0xd0, 0x1f, 0x70, 0x08, 0xa2, 0x75, 0xd0, 0x1f, 
  0x12, 0x28, 0xff, 0x00, 0xff, 0x00, 0x3c, 0x00, 
  0x3c, 0x00, 0x3c, 0x00, 0x3c, 0x00, 0xff, 0x00, 
  0xff, 0xff, 0x00, 0xff, 0x00, 0x38, 0x00, 0x3f, 
  0x00, 0x3f, 0x00, 0x38, 0x00, 0xff, 0x00, 0xff, 
  0x80, 0x00, 0xe0, 0x00, 0xe0, 0x00, 0x80, 0x00, 
  0x80, 0x00, 0xe0, 0x00, 0xe0, 0x00, 0x80, 0xf8, 
  0x00, 0xfc, 0x00, 0x3e, 0x00, 0x3f, 0x00, 0x3b, 
  0x00, 0x39, 0x00, 0xf8, 0x00, 0xf8, 0x03, 0x00, 
  0x07, 0x00, 0x0f, 0x00, 0xbf, 0x00, 0xfb, 0x00, 
  0xf3, 0x00, 0xe3, 0x00, 0x43, 0xe0, 0x00, 0xe0, 
  0x00, 0x80, 0x00, 0x80, 0x00, 0x80, 0x00, 0x80, 
  0x00, 0xe0, 0x00, 0xe0 
})

emu.PC = 0x200

function emu.tick()
	local byte0 = get_ram(emu.PC)
	emu.PC = emu.PC + 1
	local byte1 = get_ram(emu.PC)
	emu.PC = emu.PC + 1

	local v = fetch(byte0, byte1)
	run_op(
		v[1], v[2], v[3], v[4], 
		bit32.bor(
			bit32.lshift(byte0, 8), 
			byte1
		))
end

return emu