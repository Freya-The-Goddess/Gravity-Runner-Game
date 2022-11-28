#Gravity Runner game by Freya-The-Goddess
#Custom code project for Intro To Programming (COS10009)

#import external libraries
require 'rubygems'
require 'gosu'
require 'abstract_method'

#import other files
require_relative 'params'

#Entity parent class (inherited by LiveEntity, Obstacle, Hole)
class Entity
    #public attributes
    attr_accessor :x_coord, :y_coord, :height, :width

    def initialize(x_coord, y_coord, x_vel, tile_size, width, tiles)
        @x_coord = x_coord.to_f
        @y_coord = y_coord.to_f
        @x_vel = x_vel
        @y_vel = 0.0
        @height = tile_size
        @width = width
        @tiles = tiles
    end

    #check if entity is outside window
    def off_screen?
        if @x_coord + @width/2 < 0
            return :left #entity is off screen
        elsif @y_coord + @height/2 < 0
            return :top #entity is off screen
        elsif @y_coord - @height/2 > SCREEN_HEIGHT
            return :bottom #entity is off screen
        else
            return false #entity is within window
        end
    end

    #check if entity hitbox collides with other entity
    def collision?(entity)
        if @x_coord - @width/2 < entity.x_coord + entity.width/2 && 
            @x_coord + @width/2 > entity.x_coord - entity.width/2 && 
            @y_coord - @height/2 < entity.y_coord + entity.height/2 && 
            @y_coord + @height/2 > entity.y_coord - entity.height/2
                return true #collision detected
        end
        return false #no collision
    end

    #check if entity is on floor (or ceiling) and update velocity if so
    def on_floor?(gravity, holes)
        holes.each do |hole|
            return false if hole.collision?(self)
        end
        return false if @y_coord > FLOOR_Y+20
        return false if @y_coord < CEILING_Y-20
        if @y_coord >= FLOOR_Y - @height/2
            @y_coord = FLOOR_Y - @height/2 #keep inside bounding box
            @y_vel = 0 #reset vertical velocity
            return :floor if gravity == Gravity::DOWN
        end
        if @y_coord <= CEILING_Y + @height/2
            @y_coord = CEILING_Y + @height/2 #keep inside bounding box
            @y_vel = 0 #reset vertical velocity
            return :ceiling if gravity == Gravity::UP
        end
        return false #if in midair
    end

    #Calculate and update entity's vertical velocity and coordinate
    def do_gravity(gravity)
        @y_vel += (gravity * GRAVITY_CONSTANT)
        @y_coord += @y_vel
    end

    #move entity horizontally based on its x velocity and the ship speed
    def do_horizontal(ship_speed)
        @x_coord -= (ship_speed + @x_vel)
    end

    #abstract methods to be overriden by children
    abstract_method :update
    abstract_method :draw
end

#LiveEntity parent class (inherited by Player and Enemy)
class LiveEntity < Entity
    #public attributes
    attr_accessor :x_coord, :y_coord, :height, :width

    def initialize(x_coord, y_coord, x_vel, tile_size, width, tiles)
        @angle, @frame = 0, 0
        @standing = true
        @flipping = false
        @dead = false
        super(x_coord, y_coord, x_vel, tile_size, width, tiles)
    end

    #cycle through entity's running frames
    def do_running(ticks)
        if @standing #running frames
            @frame = 0 if (ticks/TICKS_PER_RUN_FRAME)%4 == 1
            @frame = 1 if (ticks/TICKS_PER_RUN_FRAME)%2 == 0
            @frame = 2 if (ticks/TICKS_PER_RUN_FRAME)%4 == 3
        end
    end

    #Rotate entity if gravity is flipping
    def do_rotate(gravity)
        #rotate player/entity when gravity is flipped
        if gravity == Gravity::UP && @angle < 180
            if @standing == :ceiling #if on ceiling set angle
                @flipping = false
                @angle = 180
            else #if in midair adjust angle each frame
                @flipping = true
                @angle += 10
            end
        elsif gravity == Gravity::DOWN && @angle > 0
            if @standing == :floor #if on floor set angle
                @flipping = false
                @angle = 0
            else #if in midair adjust angle each frame
                @flipping = true
                @angle -= 10
            end
        end
    end

    #draw entity
    def draw(z_layer, gravity)
        if @dead
            frame = 4
            x_flip = 1
        elsif @standing == :floor #running on floor
            frame = @frame
            x_flip = 1
        elsif @standing == :ceiling #running on ceiling (flip image horizontally)
            frame = @frame
            x_flip = -1
        elsif !@standing && !@flipping #jumping
            if gravity == Gravity::DOWN
                frame = 1
                x_flip = 1
            elsif gravity == Gravity::UP
                frame = 1
                x_flip = -1
            end
        elsif @flipping #gravity flipping
            frame = 3
            x_flip = 1
        else
            frame = 1
            x_flip = 1
        end
        
        #draw entity tile
        @tiles[frame].draw_rot(@x_coord, @y_coord, z_layer, @angle, 0.5, 0.5, x_flip, 1)
    end

    #abstract methods to be overriden by children
    abstract_method :update
end