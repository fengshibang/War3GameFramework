yo.ini.ability["折叠「火同眼剑」"] = function(str_id)

    local mt = yo.ability.new(str_id)
    -- 基础信息
    mt._name = "折叠「火同眼剑」"
    mt.level = 1
    mt._level = 10
    mt._cost_mana = 0
    mt._charge = 3
    mt._radius = 300
    mt._cool_frame = 3000
    mt._tip =
        [[进入%__block_time%s的招架状态，若在此期间受到%block_type%伤害，则对攻击目标造成%__damage_value%点%damage_type%伤害。若在%perfect_time%s内招架成功，伤害增至%__perfect_damage%点。]]
    -- mt._target_type = yo.ability.TARGET_TYPE_POINT

    -- 招架时间与招架类型
    mt.perfect_time = 0.15
    mt.perfect_rate = 5

    -- 定义伤害
    mt.damage_type = "物理"
    mt.isAddtion = false
    mt.damage_type = mt.damage_type .. (mt.isAddtion == true and "追击" or "")

    local block_type = {"物理", "元素-火", "元素-冰", "元素-雷"}
    mt.block_type = "[" .. table.concat(block_type, "、") .. "]"

    -- 用于计算才能得到的东西
    function mt:on_fresh()

        -- 计算招架时间
        mt.__block_time = 0.3 + 0.02 * mt._level

        -- 计算伤害
        mt.__damage_value = (3 + 1.2 * mt._level) * mt._owner:get("攻击力")

        -- 计算完美伤害
        mt.__perfect_damage = mt.__damage_value * mt.perfect_rate

    end

    function mt:on_cast()

        -- #region 定义buff

        local block = yo.buff.new("招架-折叠")
        local attack = yo.buff.new("反击-折叠")

        block.action = function(data)

            if not self.block_type:find(data.damageType) then return end
            if not (data.defencer == block._attach) then return end

            data.valid = false

            local time_diff = yo.timer.realTimer:clock() - block.addTime
            if time_diff < mt.perfect_time * 1000 then
                block._attach._owner:sendMsg(
                    ('[%.3f]'):format(os.clock()) .. "完美反击")
                attack.plus_rate = mt.perfect_rate
            else
                attack.plus_rate = 1
                block._attach._owner:sendMsg(
                    ('[%.3f]'):format(os.clock()) .. "反击成功")
            end
            data.defencer:remove_buff(block)
            data.defencer:add_buff(attack)
            attack:start()
        end

        function block:on_add()
            yo.event:add(yo.event.E_Damage.damageAwake, self.action)
        end

        function block:on_remove()
            yo.event:remove(yo.event.E_Damage.damageAwake, self.action)
        end

        attack.action = function(data)
            if (data.defencer == attack._attach) then
                local damage = setmetatable({}, yo.struct.damage)
                damage.damageType = mt.damage_type
                damage.attacker = data.defencer
                damage.defencer = data.attacker
                damage.value = mt.__damage_value * attack.plus_rate

                yo.battle.doDamage(damage)
            end
        end

        function attack:on_add()
            yo.event:add(yo.event.E_Damage.damageFinish, self.action)
        end

        function attack:on_remove()
            yo.event:remove(yo.event.E_Damage.damageFinish, self.action)
        end

        -- #endregion

        self._owner:add_buff(block)
        block:start()
        block.addTime = yo.timer.realTimer:clock()
        yo.timer.realTimer:wait(self.__block_time * 1000, function()
            if self._owner:get_buff(block._name) then
                block._attach._owner:sendMsg(
                    ('[%.3f]'):format(os.clock()) .. "反击失败")
            end

            self._owner:remove_buff(block)
        end)

    end

    return mt
end
