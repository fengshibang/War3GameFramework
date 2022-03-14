-- #region 读取元表设定
yo.ini.mt_unit = {
    obj = {
        -- 由程序决定
        ID = "",
        -- 父对象
        _parent = "",
        -- 名字
        Name = "未定义",
        -- 称谓（仅英雄拥有，显示于面板顶部）
        Propernames = "未定义",
        -- 模型路径
        file = "",
        -- 模型缩放
        modelScale = 1,
        -- 选择圈缩放大小
        scale = 1,
        -- 阴影类型(空字符串,Shadow,ShadowFlyer)
        unitShadow = "",
        -- 游戏左上角的图标
        Art = "",
        -- 碰撞体积(8,16,32,48有效)
        collision = 0,
        -- 单位声音
        unitSound = "",
        -- 隐藏英雄图标,0为显示1为隐藏
        hideHeroBar = 1,
        --
        -- 隐藏英雄的小地图显示
        hideHeroMinMap = 1,
        -- 移动速度为0，隐藏了大部分默认面板
        spd = 300,
        -- 隐藏A键的UI，与移动速度为0结合隐藏所有默认UI
        showUI1 = 1,
        -- 目标允许别人，残骸，基本不会自动攻击了
        -- targs1 = 'notself,debris',
        --
        -- 普通技能设定(默认的背包技能)
        abilList = "AInv",
        -- 英雄技能清空，使学技能的+号隐藏
        heroAbilList = "",
        -- 隐藏英雄死亡信息
        hideHeroDeathMsg = 1,
        -- 骰子数量与面数，保持为1使攻击力稳定
        sides1 = 1,
        dice1 = 1,
        -- 称谓数量
        nameCount = 1,
        -- 设置移动高度
        moveHeight = 0,
        -- 攻击前摇后腰与施法前摇后摇
        dmgpt1 = 0.1,
        backSw1 = 0,
        castpt = 0,
        castbsw = 0,
        -- 三维初始值与成长值归零
        STR = 0,
        AGI = 0,
        INT = 0,
        STRplus = 0,
        AGIplus = 0,
        INTplus = 0
    },
    ini = {
        -- 设计信息
        model_source = '东方战姬',
        hero_desinger = '幽幽墨染_樱树花开',
        hero_scripter = '幽幽墨染_樱树花开',
        -- 属性
        attribute = {
            -- 初始属性，每级提升属性
            ["最大生命值"] = {2000, 10},
            ["最大魔法值"] = {80, 2},
            ["攻击力"] = {200, 2},
            ["移动速度"] = {400, 2},
            ["攻击间隔"] = {1, -0.005}, -- 最小0.1
            ["攻击速度"] = {100, 0},
            ["攻击范围"] = {322, 0},

            ["暴击概率"] = {
                ["物理"] = 10,
                ["元素-火"] = 0,
                ["元素-雷"] = 0,
                ["元素-冰"] = 0
            },
            ["暴击倍率"] = {
                ["物理"] = 0,
                ["元素-火"] = 0,
                ["元素-雷"] = 0,
                ["元素-冰"] = 0
            },

            -- 攻击方
            ["增加固伤"] = {
                ["物理"] = 0,
                ["元素-火"] = 0,
                ["元素-雷"] = 0,
                ["元素-冰"] = 0,
                ["全伤"] = 0
            },
            -- 攻击方
            ["增加比伤"] = {
                ["物理"] = 0,
                ["元素-火"] = 0,
                ["元素-雷"] = 0,
                ["元素-冰"] = 0,
                ["全伤"] = 0
            },
            -- 防御方
            ["减少固伤"] = {
                ["物理"] = 0,
                ["元素-火"] = 0,
                ["元素-雷"] = 0,
                ["元素-冰"] = 0,
                ["全伤"] = 0
            },
            -- 防御方
            ["减少比伤"] = {
                ["物理"] = 0,
                ["元素-火"] = 0,
                ["元素-雷"] = 0,
                ["元素-冰"] = 0,
                ["全伤"] = 0
            }

        },
        -- 武器类型
        weapon_type = '太刀',
        -- 种族信息
        category = '半灵',
        -- 妹子
        yuri = true,
        -- 平胸
        pad = true,

        -- 技能名字   {"", "", ""}
        ability_names = nil,

        -- AI名字(表结构)
        -- 随机AI     {{{"", "", ""},0.2},{"", "", ""},0.4},{"", "", ""},0.4},}
        random_states = nil,
        -- 周期AI   {{"",14},{"",15},{"",30},}
        period_states = nil,
        -- 事件AI   {"", "", ""}
        event_states = nil

    }
}
yo.ini.mt_unit.__index=yo.ini.mt_unit

