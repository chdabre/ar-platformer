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

int htpPos = 0;
PImage[] htp = new PImage[3];

PImage endScreen;
PImage passwordScreen;
PImage bgImage;
PImage editImage;

int keepAwakeTime = millis();

void setup() {
  size(1280, 720, P3D);
  //fullScreen(P2D);
  frameRate(60);

  settings = new Settings("settings.json");

  markerDetection = new MarkerDetection(this, MarkerDetection.GAIN_AUTO, 50, true);
  markerDetection.setPerspective(settings.getPerspectiveSettings());

  markerObjects = new ArrayList<WorldObject>();

  mqttClient = new MQTTClient(this);
  mqttReconnect();

  htp[0] = loadImage("htp_01.png");
  htp[1] = loadImage("htp_02.png");
  htp[2] = loadImage("htp_03.png");

  endScreen = loadImage("end_screen.png");
  passwordScreen = loadImage("password_screen.png");
  bgImage = loadImage("bg.png");
  editImage = loadImage("edit.png");

  println("Ready: " + width + "x" + height);
  setupGame();
}

void connectionLost() {
  println("connection lost");
  //exec("/bin/sh", "/home/arbasel/startup.sh");
  mqttReconnect();
}

void setupGame () {
  level = 0;
  htpPos = 0;
  currentLevel = buildLevel0();
  quadBounds = null;
}

void mqttReconnect() {
  mqttClient.connect("mqtt://192.168.100.40:1883", "processing-argame");
  mqttClient.subscribe(commandTopic);
  mqttClient.publish(stateTopic, stateNames[state]);
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

    image(editImage, 0, 0, width, height);

    if (markerObjects.size() > 0) {
      for (WorldObject markerObject : markerObjects ) {
        currentLevel.remove(markerObject);
      }
    }
    markerObjects = new ArrayList<WorldObject>();

    ArrayList<ArrayList> markers = markerDetection.detectMarkers(currentFrame);
    if (markers.size() > 0) {
      for (ArrayList<PVector> markerBounds : markers) {
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
    background(255);
    if (htpPos < 4) {
      image(htp[htpPos], 0, 0, width, height);
    }
  } else if ( state == STATE_ENDSCREEN ) {
    background(255);
    image(endScreen, 0, 0, width, height);
  } else if ( state == STATE_PASSWORD) {
    background(255);
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

  //if (!mqttClient.client.isConnected()) {
  //  println("LOST CONNECTION... RECONNECT ATTEMPT");
  //  mqttReconnect();
  //}
}

void keyPressed() {
  // Prevent ESC key from closing the sketch
  if (keyCode == 27) {
    key = 0;
  }

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

  if (state == STATE_PASSWORD && "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789".indexOf((""+key).toUpperCase()) > -1) {
    passwordEntry += key;

    if (passwordEntry.length() == password.length()) {
      if (passwordEntry.toLowerCase().startsWith(password)) {
        state = STATE_STARTSCREEN;
        mqttClient.publish(stateTopic, stateNames[state]);
      }
      passwordEntry = "";
    }
  }

  if (state == STATE_PASSWORD && key == BACKSPACE && passwordEntry.length()>0) {
    passwordEntry = passwordEntry.substring( 0, passwordEntry.length()-1 );
  }
}

void keyReleased() {
  String keyIn = str(key).toLowerCase();
  println(keyIn);
  if ( keyIn.equals("r") ) {
    toggleEditMode();
  } else if ( keyCode == LEFT || keyCode == RIGHT) {
    player.stop();
  } else if (keyIn.equals("s") && (state == STATE_INGAME || state == STATE_EDIT) ) {
    htpPos = 0;
    state = STATE_STARTSCREEN;
    mqttClient.publish(stateTopic, stateNames[state]);
  } else if (keyIn.equals("s") && state == STATE_STARTSCREEN ) {
    if (htpPos < 2) {
      htpPos++;
    } else {
      state = STATE_INGAME;
      mqttClient.publish(stateTopic, stateNames[state]);
    }
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
  } else if (level == 2) {
    currentLevel = buildLevel2();
  }else {
    println("no more levels");
    state = STATE_ENDSCREEN;
    mqttClient.publish(stateTopic, stateNames[state]);
  }
}

void messageReceived(String topic, byte[] payload) {
  println("new message: " + topic + " - " + new String(payload));

  if (new String(payload).contains("RESET")) {
    setupGame();
    passwordEntry = "";
    state = STATE_PASSWORD;
  } else if (new String(payload).contains("START")) {
    setupGame();
    state = STATE_STARTSCREEN;
  } else if (new String(payload).contains("ACTIVATE")) {
    state = STATE_ENDSCREEN;
  }

  mqttClient.publish(stateTopic, stateNames[state]);
}

ArrayList<WorldObject> buildLevel0() {
  print("LEVEL 0");
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
  platformBounds.add(new PVector(600, 450));
  platformBounds.add(new PVector(800, 450));
  platformBounds.add(new PVector(800, 490));
  platformBounds.add(new PVector(600, 490));
  level.add(new WorldObject(WorldObject.TYPE_PLATFORM, platformBounds, true));

  ArrayList<PVector> doorBounds = new ArrayList<PVector>();
  doorBounds.add(new PVector(760, 380));
  doorBounds.add(new PVector(800, 380));
  doorBounds.add(new PVector(800, 450));
  doorBounds.add(new PVector(760, 450));
  level.add(new WorldObject(WorldObject.TYPE_DOOR, doorBounds, false));

  player = new Player(new PVector(250, 200));

  return level;
}

ArrayList<WorldObject> buildLevel1() {
  print("LEVEL 1");
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
  floorBounds.add(new PVector(width, height-80));
  floorBounds.add(new PVector(0, height-80));
  level.add(new WorldObject(WorldObject.TYPE_PLATFORM, floorBounds, true));

  ArrayList<PVector> platformBounds = new ArrayList<PVector>();
  platformBounds.add(new PVector(700, 270));
  platformBounds.add(new PVector(800, 270));
  platformBounds.add(new PVector(800, 290));
  platformBounds.add(new PVector(700, 290));
  level.add(new WorldObject(WorldObject.TYPE_PLATFORM, platformBounds, true));

  ArrayList<PVector> door = new ArrayList<PVector>();
  door.add(new PVector(750, 200));
  door.add(new PVector(790, 200));
  door.add(new PVector(790, 270));
  door.add(new PVector(750, 270));
  level.add(new WorldObject(WorldObject.TYPE_DOOR, door, false));

  player = new Player(new PVector(250, 200));

  return level;
}


ArrayList<WorldObject> buildLevel2() {
  print("LEVEL 2");
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
  floorBounds.add(new PVector(width, height-80));
  floorBounds.add(new PVector(0, height-80));
  level.add(new WorldObject(WorldObject.TYPE_PLATFORM, floorBounds, true));

  ArrayList<PVector> platformBounds = new ArrayList<PVector>();
  platformBounds.add(new PVector(700, 270));
  platformBounds.add(new PVector(800, 270));
  platformBounds.add(new PVector(800, 290));
  platformBounds.add(new PVector(700, 290));
  level.add(new WorldObject(WorldObject.TYPE_PLATFORM, platformBounds, true));
  
  ArrayList<PVector> endBounds = new ArrayList<PVector>();
  endBounds.add(new PVector(250, 100));
  endBounds.add(new PVector(290, 100));
  endBounds.add(new PVector(290, 170));
  endBounds.add(new PVector(250, 170));
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
