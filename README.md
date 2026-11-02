# Bash 2048

A simple terminal-based version of the classic **2048** game built entirely in **Bash**. This project was created to explore game development and state management using shell scripting while keeping the gameplay experience similar to the original 2048.

## Features

* Play 2048 directly from the terminal
* Supports board sizes from **3×3 to 9×9**
* Customizable target tile (2048, 4096, etc.)
* Save and reload games
* Score tracking and game timer
* Colored terminal interface
* Supports both **WASD** and **Arrow Key** controls

## Getting Started

Make the script executable and run it:

```bash id="7t2l1o"
chmod +x bash2048.sh
./bash2048.sh
```

Or simply:

```bash id="b4qqzu"
bash bash2048.sh
```

## Controls

| Key   | Action     |
| ----- | ---------- |
| W / ↑ | Move Up    |
| A / ← | Move Left  |
| S / ↓ | Move Down  |
| D / → | Move Right |

## Options

Run with a larger board:

```bash id="7c7e85"
./bash2048.sh -b 5
```

Change the winning tile:

```bash id="ql0x5e"
./bash2048.sh -t 4096
```

Reload a saved game:

```bash id="a14kve"
./bash2048.sh -r
```

View all available options:

```bash id="p6n0t4"
./bash2048.sh -h
```

## Implementation Details

The game uses Bash arrays to store the board state and implements the complete 2048 game logic, including:

* Tile movement and merging
* Random tile generation
* Move validation
* Win/loss detection
* Persistent save and reload functionality

The project also includes atomic save operations to prevent save-file corruption and supports configurable gameplay settings through command-line arguments.

## Author

**Raithu Reddy**
