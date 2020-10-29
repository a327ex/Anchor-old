Solid = Object:extend()
Solid:implement(GameObject)


function Solid:new(group, x, y, opts)
  self:new_game_object(group, x, y, opts)
  self:set_as_chain(true, self.vertices, 'static', 'solid')
end


function Solid:update(dt)
  self:update_game_object(dt)
end


function Solid:draw()
  self:draw_game_object()
end
