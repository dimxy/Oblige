----------------------------------------------------------------
-- GAME DEF : Half-Life
----------------------------------------------------------------
--
--  Oblige Level Maker
--
--  Copyright (C) 2010 Andrew Apted
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

HALFLIFE = { }

HALFLIFE.ENTITIES =
{
  -- players
  player1 = { id="info_player_start", kind="other", r=16,h=56 },

--??  player2 = { id="info_player_coop",  kind="other", r=16,h=56 },
--??  player3 = { id="info_player_coop",  kind="other", r=16,h=56 },
--??  player4 = { id="info_player_coop",  kind="other", r=16,h=56 },

  dm_player = { id="info_player_deathmatch", kind="other", r=16,h=56 },

  -- enemies
  grunt    = { id="monster_alien_grunt", kind="monster", r=32, h=80, },
  slave    = { id="monster_alien_slave", kind="monster", r=32, h=80, },
  barney   = { id="monster_barney",      kind="monster", r=32, h=80, },
  garg     = { id="monster_gargantua",   kind="monster", r=32, h=80, },

  baby     = { id="monster_babycrab",    kind="monster", r=32, h=80, },
  crab     = { id="monster_headcrab",    kind="monster", r=32, h=80, },
  chicken  = { id="monster_bullchicken", kind="monster", r=32, h=80, },
  roach    = { id="monster_cockroach",   kind="monster", r=32, h=80, },
  hound    = { id="monster_houndeye",    kind="monster", r=32, h=80, },

  saur     = { id="monster_ichthyosaur", kind="monster", r=32, h=80, },
  snark    = { id="monster_snark",       kind="monster", r=32, h=80, },
  zombie   = { id="monster_zombie",      kind="monster", r=32, h=80, },

  -- bosses


  -- pickups

  crowbar  = { id="weapon_crowbar",    kind="pickup", r=30, h=30, pass=true },
  shotty   = { id="weapon_shotgun",    kind="pickup", r=30, h=30, pass=true },
  nine_AR  = { id="weapon_9mmAR",      kind="pickup", r=30, h=30, pass=true },
  handgun  = { id="weapon_9mmhandgun", kind="pickup", r=30, h=30, pass=true },

  snark    = { id="weapon_snark",    kind="pickup", r=30, h=30, pass=true },
  rpg      = { id="weapon_rpg",      kind="pickup", r=30, h=30, pass=true },
  w357     = { id="weapon_357",      kind="pickup", r=30, h=30, pass=true },
  gauss    = { id="weapon_gauss",    kind="pickup", r=30, h=30, pass=true },

  buckshot  = { id="ammo_buckshot", kind="pickup", r=30, h=30, pass=true },
  clip      = { id="ammo_9mmAR",    kind="pickup", r=30, h=30, pass=true },

  health    = { id="item_healthkit", kind="pickup", r=30, h=30, pass=true },


  -- scenery


  -- special

}


HALFLIFE.PARAMETERS =
{
  sub_format = "halflife",

  -- TODO

  -- Quake engine needs all coords to lie between -4000 and +4000.
  seed_limit = 42,

  use_spawnflags = true,
  entity_delta_z = 24,

  max_name_length = 20,

  skip_monsters = { 10,30 },

  time_factor   = 1.0,
  damage_factor = 1.0,
  ammo_factor   = 0.8,
  health_factor = 0.7,
}


----------------------------------------------------------------

HALFLIFE.MATERIALS =
{
  -- special materials --
  _ERROR = { t="generic027" },
  _SKY   = { t="sky" },

  FLOOR  = { t="crete3_flr04" },
  WALL   = { t="fifties_wall14t" },

}


----------------------------------------------------------------


HALFLIFE.EXITS =
{
  exit_pad =
  {
    h=128,
    switch_w="SW1SKULL",
    exit_w="EXITSIGN", exit_h=16,
    exitside="COMPSPAN",
  },
}


HALFLIFE.STEPS =
{
  step1 = { step_w="MET5_1",   side_w="METAL2_2",  top_f="METAL2_2" },
  step2 = { step_w="CITY3_2",  side_w="CITY3_4",   top_f="CITY3_4" },
}


HALFLIFE.PICTURES =
{
  carve =
  {
    count=1,
    pic_w="O_CARVE", width=64, height=64, raise=64,
    x_offset=0, y_offset=0,
    side_t="METAL", floor="CEIL5_2", depth=8, 
    light=0.7,
  },
}


-- HALFLIFE.KEY_DOORS =
-- {
--   k_silver = { door_kind="door_silver", door_side=14 },
--   k_gold   = { door_kind="door_gold",   door_side=14 },
-- }


HALFLIFE.SUB_THEME_DEFAULTS =
{
  teleporter_mat = "TELE_TOP",
  tele_dest_mat = "COP3_4",
  pedestal_mat = "LIGHT1_1",
  periph_pillar_mat = "METAL2_6",
  track_mat = "MET5_1",
}


