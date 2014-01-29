class "PM"

function PM:__init ( )
	self.messages = { }
	self.GUI = { }
	for i = 1, 50 do
		table.insert ( self.messages, "This is a fucking test message yay!" )
	end

	self.GUI.window = GUI:Window ( "Private Messaging", Vector2 ( 0.5, 0.5 ) - Vector2 ( 0.4, 0.61 ) / 2, Vector2 ( 0.4, 0.61 ) )
	self.GUI.window:SetVisible ( false )
	self.GUI.list = GUI:SortedList ( Vector2 ( 0.0, 0.0 ), Vector2 ( 0.4, 0.85 ), self.GUI.window, { { name = "Player" } } )
	self.GUI.list:Subscribe ( "RowSelected", self, self.loadMessages )
	self.GUI.refresh = GUI:Button ( "Refresh list", Vector2 ( 0.0, 0.87 ), Vector2 ( 0.4, 0.05 ), self.GUI.window )
	self.GUI.refresh:Subscribe ( "Press", self, self.refreshList )
	self.GUI.labelM = GUI:Label ( "Messages:\n______________________________________________________", Vector2 ( 0.43, 0.02 ), Vector2 ( 0.4, 0.05 ), self.GUI.window )
	self.GUI.labelM:SizeToContents ( )
	self.GUI.messagesScroll = GUI:ScrollControl ( Vector2 ( 0.43, 0.07 ), Vector2 ( 0.54, 0.67 ), self.GUI.window )
	self.GUI.messagesLabel = GUI:Label ( "", Vector2 ( 0.0, 0.011 ), Vector2 ( 0.95, 0.3 ), self.GUI.messagesScroll )
	self.GUI.messagesLabel:SetWrap ( true )
	self.GUI.message = GUI:TextBox ( "", Vector2 ( 0.43, 0.78 ), Vector2 ( 0.54, 0.06 ), "text", self.GUI.window )
	self.GUI.message:Subscribe ( "ReturnPressed", self, self.sendMessage )
	self.GUI.send = GUI:Button ( "Send", Vector2 ( 0.43, 0.87 ), Vector2 ( 0.24, 0.05 ), self.GUI.window )
	self.GUI.send:Subscribe ( "Press", self, self.sendMessage )
	self.GUI.clear = GUI:Button ( "Clear", Vector2 ( 0.73, 0.87 ), Vector2 ( 0.24, 0.05 ), self.GUI.window )
	self.GUI.clear:Subscribe ( "Press", self, self.clearMessage )

	self.playerToRow = { }
	for player in Client:GetPlayers ( ) do
		self:addPlayerToList ( player )
	end

	Events:Subscribe ( "PlayerJoin", self, self.playerJoin )
	Events:Subscribe ( "PlayerQuit", self, self.playerQuit )
	Events:Subscribe ( "KeyUp", self, self.keyUp )
	Events:Subscribe ( "LocalPlayerInput", self, self.localPlayerInput )
	Network:Subscribe ( "PM.addMessage", self, self.addMessage )
end

function PM:keyUp ( args )
	if ( args.key == VirtualKey.F6 ) then
		self.GUI.window:SetVisible ( not self.GUI.window:GetVisible ( ) )
		Mouse:SetVisible ( self.GUI.window:GetVisible ( ) )
	end
end

function PM:localPlayerInput ( args )
	if ( self.GUI.window:GetVisible ( ) and Game:GetState ( ) == GUIState.Game ) then
		return false
	end
end

function PM:addPlayerToList ( player )
	local item = self.GUI.list:AddItem ( tostring ( player:GetName ( ) ) )
	item:SetVisible ( true )
	item:SetDataObject ( "id", player )
	self.playerToRow [ player ] = item
end

function PM:playerJoin ( args )
	self:addPlayerToList ( args.player )
end

function PM:playerQuit ( args )
	if ( self.playerToRow [ args.player ] ) then
		self.GUI.list:RemoveItem ( self.playerToRow [ args.player ] )
		self.playerToRow [ args.player ] = nil
	end
end

function PM:loadMessages ( )
	local row = self.GUI.list:GetSelectedRow ( )
	if ( row ~= nil ) then
		local player = row:GetDataObject ( "id" )
		self.GUI.messagesLabel:SetText ( "" )
		if ( self.messages [ tostring ( player:GetSteamId ( ) ) ] ) then
			for index, msg in ipairs ( self.messages [ tostring ( player:GetSteamId ( ) ) ] ) do
				if ( index > 1 ) then
					self.GUI.messagesLabel:SetText ( self.GUI.messagesLabel:GetText ( ) .."\n".. tostring ( msg ) )
				else
					self.GUI.messagesLabel:SetText ( tostring ( msg ) )
				end
			end
		end
		self.GUI.messagesLabel:SizeToContents ( )
	end
