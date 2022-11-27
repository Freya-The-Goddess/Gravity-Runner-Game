#Gravity Runner game by Freya-The-Goddess
#Custom code project for Intro To Programming (COS10009)

#import external libraries
require 'rubygems'
require 'gosu'

#Gosu z layer order
module ZOrder
  BACKGROUND, SHIP, ENTITIES, PLAYER, UI, OVERLAY = *0..5
end

#Screen size constants
SCREEN_WIDTH, SCREEN_HEIGHT = 800, 450
BACKGROUND_COLOR = Gosu::Color.argb(0xFF_00000A)
BACKGROUND_SPEED = 1.0
SHIP_START_SPEED = 2.8

#Spaceship size constants
FLOOR_Y, CEILING_Y = 300, 50 #y values for floor and ceiling collision box (unit: pixels)
FLOOR_THICKNESS = 15 #pixels, how much wider than collision box to draw

#Gosu drawing blend color (white full opacity ie no blending)
BLEND = Gosu::Color.argb(0xFF_FFFFFF)

#Player global constants
PLAYER_SIZE = 50 #size of player and sprite tiles (unit: pixels)
PLAYER_WIDTH = 18
JUMP_CONSTANT = -11.0 #initial velocity of jump (units: pixels/frame)
TICKS_PER_RUNNING_FRAME = 5

ENEMY_SIZE = 50 #size of robot and sprite tiles (unit: pixels)
ENEMY_WIDTH = 18
CRATE_SIZE = 25

#Gravity gloabal constants
GRAVITY_CONSTANT = 0.65 #acceleration due to gravity (units: pixels/frame/frame)
module Gravity
  UP = -1
  DOWN = 1
end

class Player
  attr_accessor :x_coord, :y_coord, :x_vel, :y_vel, :angle, :height, :width, :tiles, :frame, :standing, :flipping, :dead
  def initialize(y_coord, tile_size, width)
    @x_coord = 120
    @y_coord = y_coord
    @x_vel, @y_vel, @angle = 0, 0, 0
    @height = tile_size
    @width = width
    @tiles = Gosu::Image.load_tiles("media/player.png", tile_size, tile_size)
    @frame = 0
    @dead = false
  end
end

class Enemy
  attr_accessor :x_coord, :y_coord, :x_vel, :y_vel, :angle, :height, :width, :tiles, :frame, :standing, :flipping, :gravity, :dead
  def initialize(x_coord, y_coord, x_vel, tile_size, width, gravity)
    @x_coord = x_coord
    @x_vel = x_vel
    @y_coord = y_coord
    @y_vel, @angle = 0, 0
    @height = tile_size
    @width = width
    @gravity = gravity
    @tiles = Gosu::Image.load_tiles("media/robot.png", tile_size, tile_size)
    @frame = 0
    @dead = false
  end
end

class Obstacle
  attr_accessor :x_coord, :y_coord, :x_vel, :y_vel, :height, :width, :img, :flipping
  def initialize(x_coord, y_coord, tile_size, tile)
    @x_coord = x_coord
    @y_coord = y_coord
    @x_vel, @y_vel = 0, 0
    @height, @width = tile_size, tile_size
    @flipping = false
    @img = Gosu::Image.load_tiles("media/crates.png", tile_size, tile_size)[tile]
  end
end

class Hole
  attr_accessor :x_coord, :y_coord, :x_vel, :direction, :width, :height, :tiles
  def initialize(x_coord, y_coord, direction)
    @x_coord, @y_coord = x_coord, y_coord
    @x_vel = 0
    @direction = direction
    @width, @height = 150, 20
    @tiles = Gosu::Image.load_tiles("media/hole.png", 170, 20)
  end
end

#returns true mouse is within bounding box
def mouse_over_area?(min_x, min_y, max_x, max_y)
  if mouse_x >= min_x && mouse_x <= max_x && mouse_y >= min_y && mouse_y <= max_y
      return true
  else
    return false
  end
end

#player jump input
def player_jump
  if @player.standing && !@player.dead
    @jump_button_ticks = @ticks + 15
    @player.y_vel = JUMP_CONSTANT * @gravity #multiply by 1 or -1 depending on if player is jumping off FLOOR_Y or CEILING_Y
  end
end

#player gravity flip input
def player_grav_flip
  if !@player.dead
    @grav_button_ticks = @ticks + 15
    case @gravity
      when Gravity::DOWN
        @gravity = Gravity::UP
      when Gravity::UP
        @gravity = Gravity::DOWN
    end
  end
end

