#include <amxmodx>
#include <amxmisc>
#include <cstrike>
#include <engine>
#include <fakemeta>
#include <fakemeta_util>
#include <fun>
#include <hamsandwich>
#include <settings>

// Credit goes to Kpoluk for Movement Player

#define FLAG_GROUND 	(1 << 7)
#define FLAG_JUMP 		(1 << 6)
#define FLAG_DUCK 		(1 << 5)
#define FLAG_USE  		(1 << 4)
#define FLAG_FORWARD	(1 << 3)
#define FLAG_BACK		(1 << 2)
#define FLAG_MOVELEFT	(1 << 1)
#define FLAG_MOVERIGHT	(1 << 0)
#define NUM_THREADS		100
#define LOAD_MOVEMENT_TASK 4000

new Array:ArrayOrigins
new Array:ArrayAngles
new Array:ArrayBytes

new const bot_classname[] = "bot_class"

new bot_id, bot_entity, bot_name[] = "Record Bot"
new frame_counter, finish_frame
new player_sound, step_left, bool:old_jump
new Float:origin[3], Float:angle[3], byte
new file, datadir[256], mapname[MAX_NAME_LENGTH]
new Float: timer, bool: reload

public plugin_init()
{
	register_plugin("Deathrun: Movement Player", __DATE__, "Kpoluk")

	RegisterHam(Ham_TakeDamage, "player", "PlayerTakeDamage", false)
	register_forward(FM_CheckVisibility, "CheckVisibility")
	register_event("HLTV", "NewRound", "a", "1=0", "2=0")

	bot_entity = create_entity("info_target")
	register_think(bot_classname, "fwdBotThink")
	set_pev(bot_entity, pev_classname, bot_classname)

	get_mapname(mapname, charsmax(mapname))
	strtolower(mapname)

	get_datadir(datadir, charsmax(datadir))
	add(datadir, charsmax(datadir), fmt("/records/%s/top.run", mapname))
	set_task(10.0, "StartBot")

	ArrayOrigins = ArrayCreate(3)
	ArrayAngles = ArrayCreate(3)
	ArrayBytes = ArrayCreate(1)
}

public plugin_cfg()
{
	set_cvar_num("mp_autoteambalance", 0)

	file = fopen(datadir, "rb")
	if (file)
	{
		timer = get_gametime()
		set_task(0.1, "AllocateMovements", LOAD_MOVEMENT_TASK, .flags="b")
	}
}

public plugin_precache()
{
	precache_sound("player/pl_step1.wav")
	precache_sound("player/pl_step3.wav")
	precache_sound("player/pl_step2.wav")
	precache_sound("player/pl_step4.wav")
}

public plugin_end()
{
	ArrayDestroy(ArrayOrigins)
	ArrayDestroy(ArrayAngles)
	ArrayDestroy(ArrayBytes)
}

public AllocateMovements()
{
	for(new i = 0; i < NUM_THREADS; i++)
	{
		fread(file, _:origin[0], BLOCK_INT)
		fread(file, _:origin[1], BLOCK_INT)
		fread(file, _:origin[2], BLOCK_INT)
		ArrayPushArray(ArrayOrigins, origin)

		fread(file, _:angle[0], BLOCK_INT)
		fread(file, _:angle[1], BLOCK_INT)
		fread(file, _:angle[2], BLOCK_INT)
		ArrayPushArray(ArrayAngles, angle)

		fread(file, byte, BLOCK_BYTE)
		ArrayPushCell(ArrayBytes, byte)

		if(feof(file))
			break
	}

	if(feof(file))
	{
		remove_task(LOAD_MOVEMENT_TASK)
		finish_frame = ArraySize(ArrayBytes) - 1
		fclose(file)
		client_print_color(0, print_team_blue, "%s ^3Record Bot ^1loaded in ^3%.02f ^1seconds", TAG, get_gametime() - timer)
		if (reload)
		{
			set_pev(bot_entity, pev_nextthink, get_gametime() + 0.01)
			reload = false
		}
	}
}

