script.Parent.Enabled=false

local player=game.Players.LocalPlayer
local gui=script.Parent
local BEAvatarConfig:RemoteFunction=game.ReplicatedStorage:WaitForChild("AvatarConfig")
local BEAvatarManager:RemoteFunction=game.ReplicatedStorage:WaitForChild("AvatarManager")
local characterManager = require(game:GetService("StarterPlayer").StarterPlayerScripts.MainUI.Character.LocalCharacterManager)
local config=BEAvatarConfig:InvokeServer()
local sidebar = player.PlayerGui:WaitForChild("SideBar").Frame
local clonepart=gui.Root.ScalableFrame.Prefab.avatarBg
local btn_place=gui.Root.ScalableFrame.ScrollingFrame
local name_avatar=gui.Root.ScalableFrame.mainFrame.reviewFrame.charName
local REAvatarUp:RemoteEvent = game.ReplicatedStorage:WaitForChild("REAvatarUp")
local reset_char=false
local RFItemManager:RemoteFunction=game.ReplicatedStorage:WaitForChild("RFItemManager")
local clickAvatar:RemoteFunction=game.ReplicatedStorage:WaitForChild("ClickAvatar")
local thumbSize = Enum.ThumbnailSize.Size48x48
local thumbType = Enum.ThumbnailType.HeadShot
local content = game.Players:GetUserThumbnailAsync(game.Players.LocalPlayer.UserId, thumbType, thumbSize)
local isChar=false
local idChar
local CharName="OwnAvatar"
local myDesignEvent = game:GetService("ReplicatedStorage"):WaitForChild("MyDesignEvent")
local new_char={}


game.ReplicatedStorage.RENewCharacter.OnClientEvent:Connect(function(id)
	new_char[tostring(id)]=true
end)
function weldAttachments(attach1, attach2)
	local weld = Instance.new("Weld")
	weld.Part0 = attach1.Parent
	weld.Part1 = attach2.Parent
	weld.C0 = attach1.CFrame
	weld.C1 = attach2.CFrame
	weld.Parent = attach1.Parent
	return weld
end

local function buildWeld(weldName, parent, part0, part1, c0, c1)
	local weld = Instance.new("Weld")
	weld.Name = weldName
	weld.Part0 = part0
	weld.Part1 = part1
	weld.C0 = c0
	weld.C1 = c1
	weld.Parent = parent
	return weld
end

local function findFirstMatchingAttachment(model, name)
	for _, child in pairs(model:GetChildren()) do
		if child:IsA("Attachment") and child.Name == name then
			return child
		elseif not child:IsA("Accoutrement") and not child:IsA("Tool") then -- Don't look in hats or tools in the character
			local foundAttachment = findFirstMatchingAttachment(child, name)
			if foundAttachment then
				return foundAttachment
			end
		end
	end
end

function addAccoutrement(character, accoutrement)  
	accoutrement.Parent = character
	local handle = accoutrement:FindFirstChild("Handle")
	if handle then
		local accoutrementAttachment = handle:FindFirstChildOfClass("Attachment")
		if accoutrementAttachment then
			local characterAttachment = findFirstMatchingAttachment(character, accoutrementAttachment.Name)
			if characterAttachment then
				weldAttachments(characterAttachment, accoutrementAttachment)
			end
		else
			local head = character:FindFirstChild("Head")
			if head then
				local attachmentCFrame = CFrame.new(0, 0.5, 0)
				local hatCFrame = accoutrement.AttachmentPoint
				buildWeld("HeadWeld", head, head, handle, attachmentCFrame, hatCFrame)
			end
		end
	end
end
function isEquip(name)
	local player=game.Players.LocalPlayer
	for k,v in pairs(player.Character:GetChildren()) do
		if v:IsA("Accessory") and v.Name==name then
			return true
		end
	end
	return false
end
function isPreviewEquip(name)
	local player=gui.Root.ScalableFrame.mainFrame.reviewFrame.avatarBg.SelectedEmoteFrame.ViewportFrame.WorldModel:WaitForChild(player.Name)

	for k,v in pairs(player:GetChildren()) do
		if v:IsA("Accessory") and v.Name==name then
			return true
		end
	end
	return false
