local jass = require 'jass.common'
local war3 = require "base.tools.war3"
local point = require "base.abstract.point"

local unit = require "base.types.unit"

local selector = {}

selector.dummy = jass.CreateGroup()
selector.MAX_COLLISION = 200

local mt = {
    type = "selector",
    filterMode = 0,
    center = nil,
    radius = 9999,
    filterAction = nil,
    selectUnit = nil
}
mt.__index = mt

function selector.new()
    return setmetatable({filterAction = {}, selectUnit = {}}, mt)
end

-- #region 局部函数

-- 执行筛选,对选取到的单位进行过滤
local function do_filter(_mt, _unit)
    local actions = _mt.filterAction
    for i = 1, #actions do
        local filter = actions[i]
        if not filter(_unit) then return false end
    end
    return true
end

-- 单位是否位于圆形范围内
local function unit_is_in_range(_unit, center, radius)
    return _unit:center() * center - _unit:get_selected_radius() <= radius
end

-- 单位是否位于矩形范围内
local function unit_is_in_rect(_unit, rect_start, vectorFace, rect_width)

    -- 从起点指向被选中单位的向量
    local enumX, enumY = _unit:get()
    local vectorToEnum = point.new(enumX - rect_start.x, enumY - rect_start.y)

    -- 两向量的夹角
    local degAngle = math.rad(point.Angle(vectorToEnum, vectorFace))
    -- 矩形起点到选中单位的距离
    local enumLength = vectorToEnum:magtitude()

    local length = math.cos(degAngle) * enumLength - _unit:get_selected_radius()
    local width = math.sin(degAngle) * enumLength - _unit:get_selected_radius()

    return (length < vectorFace:magtitude()) and (width < rect_width / 2)

end

-- 添加单位进war3单位组
local function select(_mt)
    if _mt.filterMode == 0 then
        --	圆形选取
        local x, y = _mt.center:get()
        local r = _mt.radius

        jass.GroupEnumUnitsInRange(selector.dummy, x, y,
                                   r + selector.MAX_COLLISION, nil)

        jass.ForGroup(selector.dummy, function()
            local enumUnit = unit.j_unit(jass.GetEnumUnit())
            if enumUnit then
                if unit_is_in_range(enumUnit, _mt.center, r) and
                    do_filter(_mt, enumUnit) then
                    table.insert(_mt.selectUnit, enumUnit)
                end
            end
        end)

        jass.GroupClear(selector.dummy)

    elseif _mt.filterMode == 1 then
        --	扇形选取
        local x, y = _mt.center:get()
        local r = _mt.radius
        local angle = _mt.angle
        local section = _mt.section / 2

        jass.GroupEnumUnitsInRange(selector.dummy, x, y,
                                   r + selector.MAX_COLLISION, nil)

        jass.ForGroup(selector.dummy, function()
            local enumUnit = unit.j_unit(jass.GetEnumUnit())
            if enumUnit and unit_is_in_range(enumUnit, _mt.center, r) then
                if war3.math_angle(angle, _mt.center / enumUnit:center()) <=
                    section and do_filter(_mt, enumUnit) then
                    table.insert(_mt.selectUnit, enumUnit)
                end
            end
        end)

        jass.GroupClear(selector.dummy)

    elseif _mt.filterMode == 2 then
        --	矩形选取
        local start = _mt.center
        local target = start - {_mt.angle, _mt.len}

        local radius = _mt.len / 2

        -- 矩形中心
        local rect_center = point.new((start.x + target.x) / 2,
                                      (start.y + target.y) / 2)

        -- 从起点指向终点的向量
        local vectorFace = point.new(target.x - start.x, target.y - start.y)

        jass.GroupEnumUnitsInRange(selector.dummy, rect_center.x, rect_center.y,
                                   radius + selector.MAX_COLLISION, nil)

        jass.ForGroup(selector.dummy, function()
            local enumUnit = unit.j_unit(jass.GetEnumUnit())
            if enumUnit and unit_is_in_range(enumUnit, rect_center, radius) then
                -- 排除在矩形之外的向量
                if unit_is_in_rect(enumUnit, start, vectorFace, _mt.width) and
                    do_filter(_mt, enumUnit) then
                    table.insert(_mt.selectUnit, enumUnit)
                end
            end
        end)

        jass.GroupClear(selector.dummy)

    end
