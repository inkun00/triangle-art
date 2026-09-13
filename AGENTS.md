# Triangle Art - Godot 4 Agent Guide

This project is built with **Godot 4.x (GDScript)**.
Triangle Art is a digital geometric art game where players create drawings using only triangles.

## Core Principles
1. **Source of Truth**:
   - Every triangle's geometry is defined strictly by its 3 vertices (`vertex_a`, `vertex_b`, `vertex_c`) in local space, plus the node's `position`.
   - Never store side lengths or angles as independent authoritative state; they are always computed from the vertices via `TriangleMath`.
2. **Architecture**:
   - **Math & Geometry**: Isolated in `scripts/core/triangle_math.gd`. No UI dependencies.
   - **Undo/Redo**: Managed via `scripts/core/command_manager.gd`. Every modification (add, move, drag vertex, change color, duplicate, delete) uses the command pattern.
   - **Rendering**: Handled by `scenes/triangle/triangle_node.gd` using `_draw()` for high performance, smooth vector drawing, antialiasing, handles, and measurement overlays.
   - **Canvas**: `scenes/canvas/drawing_canvas.gd` manages grid, active selection, layers, and coordinate conversion.
   - **UI Separation**: UI controls (`scenes/ui/`) dispatch commands to the canvas or active triangle. UI never mutates geometry directly.
   - **PNG Export**: Produces a clean render of triangles without grid, selection handles, measurement text, or UI.

## GDScript Guidelines
- Use explicit static typing (`Vector2`, `float`, `int`, `Array[Vector2]`, `Color`, `bool`).
- Use `@tool` only when editor preview is strictly necessary.
- Signals should be strongly typed: `signal triangle_selected(triangle: TriangleNode)`.

## Verification Loop
Before finishing any modification:
1. Run headless test suite: `powershell -File tools/run_tests.ps1`
2. Verify zero GDScript syntax or runtime errors.
3. Validate geometry constraints (angle sum ~180°, no collapsed collinear triangles).
