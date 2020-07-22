Player = class("Player")

local scheduler = cc.Director:getInstance():getScheduler()

-- 創建玩家角色
function Player:ctor(playerName, playerID, node, cam)
    self.playerName = playerName
    self.playerID = playerID
    self.health = 100.0
    self.node = node
    self.healthBar = node:getChildByName("HealthBar")
    self.cam = cam
    self:rename(self.playerName)

    local MATERIAL_DEFAULT = cc.PhysicsMaterial(1, 0, 0) -- 密度、彈性係數、摩擦力
    self.body = cc.PhysicsBody:createBox(node:getContentSize(), MATERIAL_DEFAULT)
    self.body:setRotationEnable(false)
    self.body:setLinearDamping(10)
    self.node:setPhysicsBody(self.body)

    -- 角色橫向移動
    self.walkDirection = 0
    self.walkSpeed = 5
    local function update()
        -- self.node:runAction(cc.MoveBy:create(1/60.0, cc.p(self.walkDirection * self.walkSpeed, 0)))
        self.body:applyImpulse(cc.pMul(cc.p(self.walkDirection, 0), 1500000))
        self:cameraFollow()
    end
    scheduler:scheduleScriptFunc(update, 1 / 60, false)
end

-- 設定角色名稱
function Player:rename(playerName)
    self.node:getChildByName("Name"):setString(playerName)
end

-- 角色移動&跳躍
function Player:walk(dir)
    self.walkDirection = self.walkDirection + dir
end
function Player:jump()
    self.body:applyImpulse(cc.pMul(cc.p(0, 1), 50000000))
end

-- camera跟隨
function Player:cameraFollow()
    local camX, camY = self.node:getPosition()
    -- 限制camera不要超出地圖範圍
    camX = math.clamp(camX, 0, 1280)
    camY = math.clamp(camY, 0, 720)
    self.cam:setPosition(cc.p(camX, camY))
end