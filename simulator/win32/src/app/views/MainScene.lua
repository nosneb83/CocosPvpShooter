
local MainScene = class("MainScene", cc.load("mvc").ViewBase)

local rootNode

function MainScene:onCreate()
    rootNode = cc.CSLoader:createNode("MainScene.csb")
    self:addChild(rootNode)
end

return MainScene
