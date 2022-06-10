local jass = require "jass.common"
local japi = require "jass.japi"
local dbg = require "jass.debug"
local slk = require "jass.slk"
local war3 = require "base.tools.war3"
local log = require "base.tools.log"
local point = require "base.abstract.point"
local rect = require "base.abstract.rect"
local event = require "base.system.event"
local player = require "base.types.player"
local AI = require "base.system.behaviour_tree.Ai"

local unit = {}

unit.all_unit = {}
unit.removed_handles = setmetatable({}, {__mode = "kv"})

local mt = {
    type = "unit",
    -- 单位配置
    _config = nil,
    -- 单位类型（自定义）
    _unit_type = "",
    -- 句柄
    _handle = 0,
    -- 名字
    _name = nil,
    -- 所有者（玩家）
    _owner = nil,

    -- 是否存活
    _is_alive = nil,
    -- 是否是马甲
    _is_dummy = nil,
    -- 是否是幻象
    _is_illusion = nil,

    -- 单位位置
    _center = nil,
    -- 拥有的buff
    _buffs = nil,
    -- 拥有的技能
    _abilities = nil,
    -- 拥有的物品
    _items = nil,
    -- AI系统
    _ai = nil,
    -- 当前状态（最霸道的状态）
    _states = nil
}
mt.__index = mt
-- 保存元表以在其他文件续写
unit._mt = mt

-- #region 类的成员函数

function unit.j_unit(handle)
    if not handle or handle == 0 then return end
    local u = unit.all_unit[handle]
    if not u then
        log.warn('没有被脚本控制的单位!', handle,
                 war3.id2string(jass.GetUnitTypeId(handle)),
                 jass.GetUnitName(handle))
        u = setmetatable({}, mt)
        u:init(handle)
    end
    return u
end

function unit.new(_player, Propername, setting)

    local config = yo.ini.unit[Propername]
    local int_id = war3.string2id(config.obj.ID)
    local u = setmetatable({_id = config.obj.ID}, mt)
    -- 修改物编设置
    -- u:set_slk(setting or {})
    local handle = jass.CreateUnit(_player._handle, int_id, 0, 0, 0)
    dbg.handle_ref(handle)
    u:init(handle)

    return u
end

-- 普攻伤害触发器
local trig = war3.CreateTrigger(function()
    local damage = setmetatable({}, yo.struct.damage)
    damage.fromAbility = false
    damage.attacker = unit.j_unit(jass.GetEventDamageSource())
    damage.defencer = unit.j_unit(jass.GetTriggerUnit())
    damage.value = damage.attacker:get("攻击力")
    yo.battle.doDamage(damage)
end)

-- 以handle构建一个单位
function mt:init(handle)

    if (not handle) or (handle == 0) then return false end
    if unit.removed_handles[handle] then return false end

    self._handle = handle
    -- dbg.gchash(u, handle)
    -- u.gchash = handle

    self._id = war3.id2string(jass.GetUnitTypeId(handle))
    self._owner = player.j_player(jass.GetOwningPlayer(handle))
    local config = yo.ini.unit[self:get_name()]
    if config then self._config = setmetatable(config, yo.ini.mt_unit) end

    self._name = self._config.obj.Propernames
    self._selected_radius = self._config.obj.collision
    self._items = {}
    self._states = {
        -- 无敌的(是全免疫状态)
        _invincible = false,
        -- -- 禁锢的
        _rooted = 0,
        -- -- 沉默的
        _slienced = 0,
        -- -- 隐身的
        _invisible = 0,
        -- -- 眩晕的
        _stun = 0
    }
    self:attr_init()

    -- 保存到全局单位表中
    unit.all_unit[handle] = self

    -- 令物体可以飞行
    local int_id = war3.string2id('Arav')
    jass.UnitAddAbility(self._handle, int_id)
    jass.UnitRemoveAbility(self._handle, int_id)

    -- 忽略警戒点
    jass.RemoveGuardPosition(self._handle)
    jass.SetUnitCreepGuard(self._handle, true)

    -- 设置高度
    self:set_high(self:get_slk('moveHeight', 0))

    -- 注册受到伤害事件
    jass.TriggerRegisterUnitEvent(trig, self._handle, jass.EVENT_UNIT_DAMAGED)

    -- 蝗虫技能等级
    local lv = jass.GetUnitAbilityLevel(self._handle, war3.string2id('Aloc'))

    if lv ~= 0 then self:as_dummy() end

    return true
