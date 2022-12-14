#Gravity Runner game by Freya-The-Goddess
#Custom code project for Intro To Programming (COS10009) in 2020
#Code refactored and modified in 2022

#import external libraries
require 'rubygems'
require 'gosu'

#import other files
require_relative 'params'
require_relative 'entity'

#Hole class (inherits Entity)
class Hole < Entity
    #public attributes
    attr_accessor :x_coord, :y_coord, :height, :width, :direction
    
    def initialize(x_coord, y_coord, direction)
        @direction = direction
        super(x_coord, y_coord, 0, HOLE_HEIGHT, HOLE_COLLIDE_WIDTH)
    end

    #override collision function for holes
    #x coordinate boundry conditions are different
    def collision?(entity)
        if @x_coord - @width/2 < entity.x_coord - entity.width/2 && 
            @x_coord + @width/2 > entity.x_coord + entity.width/2 && 
            @y_coord - @height/2 < entity.y_coord + entity.height/2 && 
            @y_coord + @height/2 > entity.y_coord - entity.height/2
                return true #collision detected
        end
        return false #no collision
    end

    #update hole each frame
    def update(ship_speed)
        self.do_horizontal(ship_speed)
    end

    #draw ship hole
    def draw(z_layer)
        if @direction == :ceiling
            tile = 1
        elsif @direction == :floor
            tile = 0
        end
        self.class.tiles[tile].draw_rot(@x_coord, @y_coord, z_layer, 0, 0.5, 0.5, 1, 1)
    end

    #class instance variables
    @tiles = Gosu::Image.load_tiles(HOLE_TILES_PATH, HOLE_WIDTH, HOLE_HEIGHT) #hole sprite
    @rng = RandNormDist.new(HOLE_SPAWN_BASE, HOLE_SPAWN_SD) #spawn ticks randomizer

    #singleton object
    class << self
        #class instance variable accessors
        attr_accessor :next_spawn
        private attr_accessor :rng

        #create new obstacle with randomized type
        def summon(direction = nil)
            direction = [:floor,:ceiling][rand(0..1)] if direction.nil?
            if direction == :ceiling
                y_coord = CEILING_Y-10
            elsif direction == :floor
                y_coord = FLOOR_Y+10
            end
            return Hole.new(SCREEN_WIDTH+170, y_coord, direction)
        end

        #calculate ticks for next spawn event based on normal distribution
        def calc_next_spawn(ticks, difficulty)
            rng.mean = HOLE_SPAWN_BASE / ((difficulty - 1) * HOLE_SPAWN_MULT + 1) #update mean of normal distribution
            @next_spawn = ticks + rng.rand_ticks #generate next spawn tick value
        end
    end
end