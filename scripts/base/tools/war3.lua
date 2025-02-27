local jass = require 'jass.common'
local debug = require 'jass.debug'

local war3 = {}

war3.order2id = {
    smart = 0xD0003,
    stop = 0xD0004,
    setrally = 0xD000C,
    getitem = 0xD000D,
    attack = 0xD000F,
    attackground = 0xD0010,
    attackonce = 0xD0011,
    move = 0xD0012,
    AImove = 0xD0014,
    patrol = 0xD0016,
    holdposition = 0xD0019,
    build = 0xD001A,
    humanbuild = 0xD001B,
    orcbuild = 0xD001C,
    nightelfbuild = 0xD001D,
    undeadbuild = 0xD001E,
    resumebuild = 0xD001F,
    dropitem = 0xD0021,
    detectaoe = 0xD002F,
    resumeharvesting = 0xD0031,
    harvest = 0xD0032,
    returnresources = 0xD0034,
    autoharvestgold = 0xD0035,
    autoharvestlumber = 0xD0036,
    neutraldetectaoe = 0xD0037,
    repair = 0xD0038,
    repairon = 0xD0039,
    repairoff = 0xD003A,
    revive = 0xD0047,
    selfdestruct = 0xD0048,
    selfdestructon = 0xD0049,
    selfdestructoff = 0xD004A,
    board = 0xD004B,
    forceboard = 0xD004C,
    load = 0xD004E,
    unload = 0xD004F,
    unloadall = 0xD0050,
    unloadallinstant = 0xD0051,
    loadcorpse = 0xD0052,
    loadcorpseinstant = 0xD0055,
    unloadallcorpses = 0xD0056,
    defend = 0xD0057,
    undefend = 0xD0058,
    dispel = 0xD0059,
    flare = 0xD005C,
    heal = 0xD005F,
    healon = 0xD0060,
    healoff = 0xD0061,
    innerfire = 0xD0062,
    innerfireon = 0xD0063,
    innerfireoff = 0xD0064,
    invisibility = 0xD0065,
    militiaconvert = 0xD0067,
    militia = 0xD0068,
    militiaoff = 0xD0069,
    polymorph = 0xD006A,
    slow = 0xD006B,
    slowon = 0xD006C,
    slowoff = 0xD006D,
    tankdroppilot = 0xD006F,
    tankloadpilot = 0xD0070,
    tankpilot = 0xD0071,
    townbellon = 0xD0072,
    townbelloff = 0xD0073,
    avatar = 0xD0076,
    unavatar = 0xD0077,
    blizzard = 0xD0079,
    divineshield = 0xD007A,
    undivineshield = 0xD007B,
    holybolt = 0xD007C,
    massteleport = 0xD007D,
    resurrection = 0xD007E,
    thunderbolt = 0xD007F,
    thunderclap = 0xD0080,
    waterelemental = 0xD0081,
    battlestations = 0xD0083,
    berserk = 0xD0084,
    bloodlust = 0xD0085,
    bloodluston = 0xD0086,
    bloodlustoff = 0xD0087,
    devour = 0xD0088,
    evileye = 0xD0089,
    ensnare = 0xD008A,
    ensnareon = 0xD008B,
    ensnareoff = 0xD008C,
    healingward = 0xD008D,
    lightningshield = 0xD008E,
    purge = 0xD008F,
    standdown = 0xD0091,
    stasistrap = 0xD0092,
    chainlightning = 0xD0097,
    earthquake = 0xD0099,
    farsight = 0xD009A,
    mirrorimage = 0xD009B,
    shockwave = 0xD009D,
    spiritwolf = 0xD009E,
    stomp = 0xD009F,
    whirlwind = 0xD00A0,
    windwalk = 0xD00A1,
    unwindwalk = 0xD00A2,
    ambush = 0xD00A3,
    autodispel = 0xD00A4,
    autodispelon = 0xD00A5,
    autodispeloff = 0xD00A6,
    barkskin = 0xD00A7,
    barkskinon = 0xD00A8,
    barkskinoff = 0xD00A9,
    bearform = 0xD00AA,
    unbearform = 0xD00AB,
    corrosivebreath = 0xD00AC,
    loadarcher = 0xD00AE,
    mounthippogryph = 0xD00AF,
    cyclone = 0xD00B0,
    detonate = 0xD00B1,
    eattree = 0xD00B2,
    entangle = 0xD00B3,
    entangleinstant = 0xD00B4,
    faeriefire = 0xD00B5,
    faeriefireon = 0xD00B6,
    faeriefireoff = 0xD00B7,
    ravenform = 0xD00BB,
    unravenform = 0xD00BC,
    recharge = 0xD00BD,
    rechargeon = 0xD00BE,
    rechargeoff = 0xD00BF,
    rejuvination = 0xD00C0,
    renew = 0xD00C1,
    renewon = 0xD00C2,
    renewoff = 0xD00C3,
    roar = 0xD00C4,
    root = 0xD00C5,
    unroot = 0xD00C6,
    entanglingroots = 0xD00CB,
    flamingarrowstarg = 0xD00CD,
    flamingarrows = 0xD00CE,
    unflamingarrows = 0xD00CF,
    forceofnature = 0xD00D0,
    immolation = 0xD00D1,
    unimmolation = 0xD00D2,
    manaburn = 0xD00D3,
    metamorphosis = 0xD00D4,
    scout = 0xD00D5,
    sentinel = 0xD00D6,
    starfall = 0xD00D7,
    tranquility = 0xD00D8,
    acolyteharvest = 0xD00D9,
    antimagicshell = 0xD00DA,
    blight = 0xD00DB,
    cannibalize = 0xD00DC,
    cripple = 0xD00DD,
    curse = 0xD00DE,
    curseon = 0xD00DF,
    curseoff = 0xD00E0,
    freezingbreath = 0xD00E3,
    possession = 0xD00E4,
    raisedead = 0xD00E5,
    raisedeadon = 0xD00E6,
    raisedeadoff = 0xD00E7,
    instant = 0xD00E8,
    requestsacrifice = 0xD00E9,
    restoration = 0xD00EA,
    restorationon = 0xD00EB,
    restorationoff = 0xD00EC,
    sacrifice = 0xD00ED,
    stoneform = 0xD00EE,
    unstoneform = 0xD00EF,
    unholyfrenzy = 0xD00F1,
    unsummon = 0xD00F2,
    web = 0xD00F3,
    webon = 0xD00F4,
    weboff = 0xD00F5,
    wispharvest = 0xD00F6,
    auraunholy = 0xD00F7,
    auravampiric = 0xD00F8,
    animatedead = 0xD00F9,
    carrionswarm = 0xD00FA,
    darkritual = 0xD00FB,
    darksummoning = 0xD00FC,
    deathanddecay = 0xD00FD,
    deathcoil = 0xD00FE,
    deathpact = 0xD00FF,
    dreadlordinferno = 0xD0100,
    frostarmor = 0xD0101,
    frostnova = 0xD0102,
    sleep = 0xD0103,
    darkconversion = 0xD0104,
    darkportal = 0xD0105,
    fingerofdeath = 0xD0106,
    firebolt = 0xD0107,
    inferno = 0xD0108,
    gold2lumber = 0xD0109,
    lumber2gold = 0xD010A,
    spies = 0xD010B,
    rainofchaos = 0xD010D,
    rainoffire = 0xD010E,
    request_hero = 0xD010F,
    disassociate = 0xD0110,
    revenge = 0xD0111,
    soulpreservation = 0xD0112,
    coldarrowstarg = 0xD0113,
    coldarrows = 0xD0114,
    uncoldarrows = 0xD0115,
    creepanimatedead = 0xD0116,
    creepdevour = 0xD0117,
    creepheal = 0xD0118,
    creephealon = 0xD0119,
    creephealoff = 0xD011A,
    creepthunderbolt = 0xD011C,
    creepthunderclap = 0xD011D,
    poisonarrowstarg = 0xD011E,
    poisonarrows = 0xD011F,
    unpoisonarrows = 0xD0120,
    frostarmoron = 0xD01EA,
    frostarmoroff = 0xD01EB,
    awaken = 0xD01F2,
    nagabuild = 0xD01F3,
    mount = 0xD01F5,
    dismount = 0xD01F6,
    cloudoffog = 0xD01F9,
    controlmagic = 0xD01FA,
    magicdefense = 0xD01FE,
    magicundefense = 0xD01FF,
    magicleash = 0xD0200,
    phoenixfire = 0xD0201,
    phoenixmorph = 0xD0202,
    spellsteal = 0xD0203,
    spellstealon = 0xD0204,
    spellstealoff = 0xD0205,
    banish = 0xD0206,
    drain = 0xD0207,
    flamestrike = 0xD0208,
    summonphoenix = 0xD0209,
    ancestralspirit = 0xD020A,
    ancestralspirittarget = 0xD020B,
    corporealform = 0xD020D,
    uncorporealform = 0xD020E,
    disenchant = 0xD020F,
    etherealform = 0xD0210,
    unetherealform = 0xD0211,
    spiritlink = 0xD0213,
    unstableconcoction = 0xD0214,
    healingwave = 0xD0215,
    hex = 0xD0216,
    voodoo = 0xD0217,
    ward = 0xD0218,
    autoentangle = 0xD0219,
    autoentangleinstant = 0xD021A,
    coupletarget = 0xD021B,
    coupleinstant = 0xD021C,
    decouple = 0xD021D,
    grabtree = 0xD021F,
    manaflareon = 0xD0220,
    manaflareoff = 0xD0221,
    phaseshift = 0xD0222,
    phaseshifton = 0xD0223,
    phaseshiftoff = 0xD0224,
    phaseshiftinstant = 0xD0225,
    taunt = 0xD0228,
    vengeance = 0xD0229,
    vengeanceon = 0xD022A,
    vengeanceoff = 0xD022B,
    vengeanceinstant = 0xD022C,
    blink = 0xD022D,
    fanofknives = 0xD022E,
    shadowstrike = 0xD022F,
    spiritofvengeance = 0xD0230,
    absorb = 0xD0231,
    avengerform = 0xD0233,
    unavengerform = 0xD0234,
    burrow = 0xD0235,
    unburrow = 0xD0236,
    devourmagic = 0xD0238,
    flamingattacktarg = 0xD023B,
    flamingattack = 0xD023C,
    unflamingattack = 0xD023D,
    replenish = 0xD023E,
    replenishon = 0xD023F,
    replenishoff = 0xD0240,
    replenishlife = 0xD0241,
    replenishlifeon = 0xD0242,
    replenishlifeoff = 0xD0243,
    replenishmana = 0xD0244,
    replenishmanaon = 0xD0245,
    replenishmanaoff = 0xD0246,
    carrionscarabs = 0xD0247,
    carrionscarabson = 0xD0248,
    carrionscarabsoff = 0xD0249,
    carrionscarabsinstant = 0xD024A,
    impale = 0xD024B,
    locustswarm = 0xD024C,
    breathoffrost = 0xD0250,
    frenzy = 0xD0251,
    frenzyon = 0xD0252,
    frenzyoff = 0xD0253,
    mechanicalcritter = 0xD0254,
    mindrot = 0xD0255,
    neutralinteract = 0xD0256,
    preservation = 0xD0258,
    sanctuary = 0xD0259,
    shadowsight = 0xD025A,
    spellshield = 0xD025B,
    spellshieldaoe = 0xD025C,
    spirittroll = 0xD025D,
    steal = 0xD025E,
    attributemodskill = 0xD0260,
    blackarrow = 0xD0261,
    blackarrowon = 0xD0262,
    blackarrowoff = 0xD0263,
    breathoffire = 0xD0264,
    charm = 0xD0265,
    doom = 0xD0267,
    drunkenhaze = 0xD0269,
    elementalfury = 0xD026A,
    forkedlightning = 0xD026B,
    howlofterror = 0xD026C,
    manashieldon = 0xD026D,
    manashieldoff = 0xD026E,
    monsoon = 0xD026F,
    silence = 0xD0270,
    stampede = 0xD0271,
    summongrizzly = 0xD0272,
    summonquillbeast = 0xD0273,
    summonwareagle = 0xD0274,
    tornado = 0xD0275,
    wateryminion = 0xD0276,
    battleroar = 0xD0277,
    channel = 0xD0278,
    parasite = 0xD0279,
    parasiteon = 0xD027A,
    parasiteoff = 0xD027B,
    submerge = 0xD027C,
    unsubmerge = 0xD027D,
    neutralspell = 0xD0296,
    militiaunconvert = 0xD02AB,
    clusterrockets = 0xD02AC,
    robogoblin = 0xD02B0,
    unrobogoblin = 0xD02B1,
    summonfactory = 0xD02B2,
    acidbomb = 0xD02B6,
    chemicalrage = 0xD02B7,
    healingspray = 0xD02B8,
    transmute = 0xD02B9,
    lavamonster = 0xD02BB,
    soulburn = 0xD02BC,
    volcano = 0xD02BD,
    incineratearrow = 0xD02BE,
    incineratearrowon = 0xD02BF,
    incineratearrowoff = 0xD02C0
}