end

-- #endregion

-- #region 单位类型

-- 将单位设定为幻象(程序上可逆但不应该可逆，不提供转回操作)
function mt:as_illusion()
    self._is_illusion = true
    return self
end

-- 是否是幻象
function mt:is_illusion()
    if not self._is_illusion then self._is_illusion = false end
    return self._is_illusion
end

-- 将单位设定为马甲(程序上可逆但不应该可逆，不提供转回操作)
function mt:as_dummy()
    self._is_dummy = true
    self:hide()
    -- 添加蝗虫技能
    jass.UnitAddAbility(self._handle, war3.string2id("Aloc"))
    self:set_invincible(true)
    return self
end

-- 是否是马甲
function mt:is_dummy()
    if not self._is_dummy then self._is_dummy = false end
    return self._is_dummy
end

-- 将单位设定为英雄(程序上可逆但不应该可逆，不提供转回操作)
function mt:as_hero()
    self._unit_type = "英雄"
    if self._owner.hero then
        error(tostring(self._owner) .. "已有英雄")
    else
        self._owner.hero = self
    end

    self:add_ability("英雄公用", "Sin+D")
    self:add_ability("锻造", "Sin+Z")
    self:add_ability("升级", "Sin+X")
    self:add_ability("天赋被动魔法书", "D")

    return self
end

-- 是否是英雄
function mt:is_hero() return self:is_type("英雄") and not self:is_illusion() end

-- 将单位设定为弹幕(程序上可逆但不应该可逆，不提供转回操作)
function mt:as_bullet()
    self._unit_type = "弹幕"
    -- 添加蝗虫技能
    jass.UnitAddAbility(self._handle, war3.string2id("Aloc"))
    self:set_invincible(true)
    -- 关闭碰撞 //TODO:测试能穿越地形与路径阻碍还有地图边界吗？
    jass.SetUnitPathing(self._handle, false)
end

-- 是否是弹幕
function mt:is_bullet() return self:is_type("弹幕") end

-- 将单位设定为商店(程序上可逆但不应该可逆，不提供转回操作)
function mt:as_shop()
    self._unit_type = "商店"
    -- 添加售出物品的技能，移除移动技能和攻击等固有技能
    -- 使用物品占满格子，后使用刷新进行更新。
end

-- 是否是弹幕
function mt:is_shop() return self:is_type("商店") end


-- 自定义类型判断
function mt:is_type(_type) return self._unit_type == _type end

-- #endregion

-- #region 物编区

-- 获取物编数据
--	数据项名称
--	[如果未找到,返回的默认值]
function mt:get_slk(name, default)
    local unit_data = slk.unit[self._id]
    if not unit_data then
        log.error('单位数据未找到', self._id)
        return default
    end
    local data = unit_data[name]
    if data == nil then return default end
    if type(default) == 'number' then return tonumber(data) or default end
    return data
end

function mt:set_slk(setting)
    -- 隐藏英雄头像
    local hide_icon = setting["hide_icon"] and 0 or 1
    print(hide_icon)
    japi.EXSetUnitInteger(war3.string2id(self._id), 47, hide_icon)
    -- 隐藏选择圈
    local hide_select = setting["hide_select"] and 0 or 1
    japi.EXSetUnitInteger(war3.string2id(self._id), 47, hide_select)
end

-- #endregion

-- #region 基础函数

function mt:__tostring()
    return ('Unit:{name:%s, unit_type:%s, handle:%s}'):format(self._name,
                                                              self._unit_type,
                                                              self._handle)
end

-- 获取单位碰撞体积（用于selector）
function mt:get_selected_radius()
    return self._selected_radius or self:get_slk("collision", 16)
end

-- 获得玩家
function mt:get_owner()
    if not self._owner then
        local j_player = jass.GetOwningPlayer(self._handle)
        self._owner = player.j_player(j_player)
    end
    return self._owner
end

-- 设置玩家
function mt:set_owner(_player, color)
    self._owner = _player
    jass.SetUnitOwner(self._handle, _player._handle, not (not color))
end

-- 获取单位四位字符ID
function mt:get_type_str_id()
    if not self._id then
        self._id = war3.id2string(jass.GetUnitTypeId(self._handle))
    end
    return self._id
end

