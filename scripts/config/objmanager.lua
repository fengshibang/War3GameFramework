local slk = require "jass.slk"
local war3 = require "base.tools.war3"

local objmanager = {}

-- #region 生成物编

local function single_table(obj_table, base_table)
    local function serialize(_key, _value)
        local line
        if type(_value) == "string" then
            line = ("%s = [[%s]]"):format(_key, _value)
        elseif type(_value) == "table" then
            local _value = war3.copy_table(_value, {})
            for index, value in ipairs(_value) do
                if type(value) == "string" then
                    _value[index] = string.format([["%s"]], value)
                end
            end
            line = _key .. " = {" .. table.concat(_value, ", ") .. "}"
        else
            line = _key .. " = " .. _value
        end
        return line
    end

    local str = ""

    for key, value in pairs(base_table) do
        if (key ~= "__index") and (key ~= "ID") then
            local line
            if obj_table[key] then
                line = serialize(key, obj_table[key])
            else
                line = serialize(key, base_table[key])
            end
            str = str .. line .. "\n"
        end
    end
    return str
end

local unit_count = 1
local function unit_table()
    local file = io.open("table/unit.ini", "w")

    for key, value in pairs(yo.ini.unit) do
        local str = "[" .. war3.UnitID(unit_count) .. "]" .. "\n"
        file:write(str .. single_table(value.obj, yo.ini.mt_unit.obj) .. "\n")
        unit_count = unit_count + 1
    end
    file:flush()
end

-- 物品的ID[I1XX=I4XX]
local function item_table()
    local file = io.open("table/item.ini", "w")

    for i = 1, 4, 1 do
        for j = 1, 300, 1 do
            local index = i * 36 ^ 2 + j
            local str_id = war3.ItemID(index)
            local str = "[" .. str_id .. "]" .. "\n"
            str = str .. "abilList = \"A" .. str_id:sub(2, 4) .. "\"\n"
            file:write(str .. single_table({}, yo.ini.mt_item) .. "\n")
        end
    end
    file:flush()
end

-- 单位技能
-- A0XX-JAPI修改
-- 物品技能又要分为（点目标、单位目标）x（友方、敌方）
-- A1XX-无目标
-- A2XX-点目标
-- A3XX-友方单位目标
-- A4XX-敌方单位目标

local ability_count = 1
local function ability_table()
    local file = io.open("table/ability.ini", "w")

    -- 生成英雄技能
    local function create_hero_ability()
        for i = 1, 13 * 2, 1 do
            -- 获取单个英雄的技能
            local hero = {}
            for key, _butt in pairs(yo.hero_button) do
                if not key:find("Sin") then
                    local str_id = war3.AbilityID(ability_count)
                    hero[key] = war3.copy_table(_butt, {})
                    hero[key].ID = str_id
                    ability_count = ability_count + 1
                end
            end
            hero["D"]["DataA"] = hero["P"].ID

            -- 输出信息到ini文件
            for key, value in pairs(hero) do
                local str = "[" .. value.ID .. "]" .. "\n"
                value.Name = file:write(str ..
                                            single_table(value,
                                                         yo.ini.mt_ability) ..
                                            "\n")
            end
        end
    end

    -- 生成公用技能
    local function create_common_ability()
        local common = {}
        for key, _butt in pairs(yo.hero_button) do
            if key:find("Sin") then
                local str_id = war3.AbilityID(ability_count)
                common[key] = war3.copy_table(_butt, {})
                common[key].ID = str_id
                ability_count = ability_count + 1
            end
        end
        common["Sin+D"]["DataA"] = ("%s, %s"):format(common["Sin+Z"].ID,
                                                     common["Sin+X"].ID)

        -- 输出信息到ini文件
        for key, value in pairs(common) do
            local str = "[" .. value.ID .. "]" .. "\n"
            file:write(str .. single_table(value, yo.ini.mt_ability) .. "\n")
        end
    end

    create_common_ability()
    create_hero_ability()

    -- 生成物品技能
    for i = 1, 4, 1 do
        for j = 1, 50, 1 do
            local index = i * 36 ^ 2 + j
            local str = "[" .. war3.AbilityID(index) .. "]" .. "\n"
            local t = {Name = ("物品技能(%d,%d)"):format(i, j)}
            file:write(str .. single_table(t, yo.ini.mt_ability) .. "\n")
        end
    end

    file:flush()
end

-- #endregion

-- 重新生成物编
function objmanager.fresh()
    unit_table()

    item_table()

    ability_table()
end

-- 获取物编对应关系
function objmanager.init()
    -- unit
    for key, value in pairs(slk.unit) do
        local name = value["Propernames"]
        local info = yo.ini.unit[name]
        if info then
            print("objID", name, key)
            info.obj.ID = key
        end
    end
    -- ability
    for key, value in pairs(slk.ability) do
        local name = value["Name"]
        if yo.hero_button[name] then
            local info = yo.ini.ability[name]
            if not info then
                info = {}
                yo.ini.ability[name] = info
            end
            table.insert(info, key)
        end

    end
end

return objmanager
