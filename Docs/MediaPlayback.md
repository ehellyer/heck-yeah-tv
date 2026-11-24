# Heck Yeah TV — Media Playback (UnifiedPlayerView, Discontinuities & Watchdogs)

Date drafted: November 24, 2026

Source: `HeckYeahTV/Source/UserInterface/MediaPlayerView`

## Summary

Heck Yeah TV plays two kinds of streams:

- **HDHomeRun** tuner channels: raw MPEG-TS over HTTP.
- **IPTV** channels: mostly HLS (`.m3u8`), many with server-side ad insertion (e.g. PlutoTV).

No single player handles both well, so `UnifiedPlayerView` picks a player per channel:

| Channel source | Player | Fallback |
|---|---|---|
| HDHomeRun | VLC | — (VLC watchdog reloads, then shows the unplayable overlay) |
| IPTV | AVPlayer | VLC, if AVPlayer fails, never starts, stalls, or plays audio with no video |

Both players are guarded by a `Watchdog` that polls playback once per second:

- The **AVPlayer watchdog** decides when to give up on AVPlayer and fall back to VLC.
- The **VLC watchdog** reloads frozen streams and, as the last resort, marks a stream unplayable.

## The Problem: Ad-Break Discontinuities

### Symptom

While watching a PlutoTV channel (e.g. `https://jmp2.uk/plu-5ca525b650be2571e3943c63.m3u8`) in VLC, the picture froze when a commercial break started. About 7 seconds later the old watchdog marked the stream unplayable. Changing to another channel and back fixed it every time.

### Root Cause

Found with libVLC debug logging (VLC 3.0.23):

1. PlutoTV serves HLS with **separate renditions**: one video playlist, two audio playlists (English and English Audio-Description) and a WebVTT subtitle playlist.
2. Ads are stitched in on the server. Each ad boundary is an `#EXT-X-DISCONTINUITY`: timestamps reset and the codec parameters may change.
3. At each boundary VLC 3's adaptive (HLS) demuxer logs `Ending demuxer stream. [discontinuity]` and restarts. With separate renditions it frequently never resumes: the demuxer position (`cur` in `cached.i_time` log lines) **freezes**, even though VLC keeps refreshing the playlists and downloading new segments.
4. VLC does not report an error. It stays in `.buffering`/`.playing`, and `mediaPlayerTimeChanged` keeps firing with an unchanged time.

Reloading the stream (a fresh `VLCMedia`) always recovers, because it starts a new demuxer at the live edge. That is exactly what the manual channel switch did.

### What Did Not Fix It

- **VLC media options.** The existing discontinuity-related options (`no-ts-trust-pcr`, `clock-jitter`, etc.) don't prevent the freeze.
- **Software decoding.** The first logs showed `VT-DS err=-12906` (VideoToolbox could not create a decoder), which pointed at the decoder. Forcing avcodec (`forceSoftwareDecode`, `"codec": "avcodec,all"`) removed those errors, but the freezes continued. The decoder was not the cause.
- **`avcodec-debug`.** Not used: the stall is in the demuxer/clock, upstream of the decoder, and the output is extremely noisy.

### The Fix

- **IPTV plays in AVPlayer first.** AVFoundation handles HLS discontinuities and separate renditions natively; PlutoTV ad breaks play seamlessly.
- **VLC stays as the fallback** for IPTV streams AVPlayer can't play, and for all HDHomeRun channels.
- **The VLC watchdog** detects a frozen stream within about 3 seconds and reloads it, so streams that do end up in VLC recover automatically.
- **VLC moved to libVLC 4.** VLCKit 3 (TVVLCKit / MobileVLCKit via CocoaPods) was replaced by the `SwiftVLC` Swift package (libVLC 4), which rewrote HLS adaptive streaming and discontinuity handling. The watchdog rules were kept unchanged.

## Why Two Players

| | AVPlayer | VLC (SwiftVLC / libVLC 4) |
|---|---|---|
| HLS ad insertion / discontinuities | Seamless | VLC 3 froze; libVLC 4 handles them better, and the watchdog reloads any stall |
| Separate audio/subtitle renditions | Native media selection | Supported, but fragile at discontinuities |
| Raw MPEG-TS over HTTP (HDHomeRun) | Not supported | Supported |
| Format/codec coverage | HLS and Apple-supported codecs only | Very broad |
| Decoding | Hardware (VideoToolbox) | libVLC 4 defaults (hardware where available) |
| Volume range | 0–100% | 0–200% (amplification) |

