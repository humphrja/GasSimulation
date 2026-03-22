public class Box {
  float xMin, yMin, boxWidth, boxHeight, xMax, yMax, xMed, yMed;
  
  //public Box(float xMin, float yMin, float xMax, float yMax) {
  //  update(xMin, yMin, xMax, yMax);
  //}
  
  public Box(float xMed, float yMed, float boxWidth, float boxHeight) {
    update(xMed, yMed, boxWidth, boxHeight);
  }
  
  public void draw() {
    noFill();
    strokeWeight(2);
    stroke(255);
    rect(xMin, yMin, boxWidth, boxHeight);
  }

  public void update(float xMed, float yMed, float boxWidth, float boxHeight) {
    this.xMed = xMed;
    this.yMed = yMed;
    this.boxWidth = boxWidth;
    this.boxHeight = boxHeight;
    
    this.xMin = xMed - boxWidth/2f;
    this.xMax = xMed + boxWidth/2f;
    this.yMin = yMed - boxHeight/2f;
    this.yMax = yMed + boxHeight/2f;
  }
}
