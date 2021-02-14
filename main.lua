require 'engine'


function init()
  main = Main()
  --[[
  Add your own states by creating them in another file. See engine/game/state.lua.
    main:add(Game'game')
    main:go_to('game')
  ]]--
end


function update(dt)
  main:update(dt)
end


function draw()
  main:draw()
end


function love.run()
  return engine_run({
    game_name = 'Anchor',
    window_width = 480*3,
    window_height = 270*3,
  })
end
