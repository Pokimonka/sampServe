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
#define COLOR_GREY 	  0x00ff00AA



main()
{
	print("\n----------------------------------");
	print("--------NEW PROJECT STARTED---------");
	print("----------------------------------\n");
}

//==============================   Переменные  =================================

//------------------------------   Мусорка   -----------------------------------

new MySQL:dbHandle;
new PlayerAFK[MAX_PLAYERS];
new expmultiply = 4;
//------------------------------------------------------------------------------

//==============================================================================

enum player
{
	ID,
	NAME[MAX_PLAYER_NAME],
	PASSWORD[65],
	SALT[11],
	EMAIL[65],
	REF,
	SEX,
	RACE,
	AGE,
	SKIN,
	REGDATA[13],
	REGIP[16],
	ADMIN,
	MONEY,
	LVL,
	EXP,
	MINS,
}

new player_info[MAX_PLAYERS][player];

enum dialogs
{
	DLG_NONE,
	DLG_REG,
	DLG_REGEMAIL,
	DLG_REGREF,
	DLG_REGSEX,
	DLG_REGRACE,
	DLG_REGAGE,
	DLG_LOG,
}

public OnGameModeInit()
{
	ConnectMySQL();
	SetTimer("SecondUpdate", 1000, true);
	SetTimer("MinuteUpdate", 60000, true);

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

forward MinuteUpdate();
public MinuteUpdate()
{
	foreach(new i: Player)
	{
		if (PlayerAFK[i] < 2)
		{
			player_info[i][MINS]++;
			if (player_info[i][MINS] >= 60) 
			{
				player_info[i][MINS] = 0;
				PayDay(i);
			}
			static const fmt_query[] = "UPDATE users SET mins = '%d' WHERE id = '%d'";
			new query[sizeof(fmt_query)+(-2+2)+(-2+8)];
			format(query, sizeof(query), fmt_query, player_info[i][MINS], player_info[i][ID]);
			mysql_query(dbHandle, query, false);
		}
	}
}

stock PayDay(playerid) 
{
	SCM(playerid, COLOR_WHITE, "Зарплата");
	GiveExp(playerid, 1);
}

forward SecondUpdate();
public SecondUpdate()
{
	foreach(new i: Player)
	{
		PlayerAFK[i]++;
		if (PlayerAFK[i] >= 1)
		{
			new string[] = "{FF0000}AFK";
			if(PlayerAFK[i] < 60)
			{
				format(string, sizeof(string), "%s%d сек.", string, PlayerAFK);
			}
			else
			{
				new minute = floatround(PlayerAFK[1]/60, floatround_floor);
				new second = PlayerAFK[i] % 60;
				format(string, sizeof(string), "%s%d мин. %d сек.", string, minute, second);
			}
			SetPlayerChatBubble(i, string, -1, 20, 1000);
		}
	}
	return 1;
}

public OnPlayerRequestClass(playerid, classid)
{
	return 1;
}

public OnPlayerConnect(playerid)
{
	GetPlayerName(playerid, player_info[playerid][NAME], MAX_PLAYER_NAME);
	TogglePlayerSpectating(playerid, 1);

	InterpolateCameraPos(playerid, 1280.6528, -2037.6846, 75.6408+12.0, 13.4005, -2087.5444, 35.9909, 20000);
	InterpolateCameraLookAt(playerid, 446.5704, -2036.88773, 35.9909-12.0, 367.5072, -1855.4072, 11.2948, 20000);

	static const fmt_query[] = "SELECT pass, salt FROM users WHERE name = '%s'";
	new query[sizeof(fmt_query)+(-2+MAX_PLAYER_NAME)];
	format(query, sizeof(query), fmt_query, player_info[playerid][NAME]);
	mysql_tquery(dbHandle, query, "CheckRegistration", "i", playerid);
	SCM(playerid, COLOR_RED, player_info[playerid][NAME]);

	SetPVarInt(playerid, "WrongPassword", 3);
	return 1;
}

forward CheckRegistration(playerid);
public CheckRegistration(playerid)
{
	new rows;
	cache_get_row_count(rows);
	if(rows)
	{
		cache_get_value_name(0, "pass", player_info[playerid][PASSWORD], 65);
		cache_get_value_name(0, "salt", player_info[playerid][SALT], 11);
		ShowLogin(playerid);
	} 
	else ShowRegistration(playerid);
}

stock ShowLogin(playerid)
{
	new dialog[171+(-2+MAX_PLAYER_NAME)];
	format(dialog, sizeof(dialog), 
		"{FFFFFF}Уважаемый {0089ff}%s {FFFFFF}, с возвращением вас на {0089ff} YOUR RP {FFFFFF}\n\
		\tМы рады снова видеть вас\n\n\
		Для продолжения введите свой пароль в поле ниже:",
		player_info[playerid][NAME]
	);
	SPD(playerid, DLG_LOG, DIALOG_STYLE_INPUT, "{de0007}Авторизация{FFFFFF}", dialog, "Войти", "Выход");

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
	SPD(playerid, DLG_REG, DIALOG_STYLE_INPUT, "{de0007}Регистрация{FFFFFF} • Ввод пароля", dialog, "Войти", "Выход");
	
}

public OnPlayerDisconnect(playerid, reason)
{

	return 1;
}

public OnPlayerSpawn(playerid)
{
	if(GetPVarInt(playerid, "logged") == 0)
	{
		SCM(playerid, COLOR_RED, "[Ошибка] {FFFFFF}Для игры на сервере вы должны авторизоваться");
		return Kick(playerid);
	}
	SetPlayerSkin(playerid, player_info[playerid][SKIN]);
	SetPlayerScore(playerid, player_info[playerid][LVL]);
	switch(random(3))
	{
		case 0: 
		{
			SCM(playerid, COLOR_GREY, "0");
			SetPlayerPos(playerid, 1255.0641,-1691.6334,19.7344);
			SetPlayerFacingAngle(playerid, 90.0);
		}
		case 1:
		{
			SCM(playerid, COLOR_GREY, "0");
			SetPlayerPos(playerid, 1224.9067,-1692.1339,19.2270);
			SetPlayerFacingAngle(playerid, 270.0);
		}
		case 2:
		{
			SCM(playerid, COLOR_GREY, "0");
			SetPlayerPos(playerid, 1243.0892,-1699.7878,14.8672);
			SetPlayerFacingAngle(playerid, 180.0);
		}
	}
	SetCameraBehindPlayer(playerid);
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
	if(GetPVarInt(playerid, "logged") == 0)
	{
		SCM(playerid, COLOR_RED, "[Ошибка] {FFFFFF}Для напсиания сообщения в чате вы должны авторизоваться");
		return Kick(playerid);
	} 
	else 
	{
		new string[144];
		if (strlen(text) < 113) 
		{
			format(string, sizeof(string), "%s[%d]: %s", player_info[playerid][NAME], playerid, text);
			ProxDetector(20.0, playerid, string, COLOR_WHITE, COLOR_WHITE, COLOR_WHITE, COLOR_WHITE, COLOR_WHITE);
			SetPlayerChatBubble(playerid, text, COLOR_WHITE, 20, 7500);
			if (GetPlayerState(playerid) == PLAYER_STATE_ONFOOT)
			{
				ApplyAnimation(playerid, "PED", "IDLE_chat", 4.1, 0 ,1, 1, 1, 1);
				SetTimerEx("StopChatAnim", 3200, false, "d", playerid);
			}
		}
		else
		{
			SCM(playerid, COLOR_GREY, "Слишком длинное сообшение");
			return 0;
		}
	}
	return 0;
}

forward StopChatAnim(playerid);
public StopChatAnim(playerid) 
{
	ApplyAnimation(playerid, "PED", "facanger", 4.1, 0 ,1, 1, 1, 1);
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
	PlayerAFK[playerid] = 0;
	if(GetPlayerMoney(playerid) != player_info[playerid][MONEY])
	{
		ResetPlayerMoney(playerid);
		GivePlayerMoney(playerid, player_info[playerid][MONEY]);
	}
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
				if(!(8 <= (strlen(inputtext)) <= 32))
				{
    				ShowRegistration(playerid);
				    return SCM(playerid, COLOR_RED, "[Ошибка] {FFFFFF} Длина пароля должна быть от 8 до 32 символов");
				}
				new regex:rg_passwordcheck = regex_new("^[a-zA-Z0-9]{1,}$");
				if(regex_check(inputtext, rg_passwordcheck))
				{
				    new salt[11];
				    for (new i; i < 10; i++)
				    {
				        salt[i] = random(79) + 47;
					}
					salt[10] = 0;
					SHA256_PassHash(inputtext, salt, player_info[playerid][PASSWORD], 65);
					strmid(player_info[playerid][SALT], salt, 0, 11, 11);
					SPD(playerid, DLG_REGEMAIL, DIALOG_STYLE_INPUT, "{de0007}Регистрация{FFFFFF} • Ввод Email",
						"{FFFFFF}Введите ваш Email-адрес\n\
		 				Если вы потеряете доступ к аккаунту, то сможете восстановить его с помощью Email\n\
					 	Введите его в поле ниже и нажмите \"Далее\"",
					"Далее","");
				}
				else
				{
					ShowRegistration(playerid);
					regex_delete(rg_passwordcheck);
				    return SCM(playerid, COLOR_RED, "[Ошибка] {FFFFFF} Пароль может состоять только из латинских символов и цифр");
				}
				regex_delete(rg_passwordcheck);

  		    }
			else
			{
				SCM(playerid, COLOR_RED, "Используйте \"/q\" чтобы покинуть сервер");
				SPD(playerid, -1, 0, " ", " ", " ", "");
				return Kick(playerid);
			}
  		}
  		case DLG_REGEMAIL:
		{
			if(!strlen(inputtext))
			{
			    SPD(playerid, DLG_REGEMAIL, DIALOG_STYLE_INPUT, "{de0007}Регистрация{FFFFFF} • Ввод Email",
						"{FFFFFF}Введите ваш Email-адрес\n\
		 				Если вы потеряете доступ к аккаунту, то сможете восстановить его с помощью Email\n\
					 	Введите его в поле ниже и нажмите \"Далее\"",
				"Далее","");
				 return SCM(playerid, COLOR_RED, "[Ошибка] {FFFFFF} Введите Email в поле ниже и нажмите \"Далее\"");
			}
			new regex:rg_emailcheck = regex_new("^[a-zA-Z0-9._-]{1,43}@[a-zA-Z]{1,12}.[a-zA-Z]{1,8}$");
            if(regex_check(inputtext, rg_emailcheck))
			{
				strmid(player_info[playerid][EMAIL], inputtext, 0, strlen(inputtext), 64);
				SPD(playerid, DLG_REGREF, DIALOG_STYLE_INPUT, "{de0007}Регистрация{FFFFFF} • Ввод пригласившего",
				"{FFFFFF}Введи ник игрока, который тебя пригласил, в поле ниже",
				"Далее", "Пропустить");
				
			}
			else
			{
				SPD(playerid, DLG_REGEMAIL, DIALOG_STYLE_INPUT, "{de0007}Регистрация{FFFFFF} • Ввод Email",
					"{FFFFFF}Введите ваш Email-адрес\n\
	 				Если вы потеряете доступ к аккаунту, то сможете восстановить его с помощью Email\n\
				 	Введите его в поле ниже и нажмите \"Далее\"",
				"Далее","");
				regex_delete(rg_emailcheck);
			    return SCM(playerid, COLOR_RED, "[Ошибка] {FFFFFF} Укажите правильный Email");
			}
			regex_delete(rg_emailcheck);

		}
		case DLG_REGREF:
		{
		    if (response)
		    {
				static const fmt_query[] = "SELECT * FROM users WHERE name = '%s'";
				new query[sizeof(fmt_query[])+(-2+MAX_PLAYER_NAME)];
				format(query, sizeof(query), fmt_query, inputtext);
				mysql_tquery(dbHandle, query, "CheckReferal", "is", playerid, inputtext);
			}
		    else 
		    {
		        SPD(playerid, DLG_REGSEX, DIALOG_STYLE_MSGBOX, "{de0007}Регистрация{FFFFFF} • Выбор пола персонажа",
		        "{FFFFFF}Выберете пол вашего персонгажа",
		        "Мужской", "Женский");
			}
		}
		case DLG_REGSEX:
		{
			player_info[playerid][SEX] = (response) ? 1 : 2;
			SPD(playerid, DLG_REGRACE, DIALOG_STYLE_LIST, "{de0007}Регистрация{FFFFFF} • Выбор расы",
			"Негроидная\n\
			Европеоидная\n\
			Аизиатская",
			"Далее", "");
		}
		case DLG_REGRACE:
		{
			player_info[playerid][RACE] = listitem + 1;
			SPD(playerid, DLG_REGAGE, DIALOG_STYLE_INPUT, "{de0007}Регистрация{FFFFFF} • Выбор возраста",
			"{FFFFFF}Выберете возраст вашего персонгажа\n\
			{de0007}•Введите возраст от 18 до 60",
			"Далее", "");
		}
		case DLG_REGAGE:
		{
			if(!(18 <= (strval(inputtext)) <= 60))
			{
			     SPD(playerid, DLG_REGAGE, DIALOG_STYLE_INPUT, "{de0007}Регистрация{FFFFFF} • Выбор возраста",
				"{FFFFFF}Выберете возраст вашего персонгажа\n\
				{de0007}•Введите возраст от 18 до 60",
				"Далее", "");
				return SCM(playerid, COLOR_RED, "[Ошибка] Введите возраст от 18 до 60");
			} 
			player_info[playerid][AGE] = strval(inputtext);
			/*
			3 расы на каждый диапазон возраста
			18-29
			30-45
			46-60
			*/
			new regmaleskins[9][4] =
			{	{19,21,22,28}, //негроидная 18-29
				{24,25,36,67}, //негроидная 30-45
				{14,142,182,183}, //негроидная 46-60
				{29,96,101,26},//европиоидная 18-29
				{2,37,72,202}, //европиоидная 30-45
				{1,3,234,290}, //европиоидная 46-60
				{23,60,170,180}, //азиатская 18-29
				{20,47,48,206}, //азиатская 30-45
				{44,58,132,229} //азиатская 46-60
			};
			new regfemaleskins[9][2] =
			{	{13,69},
				{9,190},
				{10,218},
				{41,56},
				{31,151},
				{39,89},
				{169,193},
				{207,22},
				{54,130}
			};
			 new newskinindex;
			 switch(player_info[playerid][RACE])
			 {
 				case 2: newskinindex += 3;
 				case 3: newskinindex += 6;
			 }
			 switch(player_info[playerid][AGE])
			 {
 				case 30..45: newskinindex++;
 				case 46..60: newskinindex += 2;
			 }
			
			player_info[playerid][SKIN] = player_info[playerid][SEX] == 1 ? regmaleskins[newskinindex][random(4)] :  regfemaleskins[newskinindex][random(2)];
			new Year, Month, Day;
			getdate(Year, Month, Day);
			new date[12];
			format(date, sizeof(date), "%02d.%02d.%02d", Day, Month, Year);
			new ip[15];
   			GetPlayerIp(playerid, ip, sizeof(ip));
            static const fmt_query[] = "INSERT INTO users (name,  pass,  salt,  email,  ref,   sex,   race,   age,  skin, regdata, regip) VALUES ('%s',   '%s',    '%s',   '%s',  '%d',  '%d',   '%d',  '%d', '%d',   '%s',   '%s')";
			new query[sizeof(fmt_query)+(-2+MAX_PLAYER_NAME)+(-2+64)+(-2+10)+(-2+64)+(-2+8)+(-2+1)+(-2+1)+(-2+2)+(-2+3)+(-2+12)+(-2+15)];
			format(query, sizeof(query), fmt_query, player_info[playerid][NAME],
													player_info[playerid][PASSWORD],
													player_info[playerid][SALT],
													player_info[playerid][EMAIL],
													player_info[playerid][REF],
													player_info[playerid][SEX],
													player_info[playerid][RACE],
													player_info[playerid][AGE],
													player_info[playerid][SKIN],
													date,
													ip);
			mysql_query(dbHandle, query, false);
			static const fmt_query2[] = "SELECT * FROM users WHERE name = '%s' AND pass = '%s'";
			format(query, sizeof(query), fmt_query2,  player_info[playerid][NAME], player_info[playerid][PASSWORD]);
			mysql_tquery(dbHandle, query, "PlayerLogin", "i", playerid);
		}
		case DLG_LOG:
		{
			if(response)
		  	{
				new checkpass[65];
				SHA256_PassHash(inputtext, player_info[playerid][SALT], checkpass, 65);
				if(!strcmp(player_info[playerid][PASSWORD], checkpass))
				{
					static const fmt_query[] = "SELECT * FROM users WHERE name = '%s' AND pass = '%s'";
					new query[sizeof(fmt_query)+(-2+MAX_PLAYER_NAME)+(-2+64)];
					format(query, sizeof(query), fmt_query,  player_info[playerid][NAME], player_info[playerid][PASSWORD]);
					mysql_tquery(dbHandle, query, "PlayerLogin", "i", playerid);
				}
				else
				{
					new string[67];
					SetPVarInt(playerid, "WrongPassword", GetPVarInt(playerid, "WrongPassword")-1);
					if (GetPVarInt(playerid, "WrongPassword") > 0)
					{
						format(string, sizeof(string), "[Ошибка] {FFFFFF}Введен неверный пароль. У вас осталось %d попыток.", GetPVarInt(playerid, "WrongPassword"));
						SCM(playerid, COLOR_RED, string);
					}
					if (GetPVarInt(playerid, "WrongPassword") == 0)
					{
						SCM(playerid, COLOR_RED, "[Ошибка] {FFFFFF}Лимит попыток исчерпаню Вы отключены от сервера.");
						SPD(playerid, -1, 0, " ", " ", " ", "");

						return Kick(playerid);
					}
					ShowLogin(playerid);
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

forward PlayerLogin(playerid);
public PlayerLogin(playerid) 
{
	new rows;
	cache_get_row_count(rows);
	if(rows)
	{
		cache_get_value_name_int(0, "id", player_info[playerid][ID]);
		cache_get_value_name(0, "email", player_info[playerid][EMAIL], 65);
		cache_get_value_name_int(0, "ref", player_info[playerid][REF]);
		cache_get_value_name_int(0, "sex", player_info[playerid][SEX]);
		cache_get_value_name_int(0, "race", player_info[playerid][RACE]);	
		cache_get_value_name_int(0, "age", player_info[playerid][AGE]);
		cache_get_value_name_int(0, "skin", player_info[playerid][SKIN]);
		cache_get_value_name(0, "regdata", player_info[playerid][REGDATA], 13);
		cache_get_value_name(0, "regip", player_info[playerid][REGIP], 16);	
		cache_get_value_name_int(0, "admin", player_info[playerid][ADMIN]);	
		cache_get_value_name_int(0, "money", player_info[playerid][MONEY]);	
		cache_get_value_name_int(0, "lvl", player_info[playerid][LVL]);	
		cache_get_value_name_int(0, "exp", player_info[playerid][EXP]);	
		cache_get_value_name_int(0, "mins", player_info[playerid][MINS]);	


		new str[16];
		format(str, sizeof(str), "admin: %d", player_info[playerid][ADMIN]);
		SCM(playerid, COLOR_GREY, str);
		SetPVarInt(playerid, "logged", 1);
		SetSpawnInfo(playerid, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0);
		TogglePlayerSpectating(playerid, 0);


	}
	return 1;
}

forward CheckReferal(playerid, referal[]);
public CheckReferal(playerid, referal[])
{
    new rows;
	cache_get_row_count(rows);
	if(rows)
	{
  		cache_get_value_name_int(0, "id", player_info[playerid][REF]);
  		SPD(playerid, DLG_REGSEX, DIALOG_STYLE_MSGBOX, "{de0007}Регистрация{FFFFFF} • Выбор пола персонажа",
    	"{FFFFFF}Выберете пол вашего персонажа",
     	"Мужской", "Женский");
	}
	else
	{
	    SPD(playerid, DLG_REGREF, DIALOG_STYLE_INPUT, "{de0007}Регистрация{FFFFFF} • Ввод пригласившего",
		"{FFFFFF}Введи ник игрока, который тебя пригласил, в поле ниже",
		"Далее", "Пропустить");
	    return SCM(playerid, COLOR_RED, "[Ошибка] {FFFFFF} Аккаунта с таким ником не существует");
	
	}
	return 1;
}

public OnPlayerClickPlayer(playerid, clickedplayerid, source)
{
	return 1;
}

public OnPlayerClickMap(playerid, Float:fX, Float:fY, Float:fZ)
{
	printf("%d", player_info[playerid][ADMIN]);
	SCM(playerid, COLOR_RED, "ClickMap");
	if(player_info[playerid][ADMIN] >= 4) 
	{
		if (GetPlayerState(playerid) == PLAYER_STATE_DRIVER)
		{
			SetVehiclePos(GetPlayerVehicleID(playerid), fX, fY, fZ);
			PutPlayerInVehicle(playerid, GetPlayerVehicleID(playerid), 0);
		}
		else
		{
			SetPlayerPos(playerid, fX, fY, fZ);
		}
		SetPlayerVirtualWorld(playerid, 0);
		SetPlayerInterior(playerid, 0);
	} 
    return 1;
}


stock GiveMoney(playerid, money)
{	
	player_info[playerid][MONEY] += money;
	static const fmt_query[] = "UPDATE users SET money = '%d' WHERE id = '%d'";
	new query[sizeof(fmt_query)+(-2+9)+(-2+8)];
	format(query, sizeof(query), fmt_query, player_info[playerid][MONEY], player_info[playerid][ID]);
	mysql_query(dbHandle, query, false);
	GivePlayerMoney(playerid, money);
}

stock ProxDetector(Float:radi, playerid, string[], col1,col2,col3,col4,col5)
{
	if(IsPlayerConnected(playerid))
	{
		new Float:posx;new Float:posy;new Float:posz;new Float:oldposx;new Float:oldposy;new Float:oldposz;new Float:tempposx;new Float:tempposy;new Float:tempposz;
		GetPlayerPos(playerid, oldposx, oldposy, oldposz);
		foreach(new i:Player)
		{
			if(IsPlayerConnected(i))
			{
				if(GetPlayerVirtualWorld(playerid) == GetPlayerVirtualWorld(i))
				{
					GetPlayerPos(i, posx, posy, posz);
					tempposx = (oldposx - posx);
					tempposy = (oldposy - posy);
					tempposz = (oldposz - posz);
					if(((tempposx < radi/16) && (tempposx > -radi/16)) && ((tempposy < radi/16) && (tempposy > -radi/16)) && ((tempposz < radi/16) && (tempposz > -radi/16))) SCM(i, col1, string);
					else if(((tempposx < radi/8) && (tempposx > -radi/8)) && ((tempposy < radi/8) && (tempposy > -radi/8)) && ((tempposz < radi/8) && (tempposz > -radi/8))) SCM(i, col2, string);
					else if(((tempposx < radi/4) && (tempposx > -radi/4)) && ((tempposy < radi/4) && (tempposy > -radi/4)) && ((tempposz < radi/4) && (tempposz > -radi/4))) SCM(i, col3, string);
					else if(((tempposx < radi/2) && (tempposx > -radi/2)) && ((tempposy < radi/2) && (tempposy > -radi/2)) && ((tempposz < radi/2) && (tempposz > -radi/2))) SCM(i, col4, string);
					else if(((tempposx < radi) && (tempposx > -radi)) && ((tempposy < radi) && (tempposy > -radi)) && ((tempposz < radi) && (tempposz > -radi))) SCM(i, col5, string);
				}
			}
		}
	}
	return 1;
}

stock GiveExp(playerid, exp)
{
	player_info[playerid][EXP] += exp;
	new needexp = (player_info[playerid][LVL]+1)*expmultiply;
	new buffer = player_info[playerid][EXP] - needexp;
	if (player_info[playerid][EXP] >= needexp)
	{
		player_info[playerid][EXP] = 0;
		if(buffer > 0) player_info[playerid][EXP] += buffer;
		player_info[playerid][LVL]++;
		SCM(playerid, COLOR_WHITE, "Ваш уровень повышен");
		SetPlayerScore(playerid, player_info[playerid][LVL]);
	}
	static const fmt_query[] = "UPDATE users SET lvl = '%d', exp = '%d' WHERE id = '%d'";
	new query[sizeof(fmt_query)+(-2+2)+(-2+8)];
	format(query, sizeof(query), fmt_query, player_info[playerid][LVL], player_info[playerid][EXP], player_info[playerid][ID]);
	mysql_query(dbHandle, query, false);
}

