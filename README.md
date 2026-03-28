# MoodFlow
 
> **Emotion-guided AI music journeys for iOS**  
> Hackathon Project · Team of 4
 
---
 
## What It Does
 
MoodFlow takes how you're feeling right now and builds a personalized, AI-generated music journey to guide you through it — not around it.
 
You pick your **emotion** (anxious, sad, scattered, low-energy) and your **goal** (focus, calm, energize, process). Claude generates a structured 4-stage regulation journey: micro-prompts to read at each stage, music matched by BPM and energy, and an arousal trajectory curve showing where you're headed emotionally.
 
---
 
## Demo
 
| Check-In | Journey Plan | Watch Panel |
|----------|-------------|-------------|
| Emotion + goal picker | AI-generated stages + trajectory curve | Simulated HR drop (arousal proxy) |
 
---
 
## How It Works
 
**One LLM call. Structured JSON back. Everything else is local.**
 
```
User selects emotion + goal + duration
        ↓
Single API call to Claude (claude-sonnet-4-20250514)
        ↓
Returns 4-stage journey plan as JSON
        ↓
MusicMatcher filters tracks.json by BPM/energy criteria
        ↓
Journey renders: curve + stage cards + micro-prompts
```
 
### The AI Prompt
 
```
You are an emotion regulation assistant.
A user is feeling [EMOTION] and wants to [GOAL] in [DURATION] minutes.
 
Generate a regulation journey with exactly 4 stages.
For each stage return:
  - stage_name: validate / regulate / stabilize / activate
  - duration_minutes
  - target_arousal: 0.0–1.0
  - micro_prompt: one sentence, under 12 words, non-clinical
  - music_criteria: { max_bpm, energy_level, lyrics }
 
Return ONLY valid JSON. No explanation. No markdown.
```
 
### Example Output
 
```json
[
  {
    "stage_name": "validate",
    "duration_minutes": 3,
    "target_arousal": 0.75,
    "micro_prompt": "Name what you're feeling without judging it.",
    "music_criteria": { "max_bpm": 90, "energy_level": "mid", "lyrics": "low" }
  },
  {
    "stage_name": "regulate",
    "duration_minutes": 4,
    "target_arousal": 0.45,
    "micro_prompt": "Breathe out longer than you breathe in.",
    "music_criteria": { "max_bpm": 70, "energy_level": "low", "lyrics": "none" }
  },
  {
    "stage_name": "stabilize",
    "duration_minutes": 3,
    "target_arousal": 0.30,
    "micro_prompt": "Feel your feet on the floor. You're here.",
    "music_criteria": { "max_bpm": 75, "energy_level": "low", "lyrics": "none" }
  },
  {
    "stage_name": "activate",
    "duration_minutes": 2,
    "target_arousal": 0.50,
    "micro_prompt": "What's the one smallest thing you can do right now?",
    "music_criteria": { "max_bpm": 95, "energy_level": "mid", "lyrics": "low" }
  }
]
```
 
---
 
## Tech Stack
 
| Layer | Technology |
|-------|-----------|
| UI | SwiftUI (iOS 16+) |
| AI / LLM | Claude API (`claude-sonnet-4-20250514`) |
| Charts | Swift Charts (built-in) |
| Music Data | Hardcoded `tracks.json` — 20 songs, manually tagged |
| Watch Panel | SwiftUI with simulated HR data |
| Backend | None — fully local + direct API calls |
 
---
 
## Project Structure
 
```
MoodFlow/
├── Features/
│   ├── CheckIn/          # Emotion + goal picker
│   ├── Journey/          # AI journey plan + trajectory curve
│   └── WatchPanel/       # Simulated biometric feedback
├── Services/
│   ├── LLM/              # Claude API client + prompt builder
│   ├── Music/            # BPM/energy matching logic
│   └── Parsing/          # JSON response parser
├── Data/
│   ├── tracks.json       # 20 curated songs with metadata
│   └── MockData/         # Offline fallback journeys
├── Components/           # Reusable UI (cards, badges, buttons)
├── Core/                 # Navigation, extensions, utilities
└── Config/               # Environment + API config (not committed)
```
 
---
 
## Getting Started
 
### Prerequisites
 
- Xcode 15+
- iOS 16+ device or simulator
- Claude API key ([get one here](https://console.anthropic.com))
 
### Setup
 
```bash
git clone https://github.com/your-team/moodflow.git
cd moodflow
```
 
1. Open `MoodFlow.xcodeproj` in Xcode
2. Copy the config template:
   ```bash
   cp Config/APIKeys.example.swift Config/APIKeys.swift
   ```
3. Add your Claude API key to `Config/APIKeys.swift`:
   ```swift
   static let claudeAPIKey = "your-key-here"
   ```
4. Build and run on simulator or device (`Cmd + R`)
 
> ⚠️ `Config/APIKeys.swift` is in `.gitignore` — never commit your API key.
 
---
 
## Offline Mode
 
If the API is unavailable, MoodFlow automatically falls back to 5 pre-built journeys covering the most common emotion + goal combinations. No network required for the demo.
 
---
 
## What's Not Built Yet (On Purpose)
 
This is a hackathon MVP. These features are designed but not implemented:
 
- **Real Apple Watch HR integration** — currently simulated. Version 2 closes this loop with live HealthKit data for real-time adaptive regulation
- **Recency penalty system** — avoids repeating the same journey plan across sessions
- **Closed-loop adaptation** — adjusts music in real-time based on biometric response
- **Spotify / Apple Music integration** — currently uses a curated local track list
 
---
 
## The Vision
 
> Version 1 proves the core works.  
> Version 2 makes it biologically adaptive.
 
When real HR data from Apple Watch feeds back into the journey — adjusting BPM, energy, and micro-prompts in real time based on measured arousal — MoodFlow becomes a genuinely closed-loop emotion regulation tool. No app does this today.
 
---
 
## Team
 
| Person | Role |
|--------|------|
| A | iOS Lead & Architect |
| B | UI & Screens Developer |
| C | Data & Charts Engineer |
| D | Pitch & QA Lead |
 
---
 
## License
 
MIT — built at Claude AI Hackathon , Indiana University Bloomington.
 
