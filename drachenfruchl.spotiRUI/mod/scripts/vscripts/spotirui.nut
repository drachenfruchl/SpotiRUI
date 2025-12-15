untyped
global function spotirui_Init

const string CREDENTIALS_FILEPATH = "credentials.json"

int MAX_SONG_TITLE_LENGTH = 20
int MAX_ARTIST_LENGTH = 20
float UPDATE_RATE = 1.0

bool INGAMEMENU_OPEN = false
string PREVID = ""

struct{
    string clientID    
    string clientSecret
    string accessToken 
    string refreshToken
}API

struct SONG{
    bool hasValues = false

    string id
    string name
    array<string> artists
    //string album
    
    int volumePercent
    string repeatState
    bool shuffleState
    bool isPlaying
    bool smartShuffle

    int progressMS
    int durationMS
}

void function debugPrint( string text ){
    printt( "\x1b[38;2;35;255;113m[\x1b[38;2;34;246;109mS\x1b[38;2;33;238;105mP\x1b[38;2;31;229;102mO\x1b[38;2;30;221;98mT\x1b[38;2;29;212;94mI\x1b[38;2;28;204;90mR\x1b[38;2;26;195;87mU\x1b[38;2;25;187;83mI\x1b[38;2;24;178;79m]\x1b[0m " + text )
}

void function debugPrintKillfeed( string text ){
    Obituary_Print_Localized( "`0" + text + " `1[SPOTIRUI]", <29, 212, 94>, <255, 255, 255>, <255, 255, 255>, <0, 0, 0>, 1.0 )
}

void function printCredentials(){
    debugPrint( "clientID: " + API.clientID )
    debugPrint( "clientSecret: " + API.clientSecret )
    debugPrint( "accessToken: " + API.accessToken )
    debugPrint( "refreshToken: " + API.refreshToken )
}

void function updateCredentialConvars(){
    table state = {
        finished = false
    }

    SetConVarString( "SPOTIRUI_CLIENT_ID", API.clientID )
    SetConVarString( "SPOTIRUI_CLIENT_SECRET", API.clientSecret )
    SetConVarString( "SPOTIRUI_ACCESS_TOKEN", API.accessToken )
    SetConVarString( "SPOTIRUI_REFRESH_TOKEN", API.refreshToken )

    void functionref( string ) onSuccess = void function( string content ) : ( state ){
        if( content == "" ){
            debugPrint( "updateCredentialConvars(): " + CREDENTIALS_FILEPATH + " is empty! Make sure you run 'RUNME.bat' first and try again" )
            debugPrintKillfeed( "updateCredentialConvars(): " + CREDENTIALS_FILEPATH + " is empty! Make sure you run 'RUNME.bat' first and try again" )
            state.finished = true
            return
        }

        table json = DecodeJSON( content )

        json[ "SPOTIRUI_CLIENT_ID"     ] = API.clientID    
        json[ "SPOTIRUI_CLIENT_SECRET" ] = API.clientSecret
        json[ "SPOTIRUI_ACCESS_TOKEN"  ] = API.accessToken 
        json[ "SPOTIRUI_REFRESH_TOKEN" ] = API.refreshToken

        NSSaveJSONFile( CREDENTIALS_FILEPATH, json )

        debugPrint( "updateCredentialConvars(): " + "Updated credentials in " + CREDENTIALS_FILEPATH )

        state.finished = true
    }

    NSLoadFile( CREDENTIALS_FILEPATH, onSuccess )

    while( !state.finished )
        wait 0
}

