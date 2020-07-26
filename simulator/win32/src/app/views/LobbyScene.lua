local LobbyScene = class("LobbyScene", function()
    return cc.Scene:create()
end)

socket = require("LuaTcpSocket"):new():init()
require("json")
math.randomseed(os.time())
playerID = 0
local rootNode
local chooseHeroA, hightlightA
local chooseHeroB, hightlightB
local chooseHeroC, hightlightC
local randomHero, hightlightR, randomHeroCallback
local currentHeroChoice = 0
local nameInput, nameForeground
local readyButton
local readyList, readyListItemPrefab
local countdown3, countdown2, countdown1

function LobbyScene:ctor()
    -- 繪製Scene
    rootNode = cc.CSLoader:createNode("LobbyScene.csb")
    self:addChild(rootNode)

    chooseHeroA = rootNode:getChildByName("ChooseHero"):getChildByName("HeroA")
    hightlightA = rootNode:getChildByName("ChooseHero"):getChildByName("HightlightA")
    chooseHeroB = rootNode:getChildByName("ChooseHero"):getChildByName("HeroB")
    hightlightB = rootNode:getChildByName("ChooseHero"):getChildByName("HightlightB")
    chooseHeroC = rootNode:getChildByName("ChooseHero"):getChildByName("HeroC")
    hightlightC = rootNode:getChildByName("ChooseHero"):getChildByName("HightlightC")
    randomHero = rootNode:getChildByName("ChooseHero"):getChildByName("Random")
    hightlightR = rootNode:getChildByName("ChooseHero"):getChildByName("HightlightR")
    chooseHeroA:addTouchEventListener(self.chooseHeroA)
    chooseHeroB:addTouchEventListener(self.chooseHeroB)
    chooseHeroC:addTouchEventListener(self.chooseHeroC)
    randomHeroCallback = self.randomHero
    randomHero:addTouchEventListener(randomHeroCallback)

    nameInput = rootNode:getChildByName("PlayerNameInput"):getChildByName("Input")
    nameForeground = rootNode:getChildByName("PlayerNameInput"):getChildByName("Foreground")

    readyButton = rootNode:getChildByName("ReadyButton")
    readyButton:addTouchEventListener(self.ready)

    readyList = rootNode:getChildByName("ReadyPlayerList"):getChildByName("List")
    readyListItemPrefab = rootNode:getChildByName("ReadyPlayer")

    countdown3 = rootNode:getChildByName("Countdown_3")
    countdown2 = rootNode:getChildByName("Countdown_2")
    countdown1 = rootNode:getChildByName("Countdown_1")

    -- BGM
    cc.SimpleAudioEngine:getInstance():playMusic("bgm/LobbyBgm.mp3", true)

    -- socket連線
    local function ReceiveCallback(msg)
        -- 把每個{}分割開
        local opStrs = string.splitAfter(msg, "}")
        table.remove(opStrs, #opStrs)
        -- 一個一個輪流decode
        for i = 1, #opStrs do
            local jsonObj = json.decode(opStrs[i])
            self:handleOp(jsonObj)
        end
    end
    socket:setReceiveCallback(ReceiveCallback)
    socket:connect("127.0.0.1", "8888")
end

-- 選擇英雄
function LobbyScene:chooseHeroA()
    currentHeroChoice = 1
    hightlightA:setVisible(true)
    hightlightB:setVisible(false)
    hightlightC:setVisible(false)
    hightlightR:setVisible(false)
end
function LobbyScene:chooseHeroB()
    currentHeroChoice = 2
    hightlightA:setVisible(false)
    hightlightB:setVisible(true)
    hightlightC:setVisible(false)
    hightlightR:setVisible(false)
end
function LobbyScene:chooseHeroC()
    currentHeroChoice = 3
    hightlightA:setVisible(false)
    hightlightB:setVisible(false)
    hightlightC:setVisible(true)
    hightlightR:setVisible(false)
end
function LobbyScene:randomHero()
    currentHeroChoice = math.random(3)
    hightlightA:setVisible(false)
    hightlightB:setVisible(false)
    hightlightC:setVisible(false)
    hightlightR:setVisible(true)
end

-- 玩家準備就緒
function LobbyScene:ready(type)
    if type == ccui.TouchEventType.ended then
        -- 如果沒選英雄就幫他選 沒打名字就Nobody
        if currentHeroChoice == 0 then randomHeroCallback() end
        if nameInput:getString() == "" then nameInput:setString("Nobody") end

        -- 取消UI互動
        chooseHeroA:setEnabled(false)
        chooseHeroB:setEnabled(false)
        chooseHeroC:setEnabled(false)
        randomHero:setEnabled(false)
        nameInput:setEnabled(false)
        nameForeground:setVisible(true)
        readyButton:setEnabled(false)

        -- 通知server創角
        local jsonObj = {
            op = "CREATE_PLAYER",
            playerName = nameInput:getString(),
            heroType = currentHeroChoice
        }
        socket:send(json.encode(jsonObj))
    end
end

-- 倒數
function LobbyScene:countDown()
    -- 數字
    local fadeIn = cc.FadeIn:create(0.3)
    local scaleTo = cc.ScaleTo:create(0.3, 1)
    local fadeOut = cc.FadeOut:create(0)
    local count = cc.Sequence:create(cc.Spawn:create(fadeIn, scaleTo),
    cc.DelayTime:create(0.5), fadeOut)

    -- 切換場景
    local function battleStart()
        -- print("into battle !!")
        local scene = require("app/views/BattleScene.lua"):create()
        cc.Director:getInstance():replaceScene(scene)
    end
    local battle = cc.CallFunc:create(battleStart)

    -- 執行動作
    countdown3:runAction(count)
    countdown2:runAction(cc.Sequence:create(cc.DelayTime:create(1), count))
    countdown1:runAction(cc.Sequence:create(cc.DelayTime:create(2), count,
    cc.DelayTime:create(0.2), battle))

    -- 播音效
    local function countSound()
        cc.SimpleAudioEngine:getInstance():playEffect("sound/export.mp3")
    end
    local sound = cc.CallFunc:create(countSound)
    self:runAction(cc.Sequence:create(cc.DelayTime:create(0.1), sound))
end

-- 處理server傳來的指令
function LobbyScene:handleOp(jsonObj)
    -- 把jsonObj印出來看
    dump(jsonObj)
    -- 處理指令
    local op = jsonObj["op"]
    if op == "ASSIGN_ID" then
        playerID = jsonObj["playerID"]
        print("set id = " .. playerID)
    elseif op == "CREATE_PLAYER" then
        local item = readyListItemPrefab:clone()
        item:getChildByName("PlayerName"):setString(jsonObj["playerName"])
        readyList:pushBackCustomItem(item)
    elseif op == "BATTLE_START" then
        -- print("into battle !!")
        self:countDown()
        -- local scene = require("app/views/BattleScene.lua"):create()
        -- cc.Director:getInstance():replaceScene(scene)
    end
end

return LobbyScene