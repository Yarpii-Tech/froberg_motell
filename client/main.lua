local Keys = {
  ["ESC"] = 322, ["F1"] = 288, ["F2"] = 289, ["F3"] = 170, ["F5"] = 166, ["F6"] = 167, ["F7"] = 168, ["F8"] = 169, ["F9"] = 56, ["F10"] = 57,
  ["~"] = 243, ["1"] = 157, ["2"] = 158, ["3"] = 160, ["4"] = 164, ["5"] = 165, ["6"] = 159, ["7"] = 161, ["8"] = 162, ["9"] = 163, ["-"] = 84, ["="] = 83, ["BACKSPACE"] = 177,
  ["TAB"] = 37, ["Q"] = 44, ["W"] = 32, ["E"] = 38, ["R"] = 45, ["T"] = 245, ["Y"] = 246, ["U"] = 303, ["P"] = 199, ["["] = 39, ["]"] = 40, ["ENTER"] = 18,
  ["CAPS"] = 137, ["A"] = 34, ["S"] = 8, ["D"] = 9, ["F"] = 23, ["G"] = 47, ["H"] = 74, ["K"] = 311, ["L"] = 182,
  ["LEFTSHIFT"] = 21, ["Z"] = 20, ["X"] = 73, ["C"] = 26, ["V"] = 0, ["B"] = 29, ["N"] = 249, ["M"] = 244, [","] = 82, ["."] = 81,
  ["LEFTCTRL"] = 36, ["LEFTALT"] = 19, ["SPACE"] = 22, ["RIGHTCTRL"] = 70,
  ["HOME"] = 213, ["PAGEUP"] = 10, ["PAGEDOWN"] = 11, ["DELETE"] = 178,
  ["LEFT"] = 174, ["RIGHT"] = 175, ["TOP"] = 27, ["DOWN"] = 173,
  ["NENTER"] = 201, ["N4"] = 108, ["N5"] = 60, ["N6"] = 107, ["N+"] = 96, ["N-"] = 97, ["N7"] = 117, ["N8"] = 61, ["N9"] = 118
}

ESX                           = nil
local GUI                     = {}
GUI.Time                      = 0
local Ownedmotels         = {}
local Blips                   = {}
local Currentmotel         = nil
local CurrentmotelOwner    = nil
local Lastmotel           = nil
local LastPart                = nil
local HasAlreadyEnteredMarker = false
local CurrentAction           = nil
local CurrentActionMsg        = ''
local CurrentActionData       = {}
local FirstSpawn              = true
local HasChest                = false

function DrawSub(text, time)
  ClearPrints()
  SetTextEntry_2('STRING')
  AddTextComponentString(text)
  DrawSubtitleTimed(time, 1)
end

function CreateBlips()
  for i=1, #Config.motels, 1 do
    local motel = Config.motels[i]
    if motel.entering ~= nil then
      Blips[motel.name] = AddBlipForCoord(motel.entering.x, motel.entering.y, motel.entering.z)
      SetBlipSprite (Blips[motel.name], 369)
      SetBlipDisplay(Blips[motel.name], 4)
      SetBlipScale  (Blips[motel.name], 1.0)
      SetBlipAsShortRange(Blips[motel.name], true)
      BeginTextCommandSetBlipName("STRING")
      AddTextComponentString(_U('free_prop'))
      EndTextCommandSetBlipName(Blips[motel.name])
    end
  end
end

function Getmotels()
  return Config.motels
end

function Getmotel(name)
  for i=1, #Config.motels, 1 do
    if Config.motels[i].name == name then
      return Config.motels[i]
    end
  end
end

function GetGateway(motel)
  for i=1, #Config.motels, 1 do
    local motel2 = Config.motels[i]
    if motel2.isGateway and motel2.name == motel.gateway then
      return motel2
    end
  end
end

