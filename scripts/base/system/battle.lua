local jass = require "jass.common"
local event = require 'base.system.event'
local war3 = require "base.tools.war3"

local battle = {}

-- 战斗系统

local function isCrit(data)
    local crit = false

    if data.critType == "计算暴击" then
        local rate = data.attacker:get({"暴击概率", data.damageType})
        crit = math.random(100) < rate
    elseif data.critType == "必定暴击" then
        crit = true
    elseif data.critType == "必定不暴击" then
        crit = false
    else
        error("错误的暴击模式" .. data.critType)
    end
end

function battle.doDamage(data)
    if (data.type ~= "damage") then
        error('错误的类型' .. tostring(data.type))
    end

    -- 如果被攻击者不可被伤害则直接返回
    -- 此判断用于长期不可伤害的单位，不用于金身、反击等临时无敌
    -- 临时无敌只需要用damage.valide=false即可
    if data.defencer:is_damageable() == false then return end

    -- 进入伤害流程（若有免疫伤害类型的buff，监听此事件即可）
    event:notify(event.E_Damage.damageAwake, data)
    if data.valid == false then
        event:notify(event.E_Damage.damageInvalid, data)
        event:notify(event.E_Damage.damageFinish, data)
        return
    end

    -- 基础伤害
    event:notify(event.E_Damage.damageBase, data)
    if data.valid == false then
        event:notify(event.E_Damage.damageInvalid, data)
        event:notify(event.E_Damage.damageFinish, data)
        return
    end

    -- 暴击计算
    -- 非物理伤害不能暴击
    if (data.damageType == "物理") and isCrit(data) then
        data.critMul = data.attacker:get({"暴击倍率", data.damageType})
        event:notify(event.E_Damage.damageCrit, data)
        data.value = data.value * (1 + data.critMul)
        if data.valid == false then
            event:notify(event.E_Damage.damageInvalid, data)
            event:notify(event.E_Damage.damageFinish, data)
            return
        end
    end


    -- 伤害计算
    data.value = data.value *
                     (1 + data.attacker:get({"增加比伤", data.damageType}))
    data.value = data.value +
                     data.attacker:get({"增加固伤", data.damageType})
    data.value = data.value *
                     (1 + data.attacker:get({"增加比伤", "全伤"}))
    data.value = data.value + data.attacker:get({"增加固伤", "全伤"})

    data.value = data.value *
                     (1 + data.attacker:get({"减少比伤", data.damageType}))
    data.value = data.value +
                     data.attacker:get({"减少固伤", data.damageType})
    data.value = data.value *
                     (1 + data.attacker:get({"减少比伤", "全伤"}))
    data.value = data.value + data.attacker:get({"减少固伤", "全伤"})

    -- 额外计算（好像基本都是乘算）
    -- 易伤在此处，穿透是属于将属性降低了
    event:notify(event.E_Damage.damageExtra, data)
    if data.valid == false then
        event:notify(event.E_Damage.damageInvalid, data)
        event:notify(event.E_Damage.damageFinish, data)
        return
    end

    -- 即将执行
    event:notify(event.E_Damage.damageExecute, data)
    if data.valid == false then
        event:notify(event.E_Damage.damageInvalid, data)
        event:notify(event.E_Damage.damageFinish, data)
        return
    end

    -- 伤害结算
    local current = data.defencer:get("当前生命值")
    if data.value > current then
        event:notify(event.E_Damage.damageDeadly, data)
        if data.valid == false then
            event:notify(event.E_Damage.damageInvalid, data)
            event:notify(event.E_Damage.damageFinish, data)
            return
        else
            data.defencer:kill()
        end
    else
        data.defencer:set("当前生命值", current - data.value)
    end


    event:notify(event.E_Damage.damageFinish, data)

end

function battle.init()
    local trig = war3.CreateTrigger(function()
        local s = ("%s被攻击"):format(yo.unit.j_unit(jass.GetTriggerUnit()))

        print(s)
    end)

    local t = yo.unit.all_unit

    for _, _unit in pairs(t) do
        jass.TriggerRegisterUnitEvent(trig, _unit._handle,
                                      jass.EVENT_UNIT_DAMAGED)
    end
end

return battle