function war3.init()
    war3.id2order = {}
    local index = 1
    for key, value in pairs(war3.order2id) do
        war3.id2order[index] = key
        index = index + 1
    end
end

-- #region  转换256进制整数

local ids1 = {}
local ids2 = {}

local function id_encode(a)
    local r = ('>I4'):pack(a)
    ids1[a] = r
    ids2[r] = a
    return r
end

local function id_decode(a)
    local r = ('>I4'):unpack(a)
    ids2[a] = r
    ids1[r] = a
    return r
end

function war3.id2string(int_id) return ids1[int_id] or id_encode(int_id) end

function war3.string2id(str_id) return ids2[str_id] or id_decode(str_id) end

-- #endregion

-- #region 触发器

function war3.CreateTrigger(call_back)
    local trg = jass.CreateTrigger()
    debug.handle_ref(trg)
    jass.TriggerAddAction(trg, call_back)
    return trg
end

function war3.DestroyTrigger(trg)
    jass.DestroyTrigger(trg)
    debug.handle_unref(trg)
end

-- #endregion

-- #region 物编ID

local function format(index)
    local chars = [[0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ]]
    local period = 36
    local t = {}
    index = index - 1

    repeat
        local mod = index % period
        index = index // period
        table.insert(t, chars:sub(mod + 1, mod + 1))
    until index < period
    table.insert(t, chars:sub(index + 1, index + 1))
    if #t < 3 then
        table.insert(t, "0")
    elseif #t > 3 then
        error("too huge index")
    end
    return string.reverse(table.concat(t))
