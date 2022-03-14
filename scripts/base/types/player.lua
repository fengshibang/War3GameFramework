local jass = require "jass.common"
local dbg = require "jass.debug"
local event = require "base.system.event"
local war3 = require "base.tools.war3"
local point = require "base.abstract.point"
local rect = require "base.abstract.rect"
local circle = require "base.abstract.circle"
local fogmodifier = require "base.types.fogmodifier"

local player = {}

local all_player = {}

local mt = {type = "player", _handle = 0}
mt.__index = mt
-- 保存原表以在其他文件续写
player._mt = mt

local color_word = {}
local function set_color_word()
    -- 注册颜色代码
    color_word[1] = '|cFFFF0303'
    color_word[2] = '|cFF0042FF'
    color_word[3] = '|cFF1CE6B9'
    color_word[4] = '|cFF540081'
    color_word[5] = '|cFFFFFC01'
    color_word[6] = '|cFFFE8A0E'
    color_word[7] = '|cFF20C000'
    color_word[8] = '|cFFE55BB0'
    color_word[9] = '|cFF959697'
    color_word[10] = '|cFF7EBFF1'
    -- color_word[11] = "|cFF106246"
    -- color_word[12] = "|cFF4E2A04"
    color_word[11] = '|cFFFFFC01'
    color_word[12] = '|cFF0042FF'
    color_word[13] = '|cFF282828'
    color_word[14] = '|cFF282828'
    color_word[15] = '|cFF282828'
    color_word[16] = '|cFF282828'
end

-- #region 类的成员函数

-- 以1开始的索引，获得玩家
function player.get(index)
    if player[index] then
        return player[index]
    else
        error("未初始化玩家")
    end
end

function player.j_player(handle) return all_player[handle] end

function player.init()
    -- 初始化所有玩家
    for i = 1, 16, 1 do
        local p = setmetatable({}, mt)
        p._handle = jass.Player(i - 1)
        p._id = i
        all_player[p._handle] = p
        player[i] = p
    end

    -- 真实的玩家数量
    player._count = 0
    for i = 1, 16, 1 do
        -- 是否在线
        if player[i]:is_player() then player._count = player._count + 1 end
    end

    -- 设定本地玩家
    player._self = all_player[jass.GetLocalPlayer()]

    -- 保留2个图标位置
    jass.SetReservedLocalHeroButtons(0)

    -- 所有玩家都与16号玩家结盟
    for i = 1, 16 do player[i]:set_alliance_simple(player[16], true) end

    -- 初始化玩家颜色值
    set_color_word()
end

-- 清点在线玩家
function player.count_alive()
    local count = 0
    for i = 1, 16 do if player[i]:is_player() then count = count + 1 end end
    return count
end

-- #endregion

-- #region 基础

function mt:__tostring()
    return ('Player:{id:%s,name:%s}'):format(self._id, self:get_name())
end

function mt:get_name()
    if not self._name then self._name = jass.GetPlayerName(self._handle) end
    return self._name
end

function mt:set_name(name)
    if (not name) or name == "" then return end
    jass.SetPlayerName(self._handle, name)
    self._name = name
end

-- 设置颜色
-- 玩家index的颜色，以1起始
function mt:set_color(index) jass.SetPlayerColor(self._handle, index - 1) end

-- 结盟
function mt:set_alliance(dest, al, flag)
    return jass.SetPlayerAlliance(self._handle, dest._handle, al, flag)
end

-- 单位共享
--	[显示头像]
function mt:enableControl(dest, flag)
    jass.SetPlayerAlliance(dest._handle, self._handle, 6, true)
    if flag then jass.SetPlayerAlliance(dest._handle, self._handle, 7, true) end
end