public StartBot()
{
	if (bot_id)
	{
		kickBot()
	}

	if (file)
	{
		createBot()
	}
}

public NewRound()
{
	if (bot_id)
	{
		fm_set_user_frags(bot_id, -2)
		fm_give_item(bot_id, "weapon_knife")
		fm_give_item(bot_id, "weapon_usp")
		fm_set_user_godmode(bot_id, 1)
		set_user_rendering(bot_id,kRenderFxNone,0,0,0,kRenderTransAlpha,105)
	}
	
	frame_counter = 0
	player_sound = 0
	step_left = 0
	old_jump = false
}

public NewTopRecord(id)
{
	if (!bot_id)
	{
		frame_counter = 0
		createBot()
	}

	frame_counter = 0
	player_sound = 0
	step_left = 0
	old_jump = false
	reload = true

	ArrayClear(ArrayOrigins)
	ArrayClear(ArrayAngles)
	ArrayClear(ArrayBytes)

	set_task(1.0, "ReloadBot")
}

public ReloadBot()
{
	plugin_cfg()
	// StartBot()
}


public CheckVisibility(id, pset)
{		
	if(id == bot_id)
	{
		forward_return(FMV_CELL, 1)
		return FMRES_SUPERCEDE
	}
	
	return FMRES_IGNORED
}

public PlayerTakeDamage(victim, weapon, attacker, Float:damage, damagebits)
{
	if(victim == bot_id)
		return(HAM_SUPERCEDE)

	return(HAM_IGNORED)
}

public createBot()
{
	static szRejectReason[128]
	bot_id = engfunc(EngFunc_CreateFakeClient, bot_name)
	set_user_info(bot_id, "model", "urban")
	set_user_info(bot_id, "rate", "3500")
	set_user_info(bot_id, "cl_updaterate", "30")
	set_user_info(bot_id, "cl_lw", "0")
	set_user_info(bot_id, "cl_lc",	"0")
	set_user_info(bot_id, "tracker", "0")
	set_user_info(bot_id, "cl_dlmax", "128")
	set_user_info(bot_id, "lefthand", "1")
	set_user_info(bot_id, "friends", "0")
	set_user_info(bot_id, "dm", "0")
	set_user_info(bot_id, "ah", "1")
	set_user_info(bot_id, "*bot", "1")
	set_user_info(bot_id, "_cl_autowepswitch", "1")
	set_user_info(bot_id, "_vgui_menu", "0")
	set_user_info(bot_id, "_vgui_menus", "0")

	dllfunc(DLLFunc_ClientConnect, bot_id, bot_name, "127.0.0.1", szRejectReason)
	dllfunc(DLLFunc_ClientPutInServer, bot_id)
	set_pev(bot_id, pev_spawnflags, pev(bot_id, pev_spawnflags) | FL_FAKECLIENT)
	set_pev(bot_id, pev_flags, pev(bot_id, pev_flags) | FL_FAKECLIENT)
	cs_set_user_team(bot_id, CS_TEAM_CT)
	fm_cs_user_spawn(bot_id)
	fm_give_item(bot_id, "weapon_knife")
	fm_give_item(bot_id, "weapon_usp")
	fm_set_user_godmode(bot_id, 1)
	set_pev(bot_id, pev_framerate, 1.0)
	set_pev(bot_entity, pev_nextthink, get_gametime() + 0.01)
	frame_counter = 0
}

public kickBot()
{
	fclose(file)
	server_cmd("kick #%d", get_user_userid(bot_id))
	bot_id = 0
	player_sound = 0
	step_left = 0
	old_jump = false
}


public fwdBotThink(iEnt)
{
	if(bot_id > 0 && ArraySize(ArrayBytes))
	{
		if(is_user_bot(bot_id))
		{
			botThink(bot_id)
			set_pev(iEnt, pev_nextthink, get_gametime() + 0.01)
		}
		else bot_id = 0
	}
}

