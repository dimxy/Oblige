----------------------------------------------------------------
-- BUILDER
----------------------------------------------------------------
--
--  Oblige Level Maker (C) 2006,2007 Andrew Apted
--
--  This program is free software; you can redistribute it and/or
--  modify it under the terms of the GNU General Public License
--  as published by the Free Software Foundation; either version 2
--  of the License, or (at your option) any later version.
--
--  This program is distributed in the hope that it will be useful,
--  but WITHOUT ANY WARRANTY; without even the implied warranty of
--  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
--  GNU General Public License for more details.
--
----------------------------------------------------------------


function copy_block(B, ...)
  local result = copy_table(B)

  result.things = {}
  
  -- copy the overrides and corner adjustments
  for i = 1,9 do
    if B[i] then result[i] = copy_table(B[i]) end
  end

  return result
end

function copy_block_with_new(B, newbie, ...)
  local result = copy_block(B)
  merge_table(result, newbie, ...)
  return result
end


function side_to_chunk(side)
  if side == 2 then return 2, 1 end
  if side == 8 then return 2, 3 end
  if side == 4 then return 1, 2 end
  if side == 6 then return 3, 2 end
  error ("side_to_chunk: bad side " .. side)
end

---###  function side_to_corner(side, W, H)
---###    if side == 2 then return 1,1, W,1 end
---###    if side == 8 then return 1,H, W,H end
---###    if side == 4 then return 1,1, 1,H end
---###    if side == 6 then return W,1, W,H end
---###    error ("side_to_corner: bad side " .. side)
---###  end

function dir_to_corner(dir, W, H)
  if dir == 1 then return 1,1 end
  if dir == 3 then return W,1 end
  if dir == 7 then return 1,H end
  if dir == 9 then return W,H end
  error ("dir_to_corner: bad dir " .. dir)
end

function block_to_chunk(bx)
  return 1 + int((bx-1) * KW / BW)
end

function chunk_to_block(kx)
  return 1 + int((kx-1) * BW / KW)
end

function new_chunk(c, kx, ky, kind, value)
  return
  {
    [kind] = value or true,

    x1 = c.bx1-1 + chunk_to_block(kx),
    y1 = c.by1-1 + chunk_to_block(ky),
    x2 = c.bx1-1 + chunk_to_block(kx + 1) - 1,
    y2 = c.by1-1 + chunk_to_block(ky + 1) - 1,
  }
end

function copy_chunk(c, kx, ky, K)

  assert(not K.vista)

  local COPY = new_chunk(c, kx, ky, "is_copy")

  COPY.room = K.room
  COPY.void = K.void
  COPY.link = K.link
  COPY.cage = K.cage
  COPY.liquid = K.liquid
  COPY.closet = K.closet
  COPY.place  = K.place

  if K.rmodel then
    COPY.rmodel = copy_block(K.rmodel)
  end

  return COPY
end

function chunk_touches_side(kx, ky, side)
  if side == 4 then return kx == 1 end
  if side == 6 then return kx == 3 end
  if side == 2 then return ky == 1 end
  if side == 8 then return ky == 3 end
end

function valid_chunk(kx,ky)
  return 1 <= kx and kx <= KW and
         1 <= ky and ky <= KH
end

function is_roomy(cell, chunk)
  if not chunk then return false end
  if chunk.link then
    return chunk.link.build == cell
  end
  return chunk.room
end

function random_where(link)

  local LINK_WHERES = { 15, 40, 15, 90, 15, 40, 15 }

  for zzz,c in ipairs(link.cells) do
    if c.hallway then return 0 end
    if c.small_exit then return 0 end
  end

  if (link.kind == "door" and rand_odds(4)) or
     (link.kind ~= "door" and rand_odds(15))
  then
    return "double";
  end

  if (link.kind == "arch" and rand_odds(15)) or
     (link.kind == "falloff" and rand_odds(80))
  then
    return "wide";
  end

  if link.kind == "falloff" then return 0 end

  return rand_index_by_probs(LINK_WHERES) - 4
end


function show_blocks(cell) -- FIXME
  assert(cell.blocks)
  for y = BH,1,-1 do
    for x = 1,BW do
      local B = cell.blocks[x][y]
      con.printf(B and (B.fragments and "%" or
                      (B.sector and "/" or "#")) or ".")
    end
    con.printf("\n")
  end
end

function show_fragments(block)
  assert(block.fragments)
  for y = FH,1,-1 do
    for x = 1,FW do
      local fg = block.fragments[x][y]
      con.printf(fg and (fg.sector and "/" or "#") or ".")
    end
    con.printf("\n")
  end
end


function fill(p, c, sx, sy, ex, ey, B, B2)
  if sx > ex then sx, ex = ex, sx end
  if sy > ey then sy, ey = ey, sy end
  for x = sx,ex do
    for y = sy,ey do
      assert(valid_block(p, x, y))

      local N = copy_block(B)
      p.blocks[x][y] = N

      if B2 then
        merge_table(N, B2)
      end

      N.mark = N.mark or c.mark
    end
  end
end

function c_fill(p, c, sx, sy, ex, ey, B, B2)

  fill(p,c, c.bx1-1+sx, c.by1-1+sy, c.bx1-1+ex, c.by1-1+ey, B, B2)
end

function gap_fill(p, c, sx, sy, ex, ey, B, B2)
  if sx > ex then sx, ex = ex, sx end
  if sy > ey then sy, ey = ey, sy end
  for x = sx,ex do
    for y = sy,ey do

      assert(valid_block(p, x, y))

      if not p.blocks[x][y] then
        fill(p,c, x,y, x,y, B, B2)
      end
    end
  end
end

function frag_fill(p, c, sx, sy, ex, ey, F, F2)

  if sx > ex then sx, ex = ex, sx end
  if sy > ey then sy, ey = ey, sy end
  for x = sx,ex do
    for y = sy,ey do
      local bx, fx = div_mod(x, FW)
      local by, fy = div_mod(y, FH)
      
      if not p.blocks[bx][by] then
        p.blocks[bx][by] = {}
      end

      local B = p.blocks[bx][by]
      B.solid = nil

      if not B.fragments then
        B.fragments = array_2D(FW, FH)
      end

      local N = copy_block(F)
      B.fragments[fx][fy] = N

      if F2 then merge_table(N, F2) end

      N.mark = N.mark or c.mark
    end
  end
end


function move_corner(p,c, x,y,corner, dx,dy)

  local B = p.blocks[x][y]
  assert(B)

  if not B[corner] then
    B[corner] = {}
  else
    dx = dx + (B[corner].dx or 0)
    dy = dy + (B[corner].dy or 0)
  end

  B[corner].dx = dx
  B[corner].dy = dy

  -- ensure that the writer doesn't swallow up this block
  -- (which would lose the vertex we want to move)
  B.mark = allocate_mark(p)
end

-- the c_ prefix means (x,y) are cell-relative coords
function c_move_frag_corner(p,c, x,y,corner, dx,dy)

  local bx, fx = div_mod(x, FW)
  local by, fy = div_mod(y, FH)

  local B = p.blocks[c.bx1-1+bx][c.by1-1+by]
  assert(B)
  assert(B.fragments)

  local F = B.fragments[fx][fy]
  assert(F)

  if not F[corner] then
    F[corner] = {}
  else
    dx = dx + (F[corner].dx or 0)
    dy = dy + (F[corner].dy or 0)
  end

  F[corner].dx = dx
  F[corner].dy = dy

  F.mark = allocate_mark(p)
end

 
-- convert 'where' value into block position
function where_to_block(wh, long)

  if wh == 0 then return JW+1 end

  if wh == -1 then return 3 end -- FIXME: not best place
  if wh == -2 then return 2 end -- FIXME
  if wh == -3 then return 1 end
  
  if wh == 1 then return BW-1 - long end -- FIXME
  if wh == 2 then return BW   - long end -- FIXME
  if wh == 3 then return BW+1 - long end

  error("bad where value: " .. tostring(wh))
end


function scale_block(B, scale)
  -- Note: doesn't set x_offsets
  scale = (scale - 1) * 32
  B[1] = { dx=-scale, dy=-scale }
  B[3] = { dx= scale, dy=-scale }
  B[7] = { dx=-scale, dy= scale }
  B[9] = { dx= scale, dy= scale }
end

function rotate_block(B, d)
  -- Note: doesn't set x_offsets
  B[1] = { dx= 32, dy= -d }
  B[3] = { dx=  d, dy= 32 }
  B[9] = { dx=-32, dy=  d }
  B[7] = { dx= -d, dy=-32 }
end


function B_prefab(p, c, fab, skin, parm, theme, x,y,z, dir)

  -- (x,y) is always the lowest coordinate
  -- dir == 8 is the natural mode, other values rotate it

  local deep = #fab.structure
  local long = #fab.structure[1]

  local bk_deep = int((3+deep) / 4)
  local bk_long = int((3+long) / 4)

  local WALL = { solid="wall" }
  local ROOM = { }

  local function f_coords(ex, ey)
        if dir == 2 then ex,ey = long+1-ex, deep+1-ey
    elseif dir == 4 then ex,ey = deep+1-ey, ex
    elseif dir == 6 then ex,ey =        ey, long+1-ex
    end
  
    local fx = 1 + (x-1)*FW + ex - 1
    local fy = 1 + (y-1)*FH + ey - 1

    return fx, fy
  end

  local function skin_val(key)
    local V = skin[key]
    if not V then V = theme[key] end
    if not V then
      error("Bad fab/skin combo: missing data for " .. key)
    end
    return V
  end

  local function parm_val(key)
    local V = parm[key]
    if not V then V = c.rmodel[key] end
    if not V then
      error("Bad fab/parameters: missing value for " .. key)
    end
    return V
  end

  local function what_h_ref(base, rel, h)

    local result = base

    if rel then
      if not parm[rel] then
        error("Missing f/c relative value: " .. rel)
      end
      result = parm[rel]
    end

    if h then result = result + h end

    return result
  end

  local function what_tex(base, key)
    if skin[key] then return skin[key] end
    if skin[base] then return skin[base] end
    assert(theme[base])
    return theme[base]
  end

  local function elem_fill(elem, fx, fy)

    local overrides  -- FIXME

    if elem.solid then

      frag_fill (p,c, fx,fy, fx,fy,
           { solid=what_tex("wall", elem.solid) })
    else
      local sec = copy_block(c.rmodel)

      sec.f_h = what_h_ref(sec.f_h, elem.f_rel, elem.f_h)
      sec.c_h = what_h_ref(sec.c_h, elem.c_rel, elem.c_h)

      sec.f_tex = what_tex("floor", elem.f_tex)
      sec.c_tex = what_tex("ceil", elem.c_tex)

      sec.l_tex = what_tex("wall", elem.l_tex)
      sec.u_tex = what_tex("wall", elem.u_tex)

      if elem.kind then sec[elem.kind] = parm_val(elem.kind) end
      if elem.tag  then sec.tag = parm_val("tag") end

      if elem.light then sec.light = elem.light end

      frag_fill (p,c, fx,fy, fx,fy, sec)
    end
  end

  for ey = 1,deep do for ex = 1,long do
    local fx, fy = f_coords(ex,ey)

    local e = string.sub(fab.structure[deep+1-ey], ex, ex)
    local elem

        if e == "#" then elem = WALL; assert(elem)
    elseif e == "." then elem = ROOM; assert(elem)
    else
      elem = fab.elements[e]

      if not elem then
        error("Unknown element '" .. e .. "' in Prefab")
      end
    end

    elem_fill(elem, f_coords(ex, ey))
  end end
end


--
-- Build a door.
-- 
-- Valid sizes (long x deep) are:
--    4x3  4x2  4x1
--    3x3  3x2  3x1
--    2x3  2x2  2x1
--
function B_door(p, c, link, b_theme, x,y,z, dir, long,deep, door_info,
                kind,tag, key_tex)
 
  local high = door_info.h
  
  local dx, dy = dir_to_delta(dir)
  local ax, ay = dir_to_across(dir)
  local adir = delta_to_dir(ax, ay)

  assert (link.kind == "door")

  local wall_tex = b_theme.wall
  local track_tex = door_info.track or THEME.mats.TRACK.wall
  local door_tex = door_info.wall
  local side_tex
  local ceil_tex = THEME.mats.DOOR_FRAME.floor

  if key_tex then
    side_tex = nil
  else
    key_tex  = wall_tex
    side_tex = THEME.mats.DOOR_FRAME.wall -- can be nil
  end

  if deep >= 2 then
