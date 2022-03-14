local struct = {}

struct.damageType = {"物理", "元素-火", "元素-冰", "元素-雷"}

struct.damage = {
    type = "damage",
    -- 物理、元素（元素-火、元素-雷、元素-冰）
    damageType = "物理",
    -- 计算暴击、必定暴击、必定不暴击
    critType = "计算暴击",
    -- 暴击倍率
    critMul = 1,
    -- 攻击方
    attacker = nil,
    -- 防御方
    defencer = nil,
    -- 是否有效
    valid = true,
    -- 伤害值
    value = 0,
    -- 是否是追击伤害
    isAddtion = false,
    -- 是否是技能伤害（反面则是普攻伤害）
    fromAbility = true,
    -- -- 是否是弹幕伤害
    -- isBullet = false,
}
struct.damage.__index = struct.damage

return struct