end
-- index从1开始
function war3.ItemID(index) return "I" .. format(index) end
-- index从1开始
function war3.UnitID(index) return "H" .. format(index) end
-- index从1开始
function war3.AbilityID(index) return "A" .. format(index) end
-- index从1开始
function war3.AbilityOrder(index) return war3.id2order[index] end

-- #endregion

-- #region Lua表模块

-- 复制原表为新表格
function war3.copy_table(from, to)
    if type(from) ~= "table" then return end

    for key, value in pairs(from) do
        local value_type = type(value)

        if value_type == "table" then
            if value ~= from then
                to[key] = {}
                war3.copy_table(value, to[key])
            end
        else
            to[key] = value
        end
    end
    return to
end

-- 表序列化成lua表格式的字符串
function war3.serialize(_table)
    local function key_to_string(key)
        if type(key) == 'number' then
            return '[' .. key .. ']'
        elseif type(key) == 'string' then
            return "['" .. key .. "']"
        else
            error('错误的类型: ' .. type(key))
        end
    end

    local function value_to_string(value)
        if type(value) == 'number' then
            return value
        elseif type(value) == 'string' then
            if value:find([[\]]) then return "[[" .. value .. "]]" end
            return "'" .. value .. "'"
        elseif type(value) == 'boolean' then
            return value
        else
            error('错误的类型: ' .. type(value) .. tostring(value))
        end
    end

    local function key_value_pair(t)
        local tmp = {}
        for key, value in pairs(t) do
            local key = key_to_string(key)
            if type(value) == "table" then
                value = '{' .. key_value_pair(value) .. '}'
            else
                value = value_to_string(value)
            end
            table.insert(tmp, key .. [[=]] .. tostring(value))
        end
        return table.concat(tmp, ',')
    end

    return 'local ret ={' .. key_value_pair(_table) .. '} return ret'
end

-- #endregion

return war3