public botThink(id)
{
	byte = ArrayGetCell(ArrayBytes, frame_counter)

	new bool:bGround = (byte & FLAG_GROUND)? true : false
	new bool:bJump = (byte & FLAG_JUMP)? true : false
	new bool:bDuck = (byte & FLAG_DUCK)? true : false

	new Float:oldX = origin[0]
	new Float:oldY = origin[1]

	ArrayGetArray(ArrayOrigins, frame_counter, origin)
	ArrayGetArray(ArrayAngles, frame_counter, angle)

	new Float:sqr_speed = (origin[0] - oldX) * (origin[0] - oldX) + (origin[1] - oldY) * (origin[1] - oldY)

	new Float:flVelocity[3]
	flVelocity[0] = (origin[0] - oldX) * 100.0
	flVelocity[1] = (origin[1] - oldY) * 100.0
	flVelocity[2] = 0.0
	set_pev(id, pev_velocity, flVelocity)
	set_pev(id, pev_origin, origin)

	set_pev(id, pev_v_angle, angle)
	angle[0] /= -3.0
	set_pev(id, pev_angles, angle)
	set_pev(id, pev_fixangle, 1)

	set_pev(id, pev_movetype, MOVETYPE_NONE)
	set_pev(id, pev_solid, SOLID_NOT)

	new iButton = 0

	if(bDuck)
		iButton |= IN_DUCK
	if(bJump)
		iButton |= IN_JUMP
	if(byte & FLAG_FORWARD)
		iButton |= IN_FORWARD
	if(byte & FLAG_BACK)
		iButton |= IN_BACK
	if(byte & FLAG_MOVELEFT)
		iButton |= IN_MOVELEFT
	if(byte & FLAG_MOVERIGHT)
		iButton |= IN_MOVERIGHT

	set_pev(id, pev_button, iButton)
	set_pev(id, pev_sequence, 19)

	new bool:bDucking = bDuck
	new Float:dest[3]
	dest[0] = origin[0]
	dest[1] = origin[1]
	dest[2] = origin[2] - 18.0

	new ptr = create_tr2()
	engfunc(EngFunc_TraceHull, origin, dest, 0, HULL_HEAD, id, ptr)
	new Float:flFraction
	get_tr2(ptr, TR_flFraction, flFraction)
	get_tr2(ptr, TR_vecPlaneNormal, dest)
	free_tr2(ptr)

	if(flFraction < dest[2] - 0.01)
		bDucking = true

	if(bGround)
	{
		if(bJump)
			set_pev(id, pev_gaitsequence, 6)

		else
		{
			if(bDucking)
			{
				if(sqr_speed > 0.0)
					set_pev(id, pev_gaitsequence, 5)
				else
					set_pev(id, pev_gaitsequence, 2)
			}
			else
			{
				if(sqr_speed > 1.35 * 1.35)
					set_pev(id, pev_gaitsequence, 4)
				else if(sqr_speed > 0.0)
					set_pev(id, pev_gaitsequence, 3)
				else
					set_pev(id, pev_gaitsequence, 1)
			}
		}
	}
	else
	{
		if(bDuck)
			set_pev(id, pev_gaitsequence, 2)
		else
			set_pev(id, pev_gaitsequence, 6)
	}


	if(bGround && sqr_speed > 1.5 * 1.5)
	{			
		if(bJump && !old_jump)
			player_sound = 0

		playbackSound(id)
	}

	player_sound -= 10
	old_jump = bJump
	frame_counter++

	if(frame_counter >= finish_frame)
		frame_counter = 0

	return
}

public playbackSound(id)
{
	if(player_sound > 0)
		return
	
	step_left = !step_left
	new irand = random_num(0, 1) + (step_left * 2)

	player_sound = 300
	
	switch(irand)
	{
		case 0:	emit_sound(id, CHAN_BODY, "player/pl_step1.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
		case 1:	emit_sound(id, CHAN_BODY, "player/pl_step3.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
		case 2:	emit_sound(id, CHAN_BODY, "player/pl_step2.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
		case 3:	emit_sound(id, CHAN_BODY, "player/pl_step4.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
	}
	
	return
}