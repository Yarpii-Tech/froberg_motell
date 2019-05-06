ESX = nil

TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)

function Getmotel(name)
  for i=1, #Config.motels, 1 do
    if Config.motels[i].name == name then
      return Config.motels[i]
    end
  end
end

function SetmotelOwned(name, price, rented, owner)
  MySQL.Async.execute(
    'INSERT INTO owned_motel (name, price, rented, owner) VALUES (@name, @price, @rented, @owner)',
    {
      ['@name']   = name,
      ['@price']  = price,
      ['@rented'] = (rented and 1 or 0),
      ['@owner']  = owner
    },
    function(rowsChanged)
      local xPlayers = ESX.GetPlayers()
      for i=1, #xPlayers, 1 do
        local xPlayer = ESX.GetPlayerFromId(xPlayers[i])
        if xPlayer.identifier == owner then
          TriggerClientEvent('froberg_motel:setmotelOwned', xPlayer.source, name, true)
          if rented then
              TriggerClientEvent("pNotify:SendNotification",-1, {text = 'Du <font color="aqua">hyrde</font> ett motel rum för ' .. price .. '<font color="lime">SEK</font>/dygnet', type = "error", timeout = 5000, layout = "bottomCenter"})
          else
            TriggerClientEvent('esx:showNotification', xPlayer.source, _U('purchased_for') .. price)
          end
          break
        end
      end
    end
  )
end

function RemoveOwnedmotel(name, owner)
  MySQL.Async.execute(
    'DELETE FROM owned_motel WHERE name = @name AND owner = @owner',
    {
      ['@name']  = name,
      ['@owner'] = owner
    },
    function(rowsChanged)
      local xPlayers = ESX.GetPlayers()
      for i=1, #xPlayers, 1 do
        local xPlayer = ESX.GetPlayerFromId(xPlayers[i])
        if xPlayer.identifier == owner then
          TriggerClientEvent('froberg_motel:setmotelOwned', xPlayer.source, name, false)
          TriggerClientEvent('esx:showNotification', xPlayer.source, _U('made_property'))
          break
        end
      end
    end
  )
end

AddEventHandler('onMySQLReady', function ()
  MySQL.Async.fetchAll('SELECT * FROM motel', {}, function(motels)
    for i=1, #motels, 1 do
      local entering  = nil
      local exit      = nil
      local inside    = nil
      local outside   = nil
      local isSingle  = nil
      local isRoom    = nil
      local isGateway = nil
      local roomMenu  = nil
      if motels[i].entering ~= nil then
        entering = json.decode(motels[i].entering)
      end
      if motels[i].exit ~= nil then
        exit = json.decode(motels[i].exit)
      end
      if motels[i].inside ~= nil then
        inside = json.decode(motels[i].inside)
      end
      if motels[i].outside ~= nil then
        outside = json.decode(motels[i].outside)
      end
      if motels[i].is_single == 0 then
        isSingle = false
      else
        isSingle = true
      end
      if motels[i].is_room == 0 then
        isRoom = false
      else
        isRoom = true
      end
      if motels[i].is_gateway == 0 then
        isGateway = false
      else
        isGateway = true
      end
      if motels[i].room_menu ~= nil then
        roomMenu = json.decode(motels[i].room_menu)
      end
      table.insert(Config.motels, {
        name      = motels[i].name,
        label     = motels[i].label,
        entering  = entering,
        exit      = exit,
        inside    = inside,
        outside   = outside,
        ipls      = json.decode(motels[i].ipls),
        gateway   = motels[i].gateway,
        isSingle  = isSingle,
        isRoom    = isRoom,
        isGateway = isGateway,
        roomMenu  = roomMenu,
        price     = motels[i].price
      })
    end
  end)
end)

AddEventHandler('froberg_ownedmotel:getOwnedmotels', function(cb)
  MySQL.Async.fetchAll(
    'SELECT * FROM owned_motel',
    {},
    function(result)
      local motels = {}
      for i=1, #result, 1 do
        table.insert(motels, {
          id     = result[i].id,
          name   = result[i].name,
          price  = result[i].price,
          rented = (result[i].rented == 1 and true or false),
          owner  = result[i].owner,
        })
      end
      cb(motels)
    end
  )
end)

AddEventHandler('froberg_motel:setmotelOwned', function(name, price, rented, owner)
  SetmotelOwned(name, price, rented, owner)
end)

AddEventHandler('froberg_motel:removeOwnedmotel', function(name, owner)
  RemoveOwnedmotel(name, owner)
end)

RegisterServerEvent('froberg_motel:rentmotel')
AddEventHandler('froberg_motel:rentmotel', function(motelName)
  local xPlayer  = ESX.GetPlayerFromId(source)
  local motel = Getmotel(motelName)
  SetmotelOwned(motelName, motel.price / 200, true, xPlayer.identifier)
end)

