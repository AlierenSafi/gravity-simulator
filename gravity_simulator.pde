/**
 * Gravity Simulator
 * A modernized physics simulation with gravitational interactions
 * 
 * Controls:
 * - Left Click + Drag: Launch a new mass
 * - Right Click + Drag: Launch a cluster of 8 masses
 * - P: Pause/Resume
 * - K: Reset simulation
 * - N: Add sun
 * - M: Remove sun
 * - T: Toggle sun lock
 * - S: Toggle collision mode (bounce/merge)
 * - G: Toggle grid
 * - I: Toggle trails
 * - O: Toggle gravity field
 * - Y: Toggle direction arrows
 * - R: Toggle connections
 * - D: Toggle info panel
 * - H: Toggle help
 * - 1-3: Change theme
 */

// ==================== CONFIGURATION ====================

static final int HISTORY_LENGTH = 300;
static final float GRAVITY_CONSTANT = 0.7;
static final int GRID_SIZE = 5;
static final int MAX_TOTAL_MASS = 10000;
static final int TRAIL_LENGTH = 300;

// ==================== THEMES ====================

class Theme {
  String name;
  color bgColor;
  color gridColor;
  color textColor;
  color accentColor;
  color sunColor;
  color panelBg;
  
  Theme(String name, color bg, color grid, color text, color accent, color sun, color panel) {
    this.name = name;
    this.bgColor = bg;
    this.gridColor = grid;
    this.textColor = text;
    this.accentColor = accent;
    this.sunColor = sun;
    this.panelBg = panel;
  }
}

