//includes
#include <cstrike>
#include <sourcemod>
#include <colors>
#include <warden>
#include <emitsoundany>
#include <autoexecconfig>
#include <myjailbreak>
#include <lastrequest>

//Compiler Options
#pragma semicolon 1
#pragma newdecls required

//ConVars
ConVar gc_fRefuseTime;
ConVar gc_bRefuse;
ConVar gc_bPlugin;
ConVar gc_bWardenAllowRefuse;
ConVar gc_iRefuseLimit;
ConVar gc_iRefuseColorRed;
ConVar gc_iRefuseColorGreen;
ConVar gc_iRefuseColorBlue;
ConVar gc_fCapitulationTime;
ConVar gc_fRebelTime;
ConVar gc_bCapitulation;
ConVar gc_bCapitulationDamage;
ConVar gc_iCapitulationColorRed;
ConVar gc_iCapitulationColorGreen;
ConVar gc_iCapitulationColorBlue;
ConVar gc_bSounds;
ConVar gc_sSoundRefusePath;
ConVar gc_sSoundRefuseStopPath;
ConVar gc_sSoundCapitulationPath;
ConVar gc_bHeal;
ConVar gc_bHealthShot;
ConVar gc_fHealTime;
ConVar gc_iHealLimit;
ConVar gc_iHealColorRed;
ConVar gc_iHealColorGreen;
ConVar gc_iHealColorBlue;
ConVar gc_bRepeat;
ConVar gc_iRepeatLimit;
ConVar gc_sSoundRepeatPath;

//Bools
bool g_bHealed[MAXPLAYERS+1];
bool g_bCapitulated[MAXPLAYERS+1];
bool g_bRefused[MAXPLAYERS+1];
bool g_bRepeated[MAXPLAYERS+1];
bool g_bAllowRefuse;
bool IsRequest;


//Integers
int g_iRefuseCounter[MAXPLAYERS+1];
int g_iHealCounter[MAXPLAYERS+1];
int g_iRepeatCounter[MAXPLAYERS+1];
int g_iCountStopTime;


//Handles
Handle RebelTimer[MAXPLAYERS+1];
Handle RefuseTimer[MAXPLAYERS+1];
Handle RepeatTimer[MAXPLAYERS+1];
Handle CapitulationTimer[MAXPLAYERS+1];
Handle HealTimer[MAXPLAYERS+1];
Handle RefusePanel;
Handle RepeatPanel;
Handle RequestTimer;
Handle AllowRefuseTimer;

//characters
char g_sSoundRefusePath[256];
char g_sSoundRefuseStopPath[256];
char g_sSoundRepeatPath[256];
char g_sSoundCapitulationPath[256];

public Plugin myinfo = 
{
	name = "MyJailbreak - Request",
	author = "shanapu",
	description = "Requests - refuse, capitulation/pardon, heal",
	version = PLUGIN_VERSION,
	url = URL_LINK
}

