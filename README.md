# Man Viewer
Man Viewer is an easy to use program to view the man pages that are installed on the current system. The user can search and filter the man pages based on name and section. The user can also export the man page to plain text and styled PostScript.

- Universal so it runs natively on PowerPC and x86 Macs
- macOS 10.5 (Leopard) or higher

[Direct binary download](http://kendallp.net/public/files/software/man_viewer_320.dmg)

![screenshot](https://user-images.githubusercontent.com/16943066/33195584-2b343944-d096-11e7-84e4-d0f6055903c5.png)

Change log:
- 3.2
  - Added tabbed viewing
  - Resizing the window will resize the manpage output
  - Added a command line tool. Install it via the Man Viewer menu
  - Start up is more threaded now so no more spinning beachballs
- 3.1.3
  - Fixed: The window size and split view remembers its position between subsequent launches for real
  - Tooltips show the path to the man page upon hovering over the entry in the list
  - Upon right/control clicking on a man page in the list, a context menu pops up allowing the user to reveal the man page in the Finder
- 3.1.2
  - Fixed a bug that made Man Viewer incorrectly state that "That man page does not exist!" when, in reality, it definitely existed
  - The window close button is now activated and will quit the application if pressed
  - You can now have Man Viewer launch and auto select a man page by passing the name (and optionally the section) as a command line argument
  - If you load MacPorts' man pages, you should no longer see (turd_MacPorts) in the list
- 3.1.1
  - Changed the $MANPATH feature to use /usr/bin/manpath instead (this is for Snow Leopard users or those who have an empty $MANPATH environment variable)
  - Fixed the manpath feature so that it uses your default login shell instead of just bash (this is for those who don't use bash as your login shell)
  - Upon clicking on a different man page, the viewer scrolls to the top so you see the beginning whether or not you were scrolled down in the previous man page
  - Fixed some minor bugs in the preferences pane
- 3.1
  - Refactored some code so that initial launch times are extremely fast compared to previous versions!
  - Added a caching feature so after the initial launch, future launches will yet be even faster
  - On first run the preferences default to what $MANPATH is set to. Also there is now a button in the preferences that allows you to revert the preferences to $MANPATH
- 3.0.1
  - Fixed a bug that made the program crash when trying to view a large man page
- 3.0
  - Programmed in Cocoa, therefore Man Viewer is a Universal Binary, faster, smaller, and better!
  - Preferences have been improved
  - Faster searching
  - Support for macOS 10.5 with no .gz duplicates
