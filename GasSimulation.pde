Particle[] particles;

void setup() {
  size(600,600);
  frameRate(30);
  
  //int N = 10000;  // No. particles
  int N = 100;
  int s = 7;  // Size of particle
  particles = new Particle[N];
  for (int i = 0; i < N; i++) {
    particles[i] = new Particle(0, 0, s, 5);
  }
}

void draw() {
  background(0);
  translate(width/2f, height/2f);
  
  // Time delta between this frame and the last
  float timestep = 1;
  
  // Check for collisions, then re-position and re-direct particles as necessary
  for (Particle pA : particles) {
    for (Particle pB : particles) {
      // Skip checking the same particle against itself
      if (pA.equals(pB)) continue;
      
      // As the collide() function updates both particles at once, don't reapply the function if it is found later when iterating through all the particles
      // This method assumes that 1 particle collides with at most one other particle per frame
          // Otherwise each particle could have a dynamic list that stores a list of particles it has collided with in between frames. But the chance of >2 particles colliding all in the same frame is minimal.
      if (pA.particleCollisionApplied) continue;
      if (pB.particleCollisionApplied) continue;
      
      if (collisionBetween(pA, pB)) {
        collideParticles(pA, pB, timestep);
        
        pA.particleCollisionApplied = true;
        pB.particleCollisionApplied = true;
      }
    }
  }

  // For particles that didn't collide, continue their trajectory
  for (Particle p : particles) {
    p.update();
  }
  
  // Display particles
  for (Particle p : particles) {
    p.draw();
  }
}
