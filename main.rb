#Gravity Runner game by Freya-The-Goddess
#Custom code project for Intro To Programming (COS10009) in 2020
#Code refactored and modified in 2022

#import external libraries
require 'rubygems'
require 'gosu'

#import other files
require_relative 'params'
require_relative 'ui'
require_relative 'player'
require_relative 'enemy'
require_relative 'obstacle'
require_relative 'hole'

#GravityRunner game class (inherits Gosu window)
class GravityRunner < (Gosu::Window)
    def initialize()
        super(SCREEN_WIDTH, SCREEN_HEIGHT, false, UPDATE_INTERVAL) #call parent init to create game window
        self.caption = "Gravity Runner"
        new_game(false) #start new game
    end

    def new_game(restart)
        if !restart #first game
            @player = Player.new #create player instance
            @ui = UI.new #create UI instance (draws ship, background, buttons and overlays)

            @sound_on, @music_on = @ui.read_user_prefs #read user preferences from file
            @highscore = @ui.read_highscore #read highscore from file

            @show_instruct = true #show instructions first game
        end

        #reset game values to default
        @ticks = 0 #keeps track of total game ticks
        @difficulty = DIFFICULTY_START
        @score = 0 #score
        @paused = false
        @game_over = false
        @gravity = Gravity::DOWN #default gravity down

        @player.reset #reset player to starting values
        @ui.reset #reset ui to starting values

        #first spawn events (after which randomizers takes over)
        Enemy.next_spawn = FIRST_ENEMY
        Obstacle.next_spawn = FIRST_OBSTACLE
        Hole.next_spawn = FIRST_HOLE

        #reset entity lists
        @enemies = []
        @obstacles = []
        @holes = []
    end

    def needs_cursor?; true; end #enables mouse curser and touchscreen input

    #returns true if mouse is within specified bounding box
    def mouse_over_area?(min_x, min_y, max_x, max_y)
        if mouse_x >= min_x && 
            mouse_x <= max_x && 
            mouse_y >= min_y && 
            mouse_y <= max_y
                return true
        else
            return false
        end
    end

    #flip global gravity direction
    def flip_gravity
        @ui.grav_button_ticks = @ticks + BUTTON_PRESS_TICKS
        case @gravity
            when Gravity::DOWN
                @gravity = Gravity::UP
            when Gravity::UP
                @gravity = Gravity::DOWN
        end
    end

    #handle input events
    def button_down(id)
        case id
            #keyboard inputs
            when Gosu::KB_SPACE #jump
                if !@paused && !@player.dead && @player.standing
                    @ui.jump_button_ticks = @player.jump(@ticks, @gravity)
                    @ui.play_jump_sound if @sound_on
                end
            
            when Gosu::KB_RETURN #flip gravity
                if !@paused && !@player.dead
                    flip_gravity 
                    @ui.play_gravity_sound if @sound_on
                end
            
            when Gosu::KB_R #restart
                new_game(true) if @player.dead
            
            when Gosu::KB_ESCAPE #pause
                if !@player.dead
                    @paused = @paused ? false : true #swap value
                end

            #mouse / touchscreen inputs
            when Gosu::MsLeft
                if @player.dead #click anywhere to restart
                    new_game(true)

                elsif @paused 
                    if mouse_over_area?(0, 50, 100, 140) #sound on/off button
                        @sound_on = @sound_on ? false : true #swap value
                        @ui.write_user_prefs(@sound_on, @music_on) #save preferences
                    
                    elsif mouse_over_area?(SCREEN_WIDTH-100, 50, SCREEN_WIDTH, 140) #music on/off button
                        @music_on = @music_on ? false : true #swap value
                        @ui.write_user_prefs(@sound_on, @music_on) #save preferences
                    
                    else #click anywhere to resume
                        @paused = false
                    end
                
                else
                    if mouse_over_area?(0, SCREEN_HEIGHT-120, 150, SCREEN_HEIGHT) #jump button
                        if @player.standing
                            @ui.jump_button_ticks = @player.jump(@ticks, @gravity)
                            @ui.play_jump_sound if @sound_on
                        end
                    
                    elsif mouse_over_area?(SCREEN_WIDTH-150, SCREEN_HEIGHT-120, SCREEN_WIDTH, SCREEN_HEIGHT) #flip gravity button
                        flip_gravity
                        @ui.play_gravity_sound if @sound_on
                    
                    elsif mouse_over_area?(SCREEN_WIDTH/2-50, SCREEN_HEIGHT-80, SCREEN_WIDTH/2+50, SCREEN_HEIGHT) #pause button
                        @paused = true
                    end
                end
        end
    end

    #update game each frame (tick)
    def update
        if !@player.dead && !@paused
            @ticks += 1 #increment ticks
            @difficulty += DIFFICULTY_INCREASE #increase difficulty
            @score += @ui.ship.speed * SCORE_SCALER #increase score based on ship speed
            @ui.ship.move #move ship horizontally

            #SUMMON NEW ENEMIES, OBSTACLES AND HOLES
            if Enemy.next_spawn <= @ticks ##summon enemy(s) when next spawn ticks reached
                @enemies << Enemy.summon(@difficulty) #create new enemy
                @enemies << Enemy.summon(@difficulty) if rand(0..(50 / @difficulty).to_i) == 0 #chance for 2nd enemy to spawn
                Enemy.calc_next_spawn(@ticks, @difficulty) #calculate random ticks before next spawn event
            end

            if Obstacle.next_spawn <= @ticks #summon obstacle when next spawn ticks reached
                @obstacles << Obstacle.summon(@gravity) #create new obstacle
                Obstacle.calc_next_spawn(@ticks, @difficulty) #calculate random ticks before next spawn event
            end

            if Hole.next_spawn <= @ticks #summon hole when next spawn ticks reached
                if Hole.next_spawn == FIRST_HOLE 
                    @holes << Hole.summon(:floor) #create first hole on floor
                else 
                    @holes << Hole.summon #create hole with random direction
                end
                Hole.calc_next_spawn(@ticks, @difficulty) #calculate random ticks before next spawn event
            end

            #UPDATE PLAYER, ENEMIES, OBSTACLES AND HOLES
            @player.update(@gravity, @ticks, @holes, @sound_on) #update player position and state each frame

            @enemies.delete_if do |enemy| #update enemies each frame
                enemy.update(@ticks, @holes, @ui.ship.speed, @sound_on) #update enemy position and state
                @player.dead = true if enemy.collision?(@player) #check enemy collision with player
                if enemy.off_screen? #remove enemies that are off screen
                    enemy.stop_footsteps_sound
                    true
                end 
            end

            @obstacles.delete_if do |obstacle| #update obstacles each frame
                obstacle.update(@gravity, @holes, @ui.ship.speed) #update obstacle position and state
                @player.dead = true if obstacle.collision?(@player) #check obstacle collision with player
                true if obstacle.off_screen? #remove obstacles that are off screen
            end

            @holes.delete_if do |hole| #update holes each frame
                hole.update(@ui.ship.speed)
                true if hole.off_screen? #remove holes that are off screen
            end

        elsif @player.dead && !@game_over
            @game_over = true #set game_over to true so block only runs once when player dies
            @ui.play_game_over_sound if @sound_on #play game over sound

            #pause player and enemy footstep sound effects
            @player.pause_footsteps_sound
            @enemies.each do |enemy|
                enemy.pause_footsteps_sound
            end

            #update highscore if current score higher
            if @score.to_i > @highscore
                @highscore = @score.to_i
                @ui.write_highscore(@highscore)
            end

        elsif @paused
            #pause player and enemy footstep sound effects
            @player.pause_footsteps_sound
            @enemies.each do |enemy|
                enemy.pause_footsteps_sound
            end
        end
    end

    #draw frame to game window each tick
    def draw
        #DRAW BACKGROUND, SHIP AND UI
        @ui.draw_background(ZOrder::BACKGROUND, @ticks)
        @ui.draw_buttons(ZOrder::BUTTONS, @ticks, @gravity, @paused)
        @ui.draw_score(ZOrder::UI, @score, @highscore)
        @ui.ship.draw(ZOrder::SHIP)

        #DRAW OVERLAYS
        if @show_instruct && !@player.dead && !@paused #draw instructions on first game
            @show_instruct = @ui.draw_instructions(ZOrder::OVERLAY, @ticks)
        
        elsif @player.dead #draw death screen overlay with restart instructions
            @ui.draw_overlay(ZOrder::OVERLAY, 2)
        
        elsif @paused #pause screen overlay
            @ui.draw_pause_screen(ZOrder::OVERLAY, @sound_on, @music_on)
        end

        #DRAW PLAYER, ENEMIES, OBSTACLES AND HOLES
        @player.draw(ZOrder::PLAYER, @gravity) #draw player
        @enemies.each do |enemy| #draw enemies
            enemy.draw(ZOrder::ENTITIES)
        end
        @obstacles.each do |obstacle| #draw obstacles
            obstacle.draw(ZOrder::ENTITIES)
        end
        @holes.each do |hole| #draw holes
            hole.draw(ZOrder::SHIP)
        end
    end
end

#start Gosu window and game
GravityRunner.new.show if __FILE__ == $0