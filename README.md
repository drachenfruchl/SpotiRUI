# Spotify RUI Display

Displays your current played song and other features such as **artists, album, queue information and *eventally* lyrics** via an ingame RUI element.  

## TODOs

Planning to go through these sorted by priority.  
First TODO is getting the RUI element set up for further testing.

### Python

---

- [X] Setup spotify application
  - [X] Get auth token
  - [X] Get access token
- [X] Setup redirect page using local server
- [ ] ~Create GUI for setup for easier access~

### Spotify API

---

- [X] Fetch new tokens on match load
  - [X] Reauth if necessary using refresh token
- [X] Periodically fetch song infos
  - [X] Artists
  - [X] Current song name
  - [ ] ~Upcoming songs from the queue~
  - [X] Progress into song  

### Ingame

---

- [X] Create a RUI display  
    > Song name  
      <sup>Artist 1, Artist 2, Artist 3...</sup>  
      ||||||||||||||------------------ ▶⏸ 0:33 / 2:43  
      Upcoming song name  
      <sup>Upcoming song name 2</sup>

- [ ] ~Dynamically colored song name~
  - [ ] ~Base upon most prominent color(s) of the album cover art~
  - [ ] ~Animated color fade~
