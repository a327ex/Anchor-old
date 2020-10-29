-- A generic text object.
-- It implements a character based tagging system which should allow you to implement any kind of text effect possible, from setting a character's color to making it become visible, shake and play sounds.
-- You would use it like this:
--[[
yellow_text_tag = TextTag({
  init = function(c, i, text)
    text.yellow = Color(1, 0.5, 0, 1)
  end,
  draw = function(c, i, text)
    graphics.set_color(text.yellow)
  end
})

shaking_text_tag = TextTag({
  init = function(c, i, text)
    c.shaking_intensity = 8
  end,
  update = function(c, dt, i, text)
    c.ox = random:float(-c.shaking_intensity, c.shaking_intensity)
    c.oy = random:float(-c.shaking_intensity, c.shaking_intensity)
  end
})

text = Text('[yellow]This text is yellow [shaking]while this text is shaking []and this text is normal', {yellow = yellow_text_tag, shaking = shaking_text_tag}, main_font)
]]--

-- There are two main things happening in the example above: first we're create TextTags and then we're creating a text object that uses those tags.
-- The way each tag works is fairly simple: a tag accepts 3 functions, init, update and draw, and each of those functions operates on the text's characters one at a time.
-- In the example above, the text without tags is 'This text is yellow while this text is shaking and this text is normal'
-- For each of the characters in that string, different functions will be applied based on what tags were previously applied to it.
-- init, update and draw functions take in 3 arguments in common:
-- c - the character in question, a table containing .x, .y, .r, .sx, .sy, .ox, .oy and .character attributes.
-- i - the index of character in the string
-- text - the reference to the text object
-- The update function also takes in dt as the second argument.
Text = Object:extend()
function Text:new(tagged_text, text_tags, font)
  self.timer = Timer()
  self.font = font or love.graphics.getFont()
  self.tagged_text = tagged_text
  self.text_tags = text_tags
  self.raw_text, self.characters = self:parse(tagged_text)
  self.line_height_multiplier = 1
  self.line_count = 1
  self:format_text()
  for i, c in ipairs(self.characters) do
    for k, v in pairs(self.text_tags) do
      for _, tag in ipairs(c.tags) do
        if tag == k then
          if v.actions.init then v.actions.init(c, i, self) end
        end
      end
    end
  end
  return self
end


function Text:update(dt)
  self.timer:update(dt)
  self:format_text()
  for i, c in ipairs(self.characters) do
    for k, v in pairs(self.text_tags) do
      for _, tag in ipairs(c.tags) do
        if tag == k then
          if v.actions.update then v.actions.update(c, dt, i, self) end
        end
      end
    end
  end
end


-- Draws the text object at the specified location.
-- Unlike all other constructs in the engine, this x, y position is not the text's center, but its top-left position.
function Text:draw(x, y)
  for i, c in ipairs(self.characters) do
    for k, v in pairs(self.text_tags) do
      for _, tag in ipairs(c.tags) do
        if tag == k then
          if v.actions.draw then v.actions.draw(c, i, self) end
        end
      end
    end
    graphics.print(c.character, self.font, x + c.x, y + c.y, c.r or 0, c.sx or 1, c.sy or c.sx or 1, c.ox or 0, c.oy or 0)
    graphics.set_color(white)
  end
end