function GetGatewaymotels(motel)
  local motels = {}
  for i=1, #Config.motels, 1 do
    if Config.motels[i].gateway == motel.name then
      table.insert(motels, Config.motels[i])
    end
  end
  return motels
end

function Entermotel(name, owner)
  local motel       = Getmotel(name)
  local playerPed      = GetPlayerPed(-1)
  Currentmotel      = motel
  CurrentmotelOwner = owner
  for i=1, #Config.motels, 1 do
    if Config.motels[i].name ~= name then
      Config.motels[i].disabled = true
    end
  end
  TriggerServerEvent('froberg_motel:saveLastmotel', name)
  Citizen.CreateThread(function()
    DoScreenFadeOut(800)
    while not IsScreenFadedOut() do
      Citizen.Wait(0)
    end
    for i=1, #motel.ipls, 1 do
      RequestIpl(motel.ipls[i])
      while not IsIplActive(motel.ipls[i]) do
        Citizen.Wait(0)
      end
    end
    SetEntityCoords(playerPed, motel.inside.x,  motel.inside.y,  motel.inside.z)
    DoScreenFadeIn(800)
    DrawSub(motel.label, 5000)
  end)
end

function Exitmotel(name)
  local motel  = Getmotel(name)
  local playerPed = GetPlayerPed(-1)
  local outside   = nil
  Currentmotel = nil
  if motel.isSingle then
    outside = motel.outside
  else
    outside = GetGateway(motel).outside
  end
  TriggerServerEvent('froberg_motel:deleteLastmotel')
  Citizen.CreateThread(function()
    DoScreenFadeOut(800)
    while not IsScreenFadedOut() do
      Citizen.Wait(0)
    end
    SetEntityCoords(playerPed, outside.x,  outside.y,  outside.z)
    for i=1, #motel.ipls, 1 do
      RemoveIpl(motel.ipls[i])
    end
    for i=1, #Config.motels, 1 do
      Config.motels[i].disabled = false
    end
    DoScreenFadeIn(800)
  end)
end

function SetmotelOwned(name, owned)
  local motel     = Getmotel(name)
  local entering     = nil
  local enteringName = nil
  if motel.isSingle then
    entering     = motel.entering
    enteringName = motel.name
  else
    local gateway = GetGateway(motel)
    entering      = gateway.entering
    enteringName  = gateway.name
  end
  if owned then
    Ownedmotels[name] = true
    RemoveBlip(Blips[enteringName])
    Blips[enteringName] = AddBlipForCoord(entering.x,  entering.y,  entering.z)
    SetBlipSprite(Blips[enteringName], 357)
    SetBlipAsShortRange(Blips[enteringName], true)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString(_U('property'))
    EndTextCommandSetBlipName(Blips[enteringName])
  else
    Ownedmotels[name] = nil
    local found = false
    for k,v in pairs(Ownedmotels) do
      local _motel = Getmotel(k)
      local _gateway  = GetGateway(_motel)
      if _gateway ~= nil then
        if _gateway.name == enteringName then
          found = true
          break
        end
      end
    end
    if not found then
      RemoveBlip(Blips[enteringName])
      Blips[enteringName] = AddBlipForCoord(entering.x,  entering.y,  entering.z)
      SetBlipSprite(Blips[enteringName], 369)
      SetBlipAsShortRange(Blips[enteringName], true)
      BeginTextCommandSetBlipName("STRING")
      AddTextComponentString(_U('free_prop'))
      EndTextCommandSetBlipName(Blips[enteringName])
     end
  end
end

function motelIsOwned(motel)
  return Ownedmotels[motel.name] == true
end