--    side_tex = key_tex
--    ceil_tex = door_info.ceil_tex or THEME.mats.DOOR_FRAME.ceil
  end

  local DOOR = { f_h = z+8, c_h = z+8,
                 f_tex = door_info.frame_floor or THEME.mats.DOOR_FRAME.floor,
                 c_tex = door_info.ceil        or THEME.mats.DOOR_FRAME.floor,
                 light = 255,
                 l_tex = door_tex,
                 u_tex = door_tex,
                 door_kind = kind,
                 tag = tag,
                 [dir]  = { u_peg="bottom" }, [10-dir]  = { u_peg="bottom" },
                 [adir] = { l_peg="bottom" }, [10-adir] = { l_peg="bottom" }, -- TRACK
                 }

  local STEP = { f_h = z+8, c_h = z+8 + door_info.h,
                    f_tex = DOOR.f_tex,
                    c_tex = door_info.frame_ceil or THEME.mats.DOOR_FRAME.ceil,
                    light=224,
                    l_tex = door_info.step or c.theme.step or THEME.mats.STEP.wall,
                    u_tex = wall_tex,
                    [dir] = { l_peg="top" },
                    [10-dir] = { l_peg="top" },
                    }

  -- block based door (big 'n bulky)

  if long >= 3 and deep == 3 then

    local zx, zy = (long-1)*ax, (long-1)*ay
    local ex, ey = (long-2)*ax, (long-2)*ay

    fill (p,c, x,   y,    x+zx,y+zy, { solid=key_tex })
    fill (p,c, x+ax,y+ay, x+ex,y+ey, STEP )
    x = x + dx; y = y + dy

    fill (p,c, x,   y,    x+zx,y+zy, { solid=wall_tex })
    fill (p,c, x+ax,y+ay, x+ex,y+ey, DOOR)
    x = x + dx; y = y + dy

    fill (p,c, x,   y,    x+zx,y+zy, { solid=key_tex })
    fill (p,c, x+ax,y+ay, x+ex,y+ey, STEP )

    return
  end

  -- fragment based doors --

  local fx = 1 + (x-1)*FW
  local fy = 1 + (y-1)*FH

  if (dir == 4) then fx = fx + FW - 1 end
  if (dir == 2) then fy = fy + FH - 1 end

  if long >= 2 and deep <= 2 then

    local step = 1 + (deep - 1) * 2
    assert(step * 2 + 2 == deep * FW)

    local side = (long == 4) and 4 or 2
    long = long * 4 - side * 2
    assert(long == 4 or long == 8)

    local ex, ey = ax*(long+1), ay*(long+1)
    local zx, zy = ax*(long+side+1), ay*(long+side+1)

    local sx, sy = ax*side, ay*side

    -- align inner sides with outside wall
    local y_diff = link_other(link, c).ceil_h - STEP.c_h
    local far = deep * FW - 1

    local override

    if side_tex then
      override =
      {
        l_tex = side_tex,
        y_offset = y_diff
      }
    end

    frag_fill (p,c, fx,fy, fx+sx+dx*far,fy+zy-sy+dy*far,
      { solid=key_tex, [adir] = override })
    frag_fill (p,c, fx+zx-sx,fy+zy-sy, fx+zx+dx*far,fy+zy+dy*far, 
      { solid=key_tex, [10-adir] = override })

    for ff = 1,step do
      frag_fill (p,c, fx+sx,fy+sy, fx+ex,fy+ey, STEP)
      fx = fx + dx; fy = fy + dy
    end

    for mm = 1,2 do
      frag_fill (p,c, fx+ax,fy+ay, fx+zx-ax,fy+zy-ay, { solid=track_tex })
      frag_fill (p,c, fx+sx,fy+sy, fx+ex,fy+ey, DOOR)
      fx = fx + dx; fy = fy + dy
    end

    for bb = 1,step do
      frag_fill (p,c, fx+sx,fy+sy, fx+ex,fy+ey, STEP)
      fx = fx + dx; fy = fy + dy
    end

    return
  end

  error("UNIMPLEMENTED DOOR " .. long .. "x" .. deep)
end


function B_exit_door(p,c, theme, link, x,y,z, dir)
 
  assert (link.kind == "door")

  local door_info = theme.door
  assert(door_info)

  local door_w = int(door_info.w / 64)

  local long = link.long or (1 + door_w)
  local deep = 2
  local high = 72  -- FIXME: pass in "door_info"

---###  if theme.front_mark then long = long + 1 end -- FIXME: sync with link.long

  local dx, dy = dir_to_delta(dir)
  local ax, ay = dir_to_across(dir)
  local adir = delta_to_dir(ax, ay)

  local wall_tex = theme.wall
  local door_tex = door_info.wall
  local key_tex  = door_info.wall
  local track_tex = door_info.track or THEME.mats.TRACK.wall

  local DOOR = { f_h = z+8, c_h = z+8,
                 f_tex = door_info.frame_floor or THEME.mats.DOOR_FRAME.floor,
                 c_tex = door_info.ceil        or THEME.mats.DOOR_FRAME.floor,
                 light = 255,
                 door_kind = 1,
                 l_tex = theme.wall,
                 u_tex = door_tex,
                 [dir]  = { u_peg="bottom" }, [10-dir]  = { u_peg="bottom" },
                 [adir] = { l_peg="bottom" }, [10-adir] = { l_peg="bottom" }, -- TRACK
               }

  local STEP = { f_h = z+8, c_h = z+8+high,
                    f_tex = DOOR.f_tex,
                    c_tex = door_info.frame_ceil or DOOR.f_tex,
                    light=255,
                    l_tex = door_info.step or theme.step or THEME.mats.STEP.wall,
                    u_tex = wall_tex,
                    [dir] = { l_peg="top" },
                    [10-dir] = { l_peg="top" },
                }

  local SIGN
  
  if theme.sign then
    SIGN = { f_h = z+8, c_h = z+8+high-16,
               f_tex = STEP.f_tex, c_tex = theme.sign_ceil,
               light=255,
               l_tex = theme.sign, u_tex = theme.sign }

  elseif theme.front_mark then
    SIGN = { solid = wall_tex, 
             [dir]    = { l_tex = theme.front_mark},
             [10-dir] = { l_tex = theme.front_mark} }
  end

  local fx = 1 + (x-1)*FW
  local fy = 1 + (y-1)*FH

  if (dir == 4) then fx = fx + FW - 1 end
  if (dir == 2) then fy = fy + FH - 1 end

  assert (long >= 2 and deep <= 2)

  local step = 1 + (deep - 1) * 2
  assert(step * 2 + 2 == deep * FW)

  local side = (long - door_w) * 2

--con.debugf("EXIT: door_w=%d long=%d side=%d\n", door_w, long, side)

  long = long * 4 - side * 2
  assert(long == 4 or long == 8)

  local sx, sy = ax*side, ay*side
  local ex, ey = ax*(long+side-1), ay*(long+side-1)
  local zx, zy = ax*(long+side*2-1), ay*(long+side*2-1)

--con.debugf("long_f=%d  ax=%d sx=%d ex=%d zx=%d\n", long, ax, sx, ex, zx)

  frag_fill(p,c, fx, fy, fx+zx+dx*7, fy+zy+dy*7, { solid=wall_tex })

  if door_info.frame_wall then

    -- align inner sides y_offset with outside wall
    local y_diff = link_other(link, c).ceil_h - STEP.c_h
    frag_fill(p,c, fx+sx-ax, fy+sy-ay, fx+sx-ax+dx*7, fy+sy-ay+dy*7,
      { solid=wall_tex, [adir]={ l_tex=door_info.frame_wall, y_offset=y_diff }} )
    frag_fill(p,c, fx+ex+ax, fy+ey+ay, fx+ex+ax+dx*7, fy+ey+ay+dy*7,
      { solid=wall_tex, [10-adir]={ l_tex=door_info.frame_wall, y_offset=y_diff }} )
  end

  if theme.front_mark then
    frag_fill(p,c, fx, fy, fx+zx+dx, fy+zy+dy, STEP)

    frag_fill(p,c, fx+dx*2, fy+dy*2, fx+ax*3+dx*2, fy+ay*3+dy*2, SIGN)
    frag_fill(p,c, fx+zx-ax*3+dx*2, fy+zy-ay*3+dy*2, fx+zx+dx*2, fy+zy+dy*2, SIGN)
  end

  for ff = 1,4 do
    if ff == 4 then
      frag_fill (p,c, fx+ax,fy+ay, fx+ax,fy+ay,
        { solid=key_tex, [adir] = { x_offset = 112 }} )
      frag_fill (p,c, fx+zx-ax,fy+zy-ay, fx+zx-ax,fy+zy-ay,
        { solid=key_tex, [10-adir] = { x_offset = 112 }} )
    end

    frag_fill (p,c, fx+sx,fy+sy, fx+ex,fy+ey, STEP)

    -- EXIT SIGN
    if theme.sign and (ff == 2) then
      frag_fill (p,c, fx+sx+ax,fy+sy+ay, fx+sx+ax*2,fy+sy+ay*2, SIGN,
        { [10-adir] = { x_offset = 32 },
          [adir] = { x_offset = 32 }} )
    end

    fx = fx + dx; fy = fy + dy
  end

  for mm = 1,1 do
    frag_fill (p,c, fx+ax,fy+ay, fx+zx-ax,fy+zy-ay, { solid=track_tex })
    frag_fill (p,c, fx+sx,fy+sy, fx+ex,fy+ey, DOOR)
    fx = fx + dx; fy = fy + dy
  end

  for bb = 1,3 do
    if bb == 1 then
      frag_fill (p,c, fx+ax,fy+ay, fx+ax,fy+ay,
        { solid=key_tex, [adir] = { x_offset = 112 }} )
      frag_fill (p,c, fx+zx-ax,fy+zy-ay, fx+zx-ax,fy+zy-ay,
        { solid=key_tex, [10-adir] = { x_offset = 112 }} )
    end
    frag_fill (p,c, fx+sx,fy+sy, fx+ex,fy+ey, STEP)
    fx = fx + dx; fy = fy + dy
  end
end


--
-- Build an exit hole
--
function B_exit_hole(p,c, K,kx,ky, sec)

  assert(K and sec)

  local bx = K.x1
  local by = K.y1

  gap_fill(p,c, bx,by, bx+KW-1, by+KH-1, sec,
           { l_tex = c.theme.hole_tex or c.theme.void })

  -- we want the central block
  bx, by = bx+1,by+1

  local fx = (bx - 1) * FW
  local fy = (by - 1) * FH

  local HOLE = copy_block(sec)

  HOLE.f_h = HOLE.f_h - 16
  HOLE.f_tex = THEME.SKY_TEX

  HOLE.walk_kind = 52 -- "exit_W1"
  HOLE.is_cage = true  -- don't place items/monsters here

  frag_fill(p,c, fx+1,fy+1, fx+FW,fy+FH, HOLE)

  local radius = 60

  for y = 1,FH+1 do
    for x = 1,FW+1 do
      if (x==1 or x==FW+1 or y==1 or y==FH+1) then

        local zx = fx + math.min(x,FW)
        local zy = fy + math.min(y,FH)

        local dir
        if y == FH+1 then
          dir = sel(x==FW+1, 9, 7)
        else
          dir = sel(x==FW+1, 3, 1)
        end

        assert(dir)

        local cur_x = (x - 3) * 16
        local cur_y = (y - 3) * 16

        local len = dist(0,0, cur_x,cur_y)
        assert(len > 0)

        local want_x = cur_x/len * radius
        local want_y = cur_y/len * radius

        c_move_frag_corner(p,c, zx,zy,dir, want_x - cur_x, want_y - cur_y)
      end
    end
  end
end


--
-- Build a stair
--
-- Z is the starting height
--
function B_stair(p, c, bx, by, z, dir, long, deep, step)

  local dx, dy = dir_to_delta(dir)
  local ax, ay = dir_to_across(dir)

  local fx = (bx - 1) * FW + 1
  local fy = (by - 1) * FH + 1

  if (dir == 4) then fx = fx + FW - 1 end
  if (dir == 2) then fy = fy + FH - 1 end

  local zx = ax * (long*4-1)
  local zy = ay * (long*4-1)

  local out_dir = sel(step < 0, dir, 10-dir)

  -- first step is always raised off the ground
  if step > 0 then z = z + step end

  for i = 1,deep*4 do

    local sec = copy_block_with_new(c.rmodel, --FIXME: K.rmodel
    {
      f_h = z,
      f_tex = c.theme.step_floor, -- might be nil (=> rmodel.f_tex)

      [out_dir] = { l_tex=c.theme.step, l_peg="top" },
    })

    frag_fill(p,c, fx, fy, fx+zx, fy+zy, sec)

    fx = fx + dx; fy = fy + dy; z = z + step
  end
end


--
-- Build a lift
--
-- Z is the starting height
--
function B_lift(p, c, x, y, z, dir, long, deep)

  local dx, dy = dir_to_delta(dir)
  local ax, ay = dir_to_across(dir)

  local LIFT = copy_block_with_new(c.rmodel,
  {
    f_h = z,
    f_tex = c.theme.lift_floor or THEME.mats.LIFT.floor,
    l_tex = c.theme.lift or THEME.mats.LIFT.wall,

    lift_kind = 123,  -- 62 for slower kind
    lift_walk = 120,  -- 88 for slower kind

    tag = allocate_tag(p),

    [2] = { l_peg="top" }, [4] = { l_peg="top" },
    [6] = { l_peg="top" }, [8] = { l_peg="top" },
  })

  fill(p,c, x, y,
       x + (long-1) * ax + (deep-1) * dx,
       y + (long-1) * ay + (deep-1) * dy, LIFT)
end


--
-- Build a pillar switch
--
function B_pillar_switch(p,c, K,x,y, info, kind, tag)

  local SWITCH =
  {
    solid = info.switch,

    switch_kind = kind,
    switch_tag = tag,

    [2] = { l_peg="bottom" },
    [4] = { l_peg="bottom" },
    [6] = { l_peg="bottom" },
    [8] = { l_peg="bottom" },
  }

  fill(p,c, x,y, x,y, SWITCH)
end


--
-- Build a floor-standing switch
--
function B_floor_switch(p,c, x,y,z, side, info, kind, tag)

  local fx = (x - 1) * FW
  local fy = (y - 1) * FH

  local BASE = copy_block_with_new(c.rmodel,
  {
    f_h = z, near_switch = true,
  })

  frag_fill(p,c, fx+1,fy+1, fx+FW,fy+FH, BASE)

  local SWITCH = copy_block_with_new(c.rmodel,
  {
    f_h = z + 64,

    f_tex = THEME.mats.METAL.floor,
    l_tex = info.switch,

    switch_kind = kind,
    switch_tag  = tag,
  })

  do
    local tex_h = 128  -- FIXME: assumption !!!
    local y_ofs = tex_h - (SWITCH.c_h - z)

    for side = 2,8,2 do
      SWITCH[side] = { l_peg="bottom", y_offset=y_ofs }
    end
  end

  local sx,sy, ex,ey = side_coords(side, 1,1, FW,FH)

  frag_fill(p,c, fx+sx,fy+sy, fx+ex,fy+ey, SWITCH)
end


function B_wall_switch(p,c, x,y,z, side, long, sw_info, kind, tag)

  assert(long == 2 or long == 3)

  local ax, ay = dir_to_across(side)

  if long == 3 then x,y = x-ax, y-ay end

  local fx = (x - 1) * FW
  local fy = (y - 1) * FH

  frag_fill(p,c, fx+1,fy+1, fx+(long-1)*ax*FW+FW,fy+(long-1)*ay*FH+FH, { solid=c.theme.void })

  local GAP =
  {
    f_h = z,
    c_h = z + 64,
    f_tex = c.rmodel.f_tex,
    c_tex = c.theme.arch_ceil or c.rmodel.f_tex, -- SKY is no good
    light = 224,

    l_tex = c.theme.void,
    u_tex = c.theme.void,
    near_switch = true,
  }

  local sx,sy, ex,ey = side_coords(side, 1,1, FW,FH)
  local dx,dy = dir_to_delta(10-side)

  local pos = (long - 1) * 2

  sx,sy = sx + pos*ax, sy + pos*ay
  ex,ey = ex + pos*ax, ey + pos*ay

  frag_fill(p,c, fx+sx,fy+sy, fx+ex,fy+ey, GAP)

  -- lights
  if THEME.mats.SW_FRAME then
    local sw_side = THEME.mats.SW_FRAME.wall

    local lit_dir = sel(side==2 or side==8, 6, 8)
    frag_fill(p,c, fx+sx-ax,fy+sy-ay, fx+sx-ax,fy+sy-ay,
         { solid=c.theme.void, [lit_dir]={ l_tex = sw_side }} )
    frag_fill(p,c, fx+ex+ax,fy+ey+ay, fx+ex+ax,fy+ey+ay,
         { solid=c.theme.void, [10-lit_dir]={ l_tex = sw_side }} )
  end

  sx,sy = sx+dx, sy+dy
  ex,ey = ex+dx, ey+dy

  local SWITCH =
  {
    solid = sw_info.switch,

    switch_kind = kind,
    switch_tag = tag,

    [side] = { l_peg="bottom" } 
  } 

  frag_fill(p,c, fx+sx,fy+sy, fx+ex,fy+ey, SWITCH);
end


function B_flush_switch(p,c, x,y,z, side, sw_info, kind, tag)

  local ax, ay = dir_to_across(side)

  local flu1 = c.theme.flush_left
  local flu2 = c.theme.flush_right

  if (side == 4) or (side == 8) then
    flu1, flu2 = flu2, flu1
  end

  fill(p,c, x-ax,y-ay, x-ax,y-ay,
       { solid = flu1 or c.theme.void, [side] = {l_peg="bottom"} })

  fill(p,c, x+ax,y+ay, x+ax,y+ay,
       { solid = flu2 or c.theme.void, [side] = {l_peg="bottom"} })

  local SWITCH =
  {
    solid = sw_info.switch,
    switch_kind = kind,
    switch_tag = tag,

    [side] = {l_peg="bottom"} 
  } 

  fill(p,c, x,y, x,y, SWITCH);
end


--
-- Build a pedestal (items, players)
-- 
function B_pedestal(p, c, x, y, base, info, overrides)
 
  local PEDESTAL = copy_block_with_new(base,
  {
    f_h   = base.f_h + info.h,
    f_tex = info.floor,
    l_tex = info.wall,
  })

  assert((PEDESTAL.c_h - PEDESTAL.f_h) >= 64)

  fill(p,c, x,y, x,y, PEDESTAL, overrides)
end


function B_double_pedestal(p, c, bx, by, base, ped_info, overrides)
 
  local OUTER =
  {
    f_h   = ped_info.h + base.f_h,
    f_tex = ped_info.floor,
    l_tex = ped_info.wall,
    light = ped_info.light,

    c_h   = c.rmodel.c_h - ped_info.h,
    c_tex = ped_info.floor,
    u_tex = ped_info.wall,

    kind  = ped_info.glow and 8 -- GLOW TYPE  (FIXME)
  }

  local INNER =
  {
    f_h   = ped_info.h2 + base.f_h,
    f_tex = ped_info.floor2,
    l_tex = ped_info.wall2,
    light = ped_info.light2,

    c_h   = c.rmodel.c_h - ped_info.h2,
    c_tex = ped_info.floor2,
    u_tex = ped_info.wall2,

    kind = ped_info.glow2 and 8 -- GLOW TYPE  (FIXME)
  }

  if c.theme.outdoor then
    OUTER.c_h   = c.rmodel.c_h
    OUTER.c_tex = c.rmodel.c_tex

    INNER.c_h   = c.rmodel.c_h
    INNER.c_tex = c.rmodel.c_tex
  end

  assert((OUTER.c_h - OUTER.f_h) >= 64)
  assert((INNER.c_h - INNER.f_h) >= 64)

  local fx = (bx - 1) * FW
  local fy = (by - 1) * FH

  frag_fill(p,c, fx+1,fy+1, fx+4,fy+4, OUTER, overrides)

  if ped_info.rotate2 then
    frag_fill(p,c, fx+2,fy+2, fx+2,fy+2, INNER)

    c_move_frag_corner(p,c, fx+2,fy+2, 1, 16, -6)
    c_move_frag_corner(p,c, fx+2,fy+2, 3, 22, 16)
    c_move_frag_corner(p,c, fx+2,fy+2, 7, -6,  0)
    c_move_frag_corner(p,c, fx+2,fy+2, 9,  0, 22)
  else
    frag_fill(p,c, fx+2,fy+2, fx+3,fy+3, INNER)
  end
end


--
-- Build some bars
--
-- Use a nil 'tag' parameter for solid bars, otherwise
-- the bars will be openable (by LOWERING!).
--
-- size must be either 1 or 2.
--
function B_bars(p,c, x,y, dir,long, size,step, bar_theme, sec,tex,
                tag, need_sides)

  local dx, dy = dir_to_delta(dir)
  local ax, ay = dir_to_across(dir)

  local bar

  if tag then
    bar = copy_block(sec)
    bar.f_h = bar.c_h
    bar.f_tex = bar_theme.floor
    bar.c_tex = bar_theme.floor
    bar.kind = nil
    bar.tag = tag

    bar.l_tex = bar_theme.wall
    bar.u_tex = bar_theme.wall
  else
    bar = { solid=bar_theme.wall }
  end

  sec = copy_block(sec)
  sec.l_tex = tex
  sec.u_tex = tex

  for d_pos = 0,long-1 do
    local fx = (x + d_pos*ax - 1) * FW + 1
    local fy = (y + d_pos*ay - 1) * FH + 1

    frag_fill(p,c, fx,fy, fx+FW-1,fy+FH-1, sec)
  end

  for d_pos = 0,long*4-1,step do
    local fx = (x - 1) * FW + 1 + d_pos*ax
    local fy = (y - 1) * FH + 1 + d_pos*ay

    frag_fill(p,c, fx+1,fy+1, fx+size,fy+size, bar)
  end

  if need_sides then
    fill(p,c, x-ax,y-ay, x-ax,y-ay, { solid=tex })

    x,y = x+long*ax, y+long*ay
    fill(p,c, x,y, x,y, { solid=tex })
  end
end


--
-- fill a chunk with void, with pictures on the wall
--
function B_void_pic(p,c, K,kx,ky, pic, cuts)

  local z = (c.c_min + c.f_max) / 2
  local h = pic.h or (c.c_min - c.f_max - 32)

  local z1 = z-h/2
  local z2 = z+h/2

  local fx = (K.x1 - 1) * FW
  local fy = (K.y1 - 1) * FH

  frag_fill(p,c, fx+1,fy+1, fx+3*FW,fy+3*FH, { solid=c.theme.wall })

  local INNER =
  {
    solid = pic.wall,
    
    x_offset = pic.x_offset,
    y_offset = pic.y_offset,
  }
  assert(INNER.solid)

  frag_fill(p,c, fx+2,fy+2, fx+3*FW-1,fy+3*FH-1, INNER)

  local CUTOUT = copy_block_with_new(c.rmodel,
  {
    f_h = z1,
    c_h = z2,
    f_tex = c.theme.arch_floor, -- may be nil (=> rmodel.f_tex)
    c_tex = c.theme.arch_ceil  or c.rmodel.f_tex, -- SKY is no good
  })

  if cuts >= 3 or pic.glow then  -- FIXME: better way to decide
    CUTOUT.light = 255
    CUTOUT.kind  = 8  -- GLOW TYPE  (FIXME)
  end

  for side = 2,8,2 do

    local ax,ay = dir_to_across(side)
    local dx,dy = dir_to_delta(side)

    local sx,sy, ex,ey = side_coords(side, 1,1, FW*3, FH*3)

    if cuts == 1 then
      frag_fill(p,c, fx+sx+2*ax,fy+sy+2*ay, fx+ex-2*ax,fy+ey-2*ay, CUTOUT)
    elseif cuts == 2 then
      frag_fill(p,c, fx+sx+ax,fy+sy+ay, fx+sx+4*ax,fy+sy+4*ay, CUTOUT)
      frag_fill(p,c, fx+ex-4*ax,fy+ey-4*ay, fx+ex-ax,fy+ey-ay, CUTOUT)
    elseif cuts == 3 then
      for i = 0,2 do
        local j = i*FW + 1
        frag_fill(p,c, fx+sx+j*ax,fy+sy+j*ay, fx+sx+(j+1)*ax,fy+sy+(j+1)*ay, CUTOUT)
      end
    elseif cuts == 4 then
      for i = 0,2,2 do
        local j = i*FW + sel(i==0, 2, 1)
        frag_fill(p,c, fx+sx+j*ax,fy+sy+j*ay, fx+sx+j*ax,fy+sy+j*ay, CUTOUT)
      end
    end
  end
end

function B_pillar(p,c, theme, kx,ky, bx,by)

  local K = c.chunks[kx][ky]

  local PILLAR =
  {
    solid = theme.pillar or theme.void or theme.wall,

    y_offset = 128 - (K.rmodel.c_h - K.rmodel.f_h)
  }

  fill(p,c, bx, by, bx, by, PILLAR)
end

function B_crate(p,c, crate_info, base, kx,ky, bx,by)

  local K = c.chunks[kx][ky]

  local CRATE = copy_block_with_new(base,
  {
    f_h   = K.rmodel.f_h + crate_info.h,
    f_tex = crate_info.floor,
    l_tex = crate_info.wall,
    is_cage = true,  -- don't put monsters/pickups here
  })

  CRATE.c_h = math.max(base.c_h, CRATE.f_h)

  -- don't damage player if chunk is lava/nukage/etc
  CRATE.kind = nil

  local x_ofs = crate_info.x_offset
  local y_ofs = crate_info.y_offset

  if c.theme.outdoor or not c.sky_light then
    if crate_info.can_rotate and rand_odds(50) then
      rotate_block(CRATE, 0)
      CRATE.rotated = true
      x_ofs = crate_info.rot_x_offset or 9
    end
  end

  if crate_info.can_xshift and rand_odds(50) then
    x_ofs = (x_ofs or 0) + crate_info.can_xshift
  end
  if crate_info.can_yshift and rand_odds(50) then
    y_ofs = (y_ofs or 0) + crate_info.can_yshift
  end

  local x_ofs2 = crate_info.side_x_offset or x_ofs
  local y_ofs2 = crate_info.side_y_offset or y_ofs

  if rand_odds(50) then x_ofs,x_ofs2 = x_ofs2,x_ofs end
  if rand_odds(50) then y_ofs,y_ofs2 = y_ofs2,y_ofs end

  fill(p,c, bx, by, bx, by, CRATE,
       { [2] = { l_peg="top", x_offset=x_ofs,  y_offset=y_ofs  },
         [4] = { l_peg="top", x_offset=x_ofs2, y_offset=y_ofs2 },
         [6] = { l_peg="top", x_offset=x_ofs2, y_offset=y_ofs2 },
         [8] = { l_peg="top", x_offset=x_ofs,  y_offset=y_ofs  } })

  -- sometimes put monsters on top
  if not CRATE.rotated and (CRATE.c_h >= CRATE.f_h + 80) and rand_odds(33) then
    local spot = { c=c, x=bx, y=by, different=true }
    add_cage_spot(p,c, spot)
  end
end

function cage_select_height(p,c, kind, theme,rail, floor_h, ceil_h)

  if c[kind] and c[kind].z >= floor_h and rand_odds(80) then
    return c[kind].z, c[kind].open_top
  end
  
  local open_top = false

  if rail.h < 72 then open_top = true end
  if ceil_h >= floor_h + 256 then open_top = true end
  if dual_odds(c.outdoor, 50, 10) then open_top = true end

  local z1 = floor_h + 32
  local z2 = math.min(floor_h + 128, ceil_h - 16 - rail.h)

  local r = con.random() * 100
      if r < 16 then z2 = z1
  elseif r < 50 then z1 = z2
  end

  z1 = (z1+z2)/2

  if not c[kind] then
    c[kind] = { z=z1, open_top=open_top }
  end

  return (z1+z2)/2, open_top
end

function B_pillar_cage(p,c, theme, kx,ky, bx,by)

  local K = c.chunks[kx][ky]

  local rail
  if K.rmodel.c_h < K.rmodel.f_h+192 then
    rail = THEME.rails["r_1"]  -- FIXME: want "short" rail
  else
    rail = get_rand_rail()
  end
  assert(rail)

  local kind = sel(kx==2 and ky==2, "middle_cage", "pillar_cage")

  local z, open_top = cage_select_height(p,c, kind, theme,rail, K.rmodel.f_h,K.rmodel.c_h)

  if kx==2 and ky==2 and dual_odds(c.theme.outdoor, 90, 20) then
    open_top = true
  end

  local CAGE = copy_block_with_new(K.rmodel,
  {
    f_h   = z,
    f_tex = theme.floor,
    l_tex = theme.wall,
    u_tex = theme.wall,
    rail  = rail.wall,
    is_cage = true,
  })

  if not open_top then
    CAGE.c_h = CAGE.f_h + rail.h
    CAGE.c_tex = theme.ceil
    CAGE.light = 192  -- FIXME: from CAGE theme
  end

--  if K.dud_chunk and (c.theme.outdoor or not c.sky_light) then
--    rotate_block(CAGE,32)
--  end

  fill(p,c, bx,by, bx,by, CAGE)

  local spot = {c=c, x=bx, y=by}
  if kx==2 and ky==2 then spot.different = true end

  add_cage_spot(p,c, spot)
end

--
-- Build a chunk-sized monster cage
--
function B_big_cage(p,c, theme, K,kx,ky)

  local bx, by = K.x1, K.y1

  local rail = get_rand_rail()
  assert(rail)

  -- FIXME: some of this is duplicated above, merge it
 
  local rail
  if c.ceil_h < c.floor_h+192 then
    rail = THEME.rails["r_1"]
  else
    rail = get_rand_rail()
  end
  assert(rail)

  local z, open_top = cage_select_height(p,c, "big_cage", theme,rail, c.floor_h,c.ceil_h)

  local CAGE = copy_block_with_new(K.rmodel,
  {
    f_h   = z,
    f_tex = theme.floor,
    l_tex = theme.wall,
    u_tex = theme.wall,
    rail  = rail.wall,   -- FIXME: why here and down there???
    is_cage = true,
  })

  if not open_top then
    CAGE.c_h = CAGE.f_h + rail.h
    CAGE.c_tex = theme.ceil
    CAGE.light = 176
  end

  for x = 0,2 do for y = 0,2 do

    local overrides = {}
    if x == 0 then overrides[4] = { rail=rail.wall } end
    if x == 2 then overrides[6] = { rail=rail.wall } end
    if y == 0 then overrides[2] = { rail=rail.wall } end
    if y == 2 then overrides[8] = { rail=rail.wall } end

    fill(p,c, bx+x,by+y, bx+x,by+y, CAGE, overrides)
  end end

  local spot = {c=c, x=bx, y=by, double=true, dx=32, dy=32}
  if kx==2 and ky==2 then spot.different = true end

  add_cage_spot(p,c, spot)
end

--
-- Build a hidden monster closet
--
function B_monster_closet(p,c, K,kx,ky, z, tag)

  local bx, by = K.x1, K.y1

  local INNER = copy_block_with_new(c.rmodel,
  {
    f_h = z,

    --!! c_tex = c.theme.arch_ceil or c.rmodel.f_tex,

    l_tex = c.theme.void,
    u_tex = c.theme.void,

    is_cage = true,
  })

  local OUTER = copy_block_with_new(INNER,
  {
    c_h   = INNER.f_h,
    c_tex = c.theme.arch_ceil or INNER.f_tex,
    tag   = tag,
  })

  local fx = (bx - 1) * FW
  local fy = (by - 1) * FH

  frag_fill(p,c, fx+1,fy+1, fx+3*FW,fy+3*FH, OUTER);
  frag_fill(p,c, fx+2,fy+2, fx+3*FW-1,fy+3*FH-1, INNER)

  return { c=c, x=bx, y=by, double=true, dx=32, dy=32 }
end


function B_arch(p,c, bx,by, side,long, theme)

  local dx,dy = dir_to_delta(side)
  local ax,ay = dir_to_across(side)

  local ARCH = copy_block(c.rmodel)

  if not c.theme.outdoor then
    ARCH.c_h = ARCH.f_h + 96
  end

  local WALL = { solid=theme.wall }

  local fx1 = (bx - 1) * FW + 1
  local fy1 = (by - 1) * FH + 1

  local fx2 = fx1 + ax * FW * long - 1
  local fy2 = fy1 + ay * FH * long - 1

  frag_fill(p,c, fx1,fy1, fx2,fy2, WALL)

  local T = 2

  frag_fill(p,c, fx1+ax*T,fy1+ay*T, fx2-ax*T,fy2-ay*T, ARCH)
end


--
-- Build a scenic vista!
--
-- The 'kind' value can be: "solid", "frame", "open", "wire"
--
function B_vista(p,c, side,deep, theme,kind)

  local other = neighbour_by_side(p,c,side)
  assert(other)

  local x1,y1, x2,y2 = side_coords(side, 1,1, BW,BH)

  local dx,dy = dir_to_delta(side)
  local ax,ay = dir_to_across(side)

  x1,y1 = c.bx1-1 + (x1+ax*3+dx), c.by1-1 + (y1+ay*3+dy)
  x2,y2 = c.bx1-1 + (x2-ax*3+dx), c.by1-1 + (y2-ay*3+dy)

  local ARCH = copy_block(c.rmodel)

  ARCH.l_tex = theme.wall
  ARCH.u_tex = theme.wall

  if not other.theme.outdoor then
    ARCH.c_tex = sel(theme.outdoor, theme.floor, theme.ceil)
  end

  if ARCH.c_tex ~= THEME.SKY_TEX then
    ARCH.c_h = ARCH.f_h + 96
  end

  if kind ~= "solid" then
    ARCH.light = int((c.rmodel.light+other.rmodel.light)/2)
  end

  local fx1 = (x1 - 1) * FW + 1
  local fy1 = (y1 - 1) * FH + 1

  local fx2 = x2 * FW
  local fy2 = y2 * FH

  frag_fill(p,c, fx1,fy1, fx2,fy2, sel(ARCH.c_tex == THEME.SKY_TEX, ARCH, { solid=ARCH.l_tex }))
  frag_fill(p,c, fx1+ax,fy1+ay, fx2-ax,fy2-ay, ARCH)


  local ROOM   = copy_block(c.rmodel)
  local WINDOW = copy_block(c.rmodel)

  ROOM.l_tex = theme.wall
  ROOM.u_tex = theme.wall
  ROOM.c_tex = theme.ceil

  WINDOW.l_tex = theme.wall
  WINDOW.u_tex = theme.wall
  WINDOW.c_tex = theme.ceil

  ROOM.light   = other.rmodel.light
  WINDOW.light = other.rmodel.light

  WINDOW.f_h = ROOM.f_h + 32

  if kind == "open" or kind == "wire" then
    ROOM.c_h   = other.rmodel.c_h
    ROOM.c_tex = other.theme.ceil
  
    WINDOW.c_h   = other.rmodel.c_h
    WINDOW.c_tex = other.theme.ceil

  elseif kind == "frame" then
    ROOM.c_h   = other.rmodel.c_h
    ROOM.c_tex = other.theme.ceil
  
    WINDOW.c_h = ROOM.c_h - 24
    WINDOW.c_tex = sel(theme.outdoor, theme.floor, theme.ceil)
    WINDOW.light = other.rmodel.light - 16

  else -- "solid"
    local h = rand_index_by_probs { 20, 80, 20, 40 }
    ROOM.c_h   = ROOM.f_h + 96 + (h-1)*32
    ROOM.c_tex = sel(theme.outdoor, theme.floor, theme.ceil)

    if ROOM.c_h > other.sky_h then
       ROOM.c_h = math.max(other.sky_h, ROOM.f_h + 96)
    end

    WINDOW.c_h = ROOM.f_h + 96
    WINDOW.c_tex = ARCH.c_tex

    ROOM.light   = other.rmodel.light - 32
    WINDOW.light = other.rmodel.light - 16
  end

  WINDOW.impassible = true  -- FIXME

  -- save ROOM for later
  other.vista_room = ROOM


  x1,y1 = x1+dx*1, y1+dy*1
  x2,y2 = x2+dx*deep, y2+dy*deep

  if x1 > x2 then x1,x2 = x2,x1 end
  if y1 > y2 then y1,y2 = y2,y1 end


  fx1 = (x1 - 1) * FW + 1
  fy1 = (y1 - 1) * FH + 1

  fx2 = x2 * FW
  fy2 = y2 * FH

  local px1,py1, px2,py2 = side_coords(side,    fx1,fy1, fx2,fy2)
  local wx1,wy1, wx2,wy2 = side_coords(10-side, fx1,fy1, fx2,fy2)


  if kind == "wire" then

    local rail = get_rand_rail()

    local curved = true
    local far_x, far_y, far_corner

        if side == 4 then far_x, far_y, far_corner = 0, 0, 7
    elseif side == 2 then far_x, far_y, far_corner = 0, 0, 3
    elseif side == 8 then far_x, far_y, far_corner = 0, (y2-y1), 9
    elseif side == 6 then far_x, far_y, far_corner = (x2-x1), 0, 9
    end

    for x = 0,(x2-x1) do
      for y = 0,(y2-y1) do

        local overrides = {}

        if x == 0       then overrides[4] = { rail=rail.wall } end
        if x == (x2-x1) then overrides[6] = { rail=rail.wall } end
        if y == 0       then overrides[2] = { rail=rail.wall } end
        if y == (y2-y1) then overrides[8] = { rail=rail.wall } end

        -- don't block the entryway
        overrides[10-side] = nil

        -- curve ball!
        if curved then
          if (x == far_x and y == far_y) or
             (x == (far_x+ax) and y == (far_y+ay))
          then
            -- 48 is the magical distance to align the railing
            overrides[far_corner] = { dx=(dx*48), dy=(dy*48) }
            overrides.mark = allocate_mark(p)
          end  
        end

        fill(p,c, x1+x,y1+y, x1+x,y1+y, ROOM, overrides)
      end
    end

  else -- solid, frame or open
  
    frag_fill(p,c, fx1,fy1, fx2,fy2, WINDOW)
    frag_fill(p,c, fx1+1,fy1+1, fx2-1,fy2-1, ROOM)

    --- walkway ---

    frag_fill(p,c, wx1+ax,wy1+ay, wx2-ax,wy2-ay, ROOM)
  end


  --- pillars ---
  if kind == "solid" or kind == "frame" then

    local support = theme.wall  -- FIXME: "SUPPORT2"
    
    frag_fill(p,c, px1,py1, px1,py1, { solid=support })
    frag_fill(p,c, px2,py2, px2,py2, { solid=support })


    if false then  -- FIXME
      px1 = int((px1+wx1)/2)
      py1 = int((py1+wy1)/2)
      px2 = int((px2+wx2)/2)
      py2 = int((py2+wy2)/2)

      frag_fill(p,c, px1,py1, px1,py1, { solid=support })
      frag_fill(p,c, px2,py2, px2,py2, { solid=support })
    end
  end 


  -- rest of chunk in other room
  do
    local extra = 3 - (deep % 3)

    if side < 5 then
      x1,y1 = x1+dx*extra, y1+dy*extra
    else
      x2,y2 = x2+dx*extra, y2+dy*extra
    end

    gap_fill(p,c, x1,y1, x2,y2, other.rmodel)
  end

  -- FIXME !!! add spots to room
  -- return { c=c, x=x1+dx, y=y1+dy, double=true, dx=32, dy=32 }
end

--
-- create a deathmatch exit room
--
-- FIXME: it always faces south
--
function B_deathmatch_exit(p,c, K,kx,ky)

  local theme = p.exit_theme

  local x1, y1 = K.x1, K.y1
  local x2, y2 = K.x2, K.y2

  local fx = (x1 - 1) * FW
  local fy = (y1 - 1) * FH

  local door_info = theme.door

  local ROOM =
  {
    f_h = c.rmodel.f_h,
    c_h = c.rmodel.f_h + 72,
    f_tex = theme.floor,
    c_tex = theme.ceil,
    light = 176,

    l_tex = theme.void,
    u_tex = theme.void,
  }

  frag_fill(p,c, fx+1,fy+1, fx+3*FW,fy+3*FH, { solid=theme.void })
  frag_fill(p,c, fx+2,fy+5, fx+3*FW-1,fy+3*FH-1, ROOM)

  if theme.front_mark then
    frag_fill(p,c, fx+1,fy+1, fx+3*FW,fy+1, { solid=theme.front_mark })
  end

  local STEP =
  {
    f_h = c.rmodel.f_h + 8,
    c_h = c.rmodel.f_h + 80,
    f_tex = THEME.mats.DOOR_FRAME.floor,
    c_tex = THEME.mats.DOOR_FRAME.floor,
    light = 255,

    l_tex = theme.step or THEME.mats.STEP.wall,
    u_tex = theme.void,
  }

---##  frag_fill(p,c, fx+4,fy+1, fx+9,fy+4, { solid=theme.void})

  frag_fill(p,c, fx+5,fy+1, fx+8,fy+4, STEP)

  local DOOR =
  {
    f_h = c.rmodel.f_h + 8,
    c_h = c.rmodel.f_h + 8,
    f_tex = door_info.frame_floor or STEP.f_tex,
    c_tex = door_info.ceil        or STEP.f_tex,
    light = 255,

    l_tex = c.rmodel.l_tex,
    u_tex = door_info.wall,
    door_kind = 1,

    [2] = { u_peg="bottom" }, [8] = { u_peg="bottom" },
    [4] = { l_peg="bottom" }, [6] = { l_peg="bottom" }, -- TRACK
  }

  frag_fill(p,c, fx+4,fy+2, fx+9,fy+3, { solid=THEME.mats.TRACK.wall })
  frag_fill(p,c, fx+5,fy+2, fx+8,fy+3, DOOR)

  local SWITCH =
  {
    solid = theme.switch.switch,
    switch_kind = 11,

    [2] = { l_peg="bottom" }, [8] = { l_peg="bottom" },
    [4] = { l_peg="bottom" }, [6] = { l_peg="bottom" },
  }

  frag_fill(p,c, fx+5,fy+11, fx+8,fy+12, SWITCH)
end


----------------------------------------------------------------

SKY_LIGHT_FUNCS =
{
  all      = function(kx,ky, x,y) return true end,
  middle   = function(kx,ky, x,y) return kx==2 and ky==2 end,
  pillar   = function(kx,ky, x,y) return not (kx==2 and ky==2) end,

--  pillar_2 = function(kx,ky, x,y) return kx==2 and ky==2 end,

  double_x = function(kx,ky, x,y) return (x % 2) == 0 end,
  double_y = function(kx,ky, x,y) return (y % 2) == 0 end,

  triple_x = function(kx,ky, x,y) return (x % 3) == 2 end,
  triple_y = function(kx,ky, x,y) return (y % 3) == 2 end,

  holes_2 = function(kx,ky, x,y) return (x % 2) == 0 and (y % 2) == 0 end,
  holes_3 = function(kx,ky, x,y) return (x % 3) == 2 and (y % 3) == 2 end,

  boggle = function(kx,ky, x,y)
    return not ((x % 3) == 2 or (y % 3) == 2) end,

  pin_hole = function(kx,ky, x,y)
    return kx==2 and ky==2 and (x % 3 )== 2 and (y % 3) == 2 end,

  cross_1 = function(kx,ky, x,y)
    return (kx==2 and (x % 3) == 2) or 
           (ky==2 and (y % 3) == 2) end,

  cross_2 = function(kx,ky, x,y)
    return (kx==2 and ky==2) and
      ((x % 3) == 2 or (y % 3) == 2) end,

  pieces_1 = function(kx,ky, x,y)
    return (kx~=2 and ky==2 and (y%3)==2) or
           (kx==2 and ky~=2 and (x%3)==2) end,

  pieces_2 = function(kx,ky, x,y)
    return (kx~=2 and ky==2 and (x%3)==2) or
           (kx==2 and ky~=2 and (y%3)==2) end,

  weird = function(kx,ky, x,y)
    return (kx==2 or ky==2) and not (kx==2 and ky==2) and
      ((x % 3) == 2 or (y % 3) == 2) end,

--  cross = function(kx,ky, x,y) return kx==2 or  ky==2 end,
--  hash  = function(kx,ky, x,y)
--    return (kx==2 or ky==2) and not
--      ((x % 3) == 1 or (y % 3) == 1) end,
}

function random_sky_light()
  local names = {}
  for kind,func in pairs(SKY_LIGHT_FUNCS) do
    table.insert(names,kind)
  end
  return rand_element(names)
end


----------------------------------------------------------------


function setup_rmodel(p, c)

  c.rmodel =
  {
    f_h=c.floor_h,
    f_tex=c.theme.floor,
    l_tex=c.theme.wall,

    c_h=c.ceil_h,
    c_tex=c.theme.ceil,
    u_tex=c.theme.wall,

    light=c.light,
  }

  if not c.rmodel.light then
    c.rmodel.light = sel(c.theme.outdoor, 192, 144)
  end
end

function make_chunks(p)

  local function count_empty_chunks(c)
    local count = 0
    for kx = 1,KW do
      for ky = 1,KH do
        if not c.chunks[kx][ky] then
          count = count + 1
        end
      end
    end
    return count
  end

  local function empty_chunk(c)
    -- OPTIMISE with rand_shuffle
    for loop = 1,999 do
      local kx = rand_irange(1,KW)
      local ky = rand_irange(1,KH)

      if not c.chunks[kx][ky] then return kx, ky end
    end
  end


  local function alloc_door_spot(c, side, link)

    -- figure out which chunks are needed
    local coords = {}

    local kx, ky = side_to_chunk(side)
    local ax, ay = dir_to_across(side)

    assert(not c.chunks[kx][ky])

    if link.where == "double" then
      table.insert(coords, {x=kx+ax, y=ky+ay})
      table.insert(coords, {x=kx-ax, y=ky-ay})
      
      local no_void = c.closet[2] or c.closet[4] or c.closet[6] or c.closet[8]

      -- what shall we put in-between?
      local r = con.random() * 100
      local K
      if r < 40 then
        c.chunks[kx][ky] = new_chunk(c, kx,ky, "link",link)
      elseif r < 80 or no_void then
        c.chunks[kx][ky] = new_chunk(c, kx,ky, "room")
      else
        c.chunks[kx][ky] = new_chunk(c, kx,ky, "void")
      end

    elseif link.where == "wide" then
      table.insert(coords, {x=kx+ax, y=ky+ay})
      table.insert(coords, {x=kx   , y=ky   })
      table.insert(coords, {x=kx-ax, y=ky-ay})

    else
      local d_pos = where_to_block(link.where, link.long)
      -- FIXME DUPLICATED SHITE
      local d_min, d_max = 1, BW - (link.long-1)
      if (d_pos < d_min) then d_pos = d_min end
      if (d_pos > d_max) then d_pos = d_max end

      local j1 = int((d_pos - 1) / JW)
      local j2 = int((d_pos - 1 + link.long-1) / JW)
      
      for j = j1,j2 do
        assert (0 <= j and j < KW)
        table.insert(coords,
          { x = kx-ax + ax * j, y = ky-ay + ay * j })
      end

---###      if wh < 0 then wh, ax, ay = -wh, -ax, -ay end
---###      if wh > 2 then wh = 2 end
---###
---###      table.insert(coords,
---###        { x = kx+ax * int(wh/2),
---###          y = ky+ay * int(wh/2) })
---###
---###      if wh == 1 then -- straddles two chunks
---###        table.insert(coords, { x=kx+ax, y=ky+ay })
---###      end
    end

    -- now check for clashes
    local has_clash = false

    for zzz,loc in ipairs(coords) do

      kx, ky = loc.x, loc.y
      assert (1 <= kx and kx <= KW)
      assert (1 <= ky and ky <= KH)

      if c.chunks[kx][ky] then
        -- do c.chunks[kx][ky] = { link="#" }; return true end
        has_clash = true
        c.chunks.clasher = c.chunks[kx][ky]
      else
        c.chunks[kx][ky] = new_chunk(c, kx,ky, "link",link )
      end
    end
    return not has_clash
  end

  local function put_chunks_in_cell(c)

    if c.chunks then
      -- last time was successful, nothing to do
      return true
    end

    c.chunks = array_2D(KW, KH)

    for side,L in pairs(c.link) do

      if not alloc_door_spot(c, side, L) then
        assert(c.chunks.clasher)

        -- con.debugf("  CLASH IN (%d,%d)\n", c.x, c.y)

        -- be fair about which link we will blame
        if c.chunks.clasher.link and rand_odds(50) then
          L = c.chunks.clasher.link
        end

        -- remove the chunks from the offending cells and
        -- select a different exit position
        L.cells[1].chunks = nil
        L.cells[2].chunks = nil

        L.where = random_where(L)

        return false
      end
    end

    return true --OK--
  end


  local function add_travel_chunks(c)
    -- this makes sure that there is always a path
    -- from one chunk to another.  The problem areas
    -- look like this:
    -- 
    --    X |##   We need to make X and Y touch, so
    --    --+--   copy X or Y into an empty corner.
    --    ##| Y

    local function check_pair(x1,y1, x2,y2)

      -- are X or Y empty?
      if not (c.chunks[x1][y2] and c.chunks[x2][y1]) then
        return
      end

      local k1 = c.chunks[x1][y1]
      local k2 = c.chunks[x2][y2]

      if k1 and not k1.void then return end
      if k2 and not k2.void then return end

      -- from here on, k1 and k2 being non-nil implies
      -- they are void-space
      assert(not (k1 and k2))

      local src_x, src_y = x1,y2
      if rand_odds(50) then src_x, src_y = x2,y1 end

      local dest_x, dest_y = x1,y1

      if k1 or (not k2 and rand_odds(50)) then
        dest_x, dest_y = x2,y2
      end

      c.chunks[dest_x][dest_y] = copy_chunk(c, dest_x, dest_y, c.chunks[src_x][src_y])
    end

    local function check_corner(dir)
      local dx, dy = dir_to_delta(dir)

      local kx,ky = 2+dx, 2+dy
      
      local K = c.chunks[kx][ky]
      if K and K.link and K.link.build == c then
        local A = c.chunks[kx][2]
        local B = c.chunks[2][ky]

        --if A and not is_roomy(A) then A = nil end
        --if B and not is_roomy(B) then B = nil end

        if not (A and is_roomy(c, A)) and
           not (B and is_roomy(c, B)) then

              if not A then c.chunks[kx][2] = new_chunk(c, kx,2, "room")
          elseif not B then c.chunks[2][ky] = new_chunk(c, 2,ky, "room")
          end
        end
      end
    end

    --== add_travel_chunks ==--

    if c.chunks[2][2] and c.chunks[2][2].vista then
      return
    end

    -- centre chunk always roomy  (FIXME ??)
    c.chunks[2][2] = new_chunk(c, 2,2, "room")

    local pair_list =
    {
      { 2,1, 1,2 }, { 2,1, 3,2 },
      { 2,3, 1,2 }, { 2,3, 3,2 }
    }

    rand_shuffle(pair_list)

    for zzz, pair in ipairs(pair_list) do
      check_pair(unpack(pair))
    end

    -- finally, handle the case where a build-link
    -- (which are at room level) is isolated in a corner.
    -- [Not strictly essential, but prevents unneeded stairs]

    check_corner(1)
    check_corner(3)
    check_corner(7)
    check_corner(9)
  end

  local function chunk_similar(k1, k2)
    assert(k1 and k2)
    if k1.void and k2.void then return true end
    if k1.room and k2.room then return true end
    if k1.cage and k2.cage then return true end
    if k1.liquid and k2.liquid then return true end
    if k1.link and k2.link then return k1.link == k2.link end
    return false
  end

  local BIG_CAGE_ADJUST = { less=50, normal=75, more=90 }

  local function try_flush_side(c)

    -- select a side
    local side = rand_irange(1,4) * 2
    local x1, y1, x2, y2 = side_coords(side, 1,1, KW,KH)

    local common
    local possible = true

    for x = x1,x2 do
      for y = y1,y2 do
        if not possible then break end
        
        local K = c.chunks[x][y]

        if not K then
          -- continue
        elseif K.vista then
          possible = false
        elseif not common then
          common = K
        elseif not chunk_similar(common, K) then
          possible = false
        end
      end
    end

    if not (possible and common) then return end

    if not p.coop then
      -- let user adjustment parameters control whether closets and
      -- cages are made bigger.
      if common.closet and not rand_odds(BIG_CAGE_ADJUST[settings.traps]) then
        return
      end
      if common.cage and not rand_odds(BIG_CAGE_ADJUST[settings.mons]) then
        return
      end
    end

    for kx = x1,x2 do
      for ky = y1,y2 do
        if not c.chunks[kx][ky] then
          c.chunks[kx][ky] = copy_chunk(c, kx, ky, common)
        end
      end
    end
  end

  local function try_grow_room(c)
    local kx, ky

    repeat
      kx, ky = rand_irange(1,KW), rand_irange(1,KH)
    until c.chunks[kx][ky] and c.chunks[kx][ky].room

    local dir_order = { 2,4,6,8 }
    rand_shuffle(dir_order)

    for zzz,dir in ipairs(dir_order) do
      local nx,ny = dir_to_delta(dir)
      nx, ny = kx+nx, ky+ny

      if valid_chunk(nx, ny) then
        if not c.chunks[nx][ny] then
          c.chunks[nx][ny] = new_chunk(c, nx, ny, "room")
          return -- SUCCESS --
        end
      end
    end
  end

  local function void_it_up(c, kind)
    if not kind then kind = "void" end
    for kx = 1,KW do
      for ky = 1,KH do
        if not c.chunks[kx][ky] then
          c.chunks[kx][ky] = new_chunk(c, kx,ky, kind)
        end
      end
    end
  end

  local function try_add_special(c, kind)
    
    if kind == "liquid" then
      if not c.liquid then return end
      if c.is_exit and rand_odds(98) then return end
    end

    -- TODO: more cage themes...
    if kind == "cage" then
      if not THEME.mats.CAGE then return end
      if c.scenic then return end
    end

    local posits = {}

    for kx = 1,KW do
      for ky = 1,KH do
        if not c.chunks[kx][ky] then
          -- make sure cage has a walkable neighbour
          for dir = 2,8,2 do
            local nx,ny = dir_to_delta(dir)
            nx, ny = kx+nx, ky+ny

            if valid_chunk(nx, ny) and c.chunks[nx][ny] and
               (c.chunks[nx][ny].room or c.chunks[nx][ny].link)
            then
              table.insert(posits, {x=kx, y=ky})
              break;
            end
          end
        end
      end
    end

    if #posits == 0 then return end

    local p = rand_element(posits)

    c.chunks[p.x][p.y] = new_chunk(c, p.x, p.y, kind)
  end

  local function add_closet_chunks(c)
    if not c.quest.closet then return end

    local closet = c.quest.closet

    for idx,place in ipairs(closet.places) do
      if place.c == c then

        -- !!! FIXME: determine side _HERE_ (not in planner)
        local kx,ky = side_to_chunk(place.side)

        if c.chunks[kx][ky] then
          con.printf("WARNING: monster closet stomped a chunk!\n")
          con.printf("CELL (%d,%d)  CHUNK (%d,%d)\n", c.x, c.y, kx, ky)
          con.printf("%s\n", table_to_string(c.chunks[kx][ky], 2))

          show_chunks(p)
        end

        con.debugf("CLOSET CHUNK @ (%d,%d) [%d,%d]\n", c.x, c.y, kx, ky)

        local K = new_chunk(c, kx,ky, "void")
        K.closet = true
        K.place = place

        c.chunks[kx][ky] = K
      end
    end
  end

  local function add_vista_chunks(c)
    for side = 2,8,2 do
      if c.vista[side] then
        local other = neighbour_by_side(p, c, side)

        local kx,ky = side_to_chunk(side)
        local K = c.chunks[kx][ky]

        if K and not (K.room or K.link) then
          con.debugf("BLOCKED VISTA @ (%d,%d) [%d,%d]\n", c.x, c.y, kx,ky)
          c.vista[side] = nil
          other.vista_from = nil
        
        else
          if not K then
            c.chunks[kx][ky] = new_chunk(c, kx,ky, "room")
          end

          other.chunks[4-kx][4-ky] = new_chunk(c, 4-kx,4-ky, "vista")

          if c.vista[side] == 2 then
            other.chunks[2][2] = new_chunk(c, 2,2, "vista")
          end
        end
      end
    end
  end

  local function grow_small_exit(c)
    assert(c.entry_dir)
    local kx,ky = side_to_chunk(10 - c.entry_dir)

    if c.chunks[kx][ky] then
      con.printf("WARNING: small_exit stomped a chunk!\n")
    end

    local r = con.random() * 100

    if r < 2 then
      c.chunks[kx][ky] = new_chunk(c, kx,ky, "room")
    elseif r < 12 then
      c.chunks[kx][ky] = new_chunk(c, kx,ky, "cage")
      c.smex_cage = true
    end

    void_it_up(c)
  end

  local function add_dm_exit(c)

    if c.chunks[1][3] then
      con.printf("WARNING: deathmatch exit stomped a chunk!\n")
    end

    local K = new_chunk(c, 1,3, "void")
    K.dm_exit = true
    K.dir = 2

    c.chunks[1][3] = K

    if not c.chunks[1][2] then
      c.chunks[1][2] = new_chunk(c, 1,2, "room")
    end
  end

  local function flesh_out_cell(c)
    
    if p.deathmatch and c.x == 1 and c.y == p.h then
      add_dm_exit(c)
    end

    -- possibilities:
    --   (a) fill unused chunks with void
    --   (b) fill unused chunks with room
    --   (c) fill unused chunk from nearby ledge

    -- FIXME get probabilities from theme
    local kinds = { "room", "void", "flush", "cage", "liquid" }
    local probs = { 60, 10, 97, 5, 70 }

    if not c.theme.outdoor then probs[2] = 15 end

    if settings.mons == "less" then probs[4] = 3.2 end
    if settings.mons == "more" then probs[4] = 7.5 end

    if p.deathmatch then probs[4] = 0 end

    if c.scenic then probs[2] = 2; probs[4] = 0 end

    -- special handling for hallways...
    if c.hallway then
      if rand_odds(probs[4]) then
        try_add_special(c, "cage")
      end
      void_it_up(c)
    end

    if c.small_exit then
      grow_small_exit(c)
    end

    if c.scenic and c.vista_from then
      -- Bleh...
      if c.liquid and rand_odds(75) then
        void_it_up(c, "liquid")
      else
        void_it_up(c, "room")
      end
    end

    while count_empty_chunks(c) > 0 do

      local idx = rand_index_by_probs(probs)
      local kind = kinds[idx]

      if kind == "room" then
        try_grow_room(c)
      elseif kind == "void" then
        void_it_up(c)
      elseif kind == "flush" then
        try_flush_side(c)
      else
        try_add_special(c, kind)
      end
    end
  end

  local function setup_chunk_rmodels(c)

    for kx = 1,KW do for ky = 1,KH do
      local K = c.chunks[kx][ky]
      assert(K)

      K.rmodel = copy_table(c.rmodel)

      if K.link then
        local other = link_other(K.link, c)

        if K.link.build == c or K.link.kind == "falloff" then
          -- no change
        else
          K.rmodel.f_h = other.rmodel.f_h
          K.rmodel.c_h = math.max(c.rmodel.c_h, other.rmodel.c_h) --FIXME (??)
        end

      elseif K.liquid then
        K.rmodel.f_h   = K.rmodel.f_h - 12
        K.rmodel.f_tex = c.liquid.floor
      end
    end end
  end

  local function connect_chunks(c)

    -- connected value:
    --   1 for connected chunk 
    --   0 for not-yet connected chunk 
    --   nil for unconnectable chunks (void space)

    local function init_connx()

      for kx = 1,KW do for ky = 1,KH do
        local K = c.chunks[kx][ky]
        assert(K)

        if K.void or K.cage or K.vista then
          -- skip it

        elseif K.room then
          K.connected = 1

        elseif K.liquid or K.link then

          -- Note: cannot assume that it connects
          -- (it might be an isolated corner).
          K.connected = 0
        else
          error("connect_chunks: type is unknown!")
        end
      end end
    end

    local function grow_pass()

      local function grow_a_pair(K, N)
        if N.connected == 0 then
          if math.abs(K.rmodel.f_h - N.rmodel.f_h) <= 16 then
            N.connected = 1
          end
        end
      end

      for kx = 1,KW do for ky = 1,KH do
        local K = c.chunks[kx][ky]

        if K.connected == 1 then
          for dir = 2,8,2 do
            local dx,dy = dir_to_delta(dir)

            if valid_chunk(kx+dx,ky+dy) then
              grow_a_pair(K, c.chunks[kx+dx][ky+dy])
            end
          end
        end
      end end
    end

    local function grow_connx()
      for loop=1,10 do
        grow_pass()
      end
    end

    local function find_stair_pos()
      local best_diff = 999999
      local coords = {}

      for kx = 1,KW do for ky = 1,KH do
        local K = c.chunks[kx][ky]

        if K.connected == 0 then
          for dir = 2,8,2 do
            local dx,dy = dir_to_delta(dir)

            if valid_chunk(kx+dx, ky+dy) and
               c.chunks[kx+dx][ky+dy].connected == 1
            then
              local N = c.chunks[kx+dx][ky+dy]
              local diff = math.abs(K.rmodel.f_h - N.rmodel.f_h)

              if diff < best_diff then
                -- clear out previous (worse) results
                coords = {}
                best_diff = diff
              end

              if diff == best_diff then
                local loc = { x=kx, y=ky, dir=dir }
                table.insert(coords, loc)
              end
            end
          end
        end
      end end

      if #coords == 0 then return nil end

      return rand_shuffle(coords)
    end


    --- connect_chunks ---

    init_connx()

    for loop=1,99 do
      
      grow_connx()
      
      local loc = find_stair_pos()
      if not loc then break end

      local K = c.chunks[loc.x][loc.y]

--[[  DEBUG STAIR LOCS
local dx,dy = dir_to_delta(loc.dir)
  con.debugf(
  "CELL (%d,%d)  STAIR %d,%d facing %d  HT %d -> %d\n",
  c.x, c.y, loc.x, loc.y, loc.dir,
  K.delta_floor, c.chunks[loc.x+dx][loc.y+dy].delta_floor
  )
--]]
      assert(not K.stair_dir)

      K.stair_dir = loc.dir
      K.connected = 1
    end 

    --> result: certain chunks have a "stair_dir" field
    -->         Direction to neighbour chunk.  Stair will
    -->         be built inside this chunk.

    -- FIXME: randomly flip a few stairs.
    --   Requires:
    --     no stair_dir in neighbour
    --     neighbour "has space" (not building door, etc)
    --     ???
    --   Especially good: center -> ledge with centered door
  end

  local function good_Q_spot(c) -- REMOVE (use block-based alloc)

    assert(not p.deathmatch)

    local function k_dist(kx,ky)
      local side = c.entry_dir or c.exit_dir or 2

      if side==4 then return kx-1  end
      if side==6 then return KW-kx end
      if side==2 then return ky-1  end
      if side==8 then return KH-ky end
    end

---##  local in_x, in_y = side_to_chunk(c.entry_dir or c.exit_dir)

    local best_x, best_y
    local best_score = -10

    for kx = 1,KW do
      for ky = 1,KH do
        if c.chunks[kx][ky] and
           not (c.chunks[kx][ky].void or c.chunks[kx][ky].cage or
                c.chunks[kx][ky].quest or c.chunks[kx][ky].vista)
        then
          local score = k_dist(kx, ky)
          score = score + con.random() * 0.5
          if c.chunks[kx][ky].rmodel.f_h == c.rmodel.f_h then score = score + 1.7 end

          if score > best_score then
            best_score = score
            best_x, best_y = kx,ky
          end
        end
      end
    end

---##  if not best_x then error("NO FREE SPOT!") end

    return best_x, best_y
  end

  local function position_sp_stuff(c)

    if c == p.quests[1].first then
      local kx, ky = good_Q_spot(c, true)
      if not kx then error("NO FREE SPOT for Player!") end
      c.chunks[kx][ky].player=true
    end

    if c == c.quest.last then
      local can_vista = (c.quest.kind == "key") or
              (c.quest.kind == "weapon") or (c.quest.kind == "item")
      local kx, ky = good_Q_spot(c, can_vista)
      if not kx then error("NO FREE SPOT for Quest Item!") end
      c.chunks[kx][ky].quest=true

      --[[ NOT NEEDED?
      if p.coop and (c.quest.kind == "weapon") then
        local total = rand_index_by_probs { 10, 50, 90, 50 }
        for i = 2,total do
          local kx, ky = good_Q_spot(c)
          if kx then c.chunks[kx][ky].quest=true end
        end
      end
      --]]
    end
  end

  local function position_dm_stuff(c)

    local spots = {}

    local function get_spot()
      if #spots == 0 then return nil end
      return table.remove(spots, 1)
    end

    local function reusable_spot()
      if #spots == 0 then return nil end
      local S = table.remove(spots,1)
      table.insert(spots, S)
      return S
    end
    
    --- position_dm_stuff ---

    for kx = 1,KW do for ky = 1,KH do
      local K = c.chunks[kx][ky]
      if K and (K.room or K.liquid or K.link) and not K.stair_dir then
        table.insert(spots, {x=kx, y=ky, K=K})
      end
    end end

    rand_shuffle(spots)

    -- guarantee at least 4 players (each corner)
    if (c.x==1) or (c.x==p.w) or (c.y==1) or (c.y==p.h) or rand_odds(66) then
      local spot = get_spot()
      if spot then spot.K.player = true end
    end

    -- guarantee at least one weapon (central cell)
    if (c.x==int((p.w+1)/2)) or (c.y==int((p.h+1)/2)) or rand_odds(70) then
      local spot = get_spot()
      if spot then spot.K.dm_weapon = choose_dm_thing(THEME.dm.weapons, true) end
    end

    -- secondary players and weapons
    if rand_odds(33) then
      local spot = get_spot()
      if spot then spot.K.player = true end
    end
    if rand_odds(15) then
      local spot = get_spot()
      if spot then spot.K.dm_weapon = choose_dm_thing(THEME.dm.weapons, true) end
    end

    -- from here on we REUSE the spots --

    if #spots == 0 then return end

    -- health, ammo and items
    if rand_odds(70) then
      local spot = reusable_spot()
      spot.K.dm_health = choose_dm_thing(THEME.dm.health, false)
    end

    if rand_odds(90) then
      local spot = reusable_spot()
      spot.K.dm_ammo = choose_dm_thing(THEME.dm.ammo, true)
    end
 
    if rand_odds(10) then
      local spot = reusable_spot()
      spot.K.dm_item = choose_dm_thing(THEME.dm.items, true)
    end

    -- secondary health and ammo
    if rand_odds(10) then
      local spot = reusable_spot()
      spot.K.dm_health = choose_dm_thing(THEME.dm.health, false)
    end
    if rand_odds(30) then
      local spot = reusable_spot()
      spot.K.dm_ammo = choose_dm_thing(THEME.dm.ammo, true)
    end
  end

  --==-- make_chunks --==--

  for zzz,link in ipairs(p.all_links) do
    link.where = random_where(link)
  end

  -- firstly, allocate chunks based on exit locations

  for loop=1,999 do
    local clashes = 0

    for zzz,cell in ipairs(p.all_cells) do
      if not put_chunks_in_cell(cell) then
        clashes = clashes + 1
      end
    end

    con.debugf("MAKING CHUNKS: %d clashes\n", clashes)

    if clashes == 0 then break end
  end

  -- secondly, determine main walk areas

  for zzz,cell in ipairs(p.all_cells) do

      add_closet_chunks(cell)

      add_travel_chunks(cell)

      add_vista_chunks(cell)

  end

  for zzz,cell in ipairs(p.all_cells) do

      flesh_out_cell(cell)

      setup_chunk_rmodels(cell)

      connect_chunks(cell)
  end

  for zzz,cell in ipairs(p.all_cells) do
      if p.deathmatch then
        position_dm_stuff(cell)
      else
        position_sp_stuff(cell)
      end
  end
end


function setup_borders_and_corners(p)

  -- for each border and corner: decide on the type, the theme,
  -- and which cell is ultimately responsible for building it.

  local function border_theme(cells)
    assert(#cells >= 1)

    if #cells == 1 then return cells[1].theme end

    for zzz,c in ipairs(cells) do
      if c.is_exit then return c.theme end
    end

--[[    for zzz,c in ipairs(cells) do
      if c.scenic == "solid" then return c.theme end
    end
--]]
    local themes = {}
    local hall_num = 0

    for zzz,c in ipairs(cells) do
      if c.hallway then hall_num = hall_num + 1 end
      table.insert(themes, c.theme)
    end
  
    -- when some cells are hallways and some are not, we
    -- upgrade the hallways to their "outer" theme.

    if (hall_num > 0) and (#cells - hall_num > 0) then
      for idx = 1,#themes do
        if cells[idx].hallway then
          themes[idx] = cells[idx].quest.theme
        end
      end
    end

    -- when some cells are outdoor and some are indoor,
    -- remove the outdoor themes from consideration.

    local out_num = 0

    for zzz,T in ipairs(themes) do
      if T.outdoor then out_num = out_num + 1 end
    end
    
    if (out_num > 0) and (#themes - out_num > 0) then
      for idx = #themes,1,-1 do
        if themes[idx].outdoor then
          table.remove(themes, idx)
        end
      end
    end

    if #themes >= 2 then
      table.sort(themes, function(t1, t2) return t1.mat_pri < t2.mat_pri end)
    end

    return themes[1]
  end


  local function border_kind(c1, c2, side)

    if not c2 or c2.is_depot then
      if c1.theme.outdoor then return "sky" end
      return "solid"
    end

    if c1.scenic == "solid" or c2.scenic == "solid" then
      return "solid"
    end

    if c1.hallway or c2.hallway then return "solid" end

    -- TODO: sometimes allow it
    if c1.is_exit or c2.is_exit then return "solid" end

    if c1.border[side].window then return "window" end

---###    local link = c1.link[side]
---###
---###    if link then assert(c2) end

---###    if link and (link.kind == "arch") and c1.theme == c2.theme and
---###       (c1.quest.parent or c1.quest) == (c2.quest.parent or c2.quest) and
---###       dual_odds(c1.theme.outdoor, 50, 33)
---###    then
---###       return "empty"
---###    end

    -- fencing anyone?   FIXME: move tests into Planner
    local diff_h = math.min(c1.ceil_h, c2.ceil_h) - math.max(c1.f_max, c2.f_max)

    if (c1.theme.outdoor == c2.theme.outdoor) and
       (not c1.is_exit  and not c2.is_exit) and
       (not c1.is_depot and not c2.is_depot) and diff_h > 64
    then
      if c1.scenic or c2.scenic then
        return "fence"
      end

      if dual_odds(c1.theme.outdoor, 60, 7) then
        return "fence"
      end

---###      local i_W = sel(link, 3, 20)
---###      local i_F = sel(c1.theme == c2.theme, 5, 0)
---###
---###      if dual_odds(c1.theme.outdoor, 25, i_W) then return "wire" end
---###      if dual_odds(c1.theme.outdoor, 60, i_F) then return "fence" end
    end
 
    return "solid"
  end


  --[[ UNNEEDED
  local function adjust(c, side, D, c2, side2, E)

    if E.x1 > D.x2 or E.x2 < D.x1 then return end
    if E.y1 > D.y2 or E.y2 < D.y1 then return end

    local function dump_it()
      con.printf("Borders @ (%d,%d):%d and (%d,%d):%d\n",
          c.x, c.y, side, c2.x, c2.y, side2)
      con.printf("D = (%d,%d)..(%d,%d)   E = (%d,%d)..(%d,%d)\n",
          D.x1, D.y1, D.x2, D.y2, E.x1, E.y1, E.x2, E.y2)
      con.printf("OV = (%d,%d)..(%d,%d)  BB = (%d,%d)..(%d,%d)\n",
          ox, oy, ox2, oy2, bb_x1, bb_y1, bb_x2, bb_y2)
    end
    
    -- determine overlap position
    
    local ox  = math.max(D.x1, E.x1)
    local oy  = math.max(D.y1, E.y1)
    local ox2 = math.min(D.x2, E.x2)
    local oy2 = math.min(D.y2, E.y2)

    local bb_x1 = math.min(D.x1, E.x1)  -- bounding box
    local bb_y1 = math.min(D.y1, E.y1)
    local bb_x2 = math.max(D.x2, E.x2)
    local bb_y2 = math.max(D.y2, E.y2)

    -- sanity check
    if ox2 ~= ox or oy2 ~= oy or
       (bb_x1 < ox and bb_x2 > ox and bb_y1 < oy and bb_y2 > oy)
    then
      dump_it(); error("Bad border overlap")
    end

    -- check for T-junctions
    if (bb_x1 < ox and bb_x2 > ox and (bb_y1 < oy or bb_y2 > oy) )
    or (bb_y1 < oy and bb_y2 > oy and (bb_x1 < ox or bb_x2 > ox) )
    then
      dump_it(); error("Border T-junction found")
    end

    -- OK, both borders only touch at a corner.
    -- Decide which one to adjust...

    if D.theme ~= E.theme then
      local cells = { c, c2 }

      local n1 = neighbour_by_side(p, c,  side)
      local n2 = neighbour_by_side(p, c2, side2)

      if n1 then table.insert(cells, n1) end
      if n2 then table.insert(cells, n2) end

      local T = border_theme(cells)
      
      if D.theme == T then D,E = E,D end
    end

    if D.x1 == D.x2 then
      -- vertical
          if D.y1 == oy then D.y1 = D.y1 + 1; D.low_corner  = false
      elseif D.y2 == oy then D.y2 = D.y2 - 1; D.high_corner = false
      else
        dump_it(); error("Bad border L-junction")
      end
    else
      -- horizontal
      assert(D.y1 == D.y2)
          if D.x1 == ox then D.x1 = D.x1 + 1; D.low_corner  = false
      elseif D.x2 == ox then D.x2 = D.x2 - 1; D.high_corner = false  
      else
        dump_it(); error("Bad border L-junction")
      end
    end
  end

  local function jiggle(c, side)

    local D = c.border[side]
    if D.jiggled then return end -- already done

    -- these will be cleared if the border is adjusted
    D.low_corner  = true
    D.high_corner = true

    for dx = -1,1 do for dy = -1,1 do
      local c2 = valid_cell(p, c.x+dx, c.y+dy) and p.cells[c.x+dx][c.y+dy]
      if c2 then
        for side2 = 2,8,2 do
          local E = c2.border[side2]
          if E and E ~= D and not E.build then
            adjust(c, side, D, c2, side2, E)

            assert(D.x2 >= D.x1 and D.y2 >= D.y1)
            assert(E.x2 >= E.x1 and E.y2 >= E.y1)
          end
        end
      end
    end end

    D.jiggled = true
  end
  --]]

  local function init_border(c, side)

    local D = c.border[side]
    if D.build then return end -- already done

    -- which cell actually builds the border is arbitrary, unless
    -- there is a link with the other cell
    if c.link[side] then
      D.build = c.link[side].build
    else
      D.build = c
    end

    local other = neighbour_by_side(p,c, side)

    D.theme = border_theme(D.cells)
    D.kind  = border_kind (c, other, side)
  end

  local function init_corner(c, side)

    local E = c.corner[side]
    if E.build then return end -- already done

    E.build = c
    E.theme = border_theme(E.cells)
    E.kind  = "solid"
  end

  --- setup_borders_and_corners ---

  for zzz,c in ipairs(p.all_cells) do

    for side = 1,9 do
      if c.border[side] then init_border(c, side) end
    end
    for side = 1,9,2 do
      if c.corner[side] then init_corner(c, side) end
    end
  end
end

----------------------------------------------------------------


function build_cell(p, c)
 
  local function valid_and_empty(cx, cy)
    return valid_cell(p, cx, cy) and not p.cells[cx][cy]
  end

  local function player_angle(kx, ky)

    if c.exit_dir then
      return dir_to_angle(c.exit_dir)
    end

    -- when in middle of room, find an exit to look at
    if (kx==2 and ky==2) then
      for i = 1,20 do
        local dir = rand_irange(1,4)*2
        if c.link[dir] then
          return dir_to_angle(dir)
        end
      end

      return rand_irange(1,4)*2
    end

    return delta_to_angle(2-kx, 2-ky)
  end

  local function decide_void_pic(p, c)
    if c.theme.pic_wd and rand_odds(60) then
      c.void_pic = { wall=c.theme.pic_wd, w=128, h=c.theme.pic_wd_h or 128 }
      c.void_cut = 1
      return

    elseif not c.theme.outdoor and rand_odds(25) then
      c.void_pic = get_rand_wall_light()
      c.void_cut = rand_irange(3,4)
      return

    else
      c.void_pic = get_rand_pic()
      c.void_cut = 1
    end
  end

  local function build_real_link(link, side, where)

    -- DIR here points to center of current cell
    local dir = 10-side  -- FIXME: remove

    assert (link.build == c)

    local other = link_other(link, c)
    assert(other)

    local D = c.border[side]
    if not D then return end

    local b_theme = D.theme

    local x, y
    local dx, dy = dir_to_delta(dir)
    local ax, ay = dir_to_across(dir)

    local long = link.long or 2

    local d_min = 1
    local d_max = BW

    local d_pos
    
    if link.where == "wide" then
      d_pos = d_min + 1
      long  = d_max - d_min - 1
    else
      d_pos = where_to_block(where, long)
      d_max = d_max - (long-1)

      if (d_pos < d_min) then d_pos = d_min end
      if (d_pos > d_max) then d_pos = d_max end
    end

        if side == 2 then x,y = d_pos, 1
    elseif side == 8 then x,y = d_pos, BH
    elseif side == 4 then x,y =  1, d_pos
    elseif side == 6 then x,y = BW, d_pos
    end

    x = D.x1
    y = D.y1

    if (link.kind == "arch" or link.kind == "falloff") then

---###      if D.kind == "empty" then return end  -- no arch needed

      local ex, ey = x + ax*(long-1), y + ay*(long-1)
      local tex = b_theme.wall

      -- sometimes leave it empty
      if D.kind == "wire" then link.arch_rand = link.arch_rand * 4 end

      if link.kind == "arch" and link.where ~= "wide" and
        c.theme.outdoor == other.theme.outdoor and
        ((c.theme.outdoor and link.arch_rand < 50) or
         (not c.theme.outdoor and link.arch_rand < 10))
      then
        local sec = copy_block(c.rmodel)
sec.f_tex = "FWATER1"
        sec.l_tex = tex
        sec.u_tex = tex
        fill(p,c, x, y, ex, ey, sec)
        return
      end

      local arch = copy_block(c.rmodel)
      arch.c_h = math.min(c.ceil_h-32, other.ceil_h-32, c.floor_h+128)
      arch.f_tex = c.theme.arch_floor or c.rmodel.f_tex
      arch.c_tex = c.theme.arch_ceil  or arch.f_tex
arch.f_tex = "TLITE6_6"

      if (arch.c_h - arch.f_h) < 64 then
        arch.c_h = arch.f_h + 64
      end

      if c.hallway and other.hallway then
        arch.light = (c.rmodel.light + other.rmodel.light) / 2.0
      elseif c.theme.outdoor then
        arch.light = arch.light - 32
      else
        arch.light = arch.light - 16
      end

      local special_arch

      if link.where == "wide" and THEME.mats.ARCH and rand_odds(70) then
        special_arch = true

        arch.c_h = math.max(arch.c_h, c.ceil_h - 48)
        arch.c_tex = THEME.mats.ARCH.ceil

        tex = THEME.mats.ARCH.wall

        fill(p,c, x, y, ex+ax, ey+ay, { solid=tex })
      end

      arch.l_tex = tex
      arch.u_tex = tex

      fill(p,c, x, y, ex+ax, ey+ay, { solid=tex })
      fill(p,c, x+ax, y+ay, ex, ey, arch)

      if link.block_sound then
        -- FIXME block_sound(p, c, x,y, ex,ey, 1)
      end

      -- pillar in middle of special arch
      if link.where == "wide" then
        long = int((long-1) / 2)
        x, y  = x+long*ax,  y+long*ay
        ex,ey = ex-long*ax, ey-long*ay

        if x == ex and y == ey then
          fill(p,c, x, y, ex, ey, { solid=tex })
        end
      end

    elseif link.kind == "door" and link.is_exit and not link.quest then

      B_exit_door(p,c, c.theme, link, x, y, c.floor_h, dir)

    elseif link.kind == "door" and link.quest and link.quest.kind == "switch" and
       THEME.switches[link.quest.item].bars
    then
      local info = THEME.switches[link.quest.item]
      local sec = copy_block_with_new(c.rmodel,
      {
        f_tex = b_theme.floor,
        c_tex = b_theme.ceil,
      })

      if not (c.theme.outdoor and other.theme.outdoor) then
        sec.c_h = sec.c_h - 32
        while sec.c_h > (sec.c_h+sec.f_h+128)/2 do
          sec.c_h = sec.c_h - 32
        end
        if b_theme.outdoor then sec.c_tex = b_theme.arch_ceil or sec.f_tex end
      end

      local bar = link.bar_size
      local tag = link.quest.tag + 1

      B_bars(p,c, x,y, math.min(dir,10-dir),long, bar,bar*2, info, sec,b_theme.wall, tag,true)

    elseif link.kind == "door" then

      local kind = link.wide_door

      if c.quest == other.quest
        and link.door_rand < sel(c.theme.outdoor or other.theme.outdoor, 10, 20)
      then
        kind = link.narrow_door
      end

      local info = THEME.doors[kind]
      assert(info)

      local door_kind = 1
      local tag = nil
      local key_tex = nil

      if dual_odds(p.deathmatch, 75, 15) then
        door_kind = 117 -- Blaze
      end

      if link.quest and link.quest.kind == "key" then
        local bit = THEME.key_bits[link.quest.item]
        assert(bit)
        door_kind = sel(p.coop, bit.kind_once, bit.kind_rep)
        key_tex = bit.wall -- can be nil
        if bit.thing then
          -- FIXME: heretic statues !!!
        end
        if bit.door then
          kind = bit.door
          info = THEME.doors[kind]
          assert(info)
        end
      end

      if link.quest and link.quest.kind == "switch" then
        door_kind = nil
        tag = link.quest.tag + 1
        key_tex = THEME.switches[link.quest.item].wall
        assert(key_tex)
      end

      B_door(p, c, link, b_theme, x, y, c.floor_h, dir,
             1 + int(info.w / 64), 1, info, door_kind, tag, key_tex)
    else
      error("build_link: bad kind: " .. tostring(link.kind))
    end
  end

  local function build_link(side)

    local link = c.link[side]
    if not (link and link.build == c) then return end

    link.narrow_door = random_door_kind(64)
    link.wide_door   = random_door_kind(128)
    link.block_sound = rand_odds(90)
    link.bar_size    = rand_index_by_probs { 20,90 }
    link.arch_rand   = con.random() * 100
    link.door_rand   = con.random() * 100

    if link.where == "double" then
      local awh = rand_irange(2,3)
      build_real_link(link, side, -awh)
      build_real_link(link, side,  awh)
    else
      build_real_link(link, side, link.where)
    end
  end

  local function chunk_pair(cell, other, side,n)
    local cx,cy, ox,oy
    
        if side == 2 then cx,cy,ox,oy = n,1,n,KH
    elseif side == 8 then cx,cy,ox,oy = n,KH,n,1
    elseif side == 4 then cx,cy,ox,oy = 1,n,KW,n
    elseif side == 6 then cx,cy,ox,oy = KW,n,1,n
    end

    return cell.chunks[cx][cy], other.chunks[ox][oy]
  end

  local function border_floor_range(other, side)
    assert(other)

    local f_min, f_max = 65536, -65536

    for n = 1,KW do
      local K1, K2 = chunk_pair(c, other, side,n)
 
      if not (K1.void or K1.cage or K1.vista) then
        f_max = math.max(f_max, K1.rmodel.f_h)
        f_min = math.min(f_min, K1.rmodel.f_h)
      end
      if not (K2.void or K2.cage or K2.vista) then
        f_max = math.max(f_max, K2.rmodel.f_h)
        f_min = math.min(f_min, K2.rmodel.f_h)
      end
    end

    if f_min == 65536 then return nil, nil end

    return f_min, f_max
  end

  local function corner_tex(c, dx, dy)
    -- FIXME: use *border* themes, not cell themes

    local themes = { }

    local function try_add_one(x, y)
      if not valid_cell(p, x, y) then return end
      local cell = p.cells[x][y]
      if not cell then return end
      assert(cell.theme)
      table.insert(themes, cell.theme)
    end

    try_add_one(c.x+dx, c.y)
    try_add_one(c.x,    c.y+dy)
    try_add_one(c.x+dx, c.y+dy)

    local best = c.theme

    for zzz,T in ipairs(themes) do
      if not T.outdoor and best.outdoor then
        best = T
      elseif T.outdoor == best.outdoor then
        if T.mat_pri > best.mat_pri then
          best = T
        elseif T.mat_pri == best.mat_pri and rand_odds(50) then
          best = T
        end
      end
    end
    --[[ ORIG
    for zzz,T in ipairs(themes) do
      if T.mat_pri > best.mat_pri then
        best = T
      elseif T.mat_pri == best.mat_pri then
        if not T.outdoor and best.outdoor then
          best = T
        elseif not (T.outdoor or best.outdoor) and rand_odds(50) then
          best = T
        end
      end
    end --]]

    return best.void
  end

  local function build_sky_border(side, x1,y1, x2,y2)

    local WALL =
    {
      f_h = c.f_max + 48,
      f_tex = c.rmodel.f_tex,
      l_tex = c.rmodel.l_tex,

      c_h = c.rmodel.c_h,
      c_tex = c.rmodel.c_tex,
      u_tex = c.rmodel.u_tex,

      light = c.rmodel.light,
    }

    local BEHIND =
    {
      f_h = c.f_min - 512,
      c_h = c.f_min - 508,
      f_tex = c.rmodel.f_tex,
      c_tex = c.rmodel.c_tex,
      l_tex = c.rmodel.l_tex,
      u_tex = c.rmodel.u_tex,
      light = c.rmodel.light,
    }

    local ax1, ay1, ax2, ay2 = side_coords(10-side, 1,1, FW,FH)

    for x = x1,x2 do for y = y1,y2 do

      local B = p.blocks[x][y]

      -- overwrite a 64x64 block, but not a fragmented one
      if (not B) or (not B.fragments) then

        local fx = (x - 1) * FW
        local fy = (y - 1) * FH

        frag_fill(p,c, fx+  1, fy+  1, fx+ FW, fy+ FH, BEHIND)
        frag_fill(p,c, fx+ax1, fy+ay1, fx+ax2, fy+ay2, WALL)
      end

    end end
  end

  local function build_sky_corner(x, y, wx, wy)

    local WALL =
    {
      f_h = c.f_max + 48, c_h = c.rmodel.c_h,
      f_tex = c.rmodel.f_tex, c_tex = c.rmodel.c_tex,
      light = c.rmodel.light,
      l_tex = c.rmodel.l_tex,
      u_tex = c.rmodel.u_tex,
    }

    local BEHIND =
    {
      f_h = c.f_min - 512, c_h = c.f_min - 508,
      f_tex = c.rmodel.f_tex, c_tex = c.rmodel.c_tex,
      light = c.rmodel.light,
      l_tex = c.rmodel.l_tex,
      u_tex = c.rmodel.u_tex,
    }

    if not p.blocks[x][y] then

      local fx = (x - 1) * FW
      local fy = (y - 1) * FH

      frag_fill(p,c, fx+ 1, fy+ 1, fx+FW, fy+FH, BEHIND)
      frag_fill(p,c, fx+wx, fy+wy, fx+wx, fy+wy, WALL)
    end
  end

  local function build_fence(side, x1,y1, x2,y2, other, what, b_theme)

    local D = c.border[side]

      local FENCE = copy_block_with_new(c.rmodel,
      {
        f_h = math.max(c.f_max, other.f_max),
        f_tex = b_theme.floor,
        c_tex = b_theme.ceil,
        
        l_tex = b_theme.void,
        u_tex = b_theme.void,
      })

--?? local f_min, f_max = border_floor_range(other, side)

    if rand_odds(95) then FENCE.block_sound = 2 end

FENCE.f_tex = "LAVA1" --!!! TESTING

    -- determine fence kind

    local kind = "plain"
    
    if rand_odds(30) then kind = "wire" end

    -- FIXME: "castley"

--[[ 
    if c1.scenic or c2.scenic then
      return rand_sel(30, "wire", "fence")
    end

    local i_W = sel(link, 3, 20)
    local i_F = sel(c1.theme == c2.theme, 5, 0)

    if dual_odds(c1.theme.outdoor, 25, i_W) then return "wire" end
    if dual_odds(c1.theme.outdoor, 60, i_F) then return "fence" end
--]]

    -- FIXME: choose fence rail

    if kind == "plain" then
      FENCE.f_h = FENCE.f_h + 48+16*rand_irange(0,2)
      if other.scenic then FENCE.impassible = true end

    elseif kind == "wire" then
      local rail_tex =THEME.rails["r_1"].wall

      if x1==x2 and y1==y2 then
        FENCE.rail = rail_tex
      else
        local rsd = side

        if (rsd % 2) == 1 then
          rsd = sel(x1==x2, 4, 2)
        end

        if b_theme ~= c.theme then rsd = 10 - side end

        FENCE[rsd] = { rail = rail_tex }
      end
    else
      error("build_fence: unknown kind: " .. kind)
    end

    gap_fill(p,c, x1,y1, x2,y2, FENCE)

--[[
    for n = 1,KW do --!!!!! 1,KW   FIXME: sx,sy (etc) are floats!!!
        -- FIXME: ICK!!! FIXME
        local sx = x1 + (x2-x1+1) * (n-1) / KW
        local sy = y1 + (y2-y1+1) * (n-1) / KH
        local ex = x1 + (x2-x1+1) * (n  ) / KW
        local ey = y1 + (y2-y1+1) * (n  ) / KH
        if x1 == x2 then sx,ex = x1,x1 end
        if y1 == y2 then sy,ey = y1,y1 end
        ex = ex + (sx-ex)/KW
        ey = ey + (sy-ey)/KH

      local K1, K2 = chunk_pair(c, other, side, n)

      if (K1.void or K1.cage) and (K2.void or K2.cage) then
        gap_fill(p,c, c.bx1-1+sx,c.bx1-1+sy, c.by1-1+ex,c.by1-1+ey, { solid=b_theme.void})
      else
        local sec

        if what == "empty" then
          sec = copy_block(EMPTY)

          if K1.liquid or K2.liquid then
            sec.f_h = math.max(K1.rmodel.f_h or -65536, K2.rmodel.f_h or -65536)
            if K1.liquid == K2.liquid and K1.rmodel.f_h == K2.rmodel.f_h then
              sec.f_h = sec.f_h + 16
            end
          else
            sec.f_h = math.min(K1.rmodel.f_h or  65536, K2.rmodel.f_h or  65536)
          end

        else -- wire fence (floor already set)
          sec = EMPTY
        end

        sec.l_tex = b_theme.wall
        sec.u_tex = b_theme.wall

        gap_fill(p,c, c.bx1-1+sx,c.by1-1+sy, c.bx1-1+ex,c.by1-1+ey, sec, overrides)
      end
    end
--]]
  end

  local function build_window(side)

    local D = c.border[side]

    if not (D and D.window and D.build == c) then return end

    local link = c.link[side]
    local other = neighbour_by_side(p,c,side)

    local b_theme = D.theme

    local WINDOW = 
    {
      f_h = math.max(c.f_max, other.f_max) + 32,
      c_h = math.min(c.rmodel.c_h, other.rmodel.c_h) - 32,

      f_tex = b_theme.floor,
      c_tex = b_theme.ceil,

      l_tex = b_theme.wall,
      u_tex = b_theme.wall,

      light = c.rmodel.light,
    }

if (side%2)==1 then WINDOW.light=255; WINDOW.kind=8 end

    if other.scenic then WINDOW.impassible = true end

    WINDOW.light = WINDOW.light - 16
    WINDOW.c_tex = b_theme.arch_ceil or WINDOW.f_tex

---### YUCK  if (WINDOW.c_h - WINDOW.f_h) > 64 and rand_odds(30) then
---###         WINDOW.c_h = WINDOW.f_h + 64
---###       end

    local x = D.x1
    local y = D.y1

    local ax, ay = dir_to_across(D.side)

    while x <= D.x2 and y <= D.y2 do
      gap_fill(p,c, x, y, x, y, WINDOW)
      x, y = x+ax, y+ay
    end

--[[ GOOD OLD STUFF

    -- cohabitate nicely with doors
    local min_x, max_x = 1, BW

    if link then
      if link.where == "double" then return end
      if link.where == "wide"   then return end

      local l_long = link.long or 2
      local l_pos = where_to_block(link.where, l_long)
      if l_pos > (BW+1)/2 then
        max_x = l_pos - 2
      else
        min_x = l_pos + l_long + 1
      end

    elseif c.vista[side] then
      if rand_odds(50) then
        max_x = 3
      else
        min_x = BW-3+1
      end
    end

    local dx, dy = dir_to_delta(D.side)

    local x, y = side_coords(side, 1,1, BW,BH)

    x = c.bx1-1 + x+dx
    y = c.by1-1 + y+dy


    local long  = rand_index_by_probs { 30, 90, 10, 3 }
    local step  = long + rand_index_by_probs { 90, 30, 4 }
    local first = -1 + rand_index_by_probs { 90, 90, 30, 5, 2 }

    local bar, bar_step
    local bar_chance

    if D.kind == "fence" then
      bar_chance = 0.1
    else
      bar_chance = 10 + math.min(long,4) * 15
    end

    if rand_odds(bar_chance) then
      if long == 1 then bar = 1
      else bar = rand_index_by_probs { 90, 30 }
      end
      if bar > 1 then bar_step = 2 * bar
      else bar_step = 2 * rand_index_by_probs { 40, 80 }
      end
    end

    -- !!! FIXME: test crud
    if not bar and D.kind ~= "fence" then
      -- FIXME: choose window rail
      sec[side] = { rail = THEME.rails["r_2"].wall }
    end

    for d_pos = first, BW-long, step do
      local wx, wy = x + ax*d_pos, y + ay*d_pos

      if (d_pos+1) >= min_x and (d_pos+long) <= max_x then
        if bar then
          B_bars(p,c, wx,wy, math.min(side,10-side),long, bar,bar_step, THEME.mats.METAL, sec,b_theme.wall)
        else
          gap_fill(p,c, wx,wy, wx+ax*(long-1),wy+ay*(long-1), sec)
        end
      end
    end
--]]
  end

  --[[ OLD STUFF, REMOVE SOON
  local function who_build_border(c, side, other, link)

    if not other then
      return c
    end

    if link then
      return link.build
    end

    if c.vista_from == side then
      return other
    elseif c.vista[side] then
      return c
    end

    if c.theme.outdoor ~= other.theme.outdoor then
      return sel(c.theme.outdoor, other, c)
    end

    -- using 'not' because the scenic field has multiple values,
    -- but the decision must be binary.
    if (not c.scenic) ~= (not other.scenic) then
      return sel(c.scenic, other, c)
    end

---##  elseif (c.scenic == "solid") ~= (other.scenic == "solid") then
---##    return sel(c.scenic == "solid", 

    return sel(side > 5, other, c)
  end
  --]]

  local function build_corner(side)

    local E = c.corner[side]
    if not E then return end
    if E.build ~= c then return end

    -- handle outside corners
    local out_num = 0
    local f_max = -99999

    for zzz,c in ipairs(E.cells) do
      if c.theme.outdoor then out_num = out_num + 1 end
      f_max = math.max(c.f_max, f_max)
    end

    -- FIXME: determine corner_kind (like border_kind)
    if false then --!!!! out_num == #E.cells then

      local CORN = copy_block_with_new(E.cells[1].rmodel,
      {
        f_h = f_max + 64,
        f_tex = E.theme.floor,
        l_tex = E.theme.wall,
      })

      -- crappy substitute to using a real sky corner
      if out_num < 4 then CORN.c_h = CORN.f_h + 1 end

      if CORN.f_h < CORN.c_h then
        gap_fill(p,c, E.bx, E.by, E.bx, E.by, CORN)
        return
      end
    end

    gap_fill(p,c, E.bx, E.by, E.bx, E.by, { solid=E.theme.wall })
  end

  local function build_border(side)

    local D = c.border[side]
    if not D then return end
    if D.build ~= c then return end

    local link = c.link[side]
    local other = neighbour_by_side(p, c, side)

    local what = D.kind
    assert(what)

    local b_theme = D.theme
    assert(b_theme)

    if c.vista[side] then
      local kind = "open"
      local diff_h = c.floor_h - other.floor_h

      if diff_h >= 48 and rand_odds(35) then kind = "wire" end

      if not c.theme.outdoor then
        local space_h = other.ceil_h - c.floor_h
        local r = con.random() * 100

        if space_h >= 96 and space_h <= 256 and r < 15 then
          kind = "frame"
        elseif r < 60 then
          kind = "solid"
        end
      end

      B_vista(p,c, side, c.vista[side]*3-1, b_theme, kind)
    end

    local x1,y1, x2,y2 = D.x1, D.y1, D.x2, D.y2

---if (side % 2) == 1 then
---gap_fill(p,c, x1,y1, x2,y2, { solid="COMPBLUE" })
---return
---end

    if what == "wire" or what == "fence" then

      build_fence(side, x1,y1, x2,y2, other, what, b_theme)

---###      if other.scenic then FENCE.impassible = true end

    elseif what == "window" then
      build_window(side)

    elseif what == "sky" then
      build_sky_border(D.side, x1,y1, x2,y2)

      -- handle the corner (check adjacent side)
--[[ FIXME !!!!! "sky"
      for cr = 1,2 do
        local nb_side = 2
        if side == 2 or side == 8 then nb_side = 4 end
        if cr == 2 then nb_side = 10 - nb_side end

        local NB = neighbour_by_side(p, c, nb_side)

        local cx, cy = corn_x1, corn_y1
        if cr == 2 then cx, cy = corn_x2, corn_y2 end

        if NB then
          local NB_link = NB.link[side]
          local NB_other = neighbour_by_side(p, NB, side)

          if false then --!!!!! FIXME what_border_type(NB, NB_link, NB_other, side) == "sky" then
            build_sky_border(side, cx, cy, cx, cy)
          end
        else
          local wx, wy

          if cx < BW/2 then wx = FW else wx = 1 end
          if cy < BH/2 then wy = FH else wy = 1 end

          build_sky_corner(cx, cy, wx, wy)
        end
      end
--]]

    else -- solid
      gap_fill(p,c, x1,y1, x2,y2, { solid=b_theme.wall })
    end

  end

  local function build_chunk(kx, ky)

    local function link_is_door(c, side)
      return c.link[side] and c.link[side].kind == "door"
    end

    local function add_overhang_pillars(c, K, kx, ky, sec, l_tex, u_tex)
      local basex = K.x1
      local basey = K.y1

      sec = copy_block(sec)
      sec.l_tex = l_tex
      sec.u_tex = u_tex
      
      for side = 1,9,2 do
        if side ~= 5 then
          local jx, jy = dir_to_corner(side, JW, JH)
          local fx, fy = dir_to_corner(side, FW, FH)

          local bx, by = (basex + jx-1), (basey + jy-1)

          local pillar = true

          if (bx ==  1 and link_is_door(c, 4)) or
             (bx == BW and link_is_door(c, 6)) or
             (by ==  1 and link_is_door(c, 2)) or
             (by == BH and link_is_door(c, 8))
          then
            pillar = false
          end

          -- FIXME: interact better with stairs/lift

          jx,jy = (bx - 1)*FW, (by - 1)*FH

          frag_fill(p,c, jx+1, jy+1, jx+FW, jy+FH, sec)

          if pillar then
            frag_fill(p,c, jx+fx, jy+fy, jx+fx, jy+fy, { solid=K.sup_tex})
          end
        end
      end
    end


    local function wall_switch_dir(kx, ky, entry_dir)
      if not entry_dir then
        entry_dir = rand_irange(1,4)*2
      end
      
      if kx==2 and ky==2 then
        return entry_dir
      end

      if kx==2 then return sel(ky < 2, 8, 2) end
      if ky==2 then return sel(kx < 2, 6, 4) end

      return entry_dir
    end

    local function chunk_dm_offset()
      while true do
        local dx = rand_irange(1,3) - 2
        local dy = rand_irange(1,3) - 2
        if not (dx==0 and dy==0) then return dx,dy end
      end
    end

    local function add_dm_pickup(c, bx,by, name)
      -- FIXME: (a) check if middle blocked, (b) good patterns

      local cluster = 1
      if THEME.dm.cluster then cluster = THEME.dm.cluster[name] or 1 end
      assert(cluster >= 1 and cluster <= 8)

      local offsets = { 1,2,3,4, 6,7,8,9 }
      rand_shuffle(offsets)

      for i = 1,cluster do
        local dx, dy = dir_to_delta(offsets[i])
        add_thing(p, c, bx+dx, by+dy, name, false)
      end
    end

    ---=== build_chunk ===---

    local K = c.chunks[kx][ky]
    assert(K)

    if c.scenic == "solid" then
      gap_fill(p,c, K.x1, K.y1, K.x2, K.y2, { solid=c.theme.void })
      return
    end

    -- vista chunks are built by other room
    if K.vista then return end

    if K.void then
      --!!!!! TEST CRAP
      gap_fill(p,c, K.x1, K.y1, K.x2, K.y2, c.rmodel)
      do return end

      if K.closet then
        con.debugf("BUILDING CLOSET @ (%d,%d)\n", c.x, c.y)

        table.insert(K.place.spots,
          B_monster_closet(p,c, K,kx,ky, c.floor_h + 0,
            c.quest.closet.door_tag))

      elseif K.dm_exit then
        B_deathmatch_exit(p,c, K,kx,ky,K.dir)

      elseif THEME.pics and not c.small_exit
          and rand_odds(sel(c.theme.outdoor, 10, sel(c.hallway,20, 50)))
      then
        if not c.void_pic then decide_void_pic(p, c) end
        local pic,cut = c.void_pic,c.void_cut

        if not c.quest.image and (p.deathmatch or
             (c.quest.mini and rand_odds(33)))
        then
          pic = THEME.images[1]
          cut = 1
          c.quest.image = "pic"
        end

        B_void_pic(p,c, K,kx,ky, pic,cut)

      else
        gap_fill(p,c, K.x1, K.y1, K.x2, K.y2, { solid=c.theme.void })
      end
      return
    end -- K.void

    if K.cage then
      B_big_cage(p,c, THEME.mats.CAGE, K,kx,ky)
      return
    end

    if K.stair_dir then
      
      local dx, dy = dir_to_delta(K.stair_dir)
      local NB = c.chunks[kx+dx][ky+dy]

      local diff = math.abs(K.rmodel.f_h - NB.rmodel.f_h)

      local long = 2
      local deep = 1

      -- prefer no lifts in deathmatch
      if p.deathmatch and diff > 64 and rand_odds(88) then deep = 2 end

      -- FIXME: replace with proper "can walk" test !!!
      if (K.stair_dir == 6 and kx == 1 and c.border[4]) or
         (K.stair_dir == 4 and kx == 3 and c.border[6]) or
         (K.stair_dir == 8 and ky == 1 and c.border[2]) or
         (K.stair_dir == 2 and ky == 3 and c.border[8]) then
        deep = 1
      end

      local bx = (kx-1) * JW
      local by = (ky-1) * JH 

      if K.stair_dir == 8 then
        by = by + JH + 1 - deep
      elseif K.stair_dir == 2 then
        by = by + deep
      elseif ky == 1 then
        by = by + JH - 1
      elseif ky == 3 then
        by = by + 1
      else
        by = by + 1; if JH >= 4 then by = by + 1 end
      end

      if K.stair_dir == 6 then
        bx = bx + JW + 1 - deep
      elseif K.stair_dir == 4 then
        bx = bx + deep
      elseif kx == 1 then
        bx = bx + JW - 1
      elseif kx == 3 then
        bx = bx + 1
      else
        bx = bx + 1; if JW >= 4 then bx = bx + 1 end
      end

      local step = (NB.rmodel.f_h - K.rmodel.f_h) / deep / 4

      if math.abs(step) <= 16 then
        B_stair(p, c, c.bx1-1+bx, c.by1-1+by, K.rmodel.f_h, K.stair_dir,
                long, deep, (NB.rmodel.f_h - K.rmodel.f_h) / (deep * 4),
                { } )
      else
        B_lift(p, c, c.bx1-1+bx, c.by1-1+by,
               math.max(K.rmodel.f_h, NB.rmodel.f_h), K.stair_dir,
               long, deep, { } )
      end
    end  -- K.stair_dir


    local bx = K.x1 + 1
    local by = K.y1 + 1
    
    if K.player then
      local angle = player_angle(kx, ky)
      local offsets = sel(rand_odds(50), {1,3,7,9}, {2,4,6,8})
      if p.coop then
        for i = 1,4 do
          local dx,dy = dir_to_delta(offsets[i])
          if settings.game == "plutonia" then
            B_double_pedestal(p,c, bx+dx,by+dy, K.rmodel, THEME.special_ped)
          else
            B_pedestal(p, c, bx+dx, by+dy, K.rmodel, THEME.pedestals.PLAYER)
          end
          add_thing(p, c, bx+dx, by+dy, "player" .. tostring(i), true, angle)
          c.player_pos = {x=bx+dx, y=by+dy}
        end
      else
        if settings.game == "plutonia" then
          B_double_pedestal(p,c, bx,by, K.rmodel, THEME.special_ped)
        else
          B_pedestal(p, c, bx, by, K.rmodel, THEME.pedestals.PLAYER)
        end
        add_thing(p, c, bx, by, sel(p.deathmatch, "dm_player", "player1"), true, angle)
        c.player_pos = {x=bx, y=by}

        if p.deathmatch and not p.have_sp_player then
          add_thing(p, c, bx, by, "player1", true, angle)
          p.have_sp_player = true
        end
      end

    elseif K.dm_weapon then
      B_pedestal(p, c, bx, by, K.rmodel, THEME.pedestals.WEAPON)
      add_thing(p, c, bx, by, K.dm_weapon, true)

    elseif K.quest then

      if c.quest.kind == "key" or c.quest.kind == "weapon" or c.quest.kind == "item" then
        B_pedestal(p, c, bx, by, K.rmodel, THEME.pedestals.QUEST)

        -- weapon and keys are non-blocking, but we don't want
        -- a monster sitting on top of our quest item (especially
        -- when it has a pedestal).
        add_thing(p, c, bx, by, c.quest.item, true)

      elseif c.quest.kind == "switch" then
        local info = THEME.switches[c.quest.item]
        assert(info.switch)
        local kind = 103; if info.bars then kind = 23 end
        if rand_odds(40) then
          local side = wall_switch_dir(kx, ky, c.entry_dir)
          B_wall_switch(p,c, bx,by, K.rmodel.f_h, side, 2, info, kind, c.quest.tag + 1)
        else
          B_pillar_switch(p,c, K,bx,by, info,kind, c.quest.tag + 1)
        end

      elseif c.quest.kind == "exit" then
        assert(c.theme.switch)

        local side = wall_switch_dir(kx, ky, c.entry_dir)

        if settings.game == "plutonia" then
          B_double_pedestal(p,c, bx,by, K.rmodel, THEME.special_ped,
            { walk_kind = 52 }) -- FIXME "exit_W1"

        elseif c.small_exit and not c.smex_cage and rand_odds(80) then
          if c.theme.flush then
            B_flush_switch(p,c, bx,by, K.rmodel.f_h,side, c.theme.switch, 11)
          else
            B_wall_switch(p,c, bx,by, K.rmodel.f_h,side, 3, c.theme.switch, 11)
          end

          -- make the area behind the switch solid
          local x1, y1 = K.x1, K.y1
          local x2, y2 = K.x2, K.y2
              if side == 4 then x1 = x1+2
          elseif side == 6 then x2 = x2-2
          elseif side == 2 then y1 = y1+2
          elseif side == 8 then y2 = y2-2
          else   error("Bad side for small_exit switch: " .. side)
          end

          gap_fill(p,c, x1,y1, x2,y2, { solid=c.theme.wall })
          
        elseif c.theme.hole_tex and rand_odds(75) then
          B_exit_hole(p,c, K,kx,ky, c.rmodel)
          return
        elseif rand_odds(85) then
          B_floor_switch(p,c, bx,by, K.rmodel.f_h, side, c.theme.switch, 11)
        else
          B_pillar_switch(p,c, K,bx,by, c.theme.switch, 11)
        end
      end
    end -- if K.player | K.quest etc...


    ---| fill in the rest |---

    local sec = copy_block(K.rmodel)

    local surprise = c.quest.closet or c.quest.depot

    if K.quest and surprise and c == surprise.trigger_cell then

      sec.mark = allocate_mark(p)
      sec.walk_kind = 2
      sec.walk_tag  = surprise.door_tag
    end

    if K.liquid then  -- FIXME: put into setup_chunk_rmodels
      sec.kind = c.liquid.sec_kind
    end

    if K.player then

      sec.near_player = true;
      if not sec.kind then
        sec.kind = 9  -- FIXME: "secret"
      end

      if settings.mode == "coop" and settings.game == "plutonia" then
        sec.light = THEME.special_ped.coop_light
      end
    end

    -- TEST CRUD : overhangs
    if rand_odds(9) and c.theme.outdoor
      and (sec.c_h - sec.f_h <= 256)
      and not (c.quest.kind == "exit" and c.along == #c.quest.path-1)
      and not K.stair_dir
    then

      K.overhang = true

      if not c.overhang then
        local name
        name, c.overhang = rand_table_pair(THEME.hangs)
      end
      local overhang = c.overhang

      K.sup_tex = overhang.thin

      sec.c_tex = overhang.ceil
      sec.u_tex = overhang.upper

      sec.c_h = sec.c_h - (overhang.h or 24)
      sec.light = sec.light - 48
    end

    -- TEST CRUD : crates
    if not c.scenic and not K.stair_dir
      and THEME.crates
      and dual_odds(c.theme.outdoor, 20, 33)
      and (not c.hallway or rand_odds(25))
      and (not c.exit or rand_odds(50))
    then
      K.crate = true
      if not c.crate_theme then
        c.crate_theme = get_rand_crate()
      end
    end

    -- TEST CRUD : pillars
    if not K.crate and not c.scenic and not K.stair_dir
      and dual_odds(c.theme.outdoor, 12, 25)
      and (not c.hallway or rand_odds(15))
      and (not c.exit or rand_odds(22))
    then
      K.pillar = true
    end

    --FIXME: very cruddy check...
    if c.is_exit and chunk_touches_side(kx, ky, c.entry_dir) then
      K.crate  = nil
      K.pillar = nil
    end

    -- TEST CRUD : sky lights
    if c.sky_light then
      if kx==2 and ky==2 and c.sky_light.pattern == "pillar" then
        K.pillar = true
      end

      K.sky_light_sec = copy_block(sec)
      K.sky_light_sec.c_h   = sel(c.sky_light.is_sky, c.sky_h, sec.c_h + c.sky_light.h)
      K.sky_light_sec.c_tex = sel(c.sky_light.is_sky, THEME.SKY_TEX, c.sky_light.light_info.floor)
      K.sky_light_sec.light = 176
      K.sky_light_utex = c.sky_light.light_info.side

      -- make sure sky light doesn't come down too low
      K.sky_light_sec.c_h = math.max(K.sky_light_sec.c_h,
        sel(c.sky_light.is_sky, c.c_max+16, c.c_min))
    end
 
    ---- Chunk Fill ----

    local l_tex = c.rmodel.l_tex

    do
      assert(sec)

      if K.overhang then
        add_overhang_pillars(c, K, kx, ky, sec, sec.l_tex, sec.u_tex)
      end

      if K.sky_light_sec then
        local x1,y1,x2,y2 = K.x1,K.y1,K.x2,K.y2
        if kx==1  then x1=x1+1 end
        if kx==KW then x2=x2-1 end
        if ky==1  then y1=y1+1 end
        if ky==KH then y2=y2-1 end

        local func = SKY_LIGHT_FUNCS[c.sky_light.pattern]
        assert(func)

        local BB = copy_block(K.sky_light_sec)
        BB.l_tex = sec.l_tex
        BB.u_tex = K.sky_light_utex or sec.u_tex

        for x = x1,x2 do for y = y1,y2 do
          if func(kx,ky, x,y) then
            gap_fill(p,c, x,y, x,y, BB)
          end
        end end
      end

      -- get this *after* doing sky lights
      local blocked = p.blocks[K.x1+1][K.y1+1] --!!!

      if K.crate and not blocked then
        local theme = c.crate_theme
        if not c.quest.image and not c.quest.mini and
           (not p.image or rand_odds(11))
        then
          theme = THEME.images[2]
          c.quest.image = "crate"
          p.image = true
        end
        B_crate(p,c, theme, sec, kx,ky, K.x1+1,K.y1+1)
        blocked = true
      end

      if K.pillar and not blocked then

        -- TEST CRUD
        if rand_odds(22) and THEME.mats.CAGE and not p.deathmatch
          and K.rmodel.c_h >= K.rmodel.f_h + 128
        then
          B_pillar_cage(p,c, THEME.mats.CAGE, kx,ky, K.x1+1,K.y1+1)
        else
          B_pillar(p,c, c.theme, kx,ky, K.x1+1,K.y1+1)
        end
        blocked = true
      end

---###      sec.l_tex = l_tex
---###      sec.u_tex = u_tex

      gap_fill(p,c, K.x1, K.y1, K.x2, K.y2, sec)

      if not blocked and c.theme.scenery and not K.stair_dir and
         (dual_odds(c.theme.outdoor, 37, 22)
          or (c.scenic and rand_odds(51)))
      then
--!!!!!        p.blocks[K.x1+1][K.y1+1].has_scenery = true
        local th = add_thing(p, c, K.x1+1, K.y1+1, c.theme.scenery, true)
        if c.scenic then
          th.dx = rand_irange(-64,64)
          th.dy = rand_irange(-64,64)
        end
      end
    end


    if K.dm_health then
      add_dm_pickup(c, bx,by, K.dm_health)
    end
    
    if K.dm_ammo then
      add_dm_pickup(c, bx,by, K.dm_ammo)
    end
    
    if K.dm_item then
      add_dm_pickup(c, bx,by, K.dm_item)
    end
  end


  ---=== build_cell ===---

  assert(not c.mark)

  c.mark = allocate_mark(p)

  if not c.theme.outdoor and not c.is_exit and not c.hallway
     and rand_odds(70)
  then
    c.sky_light =
    {
      h  = 8 * rand_irange(2,4),
      pattern = random_sky_light(),
      is_sky = rand_odds(33),
      light_info = get_rand_light()
    }
    if not c.sky_light.is_sky and rand_odds(80) then
      c.sky_light.h = - c.sky_light.h
    end
  end

  for side = 1,9,2 do
    build_corner(side)
    build_border(side)
  end

  for side = 2,8,2 do
    build_link(side)
    build_border(side)
  end

if true then --!!!!! TESTING
local OV = {}
local T = get_rand_theme()
gap_fill(p,c, c.bx1, c.by1, c.bx2, c.by2, c.rmodel, OV)
if c == p.quests[1].first then
add_thing(p, c, c.bx1+3, c.by1+3, "player1", true, 0)
end

if c.x==1 and c.y==3 then

  fab = PREFABS["TECH_PICKUP_LARGE"]
  assert(fab)

  skin = { wall="STONE2", floor="CEIL5_2", ceil="CEIL3_5",
           light="LITE5", sky="F_SKY1",
           step="STEP1", carpet="FLOOR1_1",
           
         }
  parm = { floor = c.rmodel.f_h,
           ceil  = c.rmodel.c_h,
         }

  B_prefab(p,c, fab,skin,parm, c.theme, c.bx1+1, c.by1+1, c.rmodel.f_h, 8)

--[[
  fab = PREFABS["DOOR"]
  assert(fab)
  skin = { xx_wall="COMPBLUE", track="DOORTRAK", light="LITE3", 
           frame_floor="FLAT1", door="BIGDOOR4", step="STEP1",
          -- door_ceil="FLAT10",
         }
  parm = { floor = c.rmodel.f_h,
           ceil  = c.rmodel.c_h,
           door_top = c.rmodel.f_h+112,
           door_kind = 1, tag = 0
         }

  B_prefab(p,c, fab,skin,parm, c.theme, c.bx1+1, c.by1+1, c.rmodel.f_h, 8)
  B_prefab(p,c, fab,skin,parm, c.theme, c.bx1+5, c.by1+1, c.rmodel.f_h, 2)
  B_prefab(p,c, fab,skin,parm, c.theme, c.bx1+1, c.by1+6, c.rmodel.f_h, 4)
  B_prefab(p,c, fab,skin,parm, c.theme, c.bx1+5, c.by1+6, c.rmodel.f_h, 6)
--]]
end

return
end

  for kx = 1,KW do
    for ky = 1,KH do
      build_chunk(kx, ky)
    end
  end
end


local function build_depot(p, c)

  setup_rmodel(p, c)

  c.bx1 = BORDER_BLK + (c.x-1) * (BW+1) + 1
  c.by1 = BORDER_BLK + (c.y-1) * (BH+1) + 1

  c.bx2 = c.bx1 + BW - 1
  c.by2 = c.by1 + BW - 1

  local depot = c.quest.depot
  assert(depot)

  local places = depot.places
  assert(#places >= 2)
  assert(#places <= 4)

  local start = p.quests[1].first
--!!!!
--[[
  assert(start.player_pos)
  local player_B = p.blocks[start.player_pos.x][start.player_pos.y]
--]] local player_B = start.rmodel

  -- check for double pedestals (Plutonia)
  if player_B.fragments then
    player_B = player_B.fragments[1][1]
  end
  assert(player_B)
  assert(player_B.f_h)

  local sec = { f_h = player_B.f_h, c_h = player_B.f_h + 128,
                f_tex = c.rmodel.f_tex, c_tex = c.rmodel.c_tex,
                l_tex = c.theme.void,  u_tex = c.theme.void,
                light = 0
              }

  mon_sec = copy_block(sec)
  mon_sec[8] = { block_mon=true }

  door_sec = copy_block(sec)
  door_sec.c_h = door_sec.f_h
  door_sec.tag = depot.door_tag

  tele_sec = copy_block(sec)
  tele_sec.walk_kind = 126

  local m1,m2 = 1,4
  local t1,t2 = 6,BW

  -- mirror the room horizontally
  if c.x > start.x then
    m1,m2, t1,t2 = t1,t2, m1,m2
  end

  for y = 1,#places do
    c_fill(p, c, 1,y*2-1, BW,y*2, mon_sec, { mark=y })
    places[y].spots = rectangle_to_spots(c, c.bx1-1+m1, c.by1-1+y*2-1,
          c.bx1-1+m1+0, c.by1-1+y*2)

    for x = t1,t2 do
      local t = 1 + ((x + y) % #places)
      c_fill(p, c, x,y*2-1, x,y*2, tele_sec, { mark=x*10+y, walk_tag=places[t].tag})
    end
  end

  -- door separating monsters from teleporter lines
  c_fill(p, c, 5,1, 5,2*#places, door_sec)

  -- bottom corner block is same sector as player start,
  -- to allow sound to wake up these monsters.
  c_fill(p, c, m1,1, m1,1, copy_block(player_B), { same_sec=player_B })

  -- put a border around the room
  gap_fill(p, c, c.bx1-1, c.by1-1, c.bx2+1, c.by2+1, { solid=c.theme.wall })
end


function build_level(p)

  for zzz,cell in ipairs(p.all_cells) do
    setup_rmodel(p, cell)
  end

  make_chunks(p)
--show_chunks(p)

  con.ticker()

  setup_borders_and_corners(p)

  for zzz,cell in ipairs(p.all_cells) do
    build_cell(p, cell)
  end

  for zzz,cell in ipairs(p.all_depots) do
    build_depot(p, cell)
  end

  con.progress(25); if con.abort() then return end
 
  if not p.deathmatch then
    battle_through_level(p)
  end

  con.progress(40); if con.abort() then return end
end

