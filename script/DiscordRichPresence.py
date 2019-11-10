import rpc
import time

from PIL import Image, ImageGrab
import win32api
import win32con
import win32gui

# variables that can be configured
DEBUG = 1
# MY_WIDTH = 12 # 1080p 100%
MY_WIDTH = 15 # 1080p 125%
DISCORD_CLIENT_ID = 'YOUR_CLIENT_ID_HERE'
WOW_ICON = '1024px-wow_icon'


# these are internal use variables, don't touch them
decoded = ''
wow_hwnd = None
rpc_obj = None
last_first_line = None
last_second_line = None


def callback(hwnd, extra):
    global wow_hwnd
    if (win32gui.GetWindowText(hwnd) == 'World of Warcraft' and
            win32gui.GetClassName(hwnd).startswith('GxWindowClass')):
        wow_hwnd = hwnd


def read_squares(hwnd):
    rect = win32gui.GetWindowRect(hwnd)
    height = (win32api.GetSystemMetrics(win32con.SM_CYCAPTION) +
              win32api.GetSystemMetrics(win32con.SM_CYBORDER) * 4 +
              win32api.GetSystemMetrics(win32con.SM_CYEDGE) * 2)
    new_rect = (rect[0], rect[1], rect[2], MY_WIDTH)
    try:
        im = ImageGrab.grab(new_rect)
    except Image.DecompressionBombError:
        print('DecompressionBombError')
        return

    read = []
    for square_idx in range(int(im.width / MY_WIDTH)):
        x = int(square_idx * MY_WIDTH + MY_WIDTH / 2)
        y = int(MY_WIDTH / 2)
        r, g, b = im.getpixel((x, y))

        if DEBUG:
            im.putpixel((x, y), (255, 255, 255))

        if r == g == b == 0:
            break

        read.append(r)
        read.append(g)
        read.append(b)

    try:
        decoded = bytes(read).decode('utf-8').rstrip('\0')
    except Exception as exc:
        if not DEBUG:
            return
    parts = decoded.replace('$WorldOfWarcraftDRP$', '').split('|')

    if DEBUG:
        im.show()
        return

    # sanity check
    if (len(parts) != 2 or
            not decoded.endswith('$WorldOfWarcraftDRP$') or
            not decoded.startswith('$WorldOfWarcraftDRP$')):
        return

    first_line, second_line = parts

    return first_line, second_line


while True:
    wow_hwnd = None
    win32gui.EnumWindows(callback, None)

    if DEBUG:
        # if in debug mode, squares are read, the image with the dot matrix is
        # shown and then the script quits.
        if wow_hwnd:
            print('Debug: reading squares. Is everything alright?')
            read_squares(wow_hwnd)
        else:
            print("Launching in debug mode but I couldn't find WoW.")
        break
    elif win32gui.GetForegroundWindow() == wow_hwnd:
        lines = read_squares(wow_hwnd)

        if not lines:
            time.sleep(1)
            continue

        first_line, second_line = lines

        if first_line != last_first_line or second_line != last_second_line:
            # there has been an update, so send it to discord
            last_first_line = first_line
            last_second_line = second_line

            if not rpc_obj:
                print('Not connected to Discord, connecting...')
                while True:
                    try:
                        rpc_obj = (rpc.DiscordIpcClient
                                   .for_platform(DISCORD_CLIENT_ID))
                    except Exception as exc:
                        print("I couldn't connect to Discord (%s). It's "
                              'probably not running. I will try again in 5 '
                              'sec.' % str(exc))
                        time.sleep(5)
                        pass
                    else:
                        break
                print('Connected to Discord.')

            print('Setting new activity: %s - %s' % (first_line, second_line))
            activity = {
                'details': first_line,
                'state': second_line,
                'assets': {
                    'large_image': WOW_ICON
                }
            }

            try:
                rpc_obj.set_activity(activity)
            except Exception as exc:
                print('Looks like the connection to Discord was broken (%s). '
                      'I will try to connect again in 5 sec.' % str(exc))
                last_first_line, last_second_line = None, None
                rpc_obj = None
    elif not wow_hwnd and rpc_obj:
        print('WoW no longer exists, disconnecting')
        rpc_obj.close()
        rpc_obj = None
        # clear these so it gets reread and resubmitted upon reconnection
        last_first_line, last_second_line = None, None
    time.sleep(5)
