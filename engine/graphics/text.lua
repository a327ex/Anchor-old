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
function Text:new(text_data, text_tags)
  self.timer = Timer()
  self.text_data = text_data
  self.text_tags = text_tags
  self:set_text(text_data)
  return self
end


function Text:update(dt)
  self.timer:update(dt)
  self:format_text()
  for _, line in ipairs(self.lines) do
    for i, c in ipairs(line.characters) do
      for k, v in pairs(self.text_tags) do
        for _, tag in ipairs(c.tags) do
          if tag == k then
            if v.actions.update then 
              v.actions.update(c, dt, i, self)
            end
          end
        end
      end
    end
  end
end


-- Draws the text object centered at the specified location.
function Text:draw(x, y)
  for _, line in ipairs(self.lines) do
    for i, c in ipairs(line.characters) do
      for k, v in pairs(self.text_tags) do
        for _, tag in ipairs(c.tags) do
          if tag == k then
            if v.actions.draw then
              v.actions.draw(c, i, self)
            end
          end
        end
      end
      graphics.print(c.character, line.font, x + c.x - self.w/2, y + c.y - self.h/2, c.r or 0, c.sx or 1, c.sy or c.sx or 1, c.ox or 0, c.oy or 0)
      graphics.set_color(white)
    end
  end
end


function Text:format_text()
  self.w = 0
  for i, line in ipairs(self.lines) do
    local line_width = math.max(line.font:get_text_width(line.raw_text), line.alignment_width or 0)
    if line_width > self.w then
      self.w = line_width
    end
  end

  local x, y = 0, 0
  for j, line in ipairs(self.lines) do
    local h = (line.font.h*(line.height_multiplier or 1) + (line.height_offset or 0))*(line.sy or 1)
    for i, c in ipairs(line.characters) do
      c.x = x
      c.y = y
      c.sx = line.sx or 1
      c.sy = line.sy or 1
      x = x + line.font:get_text_width(c.character)
    end
    y = y + h
    x = 0
  end
  self.h = y

  for i, line in ipairs(self.lines) do
    if line.alignment == "right" then
      local text_width = 0
      for _, c in ipairs(line.characters) do text_width = text_width + line.font:get_text_width(c.character) end
      local left_over_width = self.w - (line.alignment_width or text_width)
      for _, c in ipairs(line.characters) do c.x = c.x + left_over_width end

    elseif line.alignment == "center" then
      local text_width = 0
      for _, c in ipairs(line.characters) do text_width = text_width + line.font:get_text_width(c.character) end
      local left_over_width = self.w - (line.alignment_width or text_width)
      for _, c in ipairs(line.characters) do c.x = c.x + left_over_width/2 end

    elseif line.alignment == "justified" then
      local text_width = 0
      for _, c in ipairs(line.characters) do text_width = text_width + line.font:get_text_width(c.character) end
      local left_over_width = self.w - (line.alignment_width or text_width)
      local spaces_count = 0
      for _, c in ipairs(line.characters) do
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


function Text:parse(text_data)
  for _, line in ipairs(text_data) do
    local tags = {}
    for i, tags_text, j in line.text:gmatch("()%[(.-)%]()") do
      if tags_text == "" then
        table.insert(tags, {i = tonumber(i), j = tonumber(j)-1})
        line.tags = tags
      else
        local local_tags = {}
        for tag in tags_text:gmatch("[%w_]+") do table.insert(local_tags, tag) end
        table.insert(tags, {i = tonumber(i), j = tonumber(j)-1, tags = local_tags})
        line.tags = tags
      end
    end
    if not line.tags then line.tags = {} end
  end

  for _, line in ipairs(text_data) do
    line.characters = {}
    local current_tags = nil
    for i = 1, #line.text do
      local c = line.text:sub(i, i)
      local inside_tags = false
      for _, tag in ipairs(line.tags) do
        if i >= tag.i and i <= tag.j then
          inside_tags = true
          current_tags = tag.tags
          break
        end
      end
      if not inside_tags then
        table.insert(line.characters, {character = c, visible = true, tags = current_tags or {}})
      end
    end
  end

  for _, line in ipairs(text_data) do
    local raw_text = ""
    for _, character in ipairs(line.characters) do
      raw_text = raw_text .. character.character
    end
    line.raw_text = raw_text
  end

  return text_data
end


-- Sets new text.
-- Reapplies all modifications (wrap width, justification, etc).
function Text:set_text(text_data)
  self.lines = self:parse(text_data)
  self:format_text()
  for _, line in ipairs(self.lines) do
    for i, c in ipairs(line.characters) do
      for k, v in pairs(self.text_tags) do
        for _, tag in ipairs(c.tags) do
          if tag == k then
            if v.actions.init then
              v.actions.init(c, i, self)
            end
          end
        end
      end
    end
  end
end


-- Sets the line's alignment width.
-- This is used to align the text according to the alignment option
-- For instance, if the alignment width is 200 and the alignment is 'right', then the right edge used for this alignment will be 200 units to the right
function Text:set_alignment_width(line, alignment_width)
  self.alignment_width = alignment_width
  self:format_text()
  return self
end


-- Sets the text's line height.
-- Lines are automatically placed vertically using the font's height for spacing, but you can increase or decrease this distance by setting these values.
function Text:set_line_height_data(line, offset, multiplier)
  self.lines[line].height_offset = offset or 0
  self.lines[line].height_multiplier = multiplier or 1
  self:format_text()
  return self
end


-- Sets the text's font. By default texts use the global font.
function Text:set_font(line, font)
  self.lines[line].font = font
  self:format_text()
  return self
end


-- Sets the alignment behavior for the given line.
-- Possible behaviors are: 'right', 'center' and 'justified'
function Text:set_alignment(line, alignment)
  self.lines[line].alignment = alignment
  self:format_text()
  return self
end


-- The text tag objects to be used with text instances.
TextTag = Object:extend()
function TextTag:new(actions)
  self.actions = actions
end
