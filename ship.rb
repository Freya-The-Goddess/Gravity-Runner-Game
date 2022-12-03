#Gravity Runner game by Freya-The-Goddess
#Custom code project for Intro To Programming (COS10009)

#import external libraries
require 'rubygems'
require 'gosu'

#import other files
require_relative 'params'

class Ship
    #public attributes
    attr_accessor :speed

    def initialize
        @speed = SHIP_START_SPEED #starting speed
        @x_shift = 0.0 #stores pixels to shift ship image for current frame
    end

    #move ship horizontally
    def move
        @speed += SHIP_ACCELERATION #increase ship speed

        @x_shift += @speed
        if @x_shift >= SCREEN_WIDTH
            @x_shift -= SCREEN_WIDTH
        end
    end

    #draw spaceship
    def draw(z_layer)
        self.class.tile.draw_as_quad(0.0-@x_shift,              CEILING_Y-FLOOR_THICKNESS, BLEND, SCREEN_WIDTH.to_f-@x_shift,              CEILING_Y-FLOOR_THICKNESS, BLEND, SCREEN_WIDTH.to_f-@x_shift,              FLOOR_Y+FLOOR_THICKNESS, BLEND, 0.0-@x_shift,              FLOOR_Y+FLOOR_THICKNESS, BLEND, z_layer, mode=:default)
        self.class.tile.draw_as_quad(0.0-@x_shift+SCREEN_WIDTH, CEILING_Y-FLOOR_THICKNESS, BLEND, SCREEN_WIDTH.to_f-@x_shift+SCREEN_WIDTH, CEILING_Y-FLOOR_THICKNESS, BLEND, SCREEN_WIDTH.to_f-@x_shift+SCREEN_WIDTH, FLOOR_Y+FLOOR_THICKNESS, BLEND, 0.0-@x_shift+SCREEN_WIDTH, FLOOR_Y+FLOOR_THICKNESS, BLEND, z_layer, mode=:default)
    end

    #ship sprite (class instance variable)
    @tile = Gosu::Image.new(SHIP_IMAGE_PATH)

    #singleton object
    class << self
        public attr_reader :tile
        private attr_writer :tile
    end
end