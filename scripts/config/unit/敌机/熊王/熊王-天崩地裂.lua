local jass = require "jass.common"
local japi = require "jass.japi"

yo.ini.state["熊王-天崩地裂"] = function(_ai)
    local _state = yo.state.new(_ai)
    local _unit = _ai._owner

    local charge = yo.state.new_aciton()
    charge.anim = "charge"
    charge.time = 1.2
    function charge:on_action()
        local eff = [[Abilities\Spells\Other\Doom\DoomTarget.mdl]]
        eff = jass.AddSpecialEffect(eff, _unit:center():get())
        japi.EXSetEffectSize(eff, 3)
        jass.DestroyEffect(eff)
        -- 单位蓄力动作，所有玩家镜头震动
        _unit:set_animation(self.anim_charge)
        for i = 1, 13, 1 do
            yo.player.get(i):setCamera(yo.point.new(0, 0), 1)
        end

        _ai._timer:wait(self.time * 1000, function()
            -- 镜头停止震动
            for i = 1, 13, 1 do
                yo.player.get(i):setCamera(yo.point.new(0, 0), 1)
            end
            self:on_finish()
        end)
    end

    local jump = yo.state.new_aciton()
    jump.anim = "stand"
    jump.jump_high = 700
    jump.duration = 0.7
    function jump:on_action()
        _unit:set_animation(self.anim)
        -- 执行移动器
        local mover = yo.mover.new {
            unit = _unit,
            lifeTime = self.duration,
            high = function(_time)
                local tmp = -4 * self.jump_high / self.duration ^ 2
                tmp = tmp * (_time - self.duration / 2) ^ 2 + self.jump_high
                return tmp
            end,
            speed = function(_time) return 1000 end
        }

        function mover:on_destroy() jump:on_finish() end

        mover:launch()
    end

    local hit_fly = yo.state.new_aciton()
    hit_fly.anim = "stand"
    hit_fly.jump_high = 500
    hit_fly.duration = 0.5
    hit_fly.time_stun = 3
    local selector = yo.selector.new()
    function hit_fly:on_action()
        local center = _unit:center()

        local eff = [[Abilities\Spells\Orc\EarthQuake\EarthQuakeTarget.mdl]]
        eff = jass.AddSpecialEffect(eff, center:get())
        japi.EXSetEffectSize(eff, 2)

        local select = selector:in_range(center, 1000):is_not(_unit):get()

        for _, selUnit in ipairs(select) do
            -- print("造成伤害")
            selUnit:set_stun(true)
            selUnit:set_animation(self.anim)
            local model =
                [[Abilities\Spells\Human\Thunderclap\ThunderclapTarget.mdl]]
            local eff = jass.AddSpecialEffectTarget(model, selUnit._handle,
                                                    "overhead")
            _ai._timer:wait(self.time_stun * 1000, function()
                selUnit:set_stun(false)
                jass.DestroyEffect(eff)
            end)

            local mover = yo.mover.new {
                unit = selUnit,
                lifeTime = self.duration,
                high = function(_time)
                    local a = -4 * self.jump_high / self.duration ^ 2
                    local tmp = a * (_time - self.duration / 2) ^ 2
                    tmp = tmp + self.jump_high
                    return tmp
                end
            }
            function mover:on_destroy()
                -- print("造成伤害")
            end

            mover:launch()
        end

        local finish = math.max(self.time_stun, self.duration)
        _ai._timer:wait(finish * 1000,
                                function() self:on_finish(_unit) end)

    end

    function charge:on_finish() jump:on_action() end
    function jump:on_finish() hit_fly:on_action() end
    local loop = 0
    function hit_fly:on_finish()
        loop = loop + 1
        if loop > 1 then
            _state:exit()
            loop = 0
        else
            hit_fly:on_action()
        end
    end

    function _state:on_enter()
        charge:on_action()
    end



    return _state
end
