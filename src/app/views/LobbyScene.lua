local LobbyScene = class("LobbyScene", function()
    return cc.Scene:create()
end)

local rootNode
local readyButton

function LobbyScene:ctor()
    rootNode = cc.CSLoader:createNode("LobbyScene.csb")
    self:addChild(rootNode)
    readyButton = rootNode:getChildByName("ReadyButton")
    readyButton:addTouchEventListener(self.ready)
end

function LobbyScene:ready(type)
    if type == ccui.TouchEventType.ended then
        print("into battle !!")
        local scene = require("app/views/BattleScene.lua"):create()
        cc.Director:getInstance():replaceScene(scene)
    end
end

return LobbyScene