function OpenmotelMenu(motel)
  local elements = {}
  if motelIsOwned(motel) then
    table.insert(elements, {label = _U('enter'), value = 'enter'})
    if not Config.EnablePlayerManagement then
      table.insert(elements, {label = _U('leave'), value = 'leave'})
    end
  else
    if not Config.EnablePlayerManagement then
      table.insert(elements, {label = _U('rent'),   value = 'rent'})
    end
    table.insert(elements, {label = _U('visit'), value = 'visit'})
  end

  ESX.UI.Menu.Open(
    'default', GetCurrentResourceName(), 'motel',
    {
      title    = 'motel Reception',
      align    = 'top-left',
      elements = elements,
    },
    function(data2, menu)
      menu.close()
      if data2.current.value == 'enter' then
        TriggerEvent('instance:create', 'motel', {motel = motel.name, owner = ESX.GetPlayerData().identifier})
      end
      if data2.current.value == 'leave' then
        TriggerServerEvent('froberg_motel:removeOwnedmotel', motel.name)
      end
      if data2.current.value == 'rent' then
        TriggerServerEvent('froberg_motel:rentmotel', motel.name)
      end
      if data2.current.value == 'visit' then
        TriggerEvent('instance:create', 'motel', {motel = motel.name, owner = ESX.GetPlayerData().identifier})
      end
    end,
    function(data, menu)
        menu.close()
        CurrentAction     = 'motel_menu'
        CurrentActionMsg  = _U('press_to_menu')
        CurrentActionData = {motel = motel}
    end
  )
end

function OpenGatewayMenu(motel)
  if Config.EnablePlayerManagement then
    OpenGatewayOwnedmotelsMenu(gatewaymotels)
  else
    ESX.UI.Menu.Open(
      'default', GetCurrentResourceName(), 'gateway',
      {
        title    = motel.name,
        align    = 'top-left',
        elements = {
          {label = _U('owned_properties'),    value = 'owned_motels'},
          {label = _U('available_properties'), value = 'available_motels'},
        }
      },
      function(data, menu)
        if data.current.value == 'owned_motels' then
          OpenGatewayOwnedmotelsMenu(motel)
        end
        if data.current.value == 'available_motels' then
          OpenGatewayAvailablemotelsMenu(motel)
        end
      end,
      function(data, menu)
        menu.close()
        CurrentAction     = 'gateway_menu'
        CurrentActionMsg  = _U('press_to_menu')
        CurrentActionData = {motel = motel}
      end
    )
  end
end

function OpenGatewayOwnedmotelsMenu(motel)
  local gatewaymotels = GetGatewaymotels(motel)
  local elements          = {}
  for i=1, #gatewaymotels, 1 do
    if motelIsOwned(gatewaymotels[i]) then
      table.insert(elements, {
        label = gatewaymotels[i].label,
        value = gatewaymotels[i].name
      })
    end
  end
  ESX.UI.Menu.Open(
    'default', GetCurrentResourceName(), 'gateway_owned_motels',
    {
      title    = motel.name .. ' - ' .. _U('owned_motels'),
      align    = 'top-left',
      elements = elements,
    },
    function(data, menu)
      menu.close()
      local elements = {
        {label = _U('enter'), value = 'enter'}
      }
      if not Config.EnablePlayerManagement then
        table.insert(elements, {label = _U('leave'), value = 'leave'})
      end
      ESX.UI.Menu.Open(
        'default', GetCurrentResourceName(), 'gateway_owned_motels_actions',
        {
          title    = data.current.label,
          align    = 'top-left',
          elements = elements,
        },
        function(data2, menu)
          menu.close()
          if data2.current.value == 'enter' then
            TriggerEvent('instance:create', 'motel', {motel = data.current.value, owner = ESX.GetPlayerData().identifier})
          end
          if data2.current.value == 'leave' then
            TriggerServerEvent('froberg_motel:removeOwnedmotel', data.current.value)
          end
        end,
        function(data, menu)
          menu.close()
        end
      )
    end,
    function(data, menu)
      menu.close()
    end
  )
end

