# Personal Voice Note App — Requirements

## Overview

This document describes the requirements to build a private iPhone app for personal note-taking using voice and text. The app will allow the user to create short voice or text notes about places, websites, or people (for example: pros and cons of a place, or someone's kids' names). All data will be stored locally on the device. The app is for a single-user, private use and will not be published to the App Store.

## Goals

- Capture quick voice notes and convert them to text.
- Allow direct text input as an alternative to voice.
- Tag notes by place name, website URL, or person name to allow fast lookup.
- Perform fast local search when user asks (voice or text) for previously saved information.
- Keep all data on the device (local-only storage).
- Support English only (MVP requirement).

## Non-goals (MVP exclusions)

- Multi-language support (only English supported in MVP).
- Cloud sync or backup (offline/local-only for MVP).
- Sharing, collaboration, or publishing notes.
- Advanced natural language understanding beyond simple intent extraction and search.

## Platforms & Distribution

- Target: iPhone running a recent iOS version (recommend iOS 15+).
- Development: Xcode with Swift and SwiftUI.
- Distribution: Sideload using a personal Apple ID (free) or an Apple Developer Program account for longer provisioning.

## Functional Requirements

1. Authentication & Access
   - No user accounts required. Access to the app is via the device lock-screen security.

2. Recording & Transcription
   - Allow the user to record a short voice note via a prominent `Record` button (microphone icon).
   - Use iOS Speech framework (`SFSpeechRecognizer`) to transcribe voice to text.
   - Default language: English. The app should only request English recognition resources.
   - **Voice Button Behavior:**
     - Tap the microphone button to START recording
     - Tap the microphone button again to STOP recording
     - Stopping the recording displays the transcript in the text field below
     - The voice button does NOT auto-save the entry
   - **Submit Button:**
     - A separate "Submit" button is displayed below the text field
     - The Submit button saves the transcribed entry to the database
     - Submit is only enabled when there is text in the transcript field
   - Live transcription should display the text the user speaks in near real-time in the text field.
   - The live transcript text field MUST be editable so the user can correct misrecognized words (accent handling).

3. Text Input
   - Allow manual text entry for pros, cons, place names, URLs, or person details.

4. Data Model
   - Store notes as `Entry` objects with fields:
     - `id: UUID`
     - `title: String` — place name, person name, or website title
     - `type: String` — enum: `place | website | person | generic`
     - `pros: String?`
     - `cons: String?`
     - `notes: String?` — free text
     - `url: String?` — website URL
     - `createdAt: Date`
     - `latitude: Double?` — optional
     - `longitude: Double?` — optional

5. Storage
   - Persist all data locally using Core Data (recommended) or a local JSON/SQLite file.
   - Database must be queryable for exact and simple fuzzy matches.

6. Search & Lookup
   - Provide a text search bar for quick lookup by title or URL.
   - Provide a fast, global search over all saved entries as part of the MVP — searching must be low-latency and return results quickly.
   - Allow voice queries for queries like: "What are the pros of [place]?" or "What is AB person's kid name?"
   - Matching rules:
     - Normalize titles (lowercase, trim whitespace).
     - First check exact `title` or `url` matches.
     - Then check `CONTAINS[cd]` matches for partial searches.
     - For person names, allow tokenized search (first/last name match).
   - If no results found, display: `No results found`.

7. Query Intent Extraction (MVP)
    - MVP will implement a simple rule-based extraction for queries to identify:
       - The intent (`ask_pros`, `ask_cons`, `ask_kids`, `ask_notes`, `show_results`)
       - The target entity (`place`, `website`, or `person`) and its `title`.    - **Enhanced Voice Parsing (January 2026):**
       - Detect entry type from explicit mentions: "name of the place", "name of the person", "website"
       - Extract structured data from voice input:
         - Title: "name of the place/person X" → title = X
         - Type: Automatically set based on keywords (place, person, website, generic)
         - Pros: Parse "pros:" or "positive:" sections
         - Cons: Parse "cons:" or "negative:" sections
       - Example: "Name of the place Central Park, pros: beautiful, spacious, cons: crowded"
         → Creates place entry with extracted pros/cons    - Example patterns:
       - "What are the pros of [X]?" -> `ask_pros`, target=`X`
       - "What is [Person] kid name?" -> `ask_kids`, target=`Person`
       - "Show Results." (voice command) -> `show_results` (display results tab)

