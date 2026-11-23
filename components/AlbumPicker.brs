sub init()
    m.list = m.top.findNode("list")
    m.hint = m.top.findNode("hint")
    m.list.observeField("itemSelected", "onSelected")
end sub

sub onAlbums()
    names = m.top.albums
    content = CreateObject("roSGNode", "ContentNode")
    for each name in names
        item = content.createChild("ContentNode")
        item.title = name
    end for
    m.list.content = content

    if names.Count() <= 1 then
        m.hint.text = "No folders with photos found. Each folder on the USB drive shows up here as an album."
    else
        m.hint.text = "Each folder on the USB drive is an album. Press OK to choose one."
    end if

    current = m.top.current
    if current < 0 or current >= names.Count() then current = 0
    m.list.checkedItem = current
    m.list.jumpToItem = current
    m.list.setFocus(true)
end sub

sub onSelected()
    m.top.chosen = m.list.itemSelected
end sub
