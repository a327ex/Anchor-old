command = arg[1]
arg1 = arg[2]
arg2 = arg[3]
arg3 = arg[4]

print('>' .. (command or '') .. ' ' .. (arg1 or '') .. ' ' .. (arg2 or '') .. ' ' .. (arg3 or ''))

local path_exists = function(path)
  local ok, err, code = os.rename(path, path)
  if not ok then
    if code == 13 then
      return true
    end
  end
  return ok, err
end

local get_lines = function(path)
  if not path_exists(path) then return {} end
  local lines = {}
  for line in io.lines(path) do table.insert(lines, line) end
  return lines
end

-- Create directory AppData/Roaming/Anchor
anchor_folder = os.getenv'APPDATA' .. '\\Anchor'
os.execute('mkdir ' .. anchor_folder .. '> NUL 2>NUL')

-- anchor.exe create name
if command == 'create' then
  if not arg1 then
    print("error: 'create' needs an argument for the project's name")
    print("       example: anchor.exe create PROJECT_NAME")
    return
  end

  local project_file = anchor_folder .. '\\' .. arg1 .. '.txt'
  if path_exists(project_file) then
    print('error: project ' .. arg1 .. ' already exists')
  else
    local project_folder = io.popen'cd':read() .. '\\' .. arg1
    os.execute('echo "' .. project_folder .. '" > "' .. project_file .. '"')
    os.execute('git clone https://github.com/a327ex/Anchor.git ' .. arg1)
    os.execute('cd ' .. project_folder .. ' && rmdir /s /q ' .. project_folder .. '\\.git')
    -- print('success: created project ' .. arg1 .. ' to ' .. project_folder)
  end

-- anchor.exe run name
elseif command == 'run' then
  if not arg1 then
    print("error: 'run' needs an argument for the project's name")
    print("       example: anchor.exe run PROJECT_NAME")
    return
  end

  local project_file = anchor_folder .. '\\' .. arg1 .. '.txt'
  if path_exists(project_file) then
    local lines = get_lines(project_file)
    local project_folder = lines[1]
    os.execute(project_folder .. '\\love\\love.exe --console ' .. project_folder)
  else
    print("error: project " .. arg1 .. " doesn't exist")
    print('       run "anchor.exe create ' .. arg1 .. '" first')
  end

-- anchor.exe upload name opt
elseif command == 'upload' then
  if not arg1 then
    print("error: 'upload' needs an argument for the project's name")
    print("       example: anchor.exe upload PROJECT_NAME")
    return
  end

  local project_file = anchor_folder .. '\\' .. arg1 .. '.txt'
  if path_exists(project_file) then
    local lines = get_lines(project_file)
    local has_uploaded_before = false
    for _, line in ipairs(lines) do
      if line:find('github_username=') then
        has_uploaded_before = line:sub(line:find('=')+1, -2)
        break
      end
    end

    local project_folder = lines[1]
    if has_uploaded_before then
      if arg2 then
        os.execute('cd ' .. project_folder .. ' && git add -A && git commit -m "' .. arg2 .. '" && git push -u origin master')
        -- print('success: uploaded changes to https://github.com/' .. has_uploaded_before .. '/' .. arg1 .. '.git')
      else
        os.execute('cd ' .. project_folder .. ' && git add -A && git commit -a --allow-empty-message -m "" && git push -u origin master')
        -- print('success: uploaded changes to https://github.com/' .. has_uploaded_before .. '/' .. arg1 .. '.git')
      end

    else
      print("info: This is your first time using 'anchor upload' for project " .. arg1)
      if not arg2 then
        print("error: 'upload' needs an argument for your github username for its first run")
        print("       example: anchor.exe upload PROJECT_NAME GITHUB_USERNAME")
        return
      end

      print("      Before uploading, you need to have created the corresponding repository on github")
      print("      This repository needs to have the same name as the one passed in to this command: " .. arg1)
      print("      And it needs to be created by the account with the matching github username: " .. arg2)
      print("      Your terminal also has to have git installed such that running 'git' by itself works")
      print("      Do you meet all these requirements for this project? Y/N")
      local response = io.read()
      if response == 'Y' or response == 'y' then
        os.execute('echo github_username=' .. arg2 .. ' >> ' .. project_file)
        os.execute('cd ' .. project_folder .. ' && git init && git remote add origin https://github.com/' .. arg2 .. '/' .. arg1 .. '.git && git add -A && git commit -a --allow-empty-message -m "" && git push -u origin master')
        -- print('success: created repository locally to ' .. project_folder .. ' and uploaded project ' .. arg1 .. ' to https://github.com/' .. arg2 .. '/' .. arg1 .. '.git')
      else
        print("error: one or more uploading requirements not met")
        return
      end
    end

  else
    print("error: project " .. arg1 .. " doesn't exist")
    print('       run "anchor.exe create ' .. arg1 .. '" first')
  end

