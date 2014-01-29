class "PM"

function PM:__init ( )
	Network:Subscribe ( "PM.send", self, self.send )
	Events:Subscribe ( "PlayerChat", self, self.playerChat )
end

function PM:send ( data, player )
	if IsValid ( data.player ) then
		data.player:SendChatMessage ( "PM from ".. tostring ( player:GetName ( ) ) ..": ".. tostring ( data.text ), Color ( 255, 255, 0 ) )
		player:SendChatMessage ( "PM to ".. tostring ( data.player:GetName ( ) ) ..": ".. tostring ( data.text ), Color ( 255, 255, 0 ) )
		Network:Send ( player, "PM.addMessage", { player = data.player, text = player:GetName ( ) ..": ".. data.text } )
		Network:Send ( data.player, "PM.addMessage", { player = player, text = player:GetName ( ) ..": ".. data.text } )
	else
		player:SendChatMessage ( "Player is not online!", Color ( 255, 0, 0 ) )
	end
end

function PM:playerChat ( args )
	local msg = args.text
	local split_msg = msg:split ( " " )
	if ( split_msg [ 1 ] == "/pm" ) then
		if ( not split_msg [ 2 ] ) then
			args.player:SendChatMessage ( "Format: /pm <name> <message>", Color ( 255, 0, 0 ) )
			return
		end

		local results = Player.Match ( split_msg [ 2 ] )
		table.remove ( split_msg, 1 )
		table.remove ( split_msg, 1 )
		local message = table.concat ( split_msg, " " )
		local to = results [ 1 ]
		if ( not to ) then
			args.player:SendChatMessage ( "Please specify a valid player name!", Color ( 255, 0, 0 ) )
			return
		elseif ( to == args.player ) then
			args.player:SendChatMessage ( "You cannot send a message to yourself!", Color ( 255, 0, 0 ) )
			return
		else
			self:send ( { player = to, text = message }, args.player )
		end
	end
end

pm = PM ( )