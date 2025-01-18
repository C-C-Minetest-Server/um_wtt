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

local S = core.get_translator("um_wtt")

local wtt_notify = function() end
if core.get_modpath("echo") then
    echo.register_event_type("um_wtt:wtt_sent", {
        title = S("WTT Sent"),
        handle_event = function(event)
            return {
                title = S("Transferred $@1 to @2", event.wtt_amount, event.wtt_to),
                description = S("Description: @1", event.wtt_desc),
                image = "wtt_front_wt.png",
            }
        end,
    })

    echo.register_event_type("um_wtt:wtt_recv", {
        title = S("WTT Received"),
        handle_event = function(event)
            return {
                title = S("Received $@1 from @2", event.wtt_amount, event.wtt_from),
                description = S("Description: @1", event.wtt_desc),
                image = "wtt_front_wt.png",
            }
        end,
    })

    wtt_notify = function(from, to, amount, desc)
        echo.send_event_to(from, {
            type = "um_wtt:wtt_sent",
            wtt_from = from,
            wtt_to = to,
            wtt_amount = amount,
            wtt_desc = desc,
        })
        echo.send_event_to(to, {
            type = "um_wtt:wtt_recv",
            wtt_from = from,
            wtt_to = to,
            wtt_amount = amount,
            wtt_desc = desc,
        })
    end
elseif core.get_modpath("mail") then
    local function wtt_notify_to_recv(from, to, amount, desc)
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

    local function wtt_notify_to_send(from, to, amount, desc)
        local msg = table.concat({
            S("Dear @1,", from),
            "",
            S("You have transferred $@1 into @2's bank account. The description given is:", amount, to),
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
            to = from,
            subject = S("Transferred $@1 to @2", amount, to),
            body = msg
        }
        mail.send(mail_packet)
    end

    wtt_notify = function(from, to, amount, desc)
        wtt_notify_to_recv(from, to, amount, desc)
        wtt_notify_to_send(from, to, amount, desc)
    end
end

return wtt_notify