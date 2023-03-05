#include <amxmodx>
#include <geoip>
#include <sqlx>
#include <settings>

#define GEOIP "geoip"

native _get_user_id(id)

new Handle:MYSQL_CONNECTION

public plugin_init(){
	#if AMXX_VERSION_NUM >= 200
		register_plugin("Deathrun: MySQL GeoIP", __DATE__, AUTHOR, URL, DESCRIPTION)
	#else
		register_plugin("Deathrun: MySQL GeoIP", __DATE__, AUTHOR)
	#endif
}

public plugin_cfg()
	MYSQL_Init()

public MYSQL_Init(){
	MYSQL_CONNECTION = SQL_MakeDbTuple(MYSQL_HOST, MYSQL_USER, MYSQL_PASSWORD, MYSQL_DATABASE)

	SQL_ThreadQuery(MYSQL_CONNECTION, "IgnoredOutput", fmt("CREATE TABLE IF NOT EXISTS `%s` (\
		`id` INT(4) NOT NULL,\
		`country_code` VARCHAR(4) NOT NULL,\
		`timestamp` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,\
		PRIMARY KEY (`id`));", GEOIP))
}

public UserLogin(id){
	new UserIP[32], CountryCode[3], pId
	pId = _get_user_id(id)
	get_user_ip(id, UserIP, charsmax(UserIP))

	if (geoip_code2_ex(UserIP, CountryCode))
		SQL_ThreadQuery(MYSQL_CONNECTION, "IgnoredOutput",
			fmt("INSERT INTO `%s` VALUES(%d, ^"%s^", NOW()) ON DUPLICATE KEY UPDATE `country_code` = ^"%s^";", GEOIP, pId, CountryCode, CountryCode))
}

public IgnoredOutput(failState, Handle:query, const error[], errNum)
	if (errNum) server_print("deathrun_addon_geoip:IgnoredOutput:(%d)%s", errNum, error)