if isServer() then
    return
end
local formatting = require("PhunRunners/formating")
require "ISUI/ISPanel"
PhunWoLUIDetails = ISPanel:derive("PhunWoLUIDetails");
local UI = PhunWoLUIDetails
local PW = PhunWoL
local PS = PhunStats

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
    o.myData = PW.data[o.playerName]
    UI.instance = o;
    return o;
end

function UI:updateData()

    self.datas:clear();
    self.myData = PW.data[self.playerName]
    local data = {}

    for k, v in pairs(PW.data) do
        -- v.online = PW.online[k] == true
        v.u = k
        table.insert(data, v)
    end

    table.sort(data, function(a, b)
        if a.m ~= b.m then
            -- if modified time is different, sort by modified time
            return a.m > b.m
        end
        -- otherwise sort by playername
        return a.u > b.u
    end)

    for _, v in ipairs(data) do
        self.datas:addItem(v.u, v)
    end

    self.loading:setVisible(PW.received ~= true);
    self.datas:setVisible(PW.received == true);

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
    self.datas.onMouseMove = self.doOnMouseMove
    self.datas.onMouseMoveOutside = self.doOnMouseMoveOutside

    local loadingText = getTextOrNull("UI_PhunWoL_Loading") or "Loading..."
    local loadingWidth = getTextManager():MeasureStringY(UIFont.Large, loadingText)
    local loadingHeight = getTextManager():MeasureStringX(UIFont.Large, loadingText)

    self.loading = ISLabel:new(10, HEADER_HGT, FONT_HGT_LARGE, loadingText, 1, 1, 1, 1, UIFont.Large, true);
    self.loading:initialise();
    self.loading:instantiate();
    self.loading:setAnchorLeft(true);
    self.loading:setAnchorRight(true);
    self.loading:setAnchorTop(true);
    self.loading:setAnchorBottom(true);
    self.loading:setVisible(true);
    self:addChild(self.loading);

    self.tooltip = ISToolTip:new();
    self.tooltip:initialise();
    self.tooltip:setVisible(false);
    self.tooltip:setAlwaysOnTop(true)
    self.tooltip.description = "";
    self.tooltip:setOwner(self.datas)

    self.datas.drawBorder = true;
    self.datas:addColumn(getTextOrNull("UI_PhunWoL_PlayerName") or "Player", 0);
    self.datas:addColumn(getTextOrNull("UI_PhunWoL_LastOnline") or "Last Online", 150);
    self:addChild(self.datas);
    self.datas:setVisible(false);
    self:updateData(PW.data or {}, PW.online or {})
    Events[PW.events.OnDataReceived].Add(function()
        self:updateData()
    end)
    Events.OnCreatePlayer.Add(function(index, playerObj)
        self:updateData()
    end)
    Events[PW.events.updated].Add(function()
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
    self:drawText(item.item.u, xoffset, y + 4, 1, 1, 1, a, self.font);
    self:clearStencilRect()

    local value = item.item.o and getTextOrNull("UI_PhunWoL_Online") or formatting:getTimeDiffAsString(item.item.m)
    local valueWidth = getTextManager():MeasureStringX(self.font, value)
    local w = self.width
    local cw = self.columns[2].size
    self:drawText(value, w - valueWidth - xoffset - 4, y + 4, 1, 1, 1, a, self.font);
    self.itemsHeight = y + self.itemheight;
    return self.itemsHeight;
end

function UI:doOnMouseMoveOutside(dx, dy)
    local tooltip = self.parent.tooltip
    tooltip:setVisible(false)
    tooltip:removeFromUIManager()
end

function UI:doOnMouseMove(dx, dy)

    local item = nil
    local tooltip = nil

    if not self.dragging and self.rowAt then
        if self:isMouseOver() then
            local row = self:rowAt(self:getMouseX(), self:getMouseY())
            if row ~= nil and row > 0 and self.items[row] then
                item = self.items[row].item
                if item then
                    tooltip = self.parent.tooltip
                    local viewer = self.parent.viewer
                    tooltip:setName(item.u)
                    local desc = {}

                    if item.o then
                        table.insert(desc, getText("UI_PhunWoL_OnlineForX", formatting:timeDifferenceAsText(
                            getTimestamp(), item.s, getText("UI_PhunWoL_LessThanAMinute"))))
                    else
                        table.insert(desc, getText("UI_PhunWoL_LastSeenX", formatting:timeAgo(item.m)))
                    end

                    if self.parent.myData and self.parent.myData.u ~= item.u then
                        if self.parent.myData.s < item.c then
                            table.insert(desc, "\n")
                            table.insert(desc, getText("UI_PhunWoL_JustJoined"))
                        elseif self.parent.myData.pm < item.c then
                            -- table.insert(desc, os.date("%Y-%m-%d %H:%M:%S", self.parent.myData.pm))
                            -- table.insert(desc, os.date("%Y-%m-%d %H:%M:%S", item.c))
                            table.insert(desc, getText("UI_PhunWoL_NewSinceYouWereLastOn"))
                        end
                    end
                    if isAdmin() then
                        table.insert(desc, "\n")
                        table.insert(desc, getText("UI_PhunWoL_SessionCountX", item.n))

                    end

                    tooltip.description = table.concat(desc, "\n")
                    if not tooltip:isVisible() then

                        tooltip:addToUIManager();
                        tooltip:setVisible(true)
                    end
                    tooltip:bringToTop()
                elseif self.parent.tooltip:isVisible() then
                    self.parent.tooltip:setVisible(false)
                    self.parent.tooltip:removeFromUIManager()
                end
            end
        end
    end

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