#Calculate and update entity's vertical velocity and coordinate
def do_entity_gravity(entity, gravity)
  entity.y_vel += (gravity * GRAVITY_CONSTANT)
  entity.y_coord += entity.y_vel
end

#Rotate entity if gravity is flipping
def do_entity_rotate(entity, gravity)
  #rotate player/entity when gravity is flipped
  if gravity == Gravity::UP && entity.angle < 180
    if entity.standing == :ceiling #if on ceiling set angle
      entity.flipping = false
      entity.angle = 180
    else #if in midair adjust angle each frame
      entity.flipping = true
      entity.angle += 10
    end
  elsif gravity == Gravity::DOWN && entity.angle > 0
    if entity.standing == :floor #if on floor set angle
      entity.flipping = false
      entity.angle = 0
    else #if in midair adjust angle each frame
      entity.flipping = true
      entity.angle -= 10
    end
  end
end

#cycle through entity's running frames
def do_entity_running(entity)
  if entity.standing #running frames
    entity.frame = 0 if (@ticks/TICKS_PER_RUNNING_FRAME)%4 == 1
    entity.frame = 1 if (@ticks/TICKS_PER_RUNNING_FRAME)%2 == 0
    entity.frame = 2 if (@ticks/TICKS_PER_RUNNING_FRAME)%4 == 3
  end
end

#move entity horizontally based on its x velocity and the ship speed
def do_entity_horizontal(entity)
  entity.x_coord -= entity.x_vel + @ship_speed
end

#check if entity is on floor (or ceiling) and update velocity if so
def on_floor?(entity, gravity)
  @holes.each do |hole|
    return false if collision?(entity, hole)
  end
  return false if entity.y_coord > FLOOR_Y+20
  return false if entity.y_coord < CEILING_Y-20
  if entity.y_coord >= FLOOR_Y - entity.height/2
    entity.y_coord = FLOOR_Y - entity.height/2 #keep inside bounding box
    entity.y_vel = 0 #reset vertical velocity
    entity.flipping = false
    return :floor if gravity == Gravity::DOWN
  end
  if entity.y_coord <= CEILING_Y + entity.height/2
    entity.y_coord = CEILING_Y + entity.height/2 #keep inside bounding box
    entity.y_vel = 0 #reset vertical velocity
    entity.flipping = false
    return :ceiling if gravity == Gravity::UP
  end
  return false #if in midair
end

#check if entity hitbox collides with (overlaps) another entity's hitbox
def collision?(entity1, entity2)
  if entity1.x_coord - entity1.width/2 < entity2.x_coord + entity2.width/2 && 
  entity1.x_coord + entity1.width/2 > entity2.x_coord - entity2.width/2 && 
  entity1.y_coord - entity1.height/2 < entity2.y_coord + entity2.height/2 && 
  entity1.y_coord + entity1.height/2 > entity2.y_coord - entity2.height/2
    return true #collision detected
  end
  return false #no collision
end

#check if entity has moved past the bounds of the window 
def off_screen?(entity)
  if entity.x_coord + entity.width/2 < 0
    return :left #entity is off screen
  elsif entity.y_coord + entity.height/2 < 0
    return :top #entity is off screen
  elsif entity.y_coord - entity.height/2 > SCREEN_HEIGHT
    return :bottom #entity is off screen
  else
    return false #entity is within window
  end
end

#draw background color and two layers of scrolling stars 
def draw_background(ticks)
  #background color
  Gosu.draw_rect(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT, BACKGROUND_COLOR, ZOrder::BACKGROUND, mode=:default)

  shift_stars = (ticks % (SCREEN_WIDTH/BACKGROUND_SPEED))*BACKGROUND_SPEED
  shift_stars2 = (ticks % (SCREEN_WIDTH/(BACKGROUND_SPEED/2)))*BACKGROUND_SPEED/2 
  #background layer 2
  @space.draw_as_quad(SCREEN_WIDTH-shift_stars2, SCREEN_HEIGHT, BLEND, 0-shift_stars2, SCREEN_HEIGHT, BLEND, 0-shift_stars2, 0, BLEND, SCREEN_WIDTH-shift_stars2, 0, BLEND, ZOrder::BACKGROUND, mode=:default)
  @space.draw_as_quad(SCREEN_WIDTH-shift_stars2+SCREEN_WIDTH, SCREEN_HEIGHT, BLEND, 0-shift_stars2+SCREEN_WIDTH, SCREEN_HEIGHT, BLEND, 0-shift_stars2+SCREEN_WIDTH, 0, BLEND, SCREEN_WIDTH-shift_stars2+SCREEN_WIDTH, 0, BLEND, ZOrder::BACKGROUND, mode=:default)
  #background layer 1
  @space.draw_as_quad(0-shift_stars, 0, BLEND, SCREEN_WIDTH-shift_stars, 0, BLEND, SCREEN_WIDTH-shift_stars, SCREEN_HEIGHT, BLEND, 0-shift_stars, SCREEN_HEIGHT, BLEND, ZOrder::BACKGROUND, mode=:default)
  @space.draw_as_quad(0-shift_stars+SCREEN_WIDTH, 0, BLEND, SCREEN_WIDTH-shift_stars+SCREEN_WIDTH, 0, BLEND, SCREEN_WIDTH-shift_stars+SCREEN_WIDTH, SCREEN_HEIGHT, BLEND, 0-shift_stars+SCREEN_WIDTH, SCREEN_HEIGHT, BLEND, ZOrder::BACKGROUND, mode=:default)
