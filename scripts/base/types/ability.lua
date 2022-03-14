local japi = require "jass.japi"
local slk = require 'jass.slk'
local jass = require "jass.common"
local player = require "base.types.player"
local war3 = require "base.tools.war3"
local math = require "base.tools.math"
local log = require "base.tools.log"
local timer = require "base.system.timer"
local event = require "base.system.event"
local unit = require "base.types.unit"

-- 仅涉及到按钮的显示逻辑与点击逻辑
-- 点击后做什么不归他管
local ability = {}

local CHARGE_FRAME = 8

local mt = {
    type = "ability",
    -- 以下均通过配置文件赋予，实际底层均为继承通魔的空的技能按钮模板

    -- 技能名
    _name = "",
    -- 最大等级
    _level = 0,
    -- 描述信息
    _tip = "",
    -- 句柄
    _handle = 0,
    -- 四位字符ID
    _id = "",
    -- 基础命令
    _order = "",
    -- 所在单位
    _owner = nil,
    -- 热键
    _hotkey = "",
    -- 图标
    _art = "",
    -- 最大充能次数
    _charge = 0,
    -- 充能时间,
    _cool_frame = 0,
    -- 魔法消耗
    _cost_mana = 0,
    -- 被动技能
    _passive = false,
    -- 可用的，生效的
    _enable = true,

    -- 额外信息
    -- 影响半径
    _radius = 0,
    -- 施法距离
    _range = 0,
    -- 目标类型,
    _target_type = 0,
    -- 目标允许
    _target_type_allow = "",
    -- 图标可见的
    _visiable = true,
    -- 技能被移除
    _isremoved = false

}

mt.__index = mt

-- #region 类的成员函数

function ability.new(str_id)
    if not str_id or str_id == "" then return end

    local _ability = setmetatable({}, mt)
    _ability._id = str_id
    _ability._hotkey = _ability:get_slk("Hotkey", "")
    local order = _ability:get_slk("DataF", "")
    if order ~= "" then _ability._order = order end

    -- 冷却计时器
    timer.realTimer:loop(CHARGE_FRAME, function(action_obj)
        if _ability._isremoved then action_obj:remove() end

        -- _ability:fresh_info()

        -- 没学习技能的时候直接返回
        if _ability._level == 0 then
            _ability:fresh_cool_remain()
            return
        end

        -- 当充能层数满的时候直接返回
        local charge_count = _ability:get_charge_count()
        if charge_count == _ability._charge then return end

        -- 还有使用次数就刷新技能
        if charge_count > 0 then _ability:fresh_cool_remain() end

        -- 冷却计时
        local cool_remain = _ability:get_cool_remain()
        if cool_remain > 0 then
            cool_remain = cool_remain - CHARGE_FRAME
            _ability:set_cool_remain(cool_remain)
            if charge_count == 0 then
                japi.EXSetAbilityState(_ability._handle, 0x01,
                                       cool_remain / 1000)
            end
        else
            charge_count = charge_count + 1
            _ability:set_charge_count(charge_count)
            _ability:set_cool_remain(_ability._cool_frame)
        end

    end)

    return _ability
end

function ability.convertTargets(data)
    local result = 0
    for name in data:gmatch '%S+' do
        local flag = ability.convert_targets[name]
        if not flag then error('错误的目标允许类型: ' .. name) end
        result = result + flag
    end
    return result
end

