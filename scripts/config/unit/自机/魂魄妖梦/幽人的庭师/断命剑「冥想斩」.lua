local jass = require "jass.common"

yo.ini.ability["断命剑「冥想斩」"] = function(str_id)

    local mt = yo.ability.new(str_id)
    -- 基础信息
    mt._name = "断命剑「冥想斩」"
    mt.level = 1
    mt._level = 10
    mt._cost_mana = 0
    mt._charge = 1
    mt._range = 5000
    mt._cool_frame = 0
    mt._tip =
        [[%delay%秒后飘向目标地点,单次最大飘动距离为%distance%,首次释放后1秒内可再次释放，最多释放3次。]]
    mt._target_type = yo.ability.TARGET_TYPE_POINT

    mt.queue = {}
    mt.duration = 1
    mt.delay = 0.5
    mt.distance = 1000

    function mt:on_fresh() end

    local source, target = yo.point.new(0, 0), yo.point.new(0, 0)

    function mt:on_cast()
        target.x, target.y = jass.GetSpellTargetX(), jass.GetSpellTargetY()

        if #self.queue == 0 then
            -- 第一次释放,将自身坐标设定为起点
            source:copy(self._owner:center())
        end

        local angle = yo.math.deg(source / target)
        local distance = yo.math.min(self.distance, source * target)
        local speed = distance / self.duration

        local mover = yo.mover.new {
            unit = self._owner,
            angle = angle,
            lifeTime = self.duration,
            speed = function(_time) return speed end
        }

        function mover:on_destroy()
            table.remove(mt.queue, 1)
            if #mt.queue > 0 then mt.queue[1]:launch() end
        end

        table.insert(mt.queue, mover)

        if #mt.queue == 1 then
            yo.timer.realTimer:wait(self.delay * 1000,
                                    function() mover:launch() end)
        end

        -- 计算结束，将下一个目标点作为起始点
        source:copy(target)
    end
    return mt
end