function OpenGatewayAvailablemotelsMenu(motel)
  local gatewaymotels = GetGatewaymotels(motel)
  local elements          = {}
  for i=1, #gatewaymotels, 1 do
    if not motelIsOwned(gatewaymotels[i]) then
      table.insert(elements, {
        label = gatewaymotels[i].label .. ' SEK' .. gatewaymotels[i].price,
        value = gatewaymotels[i].name,
        price = gatewaymotels[i].price
      })
    end
  end
  ESX.UI.Menu.Open(
    'default', GetCurrentResourceName(), 'gateway_available_motels',
    {
      title    = motel.name.. ' - ' .. _U('available_motels'),
      align    = 'top-left',
      elements = elements,
    },
    function(data, menu)
      menu.close()
      ESX.UI.Menu.Open(
        'default', GetCurrentResourceName(), 'gateway_available_motels_actions',
        {
          title    = motel.name,
          align    = 'top-left',
          elements = {
            {label = _U('rent'),   value = 'rent'},
            {label = _U('visit'), value = 'visit'},
          },
        },
        function(data2, menu)
          menu.close()
          if data2.current.value == 'rent' then
            TriggerServerEvent('froberg_motel:rentmotel', data.current.value)
          end
          if data2.current.value == 'visit' then
            TriggerEvent('instance:create', 'motel', {motel = data.current.value, owner = ESX.GetPlayerData().identifier})
          end
        end,
        function(data, menu)
          menu.close()
        end
      )
    end,
    function(data, menu)
      menu.close()
    end
  )
end

function OpenRoomMenu(motel, owner)
  local entering = nil
  local elements = {}
  if motel.isSingle then
    entering = motel.entering
  else
    entering = GetGateway(motel).entering
  end
  table.insert(elements, {label = _U('invite_player'),  value = 'invite_player'})
  if CurrentmotelOwner == owner then
    table.insert(elements, {label = _U('player_clothes'), value = 'player_dressing'})
    table.insert(elements, {label = _U('remove_cloth'), value = 'remove_cloth'})
  end
  table.insert(elements, {label = _U('remove_object'),  value = 'room_inventory'})
  table.insert(elements, {label = _U('deposit_object'), value = 'player_inventory'})
  ESX.UI.Menu.CloseAll()
  ESX.UI.Menu.Open(
    'default', GetCurrentResourceName(), 'room',
    {
      title    = motel.label,
      align    = 'top-left',
      elements = elements,
    },
    function(data, menu)
      if data.current.value == 'invite_player' then
        local playersInArea = ESX.Game.GetPlayersInArea(entering, 10.0)
        local elements      = {}
        for i=1, #playersInArea, 1 do
          if playersInArea[i] ~= PlayerId() then
            table.insert(elements, {label = GetPlayerName(playersInArea[i]), value = playersInArea[i]})
          end
        end
        ESX.UI.Menu.Open(
          'default', GetCurrentResourceName(), 'room_invite',
          {
            title    = motel.label .. ' - ' .. _U('invite'),
            align    = 'top-left',
            elements = elements,
          },
          function(data, menu)
            TriggerEvent('instance:invite', 'motel', GetPlayerServerId(data.current.value), {motel = motel.name, owner = owner})
            ESX.ShowNotification(_U('you_invited', GetPlayerName(data.current.value)))
          end,
          function(data, menu)
            menu.close()
          end
        )
      end
      if data.current.value == 'player_dressing' then
        ESX.TriggerServerCallback('froberg_motel:getPlayerDressing', function(dressing)
          local elements = {}
          for i=1, #dressing, 1 do
            table.insert(elements, {label = dressing[i], value = i})
          end
          ESX.UI.Menu.Open(
            'default', GetCurrentResourceName(), 'player_dressing',
            {
              title    = motel.label .. ' - ' .. _U('player_clothes'),
              align    = 'top-left',
              elements = elements,
            },
            function(data, menu)
              TriggerEvent('skinchanger:getSkin', function(skin)
                ESX.TriggerServerCallback('froberg_motel:getPlayerOutfit', function(clothes)
                  TriggerEvent('skinchanger:loadClothes', skin, clothes)
                  TriggerEvent('esx_skin:setLastSkin', skin)
                  TriggerEvent('skinchanger:getSkin', function(skin)
                    TriggerServerEvent('esx_skin:save', skin)
                  end)
                end, data.current.value)
              end)
            end,
            function(data, menu)
              menu.close()
            end
          )
        end)
      end
      if data.current.value == 'remove_cloth' then
          ESX.TriggerServerCallback('froberg_motel:getPlayerDressing', function(dressing)
              local elements = {}
      
              for i=1, #dressing, 1 do
                  table.insert(elements, {label = dressing[i].label, value = i})
              end
              ESX.UI.Menu.Open(
              'default', GetCurrentResourceName(), 'remove_cloth',
              {
                title    = motel.label .. ' - ' .. _U('remove_cloth'),
                align    = 'top-left',
                elements = elements,
              },
              function(data, menu)
                  menu.close()
                  TriggerServerEvent('froberg_motel:removeOutfit', data.current.value)
                  ESX.ShowNotification(_U('removed_cloth'))
              end,
              function(data, menu)
                menu.close()
              end
            )
          end)
      end
      if data.current.value == 'room_inventory' then
        OpenRoomInventoryMenu(motel, owner)
      end
      if data.current.value == 'player_inventory' then
        OpenPlayerInventoryMenu(motel, owner)
      end
    end,
    function(data, menu)
      menu.close()
      CurrentAction     = 'room_menu'
      CurrentActionMsg  = _U('press_to_menu')
      CurrentActionData = {motel = motel, owner = owner}
    end
  )
