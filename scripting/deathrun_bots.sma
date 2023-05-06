#include <amxmodx>
#include <cstrike>
#include <engine>
#include <fakemeta>
#include <fakemeta_util>
#include <fun>
#include <hamsandwich>
#include <settings>

enum BotSettings{
	botid,
	botname[MAX_NAME_LENGTH],
	CsTeams:botteam
}

new Bot[][BotSettings] = {
	{ 0, T_BOTNAME,		CS_TEAM_T },
	{ 0, CT_BOTNAME,	CS_TEAM_CT },
	{ 0, SPEC_BOTNAME,	CS_TEAM_SPECTATOR }
}

public plugin_init(){
	#if AMXX_VERSION_NUM >= 200
		register_plugin("Deathrun: Bots", __DATE__, AUTHOR, URL, DESCRIPTION)
	#else
		register_plugin("Deathrun: Bots", __DATE__, AUTHOR)
	#endif

	register_logevent("EventRoundStart", 2, "1=Round_Start")	
	
	set_task(2.0, "CreateBots")
	set_task(30.0, "check_bot", .flags="b")
}

public client_disconnected(id){
	if (id > 0){
		for (new i = 0; i < sizeof(Bot); i++){
			if (id == Bot[i][botid]){
				Bot[i][botid] = 0
			}
		}
	}
}

public CreateBots(){
	for (new i = 0; i < sizeof(Bot); i++){
		CreateBot(Bot[i][botid], Bot[i][botname], Bot[i][botteam])
	}
}

public check_bot(){
	new bool: missing_bot = false
	
	for (new i = 0; i < sizeof(Bot); i++){
		if (Bot[i][botid] == 0){
			missing_bot = true
			server_print("Bot %s is not on the server", Bot[i][botname])
			CreateBot(Bot[i][botid], Bot[i][botname], Bot[i][botteam])
		}
	}
	
	if (missing_bot == true){
		set_cvar_num("sv_restart", 1)
	}
}

public EventRoundStart(){
	set_task(1.0, "begin_render", .flags="a", .repeat=3)
}

public begin_render(){
	if (!is_user_alive(Bot[0][botid]))
		spawn(Bot[0][botid])
	
	if (Bot[0][botid])
		set_user_rendering(Bot[0][botid], kRenderFxGlowShell, 192, 192, 192, kRenderNormal, 25)

	fm_set_user_frags(Bot[1][botid], -1)
	set_pev(Bot[1][botid], pev_effects, pev(Bot[1][botid], pev_effects) | EF_NODRAW)
	entity_set_origin(Bot[1][botid], Float:{999999.0, 999999.0, 999999.0 })
	
}

stock CreateBot(&_botid, const name[], CsTeams:team){
	new id = engfunc(EngFunc_CreateFakeClient, name)
	if (pev_valid(id)){
		engfunc(EngFunc_FreeEntPrivateData, id)
		dllfunc(MetaFunc_CallGameEntity, "player", id)
		set_user_info(id, "rate", "3500")
		set_user_info(id, "cl_updaterate", "25")
		set_user_info(id, "cl_lw", "1")
		set_user_info(id, "cl_lc", "1")
		set_user_info(id, "_pw", "aLbaneso-Bot")
		set_user_info(id, "model", "gordon")
		set_user_info(id, "cl_dlmax", "128")
		set_user_info(id, "cl_righthand", "1")
		set_user_info(id, "_vgui_menus", "0")
		set_user_info(id, "_ah", "0")
		set_user_info(id, "dm", "0")
		set_user_info(id, "tracker", "0")
		set_user_info(id, "friends", "0")
		set_user_info(id, "*bot", "1")
		set_pev(id, pev_flags, pev(id, pev_flags) | FL_FAKECLIENT)
		set_pev(id, pev_colormap, id)
		
		new szMsg[128]
		dllfunc(DLLFunc_ClientConnect, id, botname, "127.0.0.1", szMsg)
		dllfunc(DLLFunc_ClientPutInServer, id)
		
		cs_set_user_team(id, team)
		ExecuteHamB(Ham_CS_RoundRespawn, id)
		
		if (team != CS_TEAM_T){
			engfunc(EngFunc_SetOrigin, id, Float:{9200.0, 9200.0, 9200.0})
		}
		
		else {
			cs_set_user_model(id, "leet")
		}
		
		set_pev(id, pev_effects, pev(id, pev_effects) | EF_NODRAW)
		set_pev(id, pev_solid, SOLID_NOT)
		dllfunc(DLLFunc_Think, id)
		
		_botid = id
		server_print("Bot %s ID[%d] is now active ", name, _botid)
	}

	else {
		set_fail_state("Can't create Bot %s", name)
	}
}