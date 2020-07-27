Player = class("Player")

require("Bullet")

local scheduler = cc.Director:getInstance():getScheduler()
local bulletPrefab
local rootNode

-- 創建玩家角色
function Player:ctor(playerName, playerID, root, cam, heroType)
    self.playerName = playerName
    self.playerID = playerID
    self.health = 100
    self.dead = false
    rootNode = root
    self.node = rootNode:getChildByName("Player"):clone()
    rootNode:addChild(self.node)
    self.healthBar = self.node:getChildByName("HealthBar")
    self.cam = cam
    self.heroType = heroType
    self:rename(self.playerName .. "_" .. tostring(self.playerID))

    -- 角色剛體
    local MATERIAL_DEFAULT = cc.PhysicsMaterial(1, 0, 0) -- 密度、彈性係數、摩擦力
    self.body = cc.PhysicsBody:createBox(self.node:getContentSize(), MATERIAL_DEFAULT)
    self.body:setRotationEnable(false)
    self.body:setLinearDamping(20)
    self.body:setCategoryBitmask(CharBitmask)
    self.body:setCollisionBitmask(GroundBitmask)
    self.body:setContactTestBitmask(BulletBitmask)
    self.node:setPhysicsBody(self.body)
    self.node:setTag(1000 + self.playerID)

    -- 角色橫向移動
    self.walkDirection = 0
    self.walkSpeed = 5
    local function update()
        if self.dead then return end
        -- self.node:runAction(cc.MoveBy:create(1/60.0, cc.p(self.walkDirection * self.walkSpeed, 0)))
        self.body:applyImpulse(cc.pMul(cc.p(self.walkDirection, 0), 1200000))
        self:cameraFollow()
        -- 判斷死亡
        if self.healthBar:getPercent() == 0 then
            self.dead = true
            print(self.playerName .. " 掛惹QQ")
            self.anim:play("die", false)
        end
    end
    scheduler:scheduleScriptFunc(update, 1 / 60, false)

    -- 角色動畫
    local animPath = "char/char" .. tostring(self.heroType) .. "/PlayerAnim" .. tostring(self.heroType) .. ".csb"
    self.sprite = cc.CSLoader:createNode(animPath)
    self.sprite:setPosition(cc.p(20, 30))
    self.anim = cc.CSLoader:createTimeline(animPath)
    self.sprite:runAction(self.anim)
    self.anim:play("idle", true)
    self.node:addChild(self.sprite)
end

-- 設定角色名稱
function Player:rename(playerName)
    self.node:getChildByName("Name"):setString(playerName)
end

-- 角色動作
function Player:walk(dir)
    if self.dead then
        self.walkDirection = 0
        return
    end
    self.walkDirection = self.walkDirection + dir
    -- 改變動畫
    if self.walkDirection > 0 then
        self.sprite:setScaleX(1)
        self.anim:play("walk", true)
    elseif self.walkDirection < 0 then
        self.sprite:setScaleX(-1)
        self.anim:play("walk", true)
    else
        self.anim:play("idle", true)
    end
end
function Player:jump()
    if self.dead then return end
    self.body:applyImpulse(cc.pMul(cc.p(0, 1), 36000000))
end
function Player:shoot(touch)
    if self.dead then return end
    local bullet = Bullet:create(rootNode, self.heroType, self.playerID)
    -- self.node:addChild(bullet.node)
    local from = cc.p(self.node:getPosition())
    -- local to = cc.pScreenToWorld(touch)
    bullet:shoot(from, touch)
    -- self.anim:play("attack", false)
end

-- 動畫播放
function Player:playAnim(animName)
    if animName == "idle" then
        self.anim:play("idle", true)
    elseif animName == "walk" then
        self.anim:play("walk", true)
    elseif animName == "attack" then -- 有bug
        local attAnim = self.anim:clone()
        self.anim:play("attack", false)
        local function func()
            if self.walkDirection > 0 then
                self.sprite:setScaleX(1)
                self.anim:gotoFrameAndPlay(45, 75, true)
            elseif self.walkDirection < 0 then
                self.sprite:setScaleX(-1)
                self.anim:gotoFrameAndPlay(45, 75, true)
            else
                self.anim:gotoFrameAndPlay(0, 40, true)
            end
        end
        local call = cc.CallFunc(func)
        self.sprite:runAction(cc.Sequence:create(attAnim, call))
    elseif animName == "die" then
        self.anim:play("die", false)
    end
end

-- camera跟隨
function Player:cameraFollow()
    if self.cam == nil then return end
    local camX, camY = self.node:getPosition()
    -- 限制camera不要超出地圖範圍
    camX = math.clamp(camX, 0, 1280)
    camY = math.clamp(camY, 0, 720)
    self.cam:setPosition(cc.p(camX, camY))
end