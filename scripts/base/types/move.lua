local jass = require 'jass.common'
local timer = require "base.system.timer"

local move = {}

function move.update_speed(u, move_speed)
    if move_speed > 522 and not move.last[u] then
        move.add(u)
    elseif move_speed <= 520 and move.last[u] then
        move.remove(u)
    end
    -- u:set('移动速度', move_speed)
end

function move.add(u)
    move.last[u] = u:center()
    table.insert(move.group, u)
end

function move.remove(u)
    move.last[u] = nil
    for i, uu in ipairs(move.group) do
        if u == uu then
            table.remove(move.group, i)
            break
        end
    end
end

function move.init()
    move.last = setmetatable({}, {__mode = 'k'})
    move.group = {}
    timer.realTimer:loop(game.FRAME * 1000, move.update)
end

local frame = game.FRAME
function move.update()
    for _, u in ipairs(move.group) do
        local last = move.last[u]
        local now = u:center()
        local speed = now * last / frame
        if speed > 520 and speed < 525 then
            local target = last - {last / now, u:get('移动速度') * frame}
            u:set_center(target.x, target.y, true)
            move.last[u] = target
        else
            move.last[u] = now
        end
    end
end

return move