function Text:format_text()
  if self.wrap_width then self.w = self.wrap_width
  else self.w = self.font:get_text_width(self.raw_text) end

  local x = 0
  local line, col = 1, 1
  local last_space_index = 1
  for i, c in ipairs(self.characters) do
    if c.character == " " then
      c.line = line
      c.col = col
      c.x = x
      c.y = self.font.h*(line-1)
      last_space_index = i
      col = col + 1
      x = x + self.font:get_text_width(c.character)
    elseif c.character == "\n" then
      c.line = line
      c.col = col
      c.x = x
      c.y = self.font.h*(line-1)
      line = line + 1
      col = 1
      x = 0
    else
      if x + self.font:get_text_width(c.character) > self.w then
        line = line + 1
        col = 1
        x = 0
        self.characters[last_space_index].character = "\n"
        for j = last_space_index+1, i do
          self.characters[j].line = line
          self.characters[j].col = col
          self.characters[j].x = x
          self.characters[j].y = self.font.h*(line-1)
          x = x + self.font:get_text_width(self.characters[j].character)
          col = col + 1
        end
        c.line = line
        c.col = col
        c.x = x
        c.y = self.font.h*(line-1)
        x = x + self.font:get_text_width(c.character)
      else
        c.line = line
        c.col = col
        c.x = x
        c.y = self.font.h*(line-1)
        col = col + 1
        x = x + self.font:get_text_width(c.character)
      end
    end
  end
  self.h = self.font.h*line*self.line_height_multiplier
  self.line_count = line

  if self.justify == "right" then
    for i = 1, self.line_count do
      local characters = self:get_characters_in_line(i)
      local line_width = 0
      for _, c in ipairs(characters) do line_width = line_width + self.font:get_text_width(c.character) end
      local left_over_width = self.w - line_width
      for _, c in ipairs(characters) do c.x = c.x + left_over_width end
    end
  elseif self.justify == "center" then
    for i = 1, self.line_count do
      local characters = self:get_characters_in_line(i)
      local line_width = 0
      for _, c in ipairs(characters) do line_width = line_width + self.font:get_text_width(c.character) end
      local left_over_width = self.w - line_width
      local spaces_count = 0
      for _, c in ipairs(characters) do
        if c.character == " " then
          spaces_count = spaces_count + 1
        end
      end
      local added_width_to_each_space = math.floor(left_over_width/spaces_count)
      local total_added_width = 0
      for _, c in ipairs(characters) do
        if c.character == " " then
          c.x = c.x + added_width_to_each_space
          total_added_width = total_added_width + added_width_to_each_space
        else
          c.x = c.x + total_added_width
        end
      end
    end
  end
end


function Text:get_characters_in_line(line)
  local characters = {}
  for _, c in ipairs(self.characters) do
    if c.line == line then table.insert(characters, c) end
  end
  return characters
end


function Text:parse(text)
  local tags = {}
  for i, tags_text, j in text:gmatch("()%[(.-)%]()") do
    if tags_text == "" then
      table.insert(tags, {i = tonumber(i), j = tonumber(j)-1})
    else
      local local_tags = {}
      for tag in tags_text:gmatch("[%w_]+") do table.insert(local_tags, tag) end
      table.insert(tags, {i = tonumber(i), j = tonumber(j)-1, tags = local_tags})
    end
  end

  local characters = {}
  local current_tags = nil
  local current_line, current_col = 1, 1
  for i = 1, #text do
    local c = text:sub(i, i)
    local inside_tags = false
    for _, tag in ipairs(tags) do
      if i >= tag.i and i <= tag.j then
        inside_tags = true
        current_tags = tag.tags
        break
      end
    end
    if not inside_tags then
      table.insert(characters, {character = c, visible = true, tags = current_tags or {}})
    end
  end

  local raw_text = ""
  for _, character in ipairs(characters) do
    raw_text = raw_text .. character.character
  end
  return raw_text, characters
end


-- Sets the text's wrap width.
-- Any text that goes over this width will automatically be placed on the next line.
function Text:set_wrap_width(wrap_width)
  self.wrap_width = wrap_width
  return self
end


-- Sets the text's line height multiplier.
-- Lines are automatically placed vertically using the font's height for spacing, but you can increase or decrease this distance by setting this multiplier.
function Text:set_line_height_multiplier(m)
  self.line_height_multiplier = m or 1
  return self
end


-- Sets the text's font. By default texts use the global font.
function Text:set_font(font)
  self.font = font
  return self
end


-- Sets the justify behavior for the text.
-- Possible behaviors are: 'left', 'right', 'center' (justified)
function Text:set_justify(justify)
  self.justify = justify or "left"
  return self
end




-- The text tag objects to be used with text instances.
TextTag = Object:extend()
function TextTag:new(actions)
  self.actions = actions
end
