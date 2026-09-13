class_name TriangleTemplates
extends RefCounted

## 30 Curated educational triangle artwork templates for Triangle Art,
## organized into 3 progressive difficulty levels (초급, 중급, 고급).

static func get_all_template_metadata() -> Array[Dictionary]:
	return [
		# --- 1단계: 초급 (단순한 도안, 3~5조각) ---
		{"name": "물고기 (Fish)", "stage": 1, "stage_name": "1단계: 초급", "pieces": 4, "tag": "바다 동물", "desc": "파란 몸통과 주황 꼬리지느러미가 매력적인 귀여운 물고기예요."},
		{"name": "요트 (Sailboat)", "stage": 1, "stage_name": "1단계: 초급", "pieces": 4, "tag": "탈것", "desc": "파도를 가르며 시원하게 달리는 멋진 요트예요."},
		{"name": "나무 (Tree)", "stage": 1, "stage_name": "1단계: 초급", "pieces": 4, "tag": "자연", "desc": "초록 잎이 3단으로 쌓인 싱그러운 전나무예요."},
		{"name": "집 (House)", "stage": 1, "stage_name": "1단계: 초급", "pieces": 4, "tag": "건축", "desc": "빨간 지붕과 굴뚝이 있는 아늑하고 따뜻한 집이에요."},
		{"name": "산 (Mountains)", "stage": 1, "stage_name": "1단계: 초급", "pieces": 4, "tag": "자연", "desc": "새하얀 눈이 덮인 웅장한 쌍둥이 산봉우리예요."},
		{"name": "버섯 (Mushroom)", "stage": 1, "stage_name": "1단계: 초급", "pieces": 4, "tag": "식물", "desc": "동화 속에 나오는 앙증맞고 귀여운 붉은 모자 버섯이에요."},
		{"name": "바람개비 (Pinwheel)", "stage": 1, "stage_name": "1단계: 초급", "pieces": 4, "tag": "장난감", "desc": "바람이 불면 빙글빙글 돌아가는 알록달록 바람개비예요."},
		{"name": "화살표 (Arrow)", "stage": 1, "stage_name": "1단계: 초급", "pieces": 4, "tag": "기호", "desc": "앞으로 힘차게 나아가는 미래지향적인 기하 화살표예요."},
		{"name": "우산 (Umbrella)", "stage": 1, "stage_name": "1단계: 초급", "pieces": 4, "tag": "사물", "desc": "비 오는 날 나를 지켜주는 예쁜 삼색 우산이에요."},
		{"name": "텐트 (Camping Tent)", "stage": 1, "stage_name": "1단계: 초급", "pieces": 3, "tag": "캠핑", "desc": "별빛 아래 자연을 즐길 수 있는 신나는 삼각 텐트예요."},

		# --- 2단계: 중급 (재미있는 도안, 6~8조각) ---
		{"name": "고양이 (Cat)", "stage": 2, "stage_name": "2단계: 중급", "pieces": 7, "tag": "동물", "desc": "귀를 쫑긋 세우고 호기심 가득 바라보는 주황 아기고양이에요."},
		{"name": "여우 (Fox)", "stage": 2, "stage_name": "2단계: 중급", "pieces": 7, "tag": "동물", "desc": "풍성한 꼬리와 날렵한 눈매를 가진 매력적인 붉은 여우예요."},
		{"name": "나비 (Butterfly)", "stage": 2, "stage_name": "2단계: 중급", "pieces": 6, "tag": "곤충", "desc": "꽃밭을 사뿐사뿐 날아다니는 아름다운 대칭 날개 나비예요."},
		{"name": "로켓 (Rocket)", "stage": 2, "stage_name": "2단계: 중급", "pieces": 7, "tag": "우주", "desc": "불꽃을 뿜으며 우주로 날아오르는 멋진 우주 탐사 로켓이에요."},
		{"name": "비행기 (Airplane)", "stage": 2, "stage_name": "2단계: 중급", "pieces": 6, "tag": "탈것", "desc": "하늘 높이 구름을 뚫고 날아가는 날렵한 제트 비행기예요."},
		{"name": "백조 (Swan)", "stage": 2, "stage_name": "2단계: 중급", "pieces": 6, "tag": "새", "desc": "호수 위를 우아하고 고요하게 헤엄치는 아름다운 백조예요."},
		{"name": "풍차 (Windmill)", "stage": 2, "stage_name": "2단계: 중급", "pieces": 6, "tag": "건축", "desc": "푸른 언덕 위에서 바람을 맞으며 돌아가는 네덜란드 풍차예요."},
		{"name": "튤립 (Tulip)", "stage": 2, "stage_name": "2단계: 중급", "pieces": 6, "tag": "꽃", "desc": "봄날 따스한 햇살을 받아 활짝 피어난 화사한 튤립이에요."},
		{"name": "별 (Star)", "stage": 2, "stage_name": "2단계: 중급", "pieces": 8, "tag": "기하", "desc": "밤하늘을 반짝반짝 수놓는 완벽한 대칭의 6각 별이에요."},
		{"name": "왕관 (Crown)", "stage": 2, "stage_name": "2단계: 중급", "pieces": 7, "tag": "왕실", "desc": "황금빛 보석들이 눈부시게 빛나는 위엄 있는 임금님 왕관이에요."},

		# --- 3단계: 고급 (복잡한 도안, 9~12조각) ---
		{"name": "공룡 티라노 (Dinosaur)", "stage": 3, "stage_name": "3단계: 고급", "pieces": 11, "tag": "고생물", "desc": "강한 턱과 늠름한 꼬리를 자랑하는 백악기 최고의 제왕 티라노사우루스예요."},
		{"name": "독수리 (Eagle)", "stage": 3, "stage_name": "3단계: 고급", "pieces": 11, "tag": "새", "desc": "날개깃을 웅장하게 펼치고 창공을 가르는 하늘의 제왕 독수리예요."},
		{"name": "기린 (Giraffe)", "stage": 3, "stage_name": "3단계: 고급", "pieces": 11, "tag": "동물", "desc": "키가 크고 다리가 긴 사바나의 평화로운 친구 기린이에요."},
		{"name": "공작새 (Peacock)", "stage": 3, "stage_name": "3단계: 고급", "pieces": 11, "tag": "새", "desc": "무지갯빛 화려한 부채꼴 깃털을 뽐내는 우아한 공작새예요."},
		{"name": "중세의 성 (Castle)", "stage": 3, "stage_name": "3단계: 고급", "pieces": 10, "tag": "건축", "desc": "높은 첨탑과 웅장한 성벽을 갖춘 동화 속 중세 판타지 성이에요."},
		{"name": "열기구 (Hot Air Balloon)", "stage": 3, "stage_name": "3단계: 고급", "pieces": 9, "tag": "탈것", "desc": "오색찬란한 무늬를 뽐내며 하늘로 두둥실 떠오르는 열기구예요."},
		{"name": "스포츠카 (Sports Car)", "stage": 3, "stage_name": "3단계: 고급", "pieces": 10, "tag": "탈것", "desc": "유선형 차체와 날렵한 스포일러를 장착한 질주하는 스포츠카예요."},
		{"name": "로봇 (Robot)", "stage": 3, "stage_name": "3단계: 고급", "pieces": 11, "tag": "SF", "desc": "최첨단 안테나와 파워풀한 팔다리를 가진 든든한 친구 미래 로봇이에요."},
		{"name": "보석 만다라 (Mandala)", "stage": 3, "stage_name": "3단계: 고급", "pieces": 12, "tag": "기하 예술", "desc": "완벽한 8방향 중심 대칭을 이루는 눈부신 크리스털 보석 만다라예요."},
		{"name": "크리스마스 트리 (Tree)", "stage": 3, "stage_name": "3단계: 고급", "pieces": 12, "tag": "축제", "desc": "반짝이는 꼭대기 별과 선물 상자가 놓인 행복한 크리스마스 트리예요."}
	]

