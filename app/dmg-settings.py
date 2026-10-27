# dmgbuild settings for MacSweep.dmg (used by app/make-dmg.sh).
#   dmgbuild -s dmg-settings.py -D app=... -D background=... -D icon=... "MacSweep" out.dmg
import os.path

app = defines["app"]  # noqa: F821  (dmgbuild injects `defines`)
appname = os.path.basename(app)

format = "ULFO"            # lzfse, macOS 10.11+
filesystem = "APFS"
size = None
files = [app]
symlinks = {"Applications": "/Applications"}
icon = defines.get("icon")  # noqa: F821  volume icon
background = defines["background"]  # noqa: F821

window_rect = ((200, 140), (660, 400))
default_view = "icon-view"
show_status_bar = False
show_tab_view = False
show_toolbar = False
show_pathbar = False
show_sidebar = False
show_icon_preview = False
include_icon_view_settings = True
arrange_by = None
icon_size = 112
text_size = 13
label_pos = "bottom"
icon_locations = {appname: (170, 210), "Applications": (490, 210)}
hide_extensions = [appname]
