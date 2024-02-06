
# Deathrun Timer
### Features

- Made on AmxxPawn * 1.9 and up supported
- Time your best run and compete against other players
- Break others records and set yourself higher in the ranking table
- Records down to milliseconds (1/1000 of a seconds)
- Uses MySQL which can be used on any side project (discord integration etc)
- Button-less, first to kill the Terrorist wins the game
-- Which means that you cannot have a player as a Terrorist. A bot will be created instead and will sit on spawn. See `deathrun_bots.sma`
- Webserver to display map records and player stats.
- Record Bot to display the path of best player


### Requirements
1. AmxxModule
2. MySQL Database
3. Web Server

### Setup
1. Modify `scripting/include/settings.inc` to ~~configure your database and~~ add your website url to later complie the files
2. Modify `configs/sql.cfg` to configure your database 
3. Modify `web/config.php` to configure your database
4. Upload web folder to your web server (requires php) and the plugins to your game server (should work on any/HLDS with AMXX 1.9+)
5. Enable mysql at configs/modules.ini file
6. Start the server, mod will take care of the SQL table creation

### Commands
1. (disabled)showbriefing ; set on default as letter I
   
Toggle between different types of timers:

![normal timer ; percentage timer ; both](https://i.imgur.com/PqrApMA.gif)

2. cvar: deathrun_respawn (default 2.3)

### TODO
You still need to block players from joining Terrorist team. Although this is mandatory for the mod to run without any problems, there should be plenty of resources online that can help you auto-join all players to CT. REHLDS has already implemented this feature unless you're using HLDS. In this case you need to look for another plugin to add on top of this MOD.

- Fix `download.php`
- `tutorial.html` to explain how to download runs and play them on own server
- Optimize `deathrun_timer.sma` and `deathrun_movement_player.sma`


### SQL Table Examples

#### maplist.sql
list will be used to loop through the rows and display the maps alphabetically on the web server
|Identifier  | Map|
|------------- | ------------- |
|1  | deathrun_arctic|
|2  | deathrun_forest|
|3  | deathrun_extreme|
|4  | deathrun_fun|

#### mapname.sql
- list will be unordered and will be used to loop through the rows and display the records from fastest to slowest

|Identifier  | Player ID | Record | Date Timestamp|
|------------- | -------------|-------------|-------------|
|1  | 1 | 65213 | 1677894385|
|2  | 3 | 41283 | 1672814126|
|3  | 2 | 55172 | 1641278853|
|4  | 4 | 43268 | 1641624426|

#### players.sql
|Player ID  | Steam ID | Name|
|------------- | -------------|-------------|
|1  | STEAM_1;0:147511418 | chriss|
|2  | STEAM_1:1:152258581 | big|
|3  | STEAM_1:1:184238112 | jacob|
|4  | STEAM_1:1:452031844 | noizy|
## Preview

[![YouTube](http://img.youtube.com/vi/duUQtwEVd0s/0.jpg)](http://www.youtube.com/watch?v=duUQtwEVd0s&list=PLuVPUqdG6VjIMcQs8Y3eVFpVRBvDWhtZ4 "aLbaneso.neT Deathrun")

### Website Images
Home Page (index.php)

[![Home Page](https://i.imgur.com/VikAJEK.png "Home Page")](https://i.imgur.com/VikAJEK.png "Home Page")

Top 15 of de_dust2 map (index.php?map=de_dust2)

[![Top 15](https://i.imgur.com/sunreLP.png "Top 15")](https://i.imgur.com/sunreLP.png "Top 15")

Best Players (player.php)

[![Best Players](https://i.imgur.com/4aFgXWA.png "Best Players")](https://i.imgur.com/4aFgXWA.png "Best Players")

Player's records list (player.php?id=5)

[![Player's records list](https://i.imgur.com/f1QZjnP.png "Player's records list")](https://i.imgur.com/f1QZjnP.png "Player's records list")

Pagination prevents page break in you have hundreds of records.
A good webserver will never have any issues sorting throught the records and ranking them quick.
If you want players information to remain private you can configure `web/config.php` to hide steamid, country and last active date.

Project made using VSCode, AMX Mod X 1.9.0.5294, PHP 8 and MariaDB
