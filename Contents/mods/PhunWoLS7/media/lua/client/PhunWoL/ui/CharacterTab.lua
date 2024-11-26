if not isClient() then
    return
end

require "ISUI/ISPanel"
PhunWoLUIDetails = ISPanel:derive("PhunWoLUIDetails");
local UI = PhunWoLUIDetails
local PW = PhunWoL

local FONT_HGT_SMALL = getTextManager():getFontHeight(UIFont.Small)
local FONT_HGT_MEDIUM = getTextManager():getFontHeight(UIFont.Medium)
local FONT_HGT_LARGE = getTextManager():getFontHeight(UIFont.Large)

local HEADER_HGT = FONT_HGT_MEDIUM + 2 * 2

function UI:initialise()
    ISPanel.initialise(self);
end

function UI:new(x, y, width, height, viewer, source)
    local o = ISPanel:new(x, y, width, height);
    setmetatable(o, self);
    o.listHeaderColor = {
        r = 0.4,
        g = 0.4,
        b = 0.4,
        a = 0.3
    };
    o.borderColor = {
        r = 0.4,
        g = 0.4,
        b = 0.4,
        a = 0
    };
    o.backgroundColor = {
        r = 0,
        g = 0,
        b = 0,
        a = 1
    };
    o.buttonBorderColor = {
        r = 0.7,
        g = 0.7,
        b = 0.7,
        a = 0.5
    };
    o.totalResult = 0;
    o.filterWidgets = {};
    o.filterWidgetMap = {}
    o.itemsHeight = 200
    o.viewer = getSpecificPlayer(viewer)
    o.playerName = o.viewer:getUsername()
    UI.instance = o;
    return o;
end

function UI:updateData()

    self.datas:clear();
    local data = {}

    for k, v in pairs(PW.data) do
        v.online = PW.online[k] == true
        table.insert(data, v)

    end

    table.sort(data, function(a, b)
        if a.lastOnline ~= b.lastOnline then
            return a.lastOnline > b.lastOnline
        end
        return a.playername > b.playername
    end)

    for _, v in ipairs(data) do
        self.datas:addItem(v.playername, v)
    end

end

function UI:createChildren()
    ISPanel.createChildren(self);

    self.datas = ISScrollingListBox:new(0, HEADER_HGT, self.width, self.height - HEADER_HGT);
    self.datas:initialise();
    self.datas:instantiate();
    self.datas.itemheight = FONT_HGT_SMALL + 4 * 2
    self.datas.selected = 0;
    self.datas.joypadParent = self;
    self.datas.font = UIFont.NewSmall;
    self.datas.doDrawItem = self.drawDatas;
    self.datas.drawBorder = true;
    self.datas:addColumn("Player", 0);
    self.datas:addColumn("Last Seen", 200);
    self:addChild(self.datas);
    self:updateData(PW.data or {}, PW.online or {})
    Events[PW.events.OnDataReceived].Add(function()
        self:updateData()
    end)
    Events.OnCreatePlayer.Add(function(index, playerObj)
        self:updateData()
    end)
end

function UI:prerender()
    ISPanel.prerender(self);

    if PW.lastChangeKey ~= self.lastChangeKey then
        self:updateData(PW.data or {}, PW.online or {})
        self.lastChangeKey = PW.lastChangeKey
    end

    local maxWidth = self.parent.width
    local maxHeight = self.parent.height
    if maxHeight > 400 then
        maxHeight = 400
    end
    local minHeight = 250
    local sw = maxWidth
    local tabY = self.parent.tabHeight
    self:setWidth(sw)
    self.datas:setX(10)
    self.datas:setWidth(self.parent.width - 20)
    self.datas:setY(tabY + 10)
    local height = maxHeight - (tabY + 20) - self.datas.itemheight
    if height > maxHeight then
        height = maxHeight
    end
    self.datas:setHeight(height)
end

