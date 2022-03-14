local track = {}

local mt_float = {_target = 0, _now = 0}
mt_float.__index = mt_float

function mt_float:reset() self._now = 0 end

function mt_float:add(_float)
    self._now = self._now + _float
    if self._now >= self._target then
        self:on_trigger()
        self:reset()
    end
end

function mt_float:on_trigger() end

local mt_char = {_target = nil, _now = nil, _targetLen = 0}
mt_char.__index = mt_char

function mt_char:reset()
    for i = #self._now + 1, 1, -1 do table.remove(self._now, i) end
end

function mt_char:add(_char)
    if self._target[#self._now + 1] == _char then
        table.insert(self._now, _char)
        if #self._now == self._targetLen then
            self:on_trigger()
            self:reset()
        end
    else
        self:reset()
    end
end

function mt_char:on_trigger() end

function track.new_float(target)
    return setmetatable({_target = target}, mt_float)
end

function track.new_char(queue)
    return setmetatable({_target = queue, _now = {}, _targetLen = #queue},
                        mt_char)
end


return track
