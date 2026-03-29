public void createPlots(int numberParticles) {
  // Create histogram for Maxwellian distribution
  velHist = new GPlot(this);
  velHist.setPos(windowGrid[1][0].x - winWidth/2f, windowGrid[1][0].y - winHeight/2f);
  // Sets margins outside of plot for axes
  velHist.setMar(60,60,50,60);
  // Plot dimensions only
  velHist.setDim(winWidth - 120, winHeight - 110);
  velHist.setYLim(0, 1.5);
    
  String title = String.format("Comparing simulated and theoretical\nvelocity distributions for %d particles.", numberParticles);
  //String title = String.format("Comparing simulated and theoretical\nvelocity distributions for %d particles\nat temperature = %d", numberParticles);
  velHist.setTitleText(title);
  velHist.getXAxis().setAxisLabelText("Particle velocity (px/frame)");
  velHist.getYAxis().setAxisLabelText("Relative frequency per velocity bin (frame/px)");
  velHist.startHistograms(GPlot.VERTICAL);
  
  // Overlay line plot for theoretical Maxwellian onto histogram
  maxwellPlot = new GPlot(this);
  maxwellPlot.setPos(velHist.getPos());
  maxwellPlot.setMar(velHist.getMar());
  maxwellPlot.setDim(velHist.getDim());
  maxwellPlot.getRightAxis().setAxisLabelText("Theoretical probability");
  maxwellPlot.getRightAxis().setDrawTickLabels(true);
  maxwellPlot.setYLim(velHist.getYLim());
  maxwellPlot.setXLim(velHist.getXLim());
  
  
  // Create time plots
  
  // Temperature over time
  tempPlot = new GPlot(this);
  tempPlot.setPos(windowGrid[0][1].x - winWidth/2f, windowGrid[0][1].y - winHeight/2f);
  tempPlot.setMar(60,60,40,40);
  tempPlot.setDim(winWidth - 100, winHeight - 100);
  tempPlot.setTitleText("System temperature record.");
  tempPlot.getXAxis().setAxisLabelText("Time (frame)");
  tempPlot.getYAxis().setAxisLabelText("Temperature (K*)");
  
  // No. collisions per frame over time
  collPlot = new GPlot(this);
  collPlot.setPos(windowGrid[1][1].x - winWidth/2f, windowGrid[1][1].y - winHeight/2f);
  collPlot.setMar(60,60,40,40);
  collPlot.setDim(winWidth - 100, winHeight - 100);
  collPlot.setTitleText("Particle-particle collision record.");
  collPlot.getXAxis().setAxisLabelText("Time (frame)");
  collPlot.getYAxis().setAxisLabelText("Number of collisions per frame (1/frame)");

  // Most probable velocity vs temperature
  velScatter = new GPlot(this);
  velScatter.setPos(windowGrid[0][2].x - winWidth/2f, windowGrid[0][2].y - winHeight/2f);
  velScatter.setMar(60,60,40,40);
  velScatter.setDim(winWidth - 100, winHeight - 100);
  velScatter.setTitleText("Comparing most probable velocity with system temperature.");
  velScatter.getXAxis().setAxisLabelText("Temperature (K*)");
  velScatter.getYAxis().setAxisLabelText("Modal velocity (px/frame)");
  
  // Relative frequency 
  freqScatter = new GPlot(this);
  freqScatter.setPos(windowGrid[1][2].x - winWidth/2f, windowGrid[1][2].y - winHeight/2f);
  freqScatter.setMar(60,60,50,40);
  freqScatter.setDim(winWidth - 100, winHeight - 110);
  freqScatter.setTitleText("Proportion of particles occupying\nthe highest frequency velocity bin.");
  freqScatter.getXAxis().setAxisLabelText("Temperature (K*)");
  freqScatter.getYAxis().setAxisLabelText("Relative frequency per velocity bin (frame/px)");
}

void updatePlots(int numBins) {
  float min = 0;
  float max = 20;
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
      //println("WARNING: bin index out of range (", binIndex, ") for velocity: ", speed);
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
    float probability = counts[i]/particles.length/binWidth;
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
  maxwellPlot.setXLim(velHist.getXLim());

  
  // Plot temperature over time
  tempPlot.addPoint(frameCount, temperature);
  
  // Plot collisions over time
  collPlot.addPoint(frameCount, numCollisions);
  
  // Plot modal velocity over time
  velScatter.addPoint(temperature, modalVelocity);
  
  // Plot frequency of modal velocity
  freqScatter.addPoint(temperature, highestFrequency/particles.length/binWidth);
}

// Used to plot the theoretical Maxwell velocity distribution
public float probability2D(float velocity, float temperature, float mass) {
  float normalisation_constant = (mass / (BoltzmannConstant*temperature));
  float velocity_term = velocity;
  float exponential_term = exp(- (mass*velocity*velocity) / (2*BoltzmannConstant*temperature));
  return normalisation_constant * velocity_term * exponential_term;
}

public void drawPlots() {
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
  maxwellPlot.drawRightAxis();
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