-- anchor.exe download name opt
elseif command == 'download' then
  if not arg1 then
    print("error: 'download' needs an argument for the project's name")
    print("       example: anchor.exe download PROJECT_NAME")
    return
  end

  local project_file = anchor_folder .. '\\' .. arg1 .. '.txt'
  if path_exists(project_file) then
    local lines = get_lines(project_file)
    local github_username = false
    for _, line in ipairs(lines) do
      if line:find('github_username=') then
        github_username = line:sub(line:find('=')+1, -2)
        break
      end
    end

    local project_folder = lines[1]
    if not github_username then
      print("error: project " .. arg1 .. " has been created but hasn't uploaded to github yet")
      print('       run "anchor.exe upload ' .. arg1 .. ' GITHUB_USERNAME" first')
      return
    else
      os.execute('cd ' .. project_folder .. ' && git pull')
      -- print('success: downloaded changes from https://github.com/' .. github_username .. '/' .. arg1 .. '.git')
    end

  else
    print("info: Project " .. arg1 .. " doesn't exist locally, attempting to download it from github...")
    if not arg2 then
      print("error: 'download' needs an argument for the github username that owns the project")
      print("       example: anchor.exe download PROJECT_NAME GITHUB_USERNAME")
      return
    end

    local project_folder = io.popen'cd':read() .. '\\' .. arg1
    os.execute('echo "' .. project_folder .. '" > "' .. project_file .. '"')
    os.execute('echo github_username=' .. arg2 .. ' >> ' .. project_file)
    os.execute('git clone https://github.com/' .. arg2 .. '/' .. arg1 .. '.git ' .. arg1)
    -- print('success: downloaded project ' .. arg1 .. ' to ' .. project_folder)
  end

-- anchor.exe build name target opt
elseif command == 'build' then
  if not arg1 then
    print("error: 'build' needs an argument for the project's name")
    print("       example: anchor.exe build PROJECT_NAME")
    return
  end

  if not arg2 then
    print("error: 'build' needs an argument for the build target")
    print("       options: steam, windows, web, h=n")
    print("       example: anchor.exe build PROJECT_NAME windows")
    return
  end

  if arg2 ~= 'steam' and arg2 ~= 'windows' and arg2 ~= 'web' and arg2 ~= 'h=n' then
    print("error: invalid build target")
    print("       try one of these: steam, windows, web, h=n")
    return
  end

  local project_file = anchor_folder .. '\\' .. arg1 .. '.txt'
  if path_exists(project_file) then
    local lines = get_lines(project_file)
    local zip, lovejs, steam = false, false, false
    for _, line in ipairs(lines) do
      if line:find('zip') then zip = true end
      if line:find('lovejs') then lovejs = true end
      if line:find('steam') then steam = true end
    end

    if not zip and not lovejs then
      print("info: This is your first time using 'anchor build' for project " .. arg1)
      print("      Before building, you need to have both 7-Zip and love.js installed:")
      print("          'C:\\Program Files\\7-Zip\\7z.exe' needs to exist")
      print("          'love-js' should be runnable on the command line")
      print("      Do you meet all these requirements for this project? Y/N")
      local response = io.read()
      if response == 'Y' or response == 'y' then
        os.execute('echo zip >> ' .. project_file)
        os.execute('echo lovejs >> ' .. project_file)
        zip = true
        lovejs = true
      else
        print("error: one or more building requirements not met")
        return
      end
    end

    if zip and lovejs then
      if arg2 == 'windows' then
        os.execute('cd ' .. project_folder .. '\\love && build_windows.bat ' .. arg1)
      elseif arg2 == 'web' then
        os.execute('cd ' .. project_folder .. '\\love && build_web.bat ' .. arg1)
      elseif arg2 == 'steam' then
        if not steam then
          print("info: This is your first time using 'anchor build' targetting 'steam' for project " .. arg1)
          print("      Before building the game for steam, you need to have followed the steps described at:")
          print("          https://github.com/a327ex/Anchor#steam")
          print("      Have you followed all these steps for this project? Y/N")
          local response = io.read()
          if response == 'Y' or response == 'y' then
            os.execute('echo steam >> ' .. project_file)
            steam = true
          else
            print("error: one or more steam building requirements not met")
            return
          end
        end

        if steam then
          if path_exists(project_folder .. '/steam/') then
            os.execute('cd ' .. project_folder .. '\\love && build_steam.bat ' .. arg1)
          else
            print("error: 'steam' directory does not exist at the project's top level")
            print("       follow the steps described at https://github.com/a327ex/Anchor#steam")
          end
        end
      end
    end

  else
    print("error: project " .. arg1 .. " doesn't exist")
    print('       run "anchor.exe create ' .. arg1 .. '" first')
  end
end
