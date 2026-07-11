# Notes AI - iOS Text Summarizer

Notes AI is a SwiftUI iOS app for summarizing long text, scanned documents, and PDF files. It combines OCR, PDF text extraction, text-to-speech, local history, theme support, and streaming AI summarization in one productivity-focused mobile experience.

## Highlights

- Summarizes typed or pasted text with selectable output styles
- Imports PDF files and extracts readable text with PDFKit
- Scans physical documents using VisionKit and Apple Vision OCR
- Streams AI responses from the Groq API
- Saves generated summaries locally for later access
- Supports text-to-speech with language-aware voice selection
- Includes copy, share, haptic feedback, and light/dark/system theme options

## Tech Stack

- SwiftUI
- VisionKit and Vision OCR
- PDFKit
- AVFoundation
- NaturalLanguage
- UserDefaults / local persistence
- Streaming API integration
- Groq API with LLaMA model

## Architecture

The project is organized around reusable SwiftUI views and small helper managers:

- `ContentView` handles the main summarization workflow
- `DocumentCameraView` wraps VisionKit document scanning
- `SpeechManager` manages text-to-speech playback
- `HapticManager` centralizes feedback interactions
- `SavedSummary` stores summary history data

## How It Works

1. The user enters text, scans a document, or imports a PDF.
2. The app extracts text when needed using Vision OCR or PDFKit.
3. The selected summary style is sent to the AI API.
4. The streamed result is displayed in the UI and saved locally.
5. The user can copy, share, or listen to the summary.

## Setup

Clone the repository:

```bash
git clone https://github.com/sulesyy/NoteSummarizer.git
```

Open the project in Xcode and run it on a real iOS device for camera scanning support.

Add your own Groq API key in the API configuration section before running the summarization feature:

```swift
let apiKey = "YOUR_API_KEY_HERE"
```

Do not commit real API keys to the repository.

## Future Improvements

- Move API key handling to a safer configuration layer
- Add iCloud sync for summary history
- Export summaries as PDF
- Add multi-language app localization
- Split the main view into smaller feature modules



<img width="432" height="946" alt="Ekran Resmi 2026-03-07 23 53 44" src="https://github.com/user-attachments/assets/e46f6d14-c0ff-4ed8-8210-c086734c9dda" />
<img width="432" height="946" alt="Ekran Resmi 2026-03-07 23 54 30" src="https://github.com/user-attachments/assets/f671879d-2bce-4437-a49b-52396cf2cb91" />
<img width="432" height="946" alt="Ekran Resmi 2026-03-07 23 54 03" src="https://github.com/user-attachments/assets/5eb27f5a-2217-41b0-9ea5-527e4ef448bd" />
<img width="432" height="946" alt="Ekran Resmi 2026-03-07 23 54 13" src="https://github.com/user-attachments/assets/7330a979-f886-4f85-be8a-1d608ee0575c" />