end

function OpenRoomInventoryMenu(motel, owner)
  ESX.TriggerServerCallback('froberg_motel:getmotelInventory', function(inventory)
    local elements = {}
    table.insert(elements, {label = _U('dirty_money') .. inventory.blackMoney, type = 'item_account', value = 'black_money'})
    for i=1, #inventory.items, 1 do
      local item = inventory.items[i]
      if item.count > 0 then
        table.insert(elements, {label = item.label .. ' x' .. item.count, type = 'item_standard', value = item.name})
      end
    end
    for i=1, #inventory.weapons, 1 do
      local weapon = inventory.weapons[i]
      table.insert(elements, {label = ESX.GetWeaponLabel(weapon.name) .. ' [' .. weapon.ammo .. ']', type = 'item_weapon', value = weapon.name, ammo = weapon.ammo})
    end
    ESX.UI.Menu.Open(
      'default', GetCurrentResourceName(), 'room_inventory',
      {
        title    = motel.label .. ' - ' .. _U('inventory'),
        align    = 'top-left',
        elements = elements,
      },
      function(data, menu)
        if data.current.type == 'item_weapon' then
          menu.close()
          TriggerServerEvent('froberg_motel:getItem', owner, data.current.type, data.current.value, data.current.ammo)
          ESX.SetTimeout(300, function()
            OpenRoomInventoryMenu(motel, owner)
          end)
        else
          ESX.UI.Menu.Open(
            'dialog', GetCurrentResourceName(), 'get_item_count',
            {
              title = _U('amount'),
            },
            function(data2, menu)
              local quantity = tonumber(data2.value)
              if quantity == nil then
                ESX.ShowNotification(_U('amount_invalid'))
              else
                menu.close()
                TriggerServerEvent('froberg_motel:getItem', owner, data.current.type, data.current.value, quantity)
                ESX.SetTimeout(300, function()
                  OpenRoomInventoryMenu(motel, owner)
                end)
              end
            end,
            function(data2,menu)
              menu.close()
            end
          )
        end
      end,
      function(data, menu)
        menu.close()
      end
    )
  end, owner)
end

