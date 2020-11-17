This is just a repo housing my scripts that I wrote for my usage of i3 window manager.

# Scripts
## Switcher
Switcher is a script that I wrote to backfill a feature that I long missed from my days using GNOME. Since I had windows, and not the whole workspaces mapped to Super+{1..9}, I could easily switch back and forth between apps, and between multiple instances of the same app.
The i3 workflow is much better when it comes to window management, but I often wished to have something like that. Thus, on one night I sat down and wrote switcher. The usage is simple: just pass a window class as the first arg, and then maybe a direction (next/previous) as the second one. Everything else will be done for you.
Example i3 config snippet that uses switcher:
```
bindsym $mod+a mode "app-switcher"
mode "app-switcher" {
    # Switch to app passed as the first arg
    bindsym f exec $i3_scripts_dir/switcher.bash Firefox; mode "default";
    bindsym Shift+f exec $i3_scripts_dir/switcher.bash Firefox previous; mode "default";

    bindsym d exec $i3_scripts_dir/switcher.bash discord; mode "default";
    bindsym Shift+d exec $i3_scripts_dir/switcher.bash discord previous; mode "default";

    bindsym Return mode "default"
    bindsym Escape mode "default"
    bindsym $mod+a mode "default"
}
```
