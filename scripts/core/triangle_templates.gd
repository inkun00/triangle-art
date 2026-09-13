class_name TriangleTemplates
extends RefCounted

## Curated educational triangle artwork templates for Triangle Art.

static func get_template_names() -> Array[String]:
	return [
		"물고기 (Fish)",
		"요트 (Sailboat)",
		"고양이 (Cat)",
		"로켓 (Rocket)",
		"집과 나무 (House)",
		"나비 (Butterfly)",
		"여우 (Fox)",
		"산과 해 (Mountains & Sun)"
	]

static func get_template_data(template_name: String, center_pos: Vector2 = Vector2(800, 450)) -> Array[Dictionary]:
	var list: Array[Dictionary] = []
	match template_name:
		"물고기 (Fish)":
			# 1. Main body (pointing right)
			list.append({
				"pos": center_pos + Vector2(-20, 0),
				"a": Vector2(90, 0),
				"b": Vector2(-60, -60),
				"c": Vector2(-60, 60),
				"color": Color("#3B82F6") # Blue
			})
			# 2. Tail fin
			list.append({
				"pos": center_pos + Vector2(-110, 0),
				"a": Vector2(30, 0),
				"b": Vector2(-50, -50),
				"c": Vector2(-50, 50),
				"color": Color("#F97316") # Orange
			})
			# 3. Top dorsal fin
			list.append({
				"pos": center_pos + Vector2(-30, -75),
				"a": Vector2(0, -40),
				"b": Vector2(-35, 15),
				"c": Vector2(35, 15),
				"color": Color("#FACC15") # Yellow
			})
			# 4. Eye/face accent
			list.append({
				"pos": center_pos + Vector2(25, -15),
				"a": Vector2(15, -10),
				"b": Vector2(-15, -10),
				"c": Vector2(0, 15),
				"color": Color("#FFFFFF") # White
			})

		"요트 (Sailboat)":
			# 1. Large main sail
			list.append({
				"pos": center_pos + Vector2(-10, -70),
				"a": Vector2(0, -110),
				"b": Vector2(-70, 40),
				"c": Vector2(0, 40),
				"color": Color("#EF4444") # Red
			})
			# 2. Small front sail
			list.append({
				"pos": center_pos + Vector2(40, -50),
				"a": Vector2(0, -70),
				"b": Vector2(0, 20),
				"c": Vector2(50, 20),
				"color": Color("#FACC15") # Yellow
			})
			# 3. Boat hull left
			list.append({
				"pos": center_pos + Vector2(-55, 30),
				"a": Vector2(-50, -20),
				"b": Vector2(45, -20),
				"c": Vector2(10, 30),
				"color": Color("#3B82F6") # Blue
			})
			# 4. Boat hull right
			list.append({
				"pos": center_pos + Vector2(35, 30),
				"a": Vector2(-45, -20),
				"b": Vector2(50, -20),
				"c": Vector2(-10, 30),
				"color": Color("#06B6D4") # Cyan
			})

		"고양이 (Cat)":
			# 1. Head (center inverted triangle)
			list.append({
				"pos": center_pos + Vector2(0, -20),
				"a": Vector2(-80, -50),
				"b": Vector2(80, -50),
				"c": Vector2(0, 60),
				"color": Color("#F97316") # Orange
			})
			# 2. Left ear
			list.append({
				"pos": center_pos + Vector2(-55, -95),
				"a": Vector2(-25, -45),
				"b": Vector2(-25, 25),
				"c": Vector2(25, 25),
				"color": Color("#EA580C")
			})
			# 3. Right ear
			list.append({
				"pos": center_pos + Vector2(55, -95),
				"a": Vector2(25, -45),
				"b": Vector2(-25, 25),
				"c": Vector2(25, 25),
				"color": Color("#EA580C")
			})
			# 4. Body
			list.append({
				"pos": center_pos + Vector2(0, 80),
				"a": Vector2(0, -40),
				"b": Vector2(-90, 70),
				"c": Vector2(90, 70),
				"color": Color("#FB923C")
			})

		"로켓 (Rocket)":
			# 1. Nose cone
			list.append({
				"pos": center_pos + Vector2(0, -110),
				"a": Vector2(0, -70),
				"b": Vector2(-40, 30),
				"c": Vector2(40, 30),
				"color": Color("#EF4444") # Red
			})
			# 2. Main body upper
			list.append({
				"pos": center_pos + Vector2(0, -30),
				"a": Vector2(0, -50),
				"b": Vector2(-50, 40),
				"c": Vector2(50, 40),
				"color": Color("#F8FAFC") # White
			})
			# 3. Left wing fin
			list.append({
				"pos": center_pos + Vector2(-65, 30),
				"a": Vector2(15, -40),
				"b": Vector2(-45, 35),
				"c": Vector2(15, 35),
				"color": Color("#3B82F6") # Blue
			})
			# 4. Right wing fin
			list.append({
				"pos": center_pos + Vector2(65, 30),
				"a": Vector2(-15, -40),
				"b": Vector2(-15, 35),
				"c": Vector2(45, 35),
				"color": Color("#3B82F6") # Blue
			})
			# 5. Flame thrust
			list.append({
				"pos": center_pos + Vector2(0, 60),
				"a": Vector2(-30, -10),
				"b": Vector2(30, -10),
				"c": Vector2(0, 50),
				"color": Color("#FACC15") # Yellow flame
			})

		"집과 나무 (House)":
			# 1. House roof
			list.append({
				"pos": center_pos + Vector2(-60, -40),
				"a": Vector2(0, -60),
				"b": Vector2(-90, 30),
				"c": Vector2(90, 30),
				"color": Color("#DC2626") # Red roof
			})
			# 2. House body left triangle
			list.append({
				"pos": center_pos + Vector2(-105, 35),
				"a": Vector2(-45, -45),
				"b": Vector2(-45, 45),
				"c": Vector2(45, 45),
				"color": Color("#FDE047") # Yellow wall
			})
			# 3. House body right triangle
			list.append({
				"pos": center_pos + Vector2(-15, 35),
				"a": Vector2(-45, -45),
				"b": Vector2(45, -45),
				"c": Vector2(45, 45),
				"color": Color("#FACC15") # Yellow wall
			})
			# 4. Pine tree top
			list.append({
				"pos": center_pos + Vector2(110, -40),
				"a": Vector2(0, -50),
				"b": Vector2(-45, 20),
				"c": Vector2(45, 20),
				"color": Color("#10B981") # Green
			})
			# 5. Pine tree bottom
			list.append({
				"pos": center_pos + Vector2(110, 10),
				"a": Vector2(0, -40),
				"b": Vector2(-60, 35),
				"c": Vector2(60, 35),
				"color": Color("#059669") # Dark green
			})

		"나비 (Butterfly)":
			# 1. Upper body (chest/head)
			list.append({
				"pos": center_pos + Vector2(0, -20),
				"a": Vector2(0, -35),
				"b": Vector2(-12, 15),
				"c": Vector2(12, 15),
				"color": Color("#374151") # Charcoal
			})
			# 2. Lower body (abdomen)
			list.append({
				"pos": center_pos + Vector2(0, 25),
				"a": Vector2(-10, -20),
				"b": Vector2(10, -20),
				"c": Vector2(0, 35),
				"color": Color("#1F2937") # Dark gray
			})
			# 3. Left Forewing (large upper)
			list.append({
				"pos": center_pos + Vector2(-65, -45),
				"a": Vector2(45, 30),
				"b": Vector2(-65, -60),
				"c": Vector2(-30, 45),
				"color": Color("#8B5CF6") # Purple
			})
			# 4. Right Forewing (large upper)
			list.append({
				"pos": center_pos + Vector2(65, -45),
				"a": Vector2(-45, 30),
				"b": Vector2(65, -60),
				"c": Vector2(30, 45),
				"color": Color("#8B5CF6") # Purple
			})
			# 5. Left Hindwing (lower)
			list.append({
				"pos": center_pos + Vector2(-55, 40),
				"a": Vector2(35, -25),
				"b": Vector2(-50, -5),
				"c": Vector2(-10, 50),
				"color": Color("#EC4899") # Pink
			})
			# 6. Right Hindwing (lower)
			list.append({
				"pos": center_pos + Vector2(55, 40),
				"a": Vector2(-35, -25),
				"b": Vector2(50, -5),
				"c": Vector2(10, 50),
				"color": Color("#EC4899") # Pink
			})
			# 7. Left Wing Accent
			list.append({
				"pos": center_pos + Vector2(-55, -25),
				"a": Vector2(25, 10),
				"b": Vector2(-30, -30),
				"c": Vector2(-10, 20),
				"color": Color("#FDE047") # Yellow
			})
			# 8. Right Wing Accent
			list.append({
				"pos": center_pos + Vector2(55, -25),
				"a": Vector2(-25, 10),
				"b": Vector2(30, -30),
				"c": Vector2(10, 20),
				"color": Color("#FDE047") # Yellow
			})

		"여우 (Fox)":
			# 1. Head Face
			list.append({
				"pos": center_pos + Vector2(0, -10),
				"a": Vector2(-60, -50),
				"b": Vector2(60, -50),
				"c": Vector2(0, 40),
				"color": Color("#F97316") # Orange
			})
			# 2. Left Ear
			list.append({
				"pos": center_pos + Vector2(-50, -85),
				"a": Vector2(-30, -45),
				"b": Vector2(-15, 25),
				"c": Vector2(25, 25),
				"color": Color("#EA580C") # Dark Orange
			})
			# 3. Right Ear
			list.append({
				"pos": center_pos + Vector2(50, -85),
				"a": Vector2(30, -45),
				"b": Vector2(-25, 25),
				"c": Vector2(15, 25),
				"color": Color("#EA580C") # Dark Orange
			})
			# 4. Snout / Muzzle
			list.append({
				"pos": center_pos + Vector2(0, 15),
				"a": Vector2(-25, -15),
				"b": Vector2(25, -15),
				"c": Vector2(0, 25),
				"color": Color("#FFFFFF") # White
			})
			# 5. Body
			list.append({
				"pos": center_pos + Vector2(-25, 80),
				"a": Vector2(25, -40),
				"b": Vector2(-60, 60),
				"c": Vector2(50, 60),
				"color": Color("#C2410C") # Rust
			})
			# 6. Belly
			list.append({
				"pos": center_pos + Vector2(10, 75),
				"a": Vector2(-10, -35),
				"b": Vector2(15, 65),
				"c": Vector2(-35, 65),
				"color": Color("#FED7AA") # Peach
			})
			# 7. Tail Main
			list.append({
				"pos": center_pos + Vector2(75, 50),
				"a": Vector2(-40, 25),
				"b": Vector2(40, -40),
				"c": Vector2(25, 45),
				"color": Color("#EA580C") # Tail Orange
			})
			# 8. Tail Tip
			list.append({
				"pos": center_pos + Vector2(110, 15),
				"a": Vector2(-15, 10),
				"b": Vector2(15, -20),
				"c": Vector2(5, 20),
				"color": Color("#FFFFFF") # White tip
			})

		"산과 해 (Mountains & Sun)":
			# 1. Sun
			list.append({
				"pos": center_pos + Vector2(110, -100),
				"a": Vector2(0, -45),
				"b": Vector2(-40, 30),
				"c": Vector2(40, 30),
				"color": Color("#FBBF24") # Sun Yellow
			})
			# 2. High Mountain
			list.append({
				"pos": center_pos + Vector2(20, -30),
				"a": Vector2(0, -110),
				"b": Vector2(-130, 80),
				"c": Vector2(120, 80),
				"color": Color("#475569") # Slate Mountain
			})
			# 3. Mountain Peak Shadow/Snow
			list.append({
				"pos": center_pos + Vector2(20, -65),
				"a": Vector2(0, -75),
				"b": Vector2(-45, 0),
				"c": Vector2(0, 0),
				"color": Color("#94A3B8") # Snow Peak
			})
			# 4. Front Mountain Left
			list.append({
				"pos": center_pos + Vector2(-95, 20),
				"a": Vector2(0, -90),
				"b": Vector2(-110, 70),
				"c": Vector2(90, 70),
				"color": Color("#0D9488") # Teal
			})
			# 5. Front Mountain Right
			list.append({
				"pos": center_pos + Vector2(110, 35),
				"a": Vector2(0, -75),
				"b": Vector2(-80, 55),
				"c": Vector2(100, 55),
				"color": Color("#10B981") # Emerald
			})
			# 6. Valley / Lake
			list.append({
				"pos": center_pos + Vector2(0, 105),
				"a": Vector2(-180, 0),
				"b": Vector2(180, 0),
				"c": Vector2(0, 35),
				"color": Color("#06B6D4") # Cyan water
			})

	return list
