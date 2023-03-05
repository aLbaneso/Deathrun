#include <amxmodx>
#include <amxmisc>
#include <sqlx>
#include <settings>

#define MYSQL_TABLE "players"

new Handle:MYSQL_CONNECTION
new DatabaseID[33]
new forwardUserLogin, forwardUserLoginReturn

public plugin_init(){
	#if AMXX_VERSION_NUM >= 200
		register_plugin("Deathrun: Player Database", __DATE__, AUTHOR, URL, DESCRIPTION)
	#else
		register_plugin("Deathrun: Player Database", __DATE__, AUTHOR)
	#endif
	forwardUserLogin = CreateMultiForward("UserLogin", ET_IGNORE, FP_CELL)
}

public plugin_natives()
	register_native("_get_user_id", "__get_user_id")

public plugin_cfg()
	MYSQL_Init()

public MYSQL_Init(){
	MYSQL_CONNECTION = SQL_MakeDbTuple(MYSQL_HOST, MYSQL_USER, MYSQL_PASSWORD, MYSQL_DATABASE)
	new query[256]
	formatex(query, charsmax(query), "CREATE TABLE IF NOT EXISTS `%s` (\
		`id` INT(4) NOT NULL AUTO_INCREMENT,\
		`steamid` VARCHAR(32) NOT NULL,\
		`name` VARCHAR(32) NOT NULL,\
		PRIMARY KEY (`id`),\
		UNIQUE (`steamid`));", MYSQL_TABLE)
	SQL_ThreadQuery(MYSQL_CONNECTION, "IgnoredOutput", query)
}

public client_putinserver(id){
	if (!is_user_bot(id) && !is_user_hltv(id)){
		new steamid[32], data[2]
		data[0] = id
		data[1] = 0
		DatabaseID[id] = 0
		get_user_authid(id, steamid, charsmax(steamid))
		SQL_ThreadQuery(MYSQL_CONNECTION, "DataOutput", fmt("SELECT * FROM `%s` WHERE BINARY `steamid` = '%s';", MYSQL_TABLE, steamid), data, sizeof(data))
	}
}

public client_disconnected(id){
	if (!is_user_bot(id) && !is_user_hltv(id)){
		SQL_ThreadQuery(MYSQL_CONNECTION, "IgnoredOutput", fmt("UPDATE `%s` SET `name` = '%n' WHERE id = %d;", MYSQL_TABLE, id, DatabaseID[id]))
		DatabaseID[id] = 0
	}
}

public __get_user_id(iPlugin, iParams)
	return is_user_connected(get_param(1)) ? DatabaseID[get_param(1)] : -1

public DataOutput(failState, Handle:query, error[], errNum, data[]){
	if (errNum) server_print("deathrun_database2:DataOutput:(%d)%s", errNum, error)

	else {
		new id = data[0]
		if(is_user_connected(id)){
			if(!SQL_NumResults(query)){
				new steamid[32]
				get_user_authid(id, steamid, charsmax(steamid))
				SQL_ThreadQuery(MYSQL_CONNECTION, "IgnoredOutput", fmt("INSERT INTO `%s` VALUES(NULL, '%s', '%n');", MYSQL_TABLE, steamid, id))
				client_putinserver(id)
				
				} else {
				DatabaseID[id] = SQL_ReadResult(query, 0)

				if (!ExecuteForward(forwardUserLogin, forwardUserLoginReturn, id))
					server_print("deathrun_database2:Cannot execute forward")
			}
		}
	}
}

public IgnoredOutput(failState, Handle:query, const error[], errNum)
	if (errNum) server_print("deathrun_database2:IgnoredOutput:(%d)%s", errNum, error)