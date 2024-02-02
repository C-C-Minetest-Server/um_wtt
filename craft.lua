-- um_wtt/craft.lua
-- Handle crafting recipies
--[[
    MIT License

    Copyright (c) 2016-2018  Gabriel Pérez-Cerezo
    Copyright (c) 2018  Hans von Smacker
    Copyright (c) 2023-2024  1F616EMO

    Permission is hereby granted, free of charge, to any person obtaining a copy
    of this software and associated documentation files (the "Software"), to deal
    in the Software without restriction, including without limitation the rights
    to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
    copies of the Software, and to permit persons to whom the Software is
    furnished to do so, subject to the following conditions:

    The above copyright notice and this permission notice shall be included in all
    copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
    SOFTWARE.
]]

local steel = nil
local mese = nil
local glass = nil
local cheap = nil

if minetest.get_modpath("mcl_core") then
    steel = "mcl_core:iron_ingot"
    mese = "mcl_core:emerald"
    glass = "mcl_core:glass"
    cheap = "mcl_core:iron_ingot"
    if minetest.get_modpath("mcl_copper") then
        cheap = "mcl_copper:copper_ingot"
    end
elseif minetest.get_modpath("default") then
    steel = "default:steel_ingot"
    mese = "default:mese_crystal"
    glass = "default:glass"
    cheap = "default:copper_ingot"
else
    if minetest.get_modpath("zr_iron") then
        steel = "zr_iron:ingot"
    end
    if minetest.get_modpath("zr_mese") then
        mese = "zr_mese:crystal"
    end
    if minetest.get_modpath("zr_glass") then
        glass = "zr_glass:glass"
    end
    if minetest.get_modpath("zr_copper") then
        cheap = "zr_copper:ingot"
    end
end
if minetest.get_modpath("mesecons_wires") then
    cheap = "mesecons:wire_00000000_off"
end

if not(steel and mese and glass and cheap) then
    minetest.log("warning","[um_atm] No valid craft items found, giving up.")
    return
end

minetest.register_craft({
	output = "um_wtt:wtt",
	recipe = {
		{steel, mese, steel},
		{glass, cheap, steel},
		{steel, mese, steel}
	}
})
