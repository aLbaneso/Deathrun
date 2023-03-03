#include <amxmodx>
#include <settings>

native _get_user_id(id)

new bool: pass[MAX_PLAYERS + 1] = false

public plugin_init(){
	#if AMXX_VERSION_NUM >= 200
		register_plugin("Deathrun: Player ID", __DATE__, AUTHOR, URL, DESCRIPTION)
	#else
		register_plugin("Deathrun: Player ID", __DATE__, AUTHOR)
	#endif
	register_clcmd("say id", "clcmd_id")
}

public UserLogin(id)
	pass[id] = true

public client_disconnected(id)
	pass[id] = false

public clcmd_id(id){
	client_print(id, print_chat, "Your ID is %d %s", _get_user_id(id), pass ? "passing" : "failing")
}