# LangLens

A macOS menu bar app for real-time language learning. Press a hotkey, speak, and get instant AI-powered feedback — translations, corrections, or pronunciation help — right on your screen.

## Features

### Smart AI Modes

LangLens automatically detects what you need based on what you say:

- **Translation** — Speak in your native language and get an instant translation to your target language, with pronunciation and examples.
- **Correction** — Speak a sentence in your target language to practice. LangLens corrects errors, explains what was wrong (in your native language), and shows alternative ways to say it.
- **Pronunciation** — Ask "how do I pronounce [word]?" or just say a single word. Get IPA phonetics, a sound-by-sound breakdown in your native language, and common mistakes to avoid.

### Learning History

Browse your full learning history from the menu bar:

- All past queries grouped by date
- Search by word, translation, or context
- Delete individual entries or clear all
- Opens in a dedicated resizable window

### Text-to-Speech

Hear how words and sentences actually sound:

- Play button on the overlay and menu bar to listen to any result
- Auto-plays pronunciation when in pronunciation mode
- Uses macOS native speech synthesis — supports all 18 languages
- Speaks translations, corrected sentences, or individual words

### Floating Overlay

Responses appear in a floating overlay on top of any app:

- Color-coded mode badges (Translation, Correction, Pronunciation)
- Interactive play button to hear the result spoken aloud
- Hidden from screen sharing by default (Zoom, Meet, Teams)
- Configurable display duration

### Menu Bar App

- Always accessible from the macOS menu bar
- Shows current language pair and learning level
- Quick access to start listening, history, and settings
- Displays last result at a glance

### Speech Recognition

- On-device speech-to-text via WhisperKit (no audio sent to the cloud)
- Configurable Whisper model (tiny, base, small, medium)

### Hotkey

- **Cmd+Shift+L** — Toggle recording
- **Esc** — Cancel recording

### Settings

- Native and target language selection (18 languages supported)
- Learning level (beginner, intermediate, advanced)
- OpenAI API key (stored in Keychain)
- Whisper model selection
- Overlay duration
- Screen share visibility toggle

## Requirements

- macOS 14.0+
- OpenAI API key
- Microphone permission
- Accessibility permission

## Setup

1. Clone the repo and open in Xcode
2. Build and run
3. Grant Microphone and Accessibility permissions when prompted
4. Open Settings from the menu bar and enter your OpenAI API key
5. Press **Cmd+Shift+L** to start learning
