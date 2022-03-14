yo.ini.ability["天赋被动"] = function(str_id)

    local mt = yo.ability.new(str_id)
    -- 基础信息
    mt._name = "天赋被动"
    mt.level = 1
    mt._level = 1
    mt._cost_mana = 0
    mt._charge = 0
    mt._radius = 0
    mt._cool_frame = 0

    return mt
end

yo.ini.ability["天赋被动魔法书"] = function(str_id)

    local mt = yo.ability.new(str_id)
    -- 基础信息
    mt._name = "天赋被动魔法书"
    mt.level = 1
    mt._level = 1
    mt._cost_mana = 0
    mt._charge = 0
    mt._radius = 0
    mt._cool_frame = 0
    mt._order="spellbook"
    return mt
end

