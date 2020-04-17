--[[
    author: szymcio
	github.com/szymixooo
]]

noti = function(text,type,time,player)
    triggerClientEvent(player,'notifications.create',player,text,type,time)
end