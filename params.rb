#Gravity Runner game by Freya-The-Goddess
#Custom code project for Intro To Programming (COS10009) in 2020
#Code refactored and modified in 2022

#import external libraries
require 'rubygems'
require 'gosu'

#Gosu z layer order module
module ZOrder
    BACKGROUND, SHIP, ENTITIES, PLAYER, BUTTONS, OVERLAY, UI = *0..6
end

#Gravity parameters
GRAVITY_CONSTANT            = 0.65                              #acceleration due to gravity (pixels/tick²)
module Gravity                                                  #gravity direction module
    UP = -1                                                     #up is negative Y
    DOWN = 1                                                    #down is positive Y
end

#Gosu color parameters
BACKGROUND_COLOR            = Gosu::Color.argb(0xFF_00000A)     #Space (dark blue)
SCORE_TEXT_COLOR            = Gosu::Color.argb(0xFF_FFFFFF)     #White Text
NEW_HIGHSCORE_TEXT_COLOR    = Gosu::Color.argb(0xFF_FF6666)     #Light Red Text
BLEND                       = Gosu::Color.argb(0xFF_FFFFFF)     #Gosu blend mode

#Game media file paths
FONT_PATH                   = "./media/courier-new-bold.ttf"    #courier new bold font path
HIGHSCORE_PATH              = "media/highscore.txt"             #highscore text file path
USER_PREFS_PATH             = "media/user-prefs.txt"            #user preferences file path
PLAYER_TILES_PATH           = "media/player.png"                #player sprites file path
ENEMY_TILES_PATH            = "media/robot.png"                 #enemy sprites file path
CRATE_TILES_PATH            = "media/crates.png"                #crate obstacle sprites file path
BARREL_TILES_PATH           = "media/barrels.png"                #crate obstacle sprites file path
HOLE_TILES_PATH             = "media/hole.png"                  #hole sprite file path
SHIP_IMAGE_PATH             = "media/ship.png"                  #ship image file path
SPACE_IMAGE_PATH            = "media/space.png"                 #space image file path
BUTTON_TILES_PATH           = "media/buttons.png"               #button tiles file path
OVERLAY_TILES_PATH          = "media/overlay.png"               #overlay tiles file path
JUMP_SOUND_PATH             = "media/jump.mp3"                  #jump sound effect file path
GRAVITY_SOUND_PATH          = "media/flip-gravity.mp3"          #gravity flip sound effect file path
GAME_OVER_SOUND_PATH        = "media/game-over.mp3"             #game over sound effect file path
PLAYER_FOOTSTEP_SOUND_PATH  = "media/player-footsteps.mp3"      #player footsteps looping sound effect file path
ENEMY_FOOTSTEP_SOUND_PATH   = "media/enemy-footsteps.mp3"       #enemy footsteps looping sound effect file path
OBSTACLE_IMPACT_SOUND_PATH  = "media/obstacle-impact.mp3"       #obstacle impact sound effect file path

#Frame rate parameters
FRAME_RATE                  = 60                                #frames per second
UPDATE_INTERVAL             = 1.0 / FRAME_RATE * 1000           #ms interval between frames

#Screen size parameters
SCREEN_WIDTH                = 800                               #game window width (pixels)
SCREEN_HEIGHT               = 450                               #game window height (pixels)

#Speed parameters
BACKGROUND_SPEED            = 1.0                               #background stars scrolling speed (pixels/tick)

#Difficulty parameters
DIFFICULTY_START            = 1.0                               #initial difficulty value
DIFFICULTY_INCREASE         = 0.0001                            #difficulty increase per tick
SCORE_SCALER                = 0.005                             #multiplied by ship speed to increase score per tick

#Button parameters
BUTTON_PRESS_TICKS          = 20                                #time (ticks) after pressed that button stays pressed down
BUTTON_SIZE                 = 150                               #button tile size (pixels)

#Button coordinate parameters [ x_min,              x_max,              y_min,              y_max         ]
JUMP_BUTTON_COORDS          = [ 0,                  150,                SCREEN_HEIGHT-120,  SCREEN_HEIGHT ]
GRAVITY_BUTTON_COORDS       = [ SCREEN_WIDTH-150,   SCREEN_WIDTH,       SCREEN_HEIGHT-120,  SCREEN_HEIGHT ]
PAUSE_BUTTON_COORDS         = [ SCREEN_WIDTH/2-50,  SCREEN_WIDTH/2+50,  SCREEN_HEIGHT-80,   SCREEN_HEIGHT ]
SOUND_BUTTON_COORDS         = [ 0,                  90,                 50,                 120           ]
MUSIC_BUTTON_COORDS         = [ SCREEN_WIDTH-80,    SCREEN_WIDTH,       50,                 120           ]

