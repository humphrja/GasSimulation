Particle[] particles;

void setup() {
  size(600,600);
  frameRate(30);
  
  int N = 1000;  // No. particles
  int s = 3;  // Size of particle
  particles = new Particle[N];
  for (int i = 0; i < N; i++) {
    particles[i] = new Particle(0, 0, s, 1);
  }
}

void draw() {
  background(0);
  translate(width/2f, height/2f);

  for (Particle p : particles) {
    p.update();
  }
  
  for (Particle p : particles) {
    p.draw();
  }
}