end

-- #endregion

-- #region 外部执行函数

-- 获取符合条件的Lua单位组，若不存在符合条件的单位则返回nil
-- 调用后自动清空单位组，因此一次选择只能调用一次
function mt:get()
    select(self)
    local len = #self.selectUnit
    if len > 0 then
        if self.sorter then table.sort(self.selectUnit, self.sorter) end
        local ret = {}
        for i = len, 1, -1 do
            table.insert(ret, table.remove(self.selectUnit, i))
        end
        return ret
    else
        return nil
    end
end

-- 加入筛选条件
function mt:add_filter(action)
    table.insert(self.filterAction, action)
    return self
end

-- 选取并选出随机单位
function mt:random()
    local g = self:get()
    if #g > 0 then return g[math.random(1, #g)] end
end

-- 圆形范围
--	圆心
--	半径
function mt:in_range(p, r)
    self.filterMode = 0
    self.center = p
    self.radius = r
    return self
end

-- 扇形范围
--	圆心
--	半径
--	角度
--	区间
function mt:in_sector(p, r, angle, section)
    self.filterMode = 1
    self.center = p
    self.radius = r
    self.angle = angle
    self.section = section
    return self
end

-- 直线范围
--	起点
--	角度
--	长度
--	宽度
function mt:in_line(p, angle, len, width)
    self.filterMode = 2
    self.center = p
    self.angle = angle
    self.len = len
    self.width = width
    return self
end

-- 对选取到的单位进行排序
function mt:set_sorter(action)
    self.sorter = action
    return self
end

-- 排序权重：1、英雄 2、和point的距离
function mt:sort_nearest_type_hero(point)
    return self:set_sorter(function(u1, u2)
        if u1:is_type('英雄') and not u2:is_type('英雄') then
            return true
        end
        if not u1:is_type('英雄') and u2:is_type('英雄') then
            return false
        end
        return u1:get_position() * point < u2:get_position() * point
    end)
end

-- #endregion

-- #region 条件筛选

-- 不是指定单位
--	单位
function mt:is_not(u)
    return self.add_filter(self, function(dest) return dest ~= u end)
end

-- 是敌人
--	参考单位/玩家
function mt:is_enemy(u)
    return self.add_filter(self, function(dest)
        return dest:get_owner():is_enemy(u:get_owner())
    end)
end

-- 是友军
--	参考单位/玩家
function mt:is_ally(u)
    return self.add_filter(self, function(dest) return dest:is_ally(u) end)
end

-- 必须是英雄
function mt:is_hero()
    return self.add_filter(self,
                           function(dest) return dest:is_type('英雄') end)
end

-- 必须不是英雄
function mt:is_not_hero()
    return self.add_filter(self,
                           function(dest) return not dest:is_type('英雄') end)
end

-- 必须是建筑
function mt:is_building()
    return self.add_filter(self,
                           function(dest) return dest:is_type('建筑') end)
end

-- 必须不是建筑
function mt:is_not_building()
    return self.add_filter(self,
                           function(dest) return not dest:is_type('建筑') end)
end

-- 必须是可见的
function mt:is_visible(u)
    return self.add_filter(self, function(dest) return dest:is_visible(u) end)
end

-- 必须是幻象的
function mt:is_illusion()
    return self.add_filter(self, function(dest) return dest:is_illusion() end)
end

-- 必须是不是幻象的
function mt:is_not_illusion()
    return self.add_filter(self,
                           function(dest) return not dest:is_illusion() end)
end

-- 必须是可伤害的
function mt:is_damageable()
    return self.add_filter(self, function(dest) return dest:is_damageable() end)
end

-- 必须不是可伤害的
function mt:is_not_damageable()
    return self.add_filter(self,
                           function(dest) return not dest:is_damageable() end)
end

-- 必须是存活的
function mt:is_alive()
    return self.add_filter(self, function(dest) return not dest:is_alive() end)
end

-- 必须是死亡的
function mt:is_dead()
    return self.add_filter(self, function(dest) return not dest:is_alive() end)
end

-- #endregion

return selector
