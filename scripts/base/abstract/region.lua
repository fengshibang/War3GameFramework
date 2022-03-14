local jass = require 'jass.common'
local dbg = require 'jass.debug'
local point = require 'base.abstract.point'
local war3 = require 'base.tools.war3'
local event = require 'base.system.event'
local unit = require "base.types.unit"

local region = {}

local mt = {
    -- 类型
    type = "region",
    -- 句柄
    _handle = 0,
    -- 进入区域触发器
    enter_trigger = nil,
    -- 离开区域触发器
    leave_trigger = nil,
    -- 此区域的单位组
    unitgroup = nil
}
mt.__index = mt

-- 创建矩形区域
---region.new(多个区域:circle,rect,point)
function region.new(...)
    local rgn = setmetatable({}, mt)
    rgn._handle = jass.CreateRegion()
    dbg.handle_ref(rgn._handle)
    rgn.unitgroup = {}
    for _, rct in ipairs {...} do rgn = rgn + rct end
    return rgn
end

-----------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------

-- 注册区域常用事件
function mt:regist_event()
    -- 单位进入区域事件
    if not self.enter_trigger then
        self.enter_trigger = war3.CreateTrigger(function()
            -- 获取此handle的unit
            local unit = unit.j_unit(jass.GetTriggerUnit())
            -- 若unit存在，则触发'区域-进入'事件
            if unit then
                table.insert(self.unitgroup, unit)
                event:notify(event.E_Unit.regionEnter, unit, self)
            end
        end)
        jass.TriggerRegisterEnterRegion(self.enter_trigger, self._handle, nil)
    end
    -- 单位离开区域事件
    if not self.leave_trigger then
        self.leave_trigger = war3.CreateTrigger(function()
            -- 获取此handle的unit
            local unit = unit.j_unit(jass.GetTriggerUnit())
            -- 若unit存在，则触发'区域-离开'事件
            if unit then
                for _, _unit in ipairs(self.unitgroup) do
                    if _unit == unit then
                        table.remove(self.unitgroup, _)
                    end
                end
                event:notify(event.E_Unit.regionLeave, unit, self)
            end
        end)
        jass.TriggerRegisterLeaveRegion(self.leave_trigger, self._handle, nil)
    end
end

-- 移除不规则区域
function mt:remove()
    jass.RemoveRegion(self._handle)
    if self.enter_trigger then war3.DestroyTrigger(self.enter_trigger) end
    if self.leave_trigger then war3.DestroyTrigger(self.leave_trigger) end
    dbg.handle_unref(self._handle)
end

-- 在不规则区域中添加/移除区域
--	region = region + other
function mt:__add(other)
    if other.type == 'rect' then
        -- 添加矩形区域
        jass.RegionAddRect(self._handle, other:to_jrect())
    elseif other.type == 'point' then
        -- 添加单元点
        jass.RegionAddCell(self._handle, other:get())
    elseif other.type == 'circle' then
        -- 添加圆形
        local x, y, r = other:get()
        local p0 = other:center()
        for x = x - r, x + r + 32, 32 do
            for y = y - r, y + r + 32, 32 do
                local p = point(x, y)
                if p * p0 <= r + 16 then
                    jass.RegionAddCell(self._handle, x, y)
                end
            end
        end
    else
        jass.RegionAddCell(self._handle, other:center():get())
    end

    return self
end

--	region = region - other
function mt:__sub(other)
    if other.type == 'rect' then
        -- 添加矩形区域
        jass.RegionClearRect(self._handle, other:to_jrect())
    elseif other.type == 'point' then
        -- 移除单元点
        jass.RegionClearCell(self._handle, other:get())
    elseif other.type == 'circle' then
        -- 移除圆形
        local x, y, r = other:get()
        local p0 = other:center()
        for x = x - r, x + r + 32, 32 do
            for y = y - r, y + r + 32, 32 do
                local p = point(x, y)
                if p * p0 <= r + 16 then
                    jass.RegionClearCell(self._handle, x, y)
                end
            end
        end
    else
        jass.RegionClearCell(self._handle, other:center():get())
    end

    return self
end

return region