yo.ini.mt_ability = {
    -- 由程序决定
    ID = "",
    -- 父对象
    _parent = "ANcl",
    -- 名字
    Name = "技能模板",
    -- 提示
    Tip = "提示",
    -- 图标
    Art = "",
    -- 热键
    Hotkey = "",
    -- 按钮位置 - 普通 (X)
    Buttonpos_1 = 0,
    -- 按钮位置 - 普通 (Y)
    Buttonpos_2 = 2,
    -- 物品技能
    item = 0,
    -- 英雄技能
    hero = 1,
    -- 最大等级 
    levels = 2,
    -- 基础命令ID
    DataF = {"", ""},
    -- 使其他技能无效
    DataE = {0, 0},
    -- 动作持续时间
    DataD = {0, 0},
    -- 技能选项（1:图标可见）
    DataC = {1, 1},
    -- 目标类型
    DataB = {0, 0},
    -- 施法持续时间
    DataA = {0, 0},

    -- 魔法释放间隔
    Cool = {0, 0},
    -- 提示工具 - 普通 - 扩展
    Ubertip = "1",
    -- 效果 - 目标
    TargetArt = "",
    -- 效果 - 施法者
    CasterArt = "",
    -- 效果 - 目标点
    EffectArt = ""
}

yo.ini.mt_item = {
    -- 物品ID(由程序决定)
    ID = "",
    -- 绑定的技能(由程序决定)
    -- abilList = "",
    -- 父对象
    _parent = "ches",
    -- 名字
    Name = "物品模板",
    -- 主动使用
    usable = 1,
    -- 黄金消耗
    goldcost = 0,
    -- 可以被抵押
    pawnable = 1
}

-- #endregion

yo.ini.unit = {}
yo.ini.ability = {}
yo.ini.item = {}
yo.ini.destruct = {}
yo.ini.state={}

-- #region 单位读取

require "config.unit.敌机.熊王.init"
require "config.unit.自机.魂魄妖梦.幽人的庭师.init"

-- #endregion

-- #region 技能读取

yo.ini.ability["英雄公用"] = function(str_id)
    local mt = yo.ability.new(str_id)
    mt._name = "英雄公用"
    mt.level = 1
    mt._level = 1
    mt._cost_mana = 0
    mt._charge = 1
    mt._radius = 0
    mt._cool_frame = 0
    mt._tip = [[英雄技能]]

    return mt
end

yo.ini.ability["锻造"] = function(str_id)
    local mt = yo.ability.new(str_id)
    mt._name = "锻造"
    mt.level = 1
    mt._level = 1
    mt._cost_mana = 0
    mt._charge = 1
    mt._radius = 0
    mt._cool_frame = 0
    mt._tip = [[将装备锻造成其他装备]]

    mt._target_type = yo.ability.TARGET_TYPE_UNIT
    mt._target_type_allow = "物品"

    return mt
end

yo.ini.ability["升级"] = function(str_id)
    local mt = yo.ability.new(str_id)
    mt._name = "升级"
    mt.level = 1
    mt._level = 1
    mt._cost_mana = 0
    mt._charge = 1
    mt._radius = 0
    mt._cool_frame = 0
    mt._tip = [[将装备升级]]

    mt._target_type = yo.ability.TARGET_TYPE_UNIT
    mt._target_type_allow = "物品"

    return mt
end

-- #endregion

-- #region 物品读取
require "config.item.兽王之鼓"
-- #endregion

-- #region 可破坏物读取

-- #endregion

