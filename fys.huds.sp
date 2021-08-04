#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <smutils>
//#include <fys.core>

#define foreachAction(%1, %2, %3) for (int %1 = %2; %1 <= %3; %1++)
#define foreachClient(%1) for (int %1 = 1; %1 <= MaxClients; %1++) if (IsClientInGame(%1))
#define foreachPlayer(%1) for (int %1 = 1; %1 <= MaxClients; %1++) if (IsClientInGame(%1) && !IsFakeClient(%1))

public Plugin myinfo = 
{
    name        = "fys - Hud controller",
    author      = "Kyle",
    description = "",
    version     = "1.0",
    url         = "https://www.kxnrl.com"
};

enum struct hud_t
{
    char Html[4096];
    float Hold;
}

ArrayList g_Queue[MAXPLAYERS+1];
Handle    g_Timer[MAXPLAYERS+1];

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
    RegPluginLibrary("fys-Huds");
    
    CreateNative("Huds_ShowHtmlHudOne", Native_ShowHtmlHudOne);
    CreateNative("Huds_ShowHtmlHudAll", Native_ShowHtmlHudAll);
    CreateNative("Huds_ShowRealHudOne", Native_ShowRealHudOne);
    CreateNative("Huds_ShowRealHudAll", Native_ShowRealHudAll);

    return APLRes_Success;
}

public any Native_ShowRealHudOne(Handle plugin, int numParmas)
{
    char message[2048];
    int client = GetNativeCell(1);
    GetNativeString(2, message, 2048);
    int holdFx = GetNativeCell(3);
    ShowStatusMessage(client, message, holdFx);
}

public any Native_ShowRealHudAll(Handle plugin, int numParmas)
{
    char message[2048];
    GetNativeString(1, message, 2048);
    int holdFx = GetNativeCell(2);
    ShowStatusMessage(-1, message, holdFx);
}

public any Native_ShowHtmlHudOne(Handle plugin, int numParmas)
{
    int client = GetNativeCell(1);
    if (g_Queue[client] == null)
        return false;

    hud_t hud;
    hud.Hold = GetNativeCell(2);
    GetNativeString(3, hud.Html, 4096);

    if (hud.Hold > 20.0)
        hud.Hold = 20.0;

    int index = g_Queue[client].PushArray(hud, sizeof(hud_t));

    if (GetNativeCell(4) || g_Timer[client] == null)
    {
        // override
        StopTimer(g_Timer[client]);
        PickQueue(client, index);
    }

    return true;
}

public any Native_ShowHtmlHudAll(Handle plugin, int numParmas)
{
    hud_t hud;
    hud.Hold = GetNativeCell(1);
    GetNativeString(2, hud.Html, 4096);

    if (hud.Hold > 20.0)
        hud.Hold = 20.0;

    bool override = GetNativeCell(3);

    for (int i = 1; i <= MaxClients; i++) if (g_Queue[i] != null)
    {
        int index = g_Queue[i].PushArray(hud, sizeof(hud_t));
        if (override || g_Timer[i] == null)
        {
            StopTimer(g_Timer[i]);
            PickQueue(i, index);
        }
    }

    return true;
}

public void OnPluginStart()
{
    HookEvent("round_start", Event_RoundStart, EventHookMode_Post);

    CreateTimer(2.0, Timer_Interval, _, TIMER_REPEAT);

    foreachPlayer(client) OnClientPutInServer(client);
}

public void OnClientPutInServer(int client)
{
    if (IsFakeClient(client))
        return;

    g_Queue[client] = new ArrayList(sizeof(hud_t));
}

public void OnClientDisconnect(int client)
{
    delete g_Queue[client];
    g_Queue[client] = null;
    StopTimer(g_Timer[client]);
}

public Action Timer_Interval(Handle timer)
{
    for (int i = 1; i <= MaxClients; i++) if (g_Queue[i] != null && g_Timer[i] == null && g_Queue[i].Length > 0)
    {
        PickQueue(i);
    }
    return Plugin_Continue;
}

void PickQueue(int client, int index = 0)
{
    if (g_Queue[client].Length <= index)
        return;

    hud_t hud;
    g_Queue[client].GetArray(index, hud, sizeof(hud_t));
    g_Queue[client].Erase(index);

    ShowHtmlMessage(client, hud.Html);

    if (strlen(hud.Html) > 0)
    g_Timer[client] = CreateTimer(hud.Hold+1.0, Timer_StopHtml, client);
}

void ShowHtmlMessage(int client, const char[] message = NULL_STRING)
{
    Event cs_win_panel_round = CreateEvent("cs_win_panel_round");
    if (cs_win_panel_round != null)
    {
        cs_win_panel_round.SetString("funfact_token", message);
        cs_win_panel_round.FireToClient(client);
        cs_win_panel_round.Cancel(); 
    }
}

void ShowStatusMessage(int client = -1, const char[] message = NULL_STRING, int hold = 1)
{
    Event show_survival_respawn_status = CreateEvent("show_survival_respawn_status");
    if (show_survival_respawn_status != null)
    {
        show_survival_respawn_status.SetString("loc_token", message);
        show_survival_respawn_status.SetInt("duration", hold);
        show_survival_respawn_status.SetInt("userid", -1);
        if (client == -1)
        {
            foreachPlayer(player)
            {
                show_survival_respawn_status.FireToClient(player);
            }
        }
        else
        {
            show_survival_respawn_status.FireToClient(client);
        }
        show_survival_respawn_status.Cancel(); 
    }
}

public Action Timer_StopHtml(Handle timer, int client)
{
    g_Timer[client] = null;
    if (IsClientInGame(client))
    {
        ShowHtmlMessage(client);
    }
    return Plugin_Stop;
}

public void Event_RoundStart(Event e, const char[] n, bool b)
{
    for (int i = 1; i <= MaxClients; i++)
    {
        StopTimer(g_Timer[i]);
    }
}
