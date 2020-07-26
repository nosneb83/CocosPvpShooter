local BattleScene = class("BattleScene", function()
    return cc.Scene:createWithPhysics()
end)

require("json")
require("Player")

-- 邏輯標籤
GroundTag = 1000
PlayerTag = 1001
EnemyTag = 1002

-- 物理 Bitmask
GroundBitmask = bit.lshift(1, 0)
CharBitmask = bit.lshift(1, 1)
BulletBitmask = bit.lshift(1, 2)

local scheduler = cc.Director:getInstance():getScheduler()
local rootNode
local groundTilePrefab
local cam
local ninja, monster
local ninjaObj
local players = {}
local mapObjs

function BattleScene:ctor()
    -- socket連線
    local function ReceiveCallback(msg)
        print("json : " .. msg)
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

    -- 叫server傳角色資料
    local jsonObj = {
        ["op"] = "PLAYER_ENTER_BATTLE"
    }
    socket:send(json.encode(jsonObj))

    -- 繪製Scene
    rootNode = cc.CSLoader:createNode("BattleScene.csb")
    self:addChild(rootNode)

    -- 地圖
    local tilemap = cc.TMXTiledMap:create("map1.tmx")
    groundTilePrefab = rootNode:getChildByName("GroundTileBox")
    tilemap:setPosition(cc.p(-640, -360))
    self:addChild(tilemap)
    self:setGroundCollider(tilemap)
    -- 出生點
    mapObjs = tilemap:getObjectGroup("SpawnPoints"):getObjects()

    -- -- 創怪物
    -- monster = rootNode:getChildByName("Monster")
    -- monster:setTag(EnemyTag)
    -- 設定物理
    self:setPhysics()

    -- BGM
    cc.SimpleAudioEngine:getInstance():playMusic("bgm/BattleBgm.mp3", true)

    -- 監聽點擊事件
    local function touchBegan(touch, event)
        -- print("touchBegan")
        return true
    end
    local function touchMoved(touch, event)
        -- print("touchMoved")
        return false
    end
    local function touchEnded(touch, event)
        -- print("touchEnded")
        local touchWorld = cc.pScreenToWorld(cc.p(touch:getLocation().x, touch:getLocation().y), self:getDefaultCamera())
        local jsonObj = {
            ["playerID"] = playerID,
            inputType = "shoot",
            -- x = touch:getLocation()["x"],
            -- y = touch:getLocation()["y"]
            x = touchWorld.x,
            y = touchWorld.y
        }
        socket:send(json.encode(jsonObj))
        return true
    end
    local function touchCanceled(touch, event)
        -- print("touchCanceled")
        return false
    end
    local listen = cc.EventListenerTouchOneByOne:create()
    listen:registerScriptHandler(touchBegan, cc.Handler.EVENT_TOUCH_BEGAN)
    listen:registerScriptHandler(touchMoved, cc.Handler.EVENT_TOUCH_MOVED)
    listen:registerScriptHandler(touchEnded, cc.Handler.EVENT_TOUCH_ENDED)
    listen:registerScriptHandler(touchCanceled, cc.Handler.EVENT_TOUCH_CANCELLED)
    local eventDispatcher = cc.Director:getInstance():getEventDispatcher()
    eventDispatcher:addEventListenerWithSceneGraphPriority(listen, self)

    -- 監聽鍵盤事件
    local function onKeyPressed(keyCode, event)
        local jsonObj = {
            ["playerID"] = playerID
        }
        if keyCode == cc.KeyCode.KEY_A then
            jsonObj["inputType"] = "walk"
            jsonObj["walkDir"] = -1
        elseif keyCode == cc.KeyCode.KEY_D then
            jsonObj["inputType"] = "walk"
            jsonObj["walkDir"] = 1
        elseif keyCode == cc.KeyCode.KEY_W then
            jsonObj["inputType"] = "jump"
        else return end
        socket:send(json.encode(jsonObj))
    end
    local function onKeyReleased(keyCode, event)
        local jsonObj = {
            ["playerID"] = playerID
        }
        if keyCode == cc.KeyCode.KEY_A then
            jsonObj["inputType"] = "walk"
            jsonObj["walkDir"] = 1
        elseif keyCode == cc.KeyCode.KEY_D then
            jsonObj["inputType"] = "walk"
            jsonObj["walkDir"] = -1
        else return end
        socket:send(json.encode(jsonObj))
    end
    listen = cc.EventListenerKeyboard:create()
    listen:registerScriptHandler(onKeyPressed, cc.Handler.EVENT_KEYBOARD_PRESSED)
    listen:registerScriptHandler(onKeyReleased, cc.Handler.EVENT_KEYBOARD_RELEASED)
    eventDispatcher:addEventListenerWithSceneGraphPriority(listen, self)
end