function OpenPlayerInventoryMenu(motel, owner)
  ESX.TriggerServerCallback('froberg_motel:getPlayerInventory', function(inventory)
    local elements = {}
    table.insert(elements, {label = _U('dirty_money') .. inventory.blackMoney, type = 'item_account', value = 'black_money'})
    for i=1, #inventory.items, 1 do
      local item = inventory.items[i]
      if item.count > 0 then
        table.insert(elements, {label = item.label .. ' x' .. item.count, type = 'item_standard', value = item.name})
      end
    end
    local playerPed  = GetPlayerPed(-1)
    local weaponList = ESX.GetWeaponList()
    for i=1, #weaponList, 1 do
      local weaponHash = GetHashKey(weaponList[i].name)
      if HasPedGotWeapon(playerPed,  weaponHash,  false) and weaponList[i].name ~= 'WEAPON_UNARMED' then
        local ammo = GetAmmoInPedWeapon(playerPed, weaponHash)
        table.insert(elements, {label = weaponList[i].label .. ' [' .. ammo .. ']', type = 'item_weapon', value = weaponList[i].name, ammo = ammo})
      end

    end
    ESX.UI.Menu.Open(
      'default', GetCurrentResourceName(), 'player_inventory',
      {
        title    = motel.label .. ' - ' .. _U('inventory'),
        align    = 'top-left',
        elements = elements,
      },
      function(data, menu)
        if data.current.type == 'item_weapon' then
          menu.close()
          TriggerServerEvent('froberg_motel:putItem', owner, data.current.type, data.current.value, data.current.ammo)
          ESX.SetTimeout(300, function()
            OpenPlayerInventoryMenu(motel, owner)
          end)
        else
          ESX.UI.Menu.Open(
            'dialog', GetCurrentResourceName(), 'put_item_count',
            {
              title = _U('amount'),
            },
            function(data2, menu)
              menu.close()
              TriggerServerEvent('froberg_motel:putItem', owner, data.current.type, data.current.value, tonumber(data2.value))
              ESX.SetTimeout(300, function()
                OpenPlayerInventoryMenu(motel, owner)
              end)
            end,
            function(data2,menu)
              menu.close()
            end
          )
        end
      end,
      function(data, menu)
        menu.close()
      end
    )
  end)
end

AddEventHandler('instance:loaded', function()
  TriggerEvent('instance:registerType', 'motel',
    function(instance)
      Entermotel(instance.data.motel, instance.data.owner)
    end,
    function(instance)
      Exitmotel(instance.data.motel)
    end
  )
end)

AddEventHandler('playerSpawned', function()
  if FirstSpawn then
    Citizen.CreateThread(function()
      while not ESX.IsPlayerLoaded() do
        Citizen.Wait(0)
      end
      ESX.TriggerServerCallback('froberg_motel:getLastmotel', function(motelName)
        if motelName ~= nil then
          TriggerEvent('instance:create', 'motel', {motel = motelName, owner = ESX.GetPlayerData().identifier})
        end
      end)

    end)
    FirstSpawn = false
  end
end)

RegisterNetEvent('esx:playerLoaded')
AddEventHandler('esx:playerLoaded', function(xPlayer)
  PlayerLoaded = true
end)

AddEventHandler('froberg_motel:getmotels', function(cb)
  cb(Getmotels())
end)

AddEventHandler('froberg_motel:getmotel', function(name, cb)
  cb(Getmotel(name))
end)

AddEventHandler('froberg_motel:getGateway', function(motel, cb)
  cb(GetGateway(motel))
end)

RegisterNetEvent('froberg_motel:setmotelOwned')
AddEventHandler('froberg_motel:setmotelOwned', function(name, owned)
  SetmotelOwned(name, owned)
end)

RegisterNetEvent('esx:playerLoaded')
AddEventHandler('esx:playerLoaded', function(xPlayer)
  ESX.TriggerServerCallback('froberg_motel:getOwnedmotels', function(ownedmotels)
    for i=1, #ownedmotels, 1 do
      SetmotelOwned(ownedmotels[i], true)
    end
  end)
end)

RegisterNetEvent('instance:onCreate')
AddEventHandler('instance:onCreate', function(instance)
  if instance.type == 'motel' then
    TriggerEvent('instance:enter', instance)
  end
end)