end

function getCharID(input)
	local strInput = tostring(input)
	local length = #strInput

	if length >= 4 then
		return tonumber(string.sub(strInput, length - 3, length))
	else
		return tonumber(strInput)
	end
end
script.Parent.Changed:Connect(function(pro)
	if (gui.Enabled and pro=="Enabled") then

		local char=game.Players.LocalPlayer.Character
		if char:GetAttribute("id") then
			game.ReplicatedStorage:WaitForChild("BEChangeModel"):Fire(char:GetAttribute("id"))
		else
			game.ReplicatedStorage:WaitForChild("BEChangeModel"):Fire(game.Players.LocalPlayer.UserId)

		end
	end
end)

function create(config)
	local player_char=game.Players.LocalPlayer.Character
	if player_char:GetAttribute("name") then
		name_avatar.Text= player_char:GetAttribute("name")
		name_avatar.charName.Text= player_char:GetAttribute("name")
	else
		name_avatar.Text=game.Players.LocalPlayer.Name
		name_avatar.charName.Text=game.Players.LocalPlayer.Name
	end
	local CharData=RFItemManager:InvokeServer(3)
	local function compare(a, b)
		return a["id"] < b["id"]
	end
	table.sort(CharData, compare)
	local new_btn=clonepart:Clone()

	new_btn.avatar.Image=content
	new_btn.Parent=btn_place
	new_btn.Visible=true
	new_btn.check.Visible= false
	new_btn.new.LocalScript.Enabled=false
	new_btn.new.Visible=false
	new_btn.check.Visible=player_char:GetAttribute("id")==nil
	new_btn.EquipBtn.MouseButton1Down:Connect(function() 
		myDesignEvent:FireServer("Menu:Avatar:Click:OwnAvatar")
		CharName="OwnAvatar"
		for k,v in pairs(btn_place:GetChildren())do
			if v:IsA("ImageLabel") then
				v.check.Visible=false
			end
		end
		name_avatar.Text=game.Players.LocalPlayer.Name
		name_avatar.charName.Text=game.Players.LocalPlayer.Name
		new_btn.check.Visible=true

		isChar=false
		reset_char=true
		idChar=game.Players.LocalPlayer.UserId
        game.ReplicatedStorage:WaitForChild("BEChangeModel"):Fire(game.Players.LocalPlayer.UserId,true)
	end)
	for k,v in pairs(CharData) do
		local new_btn=clonepart:Clone()
		local characterconfig = characterManager.GetCharacterById(v.id)
		new_btn.avatar.Image = characterconfig.image
		new_btn:SetAttribute("id",v.id)
		new_btn:SetAttribute("char",true)
		new_btn.new.LocalScript.Enabled=false
        new_btn.new.Visible= _G.NewCharacter[tostring(v.id)]==true
		if new_char[tostring(v.id)]==true then
			new_btn.new.LocalScript.Enabled=true
			new_btn.new.Visible= true
		end
		-- new_btn.avatar.Image="rbxassetid://"..v.img
		new_btn.Parent=btn_place
		new_btn.Visible=true

		new_btn.check.Visible=(getCharID(game.Players.LocalPlayer.Character:GetAttribute("id"))==getCharID(new_btn:GetAttribute("id")))
		new_btn.EquipBtn.MouseButton1Down:Connect(function() 
			myDesignEvent:FireServer("Menu:Avatar:Click:"..characterconfig.name)
			CharName=characterconfig.name
            _G.NewCharacter[tostring(v.id)]=false
			for k,v in pairs(btn_place:GetChildren())do
				if v:IsA("ImageLabel") then
					v.check.Visible=false
				end
			end
			new_btn.check.Visible= true
			isChar=true
			idChar=v.id
			new_char[tostring(v.id)]=nil
			new_btn.new.LocalScript.Enabled=false
			new_btn.new.Visible= false
			game.ReplicatedStorage:WaitForChild("BEChangeModel"):Fire(v.id)
		end)
	end
	for k,v in pairs(config) do
		local new_btn=clonepart:Clone()
		new_btn.Name="accessory"
		new_btn:SetAttribute("id",v.id)

		new_btn.avatar.Image=v.img
		new_btn.Parent=btn_place
		new_btn.Visible=true
		new_btn.check.Visible= isEquip(v.accessory.Name)
		if not v.is_new then
			new_btn.new.LocalScript.Enabled=false
			new_btn.new.Visible=false    
		else
			new_btn.new.LocalScript.Enabled=true
			new_btn.new.Visible=true
		end
		new_btn.EquipBtn.MouseButton1Down:Connect(function() 
			if not isChar then

				clickAvatar:InvokeServer(v.id)

				new_btn.new.LocalScript.Enabled=false
				new_btn.new.Visible=false   
				new_btn.check.Visible=not isPreviewEquip(v.accessory.Name)
				local preview_char=gui.Root.ScalableFrame.mainFrame.reviewFrame.avatarBg.SelectedEmoteFrame.ViewportFrame.WorldModel:WaitForChild(player.Name)
				local character=preview_char
				local accessoryData=v.accessory
				local rm=false
				for _k,_v:Accessory in pairs(character:GetDescendants()) do
					if _v:IsA("Accessory") then
						if _v.AccessoryType==v.type   then
							_v:Destroy()
						end
						if _v.Name==accessoryData.Name then
							_v:Destroy()
							rm=true
						end
					end
				end
				if not rm then
					local shortnew=accessoryData:Clone()
					addAccoutrement(character,shortnew)
				end
			end
		end)
	end
