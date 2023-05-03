#include <amxmodx>
#include <geoip>
#include <sqlx>
#include <settings>

#define GEOIP "geoip"

native _get_user_id(id)

new PluginName[MAX_NAME_LENGTH]
new Handle:MYSQL_CONNECTION

public plugin_init(){
	#if AMXX_VERSION_NUM >= 200
		register_plugin("Deathrun: MySQL GeoIP", __DATE__, AUTHOR, URL, DESCRIPTION)
	#else
		register_plugin("Deathrun: MySQL GeoIP", __DATE__, AUTHOR)
	#endif

	GetPluginName
}

public plugin_cfg(){
	MYSQL_Init()
}

public MYSQL_Init(){
	MYSQL_CONNECTION = SQL_MakeDbTuple(MYSQL_HOST, MYSQL_USER, MYSQL_PASSWORD, MYSQL_DATABASE)

	SQL_ThreadQuery(MYSQL_CONNECTION, "IgnoredOutput", fmt("CREATE TABLE IF NOT EXISTS `%s` (\
		`id` INT(4) NOT NULL,\
		`country_code` VARCHAR(4) NOT NULL,\
		`timestamp` INT(4) NOT NULL,\
	PRIMARY KEY (`id`));", GEOIP))
}

public UserLogin(id){
	new UserIP[MAX_NAME_LENGTH], CountryCode[3], systime = get_systime()
	get_user_ip(id, UserIP, charsmax(UserIP))

	if (geoip_code2_ex(UserIP, CountryCode)){
		SQL_ThreadQuery(MYSQL_CONNECTION, "IgnoredOutput",
			fmt("INSERT INTO `%s` VALUES(%d, ^"%s^", %d) ON DUPLICATE KEY UPDATE `country_code` = ^"%s^", `timestamp` = %d;", GEOIP, _get_user_id(id), CountryCode, systime, CountryCode, systime))
	}
}

public IgnoredOutput(failState, Handle:query, const error[], errNum){
	RUNPRESCRIPT("IgnoredOutput")
}