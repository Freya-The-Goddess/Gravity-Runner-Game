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
    def initialize(restart = false)
        if !restart
            super(SCREEN_WIDTH, SCREEN_HEIGHT)
            self.caption = "Gravity Runner"
            @show_instruct = true
            @font = Gosu::Font.new(20, name:"./media/courier-new-bold.ttf")
        end

        @ticks = 0 #keeps track of total game ticks
        @score = 0 #score
        @difficulty = DIFFICULTY_START

        #first spawn events (after which randomisers take over)
        @next_obstacle = 20
        @next_hole = 200
        @next_spawn = 600

        @gravity = Gravity::DOWN #default gravity down

        @player = Player.new(FLOOR_Y-PLAYER_SIZE/2, PLAYER_SIZE, PLAYER_WIDTH) #create player instance
        @ship = Ship.new() #create ship instance
        @ui = UI.new(@font) #create UI instance (background, buttons and overlays)
        
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
            when Gosu::KB_SPACE #jump
                @ui.jump_button_ticks = @player.jump(@ticks, @gravity)
            when Gosu::KB_RETURN #flip gravity
                flip_gravity if !@player.dead
            when Gosu::KB_R #restart
                initialize(true) if @player.dead

            when Gosu::MsLeft
                if @player.dead #click anywhere to restart
                    initialize(true)
                else
                    if mouse_over_area?(0, SCREEN_HEIGHT-100, 150, SCREEN_HEIGHT) #jump button
                        @ui.jump_button_ticks = @player.jump(@ticks, @gravity)
                    elsif mouse_over_area?(SCREEN_WIDTH-150, SCREEN_HEIGHT-100, SCREEN_WIDTH, SCREEN_HEIGHT) #flip gravity button
                        flip_gravity
                    end
                end
        end
    end

    #update game each frame (tick)
    def update
        if !@player.dead
            @ticks += 1 #increment ticks
            @difficulty += DIFFICULTY_INCREASE #increase difficulty
            @score += @ship.speed * SCORE_SCALER #increase score based on ship speed
            @ship.move #move ship horizontally

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
                enemy.update(@ticks, @holes, @ship.speed) #update enemy position and state
                @player.dead = true if enemy.collision?(@player) #check enemy collision with player
                true if enemy.off_screen? #remove enemies that are off screen
            end

            @obstacles.delete_if do |obstacle| #update obstacles each frame
                obstacle.update(@gravity, @holes, @ship.speed) #update obstacle position and state
                @player.dead = true if obstacle.collision?(@player) #check obstacle collision with player
                true if obstacle.off_screen? #remove obstacles that are off screen
            end

            @holes.delete_if do |hole| #update holes each frame
                hole.update(@ship.speed)
                true if hole.off_screen? #remove holes that are off screen
            end
        end
    end

    #draw frame to game window each tick
    def draw
        #DRAW BACKGROUND, SHIP AND UI
        @ui.draw_background(ZOrder::BACKGROUND, @ticks) #draw scrolling background
        @ui.draw_buttons(ZOrder::BUTTONS, @ticks, @gravity) #draw buttons for jump and flip
        @ui.draw_score(ZOrder::UI, @score) #draw score
        @ship.draw(ZOrder::SHIP) #draw spaceship

        #DRAW INSTRUCTIONS OVERLAYS OR DEATH SCREEN OVERLAY
        if @show_instruct && !@player.dead #draw instructions on first game
            @show_instruct = @ui.draw_instructions(ZOrder::OVERLAY, @ticks)
        elsif @player.dead #draw death screen overlay with restart instructions
            @ui.draw_overlay(ZOrder::OVERLAY, 2)
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