end

function PM:addMessage ( data )
	if ( data.player ) then
		if ( not self.messages [ tostring ( data.player:GetSteamId ( ) ) ] ) then
			self.messages [ tostring ( data.player:GetSteamId ( ) ) ] = { }
		end
		local row = self.GUI.list:GetSelectedRow ( )
		if ( row ~= nil ) then
			local player = row:GetDataObject ( "id" )
			if ( data.player == player ) then
				if ( #self.messages [ tostring ( data.player:GetSteamId ( ) ) ] > 0 ) then
					self.GUI.messagesLabel:SetText ( self.GUI.messagesLabel:GetText ( ) .."\n".. tostring ( data.text ) )
				else
					self.GUI.messagesLabel:SetText ( tostring ( data.text ) )
				end
				self.GUI.messagesLabel:SizeToContents ( )
			end
		end
		table.insert ( self.messages [ tostring ( data.player:GetSteamId ( ) ) ], data.text )
	end
end

function PM:sendMessage ( )
	local row = self.GUI.list:GetSelectedRow ( )
	if ( row ~= nil ) then
		local player = row:GetDataObject ( "id" )
		if ( player ) then
			local text = self.GUI.message:GetText ( )
			if ( text ~= "" ) then
				Network:Send ( "PM.send", { player = player, text = text } )
				self.GUI.message:SetText ( "" )
			end
		else
			Chat:Print ( "Player is not online!", Color ( 255, 0, 0 ) )
		end
	else
		Chat:Print ( "No player selected!", Color ( 255, 0, 0 ) )
	end
end

function PM:clearMessage ( )
	self.GUI.message:SetText ( "" )
end

function PM:refreshList ( )
	self.GUI.list:Clear ( )
	self.playerToRow = { }
	for player in Client:GetPlayers ( ) do
		self:addPlayerToList ( player )
	end
end

pm = PM ( )

class "GUI"

local textBoxTypes =
	{
		[ "text" ] = TextBox,
		[ "numeric" ] = TextBoxNumeric,
		[ "multiline" ] = TextBoxMultiline,
		[ "password" ] = PasswordTextBox
	}

function GUI:Window ( title, pos, size )
	local window = Window.Create ( )
	window:SetTitle ( title )
	window:SetPositionRel ( pos )
	window:SetSizeRel ( size )

	return window
end

function GUI:Button ( text, pos, size, parent )
	local button = Button.Create ( )
	button:SetText ( text )
	if ( parent ) then
		button:SetParent ( parent )
	end
	button:SetPositionRel ( pos )
	button:SetSizeRel ( size )

	return button
end

function GUI:Label ( text, pos, size, parent )
	local label = Label.Create ( )
	label:SetText ( text )
	if ( parent ) then
		label:SetParent ( parent )
	end
	label:SetPositionRel ( pos )
	label:SetSizeRel ( size )

	return label
end

function GUI:SortedList ( pos, size, parent, columns )
	local list = SortedList.Create ( )
	if ( parent ) then
		list:SetParent ( parent )
	end
	list:SetPositionRel ( pos )
	list:SetSizeRel ( size )
	if ( type ( columns ) == "table" and #columns > 0 ) then
		for _, col in ipairs ( columns ) do
			if tonumber ( col.width ) then
				list:AddColumn ( tostring ( col.name ), tonumber ( col.width ) )
			else
				list:AddColumn ( tostring ( col.name ) )
			end
		end
	end

	return list
end

function GUI:TextBox ( text, pos, size, type, parent )
	local func = textBoxTypes [ type ]
	if ( func ) then
		local textBox = func.Create ( )
		if ( parent ) then
			textBox:SetParent ( parent )
		end
		textBox:SetText ( text )
		textBox:SetPositionRel ( pos )
		textBox:SetSizeRel ( size )

		return textBox
	else
		return false
	end
end

function GUI:ScrollControl ( pos, size, parent )
	local scroll = ScrollControl.Create ( )
	if ( parent ) then
		scroll:SetParent ( parent )
	end
	scroll:SetPositionRel ( pos )
	scroll:SetSizeRel ( size )

	return scroll
end