-- The Group class is responsible for object management.
-- As mentioned in the state file, you'll probably at least want to use this class if not Game/State ones, as it provides access to a lot of functionality from the engine.
-- A common usage is to create different groups for different "layers" of behavior in the game, and also to create them inside one of your states, for instance:
--[[
Arena = Object:extend()
Arena:implement(State)
function Arena:new(name, opts) self:new_state(name, opts) end

function Arena:on_enter()
  self.main = Group(game.camera):set_as_physics_world(192)
  self.effects = Group(game.camera)
  self.floor = Group(game.camera)
  self.ui = Group()
end


function Arena:update(dt)
  self.main:update(dt)
  self.floor:update(dt)
  self.effects:update(dt)
  self.ui:update(dt)
end


function Arena:draw()
  self.floor:draw()
  self.main:sort_by_y()
  self.main:draw()
  self.effects:draw()
  self.ui:draw()
end
]]--

-- This is a simple example where you have four groups, each for a different purpose.
-- The main group is where all gameplay objects are and thus the only one that's using box2d.
-- If you need an object to collide with another physically then they have to use the same physics world, and thus also the same group.
-- The effects and floor groups are purely visual, one for drawing things on the floor (it's a top-down-ish 2.5D game), like shadows, and the other for drawing visual effects on top of everything else.
-- As you can see in the draw function, floor is drawn first and effects is drawn after all gameplay objects.
-- These three groups above also all use the game's main camera instance as their drawing targets since we want gameplay objects, floor and visual effects to be drawn according to the camera's transform.
-- Finally, the UI group is the one that doesn't have a camera attached to it because we want its objects to be drawn in fixed locations on the screen.
-- And this group is also drawn last because generally UI elements go on top of literally everything else.
Group = Object:extend()
function Group:new(camera, w, h)
  self.timer = Timer()
  self.camera = camera
  self.objects = {}
  self.objects.by_id = {}
  self.objects.by_class = {}
  self.cells = {}
  self.cell_size = 128
  return self
end


function Group:update(dt)
  for _, object in ipairs(self.objects) do object:update(dt) end
  if self.world then self.world:update(dt) end

  self.cells = {}
  for _, object in ipairs(self.objects) do
    local cx, cy = math.floor(object.x/self.cell_size), math.floor(object.y/self.cell_size)
    if not self.cells[cx] then self.cells[cx] = {} end
    if not self.cells[cx][cy] then self.cells[cx][cy] = {} end
    table.insert(self.cells[cx][cy], object)
  end

  for i = #self.objects, 1, -1 do
    if self.objects[i].dead then
      if self.objects[i].destroy then self.objects[i]:destroy() end
      self.objects.by_id[self.objects[i].id] = nil
      if moonscript then table.delete(self.objects.by_class[self.objects[i].__class], function(v) return v.id == object.id end)
      else table.delete(self.objects.by_class[getmetatable(self.objects[i])], function(v) return v.id == object.id end) end
      table.remove(self.objects, i)
    end
  end
end


function Group:draw(scroll_factor_x, scroll_factor_y)
  if self.camera then self.camera:attach(scroll_factor_x, scroll_factor_y) end
    for _, object in ipairs(self.objects) do object:draw() end
  if self.camera then self.camera:detach() end
end


-- Draws only objects within the indexed range
-- group:draw_range(1, 3) -> draws only 1st, 2nd and 3rd objects in this group
function Group:draw_range(i, j, scroll_factor_x, scroll_factor_y)
  if self.camera then self.camera:attach(scroll_factor_x, scroll_factor_y) end
    for k = i, j do self.objects[k]:draw() end
  if self.camera then self.camera:detach() end
end


-- Draws only objects of a certain class
-- group:draw_class(Solid) -> draws only objects of the Solid class
function Group:draw_class(class, scroll_factor_x, scroll_factor_y)
  if self.camera then self.camera:attach(scroll_factor_x, scroll_factor_y) end
    for _, object in ipairs(self.objects) do
      if moonscript then
        if object.__class == class then
          object:draw()
        end
      else
        if object:is(class) then
          object:draw()
        end
      end
    end
  if self.camera then self.camera:detach() end
end


-- Draws all objects except those of specified classes
-- group:draw_all_except({Solid, SolidGeometry}) -> draws all objects except those of the Solid and SolidGeometry classes
function Group:draw_all_except(classes, scroll_factor_x, scroll_factor_y)
  if self.camera then self.camera:attach(scroll_factor_x, scroll_factor_y) end
    for _, object in ipairs(self.objects) do
      if not table.any(classes, function(v) if moonscript then return object.__class == v else return object:is(v) end end) then
        object:draw()
      end
    end
  if self.camera then self.camera:detach() end
end


-- Sorts all objects in this group by their y position
-- This is useful for top-down 2.5D games so that objects further up on the screen are drawn first and look like they're further away from the camera
-- Objects can additionally have a .y_sort_offset attribute which gets added to this function's calculations
-- This attribute is useful for objects that are longer vertically and need some adjusting otherwise the point at which they get drawn behind looks off
function Group:sort_by_y()
  table.sort(self.objects, function(a, b) return (a.y + (a.y_sort_offset or 0)) < (b.y + (b.y_sort_offset or 0)) end)
end


-- Returns the mouse position based on the camera used by this group
-- mx, my = group:get_mouse_position() 
function Group:get_mouse_position()
  if self.camera then
    return self.camera.mouse.x, self.camera.mouse.y
  else
    local mx, my = love.mouse.getPosition()
    return mx/config.game_sx, my/config.game_sy
  end
end


function Group:destroy()
  for _, object in ipairs(self.objects) do object:destroy() end
  self.objects = {}
  self.objects.by_id = {}
  self.objects.by_class = {}
  if self.world then
    self.world:destroy()
    self.world = nil
  end
  return self
end


-- Adds an existing object to the game
-- player = Player(group, 160, 80)
-- group:add_object(player)
-- The object has its .group attribute set to this group, and has a random .id set if it doesn't already have one
-- This function is automatically called when a GameObject is created, so it doesn't actually need to be called ever
function Group:add_object(object)
  local class = getmetatable(object)
  if moonscript then class = object.__class end
  object.group = self
  if not object.id then object.id = random:uid() end
  self.objects.by_id[object.id] = object
  if not self.objects.by_class[class] then self.objects.by_class[class] = {} end
  table.insert(self.objects.by_class[class], object)
  table.insert(self.objects, object)
  return object
end


-- Returns an object by its unique id
-- group:get_object_by_id(id) -> the object
function Group:get_object_by_id(id)
  return self.objects.by_id[id]
end


-- Returns all objects of a specific class
-- group:get_object_by_class(Star) -> all objects of class Star in a table
function Group:get_objects_by_class(class)
  if not self.objects.by_class[class] then return {}
  else return table.shallow_copy(self.objects.by_class[class]) end
end


-- Returns all objects inside the shape, using its .x, .y attributes as the center and its .w, .h attributes as its bounding size.
-- If object_types is passed in then it only returns object of those classes.
-- The bounding size is used to select objects quickly and roughly, and then more specific and expensive collision methods are run on the objects returned from that selection.
-- group:get_objects_in_shape(Rectangle(player.x, player.y, 100, 100, player.r), {Enemy1, Enemy2}) -> all Enemy1 and Enemy2 instances in a 100x100 rotated rectangle around the player
function Group:get_objects_in_shape(shape, object_types)
  local out = {}
  local cx1, cy1 = math.floor((shape.x-shape.w)/self.cell_size), math.floor((shape.y-shape.h)/self.cell_size)
  local cx2, cy2 = math.floor((shape.x+shape.w)/self.cell_size), math.floor((shape.y+shape.h)/self.cell_size)
  for i = cx1, cx2 do
    for j = cy1, cy2 do
      local cx, cy = i, j
      if self.cells[cx] then
        local cell_objects = self.cells[cx][cy]
        if cell_objects then
          for _, object in ipairs(cell_objects) do
            if object_types then
              if table.any(object_types, function(v) if moonscript then return object.__class == v else return object:is(v) end end) and object.shape and object.shape:is_colliding_with_shape(shape) then
                table.insert(out, object)
              end
            else
              if object.shape and object:is_colliding_with_shape(shape) then
                table.insert(out, object)
              end
            end
          end
        end
      end
    end
  end
  return out
end


-- Returns the closest object in this group to the object passed in
-- Optionally also pass in a function which will only allow objects that pass its test to be considered in the calculations
-- group:get_closest_object(player) -> closest object to the player, if the player is in this group then this object will be the player itself
-- group:get_closest_object(player, function(o) return o.id ~= player.id end) -> closest object to the player that isn't the player
function Group:get_closest_object(object, select_function)
  if not select_function then select_function = function(o) return true end end
  local min_distance, min_index = 100000, 0
  for i, o in ipairs(self.objects) do
    if select_function(o) then
      local d = math.distance(o.x, o.y, object.x, object.y)
      if d < min_distance then
        min_distance = d
        min_index = i
      end
    end
  end
  return self.objects[min_index]
end


-- Sets this group as a physics box2d world
-- This means that objects inserted here can also be initialized as physics objects (see the gameobject file for more on this)
-- group:set_as_physics_world(192, 0, 400) -> a common platformer setup with vertical downward gravity
-- group:set_as_physics_world(192) -> a common setup for most non-platformer games
-- If your game takes place in smaller world coordinates (i.e. you set game_width and game_height to 320x240 or something) then you'll want smaller meter values, like 32 instead of 192
-- Read more on meter values for box2d worlds here: https://love2d.org/wiki/love.physics.setMeter
-- The last argument, tags, is a list of strings corresponding to collision tags that will be assigned to different objects, for instance:
-- group:set_as_physics_world(192, 0, 0, {'player', 'enemy', 'projectile', 'ghost'})
-- As different physics objects have different collision behaviors in regards to one another, the tags created here will facilitate the delineation of those differences.
function Group:set_as_physics_world(meter, xg, yg, tags)
  love.physics.setMeter(meter or 192)
  self.tags = table.unify(table.push(tags, 'solid'))
  self.collision_tags = {}
  self.trigger_tags = {}
  for i, tag in ipairs(self.tags) do
    self.collision_tags[tag] = {category = i, masks = {}}
    self.trigger_tags[tag] = {category = i, triggers = {}}
  end

  self.world = love.physics.newWorld(xg or 0, yg or 0)
  self.world:setCallbacks(
    function(fa, fb, c)
      local oa, ob = self:get_object_by_id(fa:getUserData()), self:get_object_by_id(fb:getUserData())
      if fa:isSensor() or fb:isSensor() then
        if fa:isSensor() then if oa.on_trigger_enter then oa:on_trigger_enter(ob, c) end end
        if fb:isSensor() then if ob.on_trigger_enter then ob:on_trigger_enter(oa, c) end end
      else
        if oa.on_collision_enter then oa:on_collision_enter(ob, c) end
        if ob.on_collision_enter then ob:on_collision_enter(oa, c) end
      end
    end,
    function(fa, fb, c)
      local oa, ob = self:get_object_by_id(fa:getUserData()), self:get_object_by_id(fb:getUserData())
      if fa:isSensor() or fb:isSensor() then
        if fa:isSensor() then if oa.on_trigger_exit then oa:on_trigger_exit(ob, c) end end
        if fb:isSensor() then if ob.on_trigger_exit then ob:on_trigger_exit(oa, c) end end
      else
        if oa.on_collision_exit then oa:on_collision_exit(ob, c) end
        if ob.on_collision_exit then ob:on_collision_exit(oa, c) end
      end
    end
  )
  return self
end


-- Enables physical collision between objects of two tags
-- on_collision_enter and on_collision_exit callbacks will be called when objects of these two tags physically collide
-- By default, every object physically collides with every other object
-- group:set_as_physics_world(192, 0, 0, {'player', 'enemy', 'projectile', 'ghost', 'solid'})
-- group:enable_collision_between('player', 'enemy')
function Group:enable_collision_between(tag1, tag2)
  table.delete(self.collision_tags[tag1].masks, self.collision_tags[tag2].category)
end


-- Disables physical collision between objects of two tags
-- on_collision_enter and on_collision_exit callbacks will NOT be called when objects of these two tags pass through each other
-- group:set_as_physics_world(192, 0, 0, {'player', 'enemy', 'projectile', 'ghost', 'solid'})
-- group:disable_collision_between('ghost', 'solid')
-- group:disable_collision_between('player', 'projectile')
function Group:disable_collision_between(tag1, tag2)
  table.insert(self.collision_tags[tag1].masks, self.collision_tags[tag2].category)
end


-- Enables trigger collision between objects of two tags
-- When objects have physical collision disabled between one another, you might still want to have the engine generate enter and exit events when they start/stop overlapping
-- This is the function that makes that happen
-- group:set_as_physics_world(192, 0, 0, {'player', 'enemy', 'projectile', 'ghost', 'solid'})
-- group:disable_collision_between('ghost', 'solid')
-- group:enable_trigger_between('ghost', 'solid') -> now when a ghost passes through a solid, on_trigger_enter and on_trigger_exit will be called
function Group:enable_trigger_between(tag1, tag2)
  table.insert(self.trigger_tags[tag1].triggers, self.trigger_tags[tag2].category)
end


-- Disables trigger collision between objects of two tags
-- This will only work if enable_trigger_between has been called for a pair of tags
-- In general you shouldn't use this, as trigger collisions are disabled by default for all objects
function Group:disable_trigger_between(tag1, tag2)
  table.delete(self.trigger_tags[tag1].triggers, self.trigger_tags[tag2].category)
end


-- Returns a table of all physics objects that collide with the segment passed in
-- This requires that the group is set as a physics world first and only works on objects initialized as physics objects (see gameobject file)
-- This function returns a table of hits, each hit is of the following format: {
--   x = hit's x position, y = hit's y position,
--   nx = hit's x normal, ny = hit's y normal,
--   fraction = a number from 0 to 1 representing the fraction of the segment where the hit happened,
--   other = the object hit by the segment
-- }
-- So if the following call group:raycast(100, 100, 800 800) hits 3 objects, it will return something like this: {
--   [1] = {x = ..., y = ..., nx = ..., ny = ..., fraction = ..., other = the 1st object hit},
--   [2] = {x = ..., y = ..., nx = ..., ny = ..., fraction = ..., other = the 2nd object hit},
--   [3] = {x = ..., y = ..., nx = ..., ny = ..., fraction = ..., other = the 3rd object hit},
-- }
-- Where ... just stands for some number.
function Group:raycast(x1, y1, x2, y2)
  if not self.world then return end

  self.raycast_hitlist = {}
  self.world:rayCast(x1, y1, x2, y2, function(fixture, x, y, nx, ny, fraction)
    local hit = {}
    hit.fixture = fixture
    hit.x, hit.y = x, y
    hit.nx, hit.ny = nx, ny
    hit.fraction = fraction
    table.insert(self.raycast_hitlist, hit)
    return 1
  end)

  local hits = {}
  for _, hit in ipairs(self.raycast_hitlist) do
    local obj = self:get_object_by_id(hit.fixture:getUserData())
    hit.fixture = nil
    hit.other = obj
    table.insert(hits, hit)
  end

  return hits
end
