#include <amxmodx>
#include <amxmisc>
#include <sqlx>
#include <settings>

new PluginName[MAX_NAME_LENGTH]
new Handle:MYSQL_CONNECTION
new DatabaseID[MAX_PLAYERS + 1]
new forwardUserLogin, forwardUserLoginReturn

public plugin_init()
{
	#if AMXX_VERSION_NUM >= 200
		register_plugin("Deathrun: Player Database", __DATE__, AUTHOR, URL, DESCRIPTION)
	#else
		register_plugin("Deathrun: Player Database", __DATE__, AUTHOR)
	#endif
	forwardUserLogin = CreateMultiForward("UserLogin", ET_IGNORE, FP_CELL)

	GetPluginName
}

public plugin_natives()
{
	register_native("_get_user_id", "__get_user_id")
}

public plugin_cfg()
{
	MYSQL_Init()
}

public plugin_end()
{
	SQL_FreeHandle(MYSQL_CONNECTION)
}

public MYSQL_Init()
{
	// MYSQL_CONNECTION = SQL_MakeDbTuple(MYSQL_HOST, MYSQL_USER, MYSQL_PASSWORD, MYSQL_DATABASE)
	MYSQL_CONNECTION = SQL_MakeStdTuple()
	
	new query[256]
	formatex(query, charsmax(query), "CREATE TABLE IF NOT EXISTS `%s` (\
		`id` INT(4) NOT NULL AUTO_INCREMENT,\
		`steamid` VARCHAR(32) NOT NULL,\
		`name` VARCHAR(64) NOT NULL,\
		PRIMARY KEY (`id`),\
		UNIQUE (`steamid`));", MYSQL_TABLE)
	SQL_ThreadQuery(MYSQL_CONNECTION, "IgnoredOutput", query)
}

public client_putinserver(id)
{
	if (!is_user_bot(id) && !is_user_hltv(id))
	{
		new steamid[32], data[2]
		data[0] = id
		data[1] = 0
		DatabaseID[id] = 0
		get_user_authid(id, steamid, charsmax(steamid))
		SQL_ThreadQuery(MYSQL_CONNECTION, "DataOutput", fmt("SELECT * FROM `%s` WHERE BINARY `steamid` = '%s';", MYSQL_TABLE, steamid), data, sizeof(data))
	}
}

public client_disconnected(id)
{
	if (!is_user_bot(id) && !is_user_hltv(id))
	{
		new buffer[MAX_NAME_LENGTH*2]
		SQL_QuoteStringFmt(Empty_Handle, buffer, charsmax(buffer), "%n", id)
		server_print(buffer)
		SQL_ThreadQuery(MYSQL_CONNECTION, "IgnoredOutput", fmt("UPDATE `%s` SET `name` = '%s' WHERE id = %d;", MYSQL_TABLE, buffer, DatabaseID[id]))
		DatabaseID[id] = 0
	}
}

public __get_user_id(iPlugin, iParams)
{
	return is_user_connected(get_param(1)) ? DatabaseID[get_param(1)] : -1
}

public DataOutput(failState, Handle:query, error[], errNum, data[])
{
	RUNPRESCRIPT("IgnoredOutput")

	else
	{
		new id = data[0]
		if(is_user_connected(id))
		{
			if(!SQL_NumResults(query))
			{
				new steamid[32], buffer[MAX_NAME_LENGTH*2]
				get_user_authid(id, steamid, charsmax(steamid))
				SQL_QuoteStringFmt(Empty_Handle, buffer, charsmax(buffer), "%n", id)
				server_print(buffer)
				SQL_ThreadQuery(MYSQL_CONNECTION, "IgnoredOutput", fmt("INSERT INTO `%s` VALUES(NULL, '%s', '%s');", MYSQL_TABLE, steamid, buffer))
				client_putinserver(id)
			}

			else
			{
				DatabaseID[id] = SQL_ReadResult(query, 0)

				if (!ExecuteForward(forwardUserLogin, forwardUserLoginReturn, id))
				{
					server_print("%s:Cannot execute forward", PluginName)
				}
			}
		}
	}
}

public IgnoredOutput(failState, Handle:query, const error[], errNum)
{
	RUNPRESCRIPT("IgnoredOutput")
}