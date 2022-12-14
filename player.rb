#Gravity Runner game by Freya-The-Goddess
#Custom code project for Intro To Programming (COS10009) in 2020
#Code refactored and modified in 2022

#import external libraries
require 'rubygems'
require 'gosu'

#import other files
require_relative 'params'
require_relative 'entity'

#Player class (inherits LiveEntity)
class Player < LiveEntity
    #public attributes
    attr_accessor :x_coord, :y_coord, :height, :width, :dead, :standing

    def initialize
        footsteps_channel = self.class.footsteps_sound.play(1, 1, true) #start footsteps looping sound effect channel
        footsteps_channel.pause
        super(PLAYER_X_COORD, FLOOR_Y-PLAYER_SIZE/2, 0, PLAYER_SIZE, PLAYER_WIDTH, footsteps_channel)
    end

    #reset player to starting values
    def reset
        @y_coord = FLOOR_Y-PLAYER_SIZE/2
        @y_vel, @angle, @frame = 0, 0, 0
        @standing, @flipping, @dead = true, false, false
    end

    #player jump input
    def jump(ticks, gravity)
        @y_vel = JUMP_CONSTANT * gravity #multiply by 1 or -1 depending on if player is jumping off floor or ceiling
        return ticks + BUTTON_PRESS_TICKS #jump button ticks
    end

    #update player each frame
    def update(gravity, ticks, holes, sound_on)
        do_gravity(gravity) #update player's vertical velocity and position
        @standing = on_floor?(gravity, holes)
        @flipping = false if @standing
        do_rotate(gravity) #calculate player's rotation while in midair
        do_running(ticks) #update player's current running animation frame

        #player dies if outside ship (fell through hole)
        @dead = true if @y_coord-(PLAYER_SIZE/2) < CEILING_Y - DEATH_DISTANCE
        @dead = true if @y_coord+(PLAYER_SIZE/2) > FLOOR_Y + DEATH_DISTANCE

        #play footsteps sound effect while standing, else pause sound
        @standing && sound_on ? play_footsteps_sound : pause_footsteps_sound
    end

    #draw player by calling super function
    def draw(z_layer, gravity)
        super(z_layer, gravity)
    end

    #play footsteps looping sound effect
    def play_footsteps_sound
        if !@footsteps_channel.playing?
            @footsteps_channel.resume
        end
    end

    #pause footsteps sound effect
    def pause_footsteps_sound
        if @footsteps_channel.playing?
            @footsteps_channel.pause
        end
    end

    #class instance variables
    @tiles = Gosu::Image.load_tiles(PLAYER_TILES_PATH, PLAYER_SIZE, PLAYER_SIZE) #player sprites array
    @footsteps_sound = Gosu::Sample.new(PLAYER_FOOTSTEP_SOUND_PATH) #footsteps looping sound effect
end