---
name: godot-testing
description: Runs headless Godot unit and integration tests, reporting test results and detecting regressions.
---

# Godot Testing Skill

To run tests:
1. Execute the headless test runner:
   `powershell -ExecutionPolicy Bypass -File tools/run_tests.ps1`
2. Ensure exit code is 0 and all test assertions pass.
3. Test runner is located at `res://tests/test_runner.tscn`.
4. When writing new tests, inherit or utilize assertions from `tests/test_runner.gd`.
