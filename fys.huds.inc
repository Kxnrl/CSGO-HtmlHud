#if defined _fys_Huds_Include_
    #endinput
#endif

#define _fsy_Huds_Include_

native bool Huds_ShowHtmlHudOne(int client, float hold = 0.0, const char[] html = NULL_STRING, bool override = false);
native bool Huds_ShowHtmlHudAll(float hold = 0.0, const char[] html = NULL_STRING, bool override = false);

native void Huds_ShowRealHudOne(int client, const char[] message = NULL_STRING, int hold = 1);
native void Huds_ShowRealHudAll(const char[] message = NULL_STRING, int hold = 1);

public SharedPlugin __pl_fys_Huds =
{
    name = "fys-Huds",
    file = "fys.huds.smx",
#if defined REQUIRE_PLUGIN
    required = 1
#else
    required = 0
#endif
};

#if !defined REQUIRE_PLUGIN
public void __pl_fys_Huds_SetNTVOptional()
{
    MarkNativeAsOptional("Huds_ShowHtmlHudOne");
    MarkNativeAsOptional("Huds_ShowHtmlHudAll");
    MarkNativeAsOptional("Huds_ShowRealHudOne");
    MarkNativeAsOptional("Huds_ShowRealHudAll");
}
#endif
