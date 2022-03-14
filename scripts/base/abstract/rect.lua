local point = require "base.abstract.point"
local jass = require 'jass.common'

-- 仅仅是正矩形，不能表示会倾斜的矩形
local rect = {}

local mt = {
    type = "rect",
    name = "nil",
    minx = 0,
    miny = 0,
    maxx = 0,
    maxy = 0,
    _center = point.new(0, 0)
}
mt.__index = mt

function rect.new(minx, miny, maxx, maxy, name)
    return setmetatable({
        minx = minx,
        miny = miny,
        maxx = maxx,
        maxy = maxy,
        name = name or "nil"
    }, mt)
end

function rect.j_rect(name)
    if not rect.j_rects[name] then
        local jRect = jass['gg_rct_' .. name]
        rect.j_rects[name] = rect.new(jass.GetRectMinX(jRect),
                                      jass.GetRectMinY(jRect),
                                      jass.GetRectMaxX(jRect),
                                      jass.GetRectMaxY(jRect))
    end
    return rect.j_rects[name]

end


-- 将当前区域转换为jass区域.
-- 返回值将会在下次调用to_jrect时发生变化,需马上使用.
function rect.to_jrect(_rect)
    jass.SetRect(rect.dummy, _rect:get())
    return rect.dummy
end

-- 初始化
function rect.init()
    local minx = jass.GetCameraBoundMinX() -
                     jass.GetCameraMargin(jass.CAMERA_MARGIN_LEFT) + 32
    local miny = jass.GetCameraBoundMinY() -
                     jass.GetCameraMargin(jass.CAMERA_MARGIN_BOTTOM) + 32
    local maxx = jass.GetCameraBoundMaxX() +
                     jass.GetCameraMargin(jass.CAMERA_MARGIN_RIGHT) - 32
    local maxy = jass.GetCameraBoundMaxY() +
                     jass.GetCameraMargin(jass.CAMERA_MARGIN_TOP) - 32

    rect.map = rect.new(minx, miny, maxx, maxy)
    rect.dummy = jass.Rect(0, 0, 0, 0)
    -- 保存转换为rect后的预设矩形区域
    rect.j_rects = {}
end

-----------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------

function mt:__tostring()
    return ('Rect:{%.4f, %.4f, %.4f, %.4f}'):format(self:get())
end

-- 获取4个值
function mt:get() return self.minx, self.miny, self.maxx, self.maxy end

-- 获取中心点
function mt:center()
    if not self._center then
        local p = point.new((self.minx + self.maxx) / 2,
                            (self.miny + self.maxy) / 2)
        self._center = p
    end
    return self._center
end


-- 扩展矩形区域
-- @新矩形
function mt:__add(data)
    if data.type == 'rect' then
        local minx0, miny0, maxx0, maxy0 = self:get()
        local minx1, miny1, maxx1, maxy1 = data:get()

        local minx = math.min(minx0, minx1)
        local miny = math.min(miny0, miny1)
        local maxx = math.max(maxx0, maxx1)
        local maxy = math.max(maxy0, maxy1)
        return rect.new(minx, miny, maxx, maxy, self.name)
    else
        error('错误的类型' .. tostring(data.type))
    end
end

return rect
