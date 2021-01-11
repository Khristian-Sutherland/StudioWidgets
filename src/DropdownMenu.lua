----------------------------------------
--
-- DropdownMenu.lua
--
-- Creates dropdown-style selection menu.
--
----------------------------------------
GuiUtilities = require(script.Parent.GuiUtilities)


DropdownMenu = {}
DropdownMenu.__index = DropdownMenu

DropdownMenu._defaultLength = 189

function DropdownMenu.new(nameSuffix, labelText, selectionTable)
	local self = {}
	setmetatable(self, DropdownMenu)
	self._dropdownButtonHeight = GuiUtilities.kTitleBarHeight -- should be 27
	self._expandedSize = 0
	
	
	local section = GuiUtilities.MakeStandardFixedHeightFrame('DMSection' .. nameSuffix)
	self._sectionFrame = section
	
	local label = GuiUtilities.MakeStandardPropertyLabel(labelText)
	label.Parent = section

	
	local button = Instance.new("TextButton")
	button.Text = "Select an option"
	button.Size = UDim2.new(0, 100, 0.6, 0)
	button.AnchorPoint = Vector2.new(0,0.5)
	button.Position = UDim2.new(0, GuiUtilities.StandardLineElementLeftMargin, 0.5, 0)
	button.Parent = section
	GuiUtilities.syncGuiElementBorderColor(button)
	GuiUtilities.syncGuiElementInputFieldColor(button)
	GuiUtilities.syncGuiElementFontColor(button)
	
	local invisFrame = Instance.new("Frame")
	invisFrame.Size = UDim2.new(1,0,0,0)
	invisFrame.AnchorPoint = Vector2.new(0.5,0)
	invisFrame.Position = UDim2.new(0.5,0,1,0)
	invisFrame.BackgroundTransparency = 1
	invisFrame.ClipsDescendants = true
	invisFrame.Parent = button 
	
	
	local contentsFrame = Instance.new("ScrollingFrame")
	contentsFrame.CanvasSize = UDim2.new(1,0,0,0)
	contentsFrame.ScrollBarThickness = 0
	contentsFrame.Size = UDim2.new(1,-2,0,self._expandedSize)
	contentsFrame.AnchorPoint = Vector2.new(0.5,0)
	contentsFrame.Position = UDim2.new(0.5,0,0,0)
	contentsFrame.BorderSizePixel = 1
	contentsFrame.ZIndex = 9
	contentsFrame.Parent = invisFrame
	GuiUtilities.syncGuiElementInputFieldColor(contentsFrame)
	GuiUtilities.syncGuiElementBorderColor(contentsFrame)
	
	local listLayout = Instance.new("UIListLayout")
	listLayout.FillDirection = Enum.FillDirection.Vertical
	listLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
	listLayout.SortOrder = Enum.SortOrder.Name
	listLayout.Parent = contentsFrame
	
	
	self._titleLabel = label
	self._dropButton = button
	self._contentsFrame = contentsFrame
	self._invisFrame = invisFrame
	self._buttonArray = {}
	self._selected = ""
	self._expanded = false
	self._dropButton.MouseButton1Click:Connect(function()
		self:_toggleExpand()
	end)
	
	self._dropButton.MouseButton2Click:Connect(function()
		self:_retract()
		self:ResetChoice()
	end)
	
	if selectionTable then -- if the user provided a table of selections
		self:AddSelectionsFromTable(selectionTable)
	end
	
	return self
end

function DropdownMenu:_toggleExpand()
	-- get the widget
	local widget = self._invisFrame:FindFirstAncestorOfClass("DockWidgetPluginGui")
	if widget then
		-- now test if the bottom of the frame is below the absolute size of the widget
		local absSizeY = self._contentsFrame.AbsoluteSize.Y
		local absPosY = self._contentsFrame.AbsolutePosition.Y
		local absAdded
		if self._expanded and self._contentsFrame.AnchorPoint == Vector2.new(0.5,1) then
			absAdded = absSizeY+absPosY+absSizeY
		elseif self._contentsFrame.AnchorPoint == Vector2.new(0.5,1) then
			absAdded = absSizeY+absPosY+absSizeY
		else
			absAdded = absSizeY+absPosY
		end

			if not self._expanded then
			if absAdded >= widget.AbsoluteSize.Y then
				self._contentsFrame.AnchorPoint = Vector2.new(0.5,1)
				self._contentsFrame.Position = UDim2.new(0.5,0,1,0)
				self._invisFrame.AnchorPoint = Vector2.new(0.5,1)
				self._invisFrame.Position = UDim2.new(0.5,0,0,0)
			else
				self._contentsFrame.AnchorPoint = Vector2.new(0.5,0)
				self._contentsFrame.Position = UDim2.new(0.5,0,0,0)
				self._invisFrame.AnchorPoint = Vector2.new(0.5,0)
				self._invisFrame.Position = UDim2.new(0.5,0,1,0)
			end
		end
	end
	
	if self._expanded then
		self:_retract()
		self._expanded = false
	else
		self:_expand()
		self._expanded = true
	end