static func get_template_names() -> Array[String]:
	var names: Array[String] = []
	for item in get_all_template_metadata():
		names.append(item["name"])
	return names

static func get_templates_by_stage(stage_num: int) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for item in get_all_template_metadata():
		if int(item.get("stage", 0)) == stage_num:
			result.append(item)
	return result

static func get_template_data(template_name: String, center_pos: Vector2 = Vector2(800, 450)) -> Array[Dictionary]:
	var list: Array[Dictionary] = []
	match template_name:
		# =========================================================================
		# 🟢 1단계: 초급 (1~10)
		# =========================================================================
		"물고기 (Fish)":
			# 1. 몸통
			list.append({"pos": center_pos + Vector2(-20, 0), "a": Vector2(90, 0), "b": Vector2(-60, -60), "c": Vector2(-60, 60), "color": Color("#3B82F6")})
			# 2. 꼬리지느러미
			list.append({"pos": center_pos + Vector2(-110, 0), "a": Vector2(30, 0), "b": Vector2(-50, -50), "c": Vector2(-50, 50), "color": Color("#F97316")})
			# 3. 등지느러미
			list.append({"pos": center_pos + Vector2(-30, -75), "a": Vector2(0, -40), "b": Vector2(-35, 15), "c": Vector2(35, 15), "color": Color("#FACC15")})
			# 4. 눈 포인트
			list.append({"pos": center_pos + Vector2(25, -15), "a": Vector2(15, -10), "b": Vector2(-15, -10), "c": Vector2(0, 15), "color": Color("#FFFFFF")})

		"요트 (Sailboat)":
			# 1. 큰 돛
			list.append({"pos": center_pos + Vector2(-10, -70), "a": Vector2(0, -110), "b": Vector2(-70, 40), "c": Vector2(0, 40), "color": Color("#EF4444")})
			# 2. 작은 돛
			list.append({"pos": center_pos + Vector2(40, -50), "a": Vector2(0, -70), "b": Vector2(0, 20), "c": Vector2(50, 20), "color": Color("#FACC15")})
			# 3. 선체 좌
			list.append({"pos": center_pos + Vector2(-55, 30), "a": Vector2(-50, -20), "b": Vector2(45, -20), "c": Vector2(10, 30), "color": Color("#3B82F6")})
			# 4. 선체 우
			list.append({"pos": center_pos + Vector2(35, 30), "a": Vector2(-45, -20), "b": Vector2(50, -20), "c": Vector2(-10, 30), "color": Color("#06B6D4")})

		"나무 (Tree)":
			# 1. 잎 상단
			list.append({"pos": center_pos + Vector2(0, -80), "a": Vector2(0, -50), "b": Vector2(-45, 15), "c": Vector2(45, 15), "color": Color("#22C55E")})
			# 2. 잎 중단
			list.append({"pos": center_pos + Vector2(0, -35), "a": Vector2(0, -50), "b": Vector2(-65, 20), "c": Vector2(65, 20), "color": Color("#16A34A")})
			# 3. 잎 하단
			list.append({"pos": center_pos + Vector2(0, 15), "a": Vector2(0, -55), "b": Vector2(-85, 25), "c": Vector2(85, 25), "color": Color("#15803D")})
			# 4. 나무 기둥
			list.append({"pos": center_pos + Vector2(0, 80), "a": Vector2(-25, -40), "b": Vector2(25, -40), "c": Vector2(0, 40), "color": Color("#854D0E")})

		"집 (House)":
			# 1. 지붕
			list.append({"pos": center_pos + Vector2(0, -60), "a": Vector2(0, -70), "b": Vector2(-90, 20), "c": Vector2(90, 20), "color": Color("#EF4444")})
			# 2. 벽체 좌
			list.append({"pos": center_pos + Vector2(-45, 20), "a": Vector2(-45, -60), "b": Vector2(45, -60), "c": Vector2(-45, 60), "color": Color("#3B82F6")})
			# 3. 벽체 우
			list.append({"pos": center_pos + Vector2(45, 20), "a": Vector2(-45, 60), "b": Vector2(45, -60), "c": Vector2(45, 60), "color": Color("#60A5FA")})
			# 4. 굴뚝
			list.append({"pos": center_pos + Vector2(50, -95), "a": Vector2(-15, 25), "b": Vector2(15, 25), "c": Vector2(0, -35), "color": Color("#F97316")})

		"산 (Mountains)":
			# 1. 큰 산
			list.append({"pos": center_pos + Vector2(-50, 0), "a": Vector2(0, -110), "b": Vector2(-110, 60), "c": Vector2(90, 60), "color": Color("#475569")})
			# 2. 작은 산
			list.append({"pos": center_pos + Vector2(80, 20), "a": Vector2(0, -80), "b": Vector2(-70, 40), "c": Vector2(70, 40), "color": Color("#64748B")})
			# 3. 큰 산 만년설
			list.append({"pos": center_pos + Vector2(-50, -65), "a": Vector2(0, -45), "b": Vector2(-35, 20), "c": Vector2(30, 20), "color": Color("#F8FAFC")})
			# 4. 작은 산 만년설
			list.append({"pos": center_pos + Vector2(80, -25), "a": Vector2(0, -35), "b": Vector2(-25, 15), "c": Vector2(25, 15), "color": Color("#E2E8F0")})

		"버섯 (Mushroom)":
			# 1. 버섯 갓 중앙
			list.append({"pos": center_pos + Vector2(0, -45), "a": Vector2(0, -75), "b": Vector2(-55, 25), "c": Vector2(55, 25), "color": Color("#EF4444")})
			# 2. 갓 좌측
			list.append({"pos": center_pos + Vector2(-60, -25), "a": Vector2(15, -45), "b": Vector2(-45, 20), "c": Vector2(30, 20), "color": Color("#DC2626")})
			# 3. 갓 우측
			list.append({"pos": center_pos + Vector2(60, -25), "a": Vector2(-15, -45), "b": Vector2(-30, 20), "c": Vector2(45, 20), "color": Color("#DC2626")})
			# 4. 버섯 기둥
			list.append({"pos": center_pos + Vector2(0, 45), "a": Vector2(-35, -45), "b": Vector2(35, -45), "c": Vector2(0, 45), "color": Color("#FEF08A")})

		"바람개비 (Pinwheel)":
			# 4 blades radiating from center
			list.append({"pos": center_pos, "a": Vector2(0, 0), "b": Vector2(0, -80), "c": Vector2(60, -40), "color": Color("#EF4444")})
			list.append({"pos": center_pos, "a": Vector2(0, 0), "b": Vector2(80, 0), "c": Vector2(40, 60), "color": Color("#3B82F6")})
			list.append({"pos": center_pos, "a": Vector2(0, 0), "b": Vector2(0, 80), "c": Vector2(-60, 40), "color": Color("#10B981")})
			list.append({"pos": center_pos, "a": Vector2(0, 0), "b": Vector2(-80, 0), "c": Vector2(-40, -60), "color": Color("#FACC15")})

		"화살표 (Arrow)":
			# Head & Shaft
			list.append({"pos": center_pos + Vector2(50, 0), "a": Vector2(60, 0), "b": Vector2(-40, -60), "c": Vector2(-40, 60), "color": Color("#3B82F6")})
			list.append({"pos": center_pos + Vector2(0, -35), "a": Vector2(10, 0), "b": Vector2(-50, -25), "c": Vector2(0, 25), "color": Color("#60A5FA")})
			list.append({"pos": center_pos + Vector2(0, 35), "a": Vector2(10, 0), "b": Vector2(0, -25), "c": Vector2(-50, 25), "color": Color("#60A5FA")})
			list.append({"pos": center_pos + Vector2(-60, 0), "a": Vector2(50, -30), "b": Vector2(50, 30), "c": Vector2(-50, 0), "color": Color("#1D4ED8")})

		"우산 (Umbrella)":
			# Canopy 3 pieces + Handle
			list.append({"pos": center_pos + Vector2(0, -40), "a": Vector2(0, -70), "b": Vector2(-40, 25), "c": Vector2(40, 25), "color": Color("#F43F5E")})
			list.append({"pos": center_pos + Vector2(-55, -25), "a": Vector2(45, -55), "b": Vector2(-45, 10), "c": Vector2(15, 10), "color": Color("#FB7185")})
			list.append({"pos": center_pos + Vector2(55, -25), "a": Vector2(-45, -55), "b": Vector2(-15, 10), "c": Vector2(45, 10), "color": Color("#FB7185")})
			list.append({"pos": center_pos + Vector2(0, 45), "a": Vector2(-15, -60), "b": Vector2(15, -60), "c": Vector2(0, 40), "color": Color("#0284C7")})

		"텐트 (Camping Tent)":
			# Tent 3 pieces
			list.append({"pos": center_pos + Vector2(-30, 0), "a": Vector2(20, -80), "b": Vector2(-70, 50), "c": Vector2(30, 50), "color": Color("#F97316")})
			list.append({"pos": center_pos + Vector2(40, 0), "a": Vector2(-50, -80), "b": Vector2(-40, 50), "c": Vector2(50, 30), "color": Color("#EA580C")})
			list.append({"pos": center_pos + Vector2(-20, 15), "a": Vector2(0, -40), "b": Vector2(-35, 35), "c": Vector2(35, 35), "color": Color("#FDE047")})

		# =========================================================================
		# 🟡 2단계: 중급 (11~20)
		# =========================================================================
		"고양이 (Cat)":
			list.append({"pos": center_pos + Vector2(0, -20), "a": Vector2(-70, -45), "b": Vector2(70, -45), "c": Vector2(0, 55), "color": Color("#F97316")})
			list.append({"pos": center_pos + Vector2(-50, -90), "a": Vector2(0, -35), "b": Vector2(-30, 25), "c": Vector2(30, 25), "color": Color("#EA580C")})
			list.append({"pos": center_pos + Vector2(50, -90), "a": Vector2(0, -35), "b": Vector2(-30, 25), "c": Vector2(30, 25), "color": Color("#EA580C")})
			list.append({"pos": center_pos + Vector2(0, 65), "a": Vector2(0, -30), "b": Vector2(-75, 55), "c": Vector2(75, 55), "color": Color("#F97316")})
			list.append({"pos": center_pos + Vector2(85, 80), "a": Vector2(-25, 40), "b": Vector2(40, -40), "c": Vector2(10, 40), "color": Color("#C2410C")})
			list.append({"pos": center_pos + Vector2(-35, 115), "a": Vector2(-20, 5), "b": Vector2(20, 5), "c": Vector2(0, -20), "color": Color("#FFFFFF")})
			list.append({"pos": center_pos + Vector2(35, 115), "a": Vector2(-20, 5), "b": Vector2(20, 5), "c": Vector2(0, -20), "color": Color("#FFFFFF")})

		"여우 (Fox)":
			list.append({"pos": center_pos + Vector2(0, -40), "a": Vector2(-60, -30), "b": Vector2(60, -30), "c": Vector2(0, 50), "color": Color("#EA580C")})
			list.append({"pos": center_pos + Vector2(-45, -95), "a": Vector2(-10, -35), "b": Vector2(-35, 25), "c": Vector2(25, 25), "color": Color("#C2410C")})
			list.append({"pos": center_pos + Vector2(45, -95), "a": Vector2(10, -35), "b": Vector2(-25, 25), "c": Vector2(35, 25), "color": Color("#C2410C")})
			list.append({"pos": center_pos + Vector2(0, 40), "a": Vector2(0, -30), "b": Vector2(-60, 50), "c": Vector2(60, 50), "color": Color("#EA580C")})
			list.append({"pos": center_pos + Vector2(75, 45), "a": Vector2(-30, 45), "b": Vector2(50, -40), "c": Vector2(10, 45), "color": Color("#F97316")})
			list.append({"pos": center_pos + Vector2(110, 10), "a": Vector2(-15, 25), "b": Vector2(30, -25), "c": Vector2(5, 25), "color": Color("#FFFFFF")})
			list.append({"pos": center_pos + Vector2(0, 95), "a": Vector2(-30, -5), "b": Vector2(30, -5), "c": Vector2(0, 25), "color": Color("#7C2D12")})

		"나비 (Butterfly)":
			list.append({"pos": center_pos + Vector2(-65, -55), "a": Vector2(55, 45), "b": Vector2(-65, -55), "c": Vector2(-55, 45), "color": Color("#EC4899")})
			list.append({"pos": center_pos + Vector2(65, -55), "a": Vector2(-55, 45), "b": Vector2(65, -55), "c": Vector2(55, 45), "color": Color("#EC4899")})
			list.append({"pos": center_pos + Vector2(-55, 45), "a": Vector2(45, -45), "b": Vector2(-50, 45), "c": Vector2(30, 45), "color": Color("#A855F7")})
			list.append({"pos": center_pos + Vector2(55, 45), "a": Vector2(-45, -45), "b": Vector2(50, 45), "c": Vector2(-30, 45), "color": Color("#A855F7")})
			list.append({"pos": center_pos + Vector2(0, -20), "a": Vector2(0, -45), "b": Vector2(-15, 30), "c": Vector2(15, 30), "color": Color("#FACC15")})
			list.append({"pos": center_pos + Vector2(0, 35), "a": Vector2(-15, -25), "b": Vector2(15, -25), "c": Vector2(0, 45), "color": Color("#EAB308")})

		"로켓 (Rocket)":
			list.append({"pos": center_pos + Vector2(0, -95), "a": Vector2(0, -55), "b": Vector2(-35, 35), "c": Vector2(35, 35), "color": Color("#EF4444")})
			list.append({"pos": center_pos + Vector2(-20, -10), "a": Vector2(20, -50), "b": Vector2(-20, 50), "c": Vector2(20, 50), "color": Color("#E2E8F0")})
			list.append({"pos": center_pos + Vector2(20, -10), "a": Vector2(-20, -50), "b": Vector2(20, 50), "c": Vector2(-20, 50), "color": Color("#CBD5E1")})
			list.append({"pos": center_pos + Vector2(-55, 35), "a": Vector2(35, -40), "b": Vector2(-35, 40), "c": Vector2(35, 40), "color": Color("#3B82F6")})
			list.append({"pos": center_pos + Vector2(55, 35), "a": Vector2(-35, -40), "b": Vector2(-35, 40), "c": Vector2(35, 40), "color": Color("#3B82F6")})
			list.append({"pos": center_pos + Vector2(-15, 95), "a": Vector2(15, -15), "b": Vector2(-20, 40), "c": Vector2(10, 40), "color": Color("#F97316")})
			list.append({"pos": center_pos + Vector2(15, 95), "a": Vector2(-15, -15), "b": Vector2(-10, 40), "c": Vector2(20, 40), "color": Color("#FACC15")})

		"비행기 (Airplane)":
			list.append({"pos": center_pos + Vector2(70, 0), "a": Vector2(60, 0), "b": Vector2(-40, -25), "c": Vector2(-40, 25), "color": Color("#0EA5E9")})
			list.append({"pos": center_pos + Vector2(-30, 0), "a": Vector2(60, -25), "b": Vector2(-60, 0), "c": Vector2(60, 25), "color": Color("#0284C7")})
			list.append({"pos": center_pos + Vector2(0, -65), "a": Vector2(30, 40), "b": Vector2(-70, -40), "c": Vector2(-30, 40), "color": Color("#38BDF8")})
			list.append({"pos": center_pos + Vector2(0, 65), "a": Vector2(30, -40), "b": Vector2(-30, -40), "c": Vector2(-70, 40), "color": Color("#38BDF8")})
			list.append({"pos": center_pos + Vector2(-85, -25), "a": Vector2(25, 25), "b": Vector2(-25, -25), "c": Vector2(-25, 25), "color": Color("#0369A1")})
			list.append({"pos": center_pos + Vector2(-85, 25), "a": Vector2(25, -25), "b": Vector2(-25, -25), "c": Vector2(-25, 25), "color": Color("#0369A1")})

		"백조 (Swan)":
			list.append({"pos": center_pos + Vector2(10, 30), "a": Vector2(70, -20), "b": Vector2(-80, 20), "c": Vector2(60, 20), "color": Color("#F8FAFC")})
			list.append({"pos": center_pos + Vector2(-30, -20), "a": Vector2(40, 30), "b": Vector2(-60, -40), "c": Vector2(-30, 30), "color": Color("#E2E8F0")})
			list.append({"pos": center_pos + Vector2(20, -10), "a": Vector2(30, 20), "b": Vector2(-40, -30), "c": Vector2(-10, 20), "color": Color("#CBD5E1")})
			list.append({"pos": center_pos + Vector2(65, -30), "a": Vector2(-25, 40), "b": Vector2(20, -40), "c": Vector2(30, 30), "color": Color("#F8FAFC")})
			list.append({"pos": center_pos + Vector2(95, -70), "a": Vector2(-15, 15), "b": Vector2(20, -15), "c": Vector2(10, 25), "color": Color("#F8FAFC")})
			list.append({"pos": center_pos + Vector2(120, -65), "a": Vector2(-10, -10), "b": Vector2(15, 0), "c": Vector2(-10, 10), "color": Color("#F97316")})

		"풍차 (Windmill)":
			list.append({"pos": center_pos + Vector2(0, 15), "a": Vector2(-40, -45), "b": Vector2(40, -45), "c": Vector2(-55, 45), "color": Color("#D97706")})
			list.append({"pos": center_pos + Vector2(0, 60), "a": Vector2(-55, 0), "b": Vector2(40, -90), "c": Vector2(55, 0), "color": Color("#B45309")})
			list.append({"pos": center_pos + Vector2(0, -60), "a": Vector2(0, 30), "b": Vector2(-25, -60), "c": Vector2(25, -60), "color": Color("#EF4444")})
			list.append({"pos": center_pos + Vector2(60, -30), "a": Vector2(-30, 0), "b": Vector2(60, -25), "c": Vector2(60, 25), "color": Color("#3B82F6")})
			list.append({"pos": center_pos + Vector2(0, 0), "a": Vector2(0, -30), "b": Vector2(25, 60), "c": Vector2(-25, 60), "color": Color("#10B981")})
			list.append({"pos": center_pos + Vector2(-60, -30), "a": Vector2(30, 0), "b": Vector2(-60, 25), "c": Vector2(-60, -25), "color": Color("#FACC15")})

		"튤립 (Tulip)":
			list.append({"pos": center_pos + Vector2(0, -45), "a": Vector2(0, 45), "b": Vector2(-40, -45), "c": Vector2(40, -45), "color": Color("#E11D48")})
			list.append({"pos": center_pos + Vector2(-35, -55), "a": Vector2(35, 55), "b": Vector2(-25, -35), "c": Vector2(20, -35), "color": Color("#F43F5E")})
			list.append({"pos": center_pos + Vector2(35, -55), "a": Vector2(-35, 55), "b": Vector2(-20, -35), "c": Vector2(25, -35), "color": Color("#F43F5E")})
			list.append({"pos": center_pos + Vector2(0, 40), "a": Vector2(-15, -40), "b": Vector2(15, -40), "c": Vector2(0, 50), "color": Color("#16A34A")})
			list.append({"pos": center_pos + Vector2(-45, 30), "a": Vector2(45, 10), "b": Vector2(-45, -30), "c": Vector2(-15, 40), "color": Color("#22C55E")})
			list.append({"pos": center_pos + Vector2(45, 30), "a": Vector2(-45, 10), "b": Vector2(15, 40), "c": Vector2(45, -30), "color": Color("#22C55E")})

		"별 (Star)":
			# 8 symmetrical triangles forming 6-pointed star
			list.append({"pos": center_pos + Vector2(0, -65), "a": Vector2(0, -45), "b": Vector2(-35, 25), "c": Vector2(35, 25), "color": Color("#FACC15")})
			list.append({"pos": center_pos + Vector2(0, 65), "a": Vector2(0, 45), "b": Vector2(35, -25), "c": Vector2(-35, -25), "color": Color("#FACC15")})
			list.append({"pos": center_pos + Vector2(55, -30), "a": Vector2(40, -25), "b": Vector2(-40, -25), "c": Vector2(0, 45), "color": Color("#EAB308")})
			list.append({"pos": center_pos + Vector2(-55, -30), "a": Vector2(-40, -25), "b": Vector2(0, 45), "c": Vector2(40, -25), "color": Color("#EAB308")})
			list.append({"pos": center_pos + Vector2(55, 30), "a": Vector2(40, 25), "b": Vector2(0, -45), "c": Vector2(-40, 25), "color": Color("#F59E0B")})
			list.append({"pos": center_pos + Vector2(-55, 30), "a": Vector2(-40, 25), "b": Vector2(-40, -25), "c": Vector2(40, -25), "color": Color("#F59E0B")})
			list.append({"pos": center_pos + Vector2(-20, 0), "a": Vector2(20, -35), "b": Vector2(-30, 0), "c": Vector2(20, 35), "color": Color("#FDE047")})
			list.append({"pos": center_pos + Vector2(20, 0), "a": Vector2(-20, -35), "b": Vector2(-20, 35), "c": Vector2(30, 0), "color": Color("#FEF08A")})

		"왕관 (Crown)":
			list.append({"pos": center_pos + Vector2(0, 45), "a": Vector2(-75, -25), "b": Vector2(75, -25), "c": Vector2(-60, 25), "color": Color("#D97706")})
			list.append({"pos": center_pos + Vector2(0, 45), "a": Vector2(-60, 25), "b": Vector2(75, -25), "c": Vector2(60, 25), "color": Color("#B45309")})
			list.append({"pos": center_pos + Vector2(0, -20), "a": Vector2(0, -70), "b": Vector2(-35, 40), "c": Vector2(35, 40), "color": Color("#FACC15")})
			list.append({"pos": center_pos + Vector2(-55, -5), "a": Vector2(-15, -60), "b": Vector2(-35, 25), "c": Vector2(25, 25), "color": Color("#EAB308")})
			list.append({"pos": center_pos + Vector2(55, -5), "a": Vector2(15, -60), "b": Vector2(-25, 25), "c": Vector2(35, 25), "color": Color("#EAB308")})
			list.append({"pos": center_pos + Vector2(-25, 0), "a": Vector2(-15, -15), "b": Vector2(15, -15), "c": Vector2(0, 15), "color": Color("#EF4444")})
			list.append({"pos": center_pos + Vector2(25, 0), "a": Vector2(-15, -15), "b": Vector2(15, -15), "c": Vector2(0, 15), "color": Color("#3B82F6")})

		# =========================================================================
		# 🔴 3단계: 고급 (21~30)
		# =========================================================================
		"공룡 티라노 (Dinosaur)":
			list.append({"pos": center_pos + Vector2(75, -75), "a": Vector2(45, -25), "b": Vector2(-35, -25), "c": Vector2(25, 25), "color": Color("#15803D")})
			list.append({"pos": center_pos + Vector2(70, -40), "a": Vector2(30, -10), "b": Vector2(-20, 20), "c": Vector2(30, 20), "color": Color("#166534")})
			list.append({"pos": center_pos + Vector2(35, -45), "a": Vector2(25, -30), "b": Vector2(-25, 30), "c": Vector2(25, 30), "color": Color("#16A34A")})
			list.append({"pos": center_pos + Vector2(0, 0), "a": Vector2(40, -40), "b": Vector2(-50, 40), "c": Vector2(50, 40), "color": Color("#22C55E")})
			list.append({"pos": center_pos + Vector2(-45, 10), "a": Vector2(45, -30), "b": Vector2(-45, 30), "c": Vector2(45, 30), "color": Color("#16A34A")})
			list.append({"pos": center_pos + Vector2(-95, 25), "a": Vector2(45, -15), "b": Vector2(-45, 35), "c": Vector2(25, 35), "color": Color("#15803D")})
			list.append({"pos": center_pos + Vector2(-135, 50), "a": Vector2(35, -15), "b": Vector2(-35, 25), "c": Vector2(15, 25), "color": Color("#166534")})
			list.append({"pos": center_pos + Vector2(-15, -45), "a": Vector2(0, -25), "b": Vector2(-20, 15), "c": Vector2(20, 15), "color": Color("#FACC15")})
			list.append({"pos": center_pos + Vector2(-45, -30), "a": Vector2(0, -25), "b": Vector2(-20, 15), "c": Vector2(20, 15), "color": Color("#FACC15")})
			list.append({"pos": center_pos + Vector2(20, 75), "a": Vector2(-20, -35), "b": Vector2(20, 35), "c": Vector2(-20, 35), "color": Color("#14532D")})
			list.append({"pos": center_pos + Vector2(-25, 75), "a": Vector2(-20, -35), "b": Vector2(20, 35), "c": Vector2(-20, 35), "color": Color("#14532D")})

		"독수리 (Eagle)":
			list.append({"pos": center_pos + Vector2(0, -70), "a": Vector2(0, -35), "b": Vector2(-25, 25), "c": Vector2(25, 25), "color": Color("#FFFFFF")})
			list.append({"pos": center_pos + Vector2(25, -60), "a": Vector2(-10, -10), "b": Vector2(20, 5), "c": Vector2(-10, 15), "color": Color("#F59E0B")})
			list.append({"pos": center_pos + Vector2(0, -15), "a": Vector2(0, -30), "b": Vector2(-35, 40), "c": Vector2(35, 40), "color": Color("#78350F")})
			list.append({"pos": center_pos + Vector2(-55, -40), "a": Vector2(40, 20), "b": Vector2(-60, -40), "c": Vector2(-20, 30), "color": Color("#92400E")})
			list.append({"pos": center_pos + Vector2(55, -40), "a": Vector2(-40, 20), "b": Vector2(20, 30), "c": Vector2(60, -40), "color": Color("#92400E")})
			list.append({"pos": center_pos + Vector2(-115, -45), "a": Vector2(40, 25), "b": Vector2(-50, -35), "c": Vector2(-20, 25), "color": Color("#B45309")})
			list.append({"pos": center_pos + Vector2(115, -45), "a": Vector2(-40, 25), "b": Vector2(20, 25), "c": Vector2(50, -35), "color": Color("#B45309")})
			list.append({"pos": center_pos + Vector2(-65, 10), "a": Vector2(35, -20), "b": Vector2(-45, 30), "c": Vector2(15, 30), "color": Color("#78350F")})
			list.append({"pos": center_pos + Vector2(65, 10), "a": Vector2(-35, -20), "b": Vector2(-15, 30), "c": Vector2(45, 30), "color": Color("#78350F")})
			list.append({"pos": center_pos + Vector2(-20, 55), "a": Vector2(20, -30), "b": Vector2(-30, 40), "c": Vector2(10, 40), "color": Color("#FFFFFF")})
			list.append({"pos": center_pos + Vector2(20, 55), "a": Vector2(-20, -30), "b": Vector2(-10, 40), "c": Vector2(30, 40), "color": Color("#FFFFFF")})

		"기린 (Giraffe)":
			list.append({"pos": center_pos + Vector2(55, -110), "a": Vector2(-20, -25), "b": Vector2(30, 0), "c": Vector2(-20, 25), "color": Color("#F59E0B")})
			list.append({"pos": center_pos + Vector2(40, -135), "a": Vector2(5, -15), "b": Vector2(-15, 15), "c": Vector2(15, 15), "color": Color("#B45309")})
			list.append({"pos": center_pos + Vector2(40, -60), "a": Vector2(15, -45), "b": Vector2(-20, 45), "c": Vector2(20, 45), "color": Color("#FBBF24")})
			list.append({"pos": center_pos + Vector2(25, 10), "a": Vector2(15, -45), "b": Vector2(-25, 45), "c": Vector2(25, 45), "color": Color("#F59E0B")})
			list.append({"pos": center_pos + Vector2(-25, 35), "a": Vector2(45, -25), "b": Vector2(-55, 35), "c": Vector2(45, 35), "color": Color("#D97706")})
			list.append({"pos": center_pos + Vector2(-45, 25), "a": Vector2(45, -25), "b": Vector2(-35, 35), "c": Vector2(35, 35), "color": Color("#B45309")})
			list.append({"pos": center_pos + Vector2(20, 105), "a": Vector2(-10, -35), "b": Vector2(-15, 45), "c": Vector2(15, 45), "color": Color("#D97706")})
			list.append({"pos": center_pos + Vector2(35, 105), "a": Vector2(-10, -35), "b": Vector2(-10, 45), "c": Vector2(15, 45), "color": Color("#B45309")})
			list.append({"pos": center_pos + Vector2(-55, 105), "a": Vector2(10, -35), "b": Vector2(-15, 45), "c": Vector2(10, 45), "color": Color("#D97706")})
			list.append({"pos": center_pos + Vector2(-40, 105), "a": Vector2(10, -35), "b": Vector2(-10, 45), "c": Vector2(15, 45), "color": Color("#B45309")})
			list.append({"pos": center_pos + Vector2(-80, 55), "a": Vector2(15, -20), "b": Vector2(-20, 30), "c": Vector2(5, 30), "color": Color("#78350F")})

		"공작새 (Peacock)":
			list.append({"pos": center_pos + Vector2(0, 30), "a": Vector2(0, -45), "b": Vector2(-25, 35), "c": Vector2(25, 35), "color": Color("#0284C7")})
			list.append({"pos": center_pos + Vector2(0, -25), "a": Vector2(0, -35), "b": Vector2(-15, 20), "c": Vector2(15, 20), "color": Color("#0369A1")})
			# 7 fan feathers
			list.append({"pos": center_pos + Vector2(0, -90), "a": Vector2(0, -45), "b": Vector2(-25, 35), "c": Vector2(25, 35), "color": Color("#10B981")})
			list.append({"pos": center_pos + Vector2(-45, -80), "a": Vector2(-20, -40), "b": Vector2(-35, 30), "c": Vector2(25, 20), "color": Color("#059669")})
			list.append({"pos": center_pos + Vector2(45, -80), "a": Vector2(20, -40), "b": Vector2(-25, 20), "c": Vector2(35, 30), "color": Color("#059669")})
			list.append({"pos": center_pos + Vector2(-80, -50), "a": Vector2(-35, -30), "b": Vector2(-30, 35), "c": Vector2(30, 10), "color": Color("#0D9488")})
			list.append({"pos": center_pos + Vector2(80, -50), "a": Vector2(35, -30), "b": Vector2(-30, 10), "c": Vector2(30, 35), "color": Color("#0D9488")})
			list.append({"pos": center_pos + Vector2(-105, -10), "a": Vector2(-40, -15), "b": Vector2(-20, 35), "c": Vector2(30, 0), "color": Color("#047857")})
			list.append({"pos": center_pos + Vector2(105, -10), "a": Vector2(40, -15), "b": Vector2(-30, 0), "c": Vector2(20, 35), "color": Color("#047857")})
			list.append({"pos": center_pos + Vector2(-15, 80), "a": Vector2(10, -20), "b": Vector2(-15, 25), "c": Vector2(15, 25), "color": Color("#F59E0B")})
			list.append({"pos": center_pos + Vector2(15, 80), "a": Vector2(-10, -20), "b": Vector2(-15, 25), "c": Vector2(15, 25), "color": Color("#F59E0B")})

		"중세의 성 (Castle)":
			list.append({"pos": center_pos + Vector2(0, -10), "a": Vector2(-40, -50), "b": Vector2(40, -50), "c": Vector2(-40, 50), "color": Color("#64748B")})
			list.append({"pos": center_pos + Vector2(0, -10), "a": Vector2(40, -50), "b": Vector2(40, 50), "c": Vector2(-40, 50), "color": Color("#475569")})
			list.append({"pos": center_pos + Vector2(0, -85), "a": Vector2(0, -45), "b": Vector2(-40, 25), "c": Vector2(40, 25), "color": Color("#DC2626")})
			list.append({"pos": center_pos + Vector2(-75, 10), "a": Vector2(-25, -50), "b": Vector2(25, -50), "c": Vector2(-25, 50), "color": Color("#64748B")})
			list.append({"pos": center_pos + Vector2(-75, 10), "a": Vector2(25, -50), "b": Vector2(25, 50), "c": Vector2(-25, 50), "color": Color("#475569")})
			list.append({"pos": center_pos + Vector2(-75, -60), "a": Vector2(0, -35), "b": Vector2(-25, 20), "c": Vector2(25, 20), "color": Color("#EF4444")})
			list.append({"pos": center_pos + Vector2(75, 10), "a": Vector2(-25, -50), "b": Vector2(25, -50), "c": Vector2(-25, 50), "color": Color("#64748B")})
			list.append({"pos": center_pos + Vector2(75, 10), "a": Vector2(25, -50), "b": Vector2(25, 50), "c": Vector2(-25, 50), "color": Color("#475569")})
			list.append({"pos": center_pos + Vector2(75, -60), "a": Vector2(0, -35), "b": Vector2(-25, 20), "c": Vector2(25, 20), "color": Color("#EF4444")})
			list.append({"pos": center_pos + Vector2(0, 50), "a": Vector2(0, -25), "b": Vector2(-25, 20), "c": Vector2(25, 20), "color": Color("#1E293B")})

		"열기구 (Hot Air Balloon)":
			# Balloon sphere slices
			list.append({"pos": center_pos + Vector2(0, -60), "a": Vector2(0, -60), "b": Vector2(-30, 45), "c": Vector2(30, 45), "color": Color("#F43F5E")})
			list.append({"pos": center_pos + Vector2(-45, -55), "a": Vector2(35, -55), "b": Vector2(-45, 15), "c": Vector2(10, 45), "color": Color("#F59E0B")})
			list.append({"pos": center_pos + Vector2(45, -55), "a": Vector2(-35, -55), "b": Vector2(-10, 45), "c": Vector2(45, 15), "color": Color("#F59E0B")})
			list.append({"pos": center_pos + Vector2(-65, -20), "a": Vector2(35, -35), "b": Vector2(-30, 30), "c": Vector2(15, 30), "color": Color("#10B981")})
			list.append({"pos": center_pos + Vector2(65, -20), "a": Vector2(-35, -35), "b": Vector2(-15, 30), "c": Vector2(30, 30), "color": Color("#10B981")})
			list.append({"pos": center_pos + Vector2(0, 10), "a": Vector2(-45, -20), "b": Vector2(45, -20), "c": Vector2(0, 35), "color": Color("#6366F1")})
			# Rigging & Basket
			list.append({"pos": center_pos + Vector2(-20, 45), "a": Vector2(10, -20), "b": Vector2(-15, 25), "c": Vector2(10, 25), "color": Color("#78350F")})
			list.append({"pos": center_pos + Vector2(20, 45), "a": Vector2(-10, -20), "b": Vector2(-10, 25), "c": Vector2(15, 25), "color": Color("#78350F")})
			list.append({"pos": center_pos + Vector2(0, 80), "a": Vector2(-25, -20), "b": Vector2(25, -20), "c": Vector2(0, 20), "color": Color("#B45309")})

		"스포츠카 (Sports Car)":
			# Body top/hood/trunk
			list.append({"pos": center_pos + Vector2(0, -35), "a": Vector2(-35, -30), "b": Vector2(-60, 25), "c": Vector2(40, 25), "color": Color("#38BDF8")})
			list.append({"pos": center_pos + Vector2(25, -35), "a": Vector2(-40, 25), "b": Vector2(45, 25), "c": Vector2(15, -30), "color": Color("#0284C7")})
			list.append({"pos": center_pos + Vector2(75, 5), "a": Vector2(-45, -20), "b": Vector2(55, 15), "c": Vector2(-45, 15), "color": Color("#EF4444")})
			list.append({"pos": center_pos + Vector2(-75, 5), "a": Vector2(45, -20), "b": Vector2(-45, 15), "c": Vector2(45, 15), "color": Color("#EF4444")})
			list.append({"pos": center_pos + Vector2(0, 10), "a": Vector2(-65, -15), "b": Vector2(65, -15), "c": Vector2(0, 25), "color": Color("#DC2626")})
			list.append({"pos": center_pos + Vector2(-110, -25), "a": Vector2(20, 20), "b": Vector2(-20, 20), "c": Vector2(10, -15), "color": Color("#B91C1C")})
			# Wheels
			list.append({"pos": center_pos + Vector2(-60, 45), "a": Vector2(0, -25), "b": Vector2(-25, 20), "c": Vector2(25, 20), "color": Color("#1E293B")})
			list.append({"pos": center_pos + Vector2(-60, 48), "a": Vector2(0, 15), "b": Vector2(-15, -15), "c": Vector2(15, -15), "color": Color("#64748B")})
			list.append({"pos": center_pos + Vector2(60, 45), "a": Vector2(0, -25), "b": Vector2(-25, 20), "c": Vector2(25, 20), "color": Color("#1E293B")})
			list.append({"pos": center_pos + Vector2(60, 48), "a": Vector2(0, 15), "b": Vector2(-15, -15), "c": Vector2(15, -15), "color": Color("#64748B")})

		"로봇 (Robot)":
			list.append({"pos": center_pos + Vector2(0, -95), "a": Vector2(0, -35), "b": Vector2(-30, 25), "c": Vector2(30, 25), "color": Color("#0284C7")})
			list.append({"pos": center_pos + Vector2(0, -135), "a": Vector2(0, -20), "b": Vector2(-10, 15), "c": Vector2(10, 15), "color": Color("#FACC15")})
			list.append({"pos": center_pos + Vector2(-30, -30), "a": Vector2(30, -40), "b": Vector2(-30, 40), "c": Vector2(30, 40), "color": Color("#38BDF8")})
			list.append({"pos": center_pos + Vector2(30, -30), "a": Vector2(-30, -40), "b": Vector2(-30, 40), "c": Vector2(30, 40), "color": Color("#0EA5E9")})
			list.append({"pos": center_pos + Vector2(0, -20), "a": Vector2(0, -20), "b": Vector2(-20, 20), "c": Vector2(20, 20), "color": Color("#EF4444")})
			list.append({"pos": center_pos + Vector2(-75, -40), "a": Vector2(35, 10), "b": Vector2(-35, -35), "c": Vector2(-20, 35), "color": Color("#64748B")})
			list.append({"pos": center_pos + Vector2(75, -40), "a": Vector2(-35, 10), "b": Vector2(20, 35), "c": Vector2(35, -35), "color": Color("#64748B")})
			list.append({"pos": center_pos + Vector2(-100, 10), "a": Vector2(20, -30), "b": Vector2(-20, 30), "c": Vector2(20, 30), "color": Color("#475569")})
			list.append({"pos": center_pos + Vector2(100, 10), "a": Vector2(-20, -30), "b": Vector2(-20, 30), "c": Vector2(20, 30), "color": Color("#475569")})
			list.append({"pos": center_pos + Vector2(-30, 55), "a": Vector2(0, -35), "b": Vector2(-25, 45), "c": Vector2(25, 45), "color": Color("#1E293B")})
			list.append({"pos": center_pos + Vector2(30, 55), "a": Vector2(0, -35), "b": Vector2(-25, 45), "c": Vector2(25, 45), "color": Color("#1E293B")})

		"보석 만다라 (Mandala)":
			# 8 radial outer facets + 4 inner core facets
			var colors_outer: Array[Color] = [Color("#818CF8"), Color("#C084FC"), Color("#F472B6"), Color("#FB7185"), Color("#FBBF24"), Color("#34D399"), Color("#38BDF8"), Color("#60A5FA")]
			for i in range(8):
				var ang: float = float(i) * TAU / 8.0
				var v_tip: Vector2 = Vector2(cos(ang), sin(ang)) * 105.0
				var ang_l: float = ang - 0.35
				var ang_r: float = ang + 0.35
				var v_l: Vector2 = Vector2(cos(ang_l), sin(ang_l)) * 45.0
				var v_r: Vector2 = Vector2(cos(ang_r), sin(ang_r)) * 45.0
				list.append({"pos": center_pos, "a": v_tip, "b": v_l, "c": v_r, "color": colors_outer[i]})
			for j in range(4):
				var ang_c: float = float(j) * TAU / 4.0 + 0.39
				var tip_c: Vector2 = Vector2(cos(ang_c), sin(ang_c)) * 40.0
				var base1: Vector2 = Vector2(cos(ang_c - 0.75), sin(ang_c - 0.75)) * 20.0
				var base2: Vector2 = Vector2(cos(ang_c + 0.75), sin(ang_c + 0.75)) * 20.0
				list.append({"pos": center_pos, "a": tip_c, "b": base1, "c": base2, "color": Color("#FFFFFF")})

		"크리스마스 트리 (Tree)":
			# 6 leafy tiers (pairs)
			list.append({"pos": center_pos + Vector2(-20, -75), "a": Vector2(20, -45), "b": Vector2(-35, 25), "c": Vector2(20, 25), "color": Color("#22C55E")})
			list.append({"pos": center_pos + Vector2(20, -75), "a": Vector2(-20, -45), "b": Vector2(-20, 25), "c": Vector2(35, 25), "color": Color("#16A34A")})
			list.append({"pos": center_pos + Vector2(-30, -25), "a": Vector2(30, -45), "b": Vector2(-45, 30), "c": Vector2(30, 30), "color": Color("#15803D")})
			list.append({"pos": center_pos + Vector2(30, -25), "a": Vector2(-30, -45), "b": Vector2(-30, 30), "c": Vector2(45, 30), "color": Color("#166534")})
			list.append({"pos": center_pos + Vector2(-40, 30), "a": Vector2(40, -45), "b": Vector2(-55, 35), "c": Vector2(40, 35), "color": Color("#14532D")})
			list.append({"pos": center_pos + Vector2(40, 30), "a": Vector2(-40, -45), "b": Vector2(-40, 35), "c": Vector2(55, 35), "color": Color("#14532D")})
			# Trunk
			list.append({"pos": center_pos + Vector2(0, 90), "a": Vector2(-20, -25), "b": Vector2(20, -25), "c": Vector2(0, 30), "color": Color("#78350F")})
			# Top Star (3 triangles)
			list.append({"pos": center_pos + Vector2(0, -130), "a": Vector2(0, -25), "b": Vector2(-15, 15), "c": Vector2(15, 15), "color": Color("#FACC15")})
			list.append({"pos": center_pos + Vector2(-12, -125), "a": Vector2(12, 10), "b": Vector2(-18, -10), "c": Vector2(5, -20), "color": Color("#F59E0B")})
			list.append({"pos": center_pos + Vector2(12, -125), "a": Vector2(-12, 10), "b": Vector2(-5, -20), "c": Vector2(18, -10), "color": Color("#F59E0B")})
			# 2 Gift Boxes under tree
			list.append({"pos": center_pos + Vector2(-60, 95), "a": Vector2(0, -25), "b": Vector2(-25, 20), "c": Vector2(25, 20), "color": Color("#EF4444")})
			list.append({"pos": center_pos + Vector2(60, 95), "a": Vector2(0, -25), "b": Vector2(-25, 20), "c": Vector2(25, 20), "color": Color("#3B82F6")})

	return list
