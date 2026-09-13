---
name: triangle-interaction
description: Handles selection, body drag, vertex handle manipulation, snapping, duplication, and Undo/Redo commands.
---

# Triangle Interaction Skill

When working on interactions:
1. Every state mutation must be wrapped in a Command object for Undo/Redo support.
2. Clicking inside a triangle selects it; clicking outside deselects it.
3. Dragging a vertex handle only moves that vertex; dragging the body moves all 3 vertices equally by updating `position`.
4. Snapping logic snaps vertices to the nearest grid intersection when snap is enabled.
5. Duplicating a triangle produces an exact replica with an offset (`Vector2(20, 20)`).
6. Always run interaction tests after altering selection or drag mechanics.
