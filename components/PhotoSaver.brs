sub init()
    m.a = m.top.findNode("a")
    m.b = m.top.findNode("b")
    m.clipA = m.top.findNode("clipA")
    m.clipB = m.top.findNode("clipB")
    m.bgA = m.top.findNode("bgA")
    m.bgB = m.top.findNode("bgB")
    m.backdropA = m.top.findNode("backdropA")
    m.backdropB = m.top.findNode("backdropB")
    m.msg = m.top.findNode("msg")
    m.timer = m.top.findNode("timer")
    m.fade = m.top.findNode("fade")
    m.fadeInterp = m.top.findNode("fadeInterp")

    m.captionGroup = m.top.findNode("captionGroup")
    m.captionBg = m.top.findNode("captionBg")
    m.captionLabel = m.top.findNode("captionLabel")
    m.clockGroup = m.top.findNode("clockGroup")
    m.clockLabel = m.top.findNode("clockLabel")
    m.clockShadow = m.top.findNode("clockShadow")
    m.clockTimer = m.top.findNode("clockTimer")
    m.zoomA = m.top.findNode("zoomA")
    m.zoomAInterp = m.top.findNode("zoomAInterp")
    m.zoomB = m.top.findNode("zoomB")
    m.zoomBInterp = m.top.findNode("zoomBInterp")

    m.photos = []
    m.index = -1
    m.showingB = false
    m.pending = false
    m.photoReady = false
    m.backdropDone = false
    m.nextPhoto = m.b
    m.nextBackdrop = m.bgB
    m.failures = 0

    ' Options; all extras are off unless switched on in settings
    m.shuffle = true
    m.fill = true
    m.captionMode = "off"
    m.pan = false
    m.clock = false
    m.clockLeft = false
    m.zoomIn = false

    m.timer.observeField("fire", "showNext")
    m.clockTimer.observeField("fire", "updateClock")
    m.a.observeField("loadStatus", "onLoadStatus")
    m.b.observeField("loadStatus", "onLoadStatus")
    m.bgA.observeField("loadStatus", "onLoadStatus")
    m.bgB.observeField("loadStatus", "onLoadStatus")
end sub

sub applyOptions()
    o = m.top.options
    if o = invalid then return
    if o.shuffle <> invalid then m.shuffle = o.shuffle
    if o.fill <> invalid then m.fill = o.fill
    if o.caption <> invalid then m.captionMode = o.caption
    if o.pan <> invalid then m.pan = o.pan
    if o.clock <> invalid then m.clock = o.clock
end sub

sub onPhotos()
    applyOptions()

    if m.shuffle then
        m.photos = shuffle(m.top.photos)
    else
        ' In order: sorted by folder, then file name
        m.photos = m.top.photos
        m.photos.Sort("i")
    end if

    if m.photos.Count() = 0 then
        m.msg.text = "No photos found. Put JPG or PNG files on the USB drive and plug it into the Roku."
        return
    end if
    m.msg.visible = false
    m.backdropA.visible = m.fill
    m.backdropB.visible = m.fill

    if m.clock then
        m.clock24 = (CreateObject("roDeviceInfo").GetClockFormat() = "24h")
        updateClock()
        m.clockGroup.visible = true
        m.clockTimer.control = "start"
    end if

    showNext()
end sub

' Loads the next photo into whichever slide is currently hidden. The slide is
' revealed by tryReveal() once the photo and its backdrop have both loaded.
sub showNext()
    if m.photos.Count() = 0 then return
    m.index = (m.index + 1) mod m.photos.Count()
    uri = m.photos[m.index]

    if m.showingB then
        m.nextPhoto = m.a
        m.nextBackdrop = m.bgA
    else
        m.nextPhoto = m.b
        m.nextBackdrop = m.bgB
    end if

    ' A Poster sends no load event if it is given the photo it already holds
    ' (this happens in albums of one or two photos), so count that as loaded.
    m.photoReady = (m.nextPhoto.uri = uri and m.nextPhoto.loadStatus = "ready")
    m.backdropDone = (not m.fill) or (m.nextBackdrop.uri = uri and m.nextBackdrop.loadStatus = "ready")
    m.pending = true

    if m.fill then m.nextBackdrop.uri = uri
    m.nextPhoto.uri = uri
    tryReveal()
end sub

' Called whenever a photo or backdrop starts, finishes or fails loading.
sub onLoadStatus(event as object)
    if not m.pending then return
    node = event.getRoSGNode()
    status = event.getData()

    if node.isSameNode(m.nextPhoto) then
        if status = "ready" then
            m.photoReady = true
        else if status = "failed" then
            ' Skip unreadable files, but give up if every file fails
            m.failures = m.failures + 1
            if m.failures < m.photos.Count() then
                showNext()
            else
                m.pending = false
                m.msg.text = "The photos on the USB drive could not be displayed."
                m.msg.visible = true
            end if
            return
        end if
    else if node.isSameNode(m.nextBackdrop) then
        ' A backdrop that fails to load is simply left out
        if status = "ready" or status = "failed" then m.backdropDone = true
    end if
    tryReveal()
end sub