AVPlayer earlier had stall problems with some IPTV streams, which is why VLC had been the only player. The AVPlayer watchdog now catches those cases and hands the stream to VLC instead of leaving it stuck.

## Player Selection Flow

```mermaid
flowchart TD
    A[Channel selected] --> B{IPTV channel?}
    B -- No: HDHomeRun --> V[VLCPlayerView]
    B -- Yes --> C{URL in avPlayerFailedURLs?}
    C -- Yes --> V
    C -- No --> P[AVPlayerView]
    P --> W{AVPlayer watchdog:<br/>playing OK?}
    W -- Yes --> P
    W -- No --> F["onPlaybackFailure(url)<br/>insert URL into avPlayerFailedURLs"]
    F --> V
    V --> X{VLC watchdog}
    X -- progressing --> V
    X -- stalled after playing --> R[Reload stream<br/>up to 3 times]
    R --> V
    X -- never played / reloads exhausted --> U[UnplayableStreamOverlay]
```

- `avPlayerFailedURLs` is `@State` in `UnifiedPlayerView`. A stream that failed in AVPlayer stays on VLC for the rest of the app session; it is not persisted across launches.
- `VLCPlayerView` also covers "no channel selected" (VLC handles a `nil` channel by stopping).

## AVPlayer Watchdog (`AVPlaybackController`)

AVPlayer rarely reports failure for live streams it can't really play: it may wait forever, stall, or play audio with no video. `checkPlayback()` runs once per second and calls `onPlaybackFailure` (once per load) when any rule trips:

| Rule | Threshold | Typical cause |
|---|---|---|
| `AVPlayerItem.status == .failed` | Immediate | Unsupported format, network/HTTP error |
| Playback did not start | `startupTimeout` = 10s | Stream never becomes playable |
| No progress after starting | `stallTimeout` = 6s | Mid-stream stall (AVPlayer re-buffers short hiccups itself) |
| Audio plays but no video frame is displayed | `videoStartTimeout` = 5s after start | Video can't be decoded (seen on the tvOS Simulator: `VT-DS err=-8969`, audio only) |

Notes:

- **Progress** means `timeControlStatus == .playing` and `currentTime()` changed since the last check.
- **Video check:** it uses `AVPlayerLayer.isReadyForDisplay`, so it only applies when the item has a video track. Audio-only streams pass.
- **Polling instead of KVO:** this keeps all state on the main actor.
- **Overlay:** AVPlayer never shows the unplayable overlay itself. VLC gets the stream and its watchdog makes the final call.

## VLC Watchdog (`SwiftVLCPlaybackController`)

```mermaid
stateDiagram-v2
    [*] --> Startup: load / resume / reload
    Startup --> Playing: playback time advances
    Startup --> Unplayable: no progress for 7s and never played
    Startup --> Reloading: no progress for 7s after a previous play
    Playing --> Reloading: no progress for 3s
    Reloading --> Startup: fresh Media, play
    Reloading --> Unplayable: 3 reloads without 20s of healthy playback
    Playing --> Playing: 20s healthy after a reload resets the reload budget
    Unplayable --> [*]: user selects another channel
```

| Item | Value | Why |
|---|---|---|
| Progress signal | `player.currentTime` actually changes while `.playing` | VLC 3 stayed in `.playing` while frozen |
| `startupStallThreshold` | 7s | Opening, reloading and resuming take a few seconds |
| `midStreamStallThreshold` | 3s | Once playing, a 3s freeze is treated as a stuck demuxer |
| `maxStallRecoveries` | 3 | Prevents endless reload loops on a broken stream |
| `stallRecoveryResetInterval` | 20s | Ad breaks put a discontinuity every 30–60s, so each break needs a fresh budget |

How it works:

- **Startup vs mid-stream:** `lastPlaybackTime == nil` marks startup. It is reset whenever monitoring (re)starts.
- **Unplayable:** sets `isStreamUnplayable`. `VLCPlayerView` shows `UnplayableStreamOverlay` and the controller stops the player. Selecting a different channel clears the flag.
- **VLC errors:** libVLC's own error state/event is handled separately: up to `maxErrorRetries` (3) retries in `handleError()`.

## Related Fix: VLC Audio Track Selection