function ability.init()
    -- 技能目标类型常量
    ability.TARGET_TYPE_NONE = 0 -- 无目标
    ability.TARGET_TYPE_UNIT = 1 -- 单位目标
    ability.TARGET_TYPE_POINT = 2 -- 点目标
    ability.TARGET_TYPE_UNIT_OR_POINT = 3 -- 单位或点
    -- 常用的技能目标类型
    ability.TARGET_DATA_ENEMY = '敌人'
    ability.TARGET_DATA_ALLY = '自己 玩家单位 联盟'
    -- 转换目标允许
    ability.convert_targets = {
        ["地面"] = 2 ^ 1,
        ["空中"] = 2 ^ 2,
        ["建筑"] = 2 ^ 3,
        ["守卫"] = 2 ^ 4,
        ["物品"] = 2 ^ 5,
        ["树木"] = 2 ^ 6,
        ["墙"] = 2 ^ 7,
        ["残骸"] = 2 ^ 8,
        ["装饰物"] = 2 ^ 9,
        ["桥"] = 2 ^ 10,
        -- ["未知"]	= 2 ^ 11,
        ["自己"] = 2 ^ 12,
        ["玩家单位"] = 2 ^ 13,
        ["联盟"] = 2 ^ 14,
        ["中立"] = 2 ^ 15,
        ["敌人"] = 2 ^ 16,
        -- ["未知"]	= 2 ^ 17,
        -- ["未知"]	= 2 ^ 18,
        -- ["未知"]	= 2 ^ 19,
        ["可攻击的"] = 2 ^ 20,
        ["无敌"] = 2 ^ 21,
        ["英雄"] = 2 ^ 22,
        ["非-英雄"] = 2 ^ 23,
        ["存活"] = 2 ^ 24,
        ["死亡"] = 2 ^ 25,
        ["有机生物"] = 2 ^ 26,
        ["机械类"] = 2 ^ 27,
        ["非-自爆工兵"] = 2 ^ 28,
        ["自爆工兵"] = 2 ^ 29,
        ["非-古树"] = 2 ^ 30,
        ["古树"] = 2 ^ 31
    }
    -- 技能选项
    ability.options = {
        ["图标可见"] = 2 ^ 0,
        -- 选中后从准心会变成圆面
        ["目标选取图像"] = 2 ^ 1
    }

    -- 注册触发器
    local j_trg = war3.CreateTrigger(function()
        local hero = unit.j_unit(jass.GetTriggerUnit())
        -- local spellX = jass.GetSpellTargetX()
        -- local spellY = jass.GetSpellTargetY()
        local ability_id = war3.id2string(jass.GetSpellAbilityId())
        event:notify(event.E_Ability.ButtonClick, hero, ability_id)
    end)
    for i = 1, 13 do
        jass.TriggerRegisterPlayerUnitEvent(j_trg, player[i]._handle,
                                            jass.EVENT_PLAYER_UNIT_SPELL_CHANNEL,
                                            nil)
    end

    -- 绑定事件
    event:add(event.E_Ability.ButtonClick, function(_hero, _str_id)
        local _ability = _hero:get_ability(_str_id)
        -- 如果技能不在单位身上就在单位的物品身上
        if _ability then
            _ability:button_click()
        else
            for _, _item in pairs(_hero._items) do
                if _item._ability._id == _str_id then
                    _item:on_use()
                    event:notify(event.E_Item.ItemUse, _item)
                    break
                end
            end
        end
    end)

end

function ability.get_str_id(hotkey_index)
    local hotkey_table = yo.ini.ability[hotkey_index]
    local len = #hotkey_table
    local str_id = hotkey_table[len]
    return str_id
end

function ability.pop_str_id(hotkey_index)
    local hotkey_table = yo.ini.ability[hotkey_index]
    local len = #hotkey_table
    if not hotkey_index:find("Sin") then table.remove(hotkey_table, len) end
end

-- #endregion

-- #region 物编区

-- 获取物编数据
--	数据项名称
--	[如果未找到,返回的默认值]
function mt:get_slk(name, default)
    local ability_data = slk.ability[self._id]
    if not ability_data then
        print('技能数据未找到', self._id)
        return default
    end
    local data = ability_data[name]
    if data == nil then return default end
    if type(default) == 'number' then return tonumber(data) or default end
    return data
end

local color_format = {
    ["name"] = "|cff88ff88%s|r",
    ["level"] = "|cffffff00%s|r",
    ["extra"] = "|cffff00f0%s|r",
    ["highlight"] = "|cffaa0000%s|r"
}

-- 获得标题
local function get_title(self)
    local name = color_format["name"]:format(self._name)

    local level_str = ""
    local level = self:get_level()
    if level == 0 then
        level_str = ' - [未习得]'
    else
        level_str = " - [第" .. color_format["level"]:format(level) .. "级]"
    end

    local hotkey = "(" .. color_format["highlight"]:format(self._hotkey) .. ")"

    return name .. level_str .. hotkey
end

-- 获得额外信息
local function get_extra_info(self)
    local cool
    local charge
    local radius
    local range
    local target
    if self._passive then
        cool = ""
    else
        local _temp = tostring(math.ceil(self._cool_frame / 1000))
        if self._charge > 1 then
            charge = "\n" .. color_format["extra"]:format("充能次数") .. ":"
            charge = charge .. tostring(self._charge)
            cool = "\n" .. color_format["extra"]:format("充能时间") .. ":"
            cool = cool .. _temp
        else
            charge = ""
            cool = "\n" .. color_format["extra"]:format("冷却时间") .. ":"
            cool = cool .. _temp
        end
        if self._radius > 0 then
            _temp = tostring(math.ceil(self._radius))
            radius = "\n" .. color_format["extra"]:format("影响范围") .. ":"
            radius = radius .. _temp
        else
            radius = ""
        end
        if self._range > 0 then
            _temp = tostring(math.ceil(self._range))
            range = "\n" .. color_format["extra"]:format("施法距离") .. ":"
            range = range .. _temp
        else
            range = ""
        end

        target = "\n" .. color_format["extra"]:format("目标类型") .. ":"
        local tt = self._target_type
        if tt == ability.TARGET_TYPE_NONE then
            target = target .. '无'
        elseif tt == ability.TARGET_TYPE_POINT then
            target = target .. '地面'
        elseif tt == ability.TARGET_TYPE_UNIT then
            target = target .. '单位'
        elseif tt == ability.TARGET_TYPE_UNIT_OR_POINT then
            target = target .. '单位或地面'
        end
        return charge .. cool .. radius .. range .. target
    end

end

