#include <amxmodx>
#include <amxmisc>
#include <sqlx>
#include <settings>

#pragma ctrlchar '\'

new Handle:MYSQL_CONNECTION

new PluginName[MAX_NAME_LENGTH]
new recordman[64] = "no record";
new mapname[MAX_NAME_LENGTH]
new player_id, record, name[MAX_NAME_LENGTH]
new forwardMapLoad, forwardMapLoadReturn

public plugin_init()
{
	#if AMXX_VERSION_NUM >= 200
		register_plugin("Deathrun: Recordman", __DATE__, AUTHOR, URL, DESCRIPTION)
	#else
		register_plugin("Deathrun: Recordman", __DATE__, AUTHOR)
	#endif
	forwardMapLoad = CreateMultiForward("MapLoad", ET_IGNORE, FP_CELL)
	register_event("HLTV", "WhoIsRecordman", "a", "1=0", "2=0")

	get_mapname(mapname, charsmax(mapname))
	strtolower(mapname)
	set_task(2.0, "PrintRecordman", .flags="b")

	GetPluginName
}

public plugin_natives()
{
	register_native("has_record", "_has_record")
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

	WhoIsRecordman()
	
	if (!ExecuteForward(forwardMapLoad, forwardMapLoadReturn, 0))
		server_print("%s:Cannot execute forward", PluginName)
}

public WhoIsRecordman()
{
	SQL_ThreadQuery(MYSQL_CONNECTION, "GetRecordman", fmt("SELECT * FROM `%s` ORDER BY `record` ASC LIMIT 1;", mapname))
}

public PrintRecordman()
{
	set_hudmessage(255, 255, 255, 0.85, 0.90, 0, _, 2.0, 0.1, 0.1, .channel = CHANNEL_RECORDMAN)
	show_hudmessage(0, recordman)
}

public GetRecordman( failState, Handle:query, error[], errNum)
{
	RUNPRESCRIPT("GetRecordman")

	else
	{
		if(SQL_NumResults(query))
		{
			player_id = SQL_ReadResult(query, 1)
			record = SQL_ReadResult(query, 2)
			SQL_ThreadQuery(MYSQL_CONNECTION, "GetRecordmanName", fmt("SELECT * FROM `players` WHERE `id` = %d;", player_id))
		}
	}
}

public GetRecordmanName( failState, Handle:query, error[], errNum)
{
	RUNPRESCRIPT("GetRecordmanName")
	
	else
	{
		if(SQL_NumResults(query))
		{
			SQL_ReadResult(query, 2, name, charsmax(name))
			formatex(recordman, charsmax(recordman), " #1 %s\n   %s", name, Clock(record))
		}
	}
}

public Clock(Milliseconds)
{
	return fmt("%d:%02d.%03dms", Milliseconds/1000/60, (Milliseconds/1000) % 60, Milliseconds % 1000)
}

public _has_record(iPlugin, iParams)
{
	return record
}