-- A basic color object.
-- Colors can be created in 3 forms:
-- color = Color('#ffffff')
-- color = Color(255, 255, 255)
-- color = Color(1, 1, 1)
-- You can access the colors values via .r, .g, .b and .a.
-- You can create a copy of a color by calling color:clone().
Color = Object:extend()
function Color:new(r, g, b, a)
  if type(r) == "string" then
    local hex = r:gsub("#", "")
    self.r = tonumber("0x" .. hex:sub(1, 2))/255
    self.g = tonumber("0x" .. hex:sub(3, 4))/255
    self.b = tonumber("0x" .. hex:sub(5, 6))/255
    self.a = 1
  else
    if r > 1 or g > 1 or b > 1 then
      self.r = r/255
      self.g = g/255
      self.b = b/255
      self.a = (a or 255)/255
    else
      self.r = r
      self.g = g
      self.b = b
      self.a = a or 1
    end
  end
end


function Color:clone()
  return Color(self.r, self.g, self.b, self.a)
end
