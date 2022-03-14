local jass = require 'jass.common'
-----------------------------------------------------------------------------------------------------------
------------------------------------------- 局 部 函 数 库 -------------------------------------------------
-----------------------------------------------------------------------------------------------------------
-- 执行timer在frame帧的全部委托
local function timer_on_tick(timer)
    local action_queue = timer.frame_queue[timer.cur_frame]
    -- 如果在当前帧没有委托序列
    if action_queue == nil then
        -- 设置当前序列为0
        timer.cur_index = 0
        return
    end
    -- 执行当前帧的全部委托并清空当前帧的全部委托
    for i = timer.cur_index + 1, #action_queue do
        timer.cur_index = i
        local action = action_queue[i]
        if action then action:invoke() end
        action_queue[i] = nil
    end
    -- 此时当前帧执行完毕
    -- 重置当前帧的序列为0
    timer.cur_index = 0
    -- 清空当前帧
    timer.frame_queue[timer.cur_frame] = nil
    -- 回收此队列
    table.insert(timer.frame_queue, action_queue)
end

-- 计时器申请空的帧队列
local function timer_alloc_queue(timer)
    -- 获取该计时器的自由时间队列长度
    local n = #timer.free_queue
    -- 如果长度大于0,则获取到最后一个事件队列,并将此队列从自由队列移除
    -- 否则新建一个队列
    if n > 0 then
        local r = timer.free_queue[n]
        timer.free_queue[n] = nil
        return r
    else
        return {}
    end
end

-- 将委托插入到计时器的指定帧队列
local function timer_timeout(timer, timeout_frame, action)
    -- 获取到指定的帧的委托队列
    local timeout_frame = timer.cur_frame + timeout_frame
    local action_queue = timer.frame_queue[timeout_frame]
    if action_queue == nil then
        action_queue = timer_alloc_queue(timer)
        timer.frame_queue[timeout_frame] = action_queue
    end
    -- 加入委托到委托队列
    action.timer = timer -- 设定委托所属计时器
    action.timeout_frame = timeout_frame -- 记录委托到期帧数,后续暂停与恢复需要
    table.insert(action_queue, action) -- 将委托加入队列
end

-----------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------

local action = {
    type = 'timer_action',
    timer = nil, -- 动作所属计时器
    removed = nil, -- 是否被移除
    callback = nil, -- 需要执行的函数
    timeout_frame = nil, -- 单次标志位
    timeout_loop = nil, -- 循环标志位,多少帧执行一次
    pause_remaining = nil -- 暂停标志位,只有暂停过后才会赋值
}
action.__index = action

-- 执行委托
function action:invoke()
    -- 若action被移除或者暂停就直接返回,不会执行callback
    if self.removed or self.pause_remaining then return end
    -- 执行action携带函数,注意此处传入了action本身
    self:callback()
    -- 若aciton具有循环属性,则在执行过后立刻设置下一次队列
    if self.timeout_loop then
        timer_timeout(self.timer, self.timeout_loop, self)
    else
        self:remove() -- 不具备循环属性,设置移除标记等待移除
    end
end

-- 移除委托
function action:remove()
    self.removed = true -- 设置移除标记等待移除
end

-- 暂停委托
function action:pause()
    -- 为动作设定暂停标志位，赋予剩余帧给到pause_remaining
    self.pause_remaining = self:get_remaining()
    -- 获取当前动作到期队列
    local action_queue = self.timer[self.timeout_frame]
    -- 若队列存在,则断开此委托与队列的关系
    if action_queue then
        for i = #action_queue, 1, -1 do
            if action_queue[i] == self then
                action_queue[i] = nil
                return
            end
        end
    end
end

-- 恢复委托
function action:resume()
    -- 如果动作暂停过
    if self.pause_remaining then
        -- 将按照剩余时间插入时间队列,并解除暂停标志位
        timer_timeout(self.timer, self.pause_remaining, self)
        self.pause_remaining = nil
    end
end