end

def draw_buttons()
  jump_button = @buttons[0]
  jump_button = @buttons[1] if @jump_button_ticks > @ticks
  if @gravity == Gravity::DOWN
    grav_button = @buttons[2]
    grav_button = @buttons[3] if @grav_button_ticks > @ticks
  elsif @gravity == Gravity::UP
    grav_button = @buttons[4]
    grav_button = @buttons[5] if @grav_button_ticks > @ticks
  end
  jump_button.draw_rot(0, SCREEN_HEIGHT, ZOrder::UI, 0, 0, 1, 1, 1)
  grav_button.draw_rot(SCREEN_WIDTH, SCREEN_HEIGHT, ZOrder::UI, 0, 1, 1, 1, 1)
end

#draw scrolling spaceship
def draw_ship(shift_ship, ship_speed)
  #shift_ship = (ticks % (SCREEN_WIDTH/@ship_speed))*@ship_speed
  # the above produces slightly inprecise values that accumulate over time so that the ship moves slightly faster than "stationary" objects
  # the method below needs to use a variable

  if !@player.dead
    shift_ship += ship_speed
    if shift_ship >= SCREEN_WIDTH
      shift_ship = 0
    end
  end

  @ship.draw_as_quad(0-shift_ship, CEILING_Y-FLOOR_THICKNESS, BLEND, SCREEN_WIDTH-shift_ship, CEILING_Y-FLOOR_THICKNESS, BLEND, SCREEN_WIDTH-shift_ship, FLOOR_Y+FLOOR_THICKNESS, BLEND, 0-shift_ship, FLOOR_Y+FLOOR_THICKNESS, BLEND, ZOrder::SHIP, mode=:default)
  @ship.draw_as_quad(0-shift_ship+SCREEN_WIDTH, CEILING_Y-FLOOR_THICKNESS, BLEND, SCREEN_WIDTH-shift_ship+SCREEN_WIDTH, CEILING_Y-FLOOR_THICKNESS, BLEND, SCREEN_WIDTH-shift_ship+SCREEN_WIDTH, FLOOR_Y+FLOOR_THICKNESS, BLEND, 0-shift_ship+SCREEN_WIDTH, FLOOR_Y+FLOOR_THICKNESS, BLEND, ZOrder::SHIP, mode=:default)

  return shift_ship
end

#draw entity (e.g. player, enemy) according to its attributes and gravity direction
def draw_entity(entity, gravity, z_layer)
  if entity.dead
    frame = 4
    x_flip = 1
  elsif entity.standing == :floor #running on floor
    frame = entity.frame
    x_flip = 1
  elsif entity.standing == :ceiling #running on ceiling (flip image horizontally)
    frame = entity.frame
    x_flip = -1
  elsif !entity.standing && !entity.flipping #jumping
    if gravity == Gravity::DOWN
      frame = 1
      x_flip = 1
    elsif gravity == Gravity::UP
      frame = 1
      x_flip = -1
    end
  elsif entity.flipping #gravity flipping
    frame = 3
    x_flip = 1
  end

  entity.tiles[frame].draw_rot(entity.x_coord, entity.y_coord, z_layer, entity.angle, 0.5, 0.5, x_flip, 1)
end

#draw obstacle (crate) according to its attributes and gravity direction
def draw_obstacle(obstacle, gravity, z_layer)
  obstacle.img.draw_rot(obstacle.x_coord, obstacle.y_coord, z_layer, 0, 0.5, 0.5, 1, 1)
end