-- 结盟的常用设置
function mt:set_alliance_simple(dest, flag)

    self:set_alliance(dest, 0, flag) -- ALLIANCE_PASSIVE（结盟，不侵犯）
    self:set_alliance(dest, 1, false) -- ALLIANCE_HELP_REQUEST（救援请求）
    self:set_alliance(dest, 2, false) -- ALLIANCE_HELP_RESPONSE（救援回应）
    self:set_alliance(dest, 3, flag) -- ALLIANCE_SHARED_XP（共享经验）
    self:set_alliance(dest, 4, flag) -- ALLIANCE_SHARED_SPELLS（盟友魔法锁定）
    self:set_alliance(dest, 5, flag) -- ALLIANCE_SHARED_VISION（共享视野）

    -- self:setAlliance(dest, 6, flag) -- ALLIANCE_SHARED_CONTROL（共享单位）
    -- self:setAlliance(dest, 7, flag) -- ALLIANCE_SHARED_ADVANCED_CONTROL（共享完全控制权）
    -- self:setAlliance(dest, 8, flag) -- ALLIANCE_RESCUABLE（救援）
    -- self:setAlliance(dest, 9, flag) -- ALLIANCE_SHARED_VISION_FORCED（共享视野）

end

-- 队伍
-- 设置队伍
function mt:set_team(team_id)
    jass.SetPlayerTeam(self._handle, team_id - 1)
    self.team_id = team_id
end

-- 获取队伍
function mt:get_team()
    if not self.team_id then
        self.team_id = jass.GetPlayerTeam(self._handle) + 1
    end
    return self.team_id
end

-- 命令玩家选中单位
--	单位
function mt:selectUnit(_unit)
    if self == player._self then
        jass.ClearSelection()
        jass.SelectUnit(_unit._handle, true)
    end
end

-- 命令玩家加选单位
--	单位
function mt:addSelect(_unit)
    if self == player._self then jass.SelectUnit(_unit._handle, true) end
end

-- 命令玩家取消选择某单位
--	单位
function mt:removeSelect(_unit)
    if self == player._self then jass.SelectUnit(_unit._handle, false) end
end

-- 禁用技能
function mt:enable_ability(ability_id)
    if ability_id then
        jass.SetPlayerAbilityAvailable(self._handle, war3.string2id(ability_id),
                                       true)
    end
end

function mt:disable_ability(ability_id)
    if ability_id then
        jass.SetPlayerAbilityAvailable(self._handle, war3.string2id(ability_id),
                                       false)
    end
end

-- 强制按键
--	按下的键(字符串'ESC'表示按下ESC键)
function mt:press_key(key)
    if self ~= player._self then return end

    local key = key:upper()

    if key == 'ESC' then
        jass.ForceUICancel()
    else
        jass.ForceUIKey(key)
    end
end

-- 禁止框选
function mt:disable_drag_select()
    if self == player._self then jass.EnableDragSelect(false, false) end
end

-- 允许框选
function mt:enable_drag_select()
    if self == player._self then jass.EnableDragSelect(true, true) end
end

-- 获得文字颜色
function mt:get_word_color() return color_word[self._id] end

-- #endregion

-- #region 界面

-- 允许UI
function mt:enableUI() if self == player._self then jass.EnableUserUI(true) end end

-- 禁止UI
function mt:disableUI() if self == player._self then jass.EnableUserUI(false) end end

-- 显示界面
--	[转换时间]
function mt:showInterface(time)
    if self == player._self then jass.ShowInterface(true, time or 0) end
end

-- 隐藏界面
--	[转换时间]
function mt:hideInterface(time)
    if self == player._self then jass.ShowInterface(false, time or 0) end
end

-- 设置昼夜模型
local default_model =
    'Environment\\DNC\\DNCLordaeron\\DNCLordaeronTerrain\\DNCLordaeronTerrain.mdl'
function mt:set_day(model)
    if self == player._self then
        jass.SetDayNightModels(model or default_model,
                               'Environment\\DNC\\DNCLordaeron\\DNCLordaeronUnit\\DNCLordaeronUnit.mdl')
    end
end

