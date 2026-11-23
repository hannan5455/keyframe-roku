# Keyframe

A Roku screensaver that plays a slideshow of the photos on a USB key. No account, no cloud service and no internet connection needed: plug in a key, pick an album, done.

- Shows each photo for 10 seconds, with a crossfade
- Shuffled by default, or in order by file name
- Portrait photos sit on a blurred copy of themselves instead of between black bars
- **Every folder on the key is an album, and you can have as many as you like**
- Play one album at a time, or everything
- Optional extras, all off by default: a caption, a slow pan and zoom, and a clock
- Your settings are remembered across restarts

## Albums

This is the main feature, so here is exactly how it works.

**A folder is an album.** Any folder on the USB key that has photos in it shows up in the album picker under its folder name. There is nothing to configure and no album file to maintain: make a folder, drop photos in, and it is an album.

**There is no limit on the number of albums.** Make five or five hundred. Add, rename or delete folders on the key whenever you like, and the picker shows whatever is there the next time you open it.

**Albums can be nested.** Folders inside folders each become their own album, listed by path:

```
USB key
├── Kids/                  -> album "Kids"
├── Holidays/              -> album "Holidays"
└── Trips/                 -> album "Trips"          (plays every trip)
    ├── 2024 Maine/        -> album "Trips/2024 Maine"
    └── 2025 Italy/        -> album "Trips/2025 Italy"
```

**Picking an album plays that folder and everything beneath it.** So `Trips` plays all trips together, while `Trips/2025 Italy` plays just that one.

**"All photos" plays the whole key**, including loose photos that are not in any folder. This is the default.

**To switch albums:** on the Roku go to Settings → Theme → Screensavers, highlight Keyframe, and open its settings option. Choose Album, then press OK on the one you want. The choice is saved on the Roku. If the chosen folder later disappears from the key, Keyframe falls back to all photos.

## Settings

Everything is on one settings screen: on the Roku go to Settings → Theme → Screensavers, highlight Keyframe, and open its settings option. Press OK on a row to change it. Changes are saved straight away; press Back when you are done.

| Setting | Choices | Default |
| --- | --- | --- |
| Album | All photos, or any folder on the key | All photos |
| Order | Shuffle, or in order by file name | Shuffle |
| Background | Blurred photo, or black | Blurred photo |
| Caption | Off, album name, or file name | Off |
| Pan and zoom | Off or on | Off |
| Clock | Off or on | Off |

**Order.** With Shuffle, the album is put in a new random order each time the screensaver starts, and every photo is shown once before any repeats. In order plays photos sorted by folder and then by file name, starting from the first photo each time. Name files with leading zeros (`01`, `02`, ... `10`) to control the sequence, since `10` sorts before `2` otherwise.

**Background.** Photos are always shown whole, never cropped, so a portrait photo on a wide TV leaves space on either side. With Blurred photo, that space is filled with a soft, dimmed copy of the same photo. With Black, it is left black.

**Caption.** Shows a small label in the bottom-left corner: either the album (folder) the photo is in, or the photo's file name. Loose photos that are not in a folder have no album caption.

**Pan and zoom.** Each photo drifts slowly in or out while it is on screen, instead of sitting still.

**Clock.** Shows the time in a top corner, in the Roku's own 12- or 24-hour format. It swaps corners with each photo so it never sits in one place.

## Limits

Keyframe reads up to 10,000 photos per key and follows folders up to 12 levels deep.

## What you need

- A Roku with a USB port: a Roku Ultra, most Roku TVs, or some Streambars. Express and Streaming Stick models do not have one.
- A USB key formatted as FAT32 or exFAT (most are, out of the box).
- A computer on the same network as the Roku, for the one-time install.

## Preparing photos

- **Formats:** JPG, PNG or GIF. Roku cannot display HEIC, the iPhone's default format, so convert those first.
- **Size:** photos about 1920 pixels on the longest side look best on a 1080p TV (3840 for 4K). Much smaller photos look blurry when stretched to the screen; much larger ones are slower to load.
- **Use the originals.** Photos that have been sent through a chat, a messaging app or email are often shrunk on the way. Export from the Photos app with File → Export → Export Unmodified Original, or AirDrop them from the phone.