-- 获得名字
function mt:get_name()
    if not self._name then
        self._name = self:get_slk("Propernames") or self:get_slk("Name")
    end
    return self._name
end

-- 是否存活
function mt:is_alive()
    if not self._is_alive then self._is_alive = true end
    return self._is_alive
end

-- 获得单位位置
function mt:center()
    if not self._center then self._center = point.new(0, 0) end
    local x, y = jass.GetUnitX(self._handle), jass.GetUnitY(self._handle)
    self._center.x, self._center.y = x, y
    return self._center
end

-- 设置单位位置-不会发出事件
-- 是否检查条件
-- 此api不检查点的通行条件，有需要结合is_block使用
function mt:set_center(x, y, check)
    point.gc_point.x = x
    point.gc_point.y = y
    if not point.gc_point:isin(rect.map) then
        self._owner:sendMsg('目标点超出地图范围', 5)
        return false
    end

    if check then
        if self._states._rooted == true then
            self._owner:sendMsg('被禁锢无法移动', 5)
            return false
        end
    end

    jass.SetUnitX(self._handle, x)
    jass.SetUnitY(self._handle, y)

    -- 下面的移动方式只适用于移动速度不为0的单位
    -- 当单位移速为0时只会改变碰撞器位置，不会改变模型位置
    -- jass.SetUnitX(self._handle, x)
    -- jass.SetUnitY(self._handle, y)

    -- 下面的移动方式能在移速为0时使用，但因为其机制相当于刷新单位，小地图会显示异常
    -- jass.SetUnitPosition(self._handle, x, y)
end

-- 瞬移-会发出事件
-- 是否检查位移条件
-- 是否允许穿过不可通行路径
function mt:blink_to(_point, check, flag)
    local source = self:center()

    local cross, last_walkable = source:crossUnwalk(_point)
    if cross then
        self:set_center(last_walkable, check)
        event:notify(event.E_Unit.unitBlink, self, source, last_walkable)
    else
        self:set_center(_point, check)
        event:notify(event.E_Unit.unitBlink, self, source, _point)
    end

end

-- 隐藏单位
function mt:hide(flag) jass.ShowUnit(self._handle, not flag) end

-- 颜色
mt.red = 100
mt.green = 100
mt.blue = 100
mt.alpha = 100

-- 设置单位颜色
--	[红(%)]
--	[绿(%)]
--	[蓝(%)]
function mt:setColor(red, green, blue)
    self.red, self.green, self.blue = red, green, blue
    jass.SetUnitVertexColor(self._handle, self.red * 2.55, self.green * 2.55,
                            self.blue * 2.55, self.alpha * 2.55)
end

-- 设置单位透明度
--	透明度(%)
function mt:setAlpha(alpha)
    self.alpha = alpha
    jass.SetUnitVertexColor(self._handle, self.red * 2.55, self.green * 2.55,
                            self.blue * 2.55, self.alpha * 2.55)
end

-- 获取单位透明度
function mt:getAlpha() return self.alpha end

-- 动画
-- 设置单位动画
--	动画名或动画序号
function mt:set_animation(ani)
    if not self.alive then return end
    if type(ani) == 'string' then
        jass.SetUnitAnimation(self._handle, self.animation_properties .. ani)
    else
        jass.SetUnitAnimationByIndex(self._handle, ani)
    end
end

-- 将动画添加到队列
--	动画序号
function mt:add_animation(ani)
    if not self.alive then return end
    jass.QueueUnitAnimation(self._handle, ani)
end

-- 设置动画播放速度
--	速度
function mt:set_animation_speed(speed) jass.SetUnitTimeScale(self._handle, speed) end

mt.animation_properties = ''

-- 添加动画附加名
--	附加名
function mt:add_animation_properties(name)
    jass.AddUnitAnimationProperties(self._handle, name, true)
    self.animation_properties = self.animation_properties .. name .. ' '
end

-- 移除动画附加名
--	附加名
function mt:remove_animation_properties(name)
    jass.AddUnitAnimationProperties(self._handle, name, false)
    self.animation_properties = self.animation_properties:gsub(name .. ' ', '')
end

-- 大小
mt.size = 1
mt.default_size = nil

-- 设置大小
--	大小
function mt:set_size(size)
    self.size = size
    if not self.default_size then
        self.default_size = tonumber(self:get_slk 'modelScale') or 1
    end
    size = size * self.default_size
    jass.SetUnitScale(self._handle, size, size, size)
