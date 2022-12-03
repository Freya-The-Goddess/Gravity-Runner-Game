#Gravity Runner game by Freya-The-Goddess
#Custom code project for Intro To Programming (COS10009)

#import external libraries
require 'rubygems'
require 'gosu'

#import other files
require_relative 'params'
require_relative 'entity'

#Player class (inherits LiveEntity)
class Player < LiveEntity
    #public attributes
    attr_accessor :x_coord, :y_coord, :height, :width, :dead

    #player sprites array (class instance variable)
    @tiles = Gosu::Image.load_tiles(PLAYER_TILES_PATH, PLAYER_SIZE, PLAYER_SIZE)

    def initialize
        super(120, FLOOR_Y-PLAYER_SIZE/2, 0, PLAYER_SIZE, PLAYER_WIDTH)
    end

    #player jump input
    def jump(ticks, gravity)
        if @standing && !@dead
            @y_vel = JUMP_CONSTANT * gravity #multiply by 1 or -1 depending on if player is jumping off FLOOR_Y or CEILING_Y
            return ticks + BUTTON_PRESS_TICKS #jump button ticks
        end
        return 0
    end

    #update player each frame
    def update(gravity, ticks, holes)
        self.do_gravity(gravity) #update player's vertical velocity and position
        @standing = self.on_floor?(gravity, holes)
        @flipping = false if @standing
        self.do_rotate(gravity) #calculate player's rotation while in midair
        self.do_running(ticks) #update player's current running animation frame

        #player dies if outside ship (fell through hole)
        @dead = true if @y_coord-(PLAYER_SIZE/2) < CEILING_Y - 60
        @dead = true if @y_coord+(PLAYER_SIZE/2) > FLOOR_Y + 60
    end

    #draw player by calling super function
    def draw(z_layer, gravity)
        super(z_layer, gravity)
    end
end