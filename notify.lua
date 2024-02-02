-- um_wtt/notify.lua
-- Handle notification
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

local wtt_notify = function() end
if minetest.get_modpath("mail") then
    wtt_notify = function(from, to, amount, desc)
        local msg = table.concat({
            S("Dear @1,", to),
            "",
            S("@1 has transferred $@2 into your bank account. The description given is:", from, amount),
            "",
            desc,
            "",
            S("Please check your account balance. If you find any Wire Transfer System bugs, please report them at @1.",
                "https://github.com/C-C-Minetest-Server/um_wtt/issues"),
            "",
            S("Yours truly,"),
            S("Wire Transfer System"),
            "",
            "",
            "*" .. S("This is an automatically sent message. Do not reply.") .. "*",
        }, "\n")

        local mail_packet = {
            from = "WTT System",
            to = to,
            subject = S("Received $@1 from @2", amount, from),
            body = msg
        }
        mail.send(mail_packet)
    end
end

return wtt_notify