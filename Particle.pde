class Particle {
  PVector pos, vel;
  float size;
  
  
  public Particle(float x, float y, float size, float speed) {
    this.pos = new PVector(x, y);
    this.vel = PVector.random2D();    // Unit vector with random direction
    this.vel.setMag(speed);
    this.size = size;
  }

  public void draw() {
    noStroke();
    fill(255);
    ellipse(pos.x, pos.y, size, size);
  }
  
  public void update() {
    float speed = this.vel.mag();
    this.vel = PVector.random2D();    // Unit vector with random direction
    this.vel.setMag(speed);
    pos.add(vel);
  }
}
