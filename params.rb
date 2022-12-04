#Gravity Runner game by Freya-The-Goddess
#Custom code project for Intro To Programming (COS10009)

#import external libraries
require 'rubygems'
require 'gosu'

#Gravity parameters
GRAVITY_CONSTANT    = 0.65      #acceleration due to gravity (pixels/tick²)
module Gravity #gravity direction module
    UP = -1
    DOWN = 1
end

#Gosu z layer order module
module ZOrder
    BACKGROUND, SHIP, ENTITIES, PLAYER, BUTTONS, OVERLAY, UI = *0..6
end

#Gosu color parameters
BACKGROUND_COLOR    = Gosu::Color.argb(0xFF_00000A)     #Space (dark blue)
SCORE_TEXT_COLOR    = Gosu::Color.argb(0xFF_FFFFFF)     #White Text
NEW_HIGHSCORE_COLOR = Gosu::Color.argb(0xFF_FF6666)     #Light Red Text
BLEND               = Gosu::Color.argb(0xFF_FFFFFF)     #Gosu blend mode

#Game file paths
FONT_PATH           = "./media/courier-new-bold.ttf"    #courier new bold font path
HIGHSCORE_PATH      = "media/highscore.txt"             #highscore text file path
PLAYER_TILES_PATH   = "media/player.png"                #player sprites file path
ENEMY_TILES_PATH    = "media/robot.png"                 #enemy sprites file path
OBSTACLE_TILES_PATH = "media/crates.png"                #obstacle sprites file path
HOLE_TILES_PATH     = "media/hole.png"                  #hole sprite file path
SHIP_IMAGE_PATH     = "media/ship.png"                  #ship image file path
SPACE_IMAGE_PATH    = "media/space.png"                 #space image file path
BUTTON_TILES_PATH   = "media/buttons.png"               #button tiles file path
OVERLAY_TILES_PATH  = "media/overlay.png"               #overlay tiles file path

#Screen size constants
SCREEN_WIDTH        = 800                               #game window width (pixels)
SCREEN_HEIGHT       = 450                               #game window height (pixels)

#Ship parameters
FLOOR_Y             = 300                               #y coord of floor (pixels)
CEILING_Y           = 50                                #y coord of ceiling (pixels)
FLOOR_THICKNESS     = 15                                #floor thickness (pixels)

#Difficulty parameters
DIFFICULTY_START    = 1.0                               #initial difficulty value
DIFFICULTY_INCREASE = 0.0001                            #difficulty increase per tick
SCORE_SCALER        = 0.005                             #multiplied by ship speed to increase score per tick

#Speed parameters
BACKGROUND_SPEED    = 1.0                               #background stars scrolling speed (pixels/tick)
SHIP_START_SPEED    = 2.8                               #initial speed of ship (pixels/tick)
SHIP_ACCELERATION   = 0.00005                           #ship speed acceleration (pixels/tick²)

#Button parameters
BUTTON_PRESS_TICKS  = 20                                #time (ticks) after pressed that button stays pressed down

#Player parameters
PLAYER_SIZE         = 50                                #player height (pixels)
PLAYER_WIDTH        = 18                                #player width (pixels)
JUMP_CONSTANT       = -11.0                             #initial velocity of jump (pixels/tick)
TICKS_PER_RUN_FRAME = 5                                 #ticks per running animation frame

#Entity size parameters
ENEMY_SIZE          = 50                                #enemy height (pixels)
ENEMY_WIDTH         = 18                                #enemy width (pixels)
OBSTACLE_SIZE       = 25                                #obstacle width and height (pixels)
HOLE_HEIGHT         = 20                                #hole height (pixels)
HOLE_WIDTH          = 170                               #hole width (pixels)
HOLE_COLLIDE_WIDTH  = HOLE_WIDTH - 20                   #hole collision box width (pixels)
BUTTON_SIZE         = 150                               #button size

#Spawn tick min and max values
ENEMY_SPAWN_MIN     = 100
ENEMY_SPAWN_MAX     = 800
OBSTACLE_SPAWN_MIN  = 200
OBSTACLE_SPAWN_MAX  = 1000
HOLE_SPAWN_MIN      = 300
HOLE_SPAWN_MAX      = 1000