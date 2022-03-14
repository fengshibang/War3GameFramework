yo.ini.item["兽王之鼓"] = function()

    local item = yo.item.new("兽王之鼓",2)
    item._item_type = "武器"
    item._art="abc"
    item._tip="武器"
    item._tip_ex =
        [[你的每点破防提升%crit_damage%%的暴击伤害，最多提升100%。]]
    item._gold = 10
    item.crit_damage=200

    item:fresh_info()

    -- function item:on_use()

    -- end


end
