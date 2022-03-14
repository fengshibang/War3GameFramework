local math = require "base.tools.math"
local selector = require "base.tools.selector"
local timer = require "base.system.timer"
local moverTimer = timer.realTimer

local mover = {}

local mt = {
    type = "mover",
    -- 移动单位
    unit = nil,
    -- 生命周期
    lifeTime = 0,
    -- 速度随时间变动的委托
    speed = function(_time) return 0 end,
    -- 移动主角度
    angle = 0,
    -- 在主角度基础上的偏移角度
    deviaAngle = function(_time) return 0 end,
    -- 目标单位(存活就更新主角度)
    follow = nil,
    -- 转向角度限制
    turnSpeed = 99999,
    -- 保持朝向与角度一致
    faceAngle = true,
    -- 高度委托,控制高度
    high = function(_time) return 0 end,
    -- 碰撞半径
    hitRange = 200,

    -- 暂停
    _isPause = false,
    -- 已用帧数
    _usedTime = 0,
    -- 选取器
    selector = selector.new()
}
mt.__index = mt

function mover.new(data)
    local move = setmetatable(data or {}, mt)
    move.selector = selector.new()
    return move
end

-----------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------

function mt:launch()
    -- 加入帧更新
    moverTimer:loop(game.FRAME * 1000, function(action)
        if self._isPause then return end

        -- 计算生命
        local deltaTime = game.FRAME * self.unit:get_timeScale()
        self._usedTime = self._usedTime + deltaTime
        if self.lifeTime + deltaTime < self._usedTime then
            self:on_destroy()
            if self.unit:is_bullet() then self.unit:remove() end
            action:remove()
            return
        end

        -- 控制高度
        self.unit:set_high(self.high(self._usedTime), false)

        -- 变更朝向(主朝向)
        if self.follow and self.follow:is_alive() then
            local turnSpeed = self.turnSpeed * deltaTime
            local targetAngle = self.unit:center() / self.follow:center()
            self.angle = math.angle_to(self.angle, targetAngle, turnSpeed)
        end
        -- 结合偏移朝向计算最终朝向
        local angle = self.angle + self.deviaAngle(self._usedTime)
        -- 根据设置同步单位朝向
        if self.faceAngle then self.unit:set_facing(angle, true) end

        -- 形成位移
        local x, y = self.unit:center():get()
        local rad = math.rad(angle)
        local speed = self.speed(self._usedTime) * deltaTime
        x = x + math.cos(rad) * speed
        y = y + math.sin(rad) * speed
        yo.point.gc_point.x = x
        yo.point.gc_point.y = y
        if not yo.point.gc_point:isin(yo.rect.map) then
            self._usedTime = self.lifeTime
        else
            self.unit:set_center(x, y)
            -- 检查碰撞
            local unit_center = self.unit:center()
            if unit_center:is_block() then self:on_hitwall() end
            local select = self.selector:in_range(unit_center, self.hitRange)
            local selectGroup = select:is_not(self.unit):get()

            if selectGroup then
                self.hitUnits = selectGroup
                self:on_hitunit()
            end
        end

    end)
end

function mt:pause() self._isPause = true end

function mt:resume() self._isPause = false end

-- 移除运动器
function mt:remove() self._usedTime = self.lifeTime end

-- #region 虚函数

function mt:on_create() end
function mt:on_hitwall() end
function mt:on_hitunit() end
function mt:on_destroy() end

-- #endregion

return mover
