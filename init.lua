-- um_wtt/init.lua
-- Wire Transfer Terminal for Unified Money
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

local S = minetest.get_translator("um_wtt")
local F = minetest.formspec_escape

local MP = minetest.get_modpath("um_wtt")
local wtt_notify = dofile(MP .. "/notify.lua")
dofile(MP .. "/craft.lua")

local sound = nil
if minetest.global_exists("zr_stone") then
    sound = zr_stone.sounds
elseif minetest.global_exists("default") then
    sound = default.node_sound_stone_defaults()
elseif minetest.global_exists("mcl_sounds") then
    sound = mcl_sounds.node_sound_stone_defaults()
end

local function get_form_prepare(balance)
    return table.concat({
        "size[8,6]",
        "label[2.5,0;" .. F(S("Wire Transfer Terminal")) .. "]",
        "label[2,0.5;" .. F(um_translate_common.balance_show(balance)) .. "]",
        "field[0.5,1.5;5,1;dstn;" .. F(S("Recepient")) .. ":;]",
        "field[6,1.5;2,1;amnt;" .. F(S("Amount")) .. ":;]",
        "field[0.5,3;7.5,1;desc;" .. F(S("Description")) .. ":;]",
        "button_exit[0.2,5;1.5,1;quit;" .. F(S("Quit")) .. "]",
        "button[3.7,5;4,1;pay;" .. F(S("Complete the Payment")) .. "]",
    }, "")
end

local function get_form_confirm(balance, dest, amount, desc)
    return table.concat({
        "size[8,6]",
        "label[2.5,0;" .. F(S("Wire Transfer Terminal")) .. "]",
        "label[2,0.5;" .. F(um_translate_common.balance_show(balance)) .. "]",
        "label[2.5,1;" .. F(S("TRANSACTION SUMMARY:")) .. "]",
        "label[0.5,1.5;" .. F(S("Recepient: @1", dest)) .. "]",
        "label[0.5,2;" .. F(S("Amount: @1", amount)) .. "]",
        "label[0.5,2.5;" .. F(S("Description: @1", desc)) .. "]",
        "button_exit[0.2,5;1.5,1;quit;" .. F(S("Quit")) .. "]",
        "button[4.7,5;3,1;cnfrm;" .. F(S("Comfirm Transaction")) .. "]",
        "field[100,100;0,0;dstn;;" .. F(dest) .. "]",
        "field[100,100;0,0;amnt;;" .. F(amount) .. "]",
        "field[100,100;0,0;desc;;" .. F(desc) .. "]",
    }, "")
end

local function get_form_done(balance, title, content)
    return table.concat({
        "size[8,6]",
        "label[2.5,0;" .. F(S("Wire Transfer Terminal")) .. "]",
        "label[2,0.5;" .. F(um_translate_common.balance_show(balance)) .. "]",
        "label[2.5,1;" .. F(title) .. "]",
        "label[0.5,1.5;" .. F(content) .. "]",
        "button_exit[0.2,5;1,1;quit;" .. F(S("Quit")) .. "]",
        "button[6.2,5;1.5,1;back;" .. F(S("Back")) .. "]",
    }, "")
end

minetest.register_node("um_wtt:wtt", {
    description = S("Wire Transfer Terminal"),
    tiles = {
        "wtt_top.png", "wtt_top.png",
        "wtt_side_wt.png", "wtt_side_wt.png",
        "wtt_side_wt.png", "wtt_front_wt.png"
    },
    paramtype2 = "facedir",
    groups = {
        cracky = 2,
        pickaxey = 1,
        bank_equipment = 1
    },
    legacy_facedir_simple = true,
    is_ground_content = false,
    sounds = sound,

    on_rightclick = function(pos, node, player, itemstack, pointed_thing)
        if not player:is_player() then return end
        local name = player:get_player_name()
        local balance = unified_money.get_balance_safe(name)

        minetest.show_formspec(name, "um_wtt:node_form_prepare", get_form_prepare(balance))
    end,
})

minetest.register_on_player_receive_fields(function(player, formname, fields)
    local name = player:get_player_name()
    local balance = unified_money.get_balance_safe(name)

    if (formname == "um_wtt:node_form_prepare" and fields.pay)
    or (formname == "um_wtt:node_form_confirm" and fields.cnfrm) then
        local dest = fields.dstn
        local amount = tonumber(fields.amnt)
        local desc = fields.desc or ""

        if desc == "" then
            desc = S("No descriptions given.")
        end

        if not (dest and dest ~= "" and amount) then
            minetest.show_formspec(name, "um_wtt:node_form_done",
                get_form_done(balance, S("Transaction failed"), S("Destination or amount invalid.")))
            return
        end

        if dest == name then
            minetest.show_formspec(name, "um_wtt:node_form_done",
                get_form_done(balance, S("Transaction failed"), S("Destination cannot be yourself.")))
            return
        end

        if amount > balance then
            minetest.show_formspec(name, "um_wtt:node_form_done",
                get_form_done(balance, S("Transaction failed"), S("Insufficant balance.")))
            return
        end

        if balance < 1 then
            minetest.show_formspec(name, "um_wtt:node_form_done",
                get_form_done(balance, S("Transaction failed"), S("Invalid amount.")))
            return
        end

        if not unified_money.account_exists(dest) then
            minetest.show_formspec(name, "um_wtt:node_form_done",
                get_form_done(balance, S("Transaction failed"), S("Destinatinon @1 does not exist.", dest)))
            return
        end

        if formname == "um_wtt:node_form_prepare" then
            minetest.show_formspec(name, "um_wtt:node_form_confirm",
                get_form_confirm(balance, dest, amount, desc))
        else
            local status, msg = unified_money.transaction(name, dest, amount)
            balance = unified_money.get_balance_safe(name)
            if not status then
                minetest.show_formspec(name, "um_wtt:node_form_done",
                    get_form_done(balance, S("Transaction failed"), msg))
            else
                minetest.show_formspec(name, "um_wtt:node_form_done",
                    get_form_done(balance, S("Transaction done"), S("Thank you for choosing the Wire Transfer system")))
                wtt_notify(name, dest, amount, desc)
            end
        end
    elseif formname == "um_wtt:node_form_done" and fields.back then
        minetest.show_formspec(name, "um_wtt:node_form_prepare", get_form_prepare(balance))
    end
end)