' Crossfades to the hidden slide once everything on it has loaded, so the
' backdrop never pops in late. The timer for the next photo starts here, so
' every photo gets its full time on screen however long it took to load.
sub tryReveal()
    if not (m.pending and m.photoReady and m.backdropDone) then return
    m.pending = false
    m.failures = 0

    isB = m.nextPhoto.isSameNode(m.b)
    layoutPhoto(isB)
    if m.pan then startZoom(isB)
    if isB then
        m.fadeInterp.keyValue = [0.0, 1.0]
    else
        m.fadeInterp.keyValue = [1.0, 0.0]
    end if
    m.showingB = isB
    m.fade.control = "start"
    updateCaption(m.nextPhoto.uri)
    if m.clock then moveClock()
    m.timer.control = "start"
end sub

' ---- Pan and zoom ----

' Sizes and centres the incoming photo so it fits the screen without cropping,
' and sets its clipping frame to exactly that rectangle.
sub layoutPhoto(isB as boolean)
    if isB then
        photo = m.b
        clip = m.clipB
    else
        photo = m.a
        clip = m.clipA
    end if

    w = 1920
    h = 1080
    bw = photo.bitmapWidth
    bh = photo.bitmapHeight
    if bw > 0 and bh > 0 then
        ratio = 1920 / bw
        if 1080 / bh < ratio then ratio = 1080 / bh
        w = Int(bw * ratio + 0.5)
        h = Int(bh * ratio + 0.5)
    end if
    x = Int((1920 - w) / 2)
    y = Int((1080 - h) / 2)

    photo.scale = [1.0, 1.0]
    photo.width = w
    photo.height = h
    photo.translation = [x, y]
    clip.clippingRect = [x, y, w, h]
end sub

' Slowly zooms the incoming photo in or out around a random point, which
' reads as a gentle pan. Alternates direction from one photo to the next.
' Only the picture moves; the clipping frame keeps the photo's edges still.
sub startZoom(isB as boolean)
    if isB then
        photo = m.b
        interp = m.zoomBInterp
        anim = m.zoomB
    else
        photo = m.a
        interp = m.zoomAInterp
        anim = m.zoomA
    end if

    ' A point in the middle part of the photo, in the photo's own coordinates
    photo.scaleRotateCenter = [photo.width * (0.3 + Rnd(0) * 0.4), photo.height * (0.3 + Rnd(0) * 0.4)]
    m.zoomIn = not m.zoomIn
    if m.zoomIn then
        interp.keyValue = [[1.0, 1.0], [1.12, 1.12]]
    else
        interp.keyValue = [[1.12, 1.12], [1.0, 1.0]]
    end if
    anim.control = "start"
end sub

' ---- Caption ----

sub updateCaption(uri as string)
    text = ""
    if m.captionMode = "album" then
        text = albumName(uri)
    else if m.captionMode = "file" then
        text = fileName(uri)
    end if

    if text = "" then
        m.captionGroup.visible = false
        return
    end if
    m.captionLabel.text = text
    m.captionBg.width = m.captionLabel.boundingRect().width + 40
    m.captionGroup.visible = true
end sub

' "ext1:/Trips/2025 Italy/IMG_1.jpg" -> ["Trips", "2025 Italy", "IMG_1.jpg"]
function pathParts(uri as string) as object
    idx = Instr(1, uri, ":/")
    if idx > 0 then uri = Mid(uri, idx + 2)
    return uri.Split("/")
end function

' Folder path of the photo, e.g. "Trips / 2025 Italy"; "" for loose photos
function albumName(uri as string) as string
    parts = pathParts(uri)
    name = ""
    for i = 0 to parts.Count() - 2
        if i > 0 then name = name + " / "
        name = name + parts[i]
    end for
    return name
end function

' File name without its extension
function fileName(uri as string) as string
    parts = pathParts(uri)
    if parts.Count() = 0 then return ""
    name = parts[parts.Count() - 1]
    for i = Len(name) to 2 step -1
        if Mid(name, i, 1) = "." then return Left(name, i - 1)
    end for
    return name
end function

' ---- Clock ----

sub updateClock()
    now = CreateObject("roDateTime")
    now.ToLocalTime()
    hours = now.GetHours()
    minutes = Right("0" + now.GetMinutes().ToStr(), 2)
    if m.clock24 then
        text = Right("0" + hours.ToStr(), 2) + ":" + minutes
    else
        suffix = " am"
        if hours >= 12 then suffix = " pm"
        hours = hours mod 12
        if hours = 0 then hours = 12
        text = hours.ToStr() + ":" + minutes + suffix
    end if
    m.clockLabel.text = text
    m.clockShadow.text = text
end sub

' Swaps the clock between the top corners on each photo change
sub moveClock()
    m.clockLeft = not m.clockLeft
    if m.clockLeft then
        m.clockGroup.translation = [60, 50]
    else
        m.clockGroup.translation = [1580, 50]
    end if
end sub

function shuffle(list as object) as object
    out = []
    for each item in list
        out.Push(item)
    end for
    for i = out.Count() - 1 to 1 step -1
        j = Rnd(i + 1) - 1
        tmp = out[i]
        out[i] = out[j]
        out[j] = tmp
    end for
    return out
end function