-- 获得tip
function mt:get_tip()
    local tip = self._tip:gsub('%%([%w_]*)%%',
                               function(name) return self[name] end)
    return tip .. "\n" .. get_extra_info(self)
end

-- 获得暗图标
local function get_art_b(self) return "" end

-- 根据上面的信息用japi写入技能中去
function mt:fresh_info()
    -- 检查可见性是否有更新的必要
    -- 通过异步减少计算量
    if not self._owner or
        not jass.GetPlayerAlliance(self._owner._owner._handle,
                                   player._self._handle, 6) then return end
    if not self._visiable then return end

    self:on_fresh()

    -- 根据上面的信息用japi写入技能中去

    -- 标题
    local title = get_title(self)
    if japi.EXSetAbilityString then
        japi.EXSetAbilityString(war3.string2id(self._id), 1, 0xD7, title)
    else
        japi.EXSetAbilityDataString(self._handle, 1, 0xD7, title)
    end

    -- 说明
    local tip = self:get_tip()
    if japi.EXSetAbilityString then
        japi.EXSetAbilityString(war3.string2id(self._id), 1, 0xDA, tip)
    else
        japi.EXSetAbilityDataString(self._handle, 1, 0xDA, tip)
    end

    -- 图标
    local art = self._enable and self._art or get_art_b(self)
    japi.EXSetAbilityString(war3.string2id(self._id), 1, 0xCC, art)

    -- 热键
    local hotkey = self._hotkey and self._hotkey:byte() or 0
    japi.EXSetAbilityDataInteger(self._handle, 1, 0xC8, hotkey)

    -- 施法距离
    local range = self._range or 0
    japi.EXSetAbilityDataReal(self._handle, 1, 0x6B, range)

    -- 影响范围
    local radius = self._radius or 0
    japi.EXSetAbilityDataReal(self._handle, 1, 0x6A, radius)

    -- 蓝耗
    local cost = self._cost_mana or 0
    japi.EXSetAbilityDataInteger(self._handle, 1, 0x68, cost)

    -- 释放间隔
    local cool = self._cool_frame or 0
    japi.EXSetAbilityDataReal(self._handle, 1, 0x69, cool / 1000)

    -- 目标类型
    if self._passive then
        japi.EXSetAbilityDataReal(self._handle, 1, 0x6D,
                                  ability.TARGET_TYPE_NONE)
    else
        -- 目标类型
        japi.EXSetAbilityDataReal(self._handle, 1, 0x6D, self._target_type)
        -- 目标允许
        local target_data = ability.convertTargets(self._target_type_allow)
        japi.EXSetAbilityDataInteger(self._handle, 1, 0x64, target_data)
        -- 技能选项
        local options = ((self._radius > 0) and 0x02 or 0x00) + 0x01
        japi.EXSetAbilityDataReal(self._handle, 1, 0x6E, options)
        -- 改一下技能等级以刷新目标允许
        local int_id = war3.string2id(self._id)
        jass.SetUnitAbilityLevel(self._owner._handle, int_id, 2)
        jass.SetUnitAbilityLevel(self._owner._handle, int_id, 1)
    end
end

-- #endregion

-- #region 逻辑区

-- 是否可以释放技能
function mt:iscastable()
    if self._level == 0 then return false end
    -- 被动技能和技能是否启用是模拟出来的
    if self._passive or not self._enable then return false end

    return true
end

-- 触发响应
function mt:button_click()
    if not self:iscastable() then return end

    local charge_count = self:get_charge_count()
    if charge_count == 0 then return end

    self:on_cast()
    charge_count = charge_count - 1
    self:set_charge_count(charge_count)
end

-- 获取剩余冷却时间
function mt:get_cool_remain()
    if not self.cool_remain then
        if self._charge > 1 then
            self.cool_remain = self._cool_frame
        else
            self.cool_remain = 0
        end
    end
    return self.cool_remain
end

-- 设置剩余冷却时间
function mt:set_cool_remain(_frame)
    self.cool_remain = math.clamp(_frame, 0, self._cool_frame)
end

-- 刷新技能冷却
function mt:fresh_cool_remain() japi.EXSetAbilityState(self._handle, 0x01, 0) end

-- 获取可释放层数
function mt:get_charge_count()
    if not self.charge_count then self.charge_count = 0 end
    return self.charge_count
end

-- 设置可释放层数
function mt:set_charge_count(_value)
    self.charge_count = math.clamp(_value, 0, self._charge)
end

-- 获取技能等级
function mt:get_level()
    if not self.level then self.level = 0 end
    return self.level
end

-- 设置技能等级
function mt:set_levle(_value) self.level = yo.math.clamp(_value, 0, self._level) end

-- 提升技能等级
function mt:upgrade()
    local levle = self:get_level()
    if levle == self._level then
        return false
    else
        return true
    end
end

-- #endregion

-- #region 虚函数

function mt:on_fresh()
    print(string.format("技能(%s,%d)信息更新", self._name, self._handle))
end

function mt:on_cast()
    print(string.format("技能(%s,%d)被释放", self._name, self._handle))
end

-- #endregion

return ability