public void OnPluginStart()
{
	// Translation
	LoadTranslations("MyJailbreak.Warden.phrases");
	LoadTranslations("MyJailbreak.Request.phrases");
	
	//Client Commands
	RegConsoleCmd("sm_ref", Command_refuse, "Allows the Warden start refusing time and Terrorist to refuse a game");
	RegConsoleCmd("sm_refuse", Command_refuse, "Allows the Warden start refusing time and Terrorist to refuse a game");
	
	RegConsoleCmd("sm_c", Command_Capitulation, "Allows a rebeling terrorist to request a capitulate");
	RegConsoleCmd("sm_capitulation", Command_Capitulation, "Allows a rebeling terrorist to request a capitulate");
	RegConsoleCmd("sm_p", Command_Capitulation, "Allows a rebeling terrorist to request a capitulate");
	RegConsoleCmd("sm_pardon", Command_Capitulation, "Allows a rebeling terrorist to request a capitulate");
	
	RegConsoleCmd("sm_h", Command_Heal, "Allows a Terrorist request healing");
	RegConsoleCmd("sm_heal", Command_Heal, "Allows a Terrorist request healing");
	
	RegConsoleCmd("sm_rep", Command_Repeat, "Allows a Terrorist request repeat");
	RegConsoleCmd("sm_repeat", Command_Repeat, "Allows a Terrorist request repeat");
	RegConsoleCmd("sm_what", Command_Repeat, "Allows a Terrorist request repeat");
	
	//AutoExecConfig
	AutoExecConfig_SetFile("Request", "MyJailbreak");
	AutoExecConfig_SetCreateFile(true);
	
	AutoExecConfig_CreateConVar("sm_request_version", PLUGIN_VERSION, "The version of this MyJailbreak SourceMod plugin", FCVAR_SPONLY|FCVAR_PLUGIN|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	gc_bPlugin = AutoExecConfig_CreateConVar("sm_request_enable", "1", "0 - disabled, 1 - enable Request Plugin");
	gc_bSounds = AutoExecConfig_CreateConVar("sm_request_sounds_enable", "1", "0 - disabled, 1 - enable sounds ", _, true,  0.0, true, 1.0);
	gc_bRefuse = AutoExecConfig_CreateConVar("sm_refuse_enable", "1", "0 - disabled, 1 - enable Refuse");
	gc_bWardenAllowRefuse = AutoExecConfig_CreateConVar("sm_refuse_allow", "1", "0 - disabled, 1 - Warden must allow !refuse before T can use it");
	gc_iRefuseLimit = AutoExecConfig_CreateConVar("sm_refuse_limit", "1", "Сount how many times you can use the command");
	gc_fRefuseTime = AutoExecConfig_CreateConVar("sm_refuse_time", "10.0", "Time the player gets to refuse after warden open refuse with !refuse / colortime");
	gc_iRefuseColorRed = AutoExecConfig_CreateConVar("sm_refuse_color_red", "0","What color to turn the refusing Terror into (set R, G and B values to 255 to disable) (Rgb): x - red value", _, true, 0.0, true, 255.0);
	gc_iRefuseColorGreen = AutoExecConfig_CreateConVar("sm_refuse_color_green", "250","What color to turn the refusing Terror into (rGb): x - green value", _, true, 0.0, true, 255.0);
	gc_iRefuseColorBlue = AutoExecConfig_CreateConVar("sm_refuse_color_blue", "250","What color to turn the refusing Terror into (rgB): x - blue value", _, true, 0.0, true, 255.0);
	gc_sSoundRefusePath = AutoExecConfig_CreateConVar("sm_refuse_sound", "music/MyJailbreak/refuse.mp3", "Path to the soundfile which should be played for a refusing.");
	gc_sSoundRefuseStopPath = AutoExecConfig_CreateConVar("sm_refuse_stop_sound", "music/MyJailbreak/stop.mp3", "Path to the soundfile which should be played after a refusing.");
	gc_bCapitulation = AutoExecConfig_CreateConVar("sm_capitulation_enable", "1", "0 - disabled, 1 - enable Capitulation");
	gc_fCapitulationTime = AutoExecConfig_CreateConVar("sm_capitulation_timer", "10.0", "Time to decide to accept the capitulation");
	gc_fRebelTime = AutoExecConfig_CreateConVar("sm_capitulation_rebel_timer", "10.0", "Time to give a rebel on not accepted capitulation his knife back");
	gc_bCapitulationDamage = AutoExecConfig_CreateConVar("sm_capitulation_damage", "1", "0 - disabled, 1 - enable Terror make no damage after capitulation");
	gc_iCapitulationColorRed = AutoExecConfig_CreateConVar("sm_capitulation_color_red", "0","What color to turn the capitulation Terror into (set R, G and B values to 255 to disable) (Rgb): x - red value", _, true, 0.0, true, 255.0);
	gc_iCapitulationColorGreen = AutoExecConfig_CreateConVar("sm_capitulation_color_green", "250","What color to turn the capitulation Terror into (rGb): x - green value", _, true, 0.0, true, 255.0);
	gc_iCapitulationColorBlue = AutoExecConfig_CreateConVar("sm_capitulation_color_blue", "0","What color to turn the capitulation Terror into (rgB): x - blue value", _, true, 0.0, true, 255.0);
	gc_sSoundCapitulationPath = AutoExecConfig_CreateConVar("sm_capitulation_sound", "music/MyJailbreak/capitulation.mp3", "Path to the soundfile which should be played for a capitulation.");
	gc_bHeal = AutoExecConfig_CreateConVar("sm_heal_enable", "1", "0 - disabled, 1 - enable heal");
	gc_bHealthShot = AutoExecConfig_CreateConVar("sm_heal_healthshot", "1", "0 - disabled, 1 - enable give healthshot on accept to terror");
	gc_iHealLimit = AutoExecConfig_CreateConVar("sm_heal_limit", "2", "Сount how many times you can use the command");
	gc_fHealTime = AutoExecConfig_CreateConVar("sm_heal_time", "10.0", "Time after the player gets his normal colors back");
	gc_iHealColorRed = AutoExecConfig_CreateConVar("sm_heal_color_red", "240","What color to turn the heal Terror into (set R, G and B values to 255 to disable) (Rgb): x - red value", _, true, 0.0, true, 255.0);
	gc_iHealColorGreen = AutoExecConfig_CreateConVar("sm_heal_color_green", "0","What color to turn the heal Terror into (rGb): x - green value", _, true, 0.0, true, 255.0);
	gc_iHealColorBlue = AutoExecConfig_CreateConVar("sm_heal_color_blue", "100","What color to turn the heal Terror into (rgB): x - blue value", _, true, 0.0, true, 255.0);
	gc_bRepeat = AutoExecConfig_CreateConVar("sm_repeat_enable", "1", "0 - disabled, 1 - enable repeat");
	gc_iRepeatLimit = AutoExecConfig_CreateConVar("sm_repeat_limit", "2", "Сount how many times you can use the command");
	gc_sSoundRepeatPath = AutoExecConfig_CreateConVar("sm_repeat_sound", "music/MyJailbreak/repeat.mp3", "Path to the soundfile which should be played for a repeat.");
	
	AutoExecConfig_ExecuteFile();
	AutoExecConfig_CleanFile();
	
	//Hooks
	HookEvent("round_start", RoundStart);
	
	//FindConVar
	gc_sSoundRefusePath.GetString(g_sSoundRefusePath, sizeof(g_sSoundRefusePath));
	gc_sSoundRefuseStopPath.GetString(g_sSoundRefuseStopPath, sizeof(g_sSoundRefuseStopPath));
	gc_sSoundCapitulationPath.GetString(g_sSoundCapitulationPath, sizeof(g_sSoundCapitulationPath));
	gc_sSoundRepeatPath.GetString(g_sSoundRepeatPath, sizeof(g_sSoundRepeatPath));
}

public int OnSettingChanged(Handle convar, const char[] oldValue, const char[] newValue)
{
	if(convar == gc_sSoundRefusePath)
	{
		strcopy(g_sSoundRefusePath, sizeof(g_sSoundRefusePath), newValue);
		if(gc_bSounds.BoolValue) PrecacheSoundAnyDownload(g_sSoundRefusePath);
	}
	else if(convar == gc_sSoundRefuseStopPath)
	{
		strcopy(g_sSoundRefuseStopPath, sizeof(g_sSoundRefuseStopPath), newValue);
		if(gc_bSounds.BoolValue) PrecacheSoundAnyDownload(g_sSoundRefuseStopPath);
	}
	else if(convar == gc_sSoundRepeatPath)
	{
		strcopy(g_sSoundRepeatPath, sizeof(g_sSoundRepeatPath), newValue);
		if(gc_bSounds.BoolValue) PrecacheSoundAnyDownload(g_sSoundRepeatPath);
	}
}

public void OnMapStart()
{
	if(gc_bSounds.BoolValue)
	{
		PrecacheSoundAnyDownload(g_sSoundRefusePath);
		PrecacheSoundAnyDownload(g_sSoundRefuseStopPath);
		PrecacheSoundAnyDownload(g_sSoundCapitulationPath);
		PrecacheSoundAnyDownload(g_sSoundRepeatPath);
	}
}


public Action RoundStart(Handle event, char [] name, bool dontBroadcast)
{
	LoopClients(client)
	{
		delete RefuseTimer[client];
		delete CapitulationTimer[client];
		delete RebelTimer[client];
		delete HealTimer[client];
		delete RepeatTimer[client];
		delete RequestTimer;
		delete AllowRefuseTimer;
		
		g_iRefuseCounter[client] = 0;
		g_bCapitulated[client] = false;
		g_iHealCounter[client] = 0;
		g_bHealed[client] = false;
		g_bRepeated[client] = false;
		g_iRepeatCounter[client] = 0;
		g_bRefused[client] = false;
		IsRequest = false;
		g_bAllowRefuse = false;
	}
	g_iCountStopTime = gc_fRefuseTime.IntValue;
	return Plugin_Continue;
}

public void OnClientPutInServer(int client)
{
	g_bCapitulated[client] = false;
	g_iRepeatCounter[client] = 0;
	g_iRefuseCounter[client] = 0;
	g_iHealCounter[client] = 0;
	g_bHealed[client] = false;
	g_bRepeated[client] = false;
	g_bRefused[client] = false;
	SDKHook(client, SDKHook_WeaponCanUse, OnWeaponCanUse);
	SDKHook(client, SDKHook_OnTakeDamage, OnTakedamage);
}

public void OnClientDisconnect(int client)
{
	delete RefuseTimer[client];
	delete CapitulationTimer[client];
	delete RebelTimer[client];
	delete HealTimer[client];
	delete RepeatTimer[client];
	
	g_iRepeatCounter[client] = 0;
	g_bCapitulated[client] = false;
	g_iRefuseCounter[client] = 0;
	g_bHealed[client] = false;
	g_iHealCounter[client] = 0;
	g_bRefused[client] = false;
	g_bRepeated[client] = false;
}

public Action Command_refuse(int client, int args)
{
	if (gc_bPlugin.BoolValue)
	{
		if (gc_bRefuse.BoolValue)
		{
			if(warden_iswarden(client) && gc_bWardenAllowRefuse.BoolValue)
			{
				if(!g_bAllowRefuse)
				{
					g_bAllowRefuse = true;
					AllowRefuseTimer = CreateTimer(1.0, NoAllowRefuse, _, TIMER_REPEAT);
					CPrintToChatAll("%t %t", "request_tag", "request_openrefuse");
				}
			}
			if (GetClientTeam(client) == CS_TEAM_T && IsPlayerAlive(client))
			{
				if (RefuseTimer[client] == null)
				{
					if(!g_bAllowRefuse || !gc_bWardenAllowRefuse.BoolValue)
					{
						if (g_iRefuseCounter[client] < gc_iRefuseLimit.IntValue)
						{
							g_iRefuseCounter[client]++;
							g_bRefused[client] = true;
							SetEntityRenderColor(client, gc_iRefuseColorRed.IntValue, gc_iRefuseColorGreen.IntValue, gc_iRefuseColorBlue.IntValue, 255);
							CPrintToChatAll("%t %t", "request_tag", "request_refusing", client);
							g_iCountStopTime = gc_fRefuseTime.IntValue;
							RefuseTimer[client] = CreateTimer(gc_fRefuseTime.FloatValue, ResetColorRefuse, client);
							if (warden_exist()) LoopClients(i) RefuseMenu(i);
							if(gc_bSounds.BoolValue)EmitSoundToAllAny(g_sSoundRefusePath);
						}
						else CPrintToChat(client, "%t %t", "request_tag", "request_refusedtimes");
					}
					else CPrintToChat(client, "%t %t", "request_tag", "request_refuseallow");
				}
				else
				{
					CPrintToChat(client, "%t %t", "request_tag", "request_alreadyrefused");
				}
			}
			else
			{
				CPrintToChat(client, "%t %t", "request_tag", "request_notalivect");
			}
		}
	}
	return Plugin_Handled;
}

public Action RefuseMenu(int warden)
{
	if (IsValidClient(warden, false, false) && warden_iswarden(warden))
	{
		char info1[255];
		RefusePanel = CreatePanel();
		Format(info1, sizeof(info1), "%T", "request_refuser", warden);
		SetPanelTitle(RefusePanel, info1);
		DrawPanelText(RefusePanel, "-----------------------------------");
		DrawPanelText(RefusePanel, "                                   ");
		LoopValidClients(i,true,false)
		{
			if(g_bRefused[i])
			{
				char userid[11];
				char username[MAX_NAME_LENGTH];
				IntToString(GetClientUserId(i), userid, sizeof(userid));
				Format(username, sizeof(username), "%N", i);
				DrawPanelText(RefusePanel,username);
			}
		}
		DrawPanelText(RefusePanel, "                                   ");
		DrawPanelText(RefusePanel, "-----------------------------------");
		SendPanelToClient(RefusePanel, warden, NullHandler, 20);
	}
}

//repeat

public Action Command_Repeat(int client, int args)
{
	if (gc_bPlugin.BoolValue)
	{
		if (gc_bRepeat.BoolValue)
		{
			if (GetClientTeam(client) == CS_TEAM_T && IsPlayerAlive(client))
			{
				if (RepeatTimer[client] == null)
				{
					if (g_iRepeatCounter[client] < gc_iRepeatLimit.IntValue)
					{
						g_iRepeatCounter[client]++;
						g_bRepeated[client] = true;
						CPrintToChatAll("%t %t", "request_tag", "request_repeatpls", client);
						RepeatTimer[client] = CreateTimer(10.0, RepeatEnd, client);
						if (warden_exist()) LoopClients(i) RepeatMenu(i);
						if(gc_bSounds.BoolValue)EmitSoundToAllAny(g_sSoundRepeatPath);
					}
					else
					{
						CPrintToChat(client, "%t %t", "request_tag", "request_repeattimes");
					}
				}
				else
				{
					CPrintToChat(client, "%t %t", "request_tag", "request_alreadyrepeat");
				}
			}
			else
			{
				CPrintToChat(client, "%t %t", "request_tag", "request_notalivect");
			}
		}
	}
	return Plugin_Handled;
}

public Action RepeatMenu(int warden)
{
	if (IsValidClient(warden, false, false) && warden_iswarden(warden))
	{
		char info1[255];
		RepeatPanel = CreatePanel();
		Format(info1, sizeof(info1), "%T", "request_repeat", warden);
		SetPanelTitle(RepeatPanel, info1);
		DrawPanelText(RepeatPanel, "-----------------------------------");
		DrawPanelText(RepeatPanel, "                                   ");
		for(int i = 1;i <= MaxClients;i++) if(IsValidClient(i, true))
		{
			if(g_bRepeated[i])
			{
				char userid[11];
				char username[MAX_NAME_LENGTH];
				IntToString(GetClientUserId(i), userid, sizeof(userid));
				Format(username, sizeof(username), "%N", i);
				DrawPanelText(RepeatPanel,username);
			}
		}
		DrawPanelText(RepeatPanel, "                                   ");
		DrawPanelText(RepeatPanel, "-----------------------------------");
		SendPanelToClient(RepeatPanel, warden, NullHandler, 20);
	}
}

public Action Command_Capitulation(int client, int args)
{
	if (gc_bPlugin.BoolValue)
	{
		if (gc_bCapitulation.BoolValue)
		{
			if (GetClientTeam(client) == CS_TEAM_T && (IsPlayerAlive(client)))
			{
				if (!(g_bCapitulated[client]))
				{
					if (warden_exist())
					{
						if(!IsRequest)
						{
							IsRequest = true;
							RequestTimer = CreateTimer (gc_fCapitulationTime.FloatValue, IsRequestTimer);
							g_bCapitulated[client] = true;
							CPrintToChatAll("%t %t", "request_tag", "request_capitulation", client);
							SetEntityRenderColor(client, gc_iCapitulationColorRed.IntValue, gc_iCapitulationColorGreen.IntValue, gc_iCapitulationColorBlue.IntValue, 255);
							float DoubleTime = (gc_fRebelTime.FloatValue * 2);
							RebelTimer[client] = CreateTimer(DoubleTime, GiveKnifeRebel, client);
							StripAllWeapons(client);
							LoopClients(i) CapitulationMenu(i);
							if(gc_bSounds.BoolValue)EmitSoundToAllAny(g_sSoundCapitulationPath);
						}
						else CPrintToChat(client, "%t %t", "request_tag", "request_processing");
					}
					else CPrintToChat(client, "%t %t", "request_tag", "warden_noexist");
				}
				else
				{
					CPrintToChat(client, "%t %t", "request_tag", "request_alreadycapitulated");
				}
			}
			else
			{
				CPrintToChat(client, "%t %t", "request_tag", "request_notalivect");
			}
		}
	}
	return Plugin_Handled;
}

public Action CapitulationMenu(int warden)
{
	if (IsValidClient(warden, false, false) && warden_iswarden(warden))
	{
		char info5[255], info6[255], info7[255];
		Menu menu1 = CreateMenu(CapitulationMenuHandler);
		Format(info5, sizeof(info5), "%T", "request_acceptcapitulation", warden);
		menu1.SetTitle(info5);
		Format(info6, sizeof(info6), "%T", "warden_no", warden);
		Format(info7, sizeof(info7), "%T", "warden_yes", warden);
		menu1.AddItem("1", info7);
		menu1.AddItem("0", info6);
		menu1.Display(warden, gc_fCapitulationTime.IntValue);
	}
}

public int CapitulationMenuHandler(Menu menu, MenuAction action, int client, int Position)
{
	if(action == MenuAction_Select)
	{
		char Item[11];
		menu.GetItem(Position,Item,sizeof(Item));
		int choice = StringToInt(Item);
		if(choice == 1)
		{
			LoopClients(i) if(g_bCapitulated[i])
			{
				IsRequest = false;
				RequestTimer = null;
				RebelTimer[i] = null;
				CapitulationTimer[i] = CreateTimer(gc_fCapitulationTime.FloatValue, GiveKnifeCapitulated, i);
				CPrintToChatAll("%t %t", "warden_tag", "request_accepted", i);
			}
		}
		if(choice == 0)
		{
			LoopClients(i) if(g_bCapitulated[i])
			{
				IsRequest = false;
				RequestTimer = null;
				SetEntityRenderColor(i, 255, 0, 0, 255);
				RebelTimer[i] = null;
				RebelTimer[i] = CreateTimer(gc_fRebelTime.FloatValue, GiveKnifeRebel, i);
				CPrintToChatAll("%t %t", "warden_tag", "request_noaccepted", i);
			}
		}
	}
}

//heal
public Action Command_Heal(int client, int args)
{
	if (gc_bPlugin.BoolValue)
	{
		if (gc_bHeal.BoolValue)
		{
			if (GetClientTeam(client) == CS_TEAM_T && (IsPlayerAlive(client)))
			{
				if (HealTimer[client] == null)
				{
					if (g_iHealCounter[client] < gc_iHealLimit.IntValue)
					{
						if (warden_exist())
						{
							if(!IsRequest)
							{
								IsRequest = true;
								RequestTimer = CreateTimer (gc_fHealTime.FloatValue, IsRequestTimer);
								g_bHealed[client] = true;
								g_iHealCounter[client]++;
								CPrintToChatAll("%t %t", "request_tag", "request_heal", client);
								SetEntityRenderColor(client, gc_iHealColorRed.IntValue, gc_iHealColorGreen.IntValue, gc_iHealColorBlue.IntValue, 255);
								HealTimer[client] = CreateTimer(gc_fHealTime.FloatValue, ResetColorHeal, client);
								LoopClients(i) HealMenu(i);
							}
							else CPrintToChat(client, "%t %t", "request_tag", "request_processing");
						}
						else CPrintToChat(client, "%t %t", "request_tag", "warden_noexist");
					}
					else
					{
						CPrintToChat(client, "%t %t", "request_tag", "request_healtimes");
					}
				}
				else
				{
					CPrintToChat(client, "%t %t", "request_tag", "request_alreadyhealed");
				}
			}
			else
			{
				CPrintToChat(client, "%t %t", "request_tag", "request_notalivect");
			}
		}
	}
	return Plugin_Handled;
}

public Action HealMenu(int warden)
{
	if (IsValidClient(warden, false, false) && warden_iswarden(warden))
	{
		char info5[255], info6[255], info7[255];
		Menu menu1 = CreateMenu(HealMenuHandler);
		Format(info5, sizeof(info5), "%T", "request_acceptheal", warden);
		menu1.SetTitle(info5);
		Format(info6, sizeof(info6), "%T", "warden_no", warden);
		Format(info7, sizeof(info7), "%T", "warden_yes", warden);
		menu1.AddItem("1", info7);
		menu1.AddItem("0", info6);
		menu1.Display(warden,gc_fHealTime.IntValue);
	}
}

public int HealMenuHandler(Menu menu, MenuAction action, int client, int Position)
{
	if(action == MenuAction_Select)
	{
		char Item[11];
		menu.GetItem(Position,Item,sizeof(Item));
		int choice = StringToInt(Item);
		if(choice == 1)
		{
			LoopClients(i) if(g_bHealed[i])
			{
				IsRequest = false;
				RequestTimer = null;
				if(gc_bHealthShot) GivePlayerItem(i, "weapon_healthshot");
				CPrintToChat(i, "%t %t", "request_tag", "request_health");
				CPrintToChatAll("%t %t", "warden_tag", "request_accepted", i);
			}
		}
		if(choice == 0)
		{
			IsRequest = false;
			RequestTimer = null;
			LoopClients(i) if(g_bHealed[i])
			{
				CPrintToChatAll("%t %t", "warden_tag", "request_noaccepted", i);
			}
		}
	}
}

public Action NoAllowRefuse(Handle timer)
{
	if (g_iCountStopTime > 0)
	{
		LoopValidClients(client, false, true)
		{
			if (g_iCountStopTime < 4) 
			{
				PrintHintText(client,"%t", "warden_stopcountdown_nc", g_iCountStopTime);
				CPrintToChatAll("%t %t", "warden_tag" , "warden_stopcountdown", g_iCountStopTime);
			}
		}
		g_iCountStopTime--;
		return Plugin_Continue;
	}
	if (g_iCountStopTime == 0)
	{
		LoopValidClients(client, false, true)
		{
			PrintHintText(client, "%t", "warden_countdownstop_nc");
			CPrintToChatAll("%t %t", "warden_tag" , "warden_countdownstop");
			if(gc_bSounds.BoolValue)	
			{
				EmitSoundToAllAny(g_sSoundRefuseStopPath);
			}
			g_bAllowRefuse = false;
			AllowRefuseTimer = null;
			g_iCountStopTime = gc_fRefuseTime.IntValue;
			return Plugin_Stop;
		}
	}
	return Plugin_Continue;
}

public Action IsRequestTimer(Handle timer, any client)
{
	IsRequest = false;
	RequestTimer = null;
}

public Action RepeatEnd(Handle timer, any client)
{
	RepeatTimer[client] = null;
	g_bRepeated[client] = false;
}

public Action ResetColorRefuse(Handle timer, any client)
{
	if (IsClientConnected(client))
	{
		SetEntityRenderColor(client, 255, 255, 255, 255);
	}
	RefuseTimer[client] = null;
	g_bRefused[client] = false;
}

public Action ResetColorHeal(Handle timer, any client)
{
	if (IsClientConnected(client))
	{
		SetEntityRenderColor(client, 255, 255, 255, 255);
	}
	HealTimer[client] = null;
	g_bHealed[client] = false;
}

public Action GiveKnifeCapitulated(Handle timer, any client)
{
	if (IsClientConnected(client))
	{
		GivePlayerItem(client,"weapon_knife");
		CPrintToChat(client, "%t %t", "request_tag", "request_knifeback");
		SetEntityRenderColor(client, 255, 255, 255, 255);
	}
	CapitulationTimer[client] = null;
}

public Action GiveKnifeRebel(Handle timer, any client)
{
	if (IsClientConnected(client))
	{
		GivePlayerItem(client,"weapon_knife");
		CPrintToChat(client, "%t %t", "request_tag", "request_knifeback");
		SetEntityRenderColor(client, 255, 0, 0, 255);
		
	}
	g_bCapitulated[client] = false;
	CapitulationTimer[client] = null;
	RebelTimer[client] = null;
}

public Action OnWeaponCanUse(int client, int weapon)
{
	if(g_bCapitulated[client])
	{
		char sWeapon[32];
		GetEdictClassname(weapon, sWeapon, sizeof(sWeapon));
		
		if(!StrEqual(sWeapon, "weapon_knife"))
		{
			if (IsValidClient(client, true, false))
			{
				return Plugin_Handled;
			}
		}
	}
	return Plugin_Continue;
}

public Action OnTakedamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype)
{
	if (IsValidClient(attacker, true, false) && GetClientTeam(attacker) == CS_TEAM_T && IsPlayerAlive(attacker))
	{
		if(g_bCapitulated[attacker] && gc_bCapitulationDamage.BoolValue)
		{
			CPrintToChat(attacker, "%t %t", "request_tag", "request_nodamage");
			return Plugin_Handled;
		}
	}
	return Plugin_Continue;
}

public int OnAvailableLR(int Announced)
{
	LoopClients(i) g_bCapitulated[i] = false;
}