-- 物理設定
function BattleScene:setPhysics()
    -- 世界大小
    self.visibleSize = cc.Director:getInstance():getVisibleSize()

    -- 關閉自動同步
    local function update(delta)
        self:getPhysicsWorld():step(1 / 180)
    end
    self:getPhysicsWorld():setAutoStep(false)
    self:scheduleUpdateWithPriorityLua(update, 0)

    -- 設定重力
    local gravity = cc.p(0, -120000)
    self:getPhysicsWorld():setGravity(gravity)

    -- 物理世界 Debug Mode 開啟(DEBUGDRAW_ALL)/關閉(DEBUGDRAW_NONE)
    self:getPhysicsWorld():setDebugDrawMask(cc.PhysicsWorld.DEBUGDRAW_NONE)

    -- -- 怪物剛體設定
    -- local monsterRigidBody = cc.PhysicsBody:createBox(monster:getContentSize(), cc.PhysicsMaterial(1, 0, 0))
    -- monsterRigidBody:setGravityEnable(false)
    -- monsterRigidBody:setCollisionBitmask(0)
    -- monsterRigidBody:setCategoryBitmask(CharBitmask)
    -- monsterRigidBody:setContactTestBitmask(BulletBitmask)
    -- monster:setPhysicsBody(monsterRigidBody)
    -- -- 怪物移動
    -- local moveLeft = cc.MoveBy:create(2, cc.p(-160, 0))
    -- local moveRight = cc.MoveBy:create(2, cc.p(160, 0))
    -- monster:runAction(cc.RepeatForever:create(cc.Sequence:create(moveLeft, moveRight)))
end

-- 添加地板Collider
function BattleScene:setGroundCollider(tilemap)
    -- 取得TileMap圖層
    local tilemapSize = tilemap:getMapSize()
    local colliderLayer = tilemap:getLayer("Collider")
    colliderLayer:setVisible(false)
    local colliderRoot = cc.Node:create()
    rootNode:addChild(colliderRoot)
    -- 一格一格添加Collider
    for i = 0, tilemapSize.width - 1 do
        for j = 0, tilemapSize.height - 1 do
            if (colliderLayer:getTileAt(cc.p(i, j))) ~= nil then
                local node = groundTilePrefab:clone()
                local body = cc.PhysicsBody:createBox(node:getContentSize(), cc.PhysicsMaterial(1, 0, 0))
                body:setDynamic(false)
                body:setCategoryBitmask(GroundBitmask)
                body:setCollisionBitmask(CharBitmask)
                body:setContactTestBitmask(BulletBitmask)
                node:setPosition(cc.pTileToWorld(cc.p(i, j)))
                node:setPhysicsBody(body)
                node:setTag(GroundTag)
                colliderRoot:addChild(node)
            end
        end
    end
end

-- 轉換TileMap座標至世界座標
function cc.pTileToWorld(tileCoor)
    -- 常數
    local camOffset = cc.p(640, 360)
    local tileOffset = cc.p(20, 20)
    local tileSizePx = 40
    local worldHeight = 1440
    -- 計算過程
    local worldCoor = cc.pMul(tileCoor, tileSizePx) -- Tile座標乘上Tile大小
    worldCoor = cc.pAdd(worldCoor, tileOffset) -- 加上Tile中心點的offset
    worldCoor = cc.p(worldCoor.x, worldHeight - worldCoor.y) -- 反轉Y軸座標
    worldCoor = cc.pSub(worldCoor, camOffset) -- 減掉Camera中心點的offset
    return worldCoor
end

-- 轉換螢幕座標至世界座標
function cc.pScreenToWorld(screenCoor, cam)
    -- 常數
    local camOffset = cc.p(640, 360)
    -- 計算過程
    local camOrigin = cc.pSub(cc.p(cam:getPosition()), camOffset) -- 計算Camera原點
    local worldCoor = cc.pAdd(camOrigin, screenCoor) -- 加上螢幕座標
    return worldCoor
end

-- 處理server傳來的指令
function BattleScene:handleOp(jsonObj)
    -- dump(jsonObj)
    local op = jsonObj["op"]
    if op == "CREATE_BATTLE_CHAR" then
        local battleChar = Player:create(jsonObj["playerName"], jsonObj["playerID"], rootNode, nil, jsonObj["heroType"])
        if battleChar.playerID == playerID then
            battleChar.cam = self:getDefaultCamera()
            -- battleChar.node:setTag(PlayerTag)
        end
        local spawnPoint = mapObjs[battleChar.playerID]
        battleChar.node:setPosition(cc.p(spawnPoint.x - 640, spawnPoint.y - 360 + 30))
        players[jsonObj["playerID"]] = battleChar
        -- dump(players)
    end
    if jsonObj["inputType"] == "walk" then
        players[jsonObj["playerID"]]:walk(jsonObj["walkDir"])
    elseif jsonObj["inputType"] == "jump" then
        players[jsonObj["playerID"]]:jump()
    elseif jsonObj["inputType"] == "shoot" then
        players[jsonObj["playerID"]]:shoot(cc.p(jsonObj["x"], jsonObj["y"]))
    end
end

return BattleScene