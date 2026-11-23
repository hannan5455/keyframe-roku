sub init()
    m.menu = m.top.findNode("menu")
    m.albumList = m.top.findNode("albumList")
    m.title = m.top.findNode("title")
    m.hint = m.top.findNode("hint")

    ' Menu rows, top to bottom
    m.rows = ["album", "order", "fill", "caption", "pan", "clock"]
    m.rowNames = {
        album: "Album"
        order: "Order"
        fill: "Background"
        caption: "Caption"
        pan: "Pan and zoom"
        clock: "Clock"
    }
    ' Values each option cycles through when OK is pressed
    m.choices = {
        order: ["shuffle", "ordered"]
        fill: ["blur", "black"]
        caption: ["off", "album", "file"]
        pan: ["off", "on"]
        clock: ["off", "on"]
    }
    m.valueNames = {
        shuffle: "Shuffle"
        ordered: "In order, by file name"
        blur: "Blurred photo"
        black: "Black"
        off: "Off"
        on: "On"
        album: "Album name"
        file: "File name"
    }

    m.values = { order: "shuffle", fill: "blur", caption: "off", pan: "off", clock: "off" }
    m.albumNames = ["All photos"]
    m.albumIndex = 0

    content = CreateObject("roSGNode", "ContentNode")
    for each row in m.rows
        content.createChild("ContentNode")
    end for
    m.menu.content = content
    refreshMenu()

    m.menu.observeField("itemSelected", "onMenuSelected")
    m.albumList.observeField("itemSelected", "onAlbumSelected")
    m.menu.setFocus(true)
end sub

sub onSettings()
    saved = m.top.settings
    if saved = invalid then return
    for each key in m.values
        if saved[key] <> invalid then m.values[key] = saved[key]
    end for
    refreshMenu()
end sub

sub onAlbums()
    m.albumNames = m.top.albums
    if m.albumNames.Count() = 0 then m.albumNames = ["All photos"]
    m.albumIndex = m.top.current
    if m.albumIndex < 0 or m.albumIndex >= m.albumNames.Count() then m.albumIndex = 0

    content = CreateObject("roSGNode", "ContentNode")
    for each name in m.albumNames
        item = content.createChild("ContentNode")
        item.title = name
    end for
    m.albumList.content = content
    m.albumList.checkedItem = m.albumIndex
    refreshMenu()
end sub

sub refreshMenu()
    for i = 0 to m.rows.Count() - 1
        key = m.rows[i]
        if key = "album" then
            value = m.albumNames[m.albumIndex]
        else
            value = m.valueNames[m.values[key]]
            if value = invalid then value = m.values[key]
        end if
        m.menu.content.getChild(i).title = m.rowNames[key] + ":   " + value
    end for
end sub

sub onMenuSelected()
    key = m.rows[m.menu.itemSelected]
    if key = "album" then
        showAlbums()
        return
    end if

    ' Step to the next value for this option
    options = m.choices[key]
    nextIndex = 0
    for i = 0 to options.Count() - 1
        if options[i] = m.values[key] then nextIndex = (i + 1) mod options.Count()
    end for
    m.values[key] = options[nextIndex]
    refreshMenu()
    m.top.settingChange = { key: key, value: m.values[key] }
end sub

sub showAlbums()
    m.menu.visible = false
    m.albumList.visible = true
    m.title.text = "Choose an album"
    if m.albumNames.Count() <= 1 then
        m.hint.text = "No folders with photos found. Each folder on the USB drive shows up here as an album."
    else
        m.hint.text = "Each folder on the USB drive is an album. Press OK to choose one, or Back to cancel."
    end if
    m.albumList.jumpToItem = m.albumIndex
    m.albumList.setFocus(true)
end sub

sub showMenu()
    m.albumList.visible = false
    m.menu.visible = true
    m.title.text = "Keyframe settings"
    m.hint.text = "Press OK to change a setting. Changes are saved straight away."
    refreshMenu()
    m.menu.setFocus(true)
end sub

sub onAlbumSelected()
    m.albumIndex = m.albumList.itemSelected
    m.top.settingChange = { key: "album", index: m.albumIndex }
    showMenu()
end sub

' Back from the album list returns to the menu; Back from the menu exits.
function onKeyEvent(key as string, press as boolean) as boolean
    if press and key = "back" and m.albumList.visible then
        showMenu()
        return true
    end if
    return false
end function
