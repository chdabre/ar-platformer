ArrayList<WorldObject> currentLevel = new ArrayList<WorldObject>(); //<>//
Player player;

int level = 0;

void setup() {
  size(800, 600, P3D);

  currentLevel = buildLevel0();
}

void draw() {
  background(255);
  fill(0);
  text(frameRate, 5, 20);

  for ( WorldObject obj : currentLevel ) {
    obj.render();
  }
  player.render();
  
  player.move(currentLevel);

  if (player.getCollisionObject() != null) {
    if (player.getCollisionObject().getType() == WorldObject.TYPE_DOOR) {
      println("levelup");
      levelUp();
    }else if (player.getCollisionObject().getType() == WorldObject.TYPE_END) {
      println("WIN");
      levelUp();
    }
  }
}

void keyPressed() {
  if ( keyCode == UP) { 
    player.jump();
  }

  if ( keyCode == RIGHT) {
    player.walk(Player.DIRECTION_RIGHT);
  }

  if ( keyCode == LEFT) {
    player.walk(Player.DIRECTION_LEFT);
  }
}

void keyReleased() {
  if ( keyCode == LEFT || keyCode == RIGHT) {
    player.stop();
  }
}

void levelUp() {
  level++;

  if (level == 1) {
    currentLevel = buildLevel1();
  } else {
    println("no more levels");
  }
}

ArrayList<WorldObject> buildLevel0() {
  ArrayList<WorldObject> level = new ArrayList<WorldObject>();

  ArrayList<PVector> leftWallBounds = new ArrayList<PVector>();
  leftWallBounds.add(new PVector(0, height));
  leftWallBounds.add(new PVector(-10, height));
  leftWallBounds.add(new PVector(-10, 0));
  leftWallBounds.add(new PVector(0, 0));
  level.add(new WorldObject(WorldObject.TYPE_WALL, leftWallBounds, true));

  ArrayList<PVector> rightWallBounds = new ArrayList<PVector>();
  rightWallBounds.add(new PVector(width, height));
  rightWallBounds.add(new PVector(width+10, height));
  rightWallBounds.add(new PVector(width+10, 0));
  rightWallBounds.add(new PVector(width, 0));
  level.add(new WorldObject(WorldObject.TYPE_WALL, rightWallBounds, true));

  ArrayList<PVector> floorBounds = new ArrayList<PVector>();
  floorBounds.add(new PVector(0, height));
  floorBounds.add(new PVector(width, height));
  floorBounds.add(new PVector(width, height-20));
  floorBounds.add(new PVector(0, height-20));
  level.add(new WorldObject(WorldObject.TYPE_PLATFORM, floorBounds, true));

  ArrayList<PVector> platformBounds = new ArrayList<PVector>();
  platformBounds.add(new PVector(100, 450));
  platformBounds.add(new PVector(200, 450));
  platformBounds.add(new PVector(200, 470));
  platformBounds.add(new PVector(100, 470));
  level.add(new WorldObject(WorldObject.TYPE_PLATFORM, platformBounds, true));

  ArrayList<PVector> doorBounds = new ArrayList<PVector>();
  doorBounds.add(new PVector(100, 400));
  doorBounds.add(new PVector(120, 400));
  doorBounds.add(new PVector(120, 450));
  doorBounds.add(new PVector(100, 450));
  level.add(new WorldObject(WorldObject.TYPE_DOOR, doorBounds, false));

  player = new Player(new PVector(250, 200));

  return level;
}

ArrayList<WorldObject> buildLevel1() {
  ArrayList<WorldObject> level = new ArrayList<WorldObject>();

  ArrayList<PVector> leftWallBounds = new ArrayList<PVector>();
  leftWallBounds.add(new PVector(0, height));
  leftWallBounds.add(new PVector(-10, height));
  leftWallBounds.add(new PVector(-10, 0));
  leftWallBounds.add(new PVector(0, 0));
  level.add(new WorldObject(WorldObject.TYPE_WALL, leftWallBounds, true));

  ArrayList<PVector> rightWallBounds = new ArrayList<PVector>();
  rightWallBounds.add(new PVector(width, height));
  rightWallBounds.add(new PVector(width+10, height));
  rightWallBounds.add(new PVector(width+10, 0));
  rightWallBounds.add(new PVector(width, 0));
  level.add(new WorldObject(WorldObject.TYPE_WALL, rightWallBounds, true));

  ArrayList<PVector> floorBounds = new ArrayList<PVector>();
  floorBounds.add(new PVector(0, height));
  floorBounds.add(new PVector(width, height));
  floorBounds.add(new PVector(width, height-20));
  floorBounds.add(new PVector(0, height-20));
  level.add(new WorldObject(WorldObject.TYPE_PLATFORM, floorBounds, true));

  ArrayList<PVector> platformBounds = new ArrayList<PVector>();
  platformBounds.add(new PVector(400, 450));
  platformBounds.add(new PVector(500, 450));
  platformBounds.add(new PVector(500, 470));
  platformBounds.add(new PVector(400, 470));
  level.add(new WorldObject(WorldObject.TYPE_PLATFORM, platformBounds, true));

  ArrayList<PVector> endBounds = new ArrayList<PVector>();
  endBounds.add(new PVector(450, 400));
  endBounds.add(new PVector(470, 400));
  endBounds.add(new PVector(470, 450));
  endBounds.add(new PVector(450, 450));
  level.add(new WorldObject(WorldObject.TYPE_END, endBounds, false));

  player = new Player(new PVector(250, 200));

  return level;
}