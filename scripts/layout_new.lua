----------------------------------------------------------------
--  Layouting Logic
----------------------------------------------------------------
--
--  Oblige Level Maker
--
--  Copyright (C) 2006-2010 Andrew Apted
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

require 'defs'
require 'util'


function Layout_prepare_rooms()
  for _,R in ipairs(LEVEL.all_rooms) do
    spacelib.clear()

    if R.shape == "rect" then
      local K1 = SECTIONS[R.kx1][R.ky1]
      local K2 = SECTIONS[R.kx2][R.ky2]

      spacelib.initial_rect(K1.x1, K1.y1, K2.x2, K2.y2)
    else
      for _,K in ipairs(R.sections) do
        spacelib.initial_rect(K.x1, K.y1, K.x2, K.y2)
      end
    end

    -- save the group of spaces
    R.spaces = SPACES
  end
end


function Layout_place_straddler(kind, K, N, dir)
  -- Straddlers are architecture which sits across two rooms.
  -- Currently there are only two kinds: DOORS and WINDOWS.
  -- 
  -- There are placed (i.e. allocated on a 2D map) before
  -- everything else.  The actual prefab and heights will be
  -- decided later in the normal layout code.

  R = K.room

    local deep1 = 64
    local deep2 = 64
    local long = 240

    local mx = int((K.x1 + K.x2) / 2)
    local my = int((K.y1 + K.y2) / 2)

    local x1,y1, x2,y2

    if geom.is_vert(dir) then
      x1 = mx - long/2
      x2 = mx + long/2

      if dir == 8 then
        y1 = K.y2 - deep1
        y2 = K.y2 + deep2
      else
        y1 = K.y1 - deep2
        y2 = K.y1 + deep1
      end
    else
      y1 = my - long/2
      y2 = my + long/2

      if dir == 6 then
        x1 = K.x2 - deep1
        x2 = K.x2 + deep2
      else
        x1 = K.x1 - deep2
        x2 = K.x1 + deep1
      end
    end


    local res_kind = sel(kind == "door", "walk", "air")
    local res_d = 220
    

    spacelib.make_current(K.room.spaces)

    spacelib.merge(spacelib.quad("solid", x1,y1, x2,y2))

    if dir == 2 then
      spacelib.merge(spacelib.quad(res_kind, x1,y2, x2,y2+res_d))
    elseif dir == 8 then
      spacelib.merge(spacelib.quad(res_kind, x1,y1-res_d, x2,y1))
    elseif dir == 6 then
      spacelib.merge(spacelib.quad(res_kind, x1-res_d,y1, x1,y2))
    elseif dir == 4 then
      spacelib.merge(spacelib.quad(res_kind, x2,y1, x2+res_d,y2))
    end


    spacelib.make_current(N.room.spaces)

-- [[
    spacelib.merge(spacelib.quad("solid", x1,y1, x2,y2))

    -- place walk areas (etc) in front of spaces

    if dir == 8 then
      spacelib.merge(spacelib.quad(res_kind, x1,y2, x2,y2+res_d))
    elseif dir == 2 then
      spacelib.merge(spacelib.quad(res_kind, x1,y1-res_d, x2,y1))
    elseif dir == 4 then
      spacelib.merge(spacelib.quad(res_kind, x1-res_d,y1, x1,y2))
    elseif dir == 6 then
      spacelib.merge(spacelib.quad(res_kind, x2,y1, x2+res_d,y2))
    end
--]]

stderrf(">>>>>>>>>>>> %s straddler %s --> %s\n", kind, K:tostr(), N:tostr())
stderrf("             (%d %d) --> (%d %d)\n", x1, y1, x2, y2)
end
  


function Layout_place_straddlers()
  -- do doors after windows, as doors may want to become really big
  -- and hence would need to know about the windows.

  for _,R in ipairs(LEVEL.all_rooms) do
    for _,W in ipairs(R.windows) do
      if not W.placed and W.K1.room == R then
        Layout_place_straddler("window", W.K1, W.K2, W.dir)
        W.placed = true
      end
    end
  end

  for _,R in ipairs(LEVEL.all_rooms) do
    for _,C in ipairs(R.conns) do
      if not C.placed and C.K1.room == R and C.kind == "normal" then
        Layout_place_straddler("door", C.K1, C.K2, C.dir)
        C.placed = true
      end
    end
  end