RegisterNetEvent('instance:onEnter')
AddEventHandler('instance:onEnter', function(instance)
  if instance.type == 'motel' then
    local motel = Getmotel(instance.data.motel)
    local isHost   = GetPlayerFromServerId(instance.host) == PlayerId()
    local isOwned  = false
    if motelIsOwned(motel) == true then
      isOwned = true
    end
    if(isOwned or not isHost) then
      HasChest = true
    else
      HasChest = false
    end
  end
end)

RegisterNetEvent('instance:onPlayerLeft')
AddEventHandler('instance:onPlayerLeft', function(instance, player)
  if player == instance.host then
    TriggerEvent('instance:leave')
  end
end)

AddEventHandler('froberg_motel:hasEnteredMarker', function(name, part)
  local motel = Getmotel(name)
  if part == 'entering' then
    if motel.isSingle then
      CurrentAction     = 'motel_menu'
      CurrentActionMsg  = _U('press_to_menu')
      CurrentActionData = {motel = motel}
    else
      CurrentAction     = 'gateway_menu'
      CurrentActionMsg  = _U('press_to_menu')
      CurrentActionData = {motel = motel}
    end
  end
  if part == 'exit' then
    CurrentAction     = 'room_exit'
    CurrentActionMsg  = _U('press_to_exit')
    CurrentActionData = {motelName = name}
  end
  if part == 'roomMenu' then
    CurrentAction     = 'room_menu'
    CurrentActionMsg  = _U('press_to_menu')
    CurrentActionData = {motel = motel, owner = CurrentmotelOwner}
  end

end)

AddEventHandler('froberg_motel:hasExitedMarker', function(name, part)
  ESX.UI.Menu.CloseAll()
  CurrentAction = nil
end)

Citizen.CreateThread(function()
  while ESX == nil do
    TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
    Citizen.Wait(0)
  end
  ESX.TriggerServerCallback('froberg_motel:getmotels', function(motels)
    Config.motels = motels
    CreateBlips()
  end)
end)

Citizen.CreateThread(function()
  while true do
    Wait(0)
    local coords = GetEntityCoords(GetPlayerPed(-1))
    for i=1, #Config.motels, 1 do
      local motel = Config.motels[i]
      local isHost   = false
      if(motel.entering ~= nil and not motel.disabled and GetDistanceBetweenCoords(coords, motel.entering.x, motel.entering.y, motel.entering.z, true) < Config.DrawDistance) then
        DrawMarker(Config.MarkerType, motel.entering.x, motel.entering.y, motel.entering.z, 0.0, 0.0, 0.0, 0, 0.0, 0.0, Config.MarkerSize.x, Config.MarkerSize.y, Config.MarkerSize.z, Config.MarkerColor.r, Config.MarkerColor.g, Config.MarkerColor.b, 100, false, true, 2, false, false, false, false)
      end
      if(motel.exit ~= nil and not motel.disabled and GetDistanceBetweenCoords(coords, motel.exit.x, motel.exit.y, motel.exit.z, true) < Config.DrawDistance) then
        DrawMarker(Config.MarkerType, motel.exit.x, motel.exit.y, motel.exit.z, 0.0, 0.0, 0.0, 0, 0.0, 0.0, Config.MarkerSize.x, Config.MarkerSize.y, Config.MarkerSize.z, Config.MarkerColor.r, Config.MarkerColor.g, Config.MarkerColor.b, 100, false, true, 2, false, false, false, false)
      end
      if(motel.roomMenu ~= nil and HasChest and not motel.disabled and GetDistanceBetweenCoords(coords, motel.roomMenu.x, motel.roomMenu.y, motel.roomMenu.z, true) < Config.DrawDistance) then
        DrawMarker(Config.MarkerType, motel.roomMenu.x, motel.roomMenu.y, motel.roomMenu.z, 0.0, 0.0, 0.0, 0, 0.0, 0.0, Config.MarkerSize.x, Config.MarkerSize.y, Config.MarkerSize.z, Config.RoomMenuMarkerColor.r, Config.RoomMenuMarkerColor.g, Config.RoomMenuMarkerColor.b, 100, false, true, 2, false, false, false, false)
      end
    end
  end
end)

