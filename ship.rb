#Gravity Runner game by Freya-The-Goddess
#Custom code project for Intro To Programming (COS10009) in 2020
#Code refactored and modified in 2022

#import external libraries
require 'rubygems'
require 'gosu'

#import other files
require_relative 'params'

class Ship
    #public attributes
    attr_accessor :speed

    def initialize
        @sections = []
        for i in 0..4 
            @sections.append(ShipSection.new(SHIP_SECTION_WIDTH * i))
        end
        reset
    end

    #reset ship to starting values
    def reset
        @speed = SHIP_START_SPEED #starting speed
        for section in @sections
            section.reset
        end
        ShipSection.next_type = 0
    end

    #accelerate ship horizontally
    def accelerate
        @speed += SHIP_ACCELERATION #increase ship speed
    end

    #move ship sections horizontally
    def move
        for section in @sections
            section.move(@speed)
        end
    end

    #draw ship sections
    def draw(z_layer)
        for section in @sections
            section.draw(z_layer)
        end
    end

end

class ShipSection
    def initialize(x_coord)
        @x_coord = x_coord
        reset
    end

    #reset type to randomized normal tile
    def reset
        @type = rand(0..2) > 0 ? 0 : rand(1...SHIP_NORMAL_TILES)
    end

    #move ship section horizontally
    def move(speed)
        @x_coord -= speed
        #if off left of screen, move to right of screen and change type randomly
        if @x_coord < 0 - SHIP_SECTION_WIDTH 
            @type = self.class.rand_type
            @x_coord += SCREEN_WIDTH + SHIP_SECTION_WIDTH
        end
    end

    #draw ship section
    def draw(z_layer)
        self.class.tiles[@type].draw_as_quad(
            @x_coord - 1,                      CEILING_Y - FLOOR_THICKNESS, BLEND,
            @x_coord + 1 + SHIP_SECTION_WIDTH, CEILING_Y - FLOOR_THICKNESS, BLEND, 
            @x_coord + 1 + SHIP_SECTION_WIDTH, FLOOR_Y + FLOOR_THICKNESS,   BLEND, 
            @x_coord - 1,                      FLOOR_Y + FLOOR_THICKNESS,   BLEND, 
            z_layer, mode=:default)
    end

    #ship sprites (class instance variable)
    @tiles = Gosu::Image.load_tiles(SHIP_IMAGE_PATH, SHIP_SECTION_WIDTH + 2, SHIP_SECTION_HEIGHT)

    #singleton object
    class << self
        public attr_accessor :next_type
        public attr_reader :tiles
        private attr_writer :tiles

        #generate ship section type
        def rand_type
            if rand(0..9) < 6 #60% chance of normal tile
                type = rand(0..2) > 0 ? 0 : rand(1...SHIP_NORMAL_TILES)
            else #40% chance of special tile
                type = @next_type
                @next_type += rand(2..4)
                @next_type -= SHIP_SPECIAL_TILES if @next_type >= SHIP_NORMAL_TILES + SHIP_SPECIAL_TILES
            end
            return type
        end
    end
end