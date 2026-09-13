# Godot 4 Development Rules

1. Always use typed GDScript (`var pos: Vector2`, `func calculate_area() -> float:`).
2. Separate pure computational logic from Node and UI lifecycles.
3. Node2D custom drawing should be done in `_draw()` and updated with `queue_redraw()`.
4. Ensure coordinate space clarity: local node space vs global canvas space.
5. All tests must be runnable in Godot `--headless` mode.
