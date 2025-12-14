# Client
import requests
import webbrowser
import base64
import os
from dotenv import load_dotenv
import threading
from time import sleep
import json

# Server
from http.server import BaseHTTPRequestHandler, HTTPServer
from urllib.parse import urlparse, parse_qs

# def print_track_info(json):
#     print(f"Progress into song: {json['progress_ms']}ms - {json['progress_ms']/1000}s")
#     print(f"Duration: {json['item']['duration_ms']}ms - {json['item']['duration_ms']/1000}s")

# def current_playing():
#     endpoint = 'https://api.spotify.com/v1/me/player/currently-playing'

#     headers = {
#         'Authorization': ''
#     }

#     req = requests.get(endpoint, params={}, headers=headers)
#     json = req.json()

#     print(json)
#     print_track_info(json)
# current_playing()

# def refresh_tokens():
#     endpoint = 'https://accounts.spotify.com/api/token'

#     headers = {
#         'Authorization': '',
#     }

#     params = {
#         'grant_type': 'refresh_token',
#         'refresh_token': ''
#     }

#     req = requests.get(endpoint, params=params, headers=headers)






load_dotenv()

REDIRECT_URI = '127.0.0.1'
REDIRECT_URI_PORT = 8080

AUTHORIZATION_CODE = ''
ACCESS_TOKEN = ''
REFRESH_TOKEN = ''

SERVER = None

class Server(BaseHTTPRequestHandler):
    def log_message(self, format, *args):
        return
    def do_GET(self):   
        global AUTHORIZATION_CODE

        self.send_response(200)
        self.send_header("Content-type", "text/html")
        self.end_headers()

        parsed = urlparse( self.path )
        params = parse_qs( parsed.query )

        html = """
            <!DOCTYPE html>
            <html lang="en">
            <head>
                <meta charset="UTF-8">
                <meta name="viewport" content="width=device-width, initial-scale=1.0">
                <title>Redirect</title>
            </head>
            <body>
        """

        if 'error' in params:
            AUTHORIZATION_CODE = 'error'
            html += f"""
                <h1>
                    ERROR: 
                </h1>
                <h4>
                    {params['error'][0]}
                </h4>
            """
        elif 'code' in params:
            AUTHORIZATION_CODE = params['code'][0]

            html += f"""
                <h1>
                    You may close this window
                </h1>
                <h4>
                    {params['code'][0]}
                </h4>
            """ 

        html += """
            </body>
            </html>
        """

        self.wfile.write(html.encode('UTF-8'))

def start_local_server():
    global SERVER
    SERVER = HTTPServer((REDIRECT_URI, REDIRECT_URI_PORT), Server)

    print(f'Starting server, listening on {REDIRECT_URI}:{REDIRECT_URI_PORT}')
    SERVER.serve_forever()

CLIENT_ID = os.getenv('CLIENT_ID')
if CLIENT_ID is None:
    CLIENT_ID = input('CLIENT ID: ')

CLIENT_SECRET = os.getenv('CLIENT_SECRET')
if CLIENT_SECRET is None:
    CLIENT_SECRET = input('CLIENT SECRET: ')

threading.Thread(target=start_local_server).start()

def get_authorization_code():
    endpoint = 'https://accounts.spotify.com/authorize?'

    params = {
        'client_id': CLIENT_ID,
        'response_type': 'code',
        'redirect_uri': f'http://{REDIRECT_URI}:{REDIRECT_URI_PORT}',
        'show_dialog': 'true',
        'scope': 'user-read-currently-playing user-read-playback-state'
    }

    req = requests.get( endpoint, params=params )

    url = req.url
    print('Opening link in webbrowser for user authorization')
    webbrowser.open(url)
get_authorization_code()

def has_received_authorization_code():
    return AUTHORIZATION_CODE != ''

while not has_received_authorization_code():
    sleep(0.1)

if AUTHORIZATION_CODE == 'error':
    print( 'Failed to get authorization code')
    print( 'Server closed' )
    SERVER.server_close()
    exit()

print('Received authorization code')

def get_access_token():
    global ACCESS_TOKEN
    global REFRESH_TOKEN

    auth_bytes = (CLIENT_ID + ':' + CLIENT_SECRET).encode("ascii")
    auth_base64 = base64.b64encode(auth_bytes).decode("ascii")

    endpoint = 'https://accounts.spotify.com/api/token'

    params = {
        'grant_type': 'authorization_code',
        'code': AUTHORIZATION_CODE,
        'redirect_uri': f'http://{REDIRECT_URI}:{REDIRECT_URI_PORT}'
    }

    headers = {
        'Authorization': 'Basic ' + auth_base64,
        'Content-Type': 'application/x-www-form-urlencoded'
    }

    req = requests.post(endpoint, params=params, headers=headers)

    if req.status_code != 200:
        print( 'Failed to get access token')
        SERVER.server_close()
        exit()

    json = req.json()
    ACCESS_TOKEN = 'Bearer ' + json['access_token']
    REFRESH_TOKEN = json['refresh_token']
get_access_token()

# def write_credentials_to_profile_cfg():
#     #create_save_folder()
    
#     global CLIENT_ID
#     global CLIENT_SECRET 
#     global ACCESS_TOKEN
#     global REFRESH_TOKEN

