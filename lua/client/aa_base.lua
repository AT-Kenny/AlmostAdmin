
local function PlayerChat(ply,txt,_team,dead)
    local tab = {}
    if dead then
        table.insert(tab,Color(255,30,40))
        table.insert(tab,"*DEAD* ")
    end
    if teamchat then
        table.insert(tab,Color(30,160,40))
        table.insert(tab,"(TEAM) ")
    end
    if ply:IsValid() then
        local nick=ply:Nick()
        local tag=nick:match("%[(%w%w%w)%]")
        if tag and #tag==3 then
            local r,g,b=tag:match("(%w)(%w)(%w)")
            r=255-r:byte()^2*10
            g=255-g:byte()^2*10
            b=255-b:byte()^2*10
            
            local tagcolor=Color(r,g,b,255)
            table.insert(tab,tagcolor)
            table.insert(tab,"["..tag.."]")
            nick=nick:gsub("%["..tag.."%]","")
        end
        local tcolor = team.GetColor(ply:Team())
        local color = Color(tcolor.r,tcolor.g,tcolor.b,255)
        table.insert( tab,color) 
        table.insert(tab,nick)
    else
        table.insert(tab,"Console")
    end
    table.insert(tab,Color(255,255,255))
    table.insert(tab,": "..txt)
    chat.AddText(unpack(tab))
    return true
end

hook.Add("OnPlayerChat","TeamChatColors",PlayerChat)

hook.Add("HUDPaint","nametags",function()
    
    local function DrawNameTag(pl)
        if ( pl != LocalPlayer() and pl:Health() > 0 ) or pl:GetClass()=="at_alice" then
            local visible = hook.Call( "EV_ShowPlayerName", nil, pl )
            local name=(pl:IsPlayer()) and pl:Nick() or "Alice"
            
            if ( visible != false ) then        
                local td = {}
                td.start = LocalPlayer():GetShootPos()
                td.endpos = pl:GetPos()
                if pl:IsPlayer() then td.endpos=pl:GetShootPos() end
                local trace = util.TraceLine( td )
                
                if ( !trace.HitWorld ) then         
                    surface.SetFont( "Default" )
                    local w = surface.GetTextSize( name ) + 32
                    local h = 24
                    
                    local pos = pl:GetPos()
                    if pl:IsPlayer() then pos=pl:GetShootPos() end
                    local bone = pl:LookupBone( "ValveBiped.Bip01_Head1" )
                    if ( bone ) then
                        pos = pl:GetBonePosition( bone )
                    end             
                    
                    local drawPos = pl:GetPos():ToScreen()
                    if pl:IsPlayer() then drawPos=pl:GetShootPos():ToScreen() end
                    local distance = LocalPlayer():GetShootPos():Distance( pos )
                    drawPos.x = drawPos.x - w / 2
                    drawPos.y = drawPos.y - h - 25
                    
                    local alpha = 255
                    if ( distance > 512 ) then
                        alpha = 255 - math.Clamp( ( distance - 512 ) / ( 2048 - 512 )*255,0, 255 )
                    end
                    
                    local col = Color(255,32,164)
                    if pl:IsPlayer() then
                        col=team.GetColor( pl:Team() )
                    end
            
                    surface.SetDrawColor( 50, 50, 50, alpha )
                    surface.DrawRect( drawPos.x, drawPos.y, w, h )
                    surface.SetDrawColor( col.r,col.g,col.b, alpha )
                    surface.DrawOutlinedRect( drawPos.x, drawPos.y, w, h )
                    
                    
                    surface.SetDrawColor( 255, 255, 255, math.Clamp( alpha * 2, 0, 255 ))
                    
                    col.a = math.Clamp( alpha * 2, 0, 255 )
                    draw.DrawText( name, "Default", drawPos.x + 14, drawPos.y + 5, col, 0 )
                end
            end
        end
    end
    for _,pl in pairs(player.GetAll()) do
        DrawNameTag(pl)
    end
end)

