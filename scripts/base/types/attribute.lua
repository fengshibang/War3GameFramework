local jass = require 'jass.common'
local japi = require 'jass.japi'
local war3 = require "base.tools.war3"
local move = require "base.types.move"
local math = require "base.tools.math"
local mt = require"base.types.unit"._mt
local damamgeType = require"base.define.struct".damageType

local attr_mt = {
    ["当前生命值"] = 0,
    ["最大生命值"] = 0,
    ["当前魔法值"] = 0,
    ["最大魔法值"] = 0,
    ["攻击力"] = 0,
    ["攻击间隔"] = 0,
    ["攻击速度"] = 0,
    ["攻击范围"] = 0,
    ["移动速度"] = 0,

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
    ["增加固伤"] = {
        ["物理"] = 0,
        ["元素-火"] = 0,
        ["元素-雷"] = 0,
        ["元素-冰"] = 0,
        ["全伤"] = 0
    },
    ["增加比伤"] = {
        ["物理"] = 0,
        ["元素-火"] = 0,
        ["元素-雷"] = 0,
        ["元素-冰"] = 0,
        ["全伤"] = 0
    },
    ["减少固伤"] = {
        ["物理"] = 0,
        ["元素-火"] = 0,
        ["元素-雷"] = 0,
        ["元素-冰"] = 0,
        ["全伤"] = 0
    },
    ["减少比伤"] = {
        ["物理"] = 0,
        ["元素-火"] = 0,
        ["元素-雷"] = 0,
        ["元素-冰"] = 0,
        ["全伤"] = 0
    }
}
attr_mt.__index = attr_mt

local set = {}
local get = {}
local on_add = {}
local on_get = {}
local on_set = {}

function mt:attr_init()
    
    self._attri_config = setmetatable({}, self._config.ini.attribute)
    war3.copy_table(self._config.ini.attribute,self._attri_config)
    self._attribute = setmetatable({}, attr_mt)
    for key1, value1 in pairs(self._attri_config) do
        local index1 = value1[1]
        if index1 then
            -- 是数组表
            self:set(key1, value1[1])
        else
            -- 是哈希表
            for key2, value2 in pairs(value1) do
                self:set({key1, key2}, value2)
            end
        end
    end

    self:set("当前生命值", self:get("最大生命值"))
end

function mt:set(key_pair, value)
    local function_index
    if type(key_pair) == "string" then
        if not attr_mt[key_pair] then
            error('错误的属性名:' .. tostring(key_pair))
            return
        end
        function_index = key_pair
    elseif type(key_pair) == "table" then
        local key1, key2 = key_pair[1], key_pair[2]
        if not attr_mt[key1][key2] then
            error(string.format('错误的属性名: %s,%s',key1,key2))
            return
        end
        function_index = table.concat(key_pair, ",")
    end

    set[function_index](self, value)
end

function mt:get(key_pair)
    local function_index
    if type(key_pair) == "string" then
        if not attr_mt[key_pair] then
            error('错误的属性名:' .. tostring(key_pair))
            return
        end
        function_index = key_pair
    elseif type(key_pair) == "table" then
        local key1, key2 = key_pair[1], key_pair[2]
        if not attr_mt[key1][key2] then
            error(string.format('错误的属性名: %s,%s',key1,key2))
            return
        end
        function_index = table.concat(key_pair, ",")
    end

    return get[function_index](self)
end

-- #region 一级表函数初始化
get["当前生命值"] =
    function(self) return jass.GetWidgetLife(self._handle) end

set["当前生命值"] = function(self, life)
    if life > 1 then
        jass.SetWidgetLife(self._handle, life)
    else
        jass.SetWidgetLife(self._handle, 1)
    end
end

get["最大生命值"] = function(self)
    return jass.GetUnitState(self._handle, jass.UNIT_STATE_MAX_LIFE)
end

