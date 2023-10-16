#include <amxmodx>
#include <fakemeta>
#include <hamsandwich>
#include <sqlx>
#include <settings>

#define XPOS 0.02
#define YPOS 0.5

#define RESPAWN 2023
#define TIMER 4046

native _get_user_id(id)
native _get_user_rank(id)
native _get_user_record(id)
native _get_user_timestamp(id)

new PluginName[MAX_NAME_LENGTH]
new Handle:MYSQL_CONNECTION

enum PlayerData
{
	rank,
	record,
	timestamp
}

new Player[PlayerData], mapname[MAX_NAME_LENGTH]
new Float: GetStartTime[MAX_PLAYERS + 1], Float: Time[MAX_PLAYERS + 1]

native has_record()
new recordman, Float: recordman_percentage[MAX_PLAYERS + 1], TimerToggler[MAX_PLAYERS + 1]
new bool:isPlayer[MAX_PLAYERS + 1]

public plugin_init()
{
	#if AMXX_VERSION_NUM >= 200
		register_plugin("Deathrun: Timer", __DATE__, AUTHOR, URL, DESCRIPTION)
	#else
		register_plugin("Deathrun: Timer", __DATE__, AUTHOR)
	#endif

	RegisterHam(Ham_Spawn, "player", "HookSpawn", 1)
	RegisterHam(Ham_Killed, "player", "HookKilled", 0)

	register_event("HLTV", "RefreshRecordman", "a", "1=0", "2=0")
	register_clcmd("showbriefing", "ToggleTimer")

	get_mapname(mapname, charsmax(mapname))
	strtolower(mapname)

	GetPluginName
}

public plugin_cfg()
{
	MYSQL_Init()
	RefreshRecordman()
}

public MYSQL_Init()
{
	// MYSQL_CONNECTION = SQL_MakeDbTuple(MYSQL_HOST, MYSQL_USER, MYSQL_PASSWORD, MYSQL_DATABASE)
	MYSQL_CONNECTION = SQL_MakeStdTuple()
}

public client_disconnected(id)
{
	isPlayer[id] = false
	remove_task(id)
}

public UserLogin(id)
{
	isPlayer[id] = true
	remove_task(id)
	TimerToggler[id] = 0
}

public HookSpawn(id)
{
	if (isPlayer[id])
	{
		remove_task(id)
		GetStartTime[id] = get_gametime()
		recordman_percentage[id] = 0.0

		set_task(0.09, "Start", id, .flags="b")
	}
}

public HookKilled(Victim, Attacker)
{
	new VictimTeam = get_user_team(Victim)
	new AttackerTeam = get_user_team(Attacker)
	
	if (VictimTeam == 1 && AttackerTeam == 2)
	{
		GameWin(Attacker)
	}

	else if (VictimTeam == 2)
	{
		remove_task(Victim)
		set_task(2.3, "Respawn", Victim+RESPAWN)
	}
}

public GameWin(id)
{
	Time[id] = get_gametime() - GetStartTime[id]
	new Milliseconds = floatround(Time[id] * 1000)
	remove_task(id)

	Player[rank] = _get_user_rank(id)
	Player[record] = _get_user_record(id)
	Player[timestamp] = _get_user_timestamp(id)
	new systime = get_systime()

	if (!Player[rank])
	{
		client_print_color(id, print_team_default, "%s ^1Congratulations on your first record on this map", TAG)
		PublishRecord(true, _get_user_id(id), Milliseconds, systime)
	}

	else if (Player[record])
	{
		if (Milliseconds < Player[record])
		{
			PublishRecord(false, _get_user_id(id), Milliseconds, systime)
			client_print_color(id, print_team_blue, "%s ^1New record (^3-%s ^1improvement)", TAG, Clock(Player[record] - Milliseconds))
		}

		else if (Milliseconds == Player[record])
		{
			client_print_color(id, print_team_default, "%s ^1You tie with your own record", TAG)
		}

		else
		{
			client_print_color(id, print_team_blue, "%s ^1Your best record is ^3%s", TAG, Clock(Player[record]))
		}
	}

	client_print_color(id, print_team_blue, "%s ^1%n won the round within ^3%s", TAG, id, Clock(Milliseconds))
}

public RefreshRecordman()
{
	recordman = has_record()
}

public ToggleTimer(id)
{
	if (recordman)
	{
		TimerToggler[id] >= 2 ? (TimerToggler[id] = 0) : TimerToggler[id]++
	}

	else
	{
		TimerToggler[id] = 0
	}
}

public PublishRecord(bool: improvement, player_id, new_record, systime)
{
	if (improvement)
	{
		SQL_ThreadQuery(MYSQL_CONNECTION, "IgnoredOutput", fmt("INSERT INTO `%s` VALUES(NULL, %d, %d, %d);", mapname, player_id, new_record, systime))
	}

	else
	{
		SQL_ThreadQuery(MYSQL_CONNECTION, "IgnoredOutput", fmt("UPDATE `%s` SET `record` = %d, `timestamp` = %d WHERE `player_id` = %d;", mapname, new_record, systime, player_id))
	}
}

public Start(id)
{
	Time[id] = get_gametime() - GetStartTime[id]
	new Milliseconds = floatround(Time[id] * 1000)
	recordman_percentage[id] = float(Milliseconds) / float(recordman) * 100.0

	set_dhudmessage(255, 204, 0, XPOS, YPOS, .holdtime=0.09, .fadeintime=0.0, .fadeouttime=0.09)
	show_dhudmessage(id, HudClock(Milliseconds, recordman_percentage[id], TimerToggler[id]))
}

public Respawn(id)
{
	id -= RESPAWN
	if (is_user_connected(id))
	{
		ExecuteHamB(Ham_CS_RoundRespawn, id)
	}
}

public IgnoredOutput(failState, Handle:query, const error[], errNum)
{
	RUNPRESCRIPT("IgnoredOutput")
}

public Clock(Milliseconds)
{
	return fmt("%d:%02d.%03dms", Milliseconds/1000/60, (Milliseconds/1000) % 60, Milliseconds % 1000)
}

public HudClock(Milliseconds, Float: percentage, toggle)
{
	switch (toggle)
	{
		case 0: return fmt("%d:%02d.%03dms", Milliseconds/1000/60, (Milliseconds/1000) % 60, Milliseconds % 1000)
		case 1: return fmt("%.02f%%", percentage)
		case 2: return fmt("%d:%02d.%03dms^n%.02f%%", Milliseconds/1000/60, (Milliseconds/1000) % 60, Milliseconds % 1000, percentage)
	}

	return fmt("0:00.000ms")
}