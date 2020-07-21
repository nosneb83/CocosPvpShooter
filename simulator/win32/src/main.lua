
cc.FileUtils:getInstance():setPopupNotify(false)
cc.FileUtils:getInstance():addSearchPath("src/")
cc.FileUtils:getInstance():addSearchPath("res/")

-- require("LuaDebug")("localhost",7003)
require "config"
require "cocos.init"

local function main()
    require("app.MyApp"):create():run()
end

local status, msg = xpcall(main, __G__TRACKBACK__)
if not status then
    print(msg)
end

local breakInfoFun,xpCallFun
if os.platform == "windows" then
    breakInfoFun,xpCallFun =  require("LuaDebug")("localhost",7003)
    cc.Director:getInstance():getScheduler():scheduleScriptFunc(breakInfoFun, 0.5, false)
    cc.FileUtils:getInstance():setPopupNotify(false)
end