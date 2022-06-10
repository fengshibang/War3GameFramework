local jass = require "jass.common"
local japi = require "jass.japi"

yo.ini.state["熊王-给你一巴掌"] = function(_ai)
    local _state = yo.state.new(_ai)
    local _unit = _ai._owner
    local selector = yo.selector.new()

    local _action = yo.state.new_aciton()
    _action.anim = ""
    _action.delay_front = 1
    _action.delay_back = 1
    _action.range =1000
    _action.devia =200
    function _action:on_action()
        -- 播放动画
        _unit:set_animation("")
        _unit:set_animation_speed(1)

        _ai._timer:wait(self.delay_front * 1000, function()
            -- 造成伤害
            local damage = setmetatable({}, yo.struct.damage)
            damage.damageType = "物理"
            damage.critType = "计算暴击"
            damage.value = 1.2 * _unit:get("攻击力")
            damage.attacker = _unit

            local center = _unit:center() - {_unit:get_facing(), self.devia}

            local select = selector:in_range(center, self.range):is_not(_unit):get()
            if select then
                for _, enumUnit in ipairs(select) do
                    damage.defencer = enumUnit
                    yo.battle.doDamage(damage)
                end
            end

            _ai._timer:wait(self.delay_back * 1000,
                            function() self:on_finish() end)
        end)
    end

    function _action:on_finish() _state:exit() end

    function _state:on_enter() _action:on_action() end

    return _state

end
