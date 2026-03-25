## Introduction ##
A simple paint program made in ARM64 assembly on apple silicon.
This project was created for learning purposes and I don't think i will be updating it much.

Consist of two tools:
 - Brush (b)
 - Eraser (e)

12 colors picked from the pico-8 color palette that are binded to keybinds:
- 1
- 2
- 3
- 4
- 5
- y
- x
- c
- v
- z
- r
- a
- g

## Installing ##

-- Prerequisites --
- ARM64 Assembly
- clang

1. Clone the repository
2. In the repository directory run: clang -arch arm64 <path (can be just ./ZPaint)> -o ZPaint -lobjc -framework AppKit -framework CoreGraphics -framework Foundation
3. Run ./ZPaint