end
create(config)
REAvatarUp.OnClientEvent:Connect(function(...)
	for k,v in pairs(btn_place:GetChildren()) do
		if v:IsA("ImageLabel") then
			v:Remove()
		end
	end
	local config=BEAvatarConfig:InvokeServer()
	create(config)
end)
gui.Root.ScalableFrame.backBtn.MouseButton1Down:Connect(function()
	gui.Enabled=false
	sidebar.Visible = true
end)
local btnEquip=gui.Root.ScalableFrame.okBtn
local EquipAvatar:RemoteFunction=game.ReplicatedStorage:WaitForChild("EquipAvatar")
btnEquip.MouseButton1Down:Connect(function()
	myDesignEvent:FireServer("Menu:Avatar:ChangeAvatar:"..CharName)
	if isChar then
		if idChar then
			game:GetService("ReplicatedStorage").modelswapevent:FireServer(idChar)
            game.Players.LocalPlayer.PlayerGui.PlayVideo.Enabled=true
		end
	else

		local preview_char=gui.Root.ScalableFrame.mainFrame.reviewFrame.avatarBg.SelectedEmoteFrame.ViewportFrame.WorldModel:WaitForChild(player.Name)
		local rs={}
		for _k,_v:Accessory in pairs(preview_char:GetDescendants()) do
			if _v:IsA("Accessory") and _v:GetAttribute("canUse") then
				table.insert(rs,_v.Name)
			end
		end

        EquipAvatar:InvokeServer({list=rs,is_reset=reset_char})
        game.Players.LocalPlayer.PlayerGui.PlayVideo.Enabled=true
		if reset_char then
			reset_char=false
		end
	end
	gui.Enabled=false
end)
gui.Changed:Connect(function(name)
	if name=="Enabled" and gui.Enabled then
		for k,v in pairs(btn_place:GetChildren()) do
			if v:IsA("ImageLabel") then
				v:Remove()
			end
		end
		local config=BEAvatarConfig:InvokeServer()
		create(config)
	end
end)

local BELoading:BindableEvent=game.ReplicatedStorage:WaitForChild("BELoading")
BELoading.Event:Connect(function()
	local config_current=BEAvatarManager:InvokeServer({getCurrent=true})
	local list_id={}
	for k,v in pairs(config_current) do
		if v.isChar then
			game:GetService("ReplicatedStorage").modelswapevent:FireServer(v.id)
			return
		else
			table.insert(list_id,v.accessory.Name)
		end
	end
	EquipAvatar:InvokeServer({list=list_id,is_reset=reset_char})
end)