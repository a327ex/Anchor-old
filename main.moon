export *
moonscript = true
require 'engine'


init = ->


update = (dt) ->


draw = ->


love.run = ->
  engine_run {
    moonscript: true,
    game_name: 'Anchor'
    game_width: 480
    game_height: 270
    window_width: 480*3
    window_height: 270*3
    line_style: 'rough'
    default_filter: 'nearest'
    :init
    :update
    :draw
  }