Citizen.CreateThread(function()
  while true do
    Wait(0)
    local coords          = GetEntityCoords(GetPlayerPed(-1))
    local isInMarker      = false
    local currentmotel = nil
    local currentPart     = nil
    for i=1, #Config.motels, 1 do
      local motel = Config.motels[i]
      if(motel.entering ~= nil and not motel.disabled and GetDistanceBetweenCoords(coords, motel.entering.x, motel.entering.y, motel.entering.z, true) < Config.MarkerSize.x) then
        isInMarker      = true
        currentmotel = motel.name
        currentPart     = 'entering'
      end
      if(motel.exit ~= nil and not motel.disabled and GetDistanceBetweenCoords(coords, motel.exit.x, motel.exit.y, motel.exit.z, true) < Config.MarkerSize.x) then
        isInMarker      = true
        currentmotel = motel.name
        currentPart     = 'exit'
      end
      if(motel.inside ~= nil and not motel.disabled and GetDistanceBetweenCoords(coords, motel.inside.x, motel.inside.y, motel.inside.z, true) < Config.MarkerSize.x) then
        isInMarker      = true
        currentmotel = motel.name
        currentPart     = 'inside'
      end
      if(motel.outside ~= nil and not motel.disabled and GetDistanceBetweenCoords(coords, motel.outside.x, motel.outside.y, motel.outside.z, true) < Config.MarkerSize.x) then
        isInMarker      = true
        currentmotel = motel.name
        currentPart     = 'outside'
      end
      if(motel.roomMenu ~= nil and HasChest and not motel.disabled and GetDistanceBetweenCoords(coords, motel.roomMenu.x, motel.roomMenu.y, motel.roomMenu.z, true) < Config.MarkerSize.x) then
        isInMarker      = true
        currentmotel = motel.name
        currentPart     = 'roomMenu'
      end
    end
    if isInMarker and not HasAlreadyEnteredMarker or (isInMarker and (Lastmotel ~= currentmotel or LastPart ~= currentPart) ) then
      HasAlreadyEnteredMarker = true
      Lastmotel            = currentmotel
      LastPart                = currentPart
      TriggerEvent('froberg_motel:hasEnteredMarker', currentmotel, currentPart)
    end
    if not isInMarker and HasAlreadyEnteredMarker then
      HasAlreadyEnteredMarker = false
      TriggerEvent('froberg_motel:hasExitedMarker', Lastmotel, LastPart)
    end
  end
end)

Citizen.CreateThread(function()
  while true do
    Citizen.Wait(0)
    if CurrentAction ~= nil then
      SetTextComponentFormat('STRING')
      AddTextComponentString(CurrentActionMsg)
      DisplayHelpTextFromStringLabel(0, 0, 1, -1)
      if IsControlPressed(0,  Keys['E']) and (GetGameTimer() - GUI.Time) > 300 then
        if CurrentAction == 'motel_menu' then
          OpenmotelMenu(CurrentActionData.motel)
        end
        if CurrentAction == 'gateway_menu' then
          if Config.EnablePlayerManagement then
            OpenGatewayOwnedmotelsMenu(CurrentActionData.motel)
          else
            OpenGatewayMenu(CurrentActionData.motel)
          end
        end
        if CurrentAction == 'room_menu' then
          OpenRoomMenu(CurrentActionData.motel, CurrentActionData.owner)
        end
        if CurrentAction == 'room_exit' then
          TriggerEvent('instance:leave')
        end
        CurrentAction = nil
        GUI.Time      = GetGameTimer()
      end
    end
  end
end)