end

-- 获取大小
function mt:get_size() return self.size end

-- 增加大小
--	大小
function mt:addSize(size)
    size = size + self:get_size()
    self:set_size(size)
end

-- 高度
mt.high = 0

-- 获取高度
--	[是否是绝对高度(地面高度+飞行高度)]
function mt:get_high(b)
    if b then
        return self:center():getZ() + self.high
    else
        return self.high
    end
end

-- 设置高度
--	高度
--	[是否是绝对高度]
function mt:set_high(high, b, change_time)
    if b then
        self.high = high - self:center():getZ()
    else
        self.high = high
    end
    jass.SetUnitFlyHeight(self._handle, self.high, change_time or 0)
end

-- 增加高度
--	高度
--	[是否是绝对高度]
function mt:add_high(high, b) self:set_high(self:get_high(b) + high) end

-- 朝向
-- 获得朝向
function mt:get_facing() return jass.GetUnitFacing(self._handle) end

-- 设置朝向
--	朝向
--  瞬间转身
function mt:set_facing(angle, instant)
    if instant then
        japi.EXSetUnitFacing(self._handle, angle)
    else
        jass.SetUnitFacing(self._handle, angle)
    end
end

-- #endregion

-- #region 排泄区

-- 清空buff
-- 是否清空死亡保留的
function mt:clear_buff(flag)
    local buffs = self._buffs
    if buffs then
        for key, buff in pairs(buffs) do
            if flag or (not buff.deadkeep) then
                self:remove_buff(buff)
            end
        end
    end

end

--  清空物品
function mt:clear_item()
    --
    local items = self._items
    if items then end
end

--  清空技能
function mt:clear_ability()
    local abs = self._abilities
    if abs then
        for key, value in pairs(abs) do self:remove_ability(value._id) end
    end
end

-- 杀死
function mt:kill()
    if not self:is_alive() then return end
    self:set("当前生命值", 0)

    -- 不杀马甲
    if not self:is_dummy() then
        jass.KillUnit(self._handle)
        event:notify(event.E_Unit.unitDead, self)
    end

    if self:is_illusion() then
        self:remove()
        -- elseif not self:is_hero() then
        --     self:remove()
    end

    -- 删除Buff
    self:clear_buff()

    self._is_alive = false
end

-- 移除
function mt:remove()
    jass.RemoveUnit(self._handle)
    dbg.handle_unref(self._handle)
    self:clear_ability()
    self:clear_buff(true)
    self:clear_item()
    event:notify(event.E_Unit.unitRemove, self)
    -- 从表中删除单位
    unit.all_unit[self._handle] = nil
end

-- #endregion

-- #region 战斗区

-- 设为可被伤害单位(常驻状态使用,非常驻见伤害系统)
function mt:set_damageable()
    self._states._invincible = false
    self.jass.SetUnitInvulnerable(self._handle, false)
end

-- 设为无敌单位(常驻状态使用,非常驻见伤害系统)
-- 是否设为不可被普攻（war3无敌）
function mt:set_invincible(flag)
    self._states._invincible = true
    if flag == true then jass.SetUnitInvulnerable(self._handle, true) end
end

-- 是否可伤害(常驻状态使用)
function mt:is_damageable() return self._states._invincible == false end

-- 添加技能
function mt:add_ability(name, hotkey_index)
    local str_id = yo.ability.get_str_id(hotkey_index)
    -- 已有技能直接返回
    if self:get_ability(str_id) then return end
    -- 消除一个技能
    yo.ability.pop_str_id(hotkey_index)
    -- 装载技能
    local _ability = yo.ini.ability[name](str_id)
    local int_id = war3.string2id(str_id)
    jass.UnitAddAbility(self._handle, int_id)
    jass.UnitMakeAbilityPermanent(self._handle, true, int_id)
    _ability._handle = japi.EXGetUnitAbility(self._handle, int_id)
    _ability._owner = self
    _ability:fresh_info()
    self._abilities[str_id] = _ability
    -- 对英雄单独的魔法书禁用
    if hotkey_index == "D" then self._owner:disable_ability(str_id) end
end

-- 删除技能
function mt:remove_ability(str_id)
    -- 没有技能直接返回
    local _ability = self:get_ability(str_id)
    if not _ability then return end

    local int_id = war3.string2id(_ability._id)
    jass.UnitRemoveAbility(self._handle, int_id)
    _ability._owner = nil
    _ability._isremoved = true
    self._abilities[str_id] = nil
