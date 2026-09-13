# 🕹️ Pop Push

<p align="left">
  <a href="https://javierrhp.itch.io/pop-push"><img src="https://img.shields.io/badge/Itch.io-Play%20%2F%20Download-FA5C5C?style=for-the-badge&logo=itch.io&logoColor=white" alt="Itch.io"></a>
  <img src="https://img.shields.io/badge/Language-Z80%20Assembly-00599C?style=for-the-badge&logo=assembly&logoColor=white" alt="Z80 Assembly">
  <img src="https://img.shields.io/badge/Platform-Game%20Boy%20(DMG)-YG8400?style=for-the-badge&logo=nintendo&logoColor=white" alt="Game Boy">
</p>

**Project Role:** `Gameplay Programmer` | `Custom Physics & Systems Engineer`  
**Tech Stack:** `Game Boy (Z80 / LR35902)` | `Z80 Assembly` | `RGBDS` 

<img src="https://img.itch.zone/aW1nLzIzODczMDQ4LnBuZw==/original/gBCD6O.png" alt="Pop Push Banner" width="500" height="250" style="object-fit: cover; border-radius: 6px;"/>

---

## 🎮 Game Overview

Developed in pure **Z80 Assembly (.asm)** during the **GBRetroDev** jam, **Pop Push** is a fast-paced skill arcade game built for the original **Nintendo Game Boy (DMG)**. Inspired by titles like *Don't Touch the Spikes*, the game focuses on minimalism, tight rhythm-based timing, and high arcade replayability.

The engine reuses and refines a modular bare-metal Z80 architecture, implementing **custom arcade physics, gravity accumulation, bounce dynamics, sub-pixel impulses, and physical SRAM save writes** directly on 8-bit registers.

👉 **[Play / Download Pop Push on itch.io](https://javierrhp.itch.io/pop-push)**

---

## 🧠 Design Focus & Core Loop

Designed around a **One-Button Arcade Philosophy**:
* **Bounce Mechanics:** Continuous horizontal rebounds between side walls.
* **Dynamic Hazards:** Precise dodge timing to avoid dynamic heat hazards/spikes.
* **Rhythm Input:** Single-button impulse timing to control gravity and vertical velocity.
* **High-Score Chase:** Persistent local high-score tracking across play sessions.

---

## 🏎️ Core Technical Highlights

* **⚽ Custom Z80 Physics Engine:** Developed proprietary gravity, velocity, and impulse integration using 8-bit binary arithmetic without floating-point support.
* **📐 Real-Time Collision & Bounce Dynamics:** Precise AABB spatial overlap checks handling instantaneous wall-rebound velocity inversions and floor/ceiling boundaries.
* **🌵 Dynamic Procedural Hazards:** Spike spawner system that randomizes hazard positions along walls upon every successful rebound.
* **🔄 Reusable Z80 Architecture:** Re-engineered core assembly modules, RAM memory-pooling layouts, and VRAM subroutines for high execution efficiency.

---

## 🛠️ Deep-Dive Systems & Technical Architecture

### ⚽ Proprietary 8-Bit Physics & Impulse Integration
* **Accumulated Gravity & Velocity:** Custom gravity steps applied to vertical velocity vectors (`Y-Velocity`) on every frame interrupt.
* **One-Button Impulse Calculations:** Input-triggered jump impulses modify directional momentum instantly, creating fluid arcade controls within binary hardware limitations.
* **Wall Rebound Dynamics:** Precise horizontal velocity (`X-Velocity`) inversion upon wall contact, updating orientation and movement vectors instantly.

### 🌵 Procedural Spikes & Dynamic Collision Pipeline
* **Randomized Hazard Spawning:** Pseudo-random seed generators that determine spike positions dynamically upon each wall bounce.
* **Precise AABB Overlap Detection:** Optimized bounding-box collision system checking character coordinates against dynamic hazard tables every frame.

---

## 🛠️ Technical Toolkit

| Category | Tool / Spec |
| :--- | :--- |
| **Language** | Z80 Assembly (`.asm` / Sharp LR35902 ISA) |
| **Assembler Toolchain** | RGBDS  |
| **Target Hardware** | Nintendo Game Boy (DMG-01 / CGB backwards compatible) |
| **Debugging & Testing** | BGB / (Register inspection, SRAM memory viewer) |

---

## ✉️ Contact & Links

<p align="left">
   <a href="mailto:herreroponcejavier@gmail.com"><img src="https://img.shields.io/badge/Email-D14836?style=for-the-badge&logo=gmail&logoColor=white" alt="Email"></a>
   <a href="https://javierrhp.itch.io//"><img src="https://img.shields.io/badge/Itch.io-FA5C5C?style=for-the-badge&logo=itchdotio&logoColor=white" alt="Itch.io"></a>
   <a href="https://www.linkedin.com/in/javier-herrero-ponce-0349a3345/"><img src="https://img.shields.io/badge/LinkedIn-0077B5?style=for-the-badge&logo=linkedin&logoColor=white" alt="LinkedIn"></a>
   <a href="https://www.artstation.com/javierrhp"><img src="https://img.shields.io/badge/ArtStation-131313?style=for-the-badge&logo=artstation&logoColor=white" alt="ArtStation"></a>
</p>

---
