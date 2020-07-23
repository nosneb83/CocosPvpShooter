local MainScene = class("MainScene", cc.load("mvc").ViewBase)

local rootNode
local panel

function MainScene:onCreate()
    rootNode = cc.CSLoader:createNode("MainScene.csb")
    self:addChild(rootNode)
    panel = rootNode:getChildByName("TransparentPanel")
    panel:addTouchEventListener(self.enterLobby)

    -- BGM
    cc.SimpleAudioEngine:getInstance():playMusic("bgm/StartBgm.mp3", true)
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

-- 自己實作字串分割 (相當於Golang的strings.SplitAfter)
function string.splitAfter(s, sep)
    local tab = {}
    while true do
        local n = string.find(s, sep)
        if n then
            local first = string.sub(s, 1, n)
            s = string.sub(s, n + 1, #s)
            table.insert(tab, first)
        else
            table.insert(tab, s)
            break
        end
    end
    return tab
end

return MainScene