#include <a_samp>
#include <fix>
#include <a_mysql>
#include <streamer>
#include <Pawn.cmd>
#include <sscanf2>
#include <foreach>
#include <Pawn.Regex>
#include <crashdetect>

#define 	MYSQL_HOST 	"localhost"
#define 	MYSQL_USER 	"root"
#define 	MYSQL_PASS 	""
#define 	MYSQL_BASE 	"project"

#define 	SCM   	SendClientMessage
#define 	SCMTA   SendClientMessageToAll
#define 	SPD   	ShowPlayerDialog

#define COLOR_WHITE   0xFFFFFFFF
#define COLOR_RED     0xFF0000FF



main()
{
	print("\n----------------------------------");
	print("--------NEW PROJECT STARTED---------");
	print("----------------------------------\n");
}

//==============================   Переменные  =================================

//------------------------------   Мусорка   -----------------------------------

new MySQL:dbHandle;
//------------------------------------------------------------------------------

//==============================================================================

enum player
{
	ID,
	NAME[MAX_PLAYER_NAME],
	PASSWORD[32],
}

new player_info[MAX_PLAYERS][player];

enum dialogs
{
	DLG_NONE,
	DLG_REG,
	DLG_REGEMAIL,
	DLG_LOG,
}

public OnGameModeInit()
{
	ConnectMySQL();
	return 1;
}

stock ConnectMySQL()
{
    dbHandle = mysql_connect(MYSQL_HOST, MYSQL_USER, MYSQL_PASS, MYSQL_BASE);
    switch(mysql_errno())
    {
    	case 0 : print("Подключение к MySql установленно");
    	default: print("MySql НЕ РАБОТАЕТ!!!");
    }
	mysql_log(ERROR | WARNING);
	mysql_set_charset("cp1251");
}

public OnGameModeExit()
{
	return 1;
}

public OnPlayerRequestClass(playerid, classid)
{
	return 1;
}

public OnPlayerConnect(playerid)
{
	GetPlayerName(playerid, player_info[playerid][NAME], MAX_PLAYER_NAME);
	static const fmt_query[] = "SELECT id FROM users WHERE name = '%s'";
	new query[sizeof(fmt_query[])+(-2+MAX_PLAYER_NAME)];
	format(query, sizeof(query), fmt_query, player_info[playerid][NAME]);
	mysql_tquery(dbHandle, query, "CheckRegistration", "i", playerid);
	return 1;
}

forward CheckRegistration(playerid);
public CheckRegistration(playerid)
{
	new rows;
	cache_get_row_count(rows);
	if(rows) ShowLogin(playerid);
	else ShowRegistration(playerid);
}

stock ShowLogin(playerid)
{
	SCM(playerid, COLOR_WHITE, "Игрок зарегистрирован");
}

stock ShowRegistration(playerid)
{
	new dialog[300+(-2+MAX_PLAYER_NAME)];
	format(dialog, sizeof(dialog),
		"{FFFFFF}Уважаемый {0089ff}%s {FFFFFF}, мы рады вас видеть на сервере.\n\
		Аккаунт с таким ником не зарегистрирован.\n\
		Для игры на сервере вы должны пройти регистрацию! \n\n\
		Придумайте пароль для вашего будущего аккаунта\n\
		{de0007}•Пароль должен состоять только из ластинсих букв и цифр\n\
		(от 8 до 32 символов)",
		player_info[playerid][NAME]
	);
	SPD(playerid, DLG_REG, DIALOG_STYLE_INPUT, "{de0007}Регистрация{FFFFFF} • Ввод пароля", dialog, "Далее", "Выход");
	
}

public OnPlayerDisconnect(playerid, reason)
{

	return 1;
}

public OnPlayerSpawn(playerid)
{
	return 1;
}

public OnPlayerDeath(playerid, killerid, reason)
{
	return 1;
}

public OnVehicleSpawn(vehicleid)
{
	return 1;
}

public OnVehicleDeath(vehicleid, killerid)
{
	return 1;
}

public OnPlayerText(playerid, text[])
{
	return 1;
}

public OnPlayerCommandText(playerid, cmdtext[])
{
	return 0;
}

