local MainScene = class("MainScene", cc.load("mvc").ViewBase)
local rootNode
local loginButton
function MainScene:onCreate()
    rootNode = cc.CSLoader:createNode("MainScene.csb")
    self:addChild(rootNode)
    loginButton = rootNode:getChildByName("LoginButton")
    loginButton:addTouchEventListener(self.login)
end
function MainScene:login(type)
    if type == ccui.TouchEventType.ended then
        print("into battle !!")
        local scene = require("app/views/BattleScene.lua")
        local gameScene = scene:create()
        -- 當前場景是否正在運行
        if cc.Director:getInstance():getRunningScene() then
            cc.Director:getInstance():replaceScene(gameScene)
        else
            cc.Director:getInstance():runWithScene(gameScene)
        end
    end
end
return MainScene