RegisterServerEvent('froberg_motel:buymotel')
AddEventHandler('froberg_motel:buymotel', function(motelName)
  local xPlayer  = ESX.GetPlayerFromId(source)
  local motel = Getmotel(motelName)
  if motel.price <= xPlayer.get('money') then
    xPlayer.removeMoney(motel.price)
    SetmotelOwned(motelName, motel.price, false, xPlayer.identifier)
  else
    TriggerClientEvent('esx:showNotification', source, _U('not_enough'))
  end
end)

RegisterServerEvent('froberg_motel:removeOwnedmotel')
AddEventHandler('froberg_motel:removeOwnedmotel', function(motelName)
  local xPlayer = ESX.GetPlayerFromId(source)
  RemoveOwnedmotel(motelName, xPlayer.identifier)
end)

AddEventHandler('froberg_motel:removeOwnedmotelIdentifier', function(motelName, identifier)
  RemoveOwnedmotel(motelName, identifier)
end)

RegisterServerEvent('froberg_motel:saveLastmotel')
AddEventHandler('froberg_motel:saveLastmotel', function(motel)
  local xPlayer = ESX.GetPlayerFromId(source)
  MySQL.Async.execute(
    'UPDATE users SET last_motel = @last_motel WHERE identifier = @identifier',
    {
      ['@last_motel'] = motel,
      ['@identifier']    = xPlayer.identifier
    }
  )
end)

RegisterServerEvent('froberg_motel:deleteLastmotel')
AddEventHandler('froberg_motel:deleteLastmotel', function()
  local xPlayer = ESX.GetPlayerFromId(source)
  MySQL.Async.execute(
    'UPDATE users SET last_motel = NULL WHERE identifier = @identifier',
    {
      ['@identifier']    = xPlayer.identifier
    }
  )
end)

RegisterServerEvent('froberg_motel:getItem')
AddEventHandler('froberg_motel:getItem', function(owner, type, item, count)
  local _source      = source
  local xPlayer      = ESX.GetPlayerFromId(_source)
  local xPlayerOwner = ESX.GetPlayerFromIdentifier(owner)
  if type == 'item_standard' then
    local sourceItem = xPlayer.getInventoryItem(item)
    TriggerEvent('esx_addoninventory:getInventory', 'motel', xPlayerOwner.identifier, function(inventory)
      local inventoryItem = inventory.getItem(item)
      if count > 0 and inventoryItem.count >= count then
        if sourceItem.limit ~= -1 and (sourceItem.count + count) > sourceItem.limit then
          TriggerClientEvent('esx:showNotification', _source, _U('player_cannot_hold'))
        else
          inventory.removeItem(item, count)
          xPlayer.addInventoryItem(item, count)
          TriggerClientEvent('esx:showNotification', _source, _U('have_withdrawn', count, inventoryItem.label))
        end
      else
        TriggerClientEvent('esx:showNotification', _source, _U('not_enough_in_property'))
      end
    end)
  end
  if type == 'item_account' then
    TriggerEvent('esx_addonaccount:getAccount', 'motel_' .. item, xPlayerOwner.identifier, function(account)
      local roomAccountMoney = account.money
      if roomAccountMoney >= count then
        account.removeMoney(count)
        xPlayer.addAccountMoney(item, count)
      else
        TriggerClientEvent('esx:showNotification', _source, _U('amount_invalid'))
      end
    end)
  end

  if type == 'item_weapon' then
    TriggerEvent('esx_datastore:getDataStore', 'motel', xPlayerOwner.identifier, function(store)
      local storeWeapons = store.get('weapons')
      if storeWeapons == nil then
        storeWeapons = {}
      end
      local weaponName   = nil
      local ammo         = nil
      for i=1, #storeWeapons, 1 do
        if storeWeapons[i].name == item then
          weaponName = storeWeapons[i].name
          ammo       = storeWeapons[i].ammo
          table.remove(storeWeapons, i)
          break
        end
      end
      store.set('weapons', storeWeapons)
      xPlayer.addWeapon(weaponName, ammo)
    end)
  end
end)

RegisterServerEvent('froberg_motel:putItem')
AddEventHandler('froberg_motel:putItem', function(owner, type, item, count)
  local _source      = source
  local xPlayer      = ESX.GetPlayerFromId(_source)
  local xPlayerOwner = ESX.GetPlayerFromIdentifier(owner)
  if type == 'item_standard' then
    local playerItemCount = xPlayer.getInventoryItem(item).count
    if playerItemCount >= count then
      TriggerEvent('esx_addoninventory:getInventory', 'motel', xPlayerOwner.identifier, function(inventory)
        xPlayer.removeInventoryItem(item, count)
        inventory.addItem(item, count)
        TriggerClientEvent('esx:showNotification', _source, _U('have_deposited', count, inventory.getItem(item).label))
      end)
    else
      TriggerClientEvent('esx:showNotification', _source, _U('invalid_quantity'))
    end
  end
  if type == 'item_account' then
    local playerAccountMoney = xPlayer.getAccount(item).money
    if playerAccountMoney >= count then
      xPlayer.removeAccountMoney(item, count)
      TriggerEvent('esx_addonaccount:getAccount', 'motel_' .. item, xPlayerOwner.identifier, function(account)
        account.addMoney(count)
      end)
    else
      TriggerClientEvent('esx:showNotification', _source, _U('amount_invalid'))
    end
  end
  if type == 'item_weapon' then
    TriggerEvent('esx_datastore:getDataStore', 'motel', xPlayerOwner.identifier, function(store)
      local storeWeapons = store.get('weapons')
      if storeWeapons == nil then
        storeWeapons = {}
      end
      table.insert(storeWeapons, {
        name = item,
        ammo = count
      })
      store.set('weapons', storeWeapons)
      xPlayer.removeWeapon(item)
    end)
  end
end)

