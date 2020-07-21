local BattleScene = class("BattleScene", function()
    return cc.Scene:createWithPhysics()
end)

require("Player")
local scheduler = cc.Director:getInstance():getScheduler()
local rootNode
local ninja, monster, bullet
local ninjaObj

function BattleScene:ctor()
    rootNode = cc.CSLoader:createNode("BattleScene.csb")
    self:addChild(rootNode)

    ninjaObj = Player:create("Ninja", rootNode:getChildByName("Ninja"), self:getDefaultCamera())
    ninja = ninjaObj.node

    monster = rootNode:getChildByName("Monster")
    bullet = rootNode:getChildByName("Bullet")

    self:setPhysics()

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
        self:shoot(touch)
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
        if keyCode == cc.KeyCode.KEY_A then
            ninjaObj.walkDirection = ninjaObj.walkDirection - 1
        elseif keyCode == cc.KeyCode.KEY_D then
            ninjaObj.walkDirection = ninjaObj.walkDirection + 1
        elseif keyCode == cc.KeyCode.KEY_W then
            ninjaObj:jump()
        end
    end
    local function onKeyReleased(keyCode, event)
        if keyCode == cc.KeyCode.KEY_A then
            ninjaObj.walkDirection = ninjaObj.walkDirection + 1
        elseif keyCode == cc.KeyCode.KEY_D then
            ninjaObj.walkDirection = ninjaObj.walkDirection - 1
        end
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
    local gravity = cc.p(0, -10000)
    self:getPhysicsWorld():setGravity(gravity)

    -- 物理世界 Debug Mode 開啟
    self:getPhysicsWorld():setDebugDrawMask(cc.PhysicsWorld.DEBUGDRAW_ALL) -- cc.PhysicsWorld.DEBUGDRAW_ALL显示包围盒 cc.PhysicsWorld.DEBUGDRAW_NONE不显示包围盒

    -- 設定物理世界邊框
    local edgeBody = cc.PhysicsBody:createEdgeBox(self.visibleSize, cc.PhysicsMaterial(1, 1, 0), 0)
    local edgeNode = cc.Node:create()
    rootNode:addChild(edgeNode)
    edgeNode:setPosition(self.visibleSize.width * 0.5, self.visibleSize.height * 0.5)
    edgeNode:setPhysicsBody(edgeBody)

    -- 材质类型
    local MATERIAL_DEFAULT = cc.PhysicsMaterial(1, 0, 0) -- 密度、碰撞系数、摩擦力

    -- 怪物剛體設定
    local monsterRigidBody = cc.PhysicsBody:createBox(monster:getContentSize(), MATERIAL_DEFAULT)
    monster:setPhysicsBody(monsterRigidBody)
    monsterRigidBody:setGravityEnable(false)
end

-- 子彈移動
function BattleScene:shoot(touch)
    local newBullet = bullet:clone()
    rootNode:addChild(newBullet)

    -- 設定剛體
    local bulletRigidBody = cc.PhysicsBody:createBox(newBullet:getContentSize(), cc.PhysicsMaterial(1, 0, 0))
    newBullet:setPhysicsBody(bulletRigidBody)
    bulletRigidBody:setGravityEnable(false)

    -- 設定動作
    newBullet:setPosition(ninja:getPosition())
    local pNinja = cc.p(ninja:getPosition())
    local touchP = cc.p(touch:getLocation()["x"], touch:getLocation()["y"])
    local offset = cc.pMul(cc.pNormalize(cc.pSub(touchP, pNinja)), 1000)
    local move = cc.MoveBy:create(0.5, offset)
    local removeSelf = cc.RemoveSelf:create()
    newBullet:runAction(cc.Sequence:create(move, removeSelf))
end

return BattleScene