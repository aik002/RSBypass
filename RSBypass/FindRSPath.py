"""
Find out where RS2014 lives by asking steam in which libraryfolder it is placed

how do we do it? Steam keeps a database in vdf-format for that.
We only need the app id, which can be looked up at:
https://steamdb.info/ - it's 221680

1) Parse ~/Library/Application Support/Steam/steamapps/libraryfolders.vdf
2) find the "path" which holds RS2014's app id (221680)

Usually we would use a library to parse vdf and do it the right way(TM).
We can't bring one here, so what we do is: 

1) read vdf line by line
2) if line contains "path", extract the path and store it
3) if line cotains "apps" a list of (steam) apps in that path follows, we start looking for RS2014
4) if line contains "221680" we stop looping and print the stored path
5) if line contains "}" we stop looking for rs2014, clear any stored path and go back to (2)
6) if end of file is reached and the RS2014 has not been found, we print an error message

"""
import os
import sys

RS_STEAM_ID = "221680"
RS_LIB_PATH = os.path.expanduser(
    "~/Library/Application Support/Steam/steamapps/libraryfolders.vdf"
)

rs_path = ""
apps_section = False

if not os.path.exists(RS_LIB_PATH):
    print("Error: Could not find libraryfolders.vdf.", file=sys.stderr)
    exit(1)

with open(RS_LIB_PATH) as vdf:
    for line in vdf:
        if "path" in line:
            rs_path = line.replace('"path"', "").strip().replace('"', "")

        if "apps" in line:
            apps_section = True

        if apps_section and RS_STEAM_ID in line:
            break

        if "}" in line:
            apps_section = False
            rs_path = ""

if rs_path != "":
    print(rs_path)
else:
    print(
        "Error, could not find Rocksmith 2014 in installed steamapps.", file=sys.stderr
    )
    exit(1)
