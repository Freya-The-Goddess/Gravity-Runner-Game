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

    #obstacle sprites array (class instance variable)
    @tiles = Gosu::Image.load_tiles(OBSTACLE_TILES_PATH, OBSTACLE_SIZE, OBSTACLE_SIZE)
    
    def initialize(x_coord, y_coord, tile_size, type)
        @type = type
        super(x_coord, y_coord, 0, tile_size, tile_size)
    end

    #update obstacle each frame
    def update(gravity, holes, ship_speed)
        self.do_horizontal(ship_speed)
        self.do_gravity(gravity)
        self.on_floor?(gravity, holes)
    end

    #draw obstacle (crate)
    def draw(z_layer)
        self.class.tiles[@type].draw_rot(@x_coord, @y_coord, z_layer, 0, 0.5, 0.5, 1, 1)
    end

    #singleton object
    class << self
        #create new obstacle with randomized type
        def summon(gravity)
            if gravity == Gravity::UP
                y_coord = CEILING_Y+OBSTACLE_SIZE/2
            else
                y_coord = FLOOR_Y-OBSTACLE_SIZE/2
            end
            type = rand(0..3) #select random obstacle sprite
            return Obstacle.new(SCREEN_WIDTH+OBSTACLE_SIZE, y_coord, OBSTACLE_SIZE, type)
        end
    end
end