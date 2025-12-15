# Client
import requests
import webbrowser
import base64
import os
import threading
from time import sleep
import json

# Server
from http.server import BaseHTTPRequestHandler, HTTPServer
from urllib.parse import urlparse, parse_qs

# Main
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

print('Get these values from the dashboard of your spotify app')
CLIENT_ID = input('Client ID: ')
CLIENT_SECRET = input('Client secret: ')

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
    print('Failed to get authorization code')
    print('Server closed')
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
        print('Failed to get access token')
        SERVER.server_close()
        exit()

    json = req.json()
    ACCESS_TOKEN = 'Bearer ' + json['access_token']
    REFRESH_TOKEN = json['refresh_token']
get_access_token()

def create_save_dir_and_write_credentials():
    global CLIENT_ID
    global CLIENT_SECRET 
    global ACCESS_TOKEN
    global REFRESH_TOKEN

    file_path = input('Enter the full path to your modded directory (usually R2Northstar or R2Titanfall) save_data folder: ')
    
    while(True):
        try:
            os.chdir(file_path)
            break
        except FileNotFoundError:
            print(f'Directory "{file_path}" not found!\nEnter the full path to your modded directory (usually R2Northstar or R2Titanfall) save_data folder to retry: ')
            file_path = input()

    if not os.path.exists(f'{file_path}/drachenfruchl.spotiRUI'):
        print('Added directory "drachenfruchl.spotiRUI"')
        os.mkdir('drachenfruchl.spotiRUI')
    
    file_path += '/drachenfruchl.spotiRUI'
    os.chdir(file_path)

    if not os.path.exists(f'{file_path}/credentials.txt'):
        print('Created credentials.json')

    dic = {
        "SPOTIRUI_CLIENT_ID": CLIENT_ID,
        "SPOTIRUI_CLIENT_SECRET": CLIENT_SECRET,
        "SPOTIRUI_ACCESS_TOKEN": ACCESS_TOKEN,
        "SPOTIRUI_REFRESH_TOKEN": REFRESH_TOKEN
    }

    with open('credentials.json', 'w') as file:
        file.write(json.dumps(dic))

        print('Added SPOTIRUI_CLIENT_ID to credentials')
        print('Added SPOTIRUI_CLIENT_SECRET to credentials')
        print('Added SPOTIRUI_ACCESS_TOKEN to credentials')
        print('Added SPOTIRUI_REFRESH_TOKEN to credentials')
        
create_save_dir_and_write_credentials()
print('You should now be ready to launch your game')
print('You may close this window')