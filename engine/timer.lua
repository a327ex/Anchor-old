-- The base Timer class. Useful for juicing things up generally.
-- A global instance of this called "timer" is available by default.
Timer = Object:extend()
function Timer:new()
  self.timers = {}
end


-- Calls the action function after delay seconds.
-- If tag is passed in then any other timer actions with the same tag are automatically cancelled.
-- timer:after(2, function() print(1) end) -> prints 1 after 2 seconds
function Timer:after(delay, action, tag)
  local tag = tag or random:uid()
  self.timers[tag] = {type = "after", timer = 0, unresolved_delay = delay, delay = self:resolve_delay(delay), action = action}
end


-- Calls the action function every delay seconds.
-- If times is passed in then it only calls action for that amount of times.
-- If after is passed in then it is called after the last time action is called.
-- If tag is passed in then any other timer actions with the same tag are automatically cancelled.
-- timer:every(2, function() print(1) end) -> prints 1 every 2 seconds
-- timer:every(2, function() print(1) end, 5, function() print(2) end) -> prints 1 every 2 seconds 5 times, and then prints 2
function Timer:every(delay, action, times, after, tag)
  local times = times or 0
  local after = after or function() end
  local tag = tag or random:uid()
  self.timers[tag] = {type = "every", timer = 0, unresolved_delay = delay, delay = self:resolve_delay(delay), action = action, times = times, max_times = times, after = after}
end


-- Same as every except the action is called immediately when this function is called, and then every delay seconds.
function Timer:every_immediate(delay, action, times, after, tag)
  local times = times or 0
  local after = after or function() end
  local tag = tag or random:uid()
  self.timers[tag] = {type = "every", timer = 0, unresolved_delay = delay, delay = self:resolve_delay(delay), action = action, times = times, max_times = times, after = after}
  action()
end


-- Calls the action every frame for delay seconds.
-- If after is passed in then it is called after the duration ends.
-- If tag is passed in then any other timer actions with the same tag are automatically cancelled.
-- timer:during(5, function() print(random:float(0, 100)) end)
function Timer:during(delay, action, after, tag)
  local after = after or function() end
  local tag = tag or random:uid()
  self.timers[tag] = {type = "during", timer = 0, unresolved_delay = delay, delay = self:resolve_delay(delay), action = action, after = after}
end


-- Tweens the target's values specified by the source table for delay seconds using the given tweening method.
-- All tween methods can be found in the math/math file.
-- If after is passed in then it is called after the duration ends.
-- If tag is passed in then any other timer actions with the same tag are automatically cancelled.
-- timer:tween(0.2, self, {sx = 0, sy = 0}, math.linear) -> tweens this object's scale variables to 0 linearly over 0.2 seconds
-- timer:tween(0.2, self, {sx = 0, sy = 0}, math.linear, function() self.dead = true end) -> tweens this object's scale variables to 0 linearly over 0.2 seconds and then kills it
function Timer:tween(delay, target, source, method, after, tag)
  local method = method or math.linear
  local after = after or function() end
  local tag = tag or random:uid()
  local initial_values = {}
  for k, _ in pairs(source) do initial_values[k] = target[k] end
  self.timers[tag] = {type = "tween", timer = 0, unresolved_delay = delay, delay = self:resolve_delay(delay), target = target, initial_values = initial_values, source = source, method = method, after = after}
end


-- Cancels a timer action based on its tag.
-- This is automatically called if repeated tags are given to timer actions.
function Timer:cancel(tag)
  self.timers[tag] = nil
end


-- Returns the delay of a given tag.
-- This is useful when delays are set randomly (timer:every({2, 4}, ...) would set the delay at a random number between 2 and 4) and you need to know what the value chosen was.
function Timer:get_delay(tag)
  return self.timers[tag].delay
end


-- Returns the current iteration of an every timer action with the given tag.
-- Useful if you need to know that its the nth time an every action has been called.
function Timer:get_every_iteration(tag)
  return self.timers[tag].max_times - self.timers[tag].times 
end


-- Returns the elapsed time of a given timer as a number between 0 and 1.
-- Useful if you need to know where you currently are in the duration of a during call.
function Timer:get_during_elapsed_time(tag)
  return self.timers[tag].timer/self.timers[tag].delay
end


function Timer:resolve_delay(delay)
  if type(delay) == "table" then
    return random:float(delay[1], delay[2])
  else
    return delay
  end
end


function Timer:update(dt)
  for tag, timer in pairs(self.timers) do
    timer.timer = timer.timer + dt

    if timer.type == "after" then
      if timer.timer > timer.delay then
        timer.action()
        self.timers[tag] = nil
      end

    elseif timer.type == "every" then
      if timer.timer > timer.delay then
        timer.action()
        timer.timer = timer.timer - timer.delay
        timer.delay = self:resolve_delay(timer.unresolved_delay)
        if timer.times > 0 then
          timer.times = timer.times - 1
          if timer.times <= 0 then
            timer.after()
            self.timers[tag] = nil
          end
        end
      end

    elseif timer.type == "during" then
      timer.action()
      if timer.timer > timer.delay then
        self.timers[tag] = nil
      end

    elseif timer.type == "tween" then
      local t = timer.method(timer.timer/timer.delay)
      for k, v in pairs(timer.source) do
        timer.target[k] = math.lerp(t, timer.initial_values[k], v)
      end
      if timer.timer > timer.delay then
        timer.after()
        self.timers[tag] = nil
      end
    end
  end
end
