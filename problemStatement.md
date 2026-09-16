# Flutter User Session Visual Recording / Analysis — Original Requirement

This is the original problem statement that kicked off this project, kept as-is for historical context. It predates the implementation — see `recorderPlan.md` for how the three approaches were actually built and ranked.


## Current goal

When a user enters a particular section of the app:

- Automatically capture the user's visual activity.
- No manual "Start Recording" action from the user.
- Maximum session duration: 5 minutes.
- Eventually send the captured data to a server/AI for analysis.
- For now, focus only on the visual recording/capture approach — ignore Sentry, Crashlytics, analytics, etc.

## Important distinction

### 1. OS / device screen recording

Examples: `flutter_screen_recording`, `screen_record_plus`.

```
Flutter → MediaProjection (Android) / ReplayKit (iOS) → Device screen → Video
```

Characteristics:
- Captures the device display, potentially beyond the Flutter app.
- Requires OS-level user authorization.
- Produces an actual video.
- Not preferred here — the goal is automatic in-app capture without an OS screen-recording prompt.

### 2. Flutter widget / in-app video recording

Candidates: `widget_recorder_plus`, `flutter_widget_recorder`.

```
Flutter Widget → RepaintBoundary / Flutter rendering → Capture frames → Native H.264 encoder → MP4 → Upload
```

`widget_recorder_plus`:
- Captures rendered Flutter widget frames.
- Uses native video encoding (Android: `MediaCodec`, iOS: `AVAssetWriter`).
- Produces an actual H.264/MP4 video.
- Suitable when a real video file is specifically needed.
- Potentially captures scrolling, animations, dialogs, navigation, text, images, etc., as long as they're within the captured Flutter rendering tree.
- Platform/native views (WebView, Google Maps, camera preview, native video, `AndroidView`/`UiKitView`) may have limitations and need testing.

## Video file size

For H.264: `file size ≈ bitrate × duration`.

Approximate 5-minute examples:

| Bitrate | Approx. size |
|---|---|
| 1 Mbps | ≈ 37.5 MB |
| 2 Mbps | ≈ 75 MB |
| 3 Mbps | ≈ 112.5 MB |
| 5 Mbps | ≈ 187.5 MB |

Initial configuration to test: 720p, 15 or 30 FPS, H.264, no audio, maximum 5 minutes.

### Raw frame upload is not practical

A 720p RGBA frame: `1280 × 720 × 4 ≈ 3.5 MB`.

At 30 FPS: `≈ 105 MB/sec`. For 5 minutes: `≈ 31.5 GB`.

So `Flutter → raw frames → server → encoding` is impractical. Prefer `Flutter → native H.264 encoding → compressed MP4 → server/storage`.

## Clarity approach

Microsoft Clarity is fundamentally different from `widget_recorder_plus`. It does **not** primarily create an MP4 video — it captures rendering/session information and user interactions and reconstructs the session in the Clarity player:

```
Flutter → Clarity SDK → rendering information + visual assets + interactions → Clarity servers → session reconstruction → Clarity player
```

It's closer to recording the information needed to *reproduce* the visual session than recording every pixel as a video stream. The Clarity Mobile SDK supports Flutter and provides session-recording functionality.

Potential advantages:
- No need to build/host video storage ourselves.
- Much lower data volume than raw video.
- Designed specifically for session replay and user behavior analysis.
- Can capture interaction information in addition to visual information.
- Supports controls such as pause/resume, screen names, custom session IDs/tags, and screen recording rules.

**Important limitation**: Clarity session replay is not equivalent to an MP4 file. If the requirement is "give me an actual 5-minute MP4 I can upload to my own server/AI," Clarity is not the same solution as `widget_recorder_plus`.

### Clarity MCP

Microsoft provides a Clarity MCP server that lets an MCP-compatible AI agent query Clarity data/analytics:

```
Flutter App → Clarity Flutter SDK → Clarity servers → Clarity MCP → AI agent
```

**Important**: do not assume Clarity MCP can return/download the actual session recording as an MP4 — this needs verifying against current documentation before relying on MCP for video retrieval.

