#Gravity Runner game by Freya-The-Goddess
#Custom code project for Intro To Programming (COS10009) in 2020
#Code refactored and modified in 2022

#import external libraries
require 'rubygems'
require 'gosu'

#import other files
require_relative 'params'
require_relative 'ship'

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

    #returns true if mouse is inside button bounding box
    def mouse_over_button?(mouse_coords, button_coords)
        if mouse_coords[0] >= button_coords[0] && 
            mouse_coords[0] <= button_coords[1] && 
            mouse_coords[1] >= button_coords[2] && 
            mouse_coords[1] <= button_coords[3]
                return true
        else
            return false
        end
    end

    #read highscore from file if it exists else create the file
    def read_highscore
        if File.exists?(HIGHSCORE_PATH)
            begin
                #read high score from file
                highscore = Integer(File.read(HIGHSCORE_PATH))
            rescue #error reading or converting to integer
                highscore = 0
                write_highscore(highscore)
            end
        else #file doesn't exist
            highscore = 0
            write_highscore(highscore)
        end
        return highscore
    end

    #write highscore to file
    def write_highscore(highscore)
        File.open(HIGHSCORE_PATH, "w") do |file| #write high score to file
            file.write highscore.to_s
        end
    end

    #read user preferences from file if it exists else create the file
    def read_user_prefs
        if File.exists?(USER_PREFS_PATH)
            begin
                #read user preferences from file
                prefs = File.read(USER_PREFS_PATH).split(",")
                sound_on = prefs[0] == "true"
                music_on = prefs[1] == "true"
            rescue #error reading or converting to integer
                sound_on = true
                music_on = true
                write_user_prefs(sound_on, music_on)
            end
        else #file doesn't exist
            sound_on = true
            music_on = true
            write_user_prefs(sound_on, music_on)
        end
        return sound_on, music_on
    end

    #write user prefs to file
    def write_user_prefs(sound_on, music_on)
        File.open(USER_PREFS_PATH, "w") do |file| #write high score to file
            file.write sound_on.to_s + "," + music_on.to_s
        end
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

    #draw jump, gravity flip and pause buttons
    def draw_buttons(z_layer, ticks, gravity, paused)
        jump_button = @jump_button_ticks > ticks ? self.class.buttons[1] : self.class.buttons[0]
        pause_button = paused ? self.class.buttons[7] : self.class.buttons[6]
        if gravity == Gravity::DOWN
            grav_button = @grav_button_ticks > ticks ? self.class.buttons[3] : self.class.buttons[2]
        else
            grav_button = @grav_button_ticks > ticks ? self.class.buttons[5] : self.class.buttons[4]
        end

        jump_button.draw_rot(  0,              SCREEN_HEIGHT, z_layer, 0, 0,   1, 1, 1)
        pause_button.draw_rot( SCREEN_WIDTH/2, SCREEN_HEIGHT, z_layer, 0, 0.5, 1, 1, 1)
        grav_button.draw_rot(  SCREEN_WIDTH,   SCREEN_HEIGHT, z_layer, 0, 1,   1, 1, 1)
    end

    #draw sound and music on/off buttons
    def draw_sound_buttons(z_layer, sound_on, music_on)
        sound_button = sound_on ? self.class.buttons[8] : self.class.buttons[9]
        music_button = music_on ? self.class.buttons[10] : self.class.buttons[11]

        sound_button.draw_rot( -30,             10, z_layer, 0, 0, 0, 1, 1)
        music_button.draw_rot( SCREEN_WIDTH+30, 10, z_layer, 0, 1, 0, 1, 1)
    end

    #draw pause screen overlay and sound buttons
    def draw_pause_screen(z_layer, sound_on, music_on)
        draw_overlay(z_layer, 3) #draw pause screen overlay
        draw_sound_buttons(z_layer, sound_on, music_on)
    end

    #draw pause screen overlay and sound buttons
    def draw_game_over_screen(z_layer, sound_on, music_on)
        draw_overlay(z_layer, 2) #draw pause screen overlay
        draw_sound_buttons(z_layer, sound_on, music_on)
    end

    #draw score and high score to screen
    def draw_score(z_layer, score, high_score)
        #draw score
        self.class.font.draw_text("Score: #{score.to_i.to_s}", 10, 5, z_layer, 1.0, 1.0, SCORE_TEXT_COLOR)
        
        #draw high score
        text_color = SCORE_TEXT_COLOR
        text_color = NEW_HIGHSCORE_TEXT_COLOR if score.to_i > high_score #red text when high score beat

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

    #play jump sound effect
    def play_jump_sound
        self.class.jump_sound.play
    end

    #play gravity flip sound effect
    def play_gravity_sound
        self.class.gravity_sound.play
    end
    
    #play game over sound effect
    def play_game_over_sound
        self.class.game_over_sound.play
    end

    #Gosu font (class instance variable)
    @font = Gosu::Font.new(20, name:FONT_PATH)

    #UI images (class instance variable)
    @space = Gosu::Image.new(SPACE_IMAGE_PATH)
    @buttons = Gosu::Image.load_tiles(BUTTON_TILES_PATH, BUTTON_SIZE, BUTTON_SIZE)
    @overlays = Gosu::Image.load_tiles(OVERLAY_TILES_PATH, SCREEN_WIDTH, SCREEN_HEIGHT)

    #sound effects (class instance variable)
    @jump_sound = Gosu::Sample.new(JUMP_SOUND_PATH)
    @gravity_sound = Gosu::Sample.new(GRAVITY_SOUND_PATH)
    @game_over_sound = Gosu::Sample.new(GAME_OVER_SOUND_PATH)
    
    #singleton object
    class << self
        #class instance variable accessors
        public attr_reader :font, :space, :buttons, :overlays, :jump_sound, :gravity_sound, :game_over_sound
        private attr_writer :font, :space, :buttons, :overlays, :jump_sound, :gravity_sound, :game_over_sound
    end
end