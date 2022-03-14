local point = require "base.abstract.point"

local circle = {}

local mt = {type = "circle", _point = point.new(0, 0), radius = 0}
mt.__index = mt

function circle.new(_point, radius)
    return setmetatable({_point = _point, radius = radius}, mt)
end

-----------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------

function mt:__tostring()
    return ('Circle:{center:(%.4f, %.4f), radius:%.4f}'):format(self._point.x,
                                                                self._point.y,
                                                                self.radius)
end

-- 获取3个值
function mt:get() return self._point.x, self._point.y, self.radius end

function mt:center() return self._point end

return circle
