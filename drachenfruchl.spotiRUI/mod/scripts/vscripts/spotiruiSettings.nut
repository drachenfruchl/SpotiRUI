global function spotiruiSettings_Init

void function spotiruiSettings_Init(){
	ModSettings_AddModTitle( 	"^FFFFFF00[sRUI] ^23FF7100S^21F46C00p^20E96700o^1EDE6200t^1DD35E00i^1BC85900R^1ABD5400U^18B24F00I" )

	ModSettings_AddModCategory( "^FFFFFF00> Settings" )
	AddConVarSetting(           "SPOTIRUI_UPDATE_RATE",     		"^FFFFFF00Update rate",               	"float" )
	AddConVarSetting(           "SPOTIRUI_MAX_SONG_TITLE_LENGTH",   "^FFFFFF00Max song title characters", 	"int" )
	AddConVarSetting(           "SPOTIRUI_MAX_ARTIST_LENGTH",    	"^FFFFFF00Max artist list characters",	"int" )
}