8. UI
   - Main view: Search bar, list of `Entry` items (title + short snippet), `New Entry` button.
   - New Entry view: fields for `title`, `type`, `pros`, `cons`, `notes`, `url`, `Record` button.
   - Result view: display `pros`, `cons`, `notes`, and metadata.
   - **Results List:**
     - Swipe left on any entry to delete it (with confirmation dialog)
     - Entries sorted chronologically (newest first)
   - **Voice Recording Area:**
     - Voice button shrinks when keyboard is visible so user can see what they're typing
     - Multiple voice recordings append to the transcript (not replace)
     - Example: Record → Stop → Record again = appends new text to previous
   - Front Page (Home): prominent `Voice` icon (tap to start live transcription), `Results` tab/button (shows previously saved converted voice memos), and quick `New Entry` button.
   - Results tab: shows a chronological or relevance-sorted list of previous entries.
   - Voice trigger: when the user says the phrase "Show Results. Over" the app should switch to the Results tab and display matches (speech recognition should listen for the trigger in the app's active session).

9. Import/Export (Optional)
   - Optional export to a local file (JSON) for backup. No cloud sync in MVP.

10. Privacy
    - All data remains on the device by default.
    - No analytics or remote logging.

## Non-functional Requirements

- Language: English only.
- Performance: 
  - App launch time should be fast (< 3 seconds to display main UI)
  - Services (database, speech) are initialized on-demand to reduce launch time
  - Search responses should return under 300ms for databases with a few thousand entries.
- Storage limits: App must handle at least 10,000 short entries without UI lag.
- Battery: Recording sessions should be short (user-initiated). Avoid continuous background recording.

## Offline vs Online

- MVP: Use online/system-provided speech recognition if device lacks local models. The app should work while online for best speech recognition.
- Post-MVP: Add true offline-only speech recognition by requesting on-device models and fallback logic.

## Example User Scenarios

1. Add pros/cons for a restaurant
   - User taps `New Entry`, sets `type=place`, enters `title=Joe's Diner`, taps `Record`, speaks pros and cons, taps `Save`.
   - Result: `Entry` saved locally with transcribed `pros` and `cons`.

2. Lookup pros later by voice
   - User opens the app and speaks: "What are the pros of Joe's Diner?"
   - App extracts intent `ask_pros`, finds `Joe's Diner`, and displays the `pros` text.

3. Save a person's kid name
   - User saves a person entry: `title=AB`, `type=person`, `notes=kids: Anna, Ben` (via voice or text) and saves.
   - Later user asks: "What was AB person kid name?" App matches person `AB` and displays `Anna, Ben`.

## Implementation Notes & Suggestions

- Prefer `SwiftUI` for UI; use `Combine` or `async/await` for asynchronous tasks.
- Use `Core Data` with lightweight migration for the local store.
- For transcription, implement a simple recorder manager that requests authorization for `AVAudioSession` and `SFSpeechRecognizer`.
- Implement a small natural language rule-based parser for English queries—no heavy ML needed for MVP.

## AI Assistant Behavior (MVP)

- The app should behave like a lightweight personal assistant for previously provided information. If the user asks a question that references information they previously recorded (for example, "What was AB person's kid name?"), the app should locate the relevant `Entry` and display the stored answer on screen.
- This is within MVP scope: rule-based intent/entity matching and direct lookup of stored fields. Advanced ML-based NLU is a post-MVP enhancement.

## Bottom: User Original Instructions (Verbatim)
Set 1:
"What does it take to build an app that I can only use in my iphone - not willing to publish the app into the appstore, only intend to use as personal note taking app
Idea of the app is 
* When I open the app, I give voice note to the app Pros and Cons of the place or a website I visited
* It saves the data and converts it into text and displays the same on the UI of the APP. 
* When ever I reopen the app, if I ask the app for what are the pro or Cons of place. It should display the existing result of the location (if it exisits) or esle display message - No results found.
* All data is saved in local iphone storage "
Set 2:
"Voice input should display the text I say live on screen and I should be able to edit the words when my voice is not understandable (accent issue while voice prompt)
Also, should be able to search all the previous results quickly. This is MVP. (Advanced natural language understanding beyond simple intent extraction and search.)
Basically an AI assistant, if I ask a question that I previously mentioned it should be able to gather the info I gave it before and display the results.
No login required
Front Page should show VOice icon, results tab (of user previous saved infro converted from voice memos.)
Results should be displayed on the screen when I say the word "Show Results. Over"
also, the instructiins that I gave to you in my words should be added to the bottom of the requiremtns document as a bottom block for my personal reference."

Set 3 (January 22, 2026 - UI/UX Refinements):
"1. App launch start time is very slow with a White screen displayed for more than 30 seconds
2. Voice button stop should display the voice prompt in the text field that is available below the Voice button. While recording and pressing the voice button again should NOT save it as a response 
3. A separate button should be available below the Text box field that says Submit
4. Selecting the Submit should save the response. 
5. Text field should be editable by the user if the voice is not recognized correctly."

Set 4 (January 22, 2026 - Advanced Features):
"1. Results tab saved results should be able to left slide to Delete
2. When I try to edit the text from the box, I see a Big Voice button and a empty rectangular box. I cannot see what I'm typing as top half of the device is covered with Voice button and bottom half is covered by Keyboard. Can you reduce the Voice button when I'm typing in using the Key board
3. If I start the Record and stop - I see the text added to the field - Good. But If I tap the Record again then the user input via voice is replacing what I said before. Record start and stop then record again should append the text I spoke later to the previous text. 
4. Mainly if I record something with voice and I say 'Name of the <place>', ['pros/Positive': <a,b,c,d>] and ['cons/negative': <a,b,c,d>], then voice should understand and add that as a PLACE/Person new entry. Instead all the voice inputs are just saved as generic tag."

Set 5 (January 30, 2026 - UX Improvements):
"1. Use all the synonyms like (Good, bad), (pro, con), (like, dislike) and any other related pairs to listen from the user input and add the user input (text, voice) and add to the results accordingly.
2. Make the (place, person, website, etc..) field selection mandatory before submitting.
3. Clear, Manual buttons' text is showing in 2 and 3 lines"

Set 6 (January 30, 2026 - App Polish & Performance):
"1. App name should be ProCon
2. On launch App name title should be 'Pros & Cons' not 'Voice Notes'
3. Change Clear button color to the same color as Website button (orange)
4. Lock the app usage to Portrait mode only. App shouldn't change to Landscape app.
5. App should be optimized to handle large userbase
6. App launch time should be quick with all the previous results loaded."

Set 7 (January 30, 2026 - Submit Button & Manual Button Fixes):
"1. Submit button not working highlighted when I have some voice or text in the box. Not able to click Submit button.
2. Saved '<result>' has Grey background can you change it to Light Green
3. Submit button should be green when I have some text or voice input in the field but Submit button should only work when I selected the labels: place, person, website, etc... or else it should give me a small bubble error when clicking Submit button to ask the user to select label
4. When I have text in the box of the Voice home screen and I select 'Manual' button that text is saved in the Notes which is good but when I hit back from the same Manual page that text is not present in the Main screen Text box for the user to edit."

Set 8 (January 30, 2026 - Results Page Search & Filter):
"1. Add a Search field in results page and it should be Searchable
2. Also, add Filters options for the labels as a drop down
3. When selected, the Drop down should filter that label results"


## Implementation Changes (January 22, 2026 - Build 2)

### Completed Features:
1. **Editable Results** - Results can now be edited from the detail view with a dedicated Edit button. User can modify title, type, pros, cons, notes, and URL with save/cancel options.

2. **Raw Text Storage & Display** - Added `rawText` field to Entry model to store the original voice/typed input before processing. Displayed at the bottom of each result detail view under "Original Input (Raw Text)" section.

3. **Improved Voice Recognition** - Enhanced SpeechService with:
   - Changed to `dictation` listen mode for better continuous speech handling
   - Extended listen time to 2 minutes for longer recordings
   - Increased pause tolerance to 5 seconds for natural speech patterns
   - Added error recovery and debug logging
   - Improved reliability with `cancelOnError: false` setting

4. **Type Selector Buttons** - Added horizontal scrollable button row below text field in HomeScreen with options: **Place**, **Person**, **Website**, **Generic**. Type is automatically selected based on voice input parsing and user selection.

5. **Always-Enabled Submit Button** - Submit button is now green and fully clickable whenever text is present in the transcript field, regardless of keyboard state. Users can submit directly without closing the keyboard.

6. **UI Layout Fixed** - Resolved "Bottom Overflowed by 66 pixels" issue by optimizing the search results container from `Expanded` to `Flexible` layout with proper scrolling and sizing constraints.

### Database Changes:
- Upgraded database schema from version 2 to version 3
- Added `rawText TEXT` column to entries table
- Added `updateEntry()` method to DbService for edit functionality

### Code Modifications:
- **lib/models/entry.dart**: Added rawText field, updated serialization, added copyWith method
- **lib/services/db_service.dart**: Implemented version 3 migration, updateEntry method
- **lib/screens/home_screen.dart**: Added type state management, type selector UI, fixed submit logic and layout
- **lib/screens/entry_detail_screen.dart**: Converted to StatefulWidget with full editing capability
- **lib/services/speech_service.dart**: Enhanced recognition settings and error handling
- **lib/screens/results_screen.dart**: Fixed syntax error in Dismissible widget

### Build Status:
- ✅ Build succeeded on iOS device (Vintage, iOS 26.3)
- ✅ All 6 features tested and deployed

## Implementation Changes (January 30, 2026 - Build 3)

### Completed Features:
1. **Synonym Support for Pros/Cons** - Enhanced parsing to recognize multiple keyword variations:
   - **Pros synonyms**: pros, good, positive, like, advantages
   - **Cons synonyms**: cons, bad, negative, dislike, disadvantages
   - Works in both voice/text input parsing AND query searches
   - Examples: "I like: peaceful" or "dislike: crowded" now correctly extracted

2. **Mandatory Type Selection** - Type selection is now required before submission:
   - Submit button starts disabled (grey) when no type is selected
   - Type selection defaults to empty (no default value)
   - Submit button onl30 (Build 3 - UX Improvementt is present AND a type is selected
   - Forces user to explicitly choose: Place, Person, Website, or Generic

3. **Button Layout Fixed** - Resolved text wrapping on Clear and Manual buttons:
   - Removed icons from Clear and Manual buttons to save horizontal space
   - Added `FittedBox` with `scaleDown` to prevent multi-line text wrapping
   - Set explicit padding and font sizing for consistent single-line display
   - All three buttons (Clear, Submit, Manual) now display cleanly in one row

### Code Modifications:
- **lib/screens/home_screen.dart**: 
  - Enhanced pros/cons extraction with synonym regex patterns
  - Changed default `_selectedType` from 'place' to empty string
  - Updated Submit button logic to check both text AND type selection
  - Refactored Clear/Manual buttons to remove icons and use FittedBox
- **lib/services/query_parser.dart**: 
  - Added synonym support in query parsing for voice/text searches
  - Extended pattern matching for pros queries: good about, positive about, like about
  - Extended pattern matching for cons queries: bad about, negative about, dislike about

### Build Status:
- ✅ Build succeeded on iOS Simulator (iPhone 16 Pro)
- ✅ All 3 features tested and working
- ✅ No syntax errors in main codebase

## Implementation Changes (January 30, 2026 - Build 4)

### Completed Features:
1. **App Branding** - Updated app name and title:
   - App display name changed to **"ProCon"** (visible on home screen)
   - App title changed to **"Pros & Cons"** (visible in app bar)
   - Consistent branding across iOS and Flutter

2. **Clear Button Styling** - Changed Clear button color from grey to orange:
   - Matches Website button color for visual consistency
   - Improves UI harmony and button visibility

3. **Portrait Mode Lock** - App is now locked to portrait orientation only:
   - Added `SystemChrome.setPreferredOrientations` in main.dart
   - Updated iOS Info.plist to only allow `UIInterfaceOrientationPortrait`
   - Prevents landscape mode rotation for better UX consistency

4. **Database Optimization for Large Datasets** - Added indexes for fast queries:
   - Created index on `title` column with case-insensitive collation
   - Created index on `type` column for filtered searches
   - Created descending index on `createdAt` for chronological sorting
   - Optimizes query performance for 10,000+ entries

5. **Fast App Launch** - Optimized startup performance:
   - Services (database, speech) initialized on-demand
   - Minimal blocking operations during app launch
   - Results load efficiently with indexed queries

### Code Modifications:
- **lib/main.dart**: 
  - Added portrait mode lock with SystemChrome
  - Changed app title from "ProCon Voice Notes" to "Pros & Cons"
  - Added flutter/services.dart import for orientation control
- **lib/screens/home_screen.dart**: 
  - Changed Clear button backgroundColor from Colors.grey to Colors.orange
- **ios/Runner/Info.plist**: 
  - Changed CFBundleDisplayName to "ProCon"
  - Removed landscape orientations from UISupportedInterfaceOrientations
- **lib/services/db_service.dart**: 
  - Added three database indexes in onCreate: idx_title, idx_type, idx_createdAt
  - Indexes improve query performance on large datasets

### Build Status:
- ✅ All 6 features implemented
- ⏳ Ready for testing on device/simulator

## Implementation Changes (January 30, 2026 - Build 5)

### Completed Features:
1. **Submit Button Reactivity Fixed** - Submit button now properly responds to text changes:
   - Added TextEditingController listener in initState to trigger setState on text changes
   - Button is always clickable (never disabled)
   - Shows **green** when text is present, **grey** when empty
   - Displays validation snackbar messages when clicked without proper conditions

2. **Snackbar Color Updated** - Changed success message background from dark green to **light green** (Colors.lightGreen) for softer visual feedback

3. **Smart Submit Validation** -6 - Search & Filternced:
   - Visual: Green when text present (regardless of type selection)
   - Functional: Validates both text AND type selection on click
   - Shows orange snackbar "Please enter some text first" if text empty
   - Shows orange snackbar "Please select a type..." if type not selected
   - Only saves entry when both conditions met

4. **Manual Button Text Preservation** - Fixed text persistence issue:
   - Removed `.then((_) => _clearTranscript())` from Manual button navigation
   - Text now remains in main screen text box when returning from Manual entry screen
   - Users can continue editing the same text after checking Manual view
   - Text only clears on explicit Clear button press or successful save

### Code Modifications:
- **lib/screens/home_screen.dart**: 
  - Added `_transcriptController.addListener()` in initState for reactive button updates
  - Changed submit button onPressed from conditional `null` to always-enabled with validation
  - Updated button backgroundColor logic to only check text (not type)
  - Removed _clearTranscript call from Manual button's Navigator.push().then()
  - Changed snackbar backgroundColor from Colors.green to Colors.lightGreen

### Build Status:
- ✅ All 4 fixes implemented and tested
- ✅ Submit button now fully functional with proper validation

## Implementation Changes (January 30, 2026 - Build 6)

### Completed Features:
1. **Search Functionality in Results Page** - Added real-time search capability:
   - Search field at top of results page with search icon
   - Live filtering as user types (searches across title, pros, cons, notes)
   - Clear button (X) appears when text is entered
   - Case-insensitive search
   - Shows "No matching entries" when search has no results

2. **Type Filter Dropdown** - Added dropdown filter for entry types:
   - Filter options: All Types, Place, Person, Website, Generic
   - Dropdown with emoji icons for visual clarity (🏢 🌐 👤 📝)
   - Instant filtering when selection changes
   - Works in combination with search filter

3. **Combined Search & Filter Logic** - Both filters work together:
   - Results must match BOTH search text AND selected type
   - Real-time updates as filters change
   - Result count updates in app bar title
   - Efficient filtering using `where()` on local list

### Code Modifications:
- **lib/screens/results_screen.dart**: 
  - Added `_filteredEntries` list to store filtered results
  - Added `_searchController` TextEditingController for search input
  - Added `_selectedTypeFilter` state variable (default: 'all')
  - Implemented `_filterEntries()` method with combined search and type filtering
  - Added search TextField with clear button in grey container
  - Added type filter Row with dropdown showing all entry types
  - Updated ListView to use `_filteredEntries` instead of `_entries`
  - Updated empty state to differentiate between no entries vs no matching entries
  - Added dispose method to clean up search controller

### Build Status:
- ✅ All 3 features implemented
- ✅ Search and filter working together seamlessly
- ✅ Ready for testing

## Future Enhancements (Post-MVP)

- On-device speech recognition for offline operation.
- Improved NLP for fuzzy intent extraction and entity linking.
- Face/Contact integration to auto-suggest person names.
- Encrypted local storage and secure backups.
- Voice trigger phrase refinement for "Show Results" command.

---

## Set 9 - App Stability & Export/Import (2026-01-30)

### User Request:
> "I ran the app in my connected real device. App ran opened > and worked fine. Once I disconnected the cable and launch the app, app crashes immediately and doesn't launch at all. Fix this. and also implement following feature
>
> Create an export and import options
> Export all the results into icloud
> When user selects to export - all results are saved in icloud
> Similarly on new install - Select Import and import from the icloud"

### Requirements:
1. **App Crash Fix**: Fix app crashing when cable disconnected from physical device
2. **Export to iCloud**: Export all entries to iCloud Drive as JSON backup
3. **Import from iCloud**: Import entries from iCloud backup files
4. **Backup Management**: List and select from available backup files
5. **User Feedback**: Show success/error messages for export/import operations

### Analysis:
- App crash is caused by debug provisioning profile expiring when debugger disconnects
- Solution: Build in Profile/Release mode or use paid Apple Developer account
- Export/Import requires iCloud capability enabled in Xcode
- Use JSON format for cross-device compatibility

---

## Build 7 - iCloud Export/Import (2026-01-30)

### Features Implemented:
1. **Export to iCloud**
   - Save all entries as JSON backup to iCloud Drive
   - Backup files include timestamp, version, entry count
   - Export to `iCloud/ProCon/` folder
   - Fallback to local storage if iCloud unavailable

2. **Import from iCloud**
   - List all available backup files from iCloud
   - Show backup date and entry count
   - Import entries from selected backup
   - Refresh results list after successful import

3. **Backup Management**
   - Display backup files sorted by date (newest first)
   - Show backup metadata (name, date, entry count)
   - File selection dialog with cancel option

4. **User Feedback**
   - Success messages in green
   - Error messages in red
   - No backups found notification in orange
   - Display import count on success

### Code Modifications:
- **lib/services/export_import_service.dart** (NEW FILE):
  - `exportToICloud()`: Exports all entries to iCloud as JSON
  - `importFromICloud(filePath)`: Imports entries from backup file
  - `getBackupFiles()`: Lists available backups with metadata
  - `_getICloudDirectory()`: Gets iCloud Drive path on iOS
  - `exportToLocal()`: Fallback for non-iCloud export
  - JSON format: `{version, exportDate, entriesCount, entries[]}`

- **lib/screens/results_screen.dart**:
  - Added import for `export_import_service.dart` and `dart:io`
  - Added `ExportImportService` instance
  - Replaced refresh IconButton with PopupMenuButton
  - Added menu items: Export to iCloud, Import from iCloud, Refresh
  - Implemented `_exportData()`: Calls export service, shows snackbar
  - Implemented `_importData()`: Shows backup picker, imports selected file, refreshes list

- **Xcode Project** (REQUIRED):
  - Enable iCloud capability in project settings
  - Add iCloud Documents container
  - Required for export/import to work

### Build Status:
- ✅ Export/Import service created
- ✅ UI integration complete
- ⚠️ Requires iCloud capability enabled in Xcode
- ⚠️ App crash issue requires provisioning profile fix

---

File created by project assistant on 2026-01-07.
Last updated: 2026-01-30 (Build 7 - iCloud Export/Import Completed)
