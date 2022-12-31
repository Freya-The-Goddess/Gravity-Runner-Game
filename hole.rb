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
    
    def initialize(x_coord, y_coord, direction, size)
        @direction = direction
        @size = size
        super(x_coord, y_coord, 0, HOLE_HEIGHT, size * HOLE_BASE_WIDTH)
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

    #collision function for side of hole
    def side_collision?(entity)
        if @x_coord + @width/2 < entity.x_coord + entity.width/2 &&
            ((@direction == :floor   && FLOOR_Y + FLOOR_THICKNESS   < entity.y_coord + entity.height/2) ||
            ( @direction == :ceiling && CEILING_Y - FLOOR_THICKNESS > entity.y_coord - entity.height/2) )
                return true #collision detected
        end
        return false #no collision
    end

    #update hole each frame
    def update(ship_speed)
        do_horizontal(ship_speed)
    end

    #draw ship hole
    def draw(z_layer)
        tile = (@size - 1) * 2
        tile += 1 if @direction == :floor
        self.class.tiles[tile].draw_rot(@x_coord, @y_coord, z_layer, 0, 0.5, 0.5, 1, 1)
    end

    #class instance variables
    @spawn_rng = RandNormDist.new(HOLE_SPAWN_BASE, HOLE_SPAWN_SD) #spawn ticks randomizer
    @size_rng = RandNormDist.new(HOLE_SIZE_MEAN, HOLE_SIZE_SD) #hole size randomizer
    @tiles = [] #hole tiles array

    #split holes texture into tiles using subimage (sprites are different sizes)
    texture = Gosu::Image.new(HOLE_TILES_PATH) #hole texture
    for size in 1..HOLE_SIZE_MAX
        for dir in 0..1
            @tiles.append(texture.subimage(
                (((size - 1) * size / 2) * HOLE_BASE_WIDTH) + ((size - 1) * HOLE_SIDES_WIDTH), 
                dir * HOLE_HEIGHT, 
                size * HOLE_BASE_WIDTH + HOLE_SIDES_WIDTH, 
                HOLE_HEIGHT))
        end
    end

    #singleton object
    class << self
        #class instance variable accessors
        public attr_accessor :next_spawn
        private attr_accessor :spawn_rng, :size_rng

        #create new obstacle with randomized type
        def summon(direction = nil, size = nil)
            direction = [:floor,:ceiling][rand(0..1)] if direction.nil?
            y_coord = direction == :ceiling ? CEILING_Y-10 : FLOOR_Y+10

            size = size_rng.rand_i if size.nil?
            size = 1 if size < 1
            size = HOLE_SIZE_MAX if size > HOLE_SIZE_MAX

            return Hole.new(SCREEN_WIDTH+170, y_coord, direction, size)
        end

        #calculate ticks for next spawn event based on normal distribution
        def calc_next_spawn(ticks, difficulty)
            spawn_rng.mean = HOLE_SPAWN_BASE / ((difficulty - 1) * HOLE_SPAWN_MULT + 1) #update mean of normal distribution
            @next_spawn = ticks + spawn_rng.rand_ticks #generate next spawn tick value
        end
    end
end