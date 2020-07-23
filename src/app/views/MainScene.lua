local MainScene = class("MainScene", cc.load("mvc").ViewBase)

local rootNode
local panel

function MainScene:onCreate()
    rootNode = cc.CSLoader:createNode("MainScene.csb")
    self:addChild(rootNode)
    panel = rootNode:getChildByName("TransparentPanel")
    panel:addTouchEventListener(self.enterLobby)
end

function MainScene:enterLobby(type)
    if type == ccui.TouchEventType.ended then
        print("into lobby !!")
        local scene = require("app/views/LobbyScene.lua"):create()
        -- 淡入過場
        cc.Director:getInstance():replaceScene(cc.TransitionFade:create(1, scene))
    end
end

-- 限制某數的範圍
function math.clamp(value, min, max)
    return math.min(math.max(value, min), max)
end

return MainScene