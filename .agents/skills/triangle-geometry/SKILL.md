---
name: triangle-geometry
description: Handles triangle geometry, side lengths, angles, grid units, triangle validation and classification.
---

# Triangle Geometry Skill

When modifying or verifying triangle geometry:
1. `vertex_a`, `vertex_b`, `vertex_c` are the ONLY source of truth.
2. Never store side lengths or angles as independent authoritative state.
3. Compute angles using vector dot products (`acos(clamp(v1.dot(v2) / (len1 * len2), -1.0, 1.0))`).
4. Ensure the sum of internal angles equals exactly 180° when displaying integer degrees.
5. Grid distance is computed as `pixel_distance / grid_step`.
6. Enforce minimum area threshold to prevent degenerate/collinear triangles.
7. Always run `test_triangle_math.gd` after making any geometric changes.
