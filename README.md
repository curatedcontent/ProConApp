# ProCon Voice Notes (Flutter)

A comprehensive private voice note app that converts speech to text and stores data locally. Built to match all requirements from the original iOS app specification.

## Features ✨

### Core Functionality
- **Live Voice Transcription**: Tap the voice icon to start recording, see live transcription, edit text in real-time
- **Voice Query Processing**: Ask questions like "What are the pros of Joe's Diner?" and get instant answers
- **Voice Trigger**: Say "Show Results. Over" to switch to Results tab automatically
- **Local-Only Storage**: All data stays on your device using SQLite

### Data Model
Complete Entry objects with:
- Title, Type (place/person/website/generic)
- Pros & Cons fields for structured note-taking
- Notes field (great for kids' names, additional info)
- Optional URL field for websites
- Timestamps and optional location data

### Smart Search & Queries
- **Intent Recognition**: Understands natural language queries
  - "What are the pros of [place]?"
  - "What is [person] kid name?"
  - "What are the cons of [website]?"
- **Fast Search**: Real-time search across all entries
- **No Results Handling**: Shows "No results found" when appropriate

### UI/UX
- **Tabbed Interface**: Voice tab (prominent voice icon) + Results tab
- **Live Editing**: Transcription appears in real-time and is fully editable
- **Rich Entry Form**: Structured form with type selection, pros/cons, notes
- **Detailed Views**: Full entry viewer with organized sections

## How to Run 🚀

### Prerequisites
1. Install Flutter SDK: https://flutter.dev/docs/get-started/install
2. For iOS: Xcode + iOS device or simulator
3. For Android: Android Studio + device or emulator

### Quick Start
```bash
cd ProConApp_flutter
flutter pub get
flutter run
```

### iOS Permissions
The app includes proper iOS permissions in `ios/Runner/Info.plist`:
- `NSMicrophoneUsageDescription`: For recording voice notes
- `NSSpeechRecognitionUsageDescription`: For speech-to-text conversion

### Platform Notes
- **iOS**: Uses native speech recognition (requires internet for best results)
- **Android**: Uses Android speech recognition services
- **Web**: Uses the browser's Web Speech API (Chrome/Edge recommended); requires HTTPS or localhost
- **Storage**: Local database (Sembast) - SQLite-backed on iOS/Android/desktop, IndexedDB on web (no cloud sync)

## Running on the Web 🌐

```bash
flutter run -d chrome
```

To produce a production build (used by the GitHub Pages deploy workflow):
```bash
flutter build web --release --base-href /ProConApp/ --no-web-resources-cdn
```
`--no-web-resources-cdn` bundles the CanvasKit renderer locally instead of fetching it
from Google's CDN, keeping the app self-contained.

### Deployment
Pushing to `main` runs `.github/workflows/deploy-web.yml`, which builds the web app and
publishes it via GitHub Pages. The base href (`/ProConApp/`) matches this repository's
name, so it works both at the default project-pages URL
(`https://curatedcontent.github.io/ProConApp/`) and at the same subpath under a custom
domain inherited from the account's user/org Pages site (`https://catalogentry.com/ProConApp/`).

## Usage Guide 📱

### Recording Voice Notes
1. Open the app (Voice tab should be active)
2. Tap the large voice icon to start recording
3. Speak your note - you'll see live transcription
4. Edit the text if needed (handles accent issues)
5. Tap "New Entry" to structure and save the note

### Adding Structured Entries
1. From Voice tab, tap "New Entry" (or after recording)
2. Fill in:
   - **Title**: Place name, person name, or website
   - **Type**: Select place/person/website/generic
   - **Pros**: Good things, advantages
   - **Cons**: Issues, disadvantages  
   - **Notes**: Additional info (for people: kids' names, etc.)
   - **URL**: For websites only
3. Tap "Save Entry"

### Voice Queries
Ask questions using natural language:
- "What are the pros of Joe's Diner?"
- "What is AB person kid name?"
- "What are the cons of example.com?"
- "Show Results. Over" (switches to Results tab)

### Searching & Results
- Use search bar on Voice tab for instant search
- Results tab shows all entries chronologically
- Tap any entry to view full details
- Long press or menu to delete entries

## Technical Implementation 🛠

### Dependencies
- `speech_to_text`: Voice recognition and live transcription
- `sqflite`: Local SQLite database for entries
- `path_provider`: App documents directory access

### Architecture
- **Models**: Complete Entry class matching requirements
- **Services**: 
  - SpeechService: Handles recording and transcription
  - DbService: SQLite operations and search
  - QueryParser: Natural language intent extraction
- **Screens**: 
  - MainScreen: Tabbed interface
  - HomeScreen: Voice recording and search
  - ResultsScreen: Entry list and management
  - NewEntryScreen: Structured entry form
  - EntryDetailScreen: Full entry viewer

### Query Intent Extraction
Rule-based parser that recognizes:
- `ask_pros`: "pros of [target]"
- `ask_cons`: "cons of [target]"  
- `ask_kids`: "[person] kid name"
- `ask_notes`: "notes about [target]"
- `show_results`: "Show Results. Over"

## Privacy & Security 🔒

- **No User Accounts**: App access controlled by device lock screen
- **Local Storage Only**: All data stays on device (SQLite)
- **No Analytics**: No tracking or remote logging
- **Permissions**: Only microphone and speech recognition (clearly explained)

## Future Enhancements 🔮

The current implementation covers all MVP requirements. Potential additions:
- Offline speech recognition models
- Export to local JSON files
- Enhanced NLP for fuzzy matching
- Location tagging integration
- Encrypted storage options

---

**Note**: This Flutter implementation provides the exact same functionality as specified in the original iOS requirements, with cross-platform compatibility and a native mobile experience.
