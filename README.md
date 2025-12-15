# Spotify RUI Display

Displays information about your current played spotify song via an ingame RUI element.

![Demo GIF](https://i.imgur.com/z9FWksb.gif)

## Setup

- Create an app on *https://developer.spotify.com/dashboard*
- Run 'RUNME.bat'
- Enter your `Client ID` and `Client secret`, which you receive from the dashboard of your recently created app
- Authorize the app (You might have to login to your account first)
- Enter the full file path to your save_data folder  
e.g: `C:/Program Files (x86)/Steam/steamapps/common/Titanfall2/R2Northstar/save_data`
- You should now be ready to launch the game!

**(Dont forget to extract the mod into your mods directory!)**

## FAQ

- Why is the RUI not showing up ingame?
  - Either your spotify application is not open or its paused and you just loaded into a game  
Launch or resume it and the RUI should pop right back up

- Why is the song title / artist list cut off with "..."?
  - If the song title or the entirety of the artists exceeds a certain character limit (20 by default), the rest gets cut off to not clutter the entire HUD  
(Limits can be changed respectively in the modsettings)

- Why does the RUI have some delay to it (when closing/opening the ingame menu or changing songs)
  - This is due to the API taking some time fetching the current information which is why your spotify application is sometimes ahead of the actual displayed informations on the RUI  
(API call interval can be changed in the modsettings)