end


function Layout_the_room(R)


--  R.entry_conn

--  if R.purpose then add_purpose() end
--  if R:has_teleporter() then add_teleporter() end
--  if R.weapon  then add_weapon(R.weapon)  end


  local function section_for_space(S)
    for _,K in ipairs(R.sections) do
      if geom.inside_box(S.x1, S.y1, K.x1,K.y1, K.x2,K.y2) and
         geom.inside_box(S.x2, S.y2, K.x1,K.y1, K.x2,K.y2)
      then
        return K
      end
    end
  end

  local function same_room(K, side)
    local N = K:neighbor(side)
    if not N and R.outdoor then return true end ---- FIXME HACK CRAP for SKY BORDERS
    return N and N.room == K.room
  end

  local function touches_side(S, side, foobie)
    local K = section_for_space(S)
    if foobie or not same_room(K, side) then
        if side == 4 and S.x1 < K.x1+1 then return true end
        if side == 6 and S.x2 > K.x2-1 then return true end
        if side == 2 and S.y1 < K.y1+1 then return true end
        if side == 8 and S.y2 > K.y2-1 then return true end
    end
    return false
  end

  local function touches_corner(S, side)
    local R_dir = geom.RIGHT_45[side]
    local L_dir = geom. LEFT_45[side]

    if touches_side(S, R_dir) and touches_side(S, L_dir) then
      return 1
    end

    -- handle 270 degree corners (in shaped rooms)
    if not (touches_side(S, R_dir, true) and touches_side(S, L_dir, true)) then
      return nil
    end

    local K = section_for_space(S)
    if not K then return nil end

    local L = K:neighbor(L_dir)
    local R = K:neighbor(R_dir)

    if not (L and L.room == K.room) then return nil end
    if not (R and R.room == K.room) then return nil end

    local L2 = L:neighbor(R_dir)
    local R2 = R:neighbor(L_dir)

    assert(L2 == R2)

    if L2 and L2.room == K.room then return nil end

    return 2
  end


  local THICK = 80


  local function try_add_corner()
    for _,S in ipairs(R.spaces) do
      for side = 1,9,2 do if side ~= 5 then
        if S.free and touches_corner(S, side) then
          
          local x1, y1 = S.x1, S.y1
          local x2, y2 = S.x2, S.y2

          if x2 - x1 >= THICK then
            if side == 1 or side == 7 then
              x2 = x1 + THICK
            else
              x1 = x2 - THICK
            end
          end

          if y2 - y1 >= THICK then
            if side == 1 or side == 3 then
              y2 = y1 + THICK
            else
              y1 = y2 - THICK
            end
          end

          local SPACE =
          {
            wall = true,  corner = true,
            x1 = x1, y1 = y1,
            x2 = x2, y2 = y2,
          }

          Layout_merge_space(R, SPACE)

          -- the spaces have changed, hence must start from beginning
          return true

        end
      end end
    end
  end


  local function try_add_wall()
    for _,S in ipairs(R.spaces) do
      for side = 2,8,2 do
        if S.free and touches_side(S, side) then

          local x1, y1 = S.x1, S.y1
          local x2, y2 = S.x2, S.y2

          if side == 4 and x2 - x1 >= THICK then x2 = x1 + THICK end
          if side == 6 and x2 - x1 >= THICK then x1 = x2 - THICK end
          if side == 2 and y2 - y1 >= THICK then y2 = y1 + THICK end
          if side == 8 and y2 - y1 >= THICK then y1 = y2 - THICK end

          local SPACE =
          {
            wall = true,
            x1 = x1, y1 = y1,
            x2 = x2, y2 = y2,
          }

          Layout_merge_space(R, SPACE)

          -- the spaces have changed, hence must start from beginning
          return true

        end
      end
    end
  end


  local function add_corners()
    while try_add_corner() do end
  end

  local function add_walls()
    while try_add_wall() do end
  end


  local function build_space(S)
    local c_mat = sel(R.outdoor, "_SKY", "CEIL1_1")
    local f_mat = "FLAT14"
    local w_mat = "STARTAN3"
    local corn_mat = "CRACKLE2"
    local d_mat = "TEKGREN3"
    local win_mat = "COMPBLUE"

    if S.kind == "free"  then f_mat = "NUKAGE1" end
    if S.kind == "walk"  then f_mat = "LAVA1"   end
    if S.kind == "air"   then f_mat = "FLAT5_7" end

    if S.kind == "floor"  then f_mat = "FLAT18" end
    if S.kind == "liquid" then f_mat = "FWATER1" end
    if S.kind == "solid"  then f_mat = "FLAT10"  end

    local kind, w_face, p_face = Mat_normal(f_mat)
    p_face.mark  = Plan_alloc_mark()
    p_face.light = 0.75

    if S.kind == "walk" or S.kind == "air" then p_face.special = 1 end

    S.x1 = S.bx1 ; S.y1 = S.by1
    S.x2 = S.bx2 ; S.y2 = S.by2

    local z1 = rand.irange(0,12)

    Trans.quad(S.x1,S.y1, S.x2,S.y2, nil, z1, kind, w_face, p_face)

    -- handle straddlers, which exist in two rooms
    if S.straddle == "window" then
