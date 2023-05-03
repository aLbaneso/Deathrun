# Deathrun Timer
### Features

- Made on AmxxPawn
- Time your best run and compete against other players
- Records down to milliseconds
- Uses MySQL which can be used on any side project
- Button-less, first to kill the Terrorist wins the game
- Terrorist has been replaced with a BOT

### Requirements
1. AmxxModule
2. MySQL Database

### Setup
1. Modify `scripting/include/settings.inc` to configure your database and add your website url to later complie the files
2. Upload web folder to your web server (requires php) and the plugins to your game server (should work on HLDS with AMXX 1.9+)
3. Start the server, mod will take care of the SQL table creation

### TODO
Nothing at this moment

### SQL Table Examples

#### maplist.sql
list will be used to loop throw the rows and display the maps alphabetically on the web server
|Identifier  | Map|
|------------- | ------------- |
|1  | deathrun_arctic|
|2  | deathrun_forest|
|3  | deathrun_extreme|
|4  | deathrun_fun|

#### mapname.sql
- list will be unordered and will be used to loop throw the rows and display the records from fastest to slowest

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

Website images: https://imgur.com/a/1vDFTZP (assume maps are deathrun ones ran by legit players)