// taken from dtools
string function base64Encode( string input ){
    string BASE64_CHARS = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"

    string output = ""
    int i = 0
    int len = input.len()

    while( i < len ){
        int b1 = expect int( input[i++] )
        int b2 = ( i < len ) ? expect int( input[i++] ) : -1
        int b3 = ( i < len ) ? expect int( input[i++] ) : -1

        int triple = ( b1 << 16 ) | ( ( b2 != -1 ? b2 : 0 ) << 8 ) | ( b3 != -1 ? b3 : 0 )

        int i1 = ( triple >> 18 ) & 0x3F
        int i2 = ( triple >> 12 ) & 0x3F
        int i3 = ( triple >> 6  ) & 0x3F
        int i4 = triple & 0x3F

        output += BASE64_CHARS.slice( i1, i1 + 1 )
        output += BASE64_CHARS.slice( i2, i2 + 1 )

        if( b2 != -1 ){
            output += BASE64_CHARS.slice( i3, i3 + 1 )
        } else {
            output += "="
        }

        if ( b3 != -1 ){
            output += BASE64_CHARS.slice( i4, i4 + 1 )
        } else {
            output += "="
        }
    }

    return output
}

// taken from dtools
void function waitUntilAllThreadsFinished( array< void functionref() > threads ){   
    table state = {
        threadsFinished = 0,
        totalThreads = threads.len()
    }
    
    foreach( void functionref() threadFunc in threads ) {
        thread function() : ( threadFunc, state ) {
            threadFunc()
            state.threadsFinished++
        }()
    }
    
    while( state.threadsFinished < state.totalThreads )
        WaitFrame()
}

void function spotirui_Init(){
    thread function(){
        if( !setInitialCredentials() ){
            debugPrint( "Failed to initialize! :-(" )
            debugPrintKillfeed( "Failed to initialize! :-(" )
            return
        }

        setConfigConvars()
        updateCredentialConvars()
        //printCredentials()

        dtool_waitForValidGamestate( 4, monitorRUIVisibility )
        debugPrint( "Initialized! :-)" )
        debugPrintKillfeed( "Initialized! :-)" )
    }()  
}

void function setConfigConvars(){
    MAX_ARTIST_LENGTH = GetConVarInt( "SPOTIRUI_MAX_ARTIST_LENGTH" )
    MAX_SONG_TITLE_LENGTH = GetConVarInt( "SPOTIRUI_MAX_SONG_TITLE_LENGTH" )
    UPDATE_RATE = GetConVarFloat( "SPOTIRUI_UPDATE_RATE" )
}

bool function setInitialCredentials(){
    table state = {
        finished = false,
        response = false
    }

    void functionref( string ) onSuccess = void function( string content ) : ( state ){
        if( content == "" ){
            debugPrint( "setInitialCredentials(): " + CREDENTIALS_FILEPATH + " is empty! Make sure you run 'RUNME.bat' first and try again" )
            debugPrintKillfeed( CREDENTIALS_FILEPATH + " is empty! Make sure you run 'RUNME.bat' first and try again" )
            state.finished = true
            return
        }

        table json = DecodeJSON( content )

        API.clientID        = expect string( json[ "SPOTIRUI_CLIENT_ID"     ] )
        API.clientSecret    = expect string( json[ "SPOTIRUI_CLIENT_SECRET" ] )
        API.accessToken     = expect string( json[ "SPOTIRUI_ACCESS_TOKEN"  ] )
        API.refreshToken    = expect string( json[ "SPOTIRUI_REFRESH_TOKEN" ] )

        state.finished = true
        state.response = true
    } 

    if( !NSDoesFileExist( CREDENTIALS_FILEPATH ) ){
        debugPrint( "setInitialCredentials(): " + CREDENTIALS_FILEPATH + " could not be found! Make sure you run 'RUNME.bat' first and try again" )
        debugPrintKillfeed( CREDENTIALS_FILEPATH + " could not be found! Make sure you run 'RUNME.bat' first and try again" )
        state.finished = true
    }

    NSLoadFile( CREDENTIALS_FILEPATH, onSuccess )

    while( !state.finished )
        wait 0
    
    return expect bool( state.response )
}