end

-- 获取技能
function mt:get_ability(str_id)
    if not self._abilities then self._abilities = {} end
    return self._abilities[str_id]
end

-- 添加buff
function mt:add_buff(_buff)
    local b = self:get_buff(_buff._name)
    if b then
        b:on_fresh()
        return
    end
    _buff._attach = self
    self._buffs[_buff._name] = _buff
end

-- 移除buff
function mt:remove_buff(_buff)
    local b = self:get_buff(_buff._name)
    if not b then return end
    _buff._isremoved = true
    _buff._attach = nil
    _buff:on_remove()
    self._buffs[_buff._name] = nil
end

-- 获取buff
function mt:get_buff(_name)
    if not self._buffs then self._buffs = {} end
    return self._buffs[_name]
end

-- 添加物品
function mt:add_item(_item)
    if self:get_item(_item._handle) then return end
    jass.UnitAddItem(self._handle, war3.string2id(_item._id))
end

-- 丢弃物品
function mt:drop_item(_item)
    if not self:get_item(_item._handle) then return end
    jass.UnitAddItem(self._handle, war3.string2id(_item._id))
end

-- 获取物品
function mt:get_item(_handle)
    if not self._items then self._items = {} end
    return self._items[_handle]
end

-- 设置等级
--	等级
function mt:set_level(lv)
    if lv > self:get_level() then
        jass.SetHeroLevel(self._handle, lv, self:is_hero())
    end
end

-- 获取等级
function mt:get_level()
    if not self._level then self._level = 1 end
    return self._level
end

-- 设置时间尺度
function mt:set_timeScale(_scale)
    if self._ai then
        self._ai._timer.scale = _scale
    end
    local rate = _scale / self:get_timeScale()
    self:set("移动速度", self:get("移动速度") * rate)
    self:set("攻击速度", self:get("攻击速度") * rate)
    self._timeScale = _scale
end

-- 获得时间尺度
function mt:get_timeScale()
    if not self._timeScale then self._timeScale = 1 end
    return self._timeScale
end

-- #endregion

-- #region 控制状态区(底层抽象控制)

function mt:set_root(flag)
    local _state = self._states._rooted
    if flag == true then
        _state = _state + 1
    elseif flag == false then
        _state = _state - 1
    end
    if _state < 0 then _state = 0 end
    self._states._rooted = _state
end

function mt:is_rooted() return self._states._rooted > 0 end

function mt:set_stun(flag)
    local _state = self._states._stun
    local r_stun = _state

    if flag == true then
        _state = _state + 1
    elseif flag == false then
        _state = _state - 1
    end
    if _state < 0 then _state = 0 end

    self._states._stun = _state

    if (r_stun == 0) and (_state == 1) then
        japi.EXPauseUnit(self._handle, true)
    elseif (r_stun ~= 0) and (_state == 0) then
        japi.EXPauseUnit(self._handle, false)
    end

end

function mt:is_stunned() return self._states._stun > 0 end

function mt:set_silence(flag)
    local _state = self._states._slienced
    if flag == true then
        _state = _state + 1
    elseif flag == false then
        _state = _state - 1
    end
    if _state < 0 then _state = 0 end
    self._states._slienced = _state
end

function mt:is_silence() return self._states._slienced > 0 end

-- #endregion

-- #region 扩展区

-- 保存自定义数据
--	索引
--	值
function mt:set_data(key, value)
    if not self.user_data then self.user_data = {} end
    self.user_data[key] = value
end

-- 获取自定义数据
--	索引
function mt:get_data(key)
    if not self.user_data then self.user_data = {} end
    return self.user_data[key]
end

-- 获得物品的委托函数
function mt:on_get_item(_item)
    local index = _item._handle
    if self:get_item(index) then return end
    _item._owner = self
    _item._ability._owner = self
    self._items[index] = _item
    _item:on_get()
end

-- 丢弃物品的委托函数
function mt:on_drop_item(_item)
    local index = _item._handle
    if not self:get_item(index) then return end
    _item:on_drop()
    _item._owner = nil
    _item._ability._owner = nil
    self._items[index] = nil
end

-- 获取AI系统
function mt:get_AI()
    if not self._ai then self._ai = AI.new(self) end
    return self._ai
end

-- #endregion

return unit
