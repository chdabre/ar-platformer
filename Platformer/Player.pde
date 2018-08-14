class Player {

  public static final boolean DIRECTION_RIGHT = true;
  public static final boolean DIRECTION_LEFT = false;

  public static final int STATE_DEFAULT = 0;
  public static final int STATE_LEFT = 1;
  public static final int STATE_WALK_RIGHT = 2; 
  public static final int STATE_WALK_LEFT = 3; 
  public static final int STATE_JUMP_LEFT = 4; 
  public static final int STATE_JUMP_RIGHT = 5; 

  private PImage[] stateImages = {
    loadImage("default.png"),
    loadImage("left.png"),
    loadImage("walk_right.png"),
    loadImage("walk_left.png"),
    loadImage("jump_left.png"),
    loadImage("jump_right.png")
  };

  private int playerWidth = 39;
  private int playerHeight = 48;

  private PVector position;
  private float xSpeed = 0;
  private float ySpeed = 0;
  private float maxXSpeed = 2;
  private float maxYSpeed = 10;
  private float xAccel = 0;
  private float yAccel = .4;

  private int state = 0;
  private WorldObject collisionObject = null;

  public boolean debug = false;

  public Player(PVector position) {
    this.position = position;
  }

  public void render() {
    pushMatrix();

    fill(0, 255, 0);
    strokeWeight(2);

    image(stateImages[state], this.position.x, this.position.y - this.playerHeight, this.playerWidth, this.playerHeight);
    fill(0);
    if (debug) text(this.position.x+","+this.position.y, this.position.x + playerWidth + 5, this.position.y);
    popMatrix();
  }

  public void walk(boolean direction) {
    if (direction == DIRECTION_RIGHT) {
      this.state = STATE_WALK_RIGHT;
      this.xAccel = .2;
    } else { // Left, duh
      this.state = STATE_WALK_LEFT;
      this.xAccel = -.2;
    }
  }

  public void stop() {
    if (this.xAccel > 0) {
      this.state = STATE_DEFAULT;
    } else {
      this.state = STATE_LEFT;
    }

    this.xAccel = 0;
    this.xSpeed = 0;
  }

  public void jump() {
    if (this.xAccel > 0) {
      this.state = STATE_JUMP_RIGHT;
    } else {
      this.state = STATE_JUMP_LEFT;
    }

    if (this.ySpeed == 0) this.ySpeed = -10;
  }

  public void move(ArrayList<WorldObject> level) {
    if ((this.xSpeed >=0 && this.xSpeed <= this.maxXSpeed) || (this.xSpeed <0 && this.xSpeed >= -this.maxXSpeed)) this.xSpeed += this.xAccel;
    if ((this.ySpeed >=0 && this.ySpeed <= this.maxYSpeed) || (this.ySpeed <0 && this.ySpeed >= -this.maxYSpeed)) this.ySpeed += this.yAccel;


    // Move pixel by pixel if no collision occurs
    boolean xCollision = false;
    for (int xStep = 0; xStep < (this.xSpeed >= 0 ? this.xSpeed : -this.xSpeed); xStep++) {
      for ( WorldObject w : level ) {
        if (this.collide(w, new PVector(this.position.x+(this.xSpeed >= 0 ? 1 : -1), this.position.y))) {
          if (w.collide) {
            xCollision = true;
            this.xSpeed = 0;
          }
          this.onCollide(w);
        }
      }

      if (!xCollision) {
        this.position.x += (this.xSpeed >= 0 ? 1 : -1);
      }
    }

    boolean yCollision = false;
    for (int yStep = 0; yStep < (this.ySpeed >= 0 ? this.ySpeed : -this.ySpeed); yStep++) {
      for ( WorldObject w : level ) {
        if (this.collide(w, new PVector(this.position.x, this.position.y+(this.ySpeed >= 0 ? 1 : -1)))) {
          if (w.collide) {
            yCollision = true;
            this.ySpeed = 0;
          }
          this.onCollide(w);
        }
      }

      if (!yCollision) {
        this.position.y += (this.ySpeed >= 0 ? 1 : -1);
      }
    }
  }

  private void onCollide(WorldObject w) {
    this.collisionObject = w;

    if (this.state == STATE_JUMP_LEFT || this.state == STATE_JUMP_RIGHT) {
      if (this.xAccel > 0) {
        this.state = STATE_DEFAULT;
      } else {
        this.state = STATE_LEFT;
      }
    }
  }

  private boolean collide(WorldObject w, PVector position) {

    ArrayList<PVector> collisionPoints = new ArrayList<PVector>(); 
    collisionPoints.add(new PVector(position.x + this.playerWidth/2, position.y)); //bottom
    collisionPoints.add(new PVector(position.x, position.y - playerHeight / 6)); //bottom left
    collisionPoints.add(new PVector(position.x + this.playerWidth, position.y - playerHeight / 6)); //bottom right
    collisionPoints.add(new PVector(position.x, position.y - playerHeight/2)); //left
    collisionPoints.add(new PVector(position.x + this.playerWidth/2, position.y - this.playerHeight)); //top
    collisionPoints.add(new PVector(position.x + this.playerWidth, position.y - this.playerHeight/2)); //right

    ArrayList<PVector> bounds = w.getBounds();

    for (PVector p : collisionPoints) {
      ellipseMode(CENTER);
      noStroke();
      fill(0, 0, 255);
      if (Collision.pointPolygon(bounds, (float)p.x, (float)p.y)) {
        fill(0, 255, 255);
        if (debug) ellipse(p.x, p.y, 2, 2);
        return true;
      }
      if (debug) ellipse(p.x, p.y, 2, 2);
    }
    return false;
  }

  public WorldObject getCollisionObject() {
    return this.collisionObject;
  }
}