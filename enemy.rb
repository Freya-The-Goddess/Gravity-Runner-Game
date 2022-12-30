#Gravity Runner game by Freya-The-Goddess
#Custom code project for Intro To Programming (COS10009) in 2020
#Code refactored and modified in 2022

#import external libraries
require 'rubygems'
require 'gosu'

#import other files
require_relative 'params'
require_relative 'entity'
require_relative 'randnormdist'

#Enemy class (inherits LiveEntity)
class Enemy < LiveEntity
    #public attributes
    attr_accessor :x_coord, :y_coord, :height, :width

    def initialize(x_coord, y_coord, x_vel, tile_size, width, gravity)
        @gravity = gravity
        footsteps_channel = self.class.footsteps_sound.play_pan(calc_audio_pan(x_coord), calc_audio_volume(x_coord), 1, true) #start footsteps looping sound effect channel
        footsteps_channel.pause
        super(x_coord, y_coord, x_vel, tile_size, width, footsteps_channel)
    end
    
    #update enemy each frame
    def update(ticks, holes, ship_speed, sound_on)
        do_horizontal(ship_speed) #update enemy's horizontal position
        do_gravity(@gravity) #update enemy's vertical velocity and position
        @standing = on_floor?(@gravity, holes)
        @flipping = false if @standing
        do_rotate(@gravity) #calculate enemy's rotation while in midair
        do_running(ticks) if @x_vel != 0 #update enemy's current running animation frame

        #play footsteps sound effect while standing, else pause sound
        @standing && sound_on ? play_footsteps_sound : pause_footsteps_sound
        @footsteps_channel.pan = calc_audio_pan(@x_coord)
        @footsteps_channel.volume = calc_audio_volume(@x_coord)
    end

    #draw enemy by calling super function
    def draw(z_layer)
        super(z_layer, @gravity)
    end

    #class instance variables
    @tiles = Gosu::Image.load_tiles(ENEMY_TILES_PATH, ENEMY_SIZE, ENEMY_SIZE) #enemy sprites array
    @footsteps_sound = Gosu::Sample.new(ENEMY_FOOTSTEP_SOUND_PATH) #footsteps looping sound effect
    @rng = RandNormDist.new(ENEMY_SPAWN_BASE, ENEMY_SPAWN_SD) #spawn ticks randomizer

    #singleton object
    class << self
        #class instance variable accessors
        attr_accessor :next_spawn
        private attr_accessor :rng

        #create new enemy with randomized traits
        def summon(difficulty)
            speed = rand(0.5..1.2) + difficulty/10
            gravity = [Gravity::UP, Gravity::DOWN][rand(0..1)]
            y_coord = gravity == Gravity::UP ? CEILING_Y+ENEMY_SIZE/2 : FLOOR_Y-ENEMY_SIZE/2
            return Enemy.new(SCREEN_WIDTH+ENEMY_SIZE, y_coord, speed, ENEMY_SIZE, ENEMY_WIDTH, gravity)
        end

        #calculate ticks for next spawn event based on normal distribution
        def calc_next_spawn(ticks, difficulty)
            rng.mean = ENEMY_SPAWN_BASE / ((difficulty - 1) * ENEMY_SPAWN_MULT + 1) #update mean of normal distribution
            @next_spawn = ticks + rng.rand_ticks #generate next spawn tick value
        end
    end
end