----------------------------------------------------------------
--  Oblige
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

require 'defs'
require 'util'
require 'a_star'

require 'prefab'
require 'theme'

require 'planner'
require 'plan_dm'

require 'monster'
require 'builder'
require 'writer'


function get_level_names(settings)

  local LEVELS = {}

  if (settings.game == "doom1") or (settings.game == "heretic") then

    local epi_num = 1
    local lev_num = sel(settings.length == "single", 1, 9)

    if settings.length == "full" then
      epi_num = sel(settings.game == "doom1", 4, 3)
    end

    for e = 1,epi_num do
      for m = 1,lev_num do
        table.insert(LEVELS, string.format("E%dM%d", e, m))
      end
    end

  elseif (settings.game == "wolf3d") then

    local epi_num = sel(settings.length == "full",   6, 1)
    local lev_num = sel(settings.length == "single", 1, 10)

    for e = 1,epi_num do
      for m = 1,lev_num do
        table.insert(LEVELS, string.format("E%dL%d", e, m))
      end
    end

  elseif (settings.game == "spear") then

    -- Spear of Destiny only has a single episode
    local epi_num = 1
    local lev_num = sel(settings.length == "single", 1, 21)

    for e = 1,epi_num do
      for m = 1,lev_num do
        table.insert(LEVELS, string.format("L%d", e, m))
      end
    end

  else  -- doom2 / freedoom / hexen

    local TS = { single=1, episode=10, full=32 }
    local total = TS[settings.length]
    assert(total)

    for i = 1,total do
      table.insert(LEVELS, string.format("MAP%02d", i))
    end
  end

  return LEVELS
end


function create_theme()

  local factory = GAME_FACTORIES[settings.game]

  if not factory then
    error("UNKNOWN GAME '" .. settings.game .. "'")
  end

  GAME = factory()

  name_up_theme()

  expand_prefabs(PREFABS)

  compute_pow_factors()
end


function build_cool_shit()
 
  assert(settings)

  -- the missing console functions
  con.printf = function (fmt, ...)
    if fmt then con.raw_log_print(string.format(fmt, ...)) end
  end

  con.debugf = function (fmt, ...)
    if fmt then con.raw_debug_print(string.format(fmt, ...)) end
  end

  con.printf("\n\n~~~~~~~ Making Levels ~~~~~~~\n\n")

  con.printf("SEED = %d\n\n", settings.seed)
  con.printf("Settings =\n%s\n", table_to_str(settings))

  create_theme()

  local aborted = false
  local LEVELS = get_level_names(settings)

  for idx,lev in ipairs(LEVELS) do

    con.at_level(lev, idx, #LEVELS)

    con.printf("\n=====| %s |=====\n\n", lev)

    con.rand_seed(settings.seed * 100 + idx)
 
    if settings.mode == "dm" then
      plan_dm_arena()
    elseif settings.mode == "coop" then
      plan_sp_level(true)
    else
      plan_sp_level(false)
    end

PLAN.lev_name = lev

    if con.abort() then aborted = true; break; end

    show_quests()
    con.printf("\n")

    if settings.mode == "dm" then
      show_dm_links()
    else
      show_path()
    end
    con.printf("\n")

    build_level()

    if con.abort() then aborted = true; break; end

    if settings.game == "wolf3d" or settings.game == "spear" then
      write_wolf_level(PLAN)
    else
      write_level(PLAN, lev)
    end

    if con.abort() then aborted = true; break; end

    make_mini_map(PLAN)
  end

  if aborted then
    con.printf("\n~~~~~~~ Build Aborted! ~~~~~~~\n\n")
    return "abort"
  end

  con.printf("\n~~~~~~ Finished Making Levels ~~~~~~\n\n")

  return "ok"
end