#draw ship hole according to its x coordinate and direction
def draw_hole(hole)
  if hole.direction == :ceiling
    tile = 1
  elsif hole.direction == :floor
    tile = 0
  end
  hole.tiles[tile].draw_rot(hole.x_coord, hole.y_coord, ZOrder::SHIP, 0, 0.5, 0.5, 1, 1)
end

#create new enemy with randomized traits
def summon_enemy
  speed = rand(0.5..@difficulty)
  gravity = [Gravity::UP, Gravity::DOWN][rand(0..1)]
  if gravity == Gravity::UP
    y_coord = CEILING_Y+ENEMY_SIZE/2
  else
    y_coord = FLOOR_Y-ENEMY_SIZE/2
  end
  @enemies << Enemy.new(SCREEN_WIDTH+ENEMY_SIZE, y_coord, speed, ENEMY_SIZE, ENEMY_WIDTH, gravity)
end

#create new obstacle with randomized type
def summon_obstacle
  type = rand(0..3)
  if @gravity == Gravity::UP
    y_coord = CEILING_Y+CRATE_SIZE/2
  else
    y_coord = FLOOR_Y-CRATE_SIZE/2
  end
  @obstacles << Obstacle.new(SCREEN_WIDTH+CRATE_SIZE, y_coord, CRATE_SIZE, type)
end

