local tools = {}

function tools:formatWholeNumber(number)
    number = number or 0
    -- Round the number to remove the decimal part
    local roundedNumber = math.floor(number + 0.5)
    -- Convert to string and format with commas
    local formattedNumber = tostring(roundedNumber):reverse():gsub("(%d%d%d)", "%1,")
    formattedNumber = formattedNumber:reverse():gsub("^,", "")
    return formattedNumber
end

function tools:getTimeDiffAsString(value)

    local secondsAgo = getTimestamp() - value

    if secondsAgo < 60 then
        return "Less than a minute ago"
    elseif secondsAgo < 3600 then
        local minutes = math.floor(secondsAgo / 60)
        return minutes .. " minute" .. (minutes > 1 and "s" or "") .. " ago"
    elseif secondsAgo < 86400 then
        local hours = math.floor(secondsAgo / 3600)
        return hours .. " hour" .. (hours > 1 and "s" or "") .. " ago"
    else
        local days = math.floor(secondsAgo / 86400)
        return days .. " day" .. (days > 1 and "s" or "") .. " ago"
    end

end

function tools:timeDifferenceAsText(time1, time2, defaultText)
    local days, hours, minutes, seconds = self:timeDifference(time1, time2)
    local result = {}
    if days > 1 then
        table.insert(result, days .. " " .. getText("UI_PhunTools_Days"))
    elseif days > 0 then
        table.insert(result, days .. " " .. getText("UI_PhunTools_Day"))
    end
    if hours > 1 then
        table.insert(result, hours .. " " .. getText("UI_PhunTools_Hours"))
    elseif hours > 0 then
        table.insert(result, hours .. " " .. getText("UI_PhunTools_Hour"))
    end
    if minutes > 1 then
        table.insert(result, minutes .. " " .. getText("UI_PhunTools_Minutes"))
    elseif minutes > 0 then
        table.insert(result, minutes .. " " .. getText("UI_PhunTools_Minute"))
    end

    if #result > 0 then
        return table.concat(result, " ")
    else
        return defaultText or getText("UI_PhunTools_LessThanHour")
    end

end

function tools:timeDifference(time1, time2)
    local diff = (time1 or 0) - (time2 or 0)
    if diff < 0 then
        return 0, 0, 0, 0
    end
    local days = math.floor(diff / 86400)
    local hours = math.floor((diff % 86400) / 3600)
    local minutes = math.floor((diff % 3600) / 60)
    local seconds = math.floor(diff % 60)
    return days, hours, minutes, seconds
end

function tools:timeAgo(fromTime, toTime)
    -- Default to current time if toTime is not provided
    toTime = toTime or os.time()

    -- Calculate the difference in seconds
    local diff = os.difftime(toTime, fromTime)

    -- Define time intervals in seconds
    local secondsInMinute = 60
    local secondsInHour = 3600
    local secondsInDay = 86400
    local secondsInMonth = 2592000 -- Approximate (30 days)
    local secondsInYear = 31536000 -- Approximate (365 days)

    -- Calculate time components
    local years = math.floor(diff / secondsInYear)
    diff = diff % secondsInYear
    local months = math.floor(diff / secondsInMonth)
    diff = diff % secondsInMonth
    local days = math.floor(diff / secondsInDay)
    diff = diff % secondsInDay
    local hours = math.floor(diff / secondsInHour)
    diff = diff % secondsInHour
    local minutes = math.floor(diff / secondsInMinute)
    local seconds = diff % secondsInMinute

    -- Build the result string
    local timeAgo = {}

    if years > 0 then
        table.insert(timeAgo, years .. (years == 1 and " year" or " years"))
    end

    if months > 0 then
        table.insert(timeAgo, months .. (months == 1 and " month" or " months"))
    end

    if days > 0 then
        table.insert(timeAgo, days .. (days == 1 and " day" or " days"))
    end

    if hours > 0 then
        table.insert(timeAgo, hours .. (hours == 1 and " hour" or " hours"))
    end

    if minutes > 0 then
        table.insert(timeAgo, minutes .. (minutes == 1 and " minute" or " minutes"))
    end

    if seconds > 0 and #timeAgo == 0 then
        -- Only include seconds if no larger units are present
        seconds = math.floor(seconds + 0.5)
        table.insert(timeAgo, seconds .. (seconds == 1 and " second" or " seconds"))
    end

    if #timeAgo == 0 then
        return "Just now"
    else
        return table.concat(timeAgo, ", ") .. " ago"
    end

end

return tools
