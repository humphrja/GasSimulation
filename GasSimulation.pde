import grafica.*;
import java.util.Map;

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

void setup() {
  size(1350,900);
  frameRate(30);
  
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
  
  //int N = 10000;  // No. particles
  int N = 2000;
  float s = 1;  // Size of particle
  particles = new Particle[N];
  for (int i = 0; i < N; i++) {
    float randX = random(systemBox.xMin + 2*s, systemBox.xMax - 2*s);
    float randY = random(systemBox.yMin + 2*s, systemBox.yMax - 2*s);
    particles[i] = new Particle(randX, randY, s, 0.02);
  }
  
  // Create histogram for Maxwellian distribution
  velHist = new GPlot(this);
  velHist.setPos(windowGrid[1][0].x - winWidth/2f, windowGrid[1][0].y - winHeight/2f);
  // Sets margins outside of plot for axes
  velHist.setMar(60,60,40,60);
  // Plot dimensions onlys
  velHist.setDim(winWidth - 120, winHeight - 100);
  //velHist.setYLim(0, N);
  velHist.setYLim(0, 1);
  velHist.setXLim(0, 10);
    
  String title = String.format("Comparing simulated and theoretical\nvelocity distributions for %d particles.", N);
  velHist.setTitleText(title);
  velHist.getXAxis().setAxisLabelText("Particle velocity (px/frame)");
  velHist.getYAxis().setAxisLabelText("Relative frequency per velocity bin (frame/px)");
  
  velHist.startHistograms(GPlot.VERTICAL);
  
  maxwellPlot = new GPlot(this);
  maxwellPlot.setPos(windowGrid[1][0].x - winWidth/2f, windowGrid[1][0].y - winHeight/2f);
  maxwellPlot.setMar(60,60,40,60);
  maxwellPlot.setDim(winWidth - 120, winHeight - 100);
  maxwellPlot.getRightAxis().setAxisLabelText("Theoretical Probability");
  maxwellPlot.getRightAxis().setDrawTickLabels(true);
  maxwellPlot.setYLim(0,1);
  maxwellPlot.setXLim(0, 10);
  
  
  // Create time plots with multiple series
  // One with the peak count value of the histogram
  // One with peak velocity over time
  // Maybe one to verify total no. particles over time
  
  tempPlot = new GPlot(this);
  tempPlot.setPos(windowGrid[0][1].x - winWidth/2f, windowGrid[0][1].y - winHeight/2f);
  tempPlot.setMar(60,60,40,40);
  tempPlot.setDim(winWidth - 100, winHeight - 100);
  tempPlot.setTitleText("Temperature-time");
  tempPlot.getXAxis().setAxisLabelText("Time (frame)");
  tempPlot.getYAxis().setAxisLabelText("Temperature");
  
  collPlot = new GPlot(this);
  collPlot.setPos(windowGrid[1][1].x - winWidth/2f, windowGrid[1][1].y - winHeight/2f);
  collPlot.setMar(60,60,40,40);
  collPlot.setDim(winWidth - 100, winHeight - 100);
  collPlot.setTitleText("Collisions-time");
  collPlot.getXAxis().setAxisLabelText("Time (frame)");
  collPlot.getYAxis().setAxisLabelText("Number of collisions per frame");

  velScatter = new GPlot(this);
  velScatter.setPos(windowGrid[0][2].x - winWidth/2f, windowGrid[0][2].y - winHeight/2f);
  velScatter.setMar(60,60,40,40);
  velScatter.setDim(winWidth - 100, winHeight - 100);
  velScatter.setTitleText("Velocity-Temperature");
  velScatter.getXAxis().setAxisLabelText("Temperature");
  velScatter.getYAxis().setAxisLabelText("Most frequent velocity (px/frame)");
  
  freqScatter = new GPlot(this);
  freqScatter.setPos(windowGrid[1][2].x - winWidth/2f, windowGrid[1][2].y - winHeight/2f);
  freqScatter.setMar(60,60,40,40);
  freqScatter.setDim(winWidth - 100, winHeight - 100);
  freqScatter.setTitleText("Frequency of the modal velocity");
  freqScatter.getXAxis().setAxisLabelText("Time (frame)");
  freqScatter.getYAxis().setAxisLabelText("Number particles");
  freqScatter.setYLim(0, N);
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
  
  updateHistogram(100);
  
  // Draw the histogram
  velHist.beginDraw();
  velHist.drawBackground();
  velHist.drawBox();
  velHist.drawXAxis();
  velHist.drawYAxis();
  velHist.drawTitle();
  velHist.drawHistograms();
  velHist.endDraw();

  // Overlay Maxwellian distribution
  maxwellPlot.beginDraw();
  //velHist.drawBackground();
  //velHist.drawBox();
  //velHist.drawXAxis();
  maxwellPlot.drawRightAxis();
  //velHist.drawTitle();
  //velHist.drawHistograms();
  maxwellPlot.drawLines();
  maxwellPlot.endDraw();

  
  
  // Draw the temperature-time plot
  tempPlot.beginDraw();
  tempPlot.drawBackground();
  tempPlot.drawBox();
  tempPlot.drawXAxis();
  tempPlot.drawYAxis();
  tempPlot.drawTitle();
  tempPlot.drawGridLines(GPlot.BOTH);
  tempPlot.drawLines();
  tempPlot.endDraw();
  
  // Draw the collision-time plot
  collPlot.beginDraw();
  collPlot.drawBackground();
  collPlot.drawBox();
  collPlot.drawXAxis();
  collPlot.drawYAxis();
  collPlot.drawTitle();
  collPlot.drawGridLines(GPlot.BOTH);
  collPlot.drawLines();
  collPlot.endDraw();
  
  // Draw the peak velocity over time plot
  velScatter.beginDraw();
  velScatter.drawBackground();
  velScatter.drawBox();
  velScatter.drawXAxis();
  velScatter.drawYAxis();
  velScatter.drawTitle();
  velScatter.drawGridLines(GPlot.BOTH);
  velScatter.drawPoints();
  velScatter.endDraw();

  // Draw the peak frequency over time plot
  freqScatter.beginDraw();
  freqScatter.drawBackground();
  freqScatter.drawBox();
  freqScatter.drawXAxis();
  freqScatter.drawYAxis();
  freqScatter.drawTitle();
  freqScatter.drawGridLines(GPlot.BOTH);
  freqScatter.drawPoints();
  freqScatter.endDraw();
}