class GravityRunner < (Gosu::Window)
  def initialize(restart = false)
    @restart = restart
    if !@restart
      super(SCREEN_WIDTH, SCREEN_HEIGHT)
      self.caption = "Gravity Runner"
      @font = Gosu::Font.new(20)

      @overlay = Gosu::Image.load_tiles("media/overlay.png", SCREEN_WIDTH, SCREEN_HEIGHT)
      @space = Gosu::Image.new("media/space.png")
      @buttons = Gosu::Image.load_tiles("media/buttons.png", 150, 150)

      @ship = Gosu::Image.new("media/ship.png")
    end

    @ticks = 0 #keeps track of total gameticks
    @score = 0 #player's score
    @difficulty = 1.0 #starts at 1 and gradually increases

    @jump_button_ticks = 0
    @grav_button_ticks = 0

    #first spawn events (after which randomisers take over)
    @next_obstacle = 20
    @next_hole = 200
    @next_spawn = 600

    @ship_speed = SHIP_START_SPEED #starting speed
    @shift_ship = 0 #stores pixels to shift ship image for current frame

    @gravity = Gravity::DOWN #default gravity down
    @player = Player.new(FLOOR_Y-PLAYER_SIZE/2, PLAYER_SIZE, PLAYER_WIDTH) #create new Player instance with y position at FLOOR_Y

    @enemies = []
    @obstacles = []
    @holes = []

  end

  def needs_cursor?; true; end

  def update
    if !@player.dead
      @ticks += 1

      @ship_speed = SHIP_START_SPEED+(@ticks*0.00005)
      @score += @ship_speed*0.02
      @difficulty = 1.0 + @ticks*0.00001

      #spawn enemies and obstacles if the spawn event time (ticks) is reached
      if @next_spawn <= @ticks
        summon_enemy #spawn enemy with randomised attributes 
        summon_enemy if (rand(0..50)/@difficulty).to_i == 0 #chance for 2nd enemy to spawn
        summon_enemy if (rand(0..100)/@difficulty).to_i == 0 #chance for 3rd enemy to spawn

        @next_spawn = @ticks + (200/@difficulty) + rand(0..100) #randomised amount of ticks before next spawn event
      end

      #spawn enemies and obstacles if the spawn event time (ticks) is reached
      if @next_obstacle <= @ticks
        summon_obstacle
        @next_obstacle = @ticks + 200 + rand(0..300) #randomised amount of ticks before next spawn event
      end

      #create hole if the event time is reached
      if @next_hole <= @ticks
        direction = [:floor,:ceiling][rand(0..1)]
        if direction == :ceiling
          y_coord = CEILING_Y-10
        elsif direction == :floor
          y_coord = FLOOR_Y+10
        end
        @holes << Hole.new(SCREEN_WIDTH+170, y_coord, direction)
        @next_hole = @ticks + (500/@difficulty) + rand(0..1000) #randomised amount of ticks before next spawn event
      end
      

      #Player updates
      do_entity_gravity(@player, @gravity) #calculate player's vertical velocity and coordinate
      @player.standing = on_floor?(@player, @gravity)
      do_entity_rotate(@player, @gravity) #calculate player's rotation while in midair
      do_entity_running(@player) #update player's current running animation frame

      @player.dead = true if @player.y_coord-(PLAYER_SIZE/2) < CEILING_Y - 50
      @player.dead = true if @player.y_coord+(PLAYER_SIZE/2) > FLOOR_Y + 50

      #Enemy updates
      @enemies.each do |enemy|
        do_entity_gravity(enemy, enemy.gravity) #calculate enemy's vertical velocity and coordinate
        enemy.standing = on_floor?(enemy, enemy.gravity)
        do_entity_rotate(enemy, enemy.gravity) #calculate enemy's rotation while in midair
        do_entity_running(enemy) if enemy.x_vel != 0 #update enemy's current running animation frame
        do_entity_horizontal(enemy)
      end

      #Obstacle updates
      @obstacles.each do |obstacle|
        do_entity_gravity(obstacle, @gravity)
        on_floor?(obstacle, @gravity)
        do_entity_horizontal(obstacle)
      end

      #Void hole updates
      @holes.each do |hole|
        do_entity_horizontal(hole)
      end

      @enemies.each do |enemy| #remove enemies that are off screen
        if off_screen?(enemy)
          @enemies.delete_at(@enemies.index(enemy))
        end
      end
      @obstacles.each do |obstacle| #remove obstacles that are off screen
        if off_screen?(obstacle)
          @obstacles.delete_at(@obstacles.index(obstacle))
        end
      end
      @holes.each do |hole| #remove holes that are off screen
        if off_screen?(hole)
          @holes.delete_at(@holes.index(hole))
        end
      end

      #Collision updates
      @enemies.each do |enemy|
        @player.dead = true if collision?(@player, enemy) #for each enemy check if it collides with the player
      end
      @obstacles.each do |obstacle|
        @player.dead = true if collision?(@player, obstacle) #for each enemy check if it collides with the player
      end
    else #player death
    
    end
  end

  def draw
    #draw scrolling background and spaceship
    draw_background(@ticks)
    @shift_ship = draw_ship(@shift_ship, @ship_speed)

    #draw player
    draw_entity(@player, @gravity, ZOrder::PLAYER)

    @enemies.each do |enemy|
      draw_entity(enemy, enemy.gravity, ZOrder::ENTITIES)
    end

    @obstacles.each do |obstacle|
      draw_obstacle(obstacle, @gravity, ZOrder::ENTITIES)
    end

    @holes.each do |hole|
      draw_hole(hole)
    end

    #draw instructions overlays at approptiate times, only if it's the first instance of the game running
    if !@restart && !@player.dead
      if @ticks > 80 && @ticks < 300
        @overlay[0].draw_as_quad(0, 0, BLEND, SCREEN_WIDTH, 0, BLEND, SCREEN_WIDTH, SCREEN_HEIGHT, BLEND, 0, SCREEN_HEIGHT, BLEND, ZOrder::OVERLAY, mode=:default)
      elsif @ticks > 350 && @ticks < 600
        @overlay[1].draw_as_quad(0, 0, BLEND, SCREEN_WIDTH, 0, BLEND, SCREEN_WIDTH, SCREEN_HEIGHT, BLEND, 0, SCREEN_HEIGHT, BLEND, ZOrder::OVERLAY, mode=:default)
      end
    end

    #draw death overlay with restart instructions
    if @player.dead
      @overlay[2].draw_as_quad(0, 0, BLEND, SCREEN_WIDTH, 0, BLEND, SCREEN_WIDTH, SCREEN_HEIGHT, BLEND, 0, SCREEN_HEIGHT, BLEND, ZOrder::OVERLAY, mode=:default)
    end

    #draw gui buttons for jump and flip
    draw_buttons()

    #draw score
    @font.draw_text("Score: #{@score.to_i.to_s}", 10, 5, ZOrder::UI, 1.0, 1.0, Gosu::Color::WHITE)
  end

  def button_down(id)
    case id
      when Gosu::KB_SPACE #Jump
        player_jump
      when Gosu::KB_RETURN #Flip Gravity
        player_grav_flip
      when Gosu::KB_R #restart
        if @player.dead
          initialize(true)
        end
      when Gosu::MsLeft
        if @player.dead #click anywhere to restart
          initialize(true)
        else
          if mouse_over_area?(0, SCREEN_HEIGHT-100, 150, SCREEN_HEIGHT) #Jump button
            player_jump
          elsif mouse_over_area?(SCREEN_WIDTH-150, SCREEN_HEIGHT-100, SCREEN_WIDTH, SCREEN_HEIGHT) #Grav Flip button
            player_grav_flip
          end
        end
    end
  end

end

GravityRunner.new.show if __FILE__ == $0