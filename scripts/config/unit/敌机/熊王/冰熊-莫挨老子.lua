local jass = require "jass.common"
local japi = require "jass.japi"

yo.ini.state["冰熊-莫挨老子"] = function(_ai)
    local _unit = _ai._owner

    local event_action = function(data)
        if data.defencer == _unit then
            -- 创建特效
            print("创建特效")

            -- 造成伤害
            local damage = setmetatable({}, yo.struct.damage)
            damage.damageType = "物理"
            damage.critType = "必定不暴击"
            damage.attacker = _unit
            damage.defencer = data.attacker
            damage.value = 1.2 * _unit:get("攻击力")
            damage.value = 100
            yo.battle.doDamage(damage)

        end
    end
    yo.event:add(yo.event.E_Damage.damageFinish, event_action)
end
