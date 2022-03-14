local pool = {}

local mt = {type = "pool", name = "", actions = nil, rate_sum = 0}
mt.__index = mt

function mt:add_objects(objects, rate)
    local start = self.rate_sum
    self.rate_sum = self.rate_sum + rate
    local ending = self.rate_sum

    table.insert(self.actions, function(p)
        local fit = (start < p) and (p <= ending)
        if type(objects) == "table" then
            if fit then return objects[math.random(#objects)] end
        else
            if fit then return objects end
        end
    end)

    if self.rate_sum > 1 then error(self.name .. "池子总概率超过100%") end

end

function mt:get()
    if self.rate_sum < 1 then error(self.name .. "池子总概率小于100%") end
    local p = math.random()
    local actions = self.actions
    for _, action in ipairs(actions) do
        local res = action(p)
        if res then return res end
    end
end

function pool.new() return setmetatable({actions = {}}, mt) end

return pool
