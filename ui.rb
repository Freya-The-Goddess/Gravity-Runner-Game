#Gravity Runner game by Freya-The-Goddess
#Custom code project for Intro To Programming (COS10009)

#import external libraries
require 'rubygems'
require 'gosu'

#import other files
require_relative 'params'

#user interface class for drawing background, buttons and overlays
class UI
    #public attributes
    attr_accessor :jump_button_ticks, :grav_button_ticks

    def initialize(font)
        @font = font
        @jump_button_ticks = 0
        @grav_button_ticks = 0
        @space = Gosu::Image.new("media/space.png")
        @buttons = Gosu::Image.load_tiles("media/buttons.png", 150, 150)
        @overlays = Gosu::Image.load_tiles("media/overlay.png", SCREEN_WIDTH, SCREEN_HEIGHT)
    end

    #draw background color and two layers of scrolling stars 
    def draw_background(z_layer, ticks)
        #background color
        Gosu.draw_rect(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT, BACKGROUND_COLOR, z_layer, mode=:default)

        #background layer 2
        shift_stars = (ticks % (SCREEN_WIDTH/(BACKGROUND_SPEED/2)))*BACKGROUND_SPEED/2
        @space.draw_as_quad(SCREEN_WIDTH-shift_stars,              SCREEN_HEIGHT, BLEND, 0-shift_stars,              SCREEN_HEIGHT, BLEND, 0-shift_stars,              0, BLEND, SCREEN_WIDTH-shift_stars,              0, BLEND, z_layer, mode=:default)
        @space.draw_as_quad(SCREEN_WIDTH-shift_stars+SCREEN_WIDTH, SCREEN_HEIGHT, BLEND, 0-shift_stars+SCREEN_WIDTH, SCREEN_HEIGHT, BLEND, 0-shift_stars+SCREEN_WIDTH, 0, BLEND, SCREEN_WIDTH-shift_stars+SCREEN_WIDTH, 0, BLEND, z_layer, mode=:default)
        
        #background layer 1
        shift_stars = (ticks % (SCREEN_WIDTH/BACKGROUND_SPEED))*BACKGROUND_SPEED
        @space.draw_as_quad(0-shift_stars,              0, BLEND, SCREEN_WIDTH-shift_stars,              0, BLEND, SCREEN_WIDTH-shift_stars,              SCREEN_HEIGHT, BLEND, 0-shift_stars,              SCREEN_HEIGHT, BLEND, z_layer, mode=:default)
        @space.draw_as_quad(0-shift_stars+SCREEN_WIDTH, 0, BLEND, SCREEN_WIDTH-shift_stars+SCREEN_WIDTH, 0, BLEND, SCREEN_WIDTH-shift_stars+SCREEN_WIDTH, SCREEN_HEIGHT, BLEND, 0-shift_stars+SCREEN_WIDTH, SCREEN_HEIGHT, BLEND, z_layer, mode=:default)
    end

    #draw jump and gravity flip buttons
    def draw_buttons(z_layer, ticks, gravity)
        jump_button = @buttons[0] #button unpressed
        jump_button = @buttons[1] if @jump_button_ticks > ticks #button pressed
        
        case gravity
            when Gravity::DOWN
                grav_button = @buttons[2] #button unpressed
                grav_button = @buttons[3] if @grav_button_ticks > ticks #button pressed
            when Gravity::UP
                grav_button = @buttons[4] #button unpressed
                grav_button = @buttons[5] if @grav_button_ticks > ticks #button pressed
        end

        #draw buttons to screen
        jump_button.draw_rot(0,            SCREEN_HEIGHT, z_layer, 0, 0, 1, 1, 1)
        grav_button.draw_rot(SCREEN_WIDTH, SCREEN_HEIGHT, z_layer, 0, 1, 1, 1, 1)
    end

    #draw score and high score to screen
    def draw_score(z_layer, score, high_score)
        #draw score
        @font.draw_text("Score: #{score.to_i.to_s}", 10, 5, z_layer, 1.0, 1.0, SCORE_TEXT_COLOR)
        
        #draw high score
        text_color = SCORE_TEXT_COLOR
        text_color = NEW_HIGHSCORE_COLOR if score.to_i > high_score #red text when high score beat

        @font.draw_text("High Score: #{high_score.to_s}", SCREEN_WIDTH-145-(high_score.to_s.length*11), 5, z_layer, 1.0, 1.0, text_color)
    end

    #draw overlay based on specified index
    def draw_overlay(z_layer, overlay_index)
        @overlays[overlay_index].draw_as_quad(0, 0, BLEND, SCREEN_WIDTH, 0, BLEND, SCREEN_WIDTH, SCREEN_HEIGHT, BLEND, 0, SCREEN_HEIGHT, BLEND, z_layer, mode=:default)
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
end