## Clarity + Hybrid approach

A hybrid approach for AI/user-behavior analysis: instead of continuously recording thousands of video frames, capture (1) important user events/state changes and (2) screenshots/key frames only when the visual state changes significantly.

Conceptual flow:

```
User enters screen        → Screenshot
User scrolls significantly → Screenshot
Dialog appears             → Screenshot
User taps Apply            → Screenshot
```

Stored as a lightweight timeline:

```
00:00 → screen entered      → screenshot
00:04 → significant scroll  → screenshot
00:08 → dialog appeared     → screenshot
00:12 → Apply tapped        → screenshot
```

Resulting data:

```
Session
├── timeline/events
├── screenshots/key frames
└── timestamps
```

Then: `Screenshots + timeline → Server → AI/Vision model → User behavior analysis`.

This avoids: 9,000+ frames for a 5-minute 30 FPS video, 75–150 MB MP4 uploads, continuous H.264 video encoding, and large storage/bandwidth costs.

### Hybrid approach architecture

```
Flutter App
      │
      ├── User/action/state detection
      │
      └── Key visual capture
               │
               ├── Screenshot on screen entry
               ├── Screenshot after significant scroll
               ├── Screenshot when dialog/modal appears
               ├── Screenshot after important UI transition
               └── Screenshot on important CTA/action
                       │
                       ▼
                Session Timeline
                       │
                       ▼
                    Server
                       │
                       ▼
                 AI / Vision
                       │
                       ▼
                  Analysis
```

## Possible three-way choice

**A. Actual video** — `widget_recorder_plus → H.264 → MP4 → Upload/storage → AI/video analysis`.
Use when: a real video is specifically needed, exact visual rendering over time matters, normal video playback is required.

**B. Clarity session replay** — `Clarity Flutter SDK → Clarity servers → Clarity session replay → Clarity UI / potentially MCP-based AI access`.
Use when: the main goal is session replay and user behavior analysis, an MP4 isn't needed, and a managed solution is preferred over building recording/storage infrastructure.

**C. Custom Clarity + Hybrid** — `Custom event/state tracking + key screenshots at important visual changes → lightweight session timeline → our server → AI/Vision analysis`.
Use when: control over the data is wanted, along with our own server/AI pipeline, much lower storage/bandwidth than full video, and enough visual context for AI without recording every frame.

## Current preference (at the time of writing)

The Hybrid approach:
- User enters screen → screenshot.
- Significant scroll → screenshot.
- Dialog/modal appears → screenshot.
- Important CTA/action → screenshot.
- Other meaningful visual state changes → screenshot.
- Store timestamps and event metadata alongside screenshots.
- Maximum observation window: 5 minutes.
- Send the resulting lightweight session package to our server for AI analysis.

Also worth investigating:
1. Whether Clarity can provide this functionality out of the box.
2. Whether Clarity MCP can expose/retrieve enough session information for an AI agent.
3. Whether Clarity + our own hybrid screenshots/events is better than building video recording.
4. If an actual video is required, whether `widget_recorder_plus` is the best Flutter implementation.

## Open questions at the time

- How exactly does Clarity capture/reconstruct Flutter UI?
- What visual information/assets does Clarity store?
- What does Clarity MCP actually expose?
- Can Clarity sessions be programmatically retrieved/exported?
- Can recording be restricted to a particular Flutter screen/section?
- Can a 5-minute recording window be controlled?
- How does Clarity handle Flutter animations, scrolling, dialogs, images, `CustomPainter`, WebView, maps, camera, and platform views?
- For the custom hybrid approach, what Flutter mechanisms are best for detecting meaningful visual changes?
- What is the best way to capture screenshots efficiently without causing UI jank?
- How should screenshots and event metadata be compressed and uploaded?
- Can the hybrid approach be implemented entirely locally in Flutter without OS-level screen-recording permission?

## Privacy

Any automatic visual capture may contain sensitive user information. The implementation must consider appropriate disclosure/consent, masking/redaction of sensitive UI, secure transmission, storage, and platform/app-store requirements.
