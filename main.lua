require 'engine'


function init()
  --[[
  Add your own states by creating them in another file. See engine/game/state.lua.
    state.add(Game'game')
    state.go_to('game')
  ]]--
end


function update(dt)
  state.update(dt)
end


function draw()
  state.draw()
end


function love.run()
  return engine_run({
    game_name = 'Anchor',
    window_width = 480*3,
    window_height = 270*3,
  })
end
