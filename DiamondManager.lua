local module = {}
local key="diamond"
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")
local DataStore2 = require(ServerScriptService.DataStore2)
DataStore2.Combine("DATA",key)
local WebSocket=require(game.ServerScriptService.SocketService.module.WebSocket)
local logs=require(game.ServerScriptService.DatastoreManager.LogManager)
local REDiamondUp:RemoteEvent=ReplicatedStorage:WaitForChild("REDiamondUp")
type DiamondBillType={
    date:DateTime,
    count:number,

}
type DiamondType={
    total: number,
    diamond_pay: number,
    bill: {}
}
function FormatDefault() 
    return {
        total=0,
        diamond_pay=0,

        bill={}
    }
end

function module:GetDiamondByPlayer(player : Player):DiamondType
    local diamond = DataStore2(key, player)
    local rs=diamond:Get(FormatDefault())
    if not rs.diamond_pay then
        rs.diamond_pay=0
        diamond:Set(rs)
    end
    return rs
end
function module:Reset(player):DiamondType
    local diamond = DataStore2(key, player)
    REDiamondUp:FireClient(player)
    return diamond:Set(FormatDefault())
end
function module:SetDiamond(player,new_data):DiamondType
    local diamond = DataStore2(key, player)
    REDiamondUp:FireClient(player)
    return diamond:Set(new_data)
end
function module:CostDiamond(player,cost)
    if tonumber(cost)==nil then
        return false
    end
    local cost=tonumber(cost)
    
    local diamond_data=module:GetDiamondByPlayer(player)
    local total=diamond_data.total+diamond_data.diamond_pay
    if total<cost then
        return false
    end
    if diamond_data.total>=cost then
        diamond_data.total=diamond_data.total-cost
    else
        diamond_data.diamond_pay=diamond_data.diamond_pay-(cost-diamond_data.total)
        diamond_data.total=0
    end

    
    local diamond = DataStore2(key, player)
    diamond:Set(diamond_data)
    REDiamondUp:FireClient(player)
    return true
end

function module:CheckCostDiamond(player,cost)
    if tonumber(cost)==nil then
        return false
    end
    local cost=tonumber(cost)
    local diamond_data=module:GetDiamondByPlayer(player)
    local total=diamond_data.total+diamond_data.diamond_pay
    if total<cost then
        return false
    end
    return true
end
function module:AddBill(player,data):DiamondType
    --
end
function module:AddDiamond(player, count,reason)
    if tonumber(count)==nil then
        return false
    end
    local count=tonumber(count)

    local data=module:GetDiamondByPlayer(player)
    data.total=data.total+count
    logs.warn(player,script,"add diamonds x"..count,data.total)
    if not reason then
        reason=""
    end
    if reason then
        if count>0 then

            WebSocket.emit("robux",player,"+"..count.." free diamonds. "..reason,{free=data.total,fee=data.diamond_pay},"FREE DIAMOND")
        elseif count<0 then

            WebSocket.emit("robux",player,count.." free diamonds. "..reason,{free=data.total,fee=data.diamond_pay},"FREE DIAMOND")
        end
    end
    
    REDiamondUp:FireClient(player)
    return module:SetDiamond(player,data)
end
function module:AddDiamondPay(player, count,reason)
    if tonumber(count)==nil then
        return false
    end
    local count=tonumber(count)
    local data=module:GetDiamondByPlayer(player)
    data.diamond_pay=data.diamond_pay+count
    if not reason then
        reason=""
    end
    logs.log("["..player.Name.."][ID:"..player.UserId.."] [ADD:"..count.." diamonds] "..reason)
    REDiamondUp:FireClient(player)
    if count>0 then

        WebSocket.emit("robux",player,"+"..count.." fee diamonds. "..reason,{free=data.total,fee=data.diamond_pay},"FEE DIAMOND")
    elseif count<0 then

        WebSocket.emit("robux",player,count.." fee diamonds. "..reason,{free=data.total,fee=data.diamond_pay},"FEE DIAMOND")
    end
    return module:SetDiamond(player,data)
end
function module:UseDiamond(player, count)
    local data=module:GetDiamondByPlayer(player)
    data.total=data.total-count
    REDiamondUp:FireClient(player)
    return module:SetDiamond(player,data)
end
return module