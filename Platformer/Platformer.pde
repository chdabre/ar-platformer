import mqtt.*;

ArrayList<WorldObject> currentLevel = new ArrayList<WorldObject>();
Player player;

int level = 0;

int STATE_INGAME = 0;
int STATE_EDIT   = 1;
int STATE_STARTSCREEN = 2;
int STATE_ENDSCREEN   = 3;
int STATE_PASSWORD = 4;

String[] stateNames = {
  "INGAME",
  "EDIT",
  "STARTSCREEN",
  "ENDSCREEN",
  "PASSWORD"
};

int state = STATE_PASSWORD;
String password = "mariomario";
String passwordEntry = "";
ArrayList<PVector> quadBounds;

MarkerDetection markerDetection;
ArrayList<WorldObject> markerObjects;

MQTTClient mqttClient;
String commandTopic = "/argame/command";
String stateTopic = "/argame/state";

Settings settings;

PImage bgImage = null;

void setup() {
  size(1280, 720, P3D);
  //fullScreen(P2D);
  frameRate(60);

  settings = new Settings("settings.json");

  markerDetection = new MarkerDetection(this, MarkerDetection.GAIN_AUTO, 50, true);
  markerDetection.setPerspective(settings.getPerspectiveSettings());

  markerObjects = new ArrayList<WorldObject>();

  mqttClient = new MQTTClient(this);
  mqttClient.connect("mqtt://192.168.100.40:1883", "processing-argame");
  mqttClient.subscribe(commandTopic);
  mqttClient.publish(stateTopic, stateNames[state]);

  bgImage = loadImage("bg.png");

  setupGame();
}

void setupGame () {
  level = 0;
  currentLevel = buildLevel0();
  quadBounds = null;
}

void draw() {
  background(255);
  fill(0);
  noStroke();

  if (state == STATE_INGAME ) {
    // Draw bg image
    image(bgImage, 0, 0, width, height);
  }

  if ( state == STATE_EDIT ) {
    PImage currentFrame = markerDetection.getCorrectedFrame();
    //image(currentFrame, 0, 0, currentFrame.width/4, currentFrame.height/4);

    if (markerObjects.size() > 0){
      for(WorldObject markerObject : markerObjects ){
        currentLevel.remove(markerObject);
      }
    }
    markerObjects = new ArrayList<WorldObject>();

    ArrayList<ArrayList> markers = markerDetection.detectMarkers(currentFrame);
    if(markers.size() > 0){
      for(ArrayList<PVector> markerBounds : markers){
        WorldObject markerObject = new WorldObject(WorldObject.TYPE_MARKER, markerBounds, true);
        markerObjects.add(markerObject);
        currentLevel.add(markerObject);
      }
    }
  }

  for ( WorldObject obj : currentLevel ) {
    if ( state == STATE_EDIT ) {
      obj.render(WorldObject.RENDER_MODE_EDIT);
    } else {
      obj.render(WorldObject.RENDER_MODE_INGAME);
    }
  }

  if ( state == STATE_INGAME ) {
    player.render();

    player.move(currentLevel);

    if (player.getCollisionObject() != null) {
      if (player.getCollisionObject().getType() == WorldObject.TYPE_DOOR) {
        println("levelup");
        levelUp();
      } else if (player.getCollisionObject().getType() == WorldObject.TYPE_END) {
        println("WIN");
        levelUp();
      }
    }
  } else if ( state == STATE_EDIT ) {
    player.render();
  } else if ( state == STATE_STARTSCREEN ) {
    PImage startScreen = loadImage("start_screen.png");
    background(255);
    image(startScreen, 0, 0, width, height);
  } else if ( state == STATE_ENDSCREEN ) {
    background(255);
    PImage endScreen = loadImage("end_screen.png");
    image(endScreen, 0, 0, width, height);
  } else if ( state == STATE_PASSWORD) {
    background(255);
    PImage passwordScreen = loadImage("password_screen.png");
    image(passwordScreen, 0, 0, width, height);

    color(0);
    textSize(40);
    text(passwordEntry, 300, 425);
  } else {
    println("ERR: Invalid game state");
  }
  
  color(255);
  // text(frameRate, 5, 20);
  // text(mouseX, 5, 40);
  // text(mouseY, 5, 60);
}

void keyPressed() {
  if ( state == STATE_INGAME ) {
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

    if (state == STATE_PASSWORD) {
    passwordEntry += key;

    if (passwordEntry.length() == password.length()){
      if (passwordEntry.toLowerCase().startsWith(password)) {
        state = STATE_STARTSCREEN;
        mqttClient.publish(stateTopic, stateNames[state]);
      }
      passwordEntry = "";
    }
  }
}

void keyReleased() {
  if ( key == 'r' ) {
    toggleEditMode();
  } else if ( keyCode == LEFT || keyCode == RIGHT) {
    player.stop();
  } else if (key == 's' && state == STATE_STARTSCREEN ) {
    state = STATE_INGAME;
    mqttClient.publish(stateTopic, stateNames[state]);
  }
}

void toggleEditMode() {
  if ( state == STATE_INGAME ) {
    state = STATE_EDIT;
  } else if ( state == STATE_EDIT) {
    state = STATE_INGAME;
  }
  mqttClient.publish(stateTopic, stateNames[state]);
}

void levelUp() {
  level++;

  if (level == 1) {
    currentLevel = buildLevel1();
  } else {
    println("no more levels");
    state = STATE_ENDSCREEN;
    mqttClient.publish(stateTopic, stateNames[state]);
  }
}

void messageReceived(String topic, byte[] payload) {
  println("new message: " + topic + " - " + new String(payload));

  if (new String(payload).contains("RESET")) {
    setupGame();
    state = STATE_PASSWORD;
  }
  else if (new String(payload).contains("ACTIVATE")){
    state = STATE_ENDSCREEN;
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
  floorBounds.add(new PVector(width, height-120));
  floorBounds.add(new PVector(0, height-120));
  level.add(new WorldObject(WorldObject.TYPE_PLATFORM, floorBounds, true));

  ArrayList<PVector> platformBounds = new ArrayList<PVector>();
  platformBounds.add(new PVector(400, 450));
  platformBounds.add(new PVector(700, 450));
  platformBounds.add(new PVector(200, 490));
  platformBounds.add(new PVector(100, 490));
  level.add(new WorldObject(WorldObject.TYPE_PLATFORM, platformBounds, true));

  ArrayList<PVector> platform2Bounds = new ArrayList<PVector>();
  platform2Bounds.add(new PVector(400, 750));
  platform2Bounds.add(new PVector(500, 750));
  platform2Bounds.add(new PVector(500, 770));
  platform2Bounds.add(new PVector(400, 770));
  level.add(new WorldObject(WorldObject.TYPE_PLATFORM, platform2Bounds, true));

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

ArrayList<PVector> randomQuad() {
  ArrayList<PVector> quad = new ArrayList<PVector>();

  for (int i = 0; i < 4; i++) {
    quad.add(new PVector(width/4 + random(width/2), height/4 + random(height/2)));
  }

  return quad;
}