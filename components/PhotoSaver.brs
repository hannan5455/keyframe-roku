sub init()
    m.a = m.top.findNode("a")
    m.b = m.top.findNode("b")
    m.msg = m.top.findNode("msg")
    m.timer = m.top.findNode("timer")
    m.fade = m.top.findNode("fade")
    m.fadeInterp = m.top.findNode("fadeInterp")

    m.photos = []
    m.index = -1
    m.showingB = false
    m.failures = 0

    m.timer.observeField("fire", "showNext")
    m.a.observeField("loadStatus", "onLoadStatus")
    m.b.observeField("loadStatus", "onLoadStatus")
end sub

sub onPhotos()
    m.photos = shuffle(m.top.photos)
    if m.photos.Count() = 0 then
        m.msg.text = "No photos found. Put JPG or PNG files on the USB drive and plug it into the Roku."
        return
    end if
    m.msg.visible = false
    showNext()
    m.timer.control = "start"
end sub

' Loads the next photo into whichever Poster is currently hidden.
sub showNext()
    if m.photos.Count() = 0 then return
    m.index = (m.index + 1) mod m.photos.Count()
    if m.showingB then
        m.a.uri = m.photos[m.index]
    else
        m.b.uri = m.photos[m.index]
    end if
end sub

sub onLoadStatus(event as object)
    status = event.getData()
    node = event.getRoSGNode()

    if status = "ready" then
        m.failures = 0
        if node.isSameNode(m.b) then
            m.fadeInterp.keyValue = [0.0, 1.0]
            m.showingB = true
        else
            m.fadeInterp.keyValue = [1.0, 0.0]
            m.showingB = false
        end if
        m.fade.control = "start"
    else if status = "failed" then
        ' Skip unreadable files, but give up if every file fails
        m.failures = m.failures + 1
        if m.failures < m.photos.Count() then
            showNext()
        else
            m.timer.control = "stop"
            m.msg.text = "The photos on the USB drive could not be displayed."
            m.msg.visible = true
        end if
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
