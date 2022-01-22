#include <sourcemod>
#include <geoip>

#pragma semicolon 1

public Plugin myinfo = 
{
	name = "Connect Disconnect Log", 
	author = "oppa", 
	description = "Server Player Connect and Disconnect Log", 
	version = "1.0", 
	url = "csgo-turkiye.com"
};

public void OnPluginStart(){
    LoadTranslations("csgotr-connect_disconnect_log.phrases.txt");
    char s_folder[ PLATFORM_MAX_PATH ];
    BuildPath(Path_SM, s_folder, sizeof(s_folder), "logs/connect_disconnect");
    if(!DirExists(s_folder))if(!CreateDirectory(s_folder, 511))SetFailState("%t", "Folder Create Error");
    Handle h_folder = OpenDirectory(s_folder);
    if (h_folder == null) LogError("%t", "Folder Open Error");
    else{
        FileType ft_type;
        char s_file_name[ PLATFORM_MAX_PATH ];
        while (ReadDirEntry(h_folder, s_file_name, sizeof(s_file_name), ft_type))
        {
            if(strcmp(s_file_name, ".", false) != 0 && strcmp(s_file_name, "..", false) != 0){
                if (ft_type == FileType_File){ 
                    char s_file_path[PLATFORM_MAX_PATH];
                    BuildPath(Path_SM, s_file_path, sizeof(s_file_path), "logs/connect_disconnect/%s" ,s_file_name);
                    int i_file_change_time = GetFileTime(s_file_path, FileTime_LastChange);
                    if(i_file_change_time != -1 && i_file_change_time <= GetTime() - 604800){
                        if(DeleteFile(s_file_path))PrintToServer("%t", "File Delete", s_file_path);
                        else LogError("%t", "File Delete Error", s_file_path);
                    }
                } 
            }
        }
    }
    HookEvent("player_disconnect", Event_PlayerDisconnect, EventHookMode_Pre);
}

public void OnMapStart(){
    char s_map_name[128], s_time[128], s_file[ PLATFORM_MAX_PATH ];
    GetCurrentMap(s_map_name, sizeof(s_map_name));
    int i_time = GetTime();
    FormatTime(s_time, sizeof(s_time), "%Y_%m_%d", i_time);
    BuildPath(Path_SM, s_file, sizeof(s_file), "/logs/connect_disconnect/%s.log", s_time);
    Handle h_file = OpenFile(s_file, "a+");
    FormatTime(s_time, sizeof(s_time), "%X", i_time);
    WriteFileLine(h_file, "%t", "Map Change", s_time, s_map_name);
    CloseHandle(h_file);
}

public void OnClientPostAdminCheck(int client){
    LogWrite(client);
}

void LogWrite(int client, bool connect = true, char reason[128] = ""){
    if(IsValidClient(client)){
        char s_ip[16], s_country[128], s_time[128], s_file[ PLATFORM_MAX_PATH ];
        if(GetClientIP(client, s_ip, sizeof(s_ip), true)){
            if (!GeoipCountry(s_ip, s_country, sizeof(s_country)))Format(s_country, sizeof(s_country), "%t", "Unknown Country"); 
        }else{
            Format(s_ip, sizeof(s_ip), "%t", "Unknown IP");
            Format(s_country, sizeof(s_country), "%t", "Unknown Country");
        }
        int i_time = GetTime();
        FormatTime(s_time, sizeof(s_time), "%Y_%m_%d", i_time);
        BuildPath(Path_SM, s_file, sizeof(s_file), "/logs/connect_disconnect/%s.log", s_time);
        Handle h_file = OpenFile(s_file, "a+");
        FormatTime(s_time, sizeof(s_time), "%X", i_time);
        if(connect)WriteFileLine(h_file, "%t", "Connect Log", s_time, client, s_ip, s_country);
        else WriteFileLine(h_file, "%t", "Disconnect Log", s_time, client, s_ip, s_country, RoundToCeil(GetClientTime(client) / 60), reason);
        CloseHandle(h_file);
    }
}

public Action Event_PlayerDisconnect(Event event, const char[] name, bool dontBroadcast)
{
    int i_client = GetClientOfUserId(GetEventInt(event, "userid"));
    if(IsValidClient(i_client)){
        char s_reason[128];
        GetEventString(event, "reason", s_reason, sizeof(s_reason));
        LogWrite(i_client, false, s_reason);
    }
}

bool IsValidClient(int client, bool nobots = true)
{
	if (client <= 0 || client > MaxClients || !IsClientConnected(client) || (nobots && IsFakeClient(client)))return false;
	return IsClientInGame(client);
}