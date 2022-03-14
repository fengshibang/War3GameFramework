local circle = require "base.abstract.circle"
local point = require "base.abstract.point"
local rect = require "base.abstract.rect"
local region = require "base.abstract.region"

local battle = require "base.system.battle"
local event = require "base.system.event"
local input = require "base.system.input"
local mover = require "base.system.mover"
local timer = require "base.system.timer"
local state = require "system.behaviour_tree.state"

local struct = require "base.define.struct"

local hot_fix = require "base.tools.hot_fix"
local log = require "base.tools.log"
local math = require "base.tools.math"
local pool = require "base.tools.pool"
local rsa = require "base.tools.rsa"
local selector = require "base.tools.selector"
local thread = require "base.tools.thread"
local track = require "base.tools.track"
local war3 = require "base.tools.war3"

local ability = require "base.types.ability"
local buff = require "base.types.buff"
local fog = require "base.types.fogmodifier"
local item = require "base.types.item"
local move = require "base.types.move"
local multiboard = require "base.types.multiboard"
local player = require "base.types.player"
local sound = require "base.types.sound"
local sync = require "base.types.sync"
local texttag = require "base.types.texttag"
local unit = require "base.types.unit"

local objmanager = require "config.objmanager"

yo = {}
yo.circle = circle
yo.point = point
yo.rect = rect
yo.region = region

yo.struct = struct

yo.battle = battle
yo.event = event
yo.input = input
yo.mover = mover
yo.pool = pool
yo.timer = timer
yo.state = state

yo.hot_fix = hot_fix
yo.log = log
yo.math = math
yo.rsa = rsa
yo.selector = selector
yo.thread = thread
yo.track = track
yo.war3 = war3

yo.ability = ability
yo.buff = buff
yo.fog = fog
yo.item = item
yo.move = move
yo.multiboard = multiboard
yo.player = player
yo.sound = sound
yo.sync = sync
yo.texttag = texttag
yo.unit = unit

yo.objmanager = objmanager
yo.hero_button = require "config.button"

-- 读取配置信息
yo.ini = {}
require "config.config_loader"

-- 加载unit的属性模块
require "base.types.attribute"


point.init()
rect.init()
war3.init()
player.init()
input.init()
ability.init()
item.init()
move.init()
texttag.init()
objmanager.init()

