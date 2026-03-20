class Particle {
  PVector pos, vel;    // Current position and velocity
  PVector nextPos;     // Position of this particle in one frame
  float radius;
  float mass;
  
  // Used to skip updating velocity after collision twice to one particle
  boolean particleCollisionApplied = false;
  
  public Particle(float x, float y, float size, float speed) {
    //this.pos = new PVector(x, y);
    this.pos = PVector.random2D().mult(200);
    
    this.vel = PVector.random2D();    // Unit vector with random direction
    this.vel.setMag(speed);
    
    this.nextPos = PVector.add(pos, vel);
    
    this.radius = size;
    this.mass = 1;
    // Extension could be to determine mass from radius given constant density and have a variety of different sized particles interact
  }

  public void draw() {
    noStroke();
    fill(255);
    ellipse(pos.x, pos.y, 2*radius, 2*radius);    // Last two parameters specify width/height not radii
    
    particleCollisionApplied = false;
  }
  
  public void update() {
    // Check for wall collisions
    boolean wallCollisionApplied = false;
    
    // Default values that will get overridden
    float wallX = pos.x;
    float wallY = pos.y;
    
    // Check walls
    if (abs(nextPos.x) >= width/2f - radius) {
      // Set position to border the interior side of the wall
      wallX = Math.signum(nextPos.x)*(width/2f - radius);
      // To get appropriate y value at collision, assume linear interpolation of x, between current and next positions and apply to y
      wallY = map(wallX, pos.x, nextPos.x, pos.y, nextPos.y);
      // Reflect velocity
      vel.x *= -1;
      wallCollisionApplied = true;
    }
    
    if (abs(nextPos.y) >= height/2f - radius) {
      wallY = Math.signum(nextPos.y)*(height/2f - radius);
      wallX = map(wallY, pos.y, nextPos.y, pos.x, nextPos.x);
      vel.y *= -1;
      wallCollisionApplied = true;
    }
    
    if (!wallCollisionApplied && !particleCollisionApplied) {
      // Only increment position if it was not set manually after a collision
      pos.add(vel);
    } else if (wallCollisionApplied) {
      // These should be set after the wall collision sequence because that sequence references the current and next positions, 
      // and there's a chance a corner collision occurs (2 wall collisions in one frame) so position should not be prematurely updated
      pos.x = wallX;
      pos.y = wallY;
    }
    
    // Update prediction of next position for next frame's collision calculations
    nextPos = PVector.add(pos, vel);
      // Static method is used so as not to update the position vector
  }
  
  public PVector velocityAfterCollision(Particle other) {
    // Calculates and returns the new velocity of this particle after this particle has collided with another particle
    // Retrieved from https://en.wikipedia.org/wiki/Elastic_collision#Two-dimensional_collision_with_two_moving_objects
      // Note this is dependent on the current positions and velocities of both particles
    
    // (x1-x2): Vector pointing from other particle to this particle
    PVector dPos = PVector.sub(this.pos, other.pos);
    // (v1-v2)    
    PVector dVel = PVector.sub(this.vel, other.vel);
    
    PVector dPosNorm = dPos.normalize();
    float scalarProj = PVector.dot(dVel, dPosNorm);
    PVector proj_dVel_onto_dPos = dPosNorm.mult(scalarProj);
    
    proj_dVel_onto_dPos.mult(2*this.mass / (this.mass + other.mass) );
    return PVector.sub(this.vel, proj_dVel_onto_dPos);
  }
  
  public float timeOfCollision(Particle other, float timestep) {
    // AB: Vector difference between current positions of each particle
    PVector dPos = PVector.sub(other.pos, this.pos);
    
    // AvBv: Vector difference between current velocities of each particle
    PVector dVel = PVector.sub(other.vel, this.vel);
    
    // Quadratic in t
    float a = dVel.magSq();
    float b = 2 * PVector.dot(dPos, dVel);
    float c = dPos.magSq() - sq(this.radius + other.radius);
    
    float tc1 = (-b + sqrt(b*b - 4*a*c)) / (2*a);
    float tc2 = (-b - sqrt(b*b - 4*a*c)) / (2*a);
    
    float collision_time = 0;
    
    // Select the collision time that occurs before the end of frame
    if (tc1 <= timestep && tc2 > timestep) {
      collision_time = tc1;
    } else if (tc2 <= timestep && tc1 > timestep) {
      collision_time = tc2;
    } else if (tc1 == tc2) {
      collision_time = tc1;
    } else {
      println("WARNING: neither solutions for collision time (", tc1, ", ", tc2, ") occurred before the next frame.");
      collision_time = 0;
      // Set collision to occur at start of this frame, and do not displace the particles any further along their predicted trajectory.
      // It is not expected this condition is reached at all because lines in 2D are of distance D apart strictly once either side of their point of intersection
    }
    
    return collision_time;
  }
}

// Checks the predicted position of two particles in the next frame to see if they collide. Returns true if collision occurs
public boolean collisionBetween(Particle pA, Particle pB) {
  // Predicted vector from A->B
  PVector diff = PVector.sub(pB.nextPos, pA.nextPos);
  
  // Return true if collision occurs (i.e. distance < combined radii)
  return diff.magSq() <= sq(pA.radius + pB.radius);
    // Using square operations saves a costly sqrt() function
}

// Re-calculates the next position of each particle, given they would have collided between the current and next frames.
public void collideParticles(Particle pA, Particle pB, float timestep) {
  // Find time of collision using time-dependent vector equations for particle positions over a linear trajectory between frames
  float collisionTime = pA.timeOfCollision(pB, timestep);
    // This will be less than the value of timestep to indicate a collision occurred sometime before the next frame
  
  // Position particles to their point of contact - which is some fraction of the way between current position and next position with their current velocity
  pA.pos.add(PVector.mult(pA.vel, collisionTime));
  pB.pos.add(PVector.mult(pB.vel, collisionTime));
    // Important to update their positions as the following velocity calculation assumes they are positioned at the point of contact

  // Calculate and set new particle velocities (which will be saved for future frames)
  PVector pAVelNew = pA.velocityAfterCollision(pB);
  PVector pBVelNew = pB.velocityAfterCollision(pA);
    // It is important that pA.vel is not updated before the new pB.vel is calculated
  pA.vel = pAVelNew;
  pB.vel = pBVelNew;
  
  // Update particle position for the remaining time leftover after the collision occurred, until the next frame
  float remainingTime = timestep - collisionTime;
  pA.pos.add(PVector.mult(pA.vel, remainingTime));
  pB.pos.add(PVector.mult(pB.vel, remainingTime));
}
