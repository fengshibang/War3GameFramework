local table_insert = table.insert

-- 事件中心
local event = {}
event.__index = event

event.E_Player = {
    -- 本地键盘事件
    ["key_down"] = "玩家-按下按键",
    ["key_up"] = "玩家-抬起按键",
    ["key_click"] = "玩家-点击按键",
    ["key_hold"] = "玩家-长按按键",
    ["key_unhold"] = "玩家-释放长按按键",
    -- 普通的玩家事件
    ['create_unit'] = '玩家-创建单位',
    ['create_char'] = '玩家-创建角色',
    ['send_msg'] = '玩家-发送消息',
    ['unit_select'] = '玩家-选中单位',
    ['unit_unselect'] = '玩家-取消选中单位',
    -- 1
    ["get_gold"] = "玩家-获得金钱",
    ["get_lumber"] = "玩家-获得木材",
    ["get_food"] = "玩家-获得人口"
}

event.E_Unit = {
    ["regionEnter"] = "区域-进入区域",
    ["regionLeave"] = "区域-离开区域",
    ["unitDead"] = "单位-死亡",
    ["unitRemove"] = "单位-移除",
    ["unitBlink"] = "单位-瞬移",
}
event.E_Ability = {
    ["ButtonClick"] = "技能-War3释放",
    ["AbilitySpell"] = "技能-释放技能"

}
event.E_Item = {
    ["ItemGet"] = "物品-获得物品",
    ["ItemDrop"] = "物品-丢弃物品",
    ["ItemUse"] = "物品-使用物品",
    ["ItemSell"] = "物品-售出物品"
}
event.E_Damage = {
    ["damageAwake"] = "伤害-进入流程",
    ["damageCrit"] = "伤害-造成暴击",
    ["damageInvalid"] = "伤害-无效化",
    ["damageCalcu"] = "伤害-属性计算",
    ["damageExtra"] = "伤害-额外计算",
    ["damageExecute"] = "伤害-执行步骤",
    ["damageDeadly"] = "伤害-致命伤害",
    ["damageFinish"] = "伤害-结束流程"
}

-----------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------

function event:add(eventName, func)
    if (eventName == nil or func == nil) then return end
    if (self[eventName] == nil) then self[eventName] = {} end
    table_insert(self[eventName], func)
    return func
end

function event:remove(eventName, func)
    if (eventName == nil or func == nil) then return end
    local action = self[eventName]
    if (action ~= nil) then
        if (func == nil) then
            for k, v in pairs(action) do action[k] = nil end
        else
            for k, v in pairs(action) do
                if (v == func) then action[k] = nil end
            end
        end
    end
    table_insert(self[eventName], func)
end

function event:notify(eventName, ...)
    if not eventName then return end
    local action = self[eventName]
    if not action then return end
    for i = #action, 1, -1 do action[i](...) end
end

return event
