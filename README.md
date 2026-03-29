# MoodFlow
*Emotion-guided AI music journeys for iOS*
Hackathon Project · Team of 4

Team Members:
Juman Das - judas@iu.edu
Tanmay Pawar - tpawar@iu.edu
Ayush Kapileshwar - askapile@iu.edu
Aryan Kathale - aryakath@iu.edu

---

## What It Does

MoodFlow takes how you're feeling right now — both emotionally and physiologically — and builds a personalized, AI-generated music journey to guide you through it. Not around it. Through it.

You pick your emotion (anxious, sad, stressed, overwhelmed), enter your biometric data (heart rate, respiratory rate), and set your destination mood (focused, calm, happy, energized). The AI generates a structured *4-stage regulation journey* based on the ISO principle from music therapy: meet, shift, transition, arrive. Every song is real, resolved live from Spotify's catalog, and plays directly through Spotify — no previews, no samples, full tracks.

If the music isn't working mid-journey, you tell the app and the AI *re-curates the remaining stages in real-time* with better-matched songs.

---

## How It Works


User selects current emotion
        ↓
User enters biometrics (resting HR, walking HR, respiratory rate)
        ↓
Mood inference engine blends self-report (60%) + biometrics (40%)
        ↓
User selects desired mood + journey duration
        ↓
LLM API call → returns 4-stage journey with song recommendations
        ↓
Each song resolved against Spotify Web API (search → match → URI)
        ↓
Journey plays live via Spotify iOS SDK (SPTAppRemote)
        ↓
Periodic mood check-ins → user feedback → AI re-curates if needed


### The AI Prompt


You are a music therapist and expert DJ specializing in emotional
regulation through music. You have deep knowledge of how music's
tempo (BPM), energy, and valence affect human emotions.

Create a 4-stage music journey:
- Current mood: [EMOTION] (energy: 0.7, valence: 0.2)
- Desired mood: [GOAL] (energy: 0.55, valence: 0.6)
- Duration: [DURATION] minutes
- Biometric data: Resting HR: 88 BPM, Walking HR: 125 BPM,
  Respiratory Rate: 22 breaths/min, Stress level: 72%

Stage 1 matches the current mood. Each stage moves incrementally
toward the goal. Stage 4 fully embodies the desired mood.

Return ONLY valid JSON with real songs available on Spotify.


### Example Output

⁠ json
{
  "stages": [
    {
      "name": "Acknowledge",
      "description": "Meeting your anxious energy with matching intensity",
      "order": 1,
      "target_bpm_min": 120,
      "target_bpm_max": 140,
      "target_energy": 0.7,
      "target_valence": 0.3,
      "songs": [
        {
          "title": "Breathe Deeper",
          "artist": "Tame Impala",
          "estimated_bpm": 125,
          "estimated_energy": 0.72,
          "reason": "Matches anxious energy while providing rhythmic grounding"
        }
      ]
    }
  ]
}
 ⁠

---

## Key Features

| Feature | Description |
|---------|-------------|
| *Biometric Mood Detection* | Combines self-reported emotion with heart rate & respiratory data to infer true mood |
| *Live Spotify Playback* | Songs play directly through Spotify — full tracks, not previews |
| *No Hardcoded Songs* | Every song is recommended by the AI and resolved from Spotify's live catalog |
| *4-Stage ISO Principle* | Clinically-grounded journey structure: meet → shift → transition → arrive |
| *Adaptive Re-Curation* | Mid-journey feedback triggers AI to regenerate remaining stages with better songs |
| *Playback Sync Engine* | 3-layer system (delegate callbacks + timers + watchdog) keeps app and Spotify in perfect sync |
| *Duration Control* | User sets journey length (15–60 min); songs are trimmed to fit |

---

## Tech Stack

| Layer | Technology |
|-------|------------|
| UI | SwiftUI (iOS 16+) |
| AI / LLM | Groq API — Llama 3.3 70B Versatile (OpenAI-compatible) |
| Music Playback | Spotify iOS SDK (⁠ SPTAppRemote ⁠) |
| Music Search | Spotify Web API (search, playlist creation) |
| Auth | Spotify PKCE OAuth via ⁠ ASWebAuthenticationSession ⁠ |
| Mood Engine | Custom biometric inference (HR + RR → stress/energy → mood) |
| Backend | None — fully on-device + direct API calls |

---

## Project Structure