table ornull function getPlaybackState(){
    table state = {
        finished = false,
        response = {}
    }

    HttpRequest request
    request.method = HttpRequestMethod.GET
    request.url = "https://api.spotify.com/v1/me/player"
    request.headers[ "Authorization" ] <- [ API.accessToken ]

    void functionref( HttpRequestResponse ) onSuccess = void function( HttpRequestResponse response ) : ( state ){
        if( response.statusCode == 401 ){
            debugPrint( "getPlaybackState(): " + "Refreshing access token" )
            debugPrintKillfeed( "Requesting new access token..." )
            thread refreshAccessToken()
            state.finished  = true
            state.response  = null
            return 
        }

        if( response.statusCode == 429 ){
            debugPrint( "getPlaybackState(): " + "Youre exceeding API rate limits" )
            debugPrintKillfeed( "Exceeding API rate limits!" )
            UPDATE_RATE = 1.0
            state.finished  = true
            state.response  = null
            return 
        }

        if( response.body == "" ){
            state.response = null
        } else {
            state.response = DecodeJSON( response.body )
        }

        state.finished  = true
    }

    void functionref( HttpRequestFailure ) onFailure = void function( HttpRequestFailure response ) : ( state ){
        debugPrint(
            format(
                "getPlaybackState(): " + "[%i] Failed to send HttpRequest to get playback state: %s",
                response.errorCode,
                response.errorMessage
            )
        )

        state.finished   = true
        state.response   = {}
    }

    NSHttpRequest(
        request,
        onSuccess,
        onFailure
    )

    while( !state.finished )
        wait 0

    if( state.response == null )
        return null

    return expect table( state.response )
}

void function refreshAccessTokenWrapper(){
    thread function(){
        if( !setInitialCredentials() )
            return
        refreshAccessToken()
    }()
}