HALFLIFE.SUB_THEMES =
{
  halflife_lab1 =
  {
    prob=50,

    building_walls =
    {
      WALL=50,
    },

    building_floors =
    {
      FLOOR=50,
    },

    building_ceilings =
    {
      FLOOR=50,
    },

    courtyard_floors =
    {
      FLOOR=50,
    },

    logos = { carve=50 },

    steps = { step1=50, step2=50 },

    exits = { exit_pad=50 },

    scenery =
    {
      -- FIXME
    },
  }, -- LAB1
}


----------------------------------------------------------------

HALFLIFE.MONSTERS =
{
  crab =
  {
    prob=20,
    health=25, damage=5, attack="melee",
  },

  grunt =
  {
    prob=80,
    health=30, damage=14, attack="hitscan",
  },

  barney =
  {
    prob=40,
    health=80, damage=18, attack="missile",
  },

  garg =
  {
    prob=3,
    health=80, damage=10, attack="melee",
    density=0.3,
  },

  chicken =
  {
    prob=60,
    health=75, damage=9,  attack="melee",
  },

  hound =
  {
    prob=30,
    health=250, damage=30, attack="missile",
  },

  roach =
  {
    prob=40,
    health=200, damage=15, attack="missile",
  },

  snark =
  {
    prob=10,
    health=300, damage=20, attack="melee",
  },

  saur =
  {
    prob=3,
    health=300, damage=20, attack="melee",
  },

  zombie =
  {
    prob=60,
    health=80, damage=18, attack="missile",
  },
}


HALFLIFE.WEAPONS =
{
  crowbar =
  {
    rate=2.0, damage=20, attack="melee",
  },

  shotty =
  {
    pref=50, add_prob=40, start_prob=50,
    rate=1.4, damage=45, attack="hitscan", splash={0,3},
    ammo="shell", per=2,
    give={ {ammo="shell",count=5} },
  },

  w357 =
  {
    pref=50, add_prob=40, start_prob=50,
    rate=1.4, damage=45, attack="hitscan", splash={0,3},
    ammo="shell", per=2,
    give={ {ammo="shell",count=5} },
  },

  rpg =
  {
    pref=50, add_prob=40, start_prob=50,
    rate=1.4, damage=45, attack="hitscan", splash={0,3},
    ammo="shell", per=2,
    give={ {ammo="shell",count=5} },
  },

}


HALFLIFE.PICKUPS =
{
  -- HEALTH --

  health =
  {
    prob=50,
    give={ {health=25} },
  },


  -- ARMOR --


  -- AMMO --

  buckshot =
  {
    prob=10,
    give={ {ammo="shell",count=20} },
  },

}


HALFLIFE.PLAYER_MODEL =
{
  gordon =
  {
    stats   = { health=0, shell=0 },
    weapons = { crowbar=1 },
  }
}


------------------------------------------------------------

HALFLIFE.EPISODES =
{
  episode1 =
  {
    theme = "TECH",
    sky_light = 0.75,
  },

  episode2 =
  {
    theme = "TECH",
    sky_light = 0.75,
  },

  episode3 =
  {
    theme = "TECH",
    sky_light = 0.75,
  },

  episode4 =
  {
    theme = "TECH",
    sky_light = 0.75,
  },
}


----------------------------------------------------------------

function HALFLIFE.setup()
  -- do stuff here
end


function HALFLIFE.get_levels()
  local EP_NUM  = sel(OB_CONFIG.length == "full", 4, 1)
  local MAP_NUM = sel(OB_CONFIG.length == "single", 1, 7)

  if OB_CONFIG.length == "few" then MAP_NUM = 3 end

  for episode = 1,EP_NUM do
    local ep_info = HALFLIFE.EPISODES["episode" .. episode]
    assert(ep_info)

    for map = 1,MAP_NUM do

      local LEV =
      {
        name = string.format("e%dm%d", episode, map),

        episode  = episode,
        map      = map,
        ep_along = map / MAP_NUM,

        next_map = string.format("e%dm%d", episode, map+1)
      }

      table.insert(GAME.all_levels, LEV)
    end -- for map

  end -- for episode
end


function HALFLIFE.begin_level()
  -- set the description here
  if not LEVEL.description and LEVEL.name_theme then
    LEVEL.description = Naming_grab_one(LEVEL.name_theme)
  end
end


----------------------------------------------------------------

OB_GAMES["halflife"] =
{
  label = "Half-Life",

  format = "quake",

  tables =
  {
    HALFLIFE
  },

  hooks =
  {
    setup        = HALFLIFE.setup,
    get_levels   = HALFLIFE.get_levels,
    begin_level  = HALFLIFE.begin_level,
  },
}


OB_THEMES["halflife_lab"] =
{
  label = "Lab",
  for_games = { halflife=1 },

  name_theme = "TECH",
  mixed_prob = 50,
}

