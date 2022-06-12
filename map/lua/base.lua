local runtime	= require 'jass.runtime'
local console	= require 'jass.console'
	

game = {}


--判断是否是发布版本
game.release = not pcall(require, 'lua.currentpath')

--版本号
game.VERSION = '1.0'

-- 帧速
game.FRAME = 0.03

--打开控制台
if not game.release then
	console.enable = true
end

--重载print,自动转换编码
print = console.write

--将句柄等级设置为0(地图中所有的句柄均使用table封装)
runtime.handle_level = 0

--关闭等待
runtime.sleep = false

function game.error_handle(msg)
	print("---------------------------------------")
	print(tostring(msg) .. "\n")
	print(debug.traceback())
	print("---------------------------------------")
end

--错误汇报
function runtime.error_handle(msg)
	game.error_handle(msg)
end


--测试版本和发布版本的脚本路径
if game.release then
	package.path = package.path .. [[;Poi\]] .. game.version .. [[\?.lua;scripts\?.lua]]
end

if not game.release then
	--调试器端口
	runtime.debugger = 4279
end

-- 初始化本地脚本
local function init()
	require 'main'
end

xpcall(init , function(msg)
	 print(msg, '\n', debug.traceback()) 
	end)