ESX.RegisterServerCallback('froberg_motel:getmotels', function(source, cb)
  cb(Config.motels)
end)

ESX.RegisterServerCallback('froberg_motel:getOwnedmotels', function(source, cb)
  local xPlayer = ESX.GetPlayerFromId(source)
  MySQL.Async.fetchAll(
    'SELECT * FROM owned_motel WHERE owner = @owner',
    {
      ['@owner'] = xPlayer.identifier
    },
    function(ownedmotels)
      local motels = {}
      for i=1, #ownedmotels, 1 do
        table.insert(motels, ownedmotels[i].name)
      end
      cb(motels)
    end
  )
end)

ESX.RegisterServerCallback('froberg_motel:getLastmotel', function(source, cb)
  local xPlayer = ESX.GetPlayerFromId(source)
  MySQL.Async.fetchAll(
    'SELECT * FROM users WHERE identifier = @identifier',
    {
      ['@identifier'] = xPlayer.identifier
    },
    function(users)
      cb(users[1].last_motel)
    end
  )
end)

ESX.RegisterServerCallback('froberg_motel:getmotelInventory', function(source, cb, owner)
  local xPlayer    = ESX.GetPlayerFromIdentifier(owner)
  local blackMoney = 0
  local items      = {}
  local weapons    = {}
  TriggerEvent('esx_addonaccount:getAccount', 'motel_black_money', xPlayer.identifier, function(account)
    blackMoney = account.money
  end)
  TriggerEvent('esx_addoninventory:getInventory', 'motel', xPlayer.identifier, function(inventory)
    items = inventory.items
  end)
  TriggerEvent('esx_datastore:getDataStore', 'motel', xPlayer.identifier, function(store)
    local storeWeapons = store.get('weapons')
    if storeWeapons ~= nil then
      weapons = storeWeapons
    end
  end)
  cb({
    blackMoney = blackMoney,
    items      = items,
    weapons    = weapons
  })
end)

ESX.RegisterServerCallback('froberg_motel:getPlayerInventory', function(source, cb)
  local xPlayer    = ESX.GetPlayerFromId(source)
  local blackMoney = xPlayer.getAccount('black_money').money
  local items      = xPlayer.inventory
  cb({
    blackMoney = blackMoney,
    items      = items
  })
end)

ESX.RegisterServerCallback('froberg_motel:getPlayerDressing', function(source, cb)
  local xPlayer  = ESX.GetPlayerFromId(source)
  TriggerEvent('esx_datastore:getDataStore', 'motel', xPlayer.identifier, function(store)
    local count    = store.count('dressing')
    local labels   = {}
    for i=1, count, 1 do
      local entry = store.get('dressing', i)
      table.insert(labels, entry.label)
    end
    cb(labels)
  end)
end)

ESX.RegisterServerCallback('froberg_motel:getPlayerOutfit', function(source, cb, num)
  local xPlayer  = ESX.GetPlayerFromId(source)
  TriggerEvent('esx_datastore:getDataStore', 'motel', xPlayer.identifier, function(store)
    local outfit = store.get('dressing', num)
    cb(outfit.skin)
  end)
end)

RegisterServerEvent('froberg_motel:removeOutfit')
AddEventHandler('froberg_motel:removeOutfit', function(label)
    local xPlayer = ESX.GetPlayerFromId(source)
    TriggerEvent('esx_datastore:getDataStore', 'motel', xPlayer.identifier, function(store)
        local dressing = store.get('dressing')
        if dressing == nil then
            dressing = {}
        end
        label = label
        table.remove(dressing, label)
        store.set('dressing', dressing)
    end)
end)

function PayRent()
  MySQL.Async.fetchAll(
  'SELECT * FROM owned_motel WHERE rented = 1', {},
  function (result)
    for i=1, #result, 1 do
      local xPlayer = ESX.GetPlayerFromIdentifier(result[i].owner)
      if xPlayer ~= nil then
        xPlayer.removeBank(result[i].price)
        TriggerClientEvent('esx:showNotification', xPlayer.source, _U('paid_rent', result[i].price))
      else
        MySQL.Sync.execute(
        'UPDATE users SET bank = bank - @bank WHERE identifier = @identifier',
        {
          ['@bank']       = result[i].price,
          ['@identifier'] = result[i].owner
        })
      end
      TriggerEvent('esx_addonaccount:getSharedAccount', 'society_realestateagent', function(account)
        account.addMoney(result[i].price)
      end)
    end
  end)
end

TriggerEvent('cron:runAt', 1, 0, PayRent)
