local unit = require "base.types.unit"
local dbg = require 'jass.debug'
local timer = require "base.system.timer"

local buffstate = {"wait", "active", "finish"}
local bufftag = {"positive", "negative"}

local buff = {}

local mt = {
    type = "buff",
    -- 心跳间隔
    beatinteval = 0,
    -- 心跳次数
    beatcount = 0,
    -- 死亡不消失
    deadkeep = false,

    -- buff名称
    _name = "",
    -- 生成buff的技能
    _from = nil,
    -- 附加的单位
    _attach = nil,
    -- buff当前层数
    _layer = 0,
    -- buff当前等级
    _level = 0,
    -- 暂停
    _ispause = false,
    -- 移除
    _isremoved = false
}
mt.__index = mt

function buff.new(name) return setmetatable({_name = name}, mt) end

-----------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------

function mt:pause() self._ispause = true end

function mt:resume() self._ispause = false end

function mt:start()
    self:on_add()
    local beatcount = self.beatcount or 0
    local beatinteval = self.beatinteval or 0
    if (beatcount > 0) and (beatinteval > 0) then
        local count = 0
        timer.realTimer:loop(1000 * beatinteval, function(action_obj)
            if self._isremoved then
                action_obj:remove()
                self:on_remove()
                self:on_destroy()
            end
            if not self._ispause then
                self:on_heartbeat()
                count = count + 1
                if count >= beatcount then
                    self:on_finish()
                    self._isremoved = true
                end
            end
        end)
    end
end

-----------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------

function mt:on_add() end

function mt:on_heartbeat() end

function mt:on_fresh() end

function mt:on_finish() end

function mt:on_remove() end

function mt:on_destroy() end

return buff
