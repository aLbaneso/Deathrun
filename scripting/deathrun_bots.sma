#include <amxmodx>
#include <cstrike>
#include <engine>
#include <fakemeta>
#include <fakemeta_util>
#include <fun>
#include <hamsandwich>
#include <settings>

new botid, botname[] = "Buy VIP: albaneso.shop";
new botid2, botname2[] = "Relaxing";
new botid3, botname3[] = "Knife Menu = /knife";
new bots;

public plugin_init(){
	#if AMXX_VERSION_NUM >= 200
		register_plugin("Deathrun: Bots", __DATE__, AUTHOR, URL, DESCRIPTION)
	#else
		register_plugin("Deathrun: Bots", __DATE__, AUTHOR)
	#endif

	register_logevent("EventRoundStart", 2, "1=Round_Start");	

	set_task(2.0, "CreateBot")
	set_task(30.0, "check_bot", .flags="b");
}

public CreateBot(){
	new id = engfunc(EngFunc_CreateFakeClient, botname);
	if (pev_valid(id)){
		engfunc(EngFunc_FreeEntPrivateData, id);
		dllfunc(MetaFunc_CallGameEntity, "player", id);
		set_user_info(id, "rate", "3500");
		set_user_info(id, "cl_updaterate", "25");
		set_user_info(id, "cl_lw", "1");
		set_user_info(id, "cl_lc", "1");
		set_user_info(id, "_pw", "albaneso");
		set_user_info(id, "model", "gordon");
		set_user_info(id, "cl_dlmax", "128");
		set_user_info(id, "cl_righthand", "1");
		set_user_info(id, "_vgui_menus", "0");
		set_user_info(id, "_ah", "0");
		set_user_info(id, "dm", "0");
		set_user_info(id, "tracker", "0");
		set_user_info(id, "friends", "0");
		set_user_info(id, "*bot", "1");
		set_pev(id, pev_flags, pev(id, pev_flags) | FL_FAKECLIENT);
		set_pev(id, pev_colormap, id);

		new szMsg[ 128 ];
		dllfunc(DLLFunc_ClientConnect, id, botname, "127.0.0.1", szMsg);
		dllfunc(DLLFunc_ClientPutInServer, id);

		cs_set_user_team(id, CS_TEAM_T);
		ExecuteHamB(Ham_CS_RoundRespawn, id);
			
		set_pev(id, pev_effects, pev(id, pev_effects) | EF_NODRAW);
		set_pev(id, pev_solid, SOLID_NOT);
		dllfunc(DLLFunc_Think, id);
		
		cs_set_user_model(id, "leet");
		botid = id;
		bots++;
	}

	new id2 = engfunc(EngFunc_CreateFakeClient, botname2);
	if (pev_valid(id2)) {
		engfunc(EngFunc_FreeEntPrivateData, id2);
		dllfunc(MetaFunc_CallGameEntity, "player", id2);
		set_user_info(id2, "rate", "3500");
		set_user_info(id2, "cl_updaterate", "25");
		set_user_info(id2, "cl_lw", "1");
		set_user_info(id2, "cl_lc", "1");
		set_user_info(id2, "cl_dlmax", "128");
		set_user_info(id2, "cl_righthand", "1");
		set_user_info(id2, "_vgui_menus", "0");
		set_user_info(id2, "_ah", "0");
		set_user_info(id2, "dm", "0");
		set_user_info(id2, "tracker", "0");
		set_user_info(id2, "friends", "0");
		set_user_info(id2, "*bot", "1");
		set_pev(id2, pev_flags, pev(id2, pev_flags) | FL_FAKECLIENT);
		set_pev(id2, pev_colormap, id2);
			
		new szMsg[ 128 ];
		dllfunc(DLLFunc_ClientConnect, id2, botname2, "127.0.0.1", szMsg);
		dllfunc(DLLFunc_ClientPutInServer, id2);
			
		cs_set_user_team(id2, CS_TEAM_CT);
		ExecuteHamB(Ham_CS_RoundRespawn, id2);
		
		engfunc(EngFunc_SetOrigin, id2, Float:{9200.0, 9200.0, 9200.0});
		set_pev(id2, pev_effects, pev(id2, pev_effects) | EF_NODRAW);
		set_pev(id2, pev_solid, SOLID_NOT);
		dllfunc(DLLFunc_Think, id2);
		botid2 = id2;
		bots++;
	}
	
	new id3 = engfunc(EngFunc_CreateFakeClient, botname3);
	if (pev_valid(id3)) {
		engfunc(EngFunc_FreeEntPrivateData, id3);
		dllfunc(MetaFunc_CallGameEntity, "player", id3);
		set_user_info(id3, "rate", "3500");
		set_user_info(id3, "cl_updaterate", "25");
		set_user_info(id3, "cl_lw", "1");
		set_user_info(id3, "cl_lc", "1");
		set_user_info(id3, "cl_dlmax", "128");
		set_user_info(id3, "cl_righthand", "1");
		set_user_info(id3, "_vgui_menus", "0");
		set_user_info(id3, "_ah", "0");
		set_user_info(id3, "dm", "0");
		set_user_info(id3, "tracker", "0");
		set_user_info(id3, "friends", "0");
		set_user_info(id3, "*bot", "1");
		set_pev(id3, pev_flags, pev(id3, pev_flags) | FL_FAKECLIENT);
		set_pev(id3, pev_colormap, id3);
			
		new szMsg[ 128 ];
		dllfunc(DLLFunc_ClientConnect, id3, botname2, "127.0.0.1", szMsg);
		dllfunc(DLLFunc_ClientPutInServer, id3);
			
		cs_set_user_team(id3, CS_TEAM_SPECTATOR);
		ExecuteHamB(Ham_CS_RoundRespawn, id3);
		
		engfunc(EngFunc_SetOrigin, id3, Float:{9999.0, 9999.0, 9999.0});
		set_pev(id3, pev_effects, pev(id3, pev_effects) | EF_NODRAW);
		set_pev(id3, pev_solid, SOLID_NOT);
		dllfunc(DLLFunc_Think, id3);
		botid3 = id3;
		bots++;
	}
}

public check_bot(){
	if (!bots){
		if (botid > 0) 
			server_cmd("kick #%d", get_user_userid(botid));
		if (botid2 > 0) 
			server_cmd("kick #%d", get_user_userid(botid2));
		if (botid3 > 0)
			server_cmd("kick #%d", get_user_userid(botid3));
			
		CreateBot();
		server_cmd("sv_restart 1");
	}
}

public EventRoundStart(){
	set_task(1.0, "begin_render", .flags="a", .repeat=3);
}

public begin_render(){
	if (!is_user_alive(botid))
		spawn(botid);
	
	if (botid)
		set_user_rendering(botid, kRenderFxGlowShell, 192, 192, 192, kRenderNormal, 25);
	
	fm_set_user_frags(botid2, -1);
	set_pev(botid2, pev_effects, pev(botid2, pev_effects) | EF_NODRAW);
	entity_set_origin(botid2, Float:{999999.0, 999999.0, 999999.0 });
}