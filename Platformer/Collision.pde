static class Collision {

  public static boolean pointPolygon (ArrayList<PVector> vertices, float px, float py) {
    boolean collision = false;

    for (int i=0, j=vertices.size()-1; i < vertices.size(); j = i++) {
      if ( ((vertices.get(i).y>py) != (vertices.get(j).y>py)) && (px < (vertices.get(j).x-vertices.get(i).x) * (py-vertices.get(i).y) / (vertices.get(j).y-vertices.get(i).y) + vertices.get(i).x) ) {
        collision = !collision;
      }
    }
    return collision;
  }

  // POLYGON/POINT
  public static boolean polyPoint(ArrayList<PVector> vertices, float px, float py) {
    boolean collision = false;

    // go through each of the vertices, plus
    // the next vertex in the list
    int next = 0;
    for (int current=0; current<vertices.size(); current++) {

      // get next vertex in list
      // if we've hit the end, wrap around to 0
      next = current+1;
      if (next == vertices.size()) next = 0;

      // get the PVectors at our current position
      // this makes our if statement a little cleaner
      PVector vc = vertices.get(current);    // c for "current"
      PVector vn = vertices.get(next);       // n for "next"

      // compare position, flip 'collision' variable
      // back and forth
      if (((vc.y > py && vn.y < py) || (vc.y < py && vn.y > py)) &&
        (px < (vn.x-vc.x)*(py-vc.y) / (vn.y-vc.y)+vc.x)) {
        collision = !collision;
      }
    }
    return collision;
  }
}