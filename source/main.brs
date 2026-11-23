' Keyframe: a screensaver that plays the photos on a USB drive.
' There is deliberately no Main(): a package with only RunScreenSaver is
' treated by Roku as a system-wide screensaver.

sub RunScreenSaver()
    screen = CreateObject("roSGScreen")
    port = CreateObject("roMessagePort")
    screen.SetMessagePort(port)
    scene = screen.CreateScene("PhotoSaver")
    screen.Show()

    ' Options must be set before photos, which starts the slideshow
    scene.options = {
        shuffle: GetSetting("order", "shuffle") <> "ordered"
        fill: GetSetting("fill", "blur") <> "black"
        caption: GetSetting("caption", "off")
        pan: GetSetting("pan", "off") = "on"
        clock: GetSetting("clock", "off") = "on"
    }
    scene.photos = PhotosInAlbum(FindPhotos(), GetSetting("album", ""))

    while true
        msg = wait(0, port)
        if type(msg) = "roSGScreenEvent" and msg.IsScreenClosed() then return
    end while
end sub

' Settings screen (Settings > Theme > Screensavers > Keyframe > settings).
' The screen reports each change and it is saved here straight away.
sub RunScreenSaverSettings()
    screen = CreateObject("roSGScreen")
    port = CreateObject("roMessagePort")
    screen.SetMessagePort(port)
    scene = screen.CreateScene("Settings")
    screen.Show()

    albums = FindAlbums(FindPhotos())
    names = ["All photos"]
    current = 0
    saved = LCase(GetSetting("album", ""))
    for i = 0 to albums.Count() - 1
        names.Push(albums[i])
        if saved <> "" and LCase(albums[i]) = saved then current = i + 1
    end for

    scene.settings = {
        order: GetSetting("order", "shuffle")
        fill: GetSetting("fill", "blur")
        caption: GetSetting("caption", "off")
        pan: GetSetting("pan", "off")
        clock: GetSetting("clock", "off")
    }
    scene.current = current
    scene.albums = names
    scene.observeField("settingChange", port)

    while true
        msg = wait(0, port)
        if type(msg) = "roSGScreenEvent" then
            if msg.IsScreenClosed() then return
        else if type(msg) = "roSGNodeEvent" and msg.getField() = "settingChange" then
            change = msg.getData()
            if change = invalid or change.key = invalid then
                ' nothing to save
            else if change.key = "album" then
                idx = change.index
                if idx <= 0 then
                    SetSetting("album", "")
                else if idx <= albums.Count() then
                    SetSetting("album", albums[idx - 1])
                end if
            else
                SetSetting(change.key, change.value)
            end if
        end if
    end while
end sub

' Saved settings (all strings):
'   album    folder path relative to the drive, e.g. "Trips/2025"; "" = all photos
'   order    "shuffle" or "ordered"
'   fill     "blur" or "black": what shows around photos that do not fill the screen
'   caption  "off", "album" or "file"
'   pan      "off" or "on"
'   clock    "off" or "on"
function GetSetting(key as string, fallback as string) as string
    sec = CreateObject("roRegistrySection", "settings")
    if sec.Exists(key) then return sec.Read(key)
    return fallback
end function

sub SetSetting(key as string, value as string)
    sec = CreateObject("roRegistrySection", "settings")
    sec.Write(key, value)
    sec.Flush()
end sub

' Returns the paths of every photo on every attached USB drive.
function FindPhotos() as object
    fs = CreateObject("roFileSystem")
    photos = []
    for each vol in fs.GetVolumeList()
        if LCase(Left(vol, 3)) = "ext" then ScanDir(fs, vol + "/", 0, photos)
    end for
    return photos
end function

sub ScanDir(fs as object, path as string, depth as integer, photos as object)
    if depth > 12 or photos.Count() >= 10000 then return
    for each name in fs.GetDirectoryListing(path)
        ' Skip hidden files, including the "._" files macOS writes to USB drives
        if Left(name, 1) <> "." then
            full = path + name
            if IsPhoto(name) then
                photos.Push(full)
            else
                info = fs.Stat(full)
                if info <> invalid and info.type = "directory" then
                    ScanDir(fs, full + "/", depth + 1, photos)
                end if
            end if
            if photos.Count() >= 10000 then return
        end if
    end for
end sub

function IsPhoto(name as string) as boolean
    lower = LCase(name)
    for each ext in [".jpg", ".jpeg", ".png", ".gif"]
        if Right(lower, Len(ext)) = ext then return true
    end for
    return false
end function

' Strips the drive name: "ext1:/Trips/a.jpg" -> "Trips/a.jpg"
function RelPath(path as string) as string
    idx = Instr(1, path, ":/")
    if idx = 0 then return path
    return Mid(path, idx + 2)
end function

' Photos inside the album folder or any folder beneath it.
' Falls back to every photo if the album is empty or no longer exists.
function PhotosInAlbum(photos as object, album as string) as object
    if album = "" then return photos
    prefix = LCase(album) + "/"
    out = []
    for each p in photos
        if Left(LCase(RelPath(p)), Len(prefix)) = prefix then out.Push(p)
    end for
    if out.Count() = 0 then return photos
    return out
end function

' Every folder, at any depth, that has photos somewhere inside it.
function FindAlbums(photos as object) as object
    seen = {}
    albums = []
    for each p in photos
        parts = RelPath(p).Split("/")
        prefix = ""
        for i = 0 to parts.Count() - 2
            if i > 0 then prefix = prefix + "/"
            prefix = prefix + parts[i]
            if not seen.DoesExist(prefix) then
                seen[prefix] = true
                albums.Push(prefix)
            end if
        end for
    end for
    albums.Sort("i")
    return albums
end function
