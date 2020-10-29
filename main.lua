require 'engine'


function init()

end


function update(dt)

end


function draw()

end


function love.run()
  return engine_run({
    game_name = 'Anchor',
    game_width = 480,
    game_height = 270,
    window_width = 480*3,
    window_height = 270*3,
    line_style = 'rough',
    default_filter = 'nearest',
    init = init,
    update = update,
    draw = draw
  })
end