void function refreshAccessToken(){
    //printCredentials()

    table state = {
        finished = false,
        response = {}
    }

    HttpRequest request
    request.method = HttpRequestMethod.POST

    request.url = "https://accounts.spotify.com/api/token"
    request.contentType = "application/x-www-form-urlencoded"

    request.body = "grant_type=refresh_token&refresh_token=" + API.refreshToken 

    request.headers[ "Authorization" ] <- [ "Basic " + base64Encode( format( "%s:%s", API.clientID, API.clientSecret ) ) ]
    
    void functionref( HttpRequestResponse ) onSuccess = void function( HttpRequestResponse response ) : ( state ){
        if( response.statusCode != 200){
            debugPrint( "refreshAccessToken(): " + format( "[%i] Failed trying to get new access token: %s", response.statusCode, DecodeJSON( response.body )["error"] ) )
            state.finished   = true
            return
        }

        table json = DecodeJSON( response.body )

        API.accessToken = "Bearer " + json[ "access_token" ]
        debugPrint( "refreshAccessToken(): " + "Received new access token: " + API.accessToken )
        debugPrintKillfeed( "Received new access token!" )

        if( "refresh_token" in json ){
            API.refreshToken = expect string( json[ "refresh_token" ] )
            debugPrint( "refreshAccessToken(): " + "Received new refresh token: " + API.refreshToken )
        }

        thread updateCredentialConvars()
        state.finished   = true
    }

    void functionref( HttpRequestFailure ) onFailure = void function( HttpRequestFailure response ) : ( state ){
        debugPrint(
            format(
                "refreshAccessToken(): " + "[%i] Failed to send HttpRequest for new access token: %s",
                response.errorCode,
                response.errorMessage
            )
        )

        state.finished   = true
    }

    NSHttpRequest(
        request,
        onSuccess,
        onFailure
    )

    while( !state.finished )
        wait 0
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// INGAME STUFF
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

struct{
    vector origin       = < 0.025, 0.4, 0.0 >

    var songName        = null
    var artists         = null
    var progressBar     = null
    var playbackStatus  = null
    var upcomingSong    = null

    bool isVisible      = true
    bool exists         = false
}RUI

var function createSongNameRUI(){
    var rui = RuiCreate( $"ui/cockpit_console_text_top_left.rpak", clGlobal.topoFullScreen, RUI_DRAW_HUD, 0 )
	RuiSetFloat( rui, "msgFontSize", 25.0 )
	RuiSetFloat( rui, "msgAlpha", 1.0 )
	RuiSetFloat( rui, "thicken", 0.0 )
	RuiSetString( rui, "msgText", "" )//"Song" )
	RuiSetFloat3( rui, "msgColor", <1, 1, 1> )
    RuiSetFloat2( rui, "msgPos", < RUI.origin.x, RUI.origin.y, RUI.origin.z > )

    return rui
}

var function createArtistRUI(){
    var rui = RuiCreate( $"ui/cockpit_console_text_top_left.rpak", clGlobal.topoFullScreen, RUI_DRAW_HUD, 0 )
	RuiSetFloat( rui, "msgFontSize", 15.0 )
	RuiSetFloat( rui, "msgAlpha", 1.0 )
	RuiSetFloat( rui, "thicken", 0.0 )
	RuiSetString( rui, "msgText", "" )//"Artist" )
	RuiSetFloat3( rui, "msgColor", <1, 1, 1> )
    RuiSetFloat2( rui, "msgPos", < RUI.origin.x, RUI.origin.y + 0.022, RUI.origin.z > )

    return rui    
}

var function createProgressBarRUI(){
    var rui = RuiCreate( $"ui/cockpit_console_text_top_left.rpak", clGlobal.topoFullScreen, RUI_DRAW_HUD, 0 )
	RuiSetFloat( rui, "msgFontSize", 15.0 )
	RuiSetFloat( rui, "msgAlpha", 1.0 )
	RuiSetFloat( rui, "thicken", 0.0 )
	RuiSetString( rui, "msgText", "" )//"[....................]" )
	RuiSetFloat3( rui, "msgColor", <1, 1, 1> )
    RuiSetFloat2( rui, "msgPos", < RUI.origin.x - 0.001, RUI.origin.y + 0.022 + 0.017 + 0.017, RUI.origin.z > )

    return rui
}

var function createPlaybackStatusRUI(){
    var rui = RuiCreate( $"ui/cockpit_console_text_top_left.rpak", clGlobal.topoFullScreen, RUI_DRAW_HUD, 0 )
	RuiSetFloat( rui, "msgFontSize", 15.0 )
	RuiSetFloat( rui, "msgAlpha", 1.0 )
	RuiSetFloat( rui, "thicken", 0.0 )
	RuiSetString( rui, "msgText", "" )//"0:00 / 0:00" )
	RuiSetFloat3( rui, "msgColor", <1, 1, 1> )
    RuiSetFloat2( rui, "msgPos", < RUI.origin.x, RUI.origin.y + 0.022 + 0.017, RUI.origin.z > )

    return rui
}

var function createUpcomingSongRUI(){
    var rui = RuiCreate( $"ui/cockpit_console_text_top_left.rpak", clGlobal.topoFullScreen, RUI_DRAW_HUD, 0 )
	RuiSetFloat( rui, "msgFontSize", 10.0 )
	RuiSetFloat( rui, "msgAlpha", 1.0 )
	RuiSetFloat( rui, "thicken", 0.0 )
	RuiSetString( rui, "msgText", "" )//"ERROR" )
	RuiSetFloat3( rui, "msgColor", <1, 1, 1> )
    RuiSetFloat2( rui, "msgPos", < RUI.origin.x, RUI.origin.y + 0.022 + 0.02 + 0.02 + 0.017, RUI.origin.z > )

    return rui
}

void function createSpotiRUI(){
    if( RUI.exists )
        return

    RUI.exists = true
    //debugPrintKillfeed( "Created RUI" )

    RUI.songName        = createSongNameRUI()
    RUI.artists         = createArtistRUI()
    RUI.progressBar     = createProgressBarRUI()
    RUI.playbackStatus  = createPlaybackStatusRUI()
    RUI.upcomingSong    = createUpcomingSongRUI()
}

void function destroySpotiRUI(){
    if( !RUI.exists )
        return

    RUI.exists = false

    //debugPrintKillfeed( "Destroyed RUI" )

    RuiDestroy( RUI.songName )
    RuiDestroy( RUI.artists )
    RuiDestroy( RUI.progressBar )
    RuiDestroy( RUI.playbackStatus )
    RuiDestroy( RUI.upcomingSong )

    RUI.songName        = null
    RUI.artists         = null
    RUI.progressBar     = null
    RUI.playbackStatus  = null
    RUI.upcomingSong    = null 
}

void function monitorRUIVisibility(){
    thread keepUpdatingRUI()

    for(;;){
        bool menuOpen = clGlobal.isMenuOpen

        if( menuOpen && RUI.exists )
            destroySpotiRUI()
        else if( !menuOpen && !RUI.exists && RUI.isVisible )
            createSpotiRUI()
        
        wait 0.1
    }
}

void function keepUpdatingRUI(){
    bool hasShownWarning = false

    for(;;){
        SONG songInfos = getSongInfos()
        if( !songInfos.hasValues ){
            if( !hasShownWarning ){
                debugPrintKillfeed( "Is the Spotify application running or paused?" )
                RUI.isVisible = false
                hasShownWarning = true
            }
            wait 5
            continue
        }

        if( hasShownWarning ){
            RUI.isVisible = true
            hasShownWarning = false
        }

        if( !RUI.exists ){
            wait UPDATE_RATE
            continue
        }
    
        RuiSetString( RUI.playbackStatus, "msgText", buildPlaybackStatusText( songInfos ) )
        RuiSetString( RUI.progressBar, "msgText", buildProgressBar( songInfos ) )
        RuiSetString( RUI.upcomingSong, "msgText", "@drachenfruchl" )

        if( PREVID != songInfos.id ){
            animateTransition( songInfos )
        } else {
            string artists = ""
            foreach( artist in songInfos.artists )
                artists += artist + ", "

            if( songInfos.artists.len() > 0 )
                artists = artists.slice( 0, -2 )

            artists = shortenArtists( artists )
            songInfos.name = shortenSongName( songInfos.name )

            RuiSetString( RUI.artists, "msgText", artists )
            RuiSetString( RUI.songName, "msgText", songInfos.name )
        }
        PREVID = songInfos.id 

        wait UPDATE_RATE
    }
}

void function animateTransition( SONG songInfos ){
    string artists = ""
    foreach( artist in songInfos.artists )
        artists += artist + ", "

    if( songInfos.artists.len() > 0 )
        artists = artists.slice( 0, -2 )
    
    artists = shortenArtists( artists )
    songInfos.name = shortenSongName( songInfos.name )

    array< void functionref() > threads = [
        void function() : ( songInfos ) { animateTransitionElement( RUI.songName, songInfos.name ) },
        void function() : ( artists )   { animateTransitionElement( RUI.artists, artists ) }
        //void function() : ( songInfos ) { animateTransitionElement( RUI.playbackStatus, buildPlaybackStatusText( songInfos ) ) },
        //void function() : ( songInfos ) { animateTransitionElement( RUI.progressBar, buildProgressBar( songInfos ) ) },
        //void function() : ( songInfos ) { animateTransitionElement( RUI.upcomingSong, "@drachenfruchl" ) },  
    ]

    debugPrint( "NOW PLAYING: " + songInfos.name + " - " + artists )
    debugPrintKillfeed( "NOW PLAYING: " + songInfos.name + " - " + artists )
	waitUntilAllThreadsFinished( threads )
}

void function animateTransitionElement( var rui, string text ){
    string textprog = ""

    int len = text.len()
    int i = 0

    while( i < len ){
        textprog += text.slice( i, i+1 )	
        RuiSetString( rui, "msgText", textprog )

        i++
        wait 0.05
    }
}

string function shortenSongName( string title ){
    int maxLen = MAX_SONG_TITLE_LENGTH

    if( title.len() <= maxLen )
        return title

    int lastSpaceIndex = -1

    for( int i = 0; i < maxLen; i++ ){
        string char = title.slice( i, i+1 )
        
        if( char == " " )
            lastSpaceIndex = i
    }

    if( lastSpaceIndex == -1 )
        lastSpaceIndex = maxLen

    return title.slice( 0, lastSpaceIndex ) + "..."
}

string function shortenArtists( string artists ){
    int maxLen = MAX_ARTIST_LENGTH

    if( artists.len() <= maxLen )
        return artists

    int lastCommaIndex = -1
    int lastSpaceIndex = -1

    for( int i = 0; i < maxLen; i++ ){
        string char = artists.slice( i, i+1 )

        if( char == "," )
            lastCommaIndex = i
        else if( char == " " )
            lastSpaceIndex = i
    }

    int cutIndex = -1

    if( lastCommaIndex != -1 )
        cutIndex = lastCommaIndex
    else if( lastSpaceIndex != -1 )
        cutIndex = lastSpaceIndex
    else
        cutIndex = maxLen

    return artists.slice( 0, cutIndex ) + "..."
}

string function buildProgressBar( SONG songInfos ){
    if( songInfos.durationMS <= 0 )
        return "[....................]"

    float progress = songInfos.progressMS.tofloat() / songInfos.durationMS.tofloat()
    
    if( progress < 0.0 )
        progress = 0.0
    else if( progress > 1.0 )
        progress = 1.0
    

    int barLen = floor( progress * 20 ).tointeger()
    string bar = ""

    for( int i = 0; i < barLen; i++ )
        bar += "|"

    for( int i = barLen; i < 20; i++ )
        bar += "."

    return format( "[%s]", bar )
}

string function buildPlaybackStatusText( SONG songInfos ){
    int progressSecTotal = songInfos.progressMS / 1000
    int progressMin = progressSecTotal / 60
    int progressSec = progressSecTotal % 60
    string progress = format( "%d:%02d", progressMin, progressSec )

    int durationSecTotal = songInfos.durationMS / 1000
    int durationMin = durationSecTotal / 60
    int durationSec = durationSecTotal % 60
    string duration = format( "%d:%02d", durationMin, durationSec )

    string repeatState = ""
    if( songInfos.repeatState == "context" )
        repeatState = "O"
    else if( songInfos.repeatState == "track" )
        repeatState = "O°"
    
    string shuffleState = ""
    if( songInfos.shuffleState )
        shuffleState = "X"
    else if( songInfos.smartShuffle )
        shuffleState = "X°"
    
    string isPlaying = ""
    if( songInfos.isPlaying )
        isPlaying = ">"
    else
        isPlaying = "II"

    string result = format( 
        "%s / %s - %s %s %s %s",
        progress,
        duration,
        songInfos.volumePercent.tostring() + "%",
        isPlaying,
        repeatState,
        shuffleState
    )

    return result 
}

SONG function getSongInfos(){
    SONG songInfos
    
    table ornull playbackState = getPlaybackState()
    
    if( !playbackState ){
        debugPrint( "getSongInfos(): Failed to fetch song data!" )
        return songInfos
    }
    expect table( playbackState )

    try{
        songInfos.hasValues      = true

        //SONG.album             = expect string( playbackState["item"]["album"]["name"] )
        songInfos.id             = expect string( playbackState["item"]["id"] )
        songInfos.name           = expect string( playbackState["item"]["name"] )
        songInfos.volumePercent  = expect int( playbackState["device"]["volume_percent"] )
        songInfos.repeatState    = expect string( playbackState["repeat_state"] )
        songInfos.shuffleState   = expect bool( playbackState["shuffle_state"] )
        songInfos.isPlaying      = expect bool( playbackState["is_playing"] )
        songInfos.smartShuffle   = expect bool( playbackState["smart_shuffle"] )
        songInfos.progressMS     = expect int( playbackState["progress_ms"] )
        songInfos.durationMS     = expect int( playbackState["item"]["duration_ms"] )

        array<string> artists = []
        foreach( table guy in playbackState["item"]["artists"] )
            artists.append( expect string( guy["name"] ) )
        songInfos.artists = artists
    }catch(e){
        debugPrint( "getSongInfos(): Could not successfully parse song infos" )
        debugPrintKillfeed( "Error whilst parsing song infos" )
    }

    return songInfos    
}