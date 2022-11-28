#Gravity Runner game by Freya-The-Goddess
#Custom code project for Intro To Programming (COS10009)

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
    
    def initialize(x_coord, y_coord, tile_size, tile_index)
        x_vel = 0
        tiles = []
        tiles << Gosu::Image.load_tiles("media/crates.png", tile_size, tile_size)[tile_index]
        super(x_coord, y_coord, x_vel, tile_size, tile_size, tiles)
    end

    #update obstacle each frame
    def update(gravity, holes, ship_speed)
        self.do_horizontal(ship_speed)
        self.do_gravity(gravity)
        self.on_floor?(gravity, holes)
    end

    #draw obstacle (crate)
    def draw(z_layer)
        @tiles[0].draw_rot(@x_coord, @y_coord, z_layer, 0, 0.5, 0.5, 1, 1)
    end

    #singleton class
    class << self
        #create new obstacle with randomized type
        def summon(gravity)
            type = rand(0..3)
            if gravity == Gravity::UP
                y_coord = CEILING_Y+OBSTACLE_SIZE/2
            else
                y_coord = FLOOR_Y-OBSTACLE_SIZE/2
            end
            return Obstacle.new(SCREEN_WIDTH+OBSTACLE_SIZE, y_coord, OBSTACLE_SIZE, type)
        end
    end
end