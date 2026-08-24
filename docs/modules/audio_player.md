# AUDIO_PLAYER — Play mp3 files

> Available since: v3.3.3.dev0

SLZB Ultima has a built-in 24-Bit digital sound processor that can play mp3 files from HTTP stream or from internal memory.<br>
It is recommended to use a bitrate of no more than 128.<br>
You can find a 3.5 audio output on the back of the device.<br>

## Quick Example

```berry
import AUDIO_PLAYER

AUDIO_PLAYER.play("https://online.kissfm.ua/KissFM_Deep") # play good Ukrainian online radio
# ---
AUDIO_PLAYER.play("my_song.mp3") # or play your file (file must first be uploaded into memory on the /audio page)
```

## Looping an audio file

```berry
import AUDIO_PLAYER
import TIMER

TIMER.setInterval(def()
  if (AUDIO_PLAYER.getStatus() != AUDIO_PLAYER.STATUS_PLAYING)
    AUDIO_PLAYER.play("test.mp3")
  end 
end, 100)
```

## API Reference

| Function | Description |
|----------|-------------|
| `AUDIO_PLAYER.play(url:str)` | Starts playback of an HTTP stream or local file. If playback is already running, it will be stopped and restarted with the new URL. |
| `AUDIO_PLAYER.stop()` | Stops playback. |
| `AUDIO_PLAYER.getStatus()` | Returns the current status of the player (see `STATUS_*` constants). Resets to `STATUS_IDLE` immediately after playback ends (even if it ends with an error). |
| `AUDIO_PLAYER.getLastError()` | Returns the last result of the player call. Unlike `getStatus()`, this parameter is not reset to `STATUS_IDLE` after playback ends, so can tell you if an error occurred (see `STATUS_*` constants). |

## Player State Constants

Type `AUDIO_PLAYER.STATUS_` in the script editor to autocomplete all constants.

| Constant | Value | Description |
|----------|-------|-------------|
| `AUDIO_PLAYER.STATUS_IDLE` | 0 | Nothing is playing right now. |
| `AUDIO_PLAYER.STATUS_STARTING` | 1 | The player is preparing to play. |
| `AUDIO_PLAYER.STATUS_PLAYING` | 2 | The player is playing audio. |
| `AUDIO_PLAYER.STATUS_OK` | 3 | Audio playback completed successfully. (Audio file/stream ended or `AUDIO_PLAYER.stop()` was called) |
| `AUDIO_PLAYER.STATUS_STREAM_TIMEOUT` | 4 | Timeout reading http stream. It looks like you an ADSL modem? |
| `AUDIO_PLAYER.STATUS_BAD_FILE` | 5 | The provided stream or file is not mp3 format or broken. |
| `AUDIO_PLAYER.STATUS_DECODER_INIT_FAIL` | 6 | Error starting mp3 decoder. This should not happen! |
