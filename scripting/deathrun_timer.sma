#include <amxmodx>
#include <fakemeta>
#include <hamsandwich>
#include <sqlx>
#include <settings>

#define XPOS 0.02
#define YPOS 0.5

#define RESPAWN 2023

native _get_user_id(id)
native _get_user_rank(id)
native _get_user_record(id)
native _get_user_timestamp(id)

new PluginName[MAX_NAME_LENGTH]
new Handle:MYSQL_CONNECTION

enum PlayerData{
	rank,
	record,
	timestamp
}

new Player[PlayerData], mapname[MAX_NAME_LENGTH]
new Float: GetStartTime[MAX_PLAYERS + 1], Float: Time[MAX_PLAYERS + 1]

public plugin_init(){
	#if AMXX_VERSION_NUM >= 200
		register_plugin("Deathrun: Timer", __DATE__, AUTHOR, URL, DESCRIPTION)
	#else
		register_plugin("Deathrun: Timer", __DATE__, AUTHOR)
	#endif

	RegisterHam(Ham_Spawn, "player", "HookSpawn", 1)
	RegisterHam(Ham_Killed, "player", "HookKilled", 0)

	get_mapname(mapname, charsmax(mapname))
	strtolower(mapname)

	GetPluginName
}

public plugin_cfg(){
	MYSQL_Init()
}

public MYSQL_Init(){
	MYSQL_CONNECTION = SQL_MakeDbTuple(MYSQL_HOST, MYSQL_USER, MYSQL_PASSWORD, MYSQL_DATABASE)
}

public client_disconnected(id){
	remove_task(id)
}

public UserLogin(id){
	if (task_exists(id)){
		remove_task(id)
	}
}

public HookSpawn(id){
	remove_task(id)
	GetStartTime[id] = get_gametime()
	set_task(0.09, "Start", id, .flags="b")
}

public HookKilled(Victim, Attacker){
	new VictimTeam = get_user_team(Victim)
	new AttackerTeam = get_user_team(Attacker)
	
	if (VictimTeam == 1 && AttackerTeam == 2){
		GameWin(Attacker)
	}

	else if (VictimTeam == 2){
		remove_task(Victim)
	}
}

public GameWin(id){
	Time[id] = get_gametime() - GetStartTime[id]
	new Milliseconds = floatround(Time[id] * 1000)
	remove_task(id)

	Player[rank] = _get_user_rank(id)
	Player[record] = _get_user_record(id)
	Player[timestamp] = _get_user_timestamp(id)

	if (!Player[rank]){
		client_print_color(id, print_team_default, "%s ^1Congratulations on your first record on this map", TAG)
		PublishRecord(true, _get_user_id(id), Milliseconds)
	}

	else if (Player[record]){
		if (Milliseconds < Player[record]){
			PublishRecord(false, _get_user_id(id), Milliseconds)
			client_print_color(id, print_team_blue, "%s ^1New record (^3-%s ^1improvement)", TAG, Clock(Player[record] - Milliseconds))
		}

		else if (Milliseconds == Player[record])
			client_print_color(id, print_team_default, "%s ^1You tie with your own record", TAG)

		else {
			client_print_color(id, print_team_blue, "%s ^1Your best record is ^3%s", TAG, Clock(Player[record]))
		}
	}

	client_print_color(id, print_team_blue, "%s ^1%n won the round within ^3%s", TAG, id, Clock(Milliseconds))
} 

public PublishRecord(bool: improvement, player_id, new_record){
	if (improvement){
		SQL_ThreadQuery(MYSQL_CONNECTION, "IgnoredOutput", fmt("INSERT INTO `%s` VALUES(NULL, %d, %d, %d);", mapname, player_id, new_record, get_systime()))
	}

	else {
		SQL_ThreadQuery(MYSQL_CONNECTION, "IgnoredOutput", fmt("UPDATE `%s` SET `record` = %d, `timestamp` = %d WHERE `player_id` = %d;", mapname, new_record, get_systime(), player_id))
	}
}

public Start(id){
	Time[id] = get_gametime() - GetStartTime[id]
	set_dhudmessage(255, 204, 0, XPOS, YPOS, .holdtime=0.09, .fadeintime=0.0, .fadeouttime=0.09)
	show_dhudmessage(id, Clock(floatround(Time[id] * 1000)))
}

public Respawn(id){
	id -= RESPAWN
	if (is_user_connected(id)){
		ExecuteHamB(Ham_CS_RoundRespawn, id)
	}
}

public IgnoredOutput(failState, Handle:query, const error[], errNum){
	RUNPRESCRIPT("IgnoredOutput")
}

public Clock(Value)
	return fmt("%d:%02d.%03dms", Value/1000/60, (Value/1000) % 60, Value % 1000)