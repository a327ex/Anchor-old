# Anchor

Anchor is a Lua game development engine built on top of LÖVE. Its goal is to serve as a good engine for programmers who like Lua, are mostly developing 2D games, and want to release their games on Steam and on the Web. It's currently being built so use at your own peril!

<br>

## Distributing Your Games

### Windows

To build your game for Windows simply navigate to the `engine/love` folder with your terminal and then call `build_windows.bat GAMENAME`. This will package your game up for distribution into a .zip file located in `builds/windows`.

### Steam

1. Download the latest Steamworks SDK from the [partner page](https://partner.steamgames.com/dashboard)

2. Take `redistributable_bin/win64/steam_api64.dll` and paste it to your projects `engine/love` folder

3. Take the entire `tools` folder, paste it to your project's top level folder (it should at the same level as `engine` and your `main.lua` file) and rename it to `steam`

4. If you're using git on your project, add the newly created `steam` folder to .gitignore since you don't want to keep track of it, as it tends to balloon in size

5. Unzip `SteamPipeGUI.zip` and run the SteamPipe GUI executable

6. Fill out the data in the application. In this example my game's folder is `E:\a327ex\SNKRX` and so everything is filled accordingly. In your case that folder should be different, but the rest should be the same

<p align="center">
<img src="https://i.imgur.com/EBgYKAb.png"></img>
</p>

7. Click "generate VDFs" to generate the scripts that will upload your game to Steam

8. Make sure that you've set launch options and created the depots on the Steamworks website and that you've published them

<p align="center">
<img src="https://i.imgur.com/mOEMuRT.png"></img>
</p>

<p align="center">
<img src="https://i.imgur.com/Qo2cnh7.png"></img>
</p>

9. Navigate to `engine/love` on a terminal and call `build_steam.bat GAMENAME`, this will package the game up and copy it to `steam/ContentBuilder/content`

10. Hit "upload", if you want to test it out first check the "preview build" box. A successful upload looks like this:

<p align="center">
<img src="https://i.imgur.com/gHl6GV2.png"></img>
</p>

11. Go to your builds page on the Steamworks site and set the build that you just uploaded to live

The first 8 steps need to be done once, and the final 3 need to be repeated every time you want to update the game that's uploaded to Steam.
Make sure to watch [this video](https://www.youtube.com/watch?v=SoNH-v6aU9Q) for an overall explanation of what's going on with this process.

### Web

1. Set `web = true` at the top of your `main.lua` file before you require the engine

2. Change window width and height in `conf.lua` to the size you want your game to be, as well any scaling variables like `sx, sy` in `engine/init.lua`

3. Install love.js somewhere on your computer as described in [this page](https://github.com/Davidobot/love.js). You simply need to download that folder, `cd` into it and then call `npm install` and `npm link`.

4. Call `build_web.bat GAMENAME GAMEFOLDER` where `GAMEFOLDER` is the complete path to your game. For instance, if my project was located in `e:\a327ex\JUGGLRX` I would call `build_web.bat JUGGLRX e:\a327ex\JUGGLRX`.

The build should be available in the `builds/web` folder and you can test it by `cd`ing into it, running `python -m http.server 8000` and then opening `localhost:8000` in your browser.

If you're making your game available on a site like itch.io, then editing the `index.html` file also is needed to make it work. There you should change the canvas resolution to your game's resolution, as well as removing both titles and footers from the file. You also need to set the size of the display window on itch.io to match the game's resolution.

You also need to be mindful of the restrictions that [love.js](https://github.com/Davidobot/love.js) has in regards to the Web. Those are described in that github page as well as [here](https://schellingb.github.io/LoveWebBuilder/). Most of them have already been taken care of in the engine when you set the global `web` variable to true, but in case your game fails to run, check to see if your code isn't doing any of things mentioned in either page. It's important to also notice that only the web build uses `conf.lua`, while the Windows one uses all the settings passed on to the `engine_run` function directly. In general, try to keep the number of audio files down as well as their size, otherwise you'll get dodgy audio issues.
