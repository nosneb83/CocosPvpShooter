Bullet = class("Bullet")

local rootNode

function Bullet:ctor(root, type) -- Node, 子彈類型
    -- 參數設定
    rootNode = root
    self.node = rootNode:getChildByName("Bullet"):clone()
    rootNode:addChild(self.node)
    self.damage = 10
    self.range = 500
    self.duration = 0.5
    if type == 1 then
        self.damage = 10
        self.range = 500
        self.duration = 0.5
    elseif type == 2 then
        self.damage = 10
        self.range = 500
        self.duration = 0.5
    elseif type == 3 then
        self.damage = 10
        self.range = 500
        self.duration = 0.5
    else
        print("子彈類型錯誤!!")
    end
    -- 設定剛體
    self.body = cc.PhysicsBody:createBox(self.node:getContentSize(), cc.PhysicsMaterial(1, 0, 0))
    self.body:setGravityEnable(false)
    self.body:setCategoryBitmask(BulletBitmask)
    self.body:setCollisionBitmask(0)
    self.body:setContactTestBitmask(GroundBitmask + CharBitmask)
    self.node:setPhysicsBody(self.body)

    -- 監聽碰撞事件
    local function onContactBegin(contact)
        local nodeA = contact:getShapeA():getBody():getNode()
        local tagA = nodeA:getTag()
        local nodeB = contact:getShapeB():getBody():getNode()
        local tagB = nodeB:getTag()
        print("tagA = " .. tagA .. ", tagB = " .. tagB)

        if nodeA:getTag() == GroundTag or nodeB:getTag() == GroundTag then
            self.node:runAction(cc.RemoveSelf:create())
            return true
        end

        local enemyNode = nil
        if nodeA:getTag() == EnemyTag then enemyNode = nodeA
        elseif nodeB:getTag() == EnemyTag then enemyNode = nodeB
        end
        if enemyNode ~= nil then
            self:hitEnemy(enemyNode)
        end
        return true
    end
    local contactListener = cc.EventListenerPhysicsContact:create()
    contactListener:registerScriptHandler(onContactBegin, cc.Handler.EVENT_PHYSICS_CONTACT_BEGIN)
    local eventDispatcher = cc.Director:getInstance():getEventDispatcher()
    eventDispatcher:addEventListenerWithSceneGraphPriority(contactListener, self.node)
    -- eventDispatcher:addEventListenerWithFixedPriority(contactListener, 1)
end

function Bullet:shoot(from, to)
    self.node:setPosition(from)
    local shootDir = cc.pNormalize(cc.pSub(to, from)) -- 射擊方向
    local shootVec = cc.pMul(shootDir, self.range) -- 子彈位移向量
    local shootMove = cc.MoveBy:create(self.duration, shootVec)
    local removeSelf = cc.RemoveSelf:create()
    self.node:setVisible(true)
    self.node:runAction(cc.Sequence:create(shootMove, removeSelf))
end

function Bullet:hitGround()
    self.node:runAction(cc.RemoveSelf:create())
end

function Bullet:hitEnemy(enemyNode)
    local healthBar = enemyNode:getChildByName("HealthBar")
    local health = math.max(healthBar:getPercent() - self.damage, 0)
    print("hit enemy, health = " .. health)
    healthBar:setPercent(health)
    self.node:runAction(cc.RemoveSelf:create())
end