#Gravity Runner game by Freya-The-Goddess
#Custom code project for Intro To Programming (COS10009) in 2020
#Code refactored and modified in 2022

#import external libraries
require 'rubygems'
require 'gosu'

#import other files
require_relative 'params'
require_relative 'entity'

#Obstacle class (inherits Entity)
class Obstacle < Entity
    #public attributes
    attr_accessor :x_coord, :y_coord, :height, :width
    
    def initialize(x_coord, y_coord, tile_size, width, type, static)
        @type, @static = type, static
        super(x_coord, y_coord, 0, tile_size, width)
    end

    #update obstacle each frame
    def update(gravity, holes, ship_speed, sound_on)
        do_horizontal(ship_speed)
        do_gravity(gravity)

        play_impact_sound if !@static && on_floor?(gravity, holes) && sound_on
        @static = on_floor?(gravity, holes)
    end

    #draw obstacle (crate)
    def draw(z_layer)
        self.class.tiles[@type].draw_rot(@x_coord, @y_coord, z_layer, 0, 0.5, 0.5, 1, 1)
    end

    #play impact sound effect
    def play_impact_sound
        self.class.impact_sound.play_pan(calc_audio_pan(@x_coord), calc_audio_volume(@x_coord), 1, false)
    end

    #class instance variables
    @impact_sound = Gosu::Sample.new(OBSTACLE_IMPACT_SOUND_PATH) #footsteps looping sound effect
    @rng = RandNormDist.new(OBSTACLE_SPAWN_BASE, OBSTACLE_SPAWN_SD) #spawn ticks randomizer
    @tiles = []

    @tiles += Gosu::Image.load_tiles(CRATE_TILES_PATH, OBSTACLE_WIDTH, OBSTACLE_CRATE_HEIGHT) #append crates to tiles array
    @tiles += Gosu::Image.load_tiles(BARREL_TILES_PATH, OBSTACLE_WIDTH, OBSTACLE_BARREL_HEIGHT) #append barrels to tiles array

    #singleton object
    class << self
        #class instance variable accessors
        public attr_accessor :next_spawn
        public attr_reader :impact_sound
        private attr_accessor :rng
        private attr_writer :impact_sound

        #create new obstacle with randomized type
        def summon(gravity, type = nil)
            type = rand(0...OBSTACLE_CRATE_VARIATIONS+OBSTACLE_BARREL_VARIATIONS) if type.nil? #select random obstacle sprite
            height = type < OBSTACLE_CRATE_VARIATIONS ? OBSTACLE_CRATE_HEIGHT : OBSTACLE_BARREL_HEIGHT
            y_coord = gravity == Gravity::UP ? CEILING_Y+height/2 : FLOOR_Y-height/2
            static = gravity == Gravity::UP ? :ceiling : :floor
            return Obstacle.new(SCREEN_WIDTH+OBSTACLE_WIDTH, y_coord, height, OBSTACLE_WIDTH, type, static)
        end

        #calculate ticks for next spawn event based on normal distribution
        def calc_next_spawn(ticks, difficulty)
            rng.mean = OBSTACLE_SPAWN_BASE / ((difficulty - 1) * OBSTACLE_SPAWN_MULT + 1) #update mean of normal distribution
            @next_spawn = ticks + rng.rand_ticks #generate next spawn tick value
        end
    end
end