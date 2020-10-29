-- Steering behavior specific auxiliary functions, shouldn't really be used elsewhere
C2DMatrix = Object:extend()
function C2DMatrix:new()
  self._11, self._12, self._13 = 0, 0, 0
  self._21, self._22, self._23 = 0, 0, 0
  self._31, self._32, self._33 = 0, 0, 0
  self:identity()
end


function C2DMatrix:multiply(other)
  local mat_temp = C2DMatrix()
  mat_temp._11 = (self._11 * other._11) + (self._12 * other._21) + (self._13 * other._31);
  mat_temp._12 = (self._11 * other._12) + (self._12 * other._22) + (self._13 * other._32);
  mat_temp._13 = (self._11 * other._13) + (self._12 * other._23) + (self._13 * other._33);
  mat_temp._21 = (self._21 * other._11) + (self._22 * other._21) + (self._23 * other._31);
  mat_temp._22 = (self._21 * other._12) + (self._22 * other._22) + (self._23 * other._32);
  mat_temp._23 = (self._21 * other._13) + (self._22 * other._23) + (self._23 * other._33);
  mat_temp._31 = (self._31 * other._11) + (self._32 * other._21) + (self._33 * other._31);
  mat_temp._32 = (self._31 * other._12) + (self._32 * other._22) + (self._33 * other._32);
  mat_temp._33 = (self._31 * other._13) + (self._32 * other._23) + (self._33 * other._33);
  self._11 = mat_temp._11; self._12 = mat_temp._12; self._13 = mat_temp._13
  self._21 = mat_temp._21; self._22 = mat_temp._22; self._23 = mat_temp._23
  self._31 = mat_temp._31; self._32 = mat_temp._32; self._33 = mat_temp._33
end


function C2DMatrix:identity()
  self._11, self._12, self._13 = 1, 0, 0
  self._21, self._22, self._23 = 0, 1, 0
  self._31, self._32, self._33 = 0, 0, 1
end


function C2DMatrix:transform_vector(point)
  local temp_x = (self._11 * point.x) + (self._21 * point.y) + (self._31)
  local temp_y = (self._12 * point.x) + (self._22 * point.y) + (self._32)
  point.x, point.y = temp_x, temp_y
end


function C2DMatrix:translate(x, y)
  local mat = C2DMatrix()
  mat._11 = 1; mat._12 = 0; mat._13 = 0;
  mat._21 = 0; mat._22 = 1; mat._23 = 0;
  mat._31 = x; mat._32 = y; mat._33 = 1;
  self:multiply(mat)
end


function C2DMatrix:scale(sx, sy)
    local mat = C2DMatrix()
    mat._11 = sx; mat._12 = 0;  mat._13 = 0;
    mat._21 = 0;  mat._22 = sy; mat._23 = 0;
    mat._31 = 0;  mat._32 = 0;  mat._33 = 1;
    self:multiply(mat)
end


function C2DMatrix:rotate(fwd, side)
    local mat = C2DMatrix()
    mat._11 = fwd.x;  mat._12 = fwd.y;  mat._13 = 0;
    mat._21 = side.x; mat._22 = side.y; mat._23 = 0;
    mat._31 = 0;      mat._32 = 0;      mat._33 = 1;
    self:multiply(mat)
end


function C2DMatrix:rotater(r)
    local mat = C2DMatrix()
    local sin = math.sin(r)
    local cos = math.cos(r)
    mat._11 =  cos;  mat._12 = sin;  mat._13 = 0;
    mat._21 = -sin;  mat._22 = cos;  mat._23 = 0;
    mat._31 = 0;     mat._32 = 0;    mat._33 = 1;
    self:multiply(mat)
end


function point_to_world_space(point, heading, side, position)
  local trans_point = Vector(point.x, point.y)
  local mat_transform = C2DMatrix()
  mat_transform:rotate(heading, side)
  mat_transform:translate(position.x, position.y)
  mat_transform:transform_vector(trans_point)
  return trans_point
end


function point_to_local_space(point, heading, side, position)
  local trans_point = Vector(point.x, point.y)
  local mat_transform = C2DMatrix()
  local tx, ty = -position:dot(heading), -position:dot(side)
  mat_transform._11 = heading.x; mat_transform._12 = side.x;
  mat_transform._21 = heading.y; mat_transform._22 = side.y;
  mat_transform._31 = tx;        mat_transform._32 = ty;
  mat_transform:transform_vector(trans_point)
  return trans_point
end


function vector_to_world_space(v, heading, side)
  local trans_v = Vector(v.x, v.y)
  local mat_transform = C2DMatrix()
  mat_transform:rotate(heading, side)
  mat_transform:transform_vector(trans_v)
  return trans_v
end


function rotate_vector_around_origin(v, r)
  local mat = C2DMatrix()
  mat:rotater(r)
  mat:transform_vector(v)
  return v
end