- **Rotation:** phones often store a photo sideways along with a "turn me" tag. Roku ignores that tag, so those photos appear on their side unless they are fixed first.

### The prep tool (Mac)

`tools/prep_photos.py` handles all of the above in one step. It needs only Python 3, which macOS already has.

```bash
python3 tools/prep_photos.py ~/Pictures/Originals ~/Pictures/ForRoku
```

It reads every photo under the first folder and writes a TV-ready copy into the second:

- converts HEIC and other formats to JPG
- shrinks large photos to 1920 pixels on the longest side (add `--size 3840` for a 4K TV); small photos are never enlarged
- turns sideways photos upright
- keeps your folder layout, so folders still work as albums
- lists any photos too small to look sharp on a TV
- never modifies the originals

Copy the photos (in folders, if you want albums) onto the key, eject it, and plug it into the Roku.

## Installing

Keyframe is installed by sideloading, using Roku's free Developer Mode.

1. **Get the app.** Download `keyframe.zip` from this project's Releases page, or build it yourself (see below).
2. **Turn on Developer Mode.** On the Roku remote, from the home screen, press:
   Home, Home, Home, Up, Up, Right, Left, Right, Left, Right
3. **On the screen that appears,** note the IP address shown, choose "Enable installer and restart", accept the agreement and set a password. The Roku restarts.
4. **On your computer,** open a browser and go to `http://` followed by that IP address.
5. **Sign in** with the username `rokudev` and the password you just set.
6. **Upload** `keyframe.zip` and click "Install with zip". The slideshow starts on the TV within a few seconds.
7. **Make it your screensaver.** On the Roku go to Settings → Theme → Screensavers and select "Keyframe (dev)".

To update later, upload a newer zip the same way. It replaces the installed version and keeps your album choice.

## Using it

- **When it starts:** Settings → Theme → Screensaver wait time sets how long the Roku sits idle before the screensaver begins.
- **Preview:** the Preview option on the Screensavers screen starts it immediately.
- **Changing photos:** unplug the key, change its contents on a computer, plug it back in. Keyframe rescans the key each time the screensaver starts.

## Good to know

- Roku adds "(dev)" to the name of every sideloaded app. That cannot be removed.
- A Roku holds one sideloaded app at a time, so installing another developer app replaces Keyframe.
- On a Roku TV the screensaver generally does not run over a live HDMI input such as a cable box or game console. It runs when the Roku is idle on its home screen or in a paused streaming app.
- Roku ignores the rotation tag that phones add to photos. Run them through the prep tool so they are stored upright.

## Troubleshooting

| What you see | What to do |
| --- | --- |
| "No photos found" | Check that the key is plugged into the Roku and holds JPG, PNG or GIF files. If the Roku does not recognise the key at all, reformat it as FAT32 (this erases it) and copy the photos back. |
| Sideways photos | The photo is stored rotated with a tag that Roku ignores. Run your photos through `tools/prep_photos.py`. |
| Blurry photos | The files are too small. Check their dimensions and re-export from the originals, as described under Preparing photos. |
| An album is missing from the picker | The folder has no supported photos in it, for example only HEIC files. |
| The remote sequence does nothing | Press the buttons a little faster, starting from the home screen. |
| The browser cannot reach the Roku | Make sure the computer and the Roku are on the same network, and use `http://`, not `https://`. |

## Building from source

The app is plain BrightScript and SceneGraph XML, with no build tools needed beyond `zip`.

```bash
./build.sh
```

This writes `keyframe.zip`, ready to upload to the Roku.

```
manifest                    app name, version and icons
source/main.brs             finds photos and albums, runs the screensaver and settings screens
components/PhotoSaver.*     the slideshow
components/Settings.*       the settings screen and album picker
images/                     icons
tools/prep_photos.py        converts, resizes and straightens photos for the key (Mac)
tools/mkicon.py             regenerates the icons (Python 3, no dependencies)
```

Settings you might want to change:

- Seconds per photo: `duration` on the `Timer` in `components/PhotoSaver.xml`
- Crossfade length: `duration` on the `Animation` in the same file
- Photo and folder-depth limits: `ScanDir` in `source/main.brs`
