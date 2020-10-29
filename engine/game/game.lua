-- The base game class.
-- One instance of this should be created in your main.lua file and you should add states to it.
--
-- It will automatically handle updating and drawing of states as well as calling appropriate callbacks:
-- on_enter is called when a state is activated (.active set to true) after being set via game:set_current_state
-- on_exit is called when a state is deactivated (.active set to false) after being unset via game:set_current_state
-- destroy is called when a state has its .dead attribute set to true, such states will be removed entirely from the game after being destroyed
--
-- States that are paused (.paused attribute is true after state:pause was called) are updated with dt = 0
-- States that are hidden (.hidden attribute is true after state:hide was called) are not drawn
-- States that are not active (.active attribute is false) are not updated nor drawn
-- See the State class for more information, as these two classes are tightly linked.
Game = Object:extend()
function Game:new()
  self.current_state = nil
  self.states = {}
  self.states.by_id = {}
  self.states.by_name = {}
  self.slow_amount = 1
  self.timer = Timer()
  self.camera = Camera(gw/2, gh/2, gw, gh)
  self.canvas = Canvas(gw, gh, {msaa = msaa})
end


function Game:update(dt)
  self.timer:update(dt*self.slow_amount)
  self.camera:update(dt*self.slow_amount)

  for _, state in ipairs(self.states) do
    if state.active then
      if state.paused then state:update(0)
      else state:update(dt*self.slow_amount) end
    end
  end

  for i = #self.states, 1, -1 do
    if self.states[i].dead then
      if self.states[i].destroy then
        self.states[i]:destroy()
      end
      self.states.by_id[self.states[i].id] = nil
      self.states.by_name[self.states[i].name] = nil
      table.remove(self.states, i)
    end
  end
end


function Game:draw()
  self.canvas:set()
  self.canvas:clear()
  for _, state in ipairs(self.states) do
    if state.active and not state.hidden then
      state:draw()
    end
  end
  self.canvas:unset()
  self.canvas:draw(0, 0, 0, sx, sy)
end


-- Adds an existing state to the game
-- arena_1 = Arena('arena_1')
-- game:add_state(arena_1)
function Game:add_state(state)
  if not state.id then state.id = random:uid() end
  self.states.by_id[state.id] = state
  self.states.by_name[state.name] = state
  table.insert(self.states, state)
  return state
end


-- Deactivates the current state and activates the target state
-- on_exit is called on the deactivated state and on_enter is called on the target state
-- game:set_current_state('arena_1')
function Game:set_current_state(name, ...)
  if self.current_state then self.current_state:deactivate() end
  self.current_state = self:get_state_by_name(name)
  self.current_state:activate(...)
end


-- game:add_state(Arena('arena_1'))
-- game:set_current_state('arena_1')
-- game:is_current_state('arena_1') -> true
function Game:is_current_state(name)
  return self.current_state.name == name
end


-- game:add_state(Arena('arena_1'))
-- game:set_current_state(Arena('arena_1'))
-- game:get_state_by_name('arena_1') -> the state instance that has that name
function Game:get_state_by_name(name)
  return self.states.by_name[name]
end


function Game:destroy()
  for _, state in ipairs(self.states) do state:destroy() end
  self.states = {}
  self.states.by_id = {}
  self.states.by_name = {}
  return self
end


-- Slows the updating of all states by amount for duration
-- game:slow(0.5, 0.5) -> slows the game down by 50% for 0.5 seconds, tweening it back to 100% using math.cubic_in_out
-- game:slow(0.5, 0.5, math.linear) -> same as above but using math.linear instead
function Game:slow(amount, duration, tween_method)
  self.slow_amount = amount
  timer:tween(duration, self, {slow_amount = 1}, tween_method or math.cubic_in_out, function() self.slow_amount = 1 end, 'slow')
end