MoodFlow/
├── MoodFlowApp.swift              # App entry point + auth routing
├── Config.swift                   # API keys & Spotify config
├── Info.plist                     # URL schemes, background audio
├── Models/
│   ├── Mood.swift                 # 12 moods with emoji, color, valence, energy, inference
│   ├── BiometricInput.swift       # HR/RR input model with stress & energy computation
│   ├── Journey.swift              # 4-stage journey with BPM targets
│   ├── Song.swift                 # Song model + Spotify API response types
│   ├── AppError.swift             # Error types
│   └── Extensions.swift           # Safe array subscript
├── Services/
│   ├── ClaudeService.swift        # LLM API client (Groq/Llama 3.3) + prompt builder
│   ├── SpotifyAuthService.swift   # PKCE OAuth flow
│   ├── SpotifyPlaybackService.swift # Queue management, sync watchdog, auto-advance
│   └── SpotifyWebAPIService.swift # Search, resolve songs, create playlists
├── ViewModels/
│   └── JourneyViewModel.swift     # State machine: idle → generating → preview → active → complete
├── Views/
│   ├── LoginView.swift            # Spotify login screen
│   ├── MoodSetupView.swift        # 4-step setup: emotion → vitals → goal → duration
│   ├── JourneyFlowView.swift      # State router + loading/error views
│   ├── JourneyPreviewView.swift   # Preview stages before starting
│   ├── ActiveJourneyView.swift    # Now playing + controls + mood check-in
│   └── JourneyCompleteView.swift  # Completion screen with stats
└── Assets.xcassets/               # App icon & colors


---

## Getting Started

### Prerequisites
•⁠  ⁠Xcode 15+
•⁠  ⁠iOS 16+ device (Spotify playback requires a physical device)
•⁠  ⁠Spotify Premium account
•⁠  ⁠[Groq API key](https://console.groq.com)
•⁠  ⁠[Spotify Developer App](https://developer.spotify.com/dashboard) with redirect URI ⁠ moodflow://spotify-callback ⁠
•⁠  ⁠XcodeGen (⁠ brew install xcodegen ⁠)

### Setup

⁠ bash
git clone https://github.com/your-team/moodflow.git
cd moodflow
 ⁠

Edit ⁠ MoodFlow/Config.swift ⁠ with your credentials:
⁠ swift
static let spotifyClientID = "your-spotify-client-id"
static let openAIAPIKey = "your-groq-api-key"
 ⁠

Generate the Xcode project and run:
⁠ bash
xcodegen generate
open MoodFlow.xcodeproj
# Build and run on your iPhone (Cmd + R)
 ⁠

	⁠⚠️ *Never commit API keys.* Add ⁠ Config.swift ⁠ to ⁠ .gitignore ⁠ for production use.

### Spotify Dashboard Setup
1.⁠ ⁠Create an app at [Spotify Developer Dashboard](https://developer.spotify.com/dashboard)
2.⁠ ⁠Add redirect URI: ⁠ moodflow://spotify-callback ⁠
3.⁠ ⁠Copy your Client ID to ⁠ Config.swift ⁠
4.⁠ ⁠No client secret needed — the app uses PKCE auth

---

## Design Decisions

### Why Biometric + Emotion Input?
Your body doesn't lie. A user who selects "calm" with a resting heart rate of 95 BPM is likely masking anxiety. By blending self-report (60%) with physiological signals (40%), we detect the true starting mood — leading to more effective journeys.

### Why No Hardcoded Songs?
Hardcoded playlists break after a few uses. The LLM generates fresh recommendations every time based on the specific mood transition, duration, and biometric context. Songs are validated against Spotify's live catalog to ensure they're playable.

### Why the 3-Layer Playback Sync?
Spotify's App Remote SDK doesn't natively support custom queues. When a song finishes, Spotify auto-plays unrelated tracks. We solved this with:
1.⁠ ⁠*⁠ playerStateDidChange ⁠ delegate* (primary) — detects drift the instant it happens
2.⁠ ⁠*Duration-based advance timer* (backup) — fires before song ends
3.⁠ ⁠*Polling watchdog* (safety net) — checks every 3 seconds

### Why 4 Stages?
Based on the ISO principle from music therapy. Four stages provides enough granularity for a gradual emotional transition without overwhelming the user with complexity.

---

## What's Next (V2 Roadmap)

| Feature | Status |
|---------|--------|
| Real Apple Watch HR via HealthKit | Designed — replaces manual input with live data |
| Closed-loop adaptation | Designed — adjusts songs in real-time based on measured HR |
| Apple Music support | Planned — alternative to Spotify |
| Journey history & insights | Planned — track emotional patterns over time |
| Recency penalty system | Planned — avoids repeating songs across sessions |

*V1 proves the core loop works. V2 makes it biologically adaptive.*

When real HR data from Apple Watch feeds back into the journey — adjusting BPM, energy, and songs in real time based on measured arousal — MoodFlow becomes a genuinely closed-loop emotion regulation tool. No app does this today.

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

MIT — built at AI Hackathon, Indiana University Bloomington.