With VLCKit 3, track "indexes" were elementary stream (ES) ids tied to one media instance. Stale ids after reloads selected the wrong rendition, and a late-arriving audio rendition led to a `-1` selection, which VLC treats as **Disable** (silent audio).

The SwiftVLC player avoids both:

- **Reset on new media:** track state is cleared whenever new media loads or reloads.
- **Republish on `.tracksChanged`:** late audio renditions appear in the menu when libVLC reports them; no polling.
- **Keep VLC's default:** the selection starts as the track libVLC already chose; `-1` means "no selection", never "disable".
- **Validate before applying:** `TrackItem.index` is a position in the current track list and is range-checked, so a stale index can't disable or misselect audio.

## Audio & Subtitle Menus

`PlayerOverlay` shows the audio-track and closed-caption menus whenever `appState.availableAudioTracks` / `availableSubtitleTracks` are non-empty. Both players publish into the same `AppStateProvider` properties:

| | VLC | AVPlayer |
|---|---|---|
| Track source | `player.audioTracks` / `subtitleTracks` | HLS media selection groups (`.audible`, `.legible`) |
| `TrackItem.index` | Position in the track list | Position in the option list |
| Subtitles offered | First subtitle track only (intentional) | All non-forced subtitle/caption options |
| "Off" | `-1` | `-1` (`select(nil, in: legibleGroup)`) |

The menus use an inline `Picker` so the selected item gets a native checkmark on iOS, tvOS and macOS. On macOS they also use `.menuIndicator(.hidden)` and a plain button style to match the round overlay buttons.

## Diagnostics

Useful console lines:

| Log line | Meaning |
|---|---|
| `AVPlayer: Playback started for …` | AVPlayer is progressing |
| `AVPlayer: Video rendering confirmed …` | First video frame displayed |
| `AVPlayer: Unable to play … (reason) - falling back to VLC` | AVPlayer watchdog gave up; VLC takes over |
| `SwiftVLC: No playback progress for Xs (threshold Ys) …` | VLC watchdog detected a freeze |
| `SwiftVLC: Playback stalled mid-stream … reloading attempt n of 3` | VLC reload in progress |
| `SwiftVLC: Playback healthy since last stall recovery - resetting recovery count` | Reload budget restored |
| `SwiftVLC: Marking stream as unplayable: …` | Final failure; overlay shown |
| `AVPlayer: Detected N audio tracks and M subtitle tracks …` | Track menus populated |

libVLC's own log is forwarded to the app log in DEBUG builds at `.error` (`libVLC [module] message`). To investigate VLC stalls, temporarily lower `minimumLevel` in `startLibVLCLoggingIfNeeded()` in `SwiftVLCPlayerView.swift` and look for:

- `Ending demuxer stream. [discontinuity]` at the ad boundary.
- A `cur` value in `cached.i_time … cur …` lines that stops changing.
- `buffer too late (…): dropped` / `More than 11 late frames` (A/V clock drift after a discontinuity).

## Known Limitations & Future Work

- **VLC media options are minimal.** libVLC 4 runs with its defaults plus `network-caching=1000` and `http-reconnect`. The VLC 3 tuning options (and `forceSoftwareDecode`) were not carried over; add them back only if a need is shown.
- **The fallback lasts only one session.** A stream that fails in AVPlayer goes back to AVPlayer on the next launch.
- **AVPlayer volume is capped.** App volume settings above 100 play at normal level, because AVPlayer can't amplify.
- **The Simulator differs from devices.** The tvOS Simulator can't decode video for some streams in AVPlayer (BBC Top Gear), and the iOS device plays them fine. Fallback covers it, but test on devices.

## Source Files

| File | Role |
|---|---|
| `UnifiedPlayerView.swift` | Chooses AVPlayer or VLC per channel; tracks AVPlayer-failed URLs |
| `AVPlayerView.swift` | `AVPlayerView`, `AVPlaybackController` (watchdog, track selection), `AVPlayerLayer` view |
| `VLCPlayer/VLCPlayerView.swift` | VLC host view; unplayable overlay and switching indicator |
| `VLCPlayer/SwiftVLCPlayerView.swift` | `SwiftVLCPlayerView`, `SwiftVLCPlaybackController` (libVLC 4 player, media options, watchdog and reload, track handling) |
| `Watchdog.swift` | Shared once-per-second polling actor used by both players |
| `Menu/Screens/PlayerOverlay/PlayerOverlay.swift` | Audio track and closed caption menus |
