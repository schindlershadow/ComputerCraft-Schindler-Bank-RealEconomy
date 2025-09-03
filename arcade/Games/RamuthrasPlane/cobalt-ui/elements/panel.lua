local panel = {
	x = 1,
	y = 1,
	w = 10,
	h = 5,
	backColour = colours.white,
	foreColour = colours.black,

	state = "_ALL",
	isroot = false,
	sortChildren = true,
	type = "panel",
	alwaysfocus = false,
	scrollx = 0,
	scrolly = 0,
	autosize = true,
	marginleft = 0,
	margintop = 0,
	autow = "none",
	autoh = "none",
	automl = false,
	automt = false,
	wrap = "left",
}
panel.__index = panel

function panel:getPercentages()
	if type(self.w) == "string" then
		self.w = cobalt.getPercentage( self.w )
		self.autow = self.w
	else
		self.autow = "none"
	end
	if type(self.h) == "string" then
		self.h = cobalt.getPercentage( self.h )
		self.autoh = self.h
	else
		self.autoh = "none"
	end

	if type(self.marginleft) == "string" then
		self.marginleft = cobalt.getPercentage( self.marginleft )
		self.automl = self.marginleft
	end
	if type(self.margintop) == "string" then
		self.margintop = cobalt.getPercentage( self.margintop )
		self.automt = self.margintop
	end
	if type(self.x) == "string" then
		self.x = cobalt.getPercentage( self.x )
		self.autox = self.x
	end
	if type(self.y) == "string" then
		self.y = cobalt.getPercentage( self.y )
		self.autoy = self.y
	end
end


function panel.new( data, parent, isroot )
	local self
	if data.style then
		local t = data.style
		for k, v in pairs( t ) do
			if not data[k] then
				data[k] = v
			end
		end
		data.style = nil
	end
	self = setmetatable(data,panel)
	if not self.isroot then self.parent = parent end
	self.children = { }

	self:getPercentages()

	self.bw = self.w
	self.bh = self.h



	if isroot then
		table.insert( cui.roots, self )
		self.isroot = true
	else
		if not parent then
			error( "Expected parent object")
		end
		table.insert( parent.children, self )
	end

	self:resize()
	return self
end

function panel:resize( w, h )
	if w then
		self.w = w or self.w
		if type( self.w ) == "string" then
			self:getPercentages()
		else
			self.autow = "none"
		end
	end
	if h then
		self.h = h or self.h
		if type( self.h ) == "string" then
			self:getPercentages()
		else
			self.autoh = "none"
		end
	end
	local w, h
	if self.parent then
		w = self.parent.w
		h = self.parent.h
	else
		w = cobalt.window.getWidth()
		h = cobalt.window.getHeight()
	end
	if type( self.autow ) == "number" then
		self.w = math.floor( w * self.autow )
	end
	if type( self.autoh ) == "number" then
		self.h = math.floor( h * self.autow )
	end
	if type( self.automl ) == "number" then
		self.marginleft = math.floor( w * self.automl )
	end
	if type( self.automt ) == "number" then
		self.margintop = math.floor( h * self.automt )
	end
	if self.autox and type( self.autox ) == "number" then
		self.x = math.ceil( w * self.autox )
	end
	if self.autoy and type( self.autoy ) == "number" then
		self.y = math.ceil( h * self.autoy )
	end
	if self.children then
		for i, v in pairs( self.children ) do
			v:resize()
		end
	end
	self.surf = nil
	self.surf = cobalt.surface.create( self.w, self.h, " ", self.backColour, self.foreColour )
end

function panel:setMargins( t, l )
	if t then
		self.margintop = t or self.margintop
		if type(t) == "string" then
			self:getPercentages()
		else
			self.automt = "none"
		end
	end
	if l then
		self.marginleft = l or self.marginleft
		if type(l) == "string" then
			self:getPercentages()
		else
			self.automl = "none"
		end
	end
	self:resize()
end

function panel:getAbsX()
	if not self.isroot then
		return self.x + self.parent:getAbsX()-1 + self.marginleft
	end
	return self.x + self.marginleft
end

function panel:getAbsY()
	if not self.isroot then
		return self.y + math.floor(self.parent:getAbsY())-1 + self.margintop
	end
	return self.y + self.margintop
end

function panel:getAbsW()
	return self:getAbsX() + self.w
end

function panel:getAbsH()
	return self:getAbsY() + self.h
end

function panel:setBackgroundColour( colour )
	self.backColour = colour or self.backColour
end

function panel:add( type, data )
	return cui.elements[type].new( data, self, false )
end

