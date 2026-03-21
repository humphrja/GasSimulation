import grafica.*;
import java.util.Map;

Particle[] particles;
Box systemBox;

GPlot plot;

int numCollisions;

float systemX = 300;
float systemY = 300;

//float pWinX, pWinY, dWinX, dWinY;
//float winOriginX, winOriginY;

//import javax.swing.JFrame;
//import processing.awt.PSurfaceAWT;

//JFrame frame;

void setup() {
  size(1200,600);
  frameRate(30);
  //windowMove(400,200);
  
  //PSurfaceAWT.SmoothCanvas canvas = (PSurfaceAWT.SmoothCanvas) surface.getNative();
  //// Get the JFrame which contains the canvas
  //frame = (JFrame) canvas.getFrame();
  
  //pWinX = frame.getX();
  //pWinY = frame.getY();
  //winOriginX = pWinX;
  //winOriginY = pWinY;
  
  systemBox = new Box(-90, -90, 90, 90);
  
  //int N = 10000;  // No. particles
  int N = 2000;
  float s = 1;  // Size of particle
  particles = new Particle[N];
  for (int i = 0; i < N; i++) {
    float randX = random(systemBox.xMin + 2*s, systemBox.xMax - 2*s);
    float randY = random(systemBox.yMin + 2*s, systemBox.yMax - 2*s);
    particles[i] = new Particle(randX, randY, s, 0.02);
  }
  
  plot = new GPlot(this);
  plot.setPos(610, 10);
  plot.setDim(480, 480);
  plot.setYLim(0, N);
  
  plot.setTitleText("Example plot");
  plot.getXAxis().setAxisLabelText("Particle velocity (px/frame)");
  plot.getYAxis().setAxisLabelText("Probability");
  
  plot.startHistograms(GPlot.VERTICAL);
}

void draw() {
  background(0);
  pushMatrix();
  translate(systemX, systemY);
  
  // Time delta between this frame and the last
  float timestep = 1;
  
  //float winX = frame.getX();
  //float winY = frame.getY();
  //dWinX = winX - pWinX;
  //dWinY = winY - pWinY;
  //pWinX = winX;
  //pWinY = winY;
  
  //translate(winOriginX-winX, winOriginY-winY);
  
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
    mouseInfluence();
  }

  // For particles that didn't collide, continue their trajectory
  for (Particle p : particles) {
    //p.update(dWinX, dWinY, -(winOriginX-winX), -(winOriginY-winY));
    p.update(systemBox);
  }
  
  // Display particles
  for (Particle p : particles) {
    p.draw();
  }
  
  systemBox.draw();
  
  popMatrix();
  
  updatePlot(50);
  
  plot.beginDraw();
  plot.drawBackground();
  plot.drawBox();
  plot.drawXAxis();
  plot.drawYAxis();
  plot.drawTitle();
  plot.drawHistograms();
  plot.endDraw();
}

void keyPressed() {
  if (key == ' ') {
    systemBox.update(-290, -290, 290, 290);
  }
}

void mouseInfluence() {
  float strength = 4;
  PVector mouse = new PVector(mouseX-systemX, mouseY-systemY);
  
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

void updatePlot(int numBins) {
  float min = 0;
  float max = 10;
  float binWidth = (max - min) / numBins;
  // Get particle speeds and determine maximum
  
  float[] counts = new float[numBins];
  
  for (Particle p : particles) {
    float speed = p.vel.mag();
    int binIndex = (int) ((speed - min) / binWidth);
    if (binIndex >= 0 && binIndex < numBins) {
      counts[binIndex] += 1;
    } else {
      println("WARNING: bin index out of range (", binIndex, ") for velocity: ", speed);
    }
  }
  
  // Plot the distribution
  
  GPointsArray points = new GPointsArray(particles.length);
    
  for (int i = 0; i < counts.length; i++) {
    points.add(min + i*binWidth, counts[i]);
  }
  
  plot.setPoints(points);
}