set["最大生命值"] = function(self, max_life, old_max_life)
    japi.SetUnitState(self._handle, jass.UNIT_STATE_MAX_LIFE, max_life)
    if self.freshDefenceInfo then self:freshDefenceInfo() end
end

on_set["最大生命值"] = function(self)
    local rate = self:get("当前生命值") / self:get("最大生命值")
    self:set("当前生命值", self:get("最大生命值") * rate)
end

get["当前魔法值"] = function(self)
    return jass.GetUnitState(self._handle, jass.UNIT_STATE_MANA)
end

set["当前魔法值"] = function(self, mana)
    jass.SetUnitState(self._handle, jass.UNIT_STATE_MANA, mana)
end

on_add["当前魔法值"] = function(self, v1, v2)
    v1 = v1 + v1 * self:get 'enegy_aquire_rate' / 100
    return v1, v2
end

get["最大魔法值"] = function(self)
    return jass.GetUnitState(self._handle, jass.UNIT_STATE_MAX_MANA)
end

set["最大魔法值"] = function(self, max_mana)
    japi.SetUnitState(self._handle, jass.UNIT_STATE_MAX_MANA, max_mana)
end

on_set["最大魔法值"] = function(self)
    local rate = self:get("当前魔法值") / self:get("最大魔法值")
    self:set("当前魔法值", self:get("最大魔法值") * rate)
end

get["攻击力"] = function(self)
    japi.SetUnitState(self._handle, 0x10, 1)
    japi.SetUnitState(self._handle, 0x11, 1)
    return japi.GetUnitState(self._handle, 0x12) + 1
end

set["攻击力"] = function(self, attack)
    japi.SetUnitState(self._handle, 0x12, attack - 1)
end

get["攻击间隔"] = function(self) return
    japi.GetUnitState(self._handle, 0x25) end

set["攻击间隔"] = function(self, _value)
    japi.SetUnitState(self._handle, 0x25, _value)
end

set["攻击速度"] = function(self, _value)
    if _value >= 0 then
        japi.SetUnitState(self._handle, 0x51, 1 + _value / 100)
    else
        -- 当攻击速度小于0的时候,每点相当于攻击间隔增加1%
        japi.SetUnitState(self._handle, 0x51, 1 + _value / (100 - _value))
    end
end

get["攻击范围"] = function(self) return
    japi.GetUnitState(self._handle, 0x16) end

set["攻击范围"] = function(self, attack_range)
    japi.SetUnitState(self._handle, 0x16, attack_range)
end

get["移动速度"] = function(self)
    return jass.GetUnitDefaultMoveSpeed(self._handle)
end

set["移动速度"] = function(self, move_speed)
    if self._states._rooted == false then
        jass.SetUnitMoveSpeed(self._handle, move_speed)
    end
    move.update_speed(self, on_get["移动速度"](self, move_speed))
end

on_get["移动速度"] = function(self, move_speed)
    return math.clamp(move_speed, 0, 1000)
end

-- #endregion

-- #region 二级表函数初始化

local vol1 = {"暴击概率", "暴击倍率"}
local vol2 = {"物理", "元素-火", "元素-冰", "元素-雷"}

for index1, value1 in ipairs(vol1) do
    for index2, value2 in ipairs(vol2) do
        get[value1 .. "," .. value2] = function(self)
            return self._attribute[value1][value2]
        end

        set[value1 .. "," .. value2] = function(self, _value)
            self._attribute[value1][value2] = _value
        end
    end
end

vol1 = {"增加固伤", "增加比伤", "减少固伤", "减少比伤"}
vol2 = {"物理", "元素-火", "元素-冰", "元素-雷", "全伤"}

for index1, value1 in ipairs(vol1) do
    for index2, value2 in ipairs(vol2) do
        get[value1 .. "," .. value2] = function(self)
            return self._attribute[value1][value2]
        end

        set[value1 .. "," .. value2] = function(self, _value)
            self._attribute[value1][value2] = _value
        end
    end
end

-- #endregion