-- 强制按键
--	按下的键(字符串'ESC'表示按下ESC键)
function mt:pressKey(key)
    if self ~= player._self then return end

    key = key:upper()

    if key == 'ESC' then
        jass.ForceUICancel()
    else
        jass.ForceUIKey(key)
    end
end

-- #endregion

-- #region 资源区

-- 增加金钱
-- 是否抛出加钱事件
function mt:add_gold(gold, flag)
    if gold > 0 and not flag then
        event:notify(event.E_Player.get_gold, self, gold)
    end
    if self._gold then
        self._gold = self._gold + gold
    else
        self._gold = gold
    end
    jass.SetPlayerState(self._handle, jass.PLAYER_STATE_RESOURCE_GOLD,
                        self._gold)
end

-- 获取金钱
function mt:get_gold()
    if not self._gold then
        self._gold = self.jass.GetPlayerState(self._handle,
                                              jass.PLAYER_STATE_RESOURCE_GOLD)
    end
    return self._gold
end

-- 增加木材
-- 是否抛出加木材事件
function mt:add_lumber(lumber, flag)
    if lumber > 0 and not flag then
        event:notify(event.E_Player.get_lumber, self, lumber)
    end
    if self._lumber then
        self._lumber = self._lumber + lumber
    else
        self._lumber = lumber
    end
    jass.SetPlayerState(self._handle, jass.PLAYER_STATE_RESOURCE_LUMBER,
                        self._lumber)
end

-- 获取木材
function mt:get_lumber()
    if not self._lumber then
        self._lumber = self.jass.GetPlayerState(self._handle,
                                                jass.PLAYER_STATE_RESOURCE_LUMBER)
    end
    return self._lumber
end

-- 增加人口
-- 是否抛出加人口事件
function mt:add_food(food, flag)
    if food > 0 and not flag then
        event:notify(event.E_Player.get_food, self, food)
    end
    if self._food then
        self._food = self._food + food
    else
        self._food = food
    end
    jass.SetPlayerState(self._handle, jass.PLAYER_STATE_RESOURCE_FOOD_USED,
                        self._food)
end

-- 获取人口
function mt:get_food()
    if not self._food then
        self._food = self.jass.GetPlayerState(self._handle,
                                              jass.PLAYER_STATE_RESOURCE_FOOD_USED)
    end
    return self._food
end

-- #endregion

-- #region 条件判断

-- 是否是玩家
function mt:is_player()
    return jass.GetPlayerController(self._handle) == jass.MAP_CONTROL_USER and
               jass.GetPlayerSlotState(self._handle) ==
               jass.PLAYER_SLOT_STATE_PLAYING
end

-- 是否是裁判
function mt:isObserver() return jass.IsPlayerObserver(self._handle) end

-- 是否是本地玩家
function mt:is_self() return self == player._self end

-- 目标点对我是否可见
function mt:is_visible(_point)
    return jass.IsVisibleToPlayer(_point.x, _point.y, self._handle)
end

-- 是否是敌人
function mt:is_enemy(dest) return self:get_team() ~= dest:get_team() end

-- 是否是友军
function mt:is_ally(dest) return self:get_team() == dest:get_team() end

-- #endregion

-- #region 信息传递

-- 发送消息
--	消息内容
--	[持续时间]
function mt:sendMsg(text, time)
    jass.DisplayTimedTextToPlayer(self._handle, 0, 0, time or 60, text)
end

-- 显示系统警告
--	警告内容
function mt:showSysWarning(msg)
    local sys_sound = jass.CreateSoundFromLabel('InterfaceError', false, false,
                                                false, 10, 10)
    if (jass.GetLocalPlayer() == self._handle) then
        if (msg ~= '') and (msg ~= nil) then
            jass.ClearTextMessages()
            jass.DisplayTimedTextToPlayer(self._handle, 0.5, -1, 2,
                                          '|cffffcc00' .. msg .. '|r')
        end
        jass.StartSound(sys_sound)
    end
    jass.KillSoundWhenDone(sys_sound)
