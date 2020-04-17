--[[
    author: szymcio
	github.com/szymixooo
]]

local notifications = {}
local sx,sy = guiGetScreenSize()

scale_x=function(value)
    return sx * value / 1920 
end 
scale_y=function(value)
    return sy * value / 1080 
end 

bg = dxCreateTexture("bg.png","argb",false,"wrap")

function wordWrap(text, maxwidth, scale, font, colorcoded)
    local lines = {}
    local words = split(text, " ") -- this unfortunately will collapse 2+ spaces in a row into a single space
    local line = 1 -- begin with 1st line
    local word = 1 -- begin on 1st word
    local endlinecolor
    while (words[word]) do -- while there are still words to read
        repeat
            if colorcoded and (not lines[line]) and endlinecolor and (not string.find(words[word], "^#%x%x%x%x%x%x")) then -- if on a new line, and endline color is set and the upcoming word isn't beginning with a colorcode
                lines[line] = endlinecolor -- define this line as beginning with the color code
            end
            lines[line] = lines[line] or "" -- define the line if it doesnt exist

            if colorcoded then
                local rw = string.reverse(words[word]) -- reverse the string
                local x, y = string.find(rw, "%x%x%x%x%x%x#") -- and search for the first (last) occurance of a color code
                if x and y then
                    endlinecolor = string.reverse(string.sub(rw, x, y)) -- stores it for the beginning of the next line
                end
            end
      
            lines[line] = lines[line]..words[word] -- append a new word to the this line
            lines[line] = lines[line] .. " " -- append space to the line

            word = word + 1 -- moves onto the next word (in preparation for checking whether to start a new line (that is, if next word won't fit)
        until ((not words[word]) or dxGetTextWidth(lines[line].." "..words[word], scale, font, colorcoded) > maxwidth) -- jumps back to 'repeat' as soon as the code is out of words, or with a new word, it would overflow the maxwidth
    
        lines[line] = string.sub(lines[line], 1, -2) -- removes the final space from this line
        if colorcoded then
            lines[line] = string.gsub(lines[line], "#%x%x%x%x%x%x$", "") -- removes trailing colorcodes
        end
        line = line + 1 -- moves onto the next line
    end -- jumps back to 'while' the a next word exists
    return lines
end

notifications.table = {}

notifications.enabled = false 
notifications.pos = {x=scale_x(1590),y=scale_y(250)} 
notifications.size = {w=scale_x(379),h=scale_y(56)}
notifications.time = 5000
notifications.limit = 5

notifications.init = function()
    notifications.enabled=true
end 


notifications.types = {
    ['normal'] = {255,255,255},
    ['error'] = {232, 32, 32},
    ['success'] = {42, 189, 44},
    ['info'] = {255,255,255},
}
addEventHandler('onClientResourceStart',root,function()
notifications.icon = {
    ['normal'] = nil,
    ['error'] = dxCreateTexture('err.png','argb',false,'clamp'),
    ['success'] = dxCreateTexture('sukc.png','argb',false,'clamp'),
    ['info'] = dxCreateTexture('info.png','argb',false,'clamp'),

}
end)
notifications.sounds = {
    ['normal'] = false,
    ['error'] = 'sounds/error.mp3',
    ['success'] = 'sounds/success.mp3',
    ['info'] = 'sounds/info.mp3',
}

notifications.global_sound = false

notifications.create = function(text,type,time)

    if #notifications.table > notifications.limit then 
        table.remove(notifications.table,#notifications.table)
    end 

    local toTable = ''
    local wrap = wordWrap(text,notifications.size['w']-125,1,notifications.font,false)
    if #wrap > 1 then 
        for i,v in ipairs(wrap) do 
            if i == 1 then 
            toTable=toTable..v
            else 
            toTable=toTable..'\n'..v
            end 
        end 
    else 
        toTable=wrap[1]
    end 
    if notifications.sounds[type] then 
        if notifications.global_sound ~= nil then 
            destroyElement(notifications.global_sound)
        end 
        notifications.global_sound = playSound(notifications.sounds[type],false)
        setSoundVolume(notifications.global_sound, 0.3)
    end

    table.insert(notifications.table, {
        ['visible']=true,
        ['type'] = notifications.types[type] and type or 'normal',
        ['text'] = toTable,
        ['lines'] = #wrap,
        ['offset_y'] = (notifications.size['h']+ 10) * (#notifications.table+1),
        ['time'] = time or notifications.time,
        ['tick'] = getTickCount(),
        ['where'] = 'start',
    })
    outputConsole('['..type..']'..toTable)
end 


notifications.font = 'default-bold'
addEventHandler('onClientResourceStart',resourceRoot,function()
    notifications.font = dxCreateFont('f.ttf',scale_x(11))
end)

notifications.prepared_text=function(text,x,y,w,h,lines)
    if lines > 4 then 
        dxDrawText(text,x,y,w+x,h+y,white,math.max(0.5, 1 * (3 / lines)),notifications.font,'center','center',true,false,false,false,false)
    else 
        dxDrawText(text,x,y,w+x,h+y,white,1,notifications.font,'center','center',true,false,false,false,false)
    end 
end 

notifications.moveAllNotifications = function(notification)
    for i,v in ipairs(notifications.table) do 
        if i ~= notification then 
            if i > notification then 
                local offset_y = v['offset_y']
                animate(offset_y, offset_y - (notifications.size['h'] + 10), 'OutQuad', 300, function(progress)
                    v['offset_y'] = progress
                end) 
            end 
        end     
    end 
end 

notifications.draw = function(text,x,y,w,h,type,tick,time,where,lines)
    
    if where == 'start' then 
        local notification_x = interpolateBetween(x,0,0,x-h*1,0,0,(getTickCount()-tick)/500,'InOutQuad')
        local timeInterpolation = interpolateBetween(w,0,0,0,0,0,(getTickCount()-tick)/time,'Linear')
        local r,g,b = notifications.types[type][1],notifications.types[type][2],notifications.types[type][3]
        dxDrawImage(notification_x,y,w,h,bg,0,0,0,tocolor(r,g,b,255),false)
        dxDrawImage(notification_x+15,y+15,scale_x(27),scale_y(27),notifications.icon[type],0,0,0,tocolor(255,255,255,255),false)
        notifications.prepared_text(text,notification_x,y,w,h,lines)  
    elseif where=='end' then 
        local notification_x = interpolateBetween(x,0,0,x+w*1,0,0,(getTickCount()-tick)/500,'InOutQuad')
        local r,g,b = notifications.types[type][1],notifications.types[type][2],notifications.types[type][3]
        dxDrawImage(notification_x,y,w,h,bg,0,0,0,tocolor(r,g,b,255),false)
        dxDrawImage(notification_x+15,y+15,scale_x(27),scale_y(27),notifications.icon[type],0,0,0,tocolor(255,255,255,255),false)
        notifications.prepared_text(text,notification_x,y,w,h,lines)  
    end 

end 

notifications.render = function()
    for i,v in ipairs(notifications.table) do 
        if v['visible'] then 
            local posX,posY=notifications.pos['x'],notifications.pos['y']
            local width,height=notifications.size['w'],notifications.size['h']
            local offset = v['offset_y']
            notifications.draw(v['text'],posX,posY + offset,width,height,v['type'],v['tick'],v['time'],v['where'],v['lines'])

            if getTickCount()-v['tick'] > v['time'] and v['where'] == 'start' then 
                v['where'] = 'end'
                v['tick'] = getTickCount()
            elseif getTickCount()-v['tick'] > 500 and v['where'] == 'end' then
                notifications.moveAllNotifications(i)
                table.remove(notifications.table,i)
            end 

        end 
    end 
end 
addEventHandler('onClientRender',root,notifications.render)

notifications.init()

addEvent('notifications.create',true)
noti = function(text,type,time)
    notifications.create(text,type,time)
end 
addEventHandler('notifications.create',root,noti)