#Gravity Runner game by Freya-The-Goddess
#Custom code project for Intro To Programming (COS10009)

#import external libraries
require 'rubygems'
require 'gosu'

#import other files
require_relative 'params'
require_relative 'ui'
require_relative 'ship'
require_relative 'player'
require_relative 'enemy'
require_relative 'obstacle'
require_relative 'hole'

#GravityRunner game class (inherits Gosu window)
class GravityRunner < (Gosu::Window)
    def initialize()
        super(SCREEN_WIDTH, SCREEN_HEIGHT) #call parent init to create game window
        self.caption = "Gravity Runner"
        new_game(false) #start new game
    end

    def new_game(restart)
        if !restart #first game
            #load high score if it exists
            if File.exists?(HIGHSCORE_PATH)
                begin
                    #read high score from file
                    @high_score = Integer(File.read(HIGHSCORE_PATH))
                rescue #error reading or converting to integer
                    @high_score = 0
                    write_highscore
                end
            else #file doesn't exist
                @high_score = 0
                write_highscore
            end
            @show_instruct = true #show instructions first game
        end

        @ticks = 0 #keeps track of total game ticks
        @difficulty = DIFFICULTY_START
        @score = 0 #score
        @paused = false

        #first spawn events (after which randomisers take over)
        @next_obstacle = 20
        @next_hole = 200
        @next_spawn = 600

        @gravity = Gravity::DOWN #default gravity down

        @player = Player.new #create player instance
        @ui = UI.new #create UI instance (draws ship, background, buttons and overlays)
        
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

    #write highscore to file
    def write_highscore
        File.open(HIGHSCORE_PATH, "w") do |file| #write high score to file
            file.write @high_score.to_s
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
            when Gosu::KB_SPACE #jump
                @ui.jump_button_ticks = @player.jump(@ticks, @gravity) if !@paused
            when Gosu::KB_RETURN #flip gravity
                flip_gravity if !@player.dead && !@paused
            when Gosu::KB_R #restart
                new_game(true) if @player.dead
            when Gosu::KB_ESCAPE #pause
                if !@player.dead
                    if @paused
                        @paused = false
                    else
                        @paused = true
                    end
                end

            when Gosu::MsLeft
                if @player.dead #click anywhere to restart
                    new_game(true)
                elsif @paused #click anywhere to resume
                    @paused = false
                else
                    if mouse_over_area?(0, SCREEN_HEIGHT-120, 150, SCREEN_HEIGHT) #jump button
                        @ui.jump_button_ticks = @player.jump(@ticks, @gravity)
                    elsif mouse_over_area?(SCREEN_WIDTH-150, SCREEN_HEIGHT-120, SCREEN_WIDTH, SCREEN_HEIGHT) #flip gravity button
                        flip_gravity
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
            if @next_spawn <= @ticks ##summon enemy(s) when next spawn ticks reached
                @enemies << Enemy.summon(@difficulty) #spawn enemy with randomised attributes 
                @enemies << Enemy.summon(@difficulty) if rand(0..(50 / @difficulty).to_i) == 0 #chance for 2nd enemy to spawn
                @enemies << Enemy.summon(@difficulty) if rand(0..(100 / @difficulty).to_i) == 0 #chance for 3rd enemy to spawn

                min = (ENEMY_SPAWN_MIN / @difficulty).to_i
                max = (min + (ENEMY_SPAWN_MAX - ENEMY_SPAWN_MIN) / @difficulty).to_i
                @next_spawn = @ticks + rand(min..max) #randomised amount of ticks before next spawn event
            end

            if @next_obstacle <= @ticks #summon obstacle when next spawn ticks reached
                @obstacles << Obstacle.summon(@gravity) #create new obstacle with randomized type
                
                min = (OBSTACLE_SPAWN_MIN / @difficulty).to_i
                max = (min + (OBSTACLE_SPAWN_MAX - OBSTACLE_SPAWN_MIN) / @difficulty).to_i
                @next_obstacle = @ticks + rand(min..max) #randomised amount of ticks before next spawn event
            end

            if @next_hole <= @ticks #summon hole when next spawn ticks reached
                if @next_hole == 200 #first hole always on floor
                    @holes << Hole.summon(:floor)
                else #all other holes random direction
                    @holes << Hole.summon
                end

                min = (HOLE_SPAWN_MIN / @difficulty).to_i
                max = (min + (HOLE_SPAWN_MAX - HOLE_SPAWN_MIN) / @difficulty).to_i
                @next_hole = @ticks + rand(min..max) #randomised amount of ticks before next spawn event
            end

            #UPDATE PLAYER, ENEMIES, OBSTACLES AND HOLES
            @player.update(@gravity, @ticks, @holes) #update player position and state each frame

            @enemies.delete_if do |enemy| #update enemies each frame
                enemy.update(@ticks, @holes, @ui.ship.speed) #update enemy position and state
                @player.dead = true if enemy.collision?(@player) #check enemy collision with player
                true if enemy.off_screen? #remove enemies that are off screen
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
        elsif @player.dead
            if @score.to_i > @high_score
                @high_score = @score.to_i #update high score
                write_highscore
            end
        end
    end

    #draw frame to game window each tick
    def draw
        #DRAW BACKGROUND, SHIP AND UI
        @ui.draw_background(ZOrder::BACKGROUND, @ticks) #draw scrolling background
        @ui.draw_buttons(ZOrder::BUTTONS, @ticks, @gravity, @paused) #draw buttons for jump and flip
        @ui.draw_score(ZOrder::UI, @score, @high_score) #draw score
        @ui.ship.draw(ZOrder::SHIP) #draw spaceship

        #DRAW INSTRUCTIONS OVERLAYS OR DEATH SCREEN OVERLAY
        if @show_instruct && !@player.dead && !@paused #draw instructions on first game
            @show_instruct = @ui.draw_instructions(ZOrder::OVERLAY, @ticks)
        elsif @player.dead #draw death screen overlay with restart instructions
            @ui.draw_overlay(ZOrder::OVERLAY, 2)
        elsif @paused #pause screen overlay
            @ui.draw_overlay(ZOrder::OVERLAY, 3)
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