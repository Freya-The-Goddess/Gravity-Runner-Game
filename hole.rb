#Gravity Runner game by Freya-The-Goddess
#Custom code project for Intro To Programming (COS10009)

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
        x_vel = 0
        width, height = 150, 20
        tiles = Gosu::Image.load_tiles("media/hole.png", 170, 20)
        super(x_coord, y_coord, x_vel, height, width, tiles)
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
        @tiles[tile].draw_rot(@x_coord, @y_coord, z_layer, 0, 0.5, 0.5, 1, 1)
    end

    #singleton class
    class << self
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
    end
end