Theme[] themes = {
  new Theme("Default", #F0DFEC, #7C7C7C, #000000, #4A9EFF, #FAC80F, color(255, 200)),
  new Theme("Dark Space", #0A0A1A, #404080, #E0E0FF, #6A5AF9, #FFD700, color(20, 20, 40, 200)),
  new Theme("Minimal", #F5F5F5, #CCCCCC, #222222, #333333, #FFA500, color(255, 220))
};

int currentTheme = 0;

// ==================== STATE ====================

ArrayList<Mass> masses;
Mass sun;

boolean paused = false;
boolean sunLocked = true;
boolean bounceMode = false;

boolean showGrid = false;
boolean showTrails = true;
boolean showGravityField = false;
boolean showDirections = false;
boolean showConnections = false;
boolean showInfo = false;
boolean showHelp = true;

float spawnX, spawnY;
float radiusLeft = 1;
float radiusRight = 1;
boolean isLeftPressed = false;
boolean isRightPressed = false;

int cols, rows;
int[][] gravityGrid;

int startTime;
int frameCounter = 0;
float currentFPS = 60;

// Panel UI
int panelX = 10;
int panelY = 10;
int panelW = 280;
int panelH = 420;
boolean panelCollapsed = false;
int buttonHeight = 28;
int buttonSpacing = 4;

// ==================== SETUP ====================

void setup() {
  size(1400, 900);
  surface.setTitle("Gravity Simulator");
  surface.setResizable(true);
  
  initGrid();
  initSimulation();
  
  startTime = millis();
  textFont(createFont("Arial", 12));
}

void initGrid() {
  cols = width / GRID_SIZE;
  rows = height / GRID_SIZE;
  gravityGrid = new int[cols][rows];
  for (int i = 0; i < cols; i++) {
    for (int j = 0; j < rows; j++) {
      gravityGrid[i][j] = 0;
    }
  }
}

void initSimulation() {
  masses = new ArrayList<Mass>();
  sun = new Mass(width/2, height/2, 80, themes[currentTheme].sunColor, true);
  sun.velocity.set(0, 0);
  masses.add(sun);
}

// ==================== MAIN LOOP ====================

void draw() {
  // Calculate FPS every 30 frames
  frameCounter++;
  if (frameCounter % 30 == 0) {
    currentFPS = frameRate;
  }
  
  background(themes[currentTheme].bgColor);
  
  if (showGrid) drawGrid(30, 1, themes[currentTheme].gridColor);
  if (showGravityField) drawGravityField();
  if (showConnections) drawConnections();
  
  drawSpawnPreview();
  updateMasses();
  
  if (showDirections) drawDirectionArrows();
  
  drawUI();
}

// ==================== PHYSICS ====================

void updateMasses() {
  for (int i = masses.size() - 1; i >= 0; i--) {
    Mass mass = masses.get(i);
    
    if (!paused) {
      mass.applyForce(calculateGravity(mass));
      mass.update();
    }
    
    mass.display();
    checkCollisions(mass, i);
  }
}

PVector calculateGravity(Mass mass) {
  PVector force = new PVector(0, 0);
  
  for (Mass other : masses) {
    if (mass != other) {
      PVector direction = PVector.sub(other.position, mass.position);
      float distanceSq = direction.magSq();
      distanceSq = constrain(distanceSq, 100, 100000);
      direction.normalize();
      
      float strength = GRAVITY_CONSTANT * (mass.mass * other.mass) / distanceSq;
      PVector gravitationalForce = PVector.mult(direction, strength);
      force.add(gravitationalForce);
    }
  }
  
  return force;
}

void checkCollisions(Mass target, int index) {
  // Remove masses outside screen bounds
  if (target.position.x < -width/3 || target.position.y < -height/3 ||
      target.position.x > width * 1.33 || target.position.y > height * 1.33) {
    if (!target.isSun) {
      masses.remove(index);
    }
    return;
  }
  
  for (int i = 0; i < masses.size(); i++) {
    if (i == index) continue;
    
    Mass other = masses.get(i);
    float distance = PVector.dist(target.position, other.position);
    float minDistance = target.radius + other.radius;
    
    if (distance < minDistance) {
      if (bounceMode) {
        handleBounce(target, other, distance);
      } else {
        handleMerge(target, other, index, i);
        return;
      }
    }
  }
}

void handleBounce(Mass a, Mass b, float distance) {
  PVector normal = PVector.sub(b.position, a.position).normalize();
  
  float velA = PVector.dot(a.velocity, normal);
  float velB = PVector.dot(b.velocity, normal);
  
  float newVelA = (velA * (a.mass - b.mass) + 2 * b.mass * velB) / (a.mass + b.mass);
  float newVelB = (velB * (b.mass - a.mass) + 2 * a.mass * velA) / (a.mass + b.mass);
  
  a.velocity.add(PVector.mult(normal, newVelA - velA));
  b.velocity.add(PVector.mult(normal, newVelB - velB));
  
  float overlap = (a.radius + b.radius) - distance;
  a.position.sub(PVector.mult(normal, overlap / 2));
  b.position.add(PVector.mult(normal, overlap / 2));
  
  if ((a.isSun || b.isSun) && sunLocked) {
    sun.acceleration.set(0, 0);
    sun.velocity.set(0, 0);
  }
}

void handleMerge(Mass a, Mass b, int indexA, int indexB) {
  Mass larger, smaller;
  int smallerIndex;
  
  if (a.mass >= b.mass) {
    larger = a; smaller = b; smallerIndex = indexB;
  } else {
    larger = b; smaller = a; smallerIndex = indexA;
  }
  
  if (smaller.isSun && sunLocked) {
    larger.velocity = mergeVelocities(larger.velocity, larger.mass, smaller.velocity, smaller.mass);
    larger.mass += smaller.mass;
    larger.radius = sqrt(larger.mass / PI);
    masses.remove(smallerIndex);
  } else if (!smaller.isSun) {
    larger.velocity = mergeVelocities(larger.velocity, larger.mass, smaller.velocity, smaller.mass);
    larger.mass += smaller.mass;
    larger.radius = sqrt(larger.mass / PI);
    masses.remove(smallerIndex);
  }
}

PVector mergeVelocities(PVector v1, float m1, PVector v2, float m2) {
  float totalMass = m1 + m2;
  float newX = (v1.x * m1 + v2.x * m2) / totalMass;
  float newY = (v1.y * m1 + v2.y * m2) / totalMass;
  return new PVector(newX, newY);
}

// ==================== MASS CLASS ====================

class Mass {
  PVector position;
  PVector velocity;
  PVector acceleration;
  float mass;
  float radius;
  color col;
  boolean isSun;
  ArrayList<PVector> trail;
  
  Mass(float x, float y, float r, color c, boolean sun) {
    position = new PVector(x, y);
    velocity = new PVector(random(-2, 2), random(-2, 2));
    acceleration = new PVector(0, 0);
    radius = r;
    mass = PI * r * r;
    col = c;
    isSun = sun;
    trail = new ArrayList<PVector>();
  }
  
  void applyForce(PVector force) {
    PVector f = PVector.div(force, mass);
    acceleration.add(f);
  }
  
  void update() {
    if (isSun && sunLocked) {
      acceleration.set(0, 0);
      return;
    }
    
    velocity.add(acceleration);
    position.add(velocity);
    acceleration.mult(0);
    
    if (showTrails) {
      trail.add(position.copy());
      if (trail.size() > TRAIL_LENGTH) {
        trail.remove(0);
      }
    }
  }
  
  void display() {
    if (showTrails && trail.size() > 1) {
      noFill();
      for (int i = 0; i < trail.size() - 1; i++) {
        float alpha = map(i, 0, trail.size(), 0, 255);
        stroke(red(col), green(col), blue(col), alpha);
        strokeWeight(2);
        PVector p1 = trail.get(i);
        PVector p2 = trail.get(i + 1);
        line(p1.x, p1.y, p2.x, p2.y);
      }
    }
    
    ellipseMode(RADIUS);
    if (!showGravityField) {
      fill(col);
      stroke(0, 100);
      strokeWeight(1);
    } else {
      noFill();
      stroke(col);
      strokeWeight(2);
    }
    ellipse(position.x, position.y, radius, radius);
  }
  
  void clearTrail() {
    trail.clear();
  }
}

// ==================== VISUALIZATION ====================

void drawGrid(float spacing, int weight, color col) {
  stroke(col, 50);
  strokeWeight(weight);
  
  for (float x = 0; x < width; x += spacing) {
    line(x, 0, x, height);
  }
  for (float y = 0; y < height; y += spacing) {
    line(0, y, width, y);
  }
}

void drawGravityField() {
  noStroke();
  
  for (int i = 0; i < cols; i++) {
    for (int j = 0; j < rows; j++) {
      float x = i * GRID_SIZE;
      float y = j * GRID_SIZE;
      gravityGrid[i][j] = 0;
      
      for (Mass m : masses) {
        float dist = PVector.dist(m.position, new PVector(x, y));
        if (dist > m.radius) {
          gravityGrid[i][j] += 100 * m.mass / (dist * dist);
        }
      }
      
      color c = getGravityColor(gravityGrid[i][j]);
      fill(c);
      rect(x, y, GRID_SIZE, GRID_SIZE);
    }
  }
}

color getGravityColor(int value) {
  int v = value % 20;
  if (v < 5) return color(0, 0, 200, v * 10);
  else if (v < 10) return color(0, 200, 0, v * 10);
  else if (v < 15) return color(0, 0, 200, v * 10);
  else return color(200, 200, 0, v * 10);
}

void drawConnections() {
  for (int i = 0; i < masses.size() - 1; i++) {
    Mass m1 = masses.get(i);
    for (int j = i + 1; j < masses.size(); j++) {
      Mass m2 = masses.get(j);
      float dist = PVector.dist(m1.position, m2.position);
      float force = (m1.mass * m2.mass) / pow(dist, 2);
      
      if (force > 0.001) {
        float totalMass = m1.mass + m2.mass;
        int points = 50;
        
        for (int k = 0; k < points; k++) {
          float t = float(k) / (points - 1);
          float x = lerp(m1.position.x, m2.position.x, t);
          float y = lerp(m1.position.y, m2.position.y, t);
          
          if (x >= 0 && x <= width && y >= 0 && y <= height) {
            float grad = totalMass / MAX_TOTAL_MASS;
            color c = lerpColor(color(255, 0, 0), color(15, 180, 27), grad);
            fill(c);
            noStroke();
            ellipse(x, y, 3, 3);
          }
        }
      }
    }
  }
}

void drawDirectionArrows() {
  for (Mass m : masses) {
    float speed = m.velocity.mag();
    if (speed > 0.1) {
      drawArrow(m.position.x, m.position.y, m.velocity.heading(), m.radius + 20 + speed * 5);
    }
  }
}

void drawArrow(float x, float y, float angle, float len) {
  stroke(themes[currentTheme].textColor);
  strokeWeight(2);
  
  float x2 = x + cos(angle) * len;
  float y2 = y + sin(angle) * len;
  line(x, y, x2, y2);
  
  float arrowSize = len / 4;
  line(x2, y2, x2 - cos(angle - PI/6) * arrowSize, y2 - sin(angle - PI/6) * arrowSize);
  line(x2, y2, x2 - cos(angle + PI/6) * arrowSize, y2 - sin(angle + PI/6) * arrowSize);
}

void drawSpawnPreview() {
  if (isLeftPressed) {
    fill(0, 100);
    noStroke();
    radiusLeft += 0.3;
    ellipse(spawnX, spawnY, radiusLeft, radiusLeft);
    stroke(0);
    strokeWeight(1);
    line(mouseX, mouseY, spawnX, spawnY);
  } else if (isRightPressed) {
    fill(0, 100);
    noStroke();
    radiusRight += 0.3;
    ellipse(spawnX, spawnY, radiusRight, radiusRight);
  }
}

// ==================== UI ====================

void drawUI() {
  drawControlPanel();
  drawStats();
  if (showHelp) drawHelp();
  if (showInfo) drawInfoPanel();
}

void drawControlPanel() {
  // Draw panel background
  fill(themes[currentTheme].panelBg);
  stroke(themes[currentTheme].accentColor, 100);
  strokeWeight(1);
  
  if (panelCollapsed) {
    rect(panelX, panelY, 40, 40, 8);
    fill(themes[currentTheme].textColor);
    textAlign(CENTER, CENTER);
    textSize(18);
    text("+", panelX + 20, panelY + 18);
    return;
  }
  
  rect(panelX, panelY, panelW, panelH, 10);
  
  // Title
  fill(themes[currentTheme].textColor);
  textAlign(LEFT, TOP);
  textSize(14);
  text("Gravity Simulator", panelX + 10, panelY + 10);
  
  // Collapse button (minus sign)
  fill(themes[currentTheme].accentColor);
  rect(panelX + panelW - 32, panelY + 6, 24, 22, 4);
  fill(255);
  rect(panelX + panelW - 28, panelY + 15, 16, 3, 1);
  
  int y = panelY + 38;
  int btnW = panelW - 20;
  
  // Playback controls
  drawButton(paused ? "Play" : "Pause", panelX + 10, y, btnW, paused);
  y += buttonHeight + buttonSpacing;
  drawButton("Reset (K)", panelX + 10, y, btnW, false);
  y += buttonHeight + buttonSpacing * 2;
  
  // Sun controls
  drawButton("Add Sun (N)", panelX + 10, y, btnW, false);
  y += buttonHeight + buttonSpacing;
  drawButton("Remove Sun (M)", panelX + 10, y, btnW, false);
  y += buttonHeight + buttonSpacing;
  drawButton("Lock Sun (T)", panelX + 10, y, btnW, sunLocked);
  y += buttonHeight + buttonSpacing * 2;
  
  // Display toggles - smaller toggle switches
  drawToggle("Grid (G)", showGrid, panelX + 10, y);
  y += 22;
  drawToggle("Trails (I)", showTrails, panelX + 10, y);
  y += 22;
  drawToggle("Gravity Field (O)", showGravityField, panelX + 10, y);
  y += 22;
  drawToggle("Directions (Y)", showDirections, panelX + 10, y);
  y += 22;
  drawToggle("Connections (R)", showConnections, panelX + 10, y);
  y += 22;
  drawToggle("Info (D)", showInfo, panelX + 10, y);
  y += 30;
  
  // Collision mode
  drawButton(bounceMode ? "Bounce Mode (S)" : "Merge Mode (S)", panelX + 10, y, btnW, bounceMode);
  y += buttonHeight + buttonSpacing * 2;
  
  // Theme selector
  drawButton("Theme: " + themes[currentTheme].name, panelX + 10, y, btnW, false);
}

void drawButton(String label, int x, int y, int w, boolean active) {
  if (active) {
    fill(themes[currentTheme].accentColor);
  } else {
    fill(themes[currentTheme].accentColor, 180);
  }
  noStroke();
  rect(x, y, w, buttonHeight, 5);
  
  fill(255);
  textAlign(CENTER, CENTER);
  textSize(11);
  text(label, x + w/2, y + buttonHeight/2 - 1);
}

void drawToggle(String label, boolean state, int x, int y) {
  // Toggle track - smaller size
  int toggleW = 28;
  int toggleH = 14;
  int knobSize = 10;
  
  fill(state ? themes[currentTheme].accentColor : 120);
  rect(x, y, toggleW, toggleH, toggleH/2);
  
  // Toggle knob - smaller circle
  fill(255);
  float knobX = state ? x + toggleW - knobSize/2 - 2 : x + knobSize/2 + 2;
  ellipse(knobX, y + toggleH/2, knobSize, knobSize);
  
  // Label
  fill(themes[currentTheme].textColor);
  textAlign(LEFT, CENTER);
  textSize(11);
  text(label, x + toggleW + 8, y + toggleH/2 - 1);
}

void drawStats() {
  int elapsed = (millis() - startTime) / 1000;
  int hours = elapsed / 3600;
  int minutes = (elapsed % 3600) / 60;
  int seconds = elapsed % 60;
  
  int massCount = 0;
  for (Mass m : masses) {
    if (!m.isSun) massCount++;
  }
  
  fill(themes[currentTheme].panelBg);
  noStroke();
  rect(width - 200, 10, 190, 90, 8);
  
  fill(themes[currentTheme].textColor);
  textAlign(LEFT, TOP);
  textSize(11);
  text("FPS: " + nf(currentFPS, 0, 1), width - 190, 18);
  text("Masses: " + massCount, width - 190, 36);
  text("Time: " + nf(hours, 2) + ":" + nf(minutes, 2) + ":" + nf(seconds, 2), width - 190, 54);
  text("Theme: " + themes[currentTheme].name, width - 190, 72);
}

void drawHelp() {
  String[] help = {
    "Controls:",
    "Left Drag: Launch mass",
    "Right Drag: Launch cluster",
    "",
    "Shortcuts:",
    "P: Pause  K: Reset",
    "N: Add Sun  M: Remove",
    "T: Lock Sun  S: Mode",
    "G: Grid  I: Trails",
    "O: Gravity  Y: Arrows",
    "R: Connect  D: Info",
    "H: Help  1-3: Theme"
  };
  
  int h = help.length * 16 + 16;
  fill(themes[currentTheme].panelBg);
  rect(width - 200, 110, 190, h, 8);
  
  fill(themes[currentTheme].textColor);
  textAlign(LEFT, TOP);
  textSize(10);
  
  for (int i = 0; i < help.length; i++) {
    boolean isHeader = help[i].endsWith(":") || help[i].isEmpty();
    if (isHeader) fill(themes[currentTheme].accentColor);
    else fill(themes[currentTheme].textColor);
    text(help[i], width - 190, 118 + i * 16);
  }
}

void drawInfoPanel() {
  int x = 10;
  int y = height - 130;
  int w = 280;
  int h = 120;
  
  fill(themes[currentTheme].panelBg);
  stroke(themes[currentTheme].accentColor, 100);
  rect(x, y, w, h, 8);
  
  fill(themes[currentTheme].textColor);
  textAlign(LEFT, TOP);
  textSize(11);
  text("Mass Information:", x + 10, y + 10);
  
  int row = 0;
  int index = 0;
  for (Mass m : masses) {
    if (row >= 4) break;
    
    float speed = m.velocity.mag();
    String name = m.isSun ? "Sun" : (index + 1) + "";
    
    fill(m.isSun ? color(255, 200, 0) : themes[currentTheme].textColor);
    text(name + " | M:" + nf(m.mass, 0, 1) + " | V:" + nf(speed, 0, 2), x + 10, y + 30 + row * 22);
    
    if (!m.isSun) index++;
    row++;
  }
}

// ==================== INPUT ====================

void mousePressed() {
  // Check for panel collapse/expand button first
  if (panelCollapsed) {
    if (mouseX > panelX && mouseX < panelX + 40 &&
        mouseY > panelY && mouseY < panelY + 40) {
      panelCollapsed = false;
      return;
    }
  } else {
    // Check collapse button (minus sign area)
    if (mouseX > panelX + panelW - 35 && mouseX < panelX + panelW - 5 &&
        mouseY > panelY + 5 && mouseY < panelY + 32) {
      panelCollapsed = true;
      return;
    }
    
    // Check if clicking inside expanded panel
    if (mouseX > panelX && mouseX < panelX + panelW &&
        mouseY > panelY && mouseY < panelY + panelH) {
      handlePanelClick();
      return;
    }
  }
  
  // Spawn masses
  if (mouseButton == LEFT) {
    isLeftPressed = true;
    spawnX = mouseX;
    spawnY = mouseY;
    radiusLeft = 1;
  } else if (mouseButton == RIGHT) {
    isRightPressed = true;
    spawnX = mouseX;
    spawnY = mouseY;
    radiusRight = 1;
  }
}

void handlePanelClick() {
  int y = panelY + 38;
  int btnW = panelW - 20;
  
  // Pause
  if (mouseY > y && mouseY < y + buttonHeight) {
    paused = !paused;
    return;
  }
  y += buttonHeight + buttonSpacing;
  
  // Reset
  if (mouseY > y && mouseY < y + buttonHeight) {
    resetSimulation();
    return;
  }
  y += buttonHeight + buttonSpacing * 2;
  
  // Add sun
  if (mouseY > y && mouseY < y + buttonHeight) {
    addSun();
    return;
  }
  y += buttonHeight + buttonSpacing;
  
  // Remove sun
  if (mouseY > y && mouseY < y + buttonHeight) {
    removeSun();
    return;
  }
  y += buttonHeight + buttonSpacing;
  
  // Lock sun
  if (mouseY > y && mouseY < y + buttonHeight) {
    sunLocked = !sunLocked;
    sun.clearTrail();
    return;
  }
  y += buttonHeight + buttonSpacing * 2;
  
  // Toggles area - check if clicking on toggle row
  int toggleAreaStart = y;
  int toggleAreaEnd = y + 6 * 22;
  if (mouseY >= toggleAreaStart && mouseY < toggleAreaEnd) {
    int toggleIndex = (mouseY - toggleAreaStart) / 22;
    switch(toggleIndex) {
      case 0: showGrid = !showGrid; break;
      case 1: showTrails = !showTrails; break;
      case 2: showGravityField = !showGravityField; break;
      case 3: showDirections = !showDirections; break;
      case 4: showConnections = !showConnections; break;
      case 5: showInfo = !showInfo; break;
    }
    return;
  }
  y += 6 * 22 + 8;
  
  // Collision mode
  if (mouseY > y && mouseY < y + buttonHeight) {
    bounceMode = !bounceMode;
    return;
  }
  y += buttonHeight + buttonSpacing * 2;
  
  // Theme
  if (mouseY > y && mouseY < y + buttonHeight) {
    currentTheme = (currentTheme + 1) % themes.length;
    return;
  }
}

void mouseReleased() {
  if (isLeftPressed) {
    Mass m = new Mass(spawnX, spawnY, radiusLeft, color(random(100, 255), random(100, 255), random(100, 255)), false);
    PVector dir = new PVector(spawnX - mouseX, spawnY - mouseY);
    m.velocity = dir.div(10);
    masses.add(m);
    isLeftPressed = false;
    radiusLeft = 1;
  } else if (isRightPressed) {
    float maxSpeed = 2;
    for (int i = -1; i <= 1; i++) {
      for (int j = -1; j <= 1; j++) {
        if (i != 0 || j != 0) {
          Mass m = new Mass(spawnX + i * radiusRight * 3, spawnY + j * radiusRight * 3, radiusRight, 
                           color(random(100, 255), random(100, 255), random(100, 255)), false);
          m.velocity = new PVector(i, j).mult(maxSpeed);
          masses.add(m);
        }
      }
    }
    isRightPressed = false;
    radiusRight = 1;
  }
}

void keyPressed() {
  switch(key) {
    case 'p':
    case 'P':
      paused = !paused;
      break;
    case 'k':
    case 'K':
      resetSimulation();
      break;
    case 'n':
    case 'N':
      addSun();
      break;
    case 'm':
    case 'M':
      removeSun();
      break;
    case 't':
    case 'T':
      sunLocked = !sunLocked;
      sun.clearTrail();
      break;
    case 's':
    case 'S':
      bounceMode = !bounceMode;
      break;
    case 'g':
    case 'G':
      showGrid = !showGrid;
      break;
    case 'i':
    case 'I':
      showTrails = !showTrails;
      break;
    case 'o':
    case 'O':
      showGravityField = !showGravityField;
      break;
    case 'y':
    case 'Y':
      showDirections = !showDirections;
      break;
    case 'r':
    case 'R':
      showConnections = !showConnections;
      break;
    case 'd':
    case 'D':
      showInfo = !showInfo;
      break;
    case 'h':
    case 'H':
      showHelp = !showHelp;
      break;
    case '1':
      currentTheme = 0;
      break;
    case '2':
      currentTheme = 1;
      break;
    case '3':
      currentTheme = 2;
      break;
  }
}

// ==================== ACTIONS ====================

void resetSimulation() {
  boolean hadSun = false;
  for (Mass m : masses) {
    if (m.isSun) {
      hadSun = true;
      break;
    }
  }
  
  masses.clear();
  
  if (hadSun) {
    sun = new Mass(width/2, height/2, 80, themes[currentTheme].sunColor, true);
    sun.velocity.set(0, 0);
    masses.add(sun);
  }
  
  startTime = millis();
}

void addSun() {
  boolean exists = false;
  for (Mass m : masses) {
    if (m.isSun) {
      exists = true;
      break;
    }
  }
  
  if (!exists) {
    sun = new Mass(width/2, height/2, 80, themes[currentTheme].sunColor, true);
    sun.velocity.set(0, 0);
    masses.add(sun);
  }
}

void removeSun() {
  for (int i = masses.size() - 1; i >= 0; i--) {
    if (masses.get(i).isSun) {
      masses.remove(i);
    }
  }
}

// ==================== SCENARIO SAVE/LOAD ====================

void saveScenario(String filename) {
  JSONObject scenario = new JSONObject();
  scenario.setString("name", filename);
  scenario.setString("timestamp", year() + "-" + month() + "-" + day() + "T" + hour() + ":" + minute() + ":" + second());
  
  JSONObject settings = new JSONObject();
  settings.setBoolean("paused", paused);
  settings.setBoolean("grid", showGrid);
  settings.setBoolean("trails", showTrails);
  settings.setBoolean("gravityField", showGravityField);
  settings.setBoolean("directions", showDirections);
  settings.setBoolean("connections", showConnections);
  settings.setBoolean("sunLocked", sunLocked);
  settings.setBoolean("bounceMode", bounceMode);
  settings.setInt("theme", currentTheme);
  scenario.setJSONObject("settings", settings);
  
  JSONArray massArray = new JSONArray();
  int i = 0;
  for (Mass m : masses) {
    JSONObject massObj = new JSONObject();
    massObj.setFloat("x", m.position.x);
    massObj.setFloat("y", m.position.y);
    massObj.setFloat("vx", m.velocity.x);
    massObj.setFloat("vy", m.velocity.y);
    massObj.setFloat("radius", m.radius);
    massObj.setBoolean("isSun", m.isSun);
    massArray.setJSONObject(i++, massObj);
  }
  scenario.setJSONArray("masses", massArray);
  
  saveJSONObject(scenario, filename + ".json");
  println("Scenario saved: " + filename + ".json");
}

void loadScenario(String filename) {
  try {
    JSONObject scenario = loadJSONObject(filename);
    
    JSONObject settings = scenario.getJSONObject("settings");
    paused = settings.getBoolean("paused");
    showGrid = settings.getBoolean("grid");
    showTrails = settings.getBoolean("trails");
    showGravityField = settings.getBoolean("gravityField");
    showDirections = settings.getBoolean("directions");
    showConnections = settings.getBoolean("connections");
    sunLocked = settings.getBoolean("sunLocked");
    bounceMode = settings.getBoolean("bounceMode");
    currentTheme = settings.getInt("theme");
    
    masses.clear();
    JSONArray massArray = scenario.getJSONArray("masses");
    for (int i = 0; i < massArray.size(); i++) {
      JSONObject massObj = massArray.getJSONObject(i);
      float x = massObj.getFloat("x");
      float y = massObj.getFloat("y");
      float r = massObj.getFloat("radius");
      boolean isS = massObj.getBoolean("isSun");
      
      Mass m = new Mass(x, y, r, isS ? themes[currentTheme].sunColor : color(random(100, 255), random(100, 255), random(100, 255)), isS);
      m.velocity.set(massObj.getFloat("vx"), massObj.getFloat("vy"));
      masses.add(m);
      
      if (isS) sun = m;
    }
    
    println("Scenario loaded: " + filename);
  } catch (Exception e) {
    println("Error loading scenario: " + e.getMessage());
  }
}