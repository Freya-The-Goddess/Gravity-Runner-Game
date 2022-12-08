#Gravity Runner game by Freya-The-Goddess
#Custom code project for Intro To Programming (COS10009) in 2020
#Code refactored and modified in 2022

#import external libraries
require 'rubygems'
require 'gosu'

#import other files
require_relative 'params'

#user interface class for drawing background, buttons, overlays and score
class UI
    #public attributes
    attr_accessor :jump_button_ticks, :grav_button_ticks, :ship

    def initialize
        @jump_button_ticks, @grav_button_ticks = 0, 0
        @ship = Ship.new #create ship instance
    end

    #reset ui to starting values
    def reset
        @jump_button_ticks, @grav_button_ticks = 0, 0
        @ship.reset #reset ship to starting values
    end

    #draw background color and two layers of scrolling stars 
    def draw_background(z_layer, ticks)
        #background color
        Gosu.draw_rect(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT, BACKGROUND_COLOR, z_layer, mode=:default)

        #background layer 2
        shift_stars = (ticks % (SCREEN_WIDTH/(BACKGROUND_SPEED/2)))*BACKGROUND_SPEED/2
        self.class.space.draw_as_quad(SCREEN_WIDTH-shift_stars,              SCREEN_HEIGHT, BLEND, 0-shift_stars,              SCREEN_HEIGHT, BLEND, 0-shift_stars,              0, BLEND, SCREEN_WIDTH-shift_stars,              0, BLEND, z_layer, mode=:default)
        self.class.space.draw_as_quad(SCREEN_WIDTH-shift_stars+SCREEN_WIDTH, SCREEN_HEIGHT, BLEND, 0-shift_stars+SCREEN_WIDTH, SCREEN_HEIGHT, BLEND, 0-shift_stars+SCREEN_WIDTH, 0, BLEND, SCREEN_WIDTH-shift_stars+SCREEN_WIDTH, 0, BLEND, z_layer, mode=:default)
        
        #background layer 1
        shift_stars = (ticks % (SCREEN_WIDTH/BACKGROUND_SPEED))*BACKGROUND_SPEED
        self.class.space.draw_as_quad(0-shift_stars,              0, BLEND, SCREEN_WIDTH-shift_stars,              0, BLEND, SCREEN_WIDTH-shift_stars,              SCREEN_HEIGHT, BLEND, 0-shift_stars,              SCREEN_HEIGHT, BLEND, z_layer, mode=:default)
        self.class.space.draw_as_quad(0-shift_stars+SCREEN_WIDTH, 0, BLEND, SCREEN_WIDTH-shift_stars+SCREEN_WIDTH, 0, BLEND, SCREEN_WIDTH-shift_stars+SCREEN_WIDTH, SCREEN_HEIGHT, BLEND, 0-shift_stars+SCREEN_WIDTH, SCREEN_HEIGHT, BLEND, z_layer, mode=:default)
    end

    #draw jump and gravity flip buttons
    def draw_buttons(z_layer, ticks, gravity, paused)
        jump_button = self.class.buttons[0] #jump button unpressed
        jump_button = self.class.buttons[1] if @jump_button_ticks > ticks #jump button pressed
        pause_button = self.class.buttons[6] #pause button unpressed
        pause_button = self.class.buttons[7] if paused #pause button pressed
        case gravity
            when Gravity::DOWN
                grav_button = self.class.buttons[2] #gravity button unpressed
                grav_button = self.class.buttons[3] if @grav_button_ticks > ticks #gravity button pressed
            when Gravity::UP
                grav_button = self.class.buttons[4] #gravity button unpressed
                grav_button = self.class.buttons[5] if @grav_button_ticks > ticks #gravity button pressed
        end

        #draw buttons to screen
        jump_button.draw_rot(  0,              SCREEN_HEIGHT, z_layer, 0, 0,   1, 1, 1)
        pause_button.draw_rot( SCREEN_WIDTH/2, SCREEN_HEIGHT, z_layer, 0, 0.5, 1, 1, 1)
        grav_button.draw_rot(  SCREEN_WIDTH,   SCREEN_HEIGHT, z_layer, 0, 1,   1, 1, 1)
    end

    #draw score and high score to screen
    def draw_score(z_layer, score, high_score)
        #draw score
        self.class.font.draw_text("Score: #{score.to_i.to_s}", 10, 5, z_layer, 1.0, 1.0, SCORE_TEXT_COLOR)
        
        #draw high score
        text_color = SCORE_TEXT_COLOR
        text_color = NEW_HIGHSCORE_COLOR if score.to_i > high_score #red text when high score beat

        self.class.font.draw_text("High Score: #{high_score.to_s}", SCREEN_WIDTH-145-(high_score.to_s.length*11), 5, z_layer, 1.0, 1.0, text_color)
    end

    #draw overlay based on specified index
    def draw_overlay(z_layer, overlay_index)
        self.class.overlays[overlay_index].draw_as_quad(0, 0, BLEND, SCREEN_WIDTH, 0, BLEND, SCREEN_WIDTH, SCREEN_HEIGHT, BLEND, 0, SCREEN_HEIGHT, BLEND, z_layer, mode=:default)
    end

    #draw instructions based on game ticks
    def draw_instructions(z_layer, ticks)
        if ticks > 80 && ticks < 300
            self.draw_overlay(z_layer, 0) #jump instruction
        elsif ticks > 350 && ticks < 600
            self.draw_overlay(z_layer, 1) #flip gravity instruction
        elsif ticks > 600
            return false #instructions complete (don't show again)
        end
        return true
    end

    #Gosu font (class instance variable)
    @font = Gosu::Font.new(20, name:FONT_PATH)

    #UI images (class instance variable)
    @space = Gosu::Image.new(SPACE_IMAGE_PATH)
    @buttons = Gosu::Image.load_tiles(BUTTON_TILES_PATH, BUTTON_SIZE, BUTTON_SIZE)
    @overlays = Gosu::Image.load_tiles(OVERLAY_TILES_PATH, SCREEN_WIDTH, SCREEN_HEIGHT)
    
    #singleton object
    class << self
        public attr_reader :font, :space, :buttons, :overlays
        private attr_writer :font, :space, :buttons, :overlays
    end
end