function panel:getCheckResults( group )
	local results = { }
	group = group or "_ALL"
	for k, v in pairs( self.children ) do
		if v.type and v.type == "checkbox" then
			if v.group == group or group == "_ALL" then
				if v.selected then
					results[#results+1] = v.val
				end
			end
		end
	end
	return results
end

function panel:getRadioResults( group )
	local results = { }
	group = group or "_ALL"
	for k, v in pairs( self.children ) do
		if v.type and v.type == "radio" then
			if v.group == group or group == "_ALL" then
				if v.selected then
					results[#results+1] = v.val
				end
			end
		end
	end
	return results
end



function panel:bringToFront()

	if self.parent and self.parent.sortChildren then
		for k, v in pairs( self.parent.children ) do
			if v == self then
				table.remove( self.parent.children, k )
				table.insert( self.parent.children, 1, v )
			end
		end
	else
		for k, v in pairs( cui.roots ) do
			if v == self then
				table.remove( cui.roots, k )
				table.insert( cui.roots, 1, v )
			end
		end
	end

end
function panel:sendToBack()

	if self.parent and self.parent.sortChildren then
		for k, v in pairs( self.parent.children ) do
			if v == self then
				table.remove( self.parent.children, k )
				table.insert( self.parent.children, #self.parent.children, v )
			end
		end
	else
		for k, v in pairs( cui.roots ) do
			if v == self then
				table.remove( cui.roots, k )
				table.insert( cui.roots, #cui.roots, v )
			end
		end
	end

end

function panel:update( dt )
	if self.w ~= self.bw then
		self.bw = self.w
		self:resize()
	end
	if self.h ~= self.bh then
		self.bh = self.h
		self:resize()
	end
	for i, v in pairs( self.children ) do
		if v.update then v:update(dt) end
	end

end

function panel:draw( )
	if self.wrap == "center" then
		self.x = ( self.parent.w/2 - self.w/2 ) + self.marginleft
	end
	if self.state == cobalt.state or self.state == "_ALL" then
		self.surf:clear(" ", self.backColour, self.foreColour)
		for i, v in pairs( self.children ) do
			if v.draw then v:draw() end
		end
		if self.isroot then
			if cobalt.application.view then
				cobalt.application.view:drawSurface( self.x + self.marginleft, self.y + self.margintop, self.surf )
			else
				self.surf:render(term, self.x+self.marginleft, self.y+self.margintop, self.scrollx, self.scrolly, self.scrollx + self.w, self.scrolly+self.h)
			end
		else
			self.parent.surf:drawSurface(self.x+self.marginleft, self.y+self.margintop, self.surf)
		end
	end
end

function panel:mousepressed( x, y, button )
	if self.alwaysfocus then
		self:bringToFront()
	end

	if self.state == cobalt.state or self.state == "_ALL" then
		if x >= self:getAbsX() and x <= self:getAbsX() + self.w and y >= self:getAbsY() and y <= self:getAbsY() + self.h then
			self:bringToFront()
			for i, v in pairs( self.children ) do
				if v.mousepressed then v:mousepressed( x, y, button ) end
			end

			return true
		else
			for i, v in pairs( self.children ) do
				if v.disable then v:disable() end
			end
		end
	end
end

function panel:paste( text )
	for i, v in pairs( self.children ) do
		if v.paste then
			v:paste( text )
		end
	end
end

function panel:mousereleased( x, y, button )

	if x >= self:getAbsX() and x <= self:getAbsX() + self.w and y >= self:getAbsY() and y <= self:getAbsY() + self.h then
		if self.state == cobalt.state or self.state == "_ALL" then
			for i, v in pairs( self.children ) do
				if v.mousereleased then v:mousereleased( x, y, button ) end
			end
			return true
		end
	end
end

function panel:textinput( t )

	if self.state == cobalt.state or self.state == "_ALL" then
		--

		for k, v in pairs( self.children ) do
			if v.textinput then v:textinput( t ) end
		end
	end

end

function panel:keypressed( keycode, key )
	if self.state == cobalt.state or self.state == "_ALL" then
		for k, v in pairs( self.children ) do
			if v.keypressed then v:keypressed( keycode, key ) end
		end

	end
end

function panel:mousedrag( x, y )
	for k, v in pairs( self.children ) do
		if v.mousedrag then v:mousedrag( x, y ) end
	end
end

function panel:keyreleased( keycode, key )
	if self.state == cobalt.state or self.state == "_ALL" then

		for k, v in pairs( self.children ) do
			if v.keyreleased then v:keyreleased( keycode, key ) end
		end

	end
end

return panel