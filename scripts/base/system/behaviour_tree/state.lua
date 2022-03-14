local action = {_can_break = false}
action.__index = action
function action:on_action(_unit) end
function action:on_finish(_unit) end

local state = {}

local mt = {
    type = "state",
    -- 所属AI系统
    _ai = nil,
    -- 是否正在被AI执行
    _enable = false
}
mt.__index = mt

function yo.state.new(_ai)
    local t = setmetatable({_ai = _ai}, mt)
    return t
end
function yo.state.new_aciton(data)
    local t = setmetatable(data or {}, action)
    return t
end

function mt:enter()
    if not self:on_condition() then return end

    self._enable = true
    self._ai.state = self
    self:on_enter()
end

function mt:exit()
    self._enable = false
    self._ai._state = nil
    self:on_exit()
end

-- #region 虚函数

-- 需要返回真值判定是否会进入此状态
function mt:on_condition() return true end

function mt:on_enter() end

function mt:on_exit() end

-- #endregion

return state
