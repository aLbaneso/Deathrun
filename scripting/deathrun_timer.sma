#include <amxmodx>
#include <amxmisc>
#include <fakemeta>
#include <hamsandwich>
#include <sqlx>
#include <settings>

// Credit goes to Kpoluk for Movement Recording

#define FLAG_GROUND 	(1 << 7)
#define FLAG_JUMP 		(1 << 6)
#define FLAG_DUCK 		(1 << 5)
#define FLAG_USE  		(1 << 4)
#define FLAG_FORWARD	(1 << 3)
#define FLAG_BACK  		(1 << 2)
#define FLAG_MOVELEFT	(1 << 1)
#define FLAG_MOVERIGHT	(1 << 0)

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

new Player[PlayerData], mapname[MAX_NAME_LENGTH], datadir[256]
new Float: GetStartTime[MAX_PLAYERS + 1], Float: Time[MAX_PLAYERS + 1]
new Float: intial_time[MAX_PLAYERS + 1], frames_afterinit[MAX_PLAYERS + 1], file[MAX_PLAYERS + 1], run_file[MAX_PLAYERS + 1][256]

native has_record()
new recordman, Float: recordman_percentage[MAX_PLAYERS + 1], TimerToggler[MAX_PLAYERS + 1]
new bool:isPlayer[MAX_PLAYERS + 1]

new forwardNewTopRecord, forwardNewTopRecordReturn
new Float: respawn

public plugin_init()
{
	#if AMXX_VERSION_NUM >= 200
		register_plugin("Deathrun: Timer", __DATE__, AUTHOR, URL, DESCRIPTION)
	#else
		register_plugin("Deathrun: Timer", __DATE__, AUTHOR)
	#endif

	register_forward(FM_PlayerPreThink, "PlayerPreThink")

	RegisterHam(Ham_Spawn, "player", "HookSpawn", 1)
	RegisterHam(Ham_Killed, "player", "HookKilled", 0)

	register_event("HLTV", "RefreshRecordman", "a", "1=0", "2=0")
	register_clcmd("showbriefing", "ToggleTimer")
	bind_pcvar_float(create_cvar("deathrun_timer", "2.3", .has_min=true, .min_val=0.0, .has_max=true, .max_val=5.0), respawn)

	forwardNewTopRecord = CreateMultiForward("NewTopRecord", ET_IGNORE, FP_CELL)

	get_mapname(mapname, charsmax(mapname))
	strtolower(mapname)
	get_datadir(datadir, charsmax(datadir))
	add(datadir, charsmax(datadir), "/records")
	mkdir(datadir)
	add(datadir, charsmax(datadir), fmt("/%s", mapname))
	mkdir(datadir)

	set_task(3.0, "TimerCheck", .flags="b")

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

	if (run_file[id][0] != EOS)
	{
		delete_file(run_file[id])
	}

	ResetRun(id)
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
		StartRun(id)
		recordman_percentage[id] = 0.0

		set_task(0.09, "Start", id, .flags="b")
	}
}

public PlayerPreThink(id)
{
	if(is_user_alive(id) && file[id])
	{
		if(frames_afterinit[id] == 0)
			intial_time[id] = get_gametime()

		if(get_gametime() - intial_time[id] < frames_afterinit[id] * 0.01 - 0.0005)
			return PLUGIN_HANDLED

		frames_afterinit[id]++

		new Float:flOrigin[3]
		new Float:flAngle[3]

		pev(id, pev_origin, flOrigin)
		pev(id, pev_v_angle, flAngle)
		new iButton = pev(id, pev_button)
		
		fwrite(file[id], _:flOrigin[0], BLOCK_INT)
		fwrite(file[id], _:flOrigin[1], BLOCK_INT)
		fwrite(file[id], _:flOrigin[2], BLOCK_INT)

		fwrite(file[id], _:flAngle[0], BLOCK_INT)
		fwrite(file[id], _:flAngle[1], BLOCK_INT)
		fwrite(file[id], _:flAngle[2], BLOCK_INT)

		new navbuttons = 0
		if(pev(id, pev_flags) & FL_ONGROUND)
			navbuttons |= FLAG_GROUND
		if(iButton & IN_JUMP)
			navbuttons |= FLAG_JUMP
		if(iButton & IN_DUCK)
			navbuttons |= FLAG_DUCK
		if(iButton & IN_USE)
			navbuttons |= FLAG_USE
		if(iButton & IN_FORWARD)
			navbuttons |= FLAG_FORWARD
		if(iButton & IN_BACK)
			navbuttons |= FLAG_BACK
		if(iButton & IN_MOVELEFT)
			navbuttons |= FLAG_MOVELEFT
		if(iButton & IN_MOVERIGHT)
			navbuttons |= FLAG_MOVERIGHT

		fwrite(file[id], navbuttons, BLOCK_BYTE)
	}

	return PLUGIN_HANDLED
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
		if (respawn > 0.0)
		{
			set_task(respawn, "Respawn", Victim+RESPAWN)
		}
	}
}