--    if not S.prepped then S.prepped = true; return; end
      if S.built then return; end
    end
    if S.straddle == "door" then
      if S.built then return; end
    end

    S.built = true

    if S.straddle == "door" then
--      assert(S.dir)
--      local skin = GAME.DOORS["silver"] or {}
--      Fabricate("DOOR", skin, Trans.box_transform(S.x1,S.y1, S.x2,S.y2, 0, S.dir))
    Trans.quad(S.x1,S.y1, S.x2,S.y2, 128, nil, Mat_normal(d_mat))
--  Trans.quad(S.x1,S.y1, S.x2,S.y2, nil, 16 , Mat_normal(d_mat))
    elseif S.straddle == "window" then
--    assert(S.dir)
--    Fabricate("WINDOW", {outer="STARG1", inner="STARG1"}, Trans.box_transform(S.x1,S.y1, S.x2,S.y2, 40, S.dir))
      Trans.quad(S.x1,S.y1, S.x2,S.y2, nil, 40, Mat_normal(win_mat))
      Trans.quad(S.x1,S.y1, S.x2,S.y2, 80, nil, Mat_normal(win_mat))
    elseif S.corner then
      Trans.quad(S.x1,S.y1, S.x2,S.y2, nil, nil, Mat_normal(corn_mat))
    elseif S.wall then
      Trans.quad(S.x1,S.y1, S.x2,S.y2, nil, nil, Mat_normal(w_mat))
    elseif R.outdoor then
      Trans.quad(S.x1,S.y1, S.x2,S.y2, 384, nil, Mat_sky())
    else
      Trans.quad(S.x1,S.y1, S.x2,S.y2, 256, nil, Mat_normal(c_mat))
    end
  end


  ---==| Layout_room |==---

gui.random()

  spacelib.make_current(R.spaces)

---!!!!  add_corners()

---!!!!  add_walls()

  for _,S in ipairs(SPACES) do
    build_space(S)
  end


  --!!! TEMP SHIT !!!--

  for kx = R.kx1,R.kx2 do for ky = R.ky1,R.ky2 do
    local K = SECTIONS[kx][ky]
    if K.room == R then
      Trans.entity("zombie", K.x2 - 96, K.y2 - 96, 0)
    end
  end end

  local kx = R.kx1
  local ky = R.ky1

  while SECTIONS[kx][ky].room ~= R do
    kx = kx + 1
  end

  local K = SECTIONS[kx][ky]

  local ex = (K.x1 + K.x2) / 2
  local ey = (K.y1 + K.y2) / 2
  local ent = "potion"

  if R.purpose == "START" then
    local skin = { top="O_BOLT", x_offset=36, y_offset=-8, peg=1 }
    Fabricate("PEDESTAL", skin, Trans.spot_transform(ex, ey, 0))

    ent = "player1"
  end

  if R.purpose == "EXIT" then
    ent = "evil_eye"
  end

  Trans.entity(ent, ex, ey, 0)

  if not R.outdoor then
    Trans.entity("light", ex, ey, 170, { light=150, _radius=600 })
  end
end


function Layout_rooms()
  for _,R in ipairs(LEVEL.all_rooms) do
    Layout_the_room(R)
  end