-- 获得委托还差多少帧执行
function action:get_remaining()
    -- 已移除的动作无剩余时间
    if self.removed then
        return 0 -- 无剩余时间
    end

    -- 如果当前处于暂停状态，直接返回剩余时间
    -- 暂停时pause_remaining 被赋予get_remaining的值
    if self.pause_remaining then return self.pause_remaining end

    -- 如果动作已经到期,则返回循环时间,若不存在循环时间则返回0
    if self.timeout_frame == self.timer.cur_frame then
        return self.timeout_loop or 0
    end

    -- 如果动作未移除未暂停且未到期,则返回到期帧与当前帧的差值
    return self.timeout_frame - self.timer.cur_frame
end
-----------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------

local timer = {
    type = 'timer',
    free_queue = {}, -- 自由队列（装着委托队列）
    frame_queue = {}, -- 帧队列（装着委托队列）
    cur_frame = 0, -- 当前帧
    cur_index = 0, -- 当前补帧序号

    scale_frame = 0, -- 时间尺度影响下的frame，用于计算frame的更新
    last_scale_frame = 0, -- 时间尺度影响下的frame，用于计算frame的更新
    scale = 1 -- 时间尺度
}
timer.__index = timer

-- 计时器驱动函数
function timer:on_update()
    self.scale_frame = self.scale_frame + self.scale
    local frame_count = self.scale_frame // 1 - self.last_scale_frame // 1
    for i = 1, frame_count, 1 do
        timer_on_tick(self)
        self.cur_frame = self.cur_frame + 1
    end
    self.last_scale_frame = self.scale_frame
end

-- 返回当前帧
function timer:clock() return self.cur_frame end


-- 返回计时器委托个数
function timer:timer_size()
    local n = 0
    local frame_queue = self.frame_queue
    for frame, action_queue in pairs(frame_queue) do
        n = n + #action_queue -- 加上队列里所有action的数量
    end
    return n
end

-- 多少帧后执行callback
function timer:wait(timeout_frame, callback)
    local timeout = math.max(math.floor(timeout_frame) or 1, 1)
    local action_obj = setmetatable({callback = callback}, action)
    timer_timeout(self, timeout, action_obj)
    return action_obj
end

-- 每隔多少帧执行callback
function timer:loop(timeout_frame, callback)
    local timeout = math.max(math.floor(timeout_frame) or 1, 1)
    local action_obj = setmetatable({callback = callback}, action)
    action_obj.timeout_loop = timeout -- 设定循环周期
    timer_timeout(self, timeout, action_obj)
    return action_obj
end

-- 每隔多少帧执行callback，执行count次
function timer:timer(timeout_frame, count, callback)
    if count == 0 then return self:wait(timeout_frame, callback) end
    local t = self:loop(timeout_frame, function(action_obj)
        callback(action_obj)
        count = count - 1
        if count <= 0 then action_obj:remove() end
    end)
    return t
end

-----------------------------------------------------------------------------------------------------------
----------------------------------     Create Timer  相     关     ----------------------------------------
-----------------------------------------------------------------------------------------------------------

local api = {}
-- 新建一个计时器
function api.new(driver_timer)
    local t = setmetatable({}, timer)
    if driver_timer then driver_timer:loop(1, function() t:on_update() end) end
    return t
end
-- 中心计时器
api.realTimer = api.new()

-----------------------------------------------------------------------------------------------------------
----------------------------------     Jass Timer    相     关     ----------------------------------------
-----------------------------------------------------------------------------------------------------------

local realTimer = api.realTimer
local jtimer = jass.CreateTimer()
require('jass.debug').handle_ref(jtimer)
jass.TimerStart(jtimer, 0.01, true, function()
    local detla = 10

    -- 如果cur_index不等于0，则帧率后退
    -- 这里代表的是上一帧的序列没执行完成时，当前计时器回退1个scale
    if realTimer.cur_index ~= 0 then
        realTimer.scale_frame = realTimer.scale_frame - realTimer.scale
    end

    -- 每次调用执行delta次
    for i = 1, detla, 1 do
        realTimer:on_update()
        -- print("on_update")
    end

end)

return api
