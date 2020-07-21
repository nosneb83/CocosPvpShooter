local BattleScene = class("BattleScene", function()
    return cc.Scene:createWithPhysics()
end)

local scheduler = cc.Director:getInstance():getScheduler()
local rootNode
local ninja, monster, bullet

function BattleScene:ctor()
    rootNode = cc.CSLoader:createNode("BattleScene.csb")
    self:addChild(rootNode)

    ninja = rootNode:getChildByName("Ninja")
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
            print("Press A")
            self:charMoveLeft()
        elseif keyCode == cc.KeyCode.KEY_D then
            print("Press D")
            self:charMoveRight()
        elseif keyCode == cc.KeyCode.KEY_W then
            print("Press W")
            self:charJump()
        end
    end
    local function onKeyReleased(keyCode, event)
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
        self:getPhysicsWorld():step(1/60.0)
    end
    self:getPhysicsWorld():setAutoStep(false)
    self:scheduleUpdateWithPriorityLua(update, 0)

    -- 设置物理世界重力
    local gravity = cc.p(0, -1000)
    self:getPhysicsWorld():setGravity(gravity)

    -- 物理世界显示包围盒
    self:getPhysicsWorld():setDebugDrawMask(cc.PhysicsWorld.DEBUGDRAW_ALL) -- cc.PhysicsWorld.DEBUGDRAW_ALL显示包围盒 cc.PhysicsWorld.DEBUGDRAW_NONE不显示包围盒

    -- 创建物理边框
    local edgeBody = cc.PhysicsBody:createEdgeBox(self.visibleSize, cc.PhysicsMaterial(1, 0, 0), 10)
    local edgeNode = cc.Node:create()
    rootNode:addChild(edgeNode)
    edgeNode:setPosition(self.visibleSize.width * 0.5, self.visibleSize.height * 0.5)
    edgeNode:setPhysicsBody(edgeBody)

    -- 材质类型
    local MATERIAL_DEFAULT = cc.PhysicsMaterial(1, 0, 0) -- 密度、碰撞系数、摩擦力

    -- 角色剛體設定
    local body = cc.PhysicsBody:createBox(ninja:getContentSize(), MATERIAL_DEFAULT)  -- 刚体大小，材质类型
    -- body:setGravityEnable(false)
    ninja:setPhysicsBody(body)
    body:setRotationEnable(false)

    -- 怪物剛體設定
    local monsterRigidBody = cc.PhysicsBody:createBox(monster:getContentSize(), MATERIAL_DEFAULT)
    monster:setPhysicsBody(monsterRigidBody)
    monsterRigidBody:setGravityEnable(false)
end

-- 角色移動
function BattleScene:charMoveLeft()
    ninja:runAction(cc.MoveBy:create(0.5, cc.p(-30, 0)))
end
function BattleScene:charMoveRight()
    ninja:runAction(cc.MoveBy:create(0.5, cc.p(30, 0)))
end
function BattleScene:charJump()
    ninja:runAction(cc.JumpBy:create(0.5, cc.p(0, 0), 50, 1))
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