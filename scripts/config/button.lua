local button = {}

button["Q"] = {
    -- 名字
    Name = "Q",
    -- 按钮位置 - 普通 (X)
    Buttonpos_1 = 0,
    -- 按钮位置 - 普通 (Y)
    Buttonpos_2 = 2,
    -- 英雄技能
    hero = 1,
    -- 基础命令ID
    DataF = {"blizzard", ""},
    -- 热键
    Hotkey = "Q"
}
button["W"] = {
    -- 名字
    Name = "W",
    -- 按钮位置 - 普通 (X)
    Buttonpos_1 = 1,
    -- 按钮位置 - 普通 (Y)
    Buttonpos_2 = 2,
    -- 英雄技能
    hero = 1,
    -- 基础命令ID
    DataF = {"divineshield", ""},
    -- 热键
    Hotkey = "W"
}
button["E"] = {
    -- 名字
    Name = "E",
    -- 按钮位置 - 普通 (X)
    Buttonpos_1 = 2,
    -- 按钮位置 - 普通 (Y)
    Buttonpos_2 = 2,
    -- 英雄技能
    hero = 1,
    -- 基础命令ID
    DataF = {"undivineshield", ""},
    -- 热键
    Hotkey = "E"
}
button["R"] = {
    -- 名字
    Name = "R",
    -- 按钮位置 - 普通 (X)
    Buttonpos_1 = 3,
    -- 按钮位置 - 普通 (Y)
    Buttonpos_2 = 2,
    -- 英雄技能
    hero = 1,
    -- 基础命令ID
    DataF = {"holybolt", ""},
    -- 热键
    Hotkey = "R"
}
button["F"] = {
    -- 名字
    Name = "F",
    -- 按钮位置 - 普通 (X)
    Buttonpos_1 = 1,
    -- 按钮位置 - 普通 (Y)
    Buttonpos_2 = 1,
    -- 英雄技能
    hero = 1,
    -- 基础命令ID
    DataF = {"massteleport", ""},
    -- 热键
    Hotkey = "F"
}

button["D"] = {
    -- 父对象
    _parent = "Aspb",
    -- 名字
    Name = "D",
    -- 按钮位置 - 普通 (X)
    Buttonpos_1 = 2,
    -- 按钮位置 - 普通 (Y)
    Buttonpos_2 = 1,
    -- 英雄技能
    hero = 1,
    -- 物品技能
    item = 0,
    -- 基础命令ID
    DataE = {"berserk", ""},
    -- 最小法术数量
    DataC = 0,
    -- 最大法术数量
    DataD = 12,
    -- 热键
    Hotkey = "D"
}

button["P"] = {
    -- 名字
    Name = "P",
    -- 按钮位置 - 普通 (X)
    Buttonpos_1 = 3,
    -- 按钮位置 - 普通 (Y)
    Buttonpos_2 = 0,
    -- 英雄技能
    hero = 1,
    -- 基础命令ID
    DataF = {"bloodlust", ""},
    -- 技能选项（1:图标可见）
    DataC = {1, 1},
    -- 热键
    Hotkey = "P"
}

-- 学习技能的按钮行为模式相同、隐藏且不用变更，只做一个


button["Sin+Q"] = {
    -- 名字
    Name = "Sin+Q",
    -- 按钮位置 - 普通 (X)
    Buttonpos_1 = 0,
    -- 按钮位置 - 普通 (Y)
    Buttonpos_2 = 2,
    -- 英雄技能
    hero = 1,
    -- 基础命令ID
    DataF = {"resurrection", ""},
    -- 技能选项（1:图标可见）
    DataC = {0, 0}
}
button["Sin+W"] = {
    -- 名字
    Name = "Sin+W",
    -- 按钮位置 - 普通 (X)
    Buttonpos_1 = 1,
    -- 按钮位置 - 普通 (Y)
    Buttonpos_2 = 2,
    -- 英雄技能
    hero = 1,
    -- 基础命令ID
    DataF = {"thunderbolt", ""},
    -- 技能选项（1:图标可见）
    DataC = {0, 0}
}
button["Sin+E"] = {
    -- 名字
    Name = "Sin+E",
    -- 按钮位置 - 普通 (X)
    Buttonpos_1 = 2,
    -- 按钮位置 - 普通 (Y)
    Buttonpos_2 = 2,
    -- 英雄技能
    hero = 1,
    -- 基础命令ID
    DataF = {"thunderclap", ""},
    -- 技能选项（1:图标可见）
    DataC = {0, 0}
}
button["Sin+R"] = {
    -- 名字
    Name = "Sin+R",
    -- 按钮位置 - 普通 (X)
    Buttonpos_1 = 3,
    -- 按钮位置 - 普通 (Y)
    Buttonpos_2 = 2,
    -- 英雄技能
    hero = 1,
    -- 基础命令ID
    DataF = {"waterelemental", ""},
    -- 技能选项（1:图标可见）
    DataC = {0, 0}
}
button["Sin+F"] = {
    -- 名字
    Name = "Sin+F",
    -- 按钮位置 - 普通 (X)
    Buttonpos_1 = 1,
    -- 按钮位置 - 普通 (Y)
    Buttonpos_2 = 1,
    -- 英雄技能
    hero = 1,
    -- 基础命令ID
    DataF = {"battlestations", ""},
    -- 技能选项（1:图标可见）
    DataC = {0, 0}
}

-- 魔法书和魔法书内的公用按钮只做一个

button["Sin+D"] = {
    -- 父对象
    _parent = "Aspb",
    -- 名字
    Name = "Sin+D",
    -- 按钮位置 - 普通 (X)
    Buttonpos_1 = 2,
    -- 按钮位置 - 普通 (Y)
    Buttonpos_2 = 1,
    -- 英雄技能
    hero = 1,
    -- 物品技能
    item = 0,
    -- 基础命令ID
    DataE = {"berserk", ""},
    -- 最小法术数量
    DataC = 0,
    -- 最大法术数量
    DataD = 12,
    -- 热键
    Hotkey = "D"
}

button["Sin+Z"] = {
    -- 名字
    Name = "Sin+Z",
    -- 按钮位置 - 普通 (X)
    Buttonpos_1 = 0,
    -- 按钮位置 - 普通 (Y)
    Buttonpos_2 = 0,
    -- 英雄技能
    hero = 1,
    -- 基础命令ID
    DataF = {"bloodlustoff", ""},
    -- 技能选项（1:图标可见）
    DataC = {1, 1},
    -- 热键
    Hotkey = "Z"

}

button["Sin+X"] = {
    -- 名字
    Name = "Sin+X",
    -- 按钮位置 - 普通 (X)
    Buttonpos_1 = 1,
    -- 按钮位置 - 普通 (Y)
    Buttonpos_2 = 0,
    -- 英雄技能
    hero = 1,
    -- 基础命令ID
    DataF = {"devour", ""},
    -- 目标类型
    DataB = {1, 1},
    -- 技能选项（1:图标可见）
    DataC = {1, 1},
    -- 热键
    Hotkey = "X"
}

return button
