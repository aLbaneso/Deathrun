#include <amxmodx>
#include <amxmisc>
#include <sqlx>
#include <settings>

#pragma ctrlchar '\'

native _get_user_id(id)

new PluginName[MAX_NAME_LENGTH]
new Handle:MYSQL_CONNECTION

enum PlayerData{
	rank,
	record,
	timestamp
}

new Player[MAX_PLAYERS + 1][PlayerData]
new mapname[MAX_NAME_LENGTH]

public plugin_init()
{
	#if AMXX_VERSION_NUM >= 200
		register_plugin("Deathrun: Player Rank", __DATE__, AUTHOR, URL, DESCRIPTION)
	#else
		register_plugin("Deathrun: Player Rank", __DATE__, AUTHOR)
	#endif
	register_logevent("ReloadRank", 2, "1=Round_Start") 
	
	register_clcmd("say rank", "clcmd_rank")
	get_mapname(mapname, charsmax(mapname))
	strtolower(mapname)

	GetPluginName
}

public plugin_natives()
{
	register_native("_get_user_rank", "__get_user_rank")
	register_native("_get_user_record", "__get_user_record")
	register_native("_get_user_timestamp", "__get_user_timestamp")
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
}

public UserLogin(id)
{
	Player[id][rank] = 0
	Player[id][record] = 0
	Player[id][timestamp] = 0

	new data[2]
	data[0] = id
	data[1] = 0
	SQL_ThreadQuery(MYSQL_CONNECTION, "GetRecordHandler", fmt("SELECT * FROM `%s` WHERE `player_id` = %d;", mapname, _get_user_id(id)), data, sizeof data)
}

public ReloadRank()
{
	new players[MAX_PLAYERS], num, id
	get_players(players, num, "ceh", "CT")

	for (new i = 0; i < num; i++)
	{
		id = players[i]
		if (is_user_connected(id))
		{
			new data[2]
			data[0] = id
			data[1] = 0

			SQL_ThreadQuery(MYSQL_CONNECTION, "GetRecordHandler", fmt("SELECT * FROM `%s` WHERE `player_id` = %d;", mapname, _get_user_id(id)), data, sizeof data)
		}
	}
}

public GetRecordHandler(failState, Handle:query, error[], errNum, data[])
{
	RUNPRESCRIPT("GetRecordHandler")
	
	else
	{
		new id = data[0];
		if(is_user_connected(id))
		{
			if(SQL_NumResults(query))
			{
				Player[id][record] = SQL_ReadResult(query, 2)
				Player[id][timestamp] = SQL_ReadResult(query, 3)

				new data2[2], query_rank_single[384]
				data2[0] = id
				data2[1] = 0
				formatex(query_rank_single, charsmax(query_rank_single), "select 1 + count(*)\
					from `%s`\
					where `%s`.`record` < \
					(select `%s`.`record` from `%s` where `%s`.`player_id` = %d);", mapname, mapname, mapname, mapname, mapname, _get_user_id(id))
				SQL_ThreadQuery(MYSQL_CONNECTION, "GetRankHandler", query_rank_single, data2, sizeof data2)
			}
		}
	}
}

public GetRankHandler(failState, Handle:query, error[], errNum, data[])
{
	RUNPRESCRIPT("GetRankHandler")

	else
	{
		new id = data[0];
		if(is_user_connected(id))
		{
			if(SQL_NumResults(query))
				Player[id][rank] = SQL_ReadResult(query, 0)
		}
	}
}

public clcmd_rank(id)
{
	if (Player[id][rank])
	{
		new szDate[MAX_NAME_LENGTH], ClockString[MAX_NAME_LENGTH]
		Clock(Player[id][record], ClockString, charsmax(ClockString))
		format_time(szDate, charsmax(szDate), "%B %d %Y | %I:%M:%S %p", Player[id][timestamp])

		client_print_color(id, print_team_blue, "%s ^1You're ranked ^3#%d ^1with ^3%s", TAG, Player[id][rank], ClockString)
		client_print_color(id, print_team_blue, "%s ^1This record was set on ^3%s", TAG, szDate)
	}
	
	else
		client_print_color(id, print_team_blue, "%s ^1You are not ranked yet in this map", TAG)
}

public Clock(Milliseconds, String[], Length)
{
	formatex(String, Length, "%d:%02d.%03dms", Milliseconds/1000/60, (Milliseconds/1000) % 60, Milliseconds % 1000)
}

public __get_user_rank(iPlugin, iParams)
{
	return is_user_connected(get_param(1)) ? Player[get_param(1)][rank] : -1
}

public __get_user_record(iPlugin, iParams)
{
	return is_user_connected(get_param(1)) ? Player[get_param(1)][record] : -1
}

public __get_user_timestamp(iPlugin, iParams)
{
	return is_user_connected(get_param(1)) ? Player[get_param(1)][timestamp] : -1
}