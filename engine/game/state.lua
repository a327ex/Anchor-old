-- The base state class.
-- This and the Game classes exist simply to facilitate updating, drawing and transitioning between different levels.
-- You can choose to ignore both of these classes and just build your game directly in the main.lua file, using other concepts (like Groups) alone.
-- But if you want the functionalities provided by this and the Game class, then the way to use this class is by mixing it into your own State, like so:
--
--[[
MyState = Object:extend()
MyState:implement(State)
function MyState:new(name, opts) self:new_state(name, opts) end

function MyState:on_enter(...)
  -- your initilization code
end

function MyState:update(dt)
  -- your update code
end

function MyState:draw()
  -- your draw code
end
]]--

-- Then in your main.lua file you'd have something like this:
--
--[[
function init()
  game = Game()
  game:add_state(MyState('my_states_name'))
  game:set_current_state('my_states_name')
end

function update(dt)
  game:update(dt)
end

function draw()
  game:draw()
end
]]--
State = Object:extend()
function State:new_state(name, opts)
  for k, v in pairs(opts or {}) do self[k] = v end
  self.id = random:uid()
  self.name = name
  self.active = false
  return self
end


-- Sets .active to true
-- When .active is false this state will not be updated nor drawn
function State:activate(...)
  self.active = true
  if self.on_enter then
    self:on_enter(...)
  end
end


-- Sets .active to false
-- When .active is false this state will not be updated nor drawn
function State:deactivate(...)
  self.active = false
  if self.on_exit then
    self:on_exit(...)
  end
end


-- Sets .paused to true
-- When .paused is true this state will be updated with dt = 0
function State:pause(...)
  self.paused = true
  if self.on_pause then
    self:on_pause(...)
  end
end


-- Sets .paused to false
-- When .paused is false this state will be updated normally
function State:unpause(...)
  self.paused = false
  if self.on_unpause then
    self:on_unpause(...)
  end
end


-- Sets .hidden to true
-- When .hidden is true this state will not be drawn
function State:hide(...)
  self.hidden = true
  if self.on_hide then
    self:on_hide(...)
  end
end


-- Sets .hidden to false
-- When .hidden is false this state will be drawn normally
function State:show(...)
  self.hidden = false
  if self.on_show then
    self:on_show(...)
  end
end