function UI:drawDatas(y, item, alt)

    if y + self:getYScroll() + self.itemheight < 0 or y + self:getYScroll() >= self.height then
        return y + self.itemheight
    end

    local a = 0.9;

    if self.selected == item.index then
        self:drawRect(0, (y), self:getWidth(), self.itemheight, 0.3, 0.7, 0.35, 0.15);
    end

    if alt then
        self:drawRect(0, (y), self:getWidth(), self.itemheight, 0.3, 0.6, 0.5, 0.5);
    end

    self:drawRectBorder(0, (y), self:getWidth(), self.itemheight, a, self.borderColor.r, self.borderColor.g,
        self.borderColor.b);

    local iconX = 4
    local iconSize = FONT_HGT_SMALL;
    local xoffset = 10;

    local clipX = self.columns[1].size
    local clipX2 = self.columns[2].size
    local clipY = math.max(0, y + self:getYScroll())
    local clipY2 = math.min(self.height, y + self:getYScroll() + self.itemheight)

    self:setStencilRect(clipX, clipY, clipX2 - clipX, clipY2 - clipY)
    self:drawText(item.item.playername, xoffset, y + 4, 1, 1, 1, a, self.font);
    self:clearStencilRect()

    local value = item.item.online and "Online" or PhunTools:getTimeDiffAsString(item.item.lastOnline)
    local valueWidth = getTextManager():MeasureStringX(self.font, value)
    local w = self.width
    local cw = self.columns[2].size
    self:drawText(value, w - valueWidth - xoffset - 4, y + 4, 1, 1, 1, a, self.font);
    self.itemsHeight = y + self.itemheight;
    return self.itemsHeight;
end
local function moveEntry(tbl, fromIndex, toIndex)
    -- Ensure the indices are within the valid range
    if fromIndex < 1 or fromIndex > #tbl or toIndex < 1 or toIndex > #tbl then
        return tbl -- Return the table unchanged if indices are out of range
    end

    -- Extract the entry
    local entry = table.remove(tbl, fromIndex)

    -- Insert the entry at the new position
    table.insert(tbl, toIndex, entry)

    return tbl
end
local function addCharacterPageTab(tabName, pageType, label)
    local viewName = tabName .. "View"
    local upperLayer_ISCharacterInfoWindow_createChildren = ISCharacterInfoWindow.createChildren
    function ISCharacterInfoWindow:createChildren()
        upperLayer_ISCharacterInfoWindow_createChildren(self)
        self[viewName] = pageType:new(0, 8, self.width, self.height - 8, self.playerNum)
        self[viewName]:initialise()
        self[viewName].infoText = getText("UI_" .. tabName .. "Panel");
        self.panel:addView(label, self[viewName])
        moveEntry(self.panel.viewList, #self.panel.viewList, 4)
    end

    local upperLayer_ISCharacterInfoWindow_onTabTornOff = ISCharacterInfoWindow.onTabTornOff
    function ISCharacterInfoWindow:onTabTornOff(view, window)
        if self.playerNum == 0 and view == self[viewName] then
            ISLayoutManager.RegisterWindow('charinfowindow.' .. tabName, ISCollapsableWindow, window)
        end
        upperLayer_ISCharacterInfoWindow_onTabTornOff(self, view, window)

    end

    local upperLayer_ISCharacterInfoWindow_SaveLayout = ISCharacterInfoWindow.SaveLayout
    function ISCharacterInfoWindow:SaveLayout(name, layout)
        upperLayer_ISCharacterInfoWindow_SaveLayout(self, name, layout)

        local tabs = {}
        if self[viewName].parent == self.panel then
            table.insert(tabs, tabName)
            if self[viewName] == self.panel:getActiveView() then
                layout.current = tabName
            end
        end
        if not layout.tabs then
            layout.tabs = ""
        end
        layout.tabs = layout.tabs .. table.concat(tabs, ',')
    end
end

addCharacterPageTab("PhunWoL", PhunWoLUIDetails, getText("UI_PhunWoL_CharacterTab"))