end

function DropdownMenu:_retract()
	self._invisFrame:TweenSize(UDim2.new(1,2,0,0), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.15, true)
	self._expanded = false
end

function DropdownMenu:_expand()
	self._invisFrame:TweenSize(UDim2.new(1,2,0,self._expandedSize+2), Enum.EasingDirection.In, Enum.EasingStyle.Quad, 0.15, true)
	self._expanded = true
end

function DropdownMenu:AddSelection(selectionTable)
	assert(type(selectionTable[1]) == "string", "Expected String for argument 1, got "..type(selectionTable[1]))
	assert(selectionTable[2] ~= nil, "Expected a value for argument 2, got nil")
	assert(type(selectionTable[3]) == "string", "Expected String for argument 3, got "..type(selectionTable[3]))
	
	if self._buttonArray[selectionTable[3]] then -- if the selection already exists
		return warn("There is already a selection with identifier: "..selectionTable[3])
	end
	
	local button = Instance.new("TextButton")
	button.Name = selectionTable[1]
	button.Text = selectionTable[1]
	button.Size = UDim2.new(1,0,0,self._dropdownButtonHeight)
	button.BackgroundTransparency = 1
	button.ZIndex = 10
	button.Parent = self._contentsFrame
	GuiUtilities.syncGuiElementFontColor(button)
	
	local connection = button.MouseButton1Click:Connect(function()
		self._selected = selectionTable[2]
		self._dropButton.Text = selectionTable[1]
		self:_retract()
	end)
	
	self._buttonArray[selectionTable[3]] = {button = button, connection = connection}
	
    -- change contentsFrame size. Remember to do this at the end next time.
	self:_updateSize()
end

function DropdownMenu:RemoveSelection(identifier)
	if self._buttonArray[identifier] then
		self._buttonArray[identifier].connection:Disconnect()
		self._buttonArray[identifier].button:Destroy()
		self._buttonArray[identifier] = nil
		self:_updateSize() -- resize frame
	end
end

function DropdownMenu:AddSelectionsFromTable(selectionTable)
	assert(type(selectionTable) == "table", "Expected table. Got "..type(selectionTable))
	
	for i,v in pairs(selectionTable) do
		if type(v) == "table" then
			self:AddSelection(v)
		end
	end
end

function DropdownMenu:ResetChoice()
	self._selected = ""
	self._dropButton.Text = "Select an option"
end

function DropdownMenu:GetChoice()
	return self._selected
end

function DropdownMenu:GetSectionFrame()
	return self._sectionFrame
end

function DropdownMenu:GetContentsFrame()
	return self._contentsFrame
end

function DropdownMenu:ChangeLabel(labelText)
	assert(type(labelText) == "string", "Expected string. Got "..type(labelText))
	self._titleLabel.Text = labelText
end

function DropdownMenu:_updateSize()
	local count = 0
	for _,v in pairs(self._buttonArray) do
		count += 1
	end
	if count >= 7 then
		self._canvasSize = count*self._dropdownButtonHeight
		self._expandedSize = DropdownMenu._defaultLength
		self._contentsFrame.CanvasSize = UDim2.new(1,-2,0,self._canvasSize)
		self._contentsFrame.Size = UDim2.new(1,-2,0,self._expandedSize)
		if self._expanded then
			self._invisFrame:TweenSize(UDim2.new(1,2,0,self._expandedSize), Enum.EasingDirection.In, Enum.EasingStyle.quad, 0.15, true)
		end
	else
		self._canvasSize = count*self._dropdownButtonHeight
		self._expandedSize = count*self._dropdownButtonHeight
		
		self._contentsFrame.CanvasSize = UDim2.new(1,-2,0,self._canvasSize)
		self._contentsFrame.Size = UDim2.new(1,-2,0,self._expandedSize)
		if self._expanded then
			self._invisFrame:TweenSize(UDim2.new(1,2,0,self._expandedSize), Enum.EasingDirection.In, Enum.EasingStyle.quad, 0.15, true)
		end
	end
	
end

return DropdownMenu