public GameWin(id)
{
	Time[id] = get_gametime() - GetStartTime[id]
	new const Milliseconds = floatround(Time[id] * 1000)
	remove_task(id)
	ResetRun(id)

	Player[rank] = _get_user_rank(id)
	Player[record] = _get_user_record(id)
	Player[timestamp] = _get_user_timestamp(id)
	new const systime = get_systime()
	new const recordman_time = has_record()
	new ClockString[MAX_NAME_LENGTH]
	
	if (recordman_time)
	{
		if (Milliseconds < recordman_time)
		{
			if (!ExecuteForward(forwardNewTopRecord, forwardNewTopRecordReturn, id))
			{
				server_print("%s:Cannot execute forward", PluginName)
			}

			rename_file(run_file[id], fmt("%s/top.run", datadir), 1)
		}
	}

	else
	{
		if (!ExecuteForward(forwardNewTopRecord, forwardNewTopRecordReturn, id))
		{
			server_print("%s:Cannot execute forward", PluginName)
		}

		rename_file(run_file[id], fmt("%s/top.run", datadir), 1)
	}

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
			Clock(Player[record] - Milliseconds, ClockString, charsmax(ClockString))
			client_print_color(id, print_team_blue, "%s ^1New record (^3-%s ^1improvement)", TAG, ClockString)
		}

		else if (Milliseconds == Player[record])
		{
			client_print_color(id, print_team_default, "%s ^1You tie with your own record", TAG)
		}

		else
		{
			Clock(Player[record], ClockString, charsmax(ClockString))
			client_print_color(id, print_team_blue, "%s ^1Your best record is ^3%s", TAG, ClockString)
		}
	}

	Clock(Milliseconds, ClockString, charsmax(ClockString))
	client_print_color(id, print_team_blue, "%s ^1%n won the round within ^3%s", TAG, id, ClockString)
}

public TimerCheck()
{
	for (new i = 0; i <= MAX_PLAYERS; i++)
	{
		if (is_user_connected(i))
		{
			if (get_user_team(i) != 2)
			{
				remove_task(i)
			}
		}
	}
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
	// recordman_percentage[id] = float(Milliseconds) / float(recordman) * 100.0

	set_dhudmessage(255, 204, 0, XPOS, YPOS, .holdtime=0.09, .fadeintime=0.0, .fadeouttime=0.09)
	// show_dhudmessage(id, HudClock(Milliseconds, recordman_percentage[id], TimerToggler[id]))
	// show_dhudmessage(id, Clock(Milliseconds))
	show_dhudmessage(id, "%d:%02d.%03dms", Milliseconds/1000/60, (Milliseconds/1000) % 60, Milliseconds % 1000)
}

public Respawn(id)
{
	id -= RESPAWN
	if (is_user_connected(id) && get_user_team(id) == 2)
	{
		ExecuteHamB(Ham_CS_RoundRespawn, id)
	}
}

public IgnoredOutput(failState, Handle:query, const error[], errNum)
{
	RUNPRESCRIPT("IgnoredOutput")
}

public Clock(Milliseconds, String[], Length)
{
	formatex(String, Length, "%d:%02d.%03dms", Milliseconds/1000/60, (Milliseconds/1000) % 60, Milliseconds % 1000)
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

public StartRun(id)
{
	if (run_file[id][0] != EOS)
	{
		delete_file(run_file[id])
	}

	ResetRun(id)
	formatex(run_file[id], charsmax(run_file[]), "%s/%d.run", datadir, _get_user_id(id))
	file[id] = fopen(run_file[id], "wb")
}

public ResetRun(id)
{
	fclose(file[id])
	file[id] = 0
	frames_afterinit[id] = 0
}