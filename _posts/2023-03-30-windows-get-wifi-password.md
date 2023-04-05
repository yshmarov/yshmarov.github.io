---
layout: post
title: "Find a saved WIFI password on Windows 10 or Windows 11"
author: Yaroslav Shmarov
tags: windows password
thumbnail: /assets/thumbnails/windows.png
---

I sometimes need to find a password on my Windows computer, but Windows keeps getting new updates all the time and changing things.

Nevertheless, there is one easy way to find a saved wifi password stays valid no matter what version of Windows you are on.

First, open the **command prompt**:

![windows-wifi-command-prompt.png](/assets/images/windows-open-command-prompt.png)

Type this in the command prompt to display all the saved WIFI Network names:

```shell
netsh wlan show profiles
```

![windows-wifi-list.png](/assets/images/windows-wifi-list.png)

Type this in the command prompt to display the details of any network:

```shell
netsh wlan show profile name="NETWORK" key=clear
```

In my case, I wanted to get the password of the network named `Biblioteka`, so I typed:

```shell
netsh wlan show profile name="Biblioteka" key=clear
```

The saved network password is highlighted in blue:

![windows-wifi-password.png](/assets/images/windows-wifi-password.png)

That's it!
