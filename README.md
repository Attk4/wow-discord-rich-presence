# Discord rich presence for World of Warcraft

Important: this requires a bit of patience and setup to make it work, so bear with me.
This fork works with Retail.

## Requirements

- Python 3 for Windows, the [web-based installer](https://www.python.org/downloads/windows/) is OK. When it's finished installing, you will be asked if you want Python to be added to your $PATH, you have to say yes.

## Setup

1. [Download a copy of this repo](https://github.com/Attk4/wow-discord-rich-presence/archive/master.zip) and decompress it. Inside you will find a WoW addon and a Python script.

2. Install the WoW addon by copying the DiscordRichPresence folder to your _Interface/AddOns_ directory. When you log in, type **/drptest** into your chat, and you will see a few coloured squares on top of your portrait.

   ![Squares](https://github.com/Attk4/wow-discord-rich-presence/raw/master/images/squares.png)

3. Open a Command Prompt and install the pywin32 and Pillow libraries for Python by typing this command:
   `pip install pywin32 pillow`

4. Move to the directory where you decompressed this repo with the cd command, then cd into the **script** folder. For example, if you decompressed it into your Downloads folder, you will have to do something like this:
   `cd Downloads\wow-discord-rich-presence\script`

5. Rename config\_.json to config.json

6. Go back to the command prompt while WoW is still open behind it, making sure none of the squares are being covered by the command prompt, and type this to run the DiscordRichPresence.py script:
   `python DiscordRichPresence.py`

7. Now, this is the tricky part. Your image viewer has opened and you might see something like this:

   ![Misaligned dots](https://github.com/Attk4/wow-discord-rich-presence/raw/master/images/misaligned-squares.png)

   That's really bad! Every one of the white dots has to be right at the centre of every one of the squares.

8. Open config.json with a text editor. You will see a variable called `my_width` at the top. You have to tweak it and run the DiscordRichPresence.py script again (remember, using `python DiscordRichPresence.py`) until all the dots are aligned. Most likely you will have to use decimals. In the end, it will look like this:

   ![Aligned dots](https://github.com/Attk4/wow-discord-rich-presence/raw/master/images/aligned-squares.png)

9. Create a new Discord Application at https://discordapp.com/developers/applications/ called `World of Warcraft`, copy the Client ID, and add the World of Warcraft logo and your Character icon as a Rich Presence Asset.

10. Edit the config.json file again, this time change `debug` to false, `discord_client_id` to your copied Client ID and `wow_icon` to the name of the icon without the extension.

11. You can now clean your window by typing **/drpclean**. On certain events (player login, zone change, revive) the squares will appear automatically, then disappear after 5 seconds. If it fails to update, you can use **/drp** to trigger this manually.

From now on, you can double-click the DiscordRichPresence.py file and it will work by itself. Your rich presence will be updated automatically as long as the script is kept running. You can just create a shortcut to this script on your Desktop and open it every time you open WoW.

## Licence

Both the addon and the DiscordRichPresence.py script are in the public domain.
The rpc.py file is from [this repo](https://github.com/suclearnub/python-discord-rpc) and it's [MIT licenced](https://raw.githubusercontent.com/wodim/wow-discord-rich-presence/master/script/rpc.py-LICENSE).
