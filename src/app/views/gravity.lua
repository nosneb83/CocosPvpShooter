local Scene = class("Scene", function()
    return cc.Scene:createWithPhysics() -- 物理场景
end)

function Scene:ctor()
    local layer = cc.Layer:create()
    self:addChild(layer)

    -- 世界大小
    self.visibleSize = cc.Director:getInstance():getVisibleSize()

    -- 设置物理世界重力
    local gravity = cc.p(0, -1000)
    self:getPhysicsWorld():setGravity(gravity)

    -- 物理世界显示包围盒
    self:getPhysicsWorld():setDebugDrawMask(cc.PhysicsWorld.DEBUGDRAW_ALL) -- cc.PhysicsWorld.DEBUGDRAW_ALL显示包围盒 cc.PhysicsWorld.DEBUGDRAW_NONE不显示包围盒

    -- 创建物理边框
    local edgeBody = cc.PhysicsBody:createEdgeBox(self.visibleSize, cc.PhysicsMaterial(1, 1, 0), 3)
    local edgeNode = cc.Node:create()
    layer:addChild(edgeNode)
    edgeNode:setPosition(self.visibleSize.width * 0.5, self.visibleSize.height * 0.5)
    edgeNode:setPhysicsBody(edgeBody)

    -- 材质类型
    local MATERIAL_DEFAULT = cc.PhysicsMaterial(0.1, 0.5, 0.5)                      -- 密度、碰撞系数、摩擦力

    -- 球
    local ball = cc.Sprite:create("btn-a-0.png")

    -- 刚体
    local body = cc.PhysicsBody:createBox(ball:getContentSize(), MATERIAL_DEFAULT)  -- 刚体大小，材质类型

    -- 设置球的刚体属性
    ball:setPhysicsBody(body)   -- 设置球的刚体
    ball:setPosition(display.center)
    layer:addChild(ball)

    -- 触摸事件
    local function onTouchBegan(touch, event)
        local location = touch:getLocation()
        local arr = self:getPhysicsWorld():getShapes(location)

        local body = nil
        for _, obj in ipairs(arr) do
            if obj:getBody() then
                body = obj:getBody()
            end
        end

        if body then
            local mouse = cc.Node:create()
            local physicsBody = cc.PhysicsBody:create(PHYSICS_INFINITY, PHYSICS_INFINITY)
            mouse:setPhysicsBody(physicsBody)
            physicsBody:setDynamic(false)
            mouse:setPosition(location)
            layer:addChild(mouse)
            local joint = cc.PhysicsJointPin:construct(physicsBody, body, location)
            joint:setMaxForce(5000 * body:getMass())
            cc.Director:getInstance():getRunningScene():getPhysicsWorld():addJoint(joint)
            touch.mouse = mouse

            return true
        end

        return false
    end

    local function onTouchMoved(touch, event)
        if touch.mouse then
            touch.mouse:setPosition(touch:getLocation())
        end
    end

    local function onTouchEnded(touch, event)
        if touch.mouse then
            layer:removeChild(touch.mouse)
            touch.mouse = nil
        end
    end
    local touchListener = cc.EventListenerTouchOneByOne:create()
    touchListener:registerScriptHandler(onTouchBegan, cc.Handler.EVENT_TOUCH_BEGAN)
    touchListener:registerScriptHandler(onTouchMoved, cc.Handler.EVENT_TOUCH_MOVED)
    touchListener:registerScriptHandler(onTouchEnded, cc.Handler.EVENT_TOUCH_ENDED)
    local eventDispatcher = layer:getEventDispatcher()
    eventDispatcher:addEventListenerWithSceneGraphPriority(touchListener, layer)
    return Scene
end