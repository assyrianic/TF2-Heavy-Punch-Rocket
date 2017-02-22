#include <sourcemod>
#include <sdktools>
#include <tf2_stocks>

#define and	&&
#define or	||

public Action TF2_CalcIsAttackCritical(int client, int weapon, char[] weaponname, bool& result)
{
	if( TF2_GetPlayerClass(client) != TFClass_Heavy )
		return Plugin_Continue;
	
	if( weapon != GetPlayerWeaponSlot(client, 2) )
		return Plugin_Continue;
	
	char szEnt[32];
	for( int ent=MaxClients+1 ; ent<2048 ; ent++ ) {
		if( !IsValidEdict(ent) or !IsValidEntity(ent) )
			continue;

		GetEntityClassname(ent, szEnt, sizeof(szEnt));
		if( (!strcmp(szEnt, "tf_projectile_rocket", false) or !strcmp(szEnt, "tf_projectile_sentryrocket", false)) and IsInRange(client, ent, 250.0, false) )
			ReflectRocket(client, ent);
	}
	return Plugin_Continue;
}
stock void ReflectRocket(const int client, const int target)
{
	if( GetOwner(target) == client ) // Don't reflect own rockets
		return;

	float targetvel[3]; GetEntPropVector(target, Prop_Data, "m_vecAbsVelocity", targetvel);

	float vAngles[3]; GetClientEyeAngles(client, vAngles);
	float EyePos[3]; GetClientEyePosition(client, EyePos);

	int iTeam = GetClientTeam(client);
	//SetEntPropEnt(target, Prop_Send, "m_hThrower", client);	// For grenades
	SetEntPropEnt(target, Prop_Send, "m_hOwnerEntity", client);
	SetEntProp(target,	Prop_Send, "m_iTeamNum", iTeam, 1);
	SetEntProp(target,	Prop_Send, "m_nSkin", (iTeam-2));

	SetVariantInt(iTeam); AcceptEntityInput(target, "TeamNum");
	SetVariantInt(iTeam); AcceptEntityInput(target, "SetTeam");
	
	float vVelocity[3];
	GetAngleVectors(vAngles, vVelocity, NULL_VECTOR, NULL_VECTOR);
	NormalizeVector(vVelocity, vVelocity);
	ScaleVector(vVelocity, GetVectorLength(targetvel)*1.25);
	TeleportEntity(target, EyePos, vAngles, vVelocity);

	EmitSoundToAll("weapons/loose_cannon_ball_impact.wav", client, _, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL, 100, _, EyePos, NULL_VECTOR, false, 0.0);
}
stock int GetOwner(const int entity)
{
	if( IsValidEdict(entity) and IsValidEntity(entity) )
		return GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity");
	return -1;
}
public bool TraceRayDontHitSelf(int entity, int mask, any data)
{
	return (entity != data);
}
stock bool IsInRange(const int entity, const int target, const float dist, const bool pTrace)
{
	float entitypos[3]; GetEntPropVector(entity, Prop_Data, "m_vecAbsOrigin", entitypos);
	float targetpos[3]; GetEntPropVector(target, Prop_Data, "m_vecAbsOrigin", targetpos);

	if( GetVectorDistance(entitypos, targetpos) <= dist ) {
		if( !pTrace )
			return true;
		else {
			TR_TraceRayFilter( entitypos, targetpos, MASK_SHOT, RayType_EndPoint, TraceRayDontHitSelf, entity );
			if ( TR_GetFraction() > 0.98 )
				return true;
		}
	}
	return false;
}