end


----------------------------------------------------------------


function Layout_edge_of_map()
  
  local function stretch_buildings()
    -- TODO: OPTIMISE
    for loop = 1,3 do
      for x = 1,SEED_W do for y = 1,SEED_H do
        local S = SEEDS[x][y]
        if (S.room and not S.room.outdoor) or (S.edge_of_map and S.building) then
          if (S.move_loop or 0) < loop then
            for side = 2,8,2 do
              if not S.edge_of_map or S.building_side == side then
                local N = S:neighbor(side)
                if N and N.edge_of_map and not N.building then
                  N.building = S.room or S.building
                  N.building_side = side
                  N.move_loop = loop
                end
              end
            end -- for side
          end
        end
      end end -- for x, y
    end -- for loop
  end

  local function determine_walk_heights()
    -- TODO: OPTIMISE
    for loop = 1,5 do
      for x = 1,SEED_W do for y = 1,SEED_H do
        local S = SEEDS[x][y]
        if S.edge_of_map and not S.building then
          for side = 2,8,2 do
            local N = S:neighbor(side)
            local other_h
            if N and N.edge_of_map and not N.building then
              other_h = N.walk_h
            elseif N and N.room and N.room.outdoor then
              other_h = N.room.floor_max_h
            end

            if other_h then
              S.walk_h = math.max(S.walk_h or 0, other_h)
            end
          end -- for side
        end
      end end -- for x, y
    end -- for loop
  end

  local function build_edge(S)
if not S.walk_h then S.walk_h = 16 end

    if S.building then
      local tex = S.building.cave_tex or S.building.facade or S.building.main_tex
      assert(tex)

      local kind, w_face, p_face = Mat_normal(tex)

      Trans.quad(S.x1,S.y1, S.x2,S.y2, nil,nil, { k=kind }, w_face, p_face)
      return
    end

    S.fence_h = SKY_H - 128  -- fallback value

    if S.walk_h then
      S.fence_h = math.min(S.walk_h + 64, SKY_H - 64)
    end

    local x1 = S.x1
    local y1 = S.y1
    local x2 = S.x2
    local y2 = S.y2

    local function side_quad(side,len, z1,z2, props, w_face, p_face)
      local ax1, ay1 = x1, y1
      local ax2, ay2 = x2, y2

      if side == 2 then ay2 = ay1 + len end
      if side == 8 then ay1 = ay2 - len end
      if side == 4 then ax2 = ax1 + len end
      if side == 6 then ax1 = ax2 - len end

      Trans.quad(ax1,ay1, ax2,ay2, z1,z2, props, w_face, p_face)
    end

    local function sky_side(side, fh, ch, props, w_face, p_face)
      if GAME.format == "doom" then
        -- use delta_z to make the sky go down to the floor
        -- (as per MAP01 of DOOM II)
        local p_face2 = table.copy(p_face)
        p_face2.delta_z = fh - (ch-4);

        side_quad(side, 16, ch-4,nil, props, w_face, p_face2)
      else
        -- solid sky wall for Quake engines
        side_quad(side, 16, nil,nil, props, w_face, p_face)
      end
    end

    local kind, w_face, p_face = Mat_normal(LEVEL.outer_fence_tex)
    Trans.quad(x1,y1, x2,y2, nil,S.fence_h, { k=kind }, w_face, p_face)

    kind, w_face, p_face = Mat_sky()
    Trans.quad(x1,y1, x2,y2, SKY_H,nil, { k=kind }, w_face, p_face)

    for side = 2,8,2 do
      local N = S:neighbor(side)
      if not N or N.free then
        sky_side(side, S.fence_h, SKY_H, { k=kind }, w_face, p_face)
      end

      if N and ((N.room and not N.room.outdoor) or
                (N.edge_of_map and N.building))
      then
--!!!!        Build_shadow(S, side, 64)
      end
    end
  end

  ---| Layout_edge_of_map |---
  
  gui.debugf("Layout_edge_of_map\n")

  stretch_buildings()

  determine_walk_heights()

  for x = 1,SEED_W do for y = 1,SEED_H do
    local S = SEEDS[x][y]
    if S.edge_of_map then
      build_edge(S)
    end
  end end -- for x, y
end

