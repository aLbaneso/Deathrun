#define AUTHOR "big"
#define URL "github.com/aLbaneso"
#define DESCRIPTION "Made with <3"
#define TAG "^4[INFO]"
#define WEBSITE "http://example.com"

#define MYSQL_HOST "0.0.0.0"
#define MYSQL_USER "server"
#define MYSQL_PASSWORD "server"
#define MYSQL_DATABASE "server"
#define MYSQL_TABLE "players"
#define MAPLIST "maplist"

#define RUNFAILTEST if(failState==TQUERY_CONNECT_FAILED)set_fail_state("Connection to database server failed")
#define RUNERRORTEST(%1) if(errNum)server_print("MYSQL Error # %s:%s:(%d)%s",PluginName,%1,errNum,error)
#define RUNPRESCRIPT(%1) RUNFAILTEST;RUNERRORTEST(%1)
#define GetPluginName get_plugin(-1,PluginName,charsmax(PluginName))

#define T_BOTNAME "Buy VIP: shop.example.com"
#define CT_BOTNAME "Relaxing"
#define SPEC_BOTNAME "Knife Menu = /knife"

#define CHANNEL_RECORDMAN 2