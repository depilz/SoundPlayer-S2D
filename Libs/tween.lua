local idCounter = 0
local function newID()
  idCounter = idCounter+1
  return "tween_"..idCounter
end

local Tween = {}

function Tween:new(...)
  local o = setmetatable( {}, self )
  self.__index = self
  o:initialize(...)
  return o
end


-- ---------------------------------------------------------------------------------------------------------------------
-- Tween --
-- ---------------------------------------------------------------------------------------------------------------------


function Tween:printAll(t)
  print(t, self._delta, self._scale, self:getValue())
end

function Tween:initialize(start, ease, scale, listeners)
  self._delta = start or 0
  self._ease  = ease or easing.linear
  self._scale = scale or 1

  self._onStart    = listeners.onStart
  self._onUpdate   = listeners.onUpdate
  self._onPause    = listeners.onPause
  self._onResume   = listeners.onResume
  self._onComplete = listeners.onComplete
  self._onCancel   = listeners.onCancel

  self._tag      = newID()
  self._isActive = false
  self._isPaused = false

  return self._tag
end


function Tween:getValue()
  return self._ease(self._delta, 1, 0, self._scale)
end


function Tween:setDelta(delta)
  self:stop()
  self._delta = delta
end


function Tween:getDelta()
  return self._delta
end


function Tween:setScale(scale)
  self._scale = scale
  self:_update()
end


function Tween:getScale()
  return self._scale
end


function Tween:transitionTo(params)
  self:stop()

  self._onStart    = params.onStart or self._onStart
  self._onUpdate   = params.onUpdate or self._onUpdate
  self._onPause    = params.onPause or self._onPause
  self._onResume   = params.onResume or self._onResume
  self._onComplete = params.onComplete or self._onComplete
  self._onCancel   = params.onCancel or self._onCancel


  transition.to(self, {
    delay      = params.delay,
    time       = params.time,

    _delta     = params.value,

    iterations = params.iterations,

    tag        = self._tag,

    delta      = params.delta,

    onStart    = function() self:onStart()    end,
    onComplete = function() self:onComplete() end,
    onPause    = function() self:onPause()    end,
    onResume   = function() self:onResume()   end,
    onCancel   = function() self:onCancel()   end,
    onRepeat   = self._onRepeat,
  })
end

-- Flow control --------------------------------------------------------------------------------------------------------

function Tween:enterFrame()
  self:_update()
end


function Tween:_update()
  if not self._onUpdate then return end
  local value = self:getValue()
  self._onUpdate(value)
end


function Tween:resume(params)
  if not self._isPaused then return end
  self._isPaused = false

  if self._isActive then
    Runtime:addEventListener("enterFrame", self)
  end

  transition.resume(self._tag)
end


function Tween:pause(params)
  if self._isPaused then return end

  transition.pause(self._tag)
end


function Tween:stop()
  if not self._isActive then return end
  transition.cancel(self._tag)
end


-- callbacks -----------------------------------------------------------------------------------------------------------

function Tween:onStart()
  if not self._isActive then
    Runtime:addEventListener("enterFrame", self)
  end
  self._isActive = true
  if self._onStart then self._onStart(self._delta) end
end


function Tween:onComplete()
  self._isActive = false

  Runtime:removeEventListener("enterFrame", self)

  self:_update()
  if self._onComplete then self._onComplete(self._delta) end
end


function Tween:onPause()
  self._isPaused = true

  if not self._isActive then
    Runtime:removeEventListener("enterFrame", self)
  end

  if self._onPause then self._onPause(self._delta) end
end


function Tween:onResume()
  self._isPaused = false

  if self._isActive then
    Runtime:removeEventListener("enterFrame", self)
  end

  if self._onResume then self._onResume(self._delta) end
end


function Tween:onCancel()
  if not self._isActive then return end
  self._isActive = false

  if not self._isPaused then
    Runtime:removeEventListener("enterFrame", self)
  end

  self._isPaused = false

  if self._onCancel then self._onCancel(self._delta) end
end




return Tween