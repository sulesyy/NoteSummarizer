#  Notes AI – Smart Text Summarizer for iOS

Notes AI is a modern iOS application that summarizes long texts instantly using AI.
The app allows users to summarize typed text, scanned documents, or PDF files into concise and readable summaries.

Built with **SwiftUI**, **VisionKit OCR**, **Natural Language Processing**, and **AI-powered summarization**.

---

##  Features

•  **AI Text Summarization**
Generate intelligent summaries from long text inputs.

•  **PDF Import Support**
Extract text directly from PDF files and summarize it instantly.

•  **Document Scanner (OCR)**
Scan physical documents using the device camera and convert them into text using Apple Vision OCR.

•  **Text to Speech**
Listen to generated summaries with automatic language detection.

•  **History System**
All generated summaries are saved locally for later access.

•  **Share & Copy**
Copy summaries to clipboard or share them via iOS share sheet.

•  **Dark / Light / System Theme**
User-selectable theme support.

•  **Haptic Feedback**
Interactive vibration feedback for better UX.

---

##  Technologies Used

* SwiftUI
* VisionKit
* Vision OCR
* AVFoundation (Text to Speech)
* NaturalLanguage Framework
* PDFKit
* UserDefaults (Local Storage)
* Streaming AI API Integration
* Groq AI API (LLaMA 3.1 model)

---

##  Screens

Main capabilities include:

* Writing or pasting text
* Importing PDF documents
* Scanning documents with camera
* Choosing summary style:

  * Short
  * Detailed
  * Bullet Points
* Listening to summaries
* Saving summaries automatically

---

##  Architecture

The project follows a modular SwiftUI structure including:

* **ContentView** – Main UI and summarization workflow
* **SpeechManager** – Text-to-Speech system
* **HapticManager** – User feedback interactions
* **DocumentCameraView** – OCR document scanning
* **HistoryView** – Saved summaries interface

---

##  How It Works

1. User enters text, scans a document, or uploads a PDF
2. The text is sent to an AI summarization API
3. Streaming responses generate the summary in real time
4. The summary is displayed and stored in local history

---

##  API Setup

Insert your API key in the following section of the code:

```swift
let apiKey = "YOUR_API_KEY_HERE"
```

The app currently uses:

```
Groq AI API
Model: llama-3.1-8b-instant
```

---

##  Installation

Clone the repository:

```
git clone https://github.com/sulesyy/NoteSummarizer.git
```

Open the project in **Xcode** and run on a real device to use camera scanning features.

---

##  Future Improvements

* iCloud synchronization
* Export summaries as PDF
* Multi-language UI support
* Offline summarization models
* AI keyword extraction

---

##  Developer

 Şule Yılmaz
 
Software Engineering Student

iOS Developer

---

## ⭐ Project Goal

This project was created to explore **AI-powered productivity tools on iOS**, combining **machine learning, OCR, and natural language processing** to simplify reading and note-taking workflows.
<img width="432" height="946" alt="Ekran Resmi 2026-03-07 23 53 44" src="https://github.com/user-attachments/assets/e46f6d14-c0ff-4ed8-8210-c086734c9dda" />
<img width="432" height="946" alt="Ekran Resmi 2026-03-07 23 54 30" src="https://github.com/user-attachments/assets/f671879d-2bce-4437-a49b-52396cf2cb91" />
<img width="432" height="946" alt="Ekran Resmi 2026-03-07 23 54 03" src="https://github.com/user-attachments/assets/5eb27f5a-2217-41b0-9ea5-527e4ef448bd" />
<img width="432" height="946" alt="Ekran Resmi 2026-03-07 23 54 13" src="https://github.com/user-attachments/assets/7330a979-f886-4f85-be8a-1d608ee0575c" />

