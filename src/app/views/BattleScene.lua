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
local ninja, monster, bullet
local ninjaObj

function BattleScene:ctor()
    -- socket連線
    local function ReceiveCallback(msg)
        print(msg)
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

    local mapObjGroup = tilemap:getObjectGroup("SpawnPoints")

    -- 創角色
    cam = self:getDefaultCamera()
    ninjaObj = Player:create("Ninja", 0, rootNode, cam, 1)
    ninja = ninjaObj.node
    local randomSpawnPoint = mapObjGroup:getObjects()[math.random(4)]
    ninja:setPosition(cc.p(randomSpawnPoint.x - 640, randomSpawnPoint.y - 360 + 10))
    -- print("x = " .. ninja:getPositionX() .. ", y = " .. ninja:getPositionY())
    monster = rootNode:getChildByName("Monster")
    monster:setTag(EnemyTag)
    -- bullet = rootNode:getChildByName("Bullet")

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
        -- self:shoot(touch)
        local jsonObj = {
            inputType = "shoot",
            x = touch:getLocation()["x"],
            y = touch:getLocation()["y"]
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
        local jsonObj = {}
        if keyCode == cc.KeyCode.KEY_A then
            -- ninjaObj:walk(-1)
            jsonObj["inputType"] = "walk"
            jsonObj["walkDir"] = -1
        elseif keyCode == cc.KeyCode.KEY_D then
            -- ninjaObj:walk(1)
            jsonObj["inputType"] = "walk"
            jsonObj["walkDir"] = 1
        elseif keyCode == cc.KeyCode.KEY_W then
            -- ninjaObj:jump()
            jsonObj["inputType"] = "jump"
        else return end
        socket:send(json.encode(jsonObj))
    end
    local function onKeyReleased(keyCode, event)
        local jsonObj = {}
        if keyCode == cc.KeyCode.KEY_A then
            -- ninjaObj:walk(1)
            jsonObj["inputType"] = "walk"
            jsonObj["walkDir"] = 1
        elseif keyCode == cc.KeyCode.KEY_D then
            -- ninjaObj:walk(-1)
            jsonObj["inputType"] = "walk"
            jsonObj["walkDir"] = -1
        else return end
        socket:send(json.encode(jsonObj))
    end
    listen = cc.EventListenerKeyboard:create()
    listen:registerScriptHandler(onKeyPressed, cc.Handler.EVENT_KEYBOARD_PRESSED)
    listen:registerScriptHandler(onKeyReleased, cc.Handler.EVENT_KEYBOARD_RELEASED)
    eventDispatcher:addEventListenerWithSceneGraphPriority(listen, self)

    self.monsterHealth = 100
    -- 監聽碰撞事件
    -- local function onContactBegin(contact)
    --     local nodeA = contact:getShapeA():getBody():getNode()
    --     local nodeB = contact:getShapeB():getBody():getNode()
    --     print("tag A = " .. nodeA:getTag() .. ", tag B = " .. nodeB:getTag())
    --     local monsterNode = nil
    --     if nodeA:getTag() == EnemyTag then monsterNode = nodeA
    --     elseif nodeB:getTag() == EnemyTag then monsterNode = nodeB
    --     end
    --     if monsterNode ~= nil then
    --         self.monsterHealth = math.max(self.monsterHealth - 10, 0)
    --         -- print("hit monster, health = " .. self.monsterHealth)
    --         monsterNode:getChildByName("HealthBar"):setPercent(self.monsterHealth)
    --     end
    --     return true
    -- end

    -- local contactListener = cc.EventListenerPhysicsContact:create()
    -- contactListener:registerScriptHandler(onContactBegin, cc.Handler.EVENT_PHYSICS_CONTACT_BEGIN)
    -- eventDispatcher:addEventListenerWithFixedPriority(contactListener, 1)
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
    self:getPhysicsWorld():setDebugDrawMask(cc.PhysicsWorld.DEBUGDRAW_ALL)

    -- 怪物剛體設定
    local monsterRigidBody = cc.PhysicsBody:createBox(monster:getContentSize(), cc.PhysicsMaterial(1, 0, 0))
    monsterRigidBody:setGravityEnable(false)
    monsterRigidBody:setCollisionBitmask(0)
    monsterRigidBody:setCategoryBitmask(CharBitmask)
    monsterRigidBody:setContactTestBitmask(BulletBitmask)
    monster:setPhysicsBody(monsterRigidBody)

    -- 怪物移動
    local moveLeft = cc.MoveBy:create(2, cc.p(-160, 0))
    local moveRight = cc.MoveBy:create(2, cc.p(160, 0))
    monster:runAction(cc.RepeatForever:create(cc.Sequence:create(moveLeft, moveRight)))
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
function cc.pScreenToWorld(screenCoor)
    -- 常數
    local camOffset = cc.p(640, 360)
    -- 計算過程
    local camOrigin = cc.pSub(cc.p(cam:getPosition()), camOffset) -- 計算Camera原點
    local worldCoor = cc.pAdd(camOrigin, screenCoor) -- 加上螢幕座標
    return worldCoor
end

-- 子彈移動
-- function BattleScene:shoot(touch)
--     local newBullet = bullet:clone()
--     rootNode:addChild(newBullet)

--     -- 設定剛體
--     local bulletRigidBody = cc.PhysicsBody:createBox(newBullet:getContentSize(), cc.PhysicsMaterial(1, 0, 0))
--     bulletRigidBody:setGravityEnable(false)
--     bulletRigidBody:setCollisionBitmask(0)
--     bulletRigidBody:setContactTestBitmask(bit.lshift(1, 0))
--     newBullet:setPhysicsBody(bulletRigidBody)

--     -- 設定動作
--     newBullet:setPosition(ninja:getPosition())
--     local pNinja = cc.p(ninja:getPosition())
--     local touchP = cc.p(touch:getLocation()["x"], touch:getLocation()["y"])
--     -- touch 螢幕座標轉成世界座標
--     local touchWorld = cc.pSub(cc.pAdd(touchP, cc.p(cam:getPosition())), cc.p(640, 360))
--     local offset = cc.pMul(cc.pNormalize(cc.pSub(touchWorld, pNinja)), 500)
--     local move = cc.MoveBy:create(0.5, offset)
--     local removeSelf = cc.RemoveSelf:create()
--     newBullet:runAction(cc.Sequence:create(move, removeSelf))
-- end
-- function BattleScene:shootP(touchP)
--     local newBullet = bullet:clone()
--     rootNode:addChild(newBullet)

--     -- 設定剛體
--     local bulletRigidBody = cc.PhysicsBody:createBox(newBullet:getContentSize(), cc.PhysicsMaterial(1, 0, 0))
--     bulletRigidBody:setDynamic(false)
--     bulletRigidBody:setCollisionBitmask(0)
--     bulletRigidBody:setContactTestBitmask(bit.lshift(1, 0))
--     newBullet:setPhysicsBody(bulletRigidBody)

--     -- 設定動作
--     newBullet:setPosition(ninja:getPosition())
--     local pNinja = cc.p(ninja:getPosition())
--     -- touch 螢幕座標轉成世界座標
--     local touchWorld = cc.pScreenToWorld(touchP)
--     local offset = cc.pMul(cc.pNormalize(cc.pSub(touchWorld, pNinja)), 500)
--     local move = cc.MoveBy:create(0.5, offset)
--     local removeSelf = cc.RemoveSelf:create()
--     newBullet:runAction(cc.Sequence:create(move, removeSelf))
-- end

-- 處理server傳來的指令
function BattleScene:handleOp(jsonObj)
    -- dump(jsonObj)
    local op = jsonObj["op"]
    if op == "CREATE_BATTLE_CHAR" then
        -- local item = readyListItemPrefab:clone()
        -- item:getChildByName("PlayerName"):setString(jsonObj["playerName"])
        -- readyList:pushBackCustomItem(item)
    end
    if jsonObj["inputType"] == "walk" then
        ninjaObj:walk(jsonObj["walkDir"])
    elseif jsonObj["inputType"] == "jump" then
        ninjaObj:jump()
    elseif jsonObj["inputType"] == "shoot" then
        -- self:shootP(cc.p(jsonObj["x"], jsonObj["y"]))
        ninjaObj:shoot(cc.p(jsonObj["x"], jsonObj["y"]))
    end
end

return BattleScene