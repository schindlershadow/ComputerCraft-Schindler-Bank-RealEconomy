cui = { }

cui.roots = { }
cui.styles = { }
cui.elements = { }
for i, v in pairs( fs.list( "cobalt-ui/elements" ) ) do
	cui.elements[v:sub(1, #v-4)] = dofile("cobalt-ui/elements/" .. v)
end

local colcharlookup = { }
for i = 1, 16 do
	colcharlookup[ string.byte( "0123456789abcdef",i,i)] = 2^(i-1)
end
function cui.getColourFromChar( char )
	return colcharlookup[char]
end

function cui.loadStyles( path )
	if fs.exists( path ) then
		local t = dofile(path)
		table.insert( cui.styles, t )
		return t
	else
		error("file " .. path .. " does not exist")
	end
end

function cui.update( dt )
	for i, v in ipairs( cui.roots ) do
		if v.update then
			v:update( dt )
		end
	end
end

function cui.draw()
	for i = #cui.roots, 1, -1 do
		if cui.roots[i].draw then cui.roots[i]:draw() end
	end
end

function cui.new( data )
	return cui.elements["panel"].new( data, nil, true )
end

function cui.mousepressed( x, y, button )
	for i = #cui.roots, 1, -1 do
		if cui.roots[i].mousepressed then
			if cui.roots[i]:mousepressed( x, y, button ) then return end
		end
	end
end

function cui.mousereleased( x, y, button )
	for i = #cui.roots, 1, -1 do
		if cui.roots[i].mousereleased then
			if cui.roots[i]:mousereleased( x, y, button ) then return end
		end
	end
end


function cui.keypressed( keycode, key )
	for i, v in ipairs( cui.roots ) do
		if v.keypressed then
			v:keypressed( keycode, key )
		end
	end
end

function cui.keyreleased( keycode, key )
	for i, v in ipairs( cui.roots ) do
		if v.keyreleased then
			v:keyreleased( keycode, key )
		end
	end
end

function cui.textinput( t )
	for i, v in ipairs( cui.roots ) do
		if v.textinput then
			if v:textinput( t ) then return end
		end
	end
end

function cui.mousedrag( x, y )
	for i, v in ipairs( cui.roots ) do
		if v.mousedrag then
			v:mousedrag( x, y )
		end
	end
end

function cui.paste( text )
	for i, v in ipairs( cui.roots ) do
		if v.paste then
			v:paste( text )
		end
	end
end



return cui