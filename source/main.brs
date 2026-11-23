' USB Photos screensaver.
' There is deliberately no Main(): a package with only RunScreenSaver is
' treated by Roku as a system-wide screensaver.

sub RunScreenSaver()
    screen = CreateObject("roSGScreen")
    port = CreateObject("roMessagePort")
    screen.SetMessagePort(port)
    scene = screen.CreateScene("PhotoSaver")
    screen.Show()

    scene.photos = PhotosInAlbum(FindPhotos(), GetAlbum())

    while true
        msg = wait(0, port)
        if type(msg) = "roSGScreenEvent" and msg.IsScreenClosed() then return
    end while
end sub

' Settings screen (Settings > Theme > Screensavers > USB Photos > settings):
' pick which folder on the USB drive to play.
sub RunScreenSaverSettings()
    screen = CreateObject("roSGScreen")
    port = CreateObject("roMessagePort")
    screen.SetMessagePort(port)
    scene = screen.CreateScene("AlbumPicker")
    screen.Show()

    albums = FindAlbums(FindPhotos())
    names = ["All photos"]
    current = 0
    saved = LCase(GetAlbum())
    for i = 0 to albums.Count() - 1
        names.Push(albums[i])
        if saved <> "" and LCase(albums[i]) = saved then current = i + 1
    end for

    scene.current = current
    scene.albums = names
    scene.observeField("chosen", port)

    while true
        msg = wait(0, port)
        if type(msg) = "roSGScreenEvent" then
            if msg.IsScreenClosed() then return
        else if type(msg) = "roSGNodeEvent" and msg.getField() = "chosen" then
            idx = msg.getData()
            if idx <= 0 then
                SetAlbum("")
            else if idx <= albums.Count() then
                SetAlbum(albums[idx - 1])
            end if
            screen.Close()
            return
        end if
    end while
end sub

' The chosen album is a folder path relative to the drive, e.g. "Trips/2025".
' An empty string means all photos.
function GetAlbum() as string
    sec = CreateObject("roRegistrySection", "settings")
    if sec.Exists("album") then return sec.Read("album")
    return ""
end function

sub SetAlbum(album as string)
    sec = CreateObject("roRegistrySection", "settings")
    sec.Write("album", album)
    sec.Flush()
end sub

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