#Ship parameters
FLOOR_Y                     = 300                               #y coord of floor (pixels)
CEILING_Y                   = 50                                #y coord of ceiling (pixels)
FLOOR_THICKNESS             = 15                                #floor thickness (pixels)
DEATH_DISTANCE              = 80                                #distance (pixels) below floor that player dies
SHIP_SECTION_WIDTH          = 200                               #ship section width (pixels)
SHIP_SECTION_HEIGHT         = 280                               #ship section height (pixels)
SHIP_START_SPEED            = 2.8                               #initial speed of ship (pixels/tick)
SHIP_ACCELERATION           = 0.0001                            #ship speed acceleration (pixels/tick²)
SHIP_NORMAL_TILES           = 8                                 #amount of normal ship tiles in ship.png
SHIP_SPECIAL_TILES          = 12                                #amount of special ship tiles in ship.png

#Player parameters
PLAYER_SIZE                 = 50                                #player height (pixels)
PLAYER_WIDTH                = 18                                #player width (pixels)
PLAYER_X_COORD              = 120                               #player x coord
JUMP_CONSTANT               = -11.0                             #initial velocity of jump (pixels/tick)
TICKS_PER_RUN_FRAME         = 6                                 #ticks per running animation frame

#Enemy parameters
ENEMY_SIZE                  = 50                                #enemy height (pixels)
ENEMY_WIDTH                 = 18                                #enemy width (pixels)
ENEMY_SPAWN_BASE            = 600                               #enemy base spawn tick mean (decreases ovet time)
ENEMY_SPAWN_SD              = 50                                #enemy spawn tick standard deviation from mean
ENEMY_SPAWN_MULT            = 0.8                               #enemy spawn rate multiplier (changes rate of mean decreasing)
FIRST_ENEMY                 = 600                               #first enemy spawn ticks

#Obstacle parameters
OBSTACLE_WIDTH              = 25                                #obstacle (crate and barrel) width (pixels)
OBSTACLE_CRATE_HEIGHT       = 25                                #crate obstacle height (pixels)
OBSTACLE_BARREL_HEIGHT      = 30                                #barrel obstacle height (pixels)
OBSTACLE_CRATE_VARIATIONS   = 10                                #crate obctacle types (int)
OBSTACLE_BARREL_VARIATIONS  = 8                                 #barrel obstacle types (int)
OBSTACLE_SPAWN_BASE         = 300                               #obstacle base spawn tick mean
OBSTACLE_SPAWN_SD           = 30                                #obstacle spawn tick standard deviation from mean
OBSTACLE_SPAWN_MULT         = 0.9                               #obstacle spawn rate multiplier
FIRST_OBSTACLE              = 20                                #first obstacle spawn ticks
FIRST_OBSTACLE_TYPE         = 1                                 #first obstacle type (int)

#Hole parameters
HOLE_HEIGHT                 = 20                                #hole height (pixels)
HOLE_BASE_WIDTH             = 50                                #hole base width (pixels)
HOLE_SIDES_WIDTH            = 20                                #hole sides width (pixels)
HOLE_SIZE_MEAN              = 3                                 #hole size multiplier mean
HOLE_SIZE_SD                = 0.75                              #hole size multiplier standard deviation 
HOLE_SIZE_MAX               = 5                                 #hole size multiplier maximum (int)
HOLE_SPAWN_BASE             = 600                               #hole base spawn tick mean
HOLE_SPAWN_SD               = 100                               #hole spawn tick standard deviation from mean
HOLE_SPAWN_MULT             = 0.2                               #hole spawn rate multiplier
FIRST_HOLE                  = 200                               #first hole spawn ticks
FIRST_HOLE_SIZE             = 3                                 #first hole size multiplier (int)
FIRST_HOLE_DIRECTION        = :floor                            #first hole direction (:floor or :ceiling)

#ASCII art version of gravity runner logo
ASCII_LOGO = "    ______                     _  __        \n   / ____/_____ ____ _ _   __ (_)/ /_ __  __\n  / / __ / ___// __ `/| | / // // __// / / /\n / /_/ // /   / /_/ / | |/ // // /_ / /_/ / \n \\____//_/    \\__,_/  |___//_/ \\__/ \\__, /  \n     ____                          /____/   \n    / __ \\ __  __ ____   ____   ___   _____ \n   / /_/ // / / // __ \\ / __ \\ / _ \\ / ___/ \n  / _  _// /_/ // / / // / / //  __// /     \n /_/ |_| \\__,_//_/ /_//_/ /_/ \\___//_/      \n\n      created by Freya-The-Goddess\n"