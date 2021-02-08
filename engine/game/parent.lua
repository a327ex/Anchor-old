Parent = Object:extend()


-- Follows the parent's transform exclusively.
-- This means that if the parent dies the entity also dies.
function Parent:follow_parent_exclusive()
  if self.parent and self.parent.dead then
    self.parent = nil
    self.dead = true
    return
  end
  self.x, self.y = self.parent.x, self.parent.y
  self.r = self.parent.r
  self.sx, self.sy = self.parent.sx, self.parent.sy
end
