local message = require "jass.message"
local event = require "base.system.event"
local track = require "base.tools.track"
local timer = require "base.system.timer"
local inputTimer = timer.realTimer

local input = {}
input.HOLD_FRAME = 200

-- 注册本地键盘事件
local function regist_local_keyevent()

    local key_record = {}
    local key_cast = {}

    -- 本地键盘事件（全都是本地事件）
    function message.hook(msg)
        -- 改键软件依然生效
        if not ((msg.type == 'key_down') or (msg.type == 'key_up')) then
            -- //TODO：解决这个
            -- print('other operation')
            return true
        end
        -- print(msg.code) --debug用

        -- 将按键转化为文本
        local _keychar = input.key_to_char[msg.code]
        if _keychar then
            if (msg.type == 'key_down') then
                -- print('本地玩家按下按键' .. _keychar)
                key_record[_keychar] = inputTimer:clock()
                event:notify(event.E_Player.key_down, _keychar)
            end
            if (msg.type == 'key_up') then
                -- print('本地玩家抬起按键' .. _keychar)
                local keydown_clock = key_record[_keychar] or inputTimer:clock()
                if inputTimer:clock() - keydown_clock <= input.HOLD_FRAME then
                    event:notify(event.E_Player.key_click, _keychar)
                else
                    event:notify(event.E_Player.key_unhold, _keychar)
                end
                key_record[_keychar] = nil
                key_cast[_keychar] = nil
                event:notify(event.E_Player.key_up, _keychar)
            end
        end

        return true
    end

    -- 本地拓展键盘事件
    inputTimer:loop(1, function()
        for key, value in pairs(key_record) do
            if not key_cast[key] then
                local keydown_clock = key_record[key] or inputTimer:clock()
                if inputTimer:clock() - keydown_clock > input.HOLD_FRAME then
                    -- //TODO：解决这个
                    -- print('本地玩家长按按键' .. key)
                    event:notify(event.E_Player.key_hold, key)
                    key_cast[key] = true
                end
            end
        end
    end)

end

-- 异步作弊指令
local function asyncInputKeyCode()
    local keycode_record = {}
    event:add(event.E_Player.key_down, function(_keychar)
        local _keycode = message.keyboard[_keychar]
        if #keycode_record >= 4 or _keychar == 'BACKSPACE' then
            -- 清空按键存储
            for i = #keycode_record, 1, -1 do
                table.remove(keycode_record, i)
            end
        end
        -- 如果是可显示字符（可显示字符长度都为1）就把按键码加入到表中
        -- 因为可显示的字符的按键码都是2位数，可以过去后再分割
        if string.len(_keychar) == 1 then
            table.insert(keycode_record, _keycode)
        end

        -- 分割与组装演示
        local char = {}
        for key, value in pairs(keycode_record) do
            char[key] = input.key_to_char[value]
        end
        -- //TODO：解决这个
        -- print(table.concat(char))
        -- print(tonumber(table.concat(keycode_record)))

    end)
end

function input.new_track(keychar_queue)
    local com = track.new_char(keychar_queue)
    event:add(event.E_Ability.AbilitySpell,
              function(_ability) com:add(_ability._hotkey) end)
end

function input.init()
    -- keycode与文本的对应表 
    input.key_to_char = {}
    for key, value in pairs(message.keyboard) do
        input.key_to_char[value] = key
    end

    -- 注册本地键盘事件
    regist_local_keyevent()

    -- 异步作弊指令
    asyncInputKeyCode()

end

return input