end

-- 小地图信号
--	信号位置
--	信号时间
--	[红色]
--	[绿色]
--	[蓝色]
function mt:pingMinimap(_point, time, red, green, blue, flag)
    if self == player._self then
        jass.PingMinimapEx(_point.x, _point.y, time, red or 0, green or 255,
                           blue or 0, not (not flag))
    end
end

-- 清空屏幕显示
function mt:clearMsg() if self == player._self then jass.ClearTextMessages() end end

-- #endregion

-- #region 镜头

-- 设置镜头位置
function mt:setCamera(_point, time)
    if player._self == self then
        local x, y
        if _point then
            x, y = _point:get()
        else
            x, y = jass.GetCameraTargetPositionX(),
                   jass.GetCameraTargetPositionY()
        end
        if time then
            jass.PanCameraToTimed(x, y, time)
        else
            jass.SetCameraPosition(x, y)
        end
    end
end

-- 设置镜头属性
--	镜头属性
--	数值
--	[持续时间]
function mt:setCameraField(key, value, time)
    if self == player._self then
        jass.SetCameraField(jass[key], value, time or 0)
    end
end

-- 获取镜头属性
--	镜头属性
function mt:getCameraField(key) return math.deg(jass.GetCameraField(jass[key])) end

-- 设置镜头目标
function mt:setCameraTarget(target, x, y)
    if self == player._self then
        jass.SetCameraTargetController(target and target.handle or 0, x or 0,
                                       y or 0, false)
    end
end

-- 旋转镜头
function mt:rotateCamera(_point, angle, time)
    if self == player._self then
        local x, y = _point:get()
        jass.SetCameraRotateMode(x, y, math.rad(angle), time)
    end
end

-- 获取镜头位置
function mt:getCamera()
    return point.new(jass.GetCameraTargetPositionX(),
                     jass.GetCameraTargetPositionY())
end

-- 设置镜头可用区域
function mt:setCameraBounds(...)
    if self == player._self then
        local minX, minY, maxX, maxY
        if select('#', ...) == 1 then
            local rct = rect.j_rect(...)
            minX, minY, maxX, maxY = rct:get()
        else
            minX, minY, maxX, maxY = ...
        end
        jass.SetCameraBounds(minX, minY, minX, maxY, maxX, maxY, maxX, minY)
    end
end

-- 创建可见度修正器
--	圆心
--	半径
--	[是否可见]
--	[是否共享]
--	[是否覆盖单位视野]
function mt:createFogmodifier(_player, radius, ...)
    local cir = circle.new(_player, radius)
    return fogmodifier.new(self, cir, ...)
end

-- 滤镜
function mt:cinematic_filter(data)
    jass.SetCineFilterTexture(data.file or
                                  [[ReplaceableTextures\CameraMasks\DreamFilter_Mask.blp]])
    jass.SetCineFilterBlendMode(jass.BLEND_MODE_BLEND)
    jass.SetCineFilterTexMapFlags(jass.TEXMAP_FLAG_NONE)
    jass.SetCineFilterStartUV(0, 0, 1, 1)
    jass.SetCineFilterEndUV(0, 0, 1, 1)
    if data.start then
        jass.SetCineFilterStartColor(data.start[1] * 2.55, data.start[2] * 2.55,
                                     data.start[3] * 2.55, data.start[4] * 2.55)
    end
    if data.finish then
        jass.SetCineFilterEndColor(data.finish[1] * 2.55, data.finish[2] * 2.55,
                                   data.finish[3] * 2.55, data.finish[4] * 2.55)
    end
    jass.SetCineFilterDuration(data.time)
    if self == player._self then jass.DisplayCineFilter(true) end

    function data:remove()
        if self == player._self then jass.DisplayCineFilter(false) end
    end

    return data
end

-- #endregion

-- #region 未知

-- #endregion

return player
