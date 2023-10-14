#include <amxmodx>
#include <settings>

native _get_user_id(id)

new bool: pass[MAX_PLAYERS + 1] = false
new mapname[MAX_NAME_LENGTH]

public plugin_init()
{
	#if AMXX_VERSION_NUM >= 200
		register_plugin("Deathrun: Player Commands", __DATE__, AUTHOR, URL, DESCRIPTION)
	#else
		register_plugin("Deathrun: Player Commands", __DATE__, AUTHOR)
	#endif

	register_clcmd("say id", "clcmd_id")
	register_clcmd("say stats", "clcmd_stats")
	register_clcmd("say best", "clcmd_best")
	register_clcmd("say top15", "clcmd_top15")

	get_mapname(mapname, charsmax(mapname))
	strtolower(mapname)
}

public UserLogin(id)
{
	pass[id] = true
}

public client_disconnected(id)
{
	pass[id] = false
}

public clcmd_id(id)
{
	client_print_color(id, print_team_blue, "%s ^1Your ID is ^4%d ^3%s", TAG, _get_user_id(id), pass ? "passing" : "failing")
}

public clcmd_stats(id)
{
	show_motd(id, fmt("%s/player.php?id=%d", WEBSITE, _get_user_id(id)), "My Records")
}

public clcmd_best(id)
{
	show_motd(id, fmt("%s/player.php", WEBSITE), "Best Players")
}

public clcmd_top15(id)
{
	show_motd(id, fmt("%s/index.php?map=%s", WEBSITE, mapname), fmt("%s Records", mapname))
}