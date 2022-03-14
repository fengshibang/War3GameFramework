local jass = require "jass.common"

local std_print = print
function print(...) std_print(('[%.3f]'):format(os.clock()), ...) end

local function main()

    -- 全局快捷方式
    require "shortcut"

    -- 重新生成物编(成品在魔兽根目录，替换工程同名文件重新打包后生效)
    -- yo.objmanager.fresh()

    -- -- 0显示英雄头像，1隐藏英雄头像
    -- japi.EXSetUnitInteger(war3.string2id("H000"), 47, 0)
end

main()

yo.player.get(2):set_alliance_simple(yo.player.get(1), false)
local u = yo.unit.new(yo.player.get(1), "幽人的庭师"):as_hero()

u:add_ability("天赋被动", "P")
u:add_ability("折叠「火同眼剑」", "Q")
u:add_ability("断命剑「冥想斩」", "W")



local boss = yo.unit.new(yo.player.get(2), "熊王"):as_hero()
local ai = boss:get_AI()
ai:load_states()
ai:start()

-- -- u:remove()
-- yo.ini.item["兽王之鼓"]()

-- local enemy = {}

-- for i = 1, 10, 1 do
--     local u = yo.unit.new(yo.player.get(2), "幽人的庭师")
--     u:set_center(800, 100)
--     table.insert(enemy, u)
-- end
-- local state = yo.ini.state["天崩地裂"]()
-- yo.event:add(yo.event.E_Player.key_click,
--              function(_keychar) if _keychar == "A" then state:enter(u) end end)
-- print(#nil)
