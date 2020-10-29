log = {}

-- Sends a message to the bottom left of the screen, useful for logging things when a console isn't available
-- log.message('Player died!')
function log.message(text, font)
  table.each(log.group.objects, function(v) if v:is(LogMessage) then v:move_up() end end)
  log.group:add_object(LogMessage(20, sy*gh - 20, {text = '[log_message_fade]' .. text, tags = {log_message_fade}, font = font}))
end

log_message_fade = TextTag({
  init = function(c, i, text)
    text.log_message_color = Color(1, 1, 1, 1)
    text.timer:after(1, function()
      text.timer:tween(2, text.log_message_color, {a = 0}, math.linear)
    end)
  end,

  draw = function(c, i, text)
    graphics.set_color(text.log_message_color)
  end
})


LogMessage = Object:extend()
LogMessage:implement(GameObject)
function LogMessage:new(x, y, opts) self:new_game_object(x, y, opts) end


function LogMessage:init()
  self.text = Text(opts.text, opts.tags, opts.font)
  self.y = self.y - sy*self.text.h
  self.timer:after(3, function() self.dead = true end)
end


function LogMessage:update(dt)
  self:update_game_object(dt)
  self.text:update(dt)
end


function LogMessage:draw()
  self.text:draw(self.x, self.y)
end


function LogMessage:move_up()
  self.y = self.y - 1.2*self.text.h
end
