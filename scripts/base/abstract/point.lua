local jass
jass = require 'jass.common'
local point = {}

function point.init()
    point.dummy = jass.Location(0, 0)
    -- 用于判定条件，减少gc操作
    point.gc_point = point.new(0, 0)
end

local mt = {type = "point", x = 0, y = 0, z = 0}
mt.__index = mt
point._mt = mt

function point.new(x, y, z) return setmetatable({x = x, y = y, z = z}, mt) end

-- 作为向量计算:夹角
function point.Angle(p1, p2)
    if (p1.type == "point") and (p2.type == "point") then
        local cos = point.Dot(p1, p2) / (p1:magtitude() * p2:magtitude())
        return math.deg(math.acos(cos))
    end
end
-- 作为向量计算：点乘
function point.Dot(p1, p2)
    if (p1.type == "point") and (p2.type == "point") then
        local x1, y1, z1 = p1:get()
        local x2, y2, z2 = p2:get()
        return x1 * x2 + y1 * y2 + z1 * z2
    end
end
-- 作为向量计算：叉乘
function point.Cross(p1, p2)
    if (p1.type == "point") and (p2.type == "point") then
        local x1, y1, z1 = p1:get()
        local x2, y2, z2 = p2:get()
        return
            point.new(y2 * z1 - z2 * y1, z2 * x1 - x2 * z1, x2 * y1 - y2 * x1)
    end
end
-- 作为点计算：距离
function point.Distance(p1, p2)
    if (p1.type == "point") and (p2.type == "point") then
        point.gc_point.x = p1.x - p2.x
        point.gc_point.y = p1.y - p2.y
        point.gc_point.z = p1.z - p2.z
        return point.gc_point:magtitude()
    end
end

-----------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------

function mt:__tostring()
    return ('Point:{%.4f, %.4f, %.4f}'):format(self.x, self.y, self.z)
end

-- 作为向量计算:长度
function mt:magtitude() return math.sqrt(self.x ^ 2 + self.y ^ 2 + self.z ^ 2) end

-- 作为向量计算:归一化
function mt:nomorlized()
    local magtitude = self:magtitude()
    return point.new(self.x / magtitude, self.y / magtitude, self.z / magtitude)
end

-- 获取点的三维坐标
-- flag:布尔值,是否获取z轴坐标
function mt:get(flag) return self.x, self.y, flag and self:getZ() or self.z end

-- 计算地面的z轴坐标
function mt:getZ()
    -- 移动jass点到点自身的x,y ,再计算jass点的所处高度
    jass.MoveLocation(point.dummy, self.x, self.y)
    return jass.GetLocationZ(point.dummy)
end

-- 复制目标点的三维坐标
function mt:copy(dest) self.x, self.y, self.z = dest.x, dest.y, dest.z end

-- 获得地层高度
-- 深水区0，浅水区1，平原2，之后每层+1
function mt:get_level() return jass.GetTerrainCliffLevel(self:get()) end

-- 检查点是否在范围内
function mt:isin(area)
    if (area.type == "circle") then
        return area:center() * self < area.radius
    elseif (area.type == "rect") then
        local x, y = self:get()
        local minx, miny, maxx, maxy = area:get()
        if (x > maxx) or (x < minx) or (y > maxy) or (y < miny) then
            return false
        else
            return true
        end
    elseif (area.type == "region") then
        return jass.IsPointInRegion(area._handle, self.x, self.y)
    end
end

-- 点是否对玩家可见
function mt:is_visible_to(player)
    if player.type == "player" then
        return jass.IsVisibleToPlayer(self.x, self.y, player._handle)
    else
        error('错误的类型' .. tostring(player.type))
    end
end

-- 是否无法通行
-- 是否无视地面阻挡(飞行)
-- 是否无视地图边界
function mt:is_block(path, super)
    local x, y = self:get()
    if not path then if jass.IsTerrainPathable(x, y, 1) then return true end end
    if not super then if jass.IsTerrainPathable(x, y, 2) then return true end end
    return false
end

-- 在附近寻找一个可通行的点
--	[采样范围]
--	[初始角度]
--	[不包含当前位置]
function mt:findMoveablePoint(r, angle, other)
    local r = r or 512
    local angle = angle or 0
    if not other and not self:is_block() then return self end

    for r = math.min(r, 32), r, 32 do
        for angle = angle, angle + 315, 45 do
            local p = self - {angle, r}
            if not p:is_block() then return p end
        end
    end
end

-- 求是否穿过不可通行区域
-- 判定结果,最后一个可通行点
function mt:crossUnwalk(data)
    if data.type == 'point' then
        local angle = math.deg(self / data)
        local distance = self * data
        local re = point.new(self:get())
        local next
        while distance >= 0 do
            next = re - {angle, 32}
            if next:is_block() then return true, re end
            distance = distance - 32
            re = next
        end
        return false, re
    else
        error('错误的类型' .. tostring(data.type))
    end
end

-- 按照直角坐标系移动(point + {x, y})
--	@新点
function mt:__add(data)
    if data.type == "point" then
        return point.new(self.x + data.x, self.y + data.y,
                         self.z + (data.z or 0))
    else
        error('错误的类型' .. tostring(data.type))
    end
end

-- 按照极坐标系移动(point - {angle, distance})
--	@新点
function mt:__sub(data)
    local x, y = self:get()
    local angle, distance = data[1], data[2]
    return point.new(x + distance * math.cos(angle),
                     y + distance * math.sin(angle))
end

-- 求距离(point * point)
function mt:__mul(data)
    if data.type == 'point' then
        local x1, y1 = self:get()
        local x2, y2 = data:get()
        local x0, y0 = x1 - x2, y1 - y2
        return math.sqrt(x0 * x0 + y0 * y0)
    else
        error('错误的类型' .. tostring(data.type))
    end
end

-- 求方向(point / point)
-- 返回值为弧度制，方向为self指向data
function mt:__div(data)
    if data.type == 'point' then
        local x1, y1 = self:get()
        local x2, y2 = data:get()
        return math.atan(y2 - y1, x2 - x1)
    else
        error('错误的类型' .. tostring(data.type))
    end
end

-- 求相等(point == point)
function mt:__eq(data)
    if data.type == 'point' then
        return (self.x == data.x) & (self.y == data.y) & (self.z == data.z)
    else
        error('错误的类型' .. tostring(data.type))
    end
end

return point
