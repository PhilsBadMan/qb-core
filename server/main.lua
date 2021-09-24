QBCore = {}
QBCore.Functions = {}
QBCore.Config = QBConfig
QBCore.Shared = QBShared
QBCore.ServerCallbacks = {}
QBCore.UseableItems = {}

<<<<<<< Updated upstream
-- Check perms on start

CreateThread(
  function()
    local result = exports.oxmysql:fetchSync('SELECT * FROM permissions', {})
    if result[1] ~= nil then
      for k, v in pairs(result) do
        QBCore.Config.Server.PermissionList[v.license] = {
          license = v.license,
          permission = v.permission,
          optin = true
        }
      end
    end
  end
)
=======
exports('GetCoreObject', function()
	return QBCore
end)
>>>>>>> Stashed changes