void keyPressed() {
  if (key == ' ') {
    // Enlarge system box when space is pressed
    systemBox.update(0, 0, winWidth, winHeight);
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

void updateHistogram(int numBins) {
  float min = 0;
  float max = 10;
  float binWidth = (max - min) / numBins;
  
  float[] counts = new float[numBins];
  
  // average kinetic energy
  float aveKE = 0;
  
  for (Particle p : particles) {
    float speed = p.vel.mag();
    
    // Discretise speed into bins and count frequency
    int binIndex = (int) ((speed - min) / binWidth);
    if (binIndex >= 0 && binIndex < numBins) {
      counts[binIndex] += 1;
    } else {
      println("WARNING: bin index out of range (", binIndex, ") for velocity: ", speed);
    }
    
    aveKE += 0.5*p.mass*speed*speed;
  }
  
  aveKE /= particles.length;
  float temperature = aveKE / BoltzmannConstant;  // For 2D monatomic particles with 2 degrees of freedom
  
  // Plot the speed distribution
  GPointsArray histSeries = new GPointsArray(particles.length);
  
  int particlesCounted = 0;
    
  float highestFrequency = 0;
  float modalVelocity = 0;
  for (int i = 0; i < counts.length; i++) {
    // Offset bins by 0.5 because (int) casting floors all velocities down. So the correct median for that bin is actually half of a bin's width extra
    float velocity = min + (i+0.5)*binWidth;
    float probability = counts[i]/2000/binWidth;
    histSeries.add(velocity, probability);
    
    if (counts[i] > highestFrequency) {
      highestFrequency = counts[i];
      modalVelocity = velocity;
    }
    
    particlesCounted += counts[i];
  }
  //println("Area under histogram: ", particlesCounted);
  
  velHist.setPoints(histSeries);
  
  // Plot Maxwellian distribution
  int numVels = 100;
  GPointsArray maxwellian = new GPointsArray(numVels);

  float dv = (max - min) / numVels;
  float area = 0;
  for (float v = min; v < max; v += dv) {
    float probV = probability2D(v, temperature, particles[0].mass);
    maxwellian.add(v, probV);
    
    area += probV * dv;
  }
  //println("Area under maxwellian: ", area);
  maxwellPlot.setPoints(maxwellian);
  
  
  // Plot temperature over time
  tempPlot.addPoint(frameCount, temperature);
  
  // Plot collisions over time
  collPlot.addPoint(frameCount, numCollisions);
  
  // Plot modal velocity over time
  velScatter.addPoint(temperature, modalVelocity);
  
  // Plot frequency of modal velocity
  freqScatter.addPoint(temperature, highestFrequency);
}

// Used to plot the theoretical Maxwell velocity distribution
public float probability3D(float velocity, float temperature, float mass) {
  float normalisation_constant = pow(mass / (2*PI*BoltzmannConstant*temperature), 1.5);
  float velocity_term = 4*PI*velocity*velocity;
  float exponential_term = exp(- (mass*velocity*velocity) / (2*BoltzmannConstant*temperature));
  return normalisation_constant * velocity_term * exponential_term;
}

// Used to plot the theoretical Maxwell velocity distribution
public float probability2D(float velocity, float temperature, float mass) {
  float normalisation_constant = (mass / (BoltzmannConstant*temperature));
  float velocity_term = velocity;
  float exponential_term = exp(- (mass*velocity*velocity) / (2*BoltzmannConstant*temperature));
  return normalisation_constant * velocity_term * exponential_term;
}