#     has_id = False
#     has_secret = False
#     has_access_token = False
#     has_refresh_token = False

#     path_to_profile = f'C:/Users/{os.getlogin()}/Documents/Respawn/Titanfall2/profile/profile.cfg'

#     while(True):
#         try:
#             with open(path_to_profile) as file:
#                 previous_content = file.readlines()
#             break
#         except FileNotFoundError:
#             print( f'profile.cfg in "{path_to_profile}" could not be found!\nEnter the filepath of your profile.cfg to retry: ')
#             path_to_profile = input()

#     for idx, entry in enumerate(previous_content):
#         stripped = entry.strip()
#         if stripped.startswith('SPOTIRUI_CLIENT_ID'):
#             previous_content[idx] = f'SPOTIRUI_CLIENT_ID "{CLIENT_ID}"\n'
#             has_id = True
#             print('Updated SPOTIRUI_CLIENT_ID in profile.cfg')

#         elif stripped.startswith('SPOTIRUI_CLIENT_SECRET'):
#             previous_content[idx] = f'SPOTIRUI_CLIENT_SECRET "{CLIENT_SECRET}"\n'
#             has_secret = True
#             print('Updated SPOTIRUI_CLIENT_SECRET in profile.cfg')

#         elif stripped.startswith('SPOTIRUI_ACCESS_TOKEN'):
#             previous_content[idx] = f'SPOTIRUI_ACCESS_TOKEN "{ACCESS_TOKEN}"\n'
#             has_access_token = True
#             print('Updated SPOTIRUI_ACCESS_TOKEN in profile.cfg')

#         elif stripped.startswith('SPOTIRUI_REFRESH_TOKEN'):
#             previous_content[idx] = f'SPOTIRUI_REFRESH_TOKEN "{REFRESH_TOKEN}"\n'
#             has_refresh_token = True
#             print('Updated SPOTIRUI_REFRESH_TOKEN in profile.cfg')


#     if not has_id:
#         previous_content.append(f'SPOTIRUI_CLIENT_ID "{CLIENT_ID}"\n')
#         print('Added SPOTIRUI_CLIENT_ID to profile.cfg')
#     if not has_secret:
#         previous_content.append(f'SPOTIRUI_CLIENT_SECRET "{CLIENT_SECRET}"\n')
#         print('Added SPOTIRUI_CLIENT_SECRET to profile.cfg')
#     if not has_access_token:
#         previous_content.append(f'SPOTIRUI_ACCESS_TOKEN "{ACCESS_TOKEN}"\n')
#         print('Added SPOTIRUI_ACCESS_TOKEN to profile.cfg')
#     if not has_refresh_token:
#         previous_content.append(f'SPOTIRUI_REFRESH_TOKEN "{REFRESH_TOKEN}"\n')
#         print('Added SPOTIRUI_REFRESH_TOKEN to profile.cfg')
    
#     with open(path_to_profile, 'w' ) as file:
#         file.writelines(previous_content)
    
#     print('Updated your profile.cfg - You can now start the game if you havent already done so')
# write_credentials_to_profile_cfg()
# input()

def create_save_dir_and_write_credentials():
    global CLIENT_ID
    global CLIENT_SECRET 
    global ACCESS_TOKEN
    global REFRESH_TOKEN

    file_path = 'C:/Program Files (x86)/Steam/steamapps/common/Titanfall2/R2Northstar/save_data'
    
    while(True):
        try:
            os.chdir(file_path)
            break
        except FileNotFoundError:
            print(f'Directory "{file_path}" not found!\nEnter the full path to your modded directory (R2Northstar or R2Titanfall) save_data folder to retry:')
            file_path = input()

    if not os.path.exists(f'{file_path}/drachenfruchl.spotiRUI'):
        print('Added directory "drachenfruchl.spotiRUI"')
        os.mkdir('drachenfruchl.spotiRUI')
    
    file_path += '/drachenfruchl.spotiRUI'
    os.chdir(file_path)

    if not os.path.exists(f'{file_path}/credentials.txt'):
        print('Added file "credentials.json"')

    dic = {
        "SPOTIRUI_CLIENT_ID": CLIENT_ID,
        "SPOTIRUI_CLIENT_SECRET": CLIENT_SECRET,
        "SPOTIRUI_ACCESS_TOKEN": ACCESS_TOKEN,
        "SPOTIRUI_REFRESH_TOKEN": REFRESH_TOKEN
    }

    with open('credentials.json', 'w') as file:
        file.write(json.dumps(dic))
        # file.write(f'SPOTIRUI_CLIENT_ID={CLIENT_ID}\n')
        print('Added SPOTIRUI_CLIENT_ID to credentials.json')

        # file.write(f'SPOTIRUI_CLIENT_SECRET={CLIENT_SECRET}\n')
        print('Added SPOTIRUI_CLIENT_SECRET to credentials.json')

        # file.write(f'SPOTIRUI_ACCESS_TOKEN={ACCESS_TOKEN}\n')
        print('Added SPOTIRUI_ACCESS_TOKEN to credentials.json')

        # file.write(f'SPOTIRUI_REFRESH_TOKEN={REFRESH_TOKEN}\n')
        print('Added SPOTIRUI_REFRESH_TOKEN to credentials.json')




create_save_dir_and_write_credentials()
input("You may close this window now")