import grafica.*;
import java.text.SimpleDateFormat;
import java.util.Date;

Particle[] particles;
Box systemBox;

GPlot velHist;      // Velocity histogram for Maxwellian distribution
GPlot maxwellPlot;      // Maxwellian distribution overlaid onto histogram
GPlot tempPlot;     // Temperature-time plot
GPlot collPlot;     // Collisions-time plot
GPlot velScatter;      // Collisions
GPlot freqScatter;     // No. particles in modal bin: Peak of Maxwellian

int numCollisions;

float BoltzmannConstant = 1;

// Dimensions for each window cell to fit on the canvas
int numRows = 2;
int numCols = 3;
PVector[][] windowGrid = new PVector[numRows][numCols];        // 2x2 array containing vector (x,y) for center points
float winWidth, winHeight;
float margin = 5;              // Distance between window cell and grid border

String filename;

void setup() {
  size(1350,900);
  frameRate(30);
  
  SimpleDateFormat sdf = new SimpleDateFormat("yyyy-MM-dd_HH-mm-ss");
  String startTime = sdf.format(new Date());
  filename = String.format("/data/%s_######.png", startTime);
  
  // Allocate dimensions for a 2x2 window grid
  float cellWidth = (width/((float) numCols));
  float cellHeight = (height/((float) numRows));
  winWidth = cellWidth - 2*margin;
  winHeight = cellHeight - 2*margin;
  
  for (int r = 0; r < numRows; r++) {
    for (int c = 0; c < numCols; c++) {
      windowGrid[r][c] = new PVector(
        cellWidth/2f + c*cellWidth,
        cellHeight/2f + r*cellHeight
      );
    }
  }
  
  systemBox = new Box(0, 0, winWidth/3f, winHeight/3f);
  
  int N = 2000;  // No. particles
  float s = 1;  // Size of particle
  float initSpeed = 0.02;
  particles = new Particle[N];
  for (int i = 0; i < N; i++) {
    float randX = random(systemBox.xMin + 2*s, systemBox.xMax - 2*s);
    float randY = random(systemBox.yMin + 2*s, systemBox.yMax - 2*s);
    particles[i] = new Particle(randX, randY, s, initSpeed);
  }
  
  createPlots(N);
}

void draw() {
  background(0);

  pushMatrix();
  translate(windowGrid[0][0].x, windowGrid[0][0].y);
  
  // Time delta between this frame and the last
  float timestep = 1;
    
  numCollisions = 0;
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
        numCollisions++;
      }
    }
  }
  
  if (mousePressed) {
    // Create an attractive/repulsive force that obeys inverse square law from mouse's position
    mouseInfluence();
  }

  // For particles that didn't collide, continue their trajectory
  for (Particle p : particles) {
    p.update(systemBox);
  }
  
  // Display particles
  for (Particle p : particles) {
    p.draw();
  }
  
  systemBox.draw();
  popMatrix();
  
  // Update the data within each plot, and do some statistical thermodynamic analysis
  updatePlots(100);
  
  // Display plots
  drawPlots();
}

void keyPressed() {
  if (key == CODED) {
    if (keyCode == UP) {
      // Choose a random particle and increase its energy
      //particles[(int) random(particles.length)].vel.mult(10);
      
      // Uniformly increase energy of all particles
      for (Particle p : particles) {
        p.vel.mult(1.1);
      }
    
    } else if (keyCode == DOWN) {
      // Choose a random particle and decrease its energy
      //particles[(int) random(particles.length)].vel.mult(0);

      // Uniformly increase energy of all particles
      for (Particle p : particles) {
        p.vel.mult(0.9);
      }
    }
  } else {
    if (key == ' ') {
      // Enlarge system box when space is pressed
      systemBox.update(0, 0, winWidth, winHeight);
      
    } else if (key == '\n') {
      // ENTER/RETURN to save frame
      //SimpleDateFormat sdf = new SimpleDateFormat("yyyy-MM-dd_HH-mm-ss_######");
      saveFrame(filename);
    }
  }
}

void mouseInfluence() {
  float strength = 4;
  PVector mouse = new PVector(mouseX-windowGrid[0][0].x, mouseY-windowGrid[0][0].y);
  
  // Clicking only works within the system window
  if (abs(mouse.x) >= winWidth/2f) return;
  if (abs(mouse.y) >= winHeight/2f) return;
  
  if (mouseButton == LEFT) {
    for (Particle p : particles) {
      p.attractTo(mouse, strength);
    }
    
  } else if (mouseButton == RIGHT) {
    for (Particle p : particles) {
      p.repelFrom(mouse, strength);
    }
  }
}