public OnPlayerEnterVehicle(playerid, vehicleid, ispassenger)
{
	return 1;
}

public OnPlayerExitVehicle(playerid, vehicleid)
{
	return 1;
}

public OnPlayerStateChange(playerid, newstate, oldstate)
{
	return 1;
}

public OnPlayerEnterCheckpoint(playerid)
{
	return 1;
}

public OnPlayerLeaveCheckpoint(playerid)
{
	return 1;
}

public OnPlayerEnterRaceCheckpoint(playerid)
{
	return 1;
}

public OnPlayerLeaveRaceCheckpoint(playerid)
{
	return 1;
}

public OnRconCommand(cmd[])
{
	return 1;
}

public OnPlayerRequestSpawn(playerid)
{
	return 1;
}

public OnObjectMoved(objectid)
{
	return 1;
}

public OnPlayerObjectMoved(playerid, objectid)
{
	return 1;
}

public OnPlayerPickUpPickup(playerid, pickupid)
{
	return 1;
}

public OnVehicleMod(playerid, vehicleid, componentid)
{
	return 1;
}

public OnVehiclePaintjob(playerid, vehicleid, paintjobid)
{
	return 1;
}

public OnVehicleRespray(playerid, vehicleid, color1, color2)
{
	return 1;
}

public OnPlayerSelectedMenuRow(playerid, row)
{
	return 1;
}

public OnPlayerExitedMenu(playerid)
{
	return 1;
}

public OnPlayerInteriorChange(playerid, newinteriorid, oldinteriorid)
{
	return 1;
}

public OnPlayerKeyStateChange(playerid, newkeys, oldkeys)
{
	return 1;
}

public OnRconLoginAttempt(ip[], password[], success)
{
	return 1;
}

public OnPlayerUpdate(playerid)
{
	return 1;
}

public OnPlayerStreamIn(playerid, forplayerid)
{
	return 1;
}

public OnPlayerStreamOut(playerid, forplayerid)
{
	return 1;
}

public OnVehicleStreamIn(vehicleid, forplayerid)
{
	return 1;
}

public OnVehicleStreamOut(vehicleid, forplayerid)
{
	return 1;
}

public OnDialogResponse(playerid, dialogid, response, listitem, inputtext[])
{
	switch(dialogid)
	{
  		case DLG_REG:
  		{
  		    if(response)
		  	{
				if(!strlen(inputtext))
				{
				    ShowRegistration(playerid);
				    return SCM(playerid, COLOR_RED, "[Ошибка] {FFFFFF} Введите пароль в поле ниже и нажмите далее");
				}
				if(strlen(inputtext) < 8 || strlen(inputtext) > 32)
				{
    				ShowRegistration(playerid);
				    return SCM(playerid, COLOR_RED, "[Ошибка] {FFFFFF} Длина пароля должна быть от 8 до 32 символов");
				}
				new regex:rg_passwordcheck = regex_new("^[a-zA-Z0-9]{1,}$$");
				if(regex_check(inputtext, rg_passwordcheck))
				{
					strmid(player_info[playerid][PASSWORD], inputtext, 0, strlen(inputtext), 32);
					SPD(playerid, DLG_REGEMAIL, DIALOG_STYLE_INPUT, "{de0007}Регистрация{FFFFFF} • Ввод Email",
						"{FFFFFF}Введите ваш Email-адрес\n\
		 				Если вы потеряете доступ к аккаунту, то сможете восстановить его с помощью Email\n\
					 	Введите его в поле ниже и нажмите \"Далее\"",
					"Далее","");
				}
				else
				{
					ShowRegistration(playerid);
				    return SCM(playerid, COLOR_RED, "[Ошибка] {FFFFFF} Пароль может состоять только из латинских символов и цифр");
				}
  		    }
			else
			{
				SCM(playerid, COLOR_RED, "Используйте \"/q\" чтобы покинуть сервер");
				SPD(playerid, -1, 0, " ", " ", " ", "");
				return Kick(playerid);
			}
		
  		    
  		}
	}
	return 1;
}

public OnPlayerClickPlayer(playerid, clickedplayerid, source)
{
	return 1;
}
