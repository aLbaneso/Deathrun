#include <amxmodx>
#include <amxmisc>
#include <sqlx>
#include <settings>

#pragma ctrlchar '\'

new Handle:MYSQL_CONNECTION

new recordmen[64] = "no record";
new mapname[32];
new player_id, record, name[32]
new forwardMapLoad, forwardMapLoadReturn

public plugin_init(){
	#if AMXX_VERSION_NUM >= 200
		register_plugin("Deathrun: Recordmen", __DATE__, AUTHOR, URL, DESCRIPTION)
	#else
		register_plugin("Deathrun: Recordmen", __DATE__, AUTHOR)
	#endif
	forwardMapLoad = CreateMultiForward("MapLoad", ET_IGNORE, FP_CELL)
	register_event("HLTV", "WhoIsRecordmen", "a", "1=0", "2=0");

	get_mapname(mapname, charsmax(mapname))
	strtolower(mapname)
	set_task(2.0, "PrintRecordmen", .flags="b");
}

public plugin_cfg()
	MYSQL_Init()

public PrintRecordmen(){
	set_hudmessage(255, 255, 255, 0.85, 0.90, 0, _, 2.0, 0.1, 0.1, .channel = 2);
	show_hudmessage(0, recordmen);
}

public MYSQL_Init(){
	MYSQL_CONNECTION = SQL_MakeDbTuple(MYSQL_HOST, MYSQL_USER, MYSQL_PASSWORD, MYSQL_DATABASE)
	WhoIsRecordmen()
	
	if (!ExecuteForward(forwardMapLoad, forwardMapLoadReturn, 0))
		server_print("map_recordmen:Cannot execute forward")
}

public WhoIsRecordmen(){
	SQL_ThreadQuery(MYSQL_CONNECTION, "GetRecordmen", fmt("SELECT * FROM `%s` ORDER BY `record` ASC LIMIT 1;", mapname));
}

public GetRecordmen( failState, Handle:query, error[], errNum){
	if (errNum) server_print("map_recordmen:GetRecordmen:(%d)%s", errNum, error)

	else {
		if(SQL_NumResults(query)){
			player_id = SQL_ReadResult(query, 1)
			record = SQL_ReadResult(query, 2)
			SQL_ThreadQuery(MYSQL_CONNECTION, "GetRecordmenName", fmt("SELECT * FROM `players` WHERE `id` = %d;", player_id));
		}
	}
}

public GetRecordmenName( failState, Handle:query, error[], errNum){
	if (errNum) server_print("map_recordmen:GetRecordmenName:(%d)%s", errNum, error)

	else {
		if(SQL_NumResults(query)){
			SQL_ReadResult(query, 2, name, charsmax(name))
			formatex(recordmen, charsmax(recordmen), " #1 %s\n   %s", name, Clock(record));
		}
	}
}

public Clock(Milliseconds)
	return fmt("%d:%02d.%03dms", Milliseconds/1000/60, (Milliseconds/1000) % 60, Milliseconds % 1000)