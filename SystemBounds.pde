//public SystemBounds {
//  public SystemBounds() {
    
//  }
  
//  public void draw() {
    
//  }
  
//  public boolean enclosesParticle(Particle p) {
    
//  }
  
//  public void collideParticle(Particle p) {
  
//  }
//}

public class Box {
  float xMin, yMin, boxWidth, boxHeight, xMax, yMax, xMed, yMed;
  
  public Box(float xMin, float yMin, float xMax, float yMax) {
    update(xMin, yMin, xMax, yMax);
  }
  
  public void draw() {
    noFill();
    strokeWeight(2);
    stroke(255);
    rect(xMin, yMin, boxWidth, boxHeight);
  }
  
  public void update(float xMin, float yMin, float xMax, float yMax) {
    this.xMin = xMin;
    this.yMin = yMin;
    this.xMax = xMax;
    this.yMax = yMax;
    
    this.boxWidth = xMax - xMin;
    this.boxHeight = yMax - yMin;
    this.xMed = xMin + boxWidth/2f;
    this.yMed = yMin + boxHeight/2f;
  }
}

//public class Circle {
//  float x, y, r;
//  public Circle(float x, float y, float r) {
//    this.x = x;
//    this.y = y;
//    this.r = r;
//  }
  
//  public void draw() {
    
//  }
//}
