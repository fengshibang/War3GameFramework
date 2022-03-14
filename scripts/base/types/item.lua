local jass = require "jass.common"
local japi = require "jass.japi"
local event = require "base.system.event"
local war3 = require "base.tools.war3"
local player = require "base.types.player"
local unit = require "base.types.unit"
local ability = require "base.types.ability"

local item = {}
item.all_item = {}
item.name_to_id = {}
-- 无目标，点目标，友方目标，敌方目标
item.id_count = {0, 0, 0, 0}

local mt = {
    type = "item",

    -- ID
    _id = "",
    -- 句柄
    _handle = 0,
    -- 物品名称
    _name = "",
    -- 所有者（单位）
    _owner = nil,
    -- 创建帧
    _create_frame = 0,
    -- 绑定技能
    _ability = nil,

    -- 自定义的物品类型
    _item_type = "",
    -- 图标
    _art = "",
    -- 购买说明
    _purchase = "购买_name%%",
    -- 在地上的说明
    _tip = "地上的说明",
    -- 装备栏的说明
    _tip_ex = "装备栏的说明",
    -- 价格
    _gold = 0

}
mt.__index = mt

-- type_int取值范围[1,4]
function item.new(name, type_int)
    -- 相同物品名公用一个ID
    local str_id = item.name_to_id[name]
    if not str_id then
        item.id_count[type_int] = item.id_count[type_int] + 1
        str_id = war3.ItemID(type_int * 36 ^ 2 + item.id_count[type_int])
        item.name_to_id[name] = str_id
    end
    local i = setmetatable({_id = str_id}, mt)
    i._id = str_id
    i._name = name
    i._handle = jass.CreateItem(war3.string2id(str_id), 0, 0)
    i._create_frame = yo.timer.realTimer:clock()
    i._ability = ability.new("A" .. str_id:sub(2, 4))

    item.all_item[i._handle] = i
    return i
end

function item.init()

    -- 获得物品
    local j_trg = war3.CreateTrigger(function()
        local _item = item.j_item(jass.GetManipulatedItem())
        local _unit = unit.j_unit(jass.GetTriggerUnit())
        _unit:on_get_item(_item)
        event:notify(event.E_Item.ItemGet, _item)
    end)
    for i = 1, 13 do
        jass.TriggerRegisterPlayerUnitEvent(j_trg, player[i]._handle,
                                            jass.EVENT_PLAYER_UNIT_PICKUP_ITEM,
                                            nil)
    end

    -- 丢弃物品
    local j_trg = war3.CreateTrigger(function()
        local _item = item.j_item(jass.GetManipulatedItem())
        local _unit = unit.j_unit(jass.GetTriggerUnit())
        event:notify(event.E_Item.ItemDrop, _item)
        _unit:on_drop_item(_item)
    end)
    for i = 1, 13 do
        jass.TriggerRegisterPlayerUnitEvent(j_trg, player[i]._handle,
                                            jass.EVENT_PLAYER_UNIT_DROP_ITEM,
                                            nil)
    end

    -- 由于使用物品无法捕捉到其主动技能相关信息，所以已放弃使用
    -- -- 使用物品
    -- local j_trg = war3.CreateTrigger(function()
    --     local _item = item.j_item(jass.GetManipulatedItem())
    --     _item:on_use()
    --     event:notify(event.E_Item.ItemUse, _item)
    -- end)
    -- for i = 1, 13 do
    --     jass.TriggerRegisterPlayerUnitEvent(j_trg, player[i]._handle,
    --                                         jass.EVENT_PLAYER_UNIT_USE_ITEM, nil)
    -- end

    -- -- 售出物品
    -- local j_trg = war3.CreateTrigger(function()
    --     local _item = item.j_item(jass.GetManipulatedItem())
    --     event:notify(event.E_Item.ItemSell, _item)
    -- end)
    -- for i = 1, 13 do
    --     jass.TriggerRegisterPlayerUnitEvent(j_trg, player[i]._handle,
    --                                         jass.EVENT_UNIT_SELL_ITEM, nil)
    -- end
end

function item.j_item(_handle) return item.all_item[_handle] end

-- #region 物编区

local color_format = {
    ["name"] = "|cffaa0000%s|r",
    ["extra"] = "|cffaa0000%s|r",
    ["highlight"] = "|cffaa0000%s|r"
}

-- 获得标题
local function get_title(self)
    local name = color_format["name"]:format(self._name)
    return name
end

-- 获得购买的说明
local function get_purchase(self)
    return self._purchase:gsub('%%([%w_]*)%%',
                               function(name) return self[name] end)
end

-- 获得在地上的说明
local function get_tip(self)
    return self._tip:gsub('%%([%w_]*)%%', function(name) return self[name] end)
end

-- 获得在装备栏的说明
local function get_tip_ex(self)
    return self._tip_ex:gsub('%%([%w_]*)%%',
                             function(name) return self[name] end)
end

-- 获得暗图标
local function get_art_b(self) return "" end

function mt:fresh_info()
    local int_id = war3.string2id(self._id)

    -- 设置图标
    japi.EXSetItemDataString(int_id, 1, self._art)

    -- 设购买文本
    japi.EXSetItemDataString(int_id, 2, get_purchase(self))

    -- 设置物品栏文本
    japi.EXSetItemDataString(int_id, 3, get_tip_ex(self))

    -- 设置名字
    japi.EXSetItemDataString(int_id, 4, get_title(self))

    -- 设置地面说明
    japi.EXSetItemDataString(int_id, 5, get_tip(self))

end
-- #endregion

-- #region 逻辑区

-- 获取使用次数
function mt:get_stack() return jass.GetItemCharges(self._handle) end

-- 设置使用次数
function mt:set_stack(count) jass.SetItemCharges(self._handle, count) end

-- 增加使用次数
function mt:add_stack(count) self:set_stack(self:get_stack() + (count or 1)) end

-- 设置是否可丢弃
function mt:dropable(flag) jass.SetItemDroppable(self._handle, flag) end

-- 销毁物品
function mt:remove() jass.RemoveItem(self._handle) end

-- #endregion

-- #region 虚函数

function mt:on_get()
    print(string.format("物品(%s,%d)被捡起", self._name, self._handle))
end

function mt:on_use()
    print(string.format("物品(%s,%d)被使用", self._name, self._handle))
end

function mt:on_drop()
    print(string.format("物品(%s,%d)被丢弃", self._name, self._handle))
end
-- #endregion

return item
