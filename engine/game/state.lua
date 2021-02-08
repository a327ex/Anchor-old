-- The base State class.  
-- The general way of creating an object that implements these functions goes like this:
--[[
MyState = Object:extend()
MyState:implement(State)
function MyState:init(name)
  self:init_state(name)
end

function MyState:on_enter(from)

end

function MyState:update(dt)

end


function MyState:draw()

end
]]--

-- This creates a new MyState class which you can then use to start writing your code.
-- Use the init function for things you need to do when the state object is created.
-- Use the on_enter function for things you need to do whenever the state gets activated.
-- By default, whenever a state gets deactivated it's not deleted from memory, so if you want to restart a level, for instance, whenever you switch states,
-- then you need to destroy everything that needs to be destroyed in an on_exit function and then recreate it again in the on_enter function.
-- You'd add a state to the game like this:
--   state.add(MyState'level_1')
-- You'd move to that state like so:
--   state.go_to'level_1'
-- state.go_to automatically calls on_exit for the currently active state and on_enter for the new one.
State = Object:extend()
function State:init_state(name)
  self.name = name or random:uid()
end


function State:enter(from)
  self.active = true
  if self.on_enter then self:on_enter(from) end
end


function State:exit(to)
  self.active = false
  if self.on_exit then self:on_exit(to) end
end


function State:hide()
  self.hidden = true
  if self.on_hide then self:on_hide() end
end


function State:unhide()
  self.hidden = false
  if self.on_unhide then self:on_unhide() end
end


function State:pause()
  self.paused = true
  if self.on_pause then self:on_pause() end
end


function State:unpause()
  self.paused = false
  if self.on_unpause then self:on_unpause() end
end


state = {}
state.states = {}
function state.add(state_object)
  state.states[state_object.name] = state_object
end


function state.get(state_name)
  return state.states[state_name]
end


-- Deactivates the current active state and activates the target one.
-- Calls on_exit for the deactivated state and on_enter for the activated one.
function state.go_to(state_object)
  if type(state_object) == 'string' then state_object = state.get(state_object) end

  if state.current then
    if state.current.active then
      state.current:exit(state_object)
    end
  end

  local last_state = state.current
  state.current = state_object
  state_object:enter(last_state)
end


function state.update(dt)
  for _, state in pairs(state.states) do
    if (state.active and not state.paused) or state.persistent_update then
      state:update(dt)
    end
  end
end


function state.draw()
  for _, state in pairs(state.states) do
    if (state.active and not state.hidden) or state.persistent_draw then
      state:draw()
    end
  end
end
