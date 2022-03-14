local ai = {}

local mt = {

    -- 随机AI
    random_states = nil,
    -- 周期AI
    period_states = nil,

    -- 行为周期缩减，越大周期越短
    _loop_div = 1,

    -- 随机行为意愿[0,1],越大越趋向于释放技能
    _random_willing = 0.5,
    -- 随机判定间隔
    _random_interval = 1,
    -- 等待中
    _random_waiting = false,

    -- 执行中的state(不为nil则ai在执行动作)
    _state = nil,
    -- 所属单位
    _owner = nil,
    -- AI计时器
    _timer = nil

}
mt.__index = mt

function ai.new(_unit)
    local config = _unit._config
    if not config then error("No config unit create AI") end
    local t = setmetatable({_owner = _unit}, mt)
    return t
end

function mt:load_states()
    local config = self._owner._config.ini

    -- 载入随机状态
    local randoms = config.random_states
    if randoms then
        self.random_states = yo.pool.new()
        for _, actionConfig in ipairs(randoms) do
            local name, probability = actionConfig[1], actionConfig[2]
            local state = yo.ini.state[name](self)
            self.random_states:add_objects(state, probability)
        end
    end
    -- 载入周期状态
    local period = config.period_states
    if period then
        self.period_states = {}
        for _, actionConfig in ipairs(period) do
            local name, target = actionConfig[1], actionConfig[2]
            local state = yo.ini.state[name](self)
            local track = yo.track.new_float(target / self._loop_div)
            function track:on_trigger() state:enter() end
            table.insert(self.period_states, track)
        end
    end
    -- 载入事件状态
    local event = config.event_states
    if event then
        self.event_states = {}
        for _, stateName in ipairs(event) do
            local state = yo.ini.state[stateName](self)
            table.insert(self.event_states, state)
        end

    end
end

-- 获得单位计时器
function mt:get_timer()
    if not self._timer then self._timer = yo.timer.new(yo.timer.realTimer) end
    return self._timer
end

-- 开始AI逻辑
function mt:start()
    self:get_timer():loop(game.FRAME * 1000, function()

        -- 检查是否占用
        if self._state then
            print("占用中")
            return
        end

        -- 周期动作帧更新
        if self.period_states then
            for index, track in ipairs(self.period_states) do
                track:add(self._owner:get_timeScale() * game.FRAME)
            end
        end
        -- 随机动作帧更新

        if self.random_states then
            -- 等待中不执行任何事情
            if self._random_waiting then return end

            -- 随机数小于行为意愿，不作为
            if math.random() < self._random_willing then
                -- 设定等待并在延迟后结束等待
                self._random_waiting = true
                self:get_timer():wait(self._random_interval * 1000, function()
                    self._random_waiting = false
                end)
                return
            end

            -- 决定要做事了
            local _state = self.random_states:get()
            _state:enter()
        end

    end)

end

return ai
