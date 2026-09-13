# 🔺 Triangle Art (트라이앵글 아트)

> **삼각형만으로 펼쳐지는 무한한 디지털 기하학 아트 게임**  
> Godot 4.x 기반으로 제작된 웹/데스크톱 인터랙티브 기하학 아트 & 퍼즐 챌린지 게임입니다.

[![Godot Engine](https://img.shields.io/badge/Godot-4.x-478cbf?logo=godotengine&logoColor=white)](https://godotengine.org)
[![Vercel Deployment](https://img.shields.io/badge/Vercel-Deployed-black?logo=vercel&logoColor=white)](https://vercel.com)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

---

## ✨ 주요 기능 (Key Features)

### 1. 정밀 기하학 드로잉 시스템
- **순수 기하학적 진실의 원천**: 모든 삼각형은 3개의 정점 좌표(`vertex_a`, `vertex_b`, `vertex_c`)와 로컬 변환을 수학적으로 엄밀히 연산.
- **자석 정점 스냅 (Magnetic Snap)**: 인접한 삼각형의 정점에 마우스가 다가가면 부드럽게 결합되는 스냅 효과.
- **15° 회전 스냅 & 각도 피드백**: 최상단 꼭짓점 앵커 기반 회전 핸들과 모서리 회전 영역 지원.
- **다중 선택 & 그룹화 (`Ctrl+G`)**: 여러 삼각형을 한 묶음으로 묶어 일체화 회전 및 크기 조절.
- **무제한 실행 취소/다시 실행 (Undo/Redo, `Ctrl+Z`, `Ctrl+Y`)**: 모든 조작에 커맨드 패턴 적용.

### 2. 퍼즐 챌린지 모드 (Puzzle Challenge Mode)
- **실시간 일치도 평가기 (`PuzzleEvaluator`)**: 실루엣 목표 도안과 플레이어가 배치한 도형 간의 면적 중첩도를 실시간(0~100%) 평가.
- **3-Star 레이팅 & 클리어 연출**: 90% 이상 일치 시 황금 승리 배너, 축하 팡파레, 80여 개의 물리 기반 삼각 컨페티 파티클 폭죽 발사!
- **8종 창의 도안 라이브러리**: 나비, 여우, 산과 해, 우주선, 집, 보트, 하트, 풍차.

### 3. 상용 인디 게임급 프리미엄 UI / UX
- **다크 글래스모피즘 캡슐 HUD**: 모뉴먼트 밸리(Monument Valley) & 타운스케이퍼(Townscaper) 감성의 미려한 반투명 플로팅 HUD.
- **플로팅 독 컬러 팔레트**: 하단 스와치 바, 호버 스케일업 및 네온 링 발광 애니메이션.
- **도화지 규격 프리셋**: 1:1 정사각, 16:9 와이드, A4 비율 등 자유로운 캔버스 설정.
- **순수 절차적 PCM 사운드 엔진**: 외부 에셋 없이 100% 코드로 합성된 16비트 모노 오디오 효과음 및 상단 음소거 토글 버튼(`🔊`/`🔇`).

### 4. 내보내기 & 프로젝트 저장
- **PNG 고화질 이미지 내보내기**: 격자와 UI 없이 순수 아트워크만 투명 배경/캔버스 배경으로 저장.
- **프로젝트 파일 저장/열기 (`.triart` / `.json`)**: 작업 중인 아트워크의 모든 기하 정보를 무손실 저장 및 복원.

---

## 🚀 빠른 시작 (Getting Started)

### 웹에서 플레이
Vercel에 배포된 라이브 데모에서 브라우저로 즉시 플레이할 수 있습니다.

### 로컬 실행 (Godot 4.x)
```bash
# 저장소 클론
git clone https://github.com/inkun00/triangle-art.git
cd triangle-art

# Godot 4 에디터로 실행
godot --editor .
```

### 테스트 스위트 실행
```powershell
powershell -File tools/run_tests.ps1
```

### 빌드 및 배포
```powershell
# 웹 빌드 내보내기
powershell -File tools/export_web.ps1

# 윈도우 독립형 패키지 내보내기
powershell -File tools/export_desktop.ps1
```

---

## 🛠️ 기술 스택
- **Engine**: Godot Engine 4.x (GDScript)
- **Math & Core**: Pure Vector2 Analytic Geometry & Command Pattern
- **Platform**: Web (HTML5 / WebAssembly Single-Threaded), Windows Desktop
- **Deployment**: Vercel & GitHub
