#include <amxmodx>
#include <amxmisc>
#include <sqlx>
#include <settings>

native _get_user_id(id)

new Handle:MYSQL_CONNECTION
new mapname[32]

enum PlayerData{
	record,
	timestamp
}

new Player[MAX_PLAYERS + 1][PlayerData]

public plugin_init(){
	#if AMXX_VERSION_NUM >= 200
		register_plugin("Deathrun: Map Database", __DATE__, AUTHOR, URL, DESCRIPTION)
	#else
		register_plugin("Deathrun: Map Database", __DATE__, AUTHOR)
	#endif
	get_mapname(mapname, charsmax(mapname))
	strtolower(mapname)
}

public plugin_cfg()
	MYSQL_Init()

public MYSQL_Init(){
	MYSQL_CONNECTION = SQL_MakeDbTuple(MYSQL_HOST, MYSQL_USER, MYSQL_PASSWORD, MYSQL_DATABASE)

	SQL_ThreadQuery(MYSQL_CONNECTION, "IgnoredOutput", fmt("CREATE TABLE IF NOT EXISTS `%s` (\
		`id` INT(4) NOT NULL AUTO_INCREMENT,\
		`player_id` INT(4) NOT NULL,\
		`record` INT(4) NOT NULL,\
		`timestamp` INT(4) NOT NULL,\
		PRIMARY KEY (`id`),\
		UNIQUE (`player_id`));", mapname))

	SQL_ThreadQuery(MYSQL_CONNECTION, "IgnoredOutput", fmt("CREATE TABLE IF NOT EXISTS `%s` (\
		`id` INT(4) NOT NULL AUTO_INCREMENT,\
		`map` VARCHAR(32) NOT NULL,\
		PRIMARY KEY (`id`),\
		UNIQUE (`map`));", MAPLIST))

	SQL_ThreadQuery(MYSQL_CONNECTION, "MapOutput", fmt("SELECT * FROM `%s` WHERE `map` = '%s';", MAPLIST, mapname))
}

public UserLogin(id){
	new data[2]
	data[0] = id
	data[1] = 0
	Player[id][record] = 0
	Player[id][timestamp] = 0
	SQL_ThreadQuery(MYSQL_CONNECTION, "DataOutput", fmt("SELECT * FROM `%s` WHERE `player_id` = %d;", mapname, _get_user_id(id)), data, sizeof(data))
}

public MapOutput(failState, Handle:query, error[], errNum){
	if (errNum) server_print("map_database:MapOutput:%s", error)
	if(!SQL_NumResults(query))
		SQL_ThreadQuery(MYSQL_CONNECTION, "IgnoredOutput", fmt("INSERT INTO `%s` VALUES(NULL, '%s');", MAPLIST, mapname))
}

public DataOutput(failState, Handle:query, error[], errNum, data[]){
	if (errNum) server_print("map_database:DataOutput:(%d)%s", errNum, error)
	
	else {
		new id = data[0]
		if(is_user_connected(id)){
			if(SQL_NumResults(query)){
				Player[id][record] = SQL_ReadResult(query, 2)
				Player[id][timestamp] = SQL_ReadResult(query, 3)
			}
		}
	}
}

public IgnoredOutput(failState, Handle:query, const error[], errNum)
	if (errNum) server_print("map_database:IgnoredOutput:(%d)%s", errNum, error)