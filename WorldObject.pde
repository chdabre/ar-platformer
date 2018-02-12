class WorldObject {
  public static final int TYPE_PLATFORM = 0;
  public static final int TYPE_DOOR     = 1;
  public static final int TYPE_END      = 2;
  public static final int TYPE_WALL     = 3;
  
  private PImage platformTexture = loadImage("textures/platform.jpg");
  
  private int type = 0;
  private ArrayList<PVector> bounds;
  private boolean collide;

  public WorldObject(int type, ArrayList<PVector> bounds, boolean collide) {
    this.type = type; //<>//
    this.bounds = bounds;
    this.collide = collide;
  }

  public void render() {
    pushMatrix();
    
    noStroke();
    
    beginShape();
    textureWrap(REPEAT);
    textureMode(NORMAL);
    
    
    if (this.type == TYPE_PLATFORM) {
      fill(255,0,0);//texture(platformTexture);
    } else if (this.type == TYPE_DOOR) {
      fill(0, 0, 0);
    } else if (this.type == TYPE_END) {
      fill(0, 0, 255);
    } else if(this.type == TYPE_WALL){
      noFill();
    }else {
      println("ERR: Invalid Object Type");
      fill(255, 255, 0);
    }
    
    vertex(this.bounds.get(0).x, this.bounds.get(0).y, 0, 0);
    vertex(this.bounds.get(1).x, this.bounds.get(1).y, 1, 0);
    vertex(this.bounds.get(2).x, this.bounds.get(2).y, 1, 1);
    vertex(this.bounds.get(3).x, this.bounds.get(3).y, 0, 1);
    
    endShape(CLOSE);
    
    popMatrix();
  }

  public int getType() {
    return this.type;
  }
  public ArrayList<PVector> getBounds() {
    return this.bounds;
  }
}