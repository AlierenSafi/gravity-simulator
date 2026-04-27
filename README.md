# Gravity Simulator

[![Processing](https://img.shields.io/badge/Processing-3.x%20|%204.x-006699?style=flat-square&logo=processing&logoColor=white)](https://processing.org)
[![License](https://img.shields.io/badge/License-MIT-green?style=flat-square)](LICENSE)

A physics-based gravitational interaction simulation built with Processing. Create masses, launch them into orbit, and observe gravitational interactions, collisions, and orbital dynamics.

---

## Overview

This simulation demonstrates Newton's law of universal gravitation in an interactive environment. Users can create masses with initial velocities and observe how they interact through gravitational forces, form stable orbits, collide, or merge depending on the selected collision mode.

---

## Features

### Physics Engine
- Real-time gravitational force calculations between all bodies
- Two collision modes:
  - Bounce: Elastic collisions with momentum conservation
  - Merge: Inelastic collisions where masses combine
- Optional sun lock for stable central mass
- Trail visualization for tracking movement history
- Gravity field visualization with color-coded intensity

### Visualization
- Three display themes: Default, Dark Space, and Minimal
- Toggleable grid overlay
- Velocity vector arrows
- Connection lines between gravitationally bound masses
- Real-time statistics (FPS, mass count, runtime)

---

## Screenshots

### Orbital Simulation
![Orbital Simulation](screenshot%201.png)

### Gravity Field Visualization
![Gravity Fields](screenshot%20gravity%20fields.png)

---

## Requirements

- [Processing 3.x or 4.x](https://processing.org/download)
- No additional libraries required

**System Requirements:**
- OS: Windows, macOS, or Linux
- RAM: 2GB minimum
- Graphics: OpenGL-compatible GPU

---

## Installation

1. Download and install Processing from [processing.org](https://processing.org)
2. Clone this repository or download as ZIP
3. Open `gravity_simulator.pde` in Processing
4. Click the Run button

```bash
git clone https://github.com/AlierenSafi/gravity-simulator.git
```

---

## Usage

### Basic Controls
- **Left Click + Drag**: Create a mass with initial velocity
- **Right Click + Drag**: Launch a cluster of 8 masses

### Keyboard Shortcuts

| Key | Action |
|-----|--------|
| P | Pause/Resume simulation |
| K | Reset simulation |
| N | Add central sun mass |
| M | Remove sun |
| T | Toggle sun lock |
| S | Toggle collision mode (Bounce/Merge) |
| G | Toggle grid |
| I | Toggle trails |
| O | Toggle gravity field |
| Y | Toggle velocity arrows |
| R | Toggle connection lines |
| D | Toggle info panel |
| H | Toggle help panel |
| 1-3 | Switch themes |

---

## Physics Parameters

| Parameter | Value | Description |
|-----------|-------|-------------|
| Gravity Constant | 0.7 | Strength of gravitational attraction |
| Trail Length | 300 | Position history points |
| Grid Size | 5px | Gravity field resolution |
| Max Mass | 10000 | Upper mass limit |

---

## Scenario System

Save and load simulation states:

```java
// Save current simulation
saveScenario("my-scenario");

// Load saved simulation
loadScenario("my-scenario.json");
```

Scenarios preserve mass positions, velocities, and simulation settings.

---

## Technical Details

### Gravitational Force
```
F = G * (m1 * m2) / r^2
```

### Collision Detection
- Circle-circle collision detection
- Elastic collision response with momentum conservation
- Optional mass merging for inelastic collisions

---

##  License

This project is licensed under the MIT License. See [LICENSE](LICENSE) for details.

---

Built with [Processing](https://processing.org), a flexible software sketchbook for visual arts and coding.
