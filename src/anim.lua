Test = class("Test")
function Test:ctor()
    self.node = cc.CSLoader:createNode("plaza/gamePropAnim/bingtong.csb")
    self._root:addChild(self.node)
    -- 是否反转
    if self.data.reverse then
        self.node:getChildByName("Node_1"):setScaleX(-1)
    end
    -- 播放动画
    self.node:setPosition(self.data.staPos.x,self.data.staPos.y)
    self.node:runAction(cc.MoveTo:create(0.6,cc.p(self.data.endPos.x + (not self.data.reverse and -110 or 110), self.data.endPos.y + 240)))
    self.node:runAction(cc.Sequence:create(cc.ScaleTo:create(0.6,1.5),
    cc.CallFunc:create(function()
        local nodeAction = cc.CSLoader:createTimeline("plaza/gamePropAnim/bingtong.csb")
        -- 设置回调
        local eventFrameCall = function(frame)
            local eventName = frame:getEvent()
            if eventName == "end" then
                self.node:removeFromParent()
                self.node = nil
            end
        end
        nodeAction:clearFrameEventCallFunc()
        nodeAction:setFrameEventCallFunc(eventFrameCall)
        nodeAction:play("end", false)
        nodeAction:gotoFrameAndPlay(0, 130, false)
        self.node:runAction(nodeAction)
    end)))
end