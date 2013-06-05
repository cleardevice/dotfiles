--------------------------------------------------------------------------------------------
-- File   : ~/.xmonad/xmonad.hs                                                           --
-- Author : Nnoell <nnoell3[at]gmail.com>                                                 --
-- Deps   : DzenBoxLogger.hs                                                              --
-- Desc   : My XMonad config                                                              --
-- Note   : Do not use "xmonad --recompile", it will throw errors because of non-official --
--          modules. Compile it manually with "ghc -o <outputName> xmonad.hs". EG:        --
--          $ cd ~/.xmonad/                                                               --
--          $ ghc -o xmonad-x86_64-linux xmonad.hs                                        --
--------------------------------------------------------------------------------------------

-- Language
{-# LANGUAGE DeriveDataTypeable, NoMonomorphismRestriction, TypeSynonymInstances, MultiParamTypeClasses,  ImplicitParams, PatternGuards #-}

-- Modules
import XMonad
import XMonad.Core
import XMonad.Layout
import XMonad.Layout.IM
import XMonad.Layout.Gaps
import XMonad.Layout.Named
import XMonad.Layout.Tabbed
import XMonad.Layout.OneBig
import XMonad.Layout.Master
import XMonad.Layout.Reflect
import XMonad.Layout.MosaicAlt
import XMonad.Layout.NoFrillsDecoration
import XMonad.Layout.SimplestFloat
import XMonad.Layout.NoBorders (noBorders,smartBorders,withBorder)
import XMonad.Layout.ResizableTile
import XMonad.Layout.MultiToggle
import XMonad.Layout.MultiToggle.Instances
import XMonad.Layout.PerWorkspace (onWorkspace)
import XMonad.Layout.Minimize
import XMonad.Layout.Maximize
import XMonad.Layout.WindowNavigation
import XMonad.StackSet (RationalRect (..), currentTag)
import XMonad.Hooks.DynamicLog
import XMonad.Hooks.DynamicHooks
import XMonad.Hooks.ManageDocks
import XMonad.Hooks.UrgencyHook
import XMonad.Hooks.EwmhDesktops
import XMonad.Hooks.SetWMName
import XMonad.Hooks.ManageHelpers
import XMonad.Prompt
import XMonad.Prompt.Shell
import XMonad.Prompt.XMonad
import XMonad.Prompt.Man
import XMonad.Util.Timer
import XMonad.Util.Cursor
import XMonad.Util.Loggers
import XMonad.Util.EZConfig
import XMonad.Util.Run (spawnPipe)
import XMonad.Util.Scratchpad
import XMonad.Util.NamedScratchpad
import XMonad.Actions.CycleWS
import XMonad.Actions.ShowText
import XMonad.Actions.GridSelect
import XMonad.Actions.MouseResize
import Data.IORef
import Data.Monoid
import Data.List
import Graphics.X11.ExtraTypes.XF86
import System.Exit
import System.IO (Handle, hPutStrLn)
import Control.Exception as E
import qualified XMonad.StackSet as W
import qualified Data.Map as M
import qualified XMonad.Actions.FlexibleResize as Flex
import qualified XMonad.Util.ExtensibleState as XS

-- non-official modules
import DzenBoxLoggers

-- Main
main :: IO ()
main = do
	spawn "/home/nnoell/bin/cpuUsage.sh 0"
	spawn "/home/nnoell/bin/cpuUsage.sh 1"
	spawn "/home/nnoell/bin/cpuUsage.sh 2"
	spawn "/home/nnoell/bin/cpuUsage.sh 3"
	topLeftBar              <- spawnPipe myTopLeftBar
	topRightBar             <- spawnPipe myTopRightBar
	botLeftBar              <- spawnPipe myBotLeftBar
	botRightBar             <- spawnPipe myBotRightBar
	focusFollow             <- newIORef True; let ?focusFollow = focusFollow
	xmonad $ myUrgencyHook $ defaultConfig
		{ terminal           = "urxvtc"
		, modMask            = mod4Mask
		, focusFollowsMouse  = False
		, borderWidth        = 1
		, normalBorderColor  = colorBlackAlt
		, focusedBorderColor = colorGray
		, layoutHook         = myLayoutHook
		, workspaces         = myWorkspaces
		, manageHook         = myManageHook <+> manageScratchPad <+> manageDocks <+> dynamicMasterHook
		, logHook            = myLogHook botLeftBar <+> myLogHook1 botRightBar <+> myLogHook2 topLeftBar <+> myLogHook3 topRightBar <+> ewmhDesktopsLogHook >> setWMName "LG3D"
		, handleEventHook    = myHandleEventHook
		, keys               = myKeys
		, mouseBindings      = myMouseBindings
		, startupHook        = setDefaultCursor xC_left_ptr <+> (startTimer 1 >>= XS.put . TID)
		}
		`additionalKeysP`
		[ ("<XF86TouchpadToggle>", spawn "/home/nnoell/bin/touchpadtoggle.sh") --because xF86XK_TouchpadToggle doesnt exist
		, ("M-v", io $ modifyIORef ?focusFollow not)                           --Toggle focus follow moouse
		]


--------------------------------------------------------------------------------------------
-- LOOK AND FEEL CONFIG                                                                   --
--------------------------------------------------------------------------------------------

-- Colors, fonts and paths
dzenFont             = "-*-montecarlo-medium-r-normal-*-11-*-*-*-*-*-*-*"
colorBlack           = "#020202" --Background (Dzen_BG)
colorBlackAlt        = "#1c1c1c" --Black Xdefaults
colorGray            = "#444444" --Gray       (Dzen_FG2)
colorGrayAlt         = "#101010" --Gray dark
colorWhite           = "#a9a6af" --Foreground (Shell_FG)
colorWhiteAlt        = "#9d9d9d" --White dark (Dzen_FG)
colorMagenta         = "#8e82a2"
colorBlue            = "#44aacc"
colorBlueAlt         = "#3955c4"
colorRed             = "#f7a16e"
colorRedAlt          = "#e0105f"
colorGreen           = "#66ff66"
colorGreenAlt        = "#558965"
boxLeftIcon          = "/home/nnoell/.icons/xbm_icons/subtle/boxleft.xbm"  -- left icon of dzen logger boxes
boxRightIcon         = "/home/nnoell/.icons/xbm_icons/subtle/boxright.xbm" -- right icon of dzen logger boxes
xRes                 = 1366
yRes                 = 768
panelHeight          = 16  -- height of top and bottom panels
boxHeight            = 12  -- height of dzen logger box
topPanelSepPos       = 950 -- left-right alignment pos of top panel
botPanelSepPos       = 400 -- left-right alignment pos of bottom panel

-- Title theme
myTitleTheme :: Theme
myTitleTheme = defaultTheme
	{ fontName            = dzenFont
	, inactiveBorderColor = colorBlackAlt
	, inactiveColor       = colorBlack
	, inactiveTextColor   = colorGray
	, activeBorderColor   = colorGray
	, activeColor         = colorBlackAlt
	, activeTextColor     = colorWhiteAlt
	, urgentBorderColor   = colorGray
	, urgentTextColor     = colorGreen
	, decoHeight          = 14
	}

-- Prompt theme
myXPConfig :: XPConfig
myXPConfig = defaultXPConfig
	{ font                = dzenFont
	, bgColor             = colorBlack
	, fgColor             = colorWhite
	, bgHLight            = colorBlue
	, fgHLight            = colorBlack
	, borderColor         = colorGrayAlt
	, promptBorderWidth   = 1
	, height              = panelHeight
	, position            = Top
	, historySize         = 100
	, historyFilter       = deleteConsecutive
	, autoComplete        = Nothing
	}

-- GridSelect color scheme
myColorizer :: Window -> Bool -> X (String, String)
myColorizer = colorRangeFromClassName
	(0x00,0x00,0x00) -- lowest inactive bg
	(0x1C,0x1C,0x1C) -- highest inactive bg
	(0x44,0xAA,0xCC) -- active bg
	(0xBB,0xBB,0xBB) -- inactive fg
	(0x00,0x00,0x00) -- active fg

-- GridSelect theme
myGSConfig :: t -> GSConfig Window
myGSConfig colorizer = (buildDefaultGSConfig myColorizer)
	{ gs_cellheight  = 50
	, gs_cellwidth   = 200
	, gs_cellpadding = 10
	, gs_font        = dzenFont
	}

-- Flash text config
myTextConfig :: ShowTextConfig
myTextConfig = STC
	{ st_font = dzenFont
	, st_bg = colorBlack
	, st_fg = colorWhite
    }

-- Dzen logger box pretty printing themes
grayBoxPP :: BoxPP
grayBoxPP = BoxPP { bgColorBPP   = colorBlack
				  , fgColorBPP   = colorGray
				  , boxColorBPP  = colorGrayAlt
				  , leftIconBPP  = boxLeftIcon
				  , rightIconBPP = boxRightIcon
				  , boxHeightBPP = boxHeight
				  }

blueBoxPP :: BoxPP
blueBoxPP = BoxPP { bgColorBPP   = colorBlack
				  , fgColorBPP   = colorBlue
				  , boxColorBPP  = colorGrayAlt
				  , leftIconBPP  = boxLeftIcon
				  , rightIconBPP = boxRightIcon
				  , boxHeightBPP = boxHeight
				  }

whiteBoxPP :: BoxPP
whiteBoxPP = BoxPP { bgColorBPP   = colorBlack
				   , fgColorBPP   = colorWhiteAlt
				   , boxColorBPP  = colorGrayAlt
				   , leftIconBPP  = boxLeftIcon
				   , rightIconBPP = boxRightIcon
				   , boxHeightBPP = boxHeight
				   }

blackBoxPP :: BoxPP
blackBoxPP = BoxPP { bgColorBPP   = colorBlack
				   , fgColorBPP   = colorBlack
				   , boxColorBPP  = colorGrayAlt
				   , leftIconBPP  = boxLeftIcon
				   , rightIconBPP = boxRightIcon
				   , boxHeightBPP = boxHeight
				   }

whiteBBoxPP :: BoxPP
whiteBBoxPP = BoxPP { bgColorBPP   = colorBlack
					, fgColorBPP   = colorBlack
					, boxColorBPP  = colorWhiteAlt
					, leftIconBPP  = boxLeftIcon
					, rightIconBPP = boxRightIcon
					, boxHeightBPP = boxHeight
					}

blueBBoxPP :: BoxPP -- current workspace
blueBBoxPP = BoxPP { bgColorBPP   = colorBlack
				   , fgColorBPP   = colorBlack
				   , boxColorBPP  = colorBlue
				   , leftIconBPP  = boxLeftIcon
				   , rightIconBPP = boxRightIcon
				   , boxHeightBPP = boxHeight
				   }

greenBBoxPP :: BoxPP -- urgent workspace
greenBBoxPP = BoxPP { bgColorBPP   = colorBlack
					, fgColorBPP   = colorBlack
					, boxColorBPP  = colorGreen
					, leftIconBPP  = boxLeftIcon
					, rightIconBPP = boxRightIcon
					, boxHeightBPP = boxHeight
					}

-- Dzen logger clickable areas
calendarCA :: CA
calendarCA = CA { leftClickCA   = "/home/nnoell/bin/dzencal.sh"
				, middleClickCA = ""
				, rightClickCA  = ""
				, wheelUpCA     = ""
				, wheelDownCA   = ""
				}

layoutCA :: CA
layoutCA = CA { leftClickCA   = "/usr/bin/xdotool key super+space"
			  , middleClickCA = ""
			  , rightClickCA  = "/usr/bin/xdotool key super+shift+space"
			  , wheelUpCA     = ""
			  , wheelDownCA   = ""
			  }

workspaceCA :: CA
workspaceCA = CA { leftClickCA   = "/usr/bin/xdotool key super+1"
				 , middleClickCA = "/usr/bin/xdotool key super+g"
				 , rightClickCA  = "/usr/bin/xdotool key super+0"
				 , wheelUpCA     = ""
				 , wheelDownCA   = ""
				 }

focusCA :: CA
focusCA = CA { leftClickCA   = "/usr/bin/xdotool key super+m"
			 , middleClickCA = "/usr/bin/xdotool key super+c"
			 , rightClickCA  = "/usr/bin/xdotool key super+shift+m"
			 , wheelUpCA     = ""
			 , wheelDownCA   = ""
			 }

-- Workspaces
myWorkspaces :: [WorkspaceId]
myWorkspaces = ["1", "2", "3", "4", "5", "6", "7", "8", "9", "0"]


--------------------------------------------------------------------------------------------
-- LAYOUT CONFIG                                                                          --
--------------------------------------------------------------------------------------------

-- Layouts (name must be diferent of Minimize, Maximize and Mirror)
myTile = named "ResizableTall"     $ smartBorders $ ResizableTall 1 0.03 0.5 []
myMirr = named "MirrResizableTall" $ smartBorders $ Mirror myTile
myMosA = named "MosaicAlt"         $ smartBorders $ MosaicAlt M.empty
myObig = named "OneBig"            $ smartBorders $ OneBig 0.75 0.65
myTabs = named "Simple Tabbed"     $ smartBorders $ tabbed shrinkText myTitleTheme
myFull = named "Full Tabbed"       $ smartBorders $ tabbedAlways shrinkText myTitleTheme
myTabM = named "Master Tabbed"     $ smartBorders $ mastered 0.01 0.4 $ tabbed shrinkText myTitleTheme
myFlat = named "Simple Float"      $ mouseResize  $ noFrillsDeco shrinkText myTitleTheme simplestFloat
myGimp = named "Gimp MosaicAlt"    $ withIM (0.15) (Role "gimp-toolbox") $ reflectHoriz $ withIM (0.20) (Role "gimp-dock") myMosA
myChat = named "Pidgin MosaicAlt"  $ withIM (0.20) (Title "Buddy List") $ Mirror $ ResizableTall 1 0.03 0.5 []

-- Tabbed transformer (W+f)
data TABBED = TABBED deriving (Read, Show, Eq, Typeable)
instance Transformer TABBED Window where
	transform TABBED x k = k myFull (\_ -> x)

-- Floated transformer (W+ctl+f)
data FLOATED = FLOATED deriving (Read, Show, Eq, Typeable)
instance Transformer FLOATED Window where
	transform FLOATED x k = k myFlat (\_ -> x)

-- Layout hook
myLayoutHook = gaps [(U,panelHeight), (D,panelHeight), (L,0), (R,0)]
	$ avoidStruts
	$ windowNavigation
	$ minimize
	$ maximize
	$ mkToggle (single TABBED)
	$ mkToggle (single FLOATED)
	$ mkToggle (single MIRROR)
	$ mkToggle (single REFLECTX)
	$ mkToggle (single REFLECTY)
	$ onWorkspace (myWorkspaces !! 1) webLayouts  --Workspace 1 layouts
	$ onWorkspace (myWorkspaces !! 2) codeLayouts --Workspace 2 layouts
	$ onWorkspace (myWorkspaces !! 3) gimpLayouts --Workspace 3 layouts
	$ onWorkspace (myWorkspaces !! 4) chatLayouts --Workspace 4 layouts
	$ allLayouts
	where
		allLayouts  = myTile ||| myObig ||| myMirr ||| myMosA ||| myTabM
		webLayouts  = myTabs ||| myMirr ||| myTabM
		codeLayouts = myTabM ||| myTile
		gimpLayouts = myGimp
		chatLayouts = myChat


--------------------------------------------------------------------------------------------
-- HANDLE EVENT HOOK CONFIG                                                               --
--------------------------------------------------------------------------------------------

-- wrapper for the Timer id, so it can be stored as custom mutable state
data TidState = TID TimerId deriving Typeable

instance ExtensionClass TidState where
	initialValue = TID 0

-- Handle event hook
myHandleEventHook :: (?focusFollow::IORef Bool) => Event -> X All
myHandleEventHook = fullscreenEventHook <+> docksEventHook <+> clockEventHook <+> handleTimerEvent <+> toggleFocus
	where
		toggleFocus e = case e of --thanks to Vgot
			CrossingEvent {ev_window=w, ev_event_type=t}
				| t == enterNotify, ev_mode e == notifyNormal -> do
					whenX (io $ readIORef ?focusFollow) (focus w)
					return $ All True
			_ -> return $ All True
		clockEventHook e = do                   --thanks to DarthFennec
			(TID t) <- XS.get                   --get the recent Timer id
			handleTimer t e $ do                --run the following if e matches the id
			    startTimer 1 >>= XS.put . TID   --restart the timer, store the new id
			    ask >>= logHook.config          --get the loghook and run it
			    return Nothing                  --return required type
			return $ All True                   --return required type


--------------------------------------------------------------------------------------------
-- MANAGE HOOK CONFIG                                                                     --
--------------------------------------------------------------------------------------------

-- Scratchpad (W+º)
manageScratchPad :: ManageHook
manageScratchPad = scratchpadManageHook (W.RationalRect (0) (1/50) (1) (3/4))
scratchPad = scratchpadSpawnActionCustom "urxvtc -name scratchpad"

-- Manage hook
myManageHook :: ManageHook
myManageHook = composeAll . concat $
	[ [resource     =? r     --> doIgnore                             | r <- myIgnores] --ignore desktop
	, [className    =? c     --> doShift (myWorkspaces !! 1)          | c <- myWebS   ] --move myWebS windows to workspace 1 by classname
	, [className    =? c     --> doShift (myWorkspaces !! 2)          | c <- myCodeS  ] --move myCodeS windows to workspace 2 by classname
	, [className    =? c     --> doShift (myWorkspaces !! 4)          | c <- myChatS  ] --move myChatS windows to workspace 4 by classname
	, [className    =? c     --> doShift (myWorkspaces !! 3)          | c <- myGfxS   ] --move myGfxS windows to workspace 4 by classname
	, [className    =? c     --> doShiftAndGo (myWorkspaces !! 5)     | c <- myAlt1S  ] --move myGameS windows to workspace 5 by classname and shift
	, [className    =? c     --> doShift (myWorkspaces !! 7)          | c <- myAlt3S  ] --move myOtherS windows to workspace 5 by classname and shift
	, [className    =? c     --> doCenterFloat                        | c <- myFloatCC] --float center geometry by classname
	, [name         =? n     --> doCenterFloat                        | n <- myFloatCN] --float center geometry by name
	, [name         =? n     --> doSideFloat NW                       | n <- myFloatSN] --float side NW geometry by name
	, [className    =? c     --> doF W.focusDown                      | c <- myFocusDC] --dont focus on launching by classname
	, [isFullscreen          --> doFullFloat]
	]
	where
		doShiftAndGo ws = doF (W.greedyView ws) <+> doShift ws
		role            = stringProperty "WM_WINDOW_ROLE"
		name            = stringProperty "WM_NAME"
		myIgnores       = ["desktop","desktop_window"]
		myWebS          = ["Chromium","Firefox", "Opera"]
		myCodeS         = ["NetBeans IDE 7.2"]
		myGfxS          = ["Gimp", "gimp", "GIMP"]
		myChatS         = ["Pidgin", "Xchat"]
		myAlt1S         = ["zsnes"]
		myAlt3S         = ["Amule", "Transmission-gtk"]
		myFloatCC       = ["MPlayer", "mplayer2", "File-roller", "zsnes", "Gcalctool", "Exo-helper-1", "Gksu", "PSX", "Galculator", "Nvidia-settings", "XFontSel"
						  , "XCalc", "XClock", "Desmume", "Ossxmix", "Xvidcap", "Main", "Wicd-client.py", "com-mathworks-util-PostVMInit", "MATLAB"]
		myFloatCN       = ["ePSXe - Enhanced PSX emulator", "Seleccione Archivo", "Config Video", "Testing plugin", "Config Sound", "Config Cdrom", "Config Bios"
						  , "Config Netplay", "Config Memcards", "About ePSXe", "Config Controller", "Config Gamepads", "Select one or more files to open"
						  , "Add media", "Choose a file", "Open Image", "File Operation Progress", "Firefox Preferences", "Preferences", "Search Engines"
						  , "Set up sync", "Passwords and Exceptions", "Autofill Options", "Rename File", "Copying files", "Moving files", "File Properties", "Replace", ""]
		myFloatSN       = ["Event Tester"]
		myFocusDC       = ["Event Tester", "Notify-osd"]


--------------------------------------------------------------------------------------------
-- STATUS BARS CONFIG                                                                     --
--------------------------------------------------------------------------------------------

-- UrgencyHook
myUrgencyHook = withUrgencyHook dzenUrgencyHook
	{ args = ["-fn", dzenFont, "-bg", colorBlack, "-fg", colorGreen, "-h", show panelHeight] }

-- botLeftBar
myBotLeftBar = "dzen2 -x 0 -y " ++ show (yRes - panelHeight) ++ " -h " ++ show panelHeight ++ " -w " ++ show botPanelSepPos ++ " -ta 'l' -fg '" ++ colorWhiteAlt ++ "' -bg '" ++ colorBlack ++ "' -fn '" ++ dzenFont ++ "' -p -e 'onstart=lower'"
myLogHook :: Handle -> X ()
myLogHook h = dynamicLogWithPP $ defaultPP
	{ ppOutput          = hPutStrLn h
	, ppSort            = fmap (namedScratchpadFilterOutWorkspace .) (ppSort defaultPP) --hide "NSP" from workspace list
	, ppOrder           = \(ws:l:_:x) -> [ws] ++ x
	, ppSep             = " "
	, ppWsSep           = ""
	, ppCurrent         = dzenBoxStyle blueBBoxPP
	, ppUrgent          = dzenBoxStyle greenBBoxPP . dzenClickWorkspace
	, ppVisible         = dzenBoxStyle blackBoxPP  . dzenClickWorkspace
	, ppHiddenNoWindows = dzenBoxStyle blackBoxPP  . dzenClickWorkspace
	, ppHidden          = dzenBoxStyle whiteBoxPP  . dzenClickWorkspace
	, ppExtras          = [ myFsL ]
	}
	where
		dzenClickWorkspace ws = "^ca(1," ++ xdo "w;" ++ xdo index ++ ")" ++ "^ca(3," ++ xdo "w;" ++ xdo index ++ ")" ++ ws ++ "^ca()^ca()"
			where
				wsIdxToString Nothing = "1"
				wsIdxToString (Just n) = show $ mod (n+1) $ length myWorkspaces
				index = wsIdxToString (elemIndex ws myWorkspaces)
				xdo key = "/usr/bin/xdotool key super+" ++ key


-- botRightBar
myBotRightBar = "dzen2 -x " ++ show botPanelSepPos ++ " -y " ++ show (yRes - panelHeight) ++ " -h " ++ show panelHeight ++ " -w " ++ show (xRes - botPanelSepPos) ++ " -ta 'r' -fg '" ++ colorWhiteAlt ++ "' -bg '" ++ colorBlack ++ "' -fn '" ++ dzenFont ++ "' -p -e 'onstart=lower'"
myLogHook1 :: Handle -> X ()
myLogHook1 h = dynamicLogWithPP $ defaultPP
	{ ppOutput          = hPutStrLn h
	, ppOrder           = \(_:_:_:x) -> x
	, ppSep             = " "
	, ppExtras          = [ myCpuL, myMemL, myTempL, myBrightL, myWifiL, myBatL ]
	}

-- TopLeftBar
myTopLeftBar = "dzen2 -x 0 -y 0 -h " ++ show panelHeight ++ " -w " ++ show topPanelSepPos ++ " -ta 'l' -fg '" ++ colorWhiteAlt ++ "' -bg '" ++ colorBlack ++ "' -fn '" ++ dzenFont ++ "' -p -e 'onstart=lower'"
myLogHook2 :: Handle -> X ()
myLogHook2 h = dynamicLogWithPP $ defaultPP
	{ ppOutput          = hPutStrLn h
	, ppOrder           = \(_:_:_:x) -> x
	, ppSep             = " "
	, ppExtras          = [ myLayoutL, myWorkspaceL, myFocusL ]
	}


-- TopRightBar
myTopRightBar = "dzen2 -x " ++ show topPanelSepPos ++ " -y 0 -h " ++ show panelHeight ++ " -w " ++ show (xRes - topPanelSepPos) ++ " -ta 'r' -fg '" ++ colorWhiteAlt ++ "' -bg '" ++ colorBlack ++ "' -fn '" ++ dzenFont ++ "' -p -e 'onstart=lower'"
myLogHook3 :: Handle -> X ()
myLogHook3 h = dynamicLogWithPP $ defaultPP
	{ ppOutput          = hPutStrLn h
	, ppOrder           = \(_:_:_:x) -> x
	, ppSep             = " "
	, ppExtras          = [ myUptimeL, myDateL, myCalL ]
	}


--------------------------------------------------------------------------------------------
-- LOGGERS CONFIG                                                                         --
--------------------------------------------------------------------------------------------

myBatL       = (dzenBoxStyleL grayBoxPP $ labelL "BATTERY") ++! (dzenBoxStyleL blueBoxPP batPercent) ++! (dzenBoxStyleL whiteBoxPP batStatus)
myWifiL      = (dzenBoxStyleL grayBoxPP $ labelL "WIFI")    ++! (dzenBoxStyleL blueBoxPP wifiSignal)
myBrightL    = (dzenBoxStyleL grayBoxPP $ labelL "BRIGHT")  ++! (dzenBoxStyleL blueBoxPP brightPerc)
myTempL      = (dzenBoxStyleL grayBoxPP $ labelL "TEMP")    ++! (dzenBoxStyleL blueBoxPP cpuTemp)
myMemL       = (dzenBoxStyleL grayBoxPP $ labelL "MEM")     ++! (dzenBoxStyleL blueBoxPP memUsage)
myCpuL       = (dzenBoxStyleL grayBoxPP $ labelL "CPU")     ++! (dzenBoxStyleL blueBoxPP cpuUsage)
myFsL        = (dzenBoxStyleL blueBoxPP $ labelL "ROOT") ++! (dzenBoxStyleL whiteBoxPP $ fsPerc "/") ++! (dzenBoxStyleL blueBoxPP $ labelL "HOME") ++! (dzenBoxStyleL whiteBoxPP $ fsPerc "/home")
myCalL       = (dzenClickStyleL calendarCA $ dzenBoxStyleL blueBoxPP $ labelL "CALENDAR")
myDateL      = (dzenBoxStyleL whiteBBoxPP $ date "%A") ++! (dzenBoxStyleL whiteBoxPP $ date $ "%Y^fg(" ++ colorGray ++ ").^fg()%m^fg(" ++ colorGray ++ ").^fg()^fg(" ++ colorBlue ++ ")%d^fg() ^fg(" ++ colorGray ++ ")-^fg() %H^fg(" ++ colorGray ++ "):^fg()%M^fg(" ++ colorGray ++ "):^fg()^fg(" ++ colorGreen ++ ")%S^fg()")
myUptimeL    = (dzenBoxStyleL blueBoxPP $ labelL "UPTIME") ++! (dzenBoxStyleL whiteBoxPP uptime)
myFocusL     = (dzenClickStyleL focusCA $ dzenBoxStyleL whiteBBoxPP $ labelL "FOCUS")       ++! (dzenBoxStyleL whiteBoxPP $ shortenL 100 logTitle)
myLayoutL    = (dzenClickStyleL layoutCA $ dzenBoxStyleL blueBoxPP $ labelL "LAYOUT")       ++! (dzenBoxStyleL whiteBoxPP $ onLogger (layoutText . removeWord . removeWord) logLayout)
	where
		removeWord = tail . dropWhile (/= ' ')
		layoutText xs
			| isPrefixOf "Mirror" xs       = layoutText $ removeWord xs ++ " [M]"
			| isPrefixOf "ReflectY" xs     = layoutText $ removeWord xs ++ " [Y]"
			| isPrefixOf "ReflectX" xs     = layoutText $ removeWord xs ++ " [X]"
			| isPrefixOf "Simple Float" xs = "^fg(" ++ colorRed ++ ")" ++ xs
			| isPrefixOf "Full Tabbed" xs  = "^fg(" ++ colorGreen ++ ")" ++ xs
			| otherwise                    = "^fg(" ++ colorWhiteAlt ++ ")" ++ xs
myWorkspaceL = (dzenClickStyleL workspaceCA $ dzenBoxStyleL blueBoxPP $ labelL "WORKSPACE") ++! (dzenBoxStyleL whiteBoxPP $ onLogger namedWorkspaces logCurrent)
	where
		namedWorkspaces w
			| w == "1"  = "^fg(" ++ colorGreen ++ ")1^fg(" ++ colorGray ++ ")|^fg()Terminal"
			| w == "2"  = "^fg(" ++ colorGreen ++ ")2^fg(" ++ colorGray ++ ")|^fg()Network"
			| w == "3"  = "^fg(" ++ colorGreen ++ ")3^fg(" ++ colorGray ++ ")|^fg()Development"
			| w == "4"  = "^fg(" ++ colorGreen ++ ")4^fg(" ++ colorGray ++ ")|^fg()Graphics"
			| w == "5"  = "^fg(" ++ colorGreen ++ ")5^fg(" ++ colorGray ++ ")|^fg()Chatting"
			| w == "6"  = "^fg(" ++ colorGreen ++ ")6^fg(" ++ colorGray ++ ")|^fg()Alternative"
			| w == "7"  = "^fg(" ++ colorGreen ++ ")7^fg(" ++ colorGray ++ ")|^fg()Alternative"
			| w == "8"  = "^fg(" ++ colorGreen ++ ")8^fg(" ++ colorGray ++ ")|^fg()Alternative"
			| w == "9"  = "^fg(" ++ colorGreen ++ ")9^fg(" ++ colorGray ++ ")|^fg()Alternative"
			| w == "0"  = "^fg(" ++ colorGreen ++ ")0^fg(" ++ colorGray ++ ")|^fg()Alternative"
			| otherwise = "^fg(" ++ colorRed   ++ ")x^fg(" ++ colorGray ++ ")|^fg()" ++ w


--------------------------------------------------------------------------------------------
-- BINDINGS CONFIG                                                                        --
--------------------------------------------------------------------------------------------

-- Key bindings
myKeys :: XConfig Layout -> M.Map (KeyMask, KeySym) (X ())
myKeys conf@(XConfig {XMonad.modMask = modMask}) = M.fromList $
	--Xmonad bindings
	[((modMask .|. shiftMask, xK_q), io (exitWith ExitSuccess))          --Quit xmonad
	, ((modMask, xK_q), restart "xmonad" True)                           --Restart xmonad
	, ((mod1Mask, xK_F2), shellPrompt myXPConfig)                        --Launch Xmonad shell prompt
	, ((modMask, xK_F2), xmonadPrompt myXPConfig)                        --Launch Xmonad prompt
	, ((mod1Mask, xK_F3), manPrompt myXPConfig)                          --Launch man prompt
	, ((modMask, xK_g), goToSelected $ myGSConfig myColorizer)           --Launch GridSelect
	, ((modMask, xK_masculine), scratchPad)                              --Scratchpad
	, ((modMask .|. shiftMask, xK_Return), spawn $ XMonad.terminal conf) --Launch default terminal
	--Window management bindings
	, ((modMask, xK_c), kill)                                              --Close focused window
	, ((mod1Mask, xK_F4), kill)
	, ((modMask, xK_n), refresh)                                           --Resize viewed windows to the correct size
	, ((modMask, xK_Tab), windows W.focusDown)                             --Move focus to the next window
	, ((modMask, xK_j), windows W.focusDown)
	, ((mod1Mask, xK_Tab), windows W.focusDown)
	, ((modMask, xK_k), windows W.focusUp)                                 --Move focus to the previous window
	, ((modMask, xK_a), windows W.focusMaster)                             --Move focus to the master window
	, ((modMask .|. shiftMask, xK_a), windows W.swapMaster)                --Swap the focused window and the master window
	, ((modMask .|. shiftMask, xK_j), windows W.swapDown)                  --Swap the focused window with the next window
	, ((modMask .|. shiftMask, xK_k), windows W.swapUp)                    --Swap the focused window with the previous window
	, ((modMask, xK_h), sendMessage Shrink)                                --Shrink the master area
	, ((modMask .|. shiftMask, xK_Left), sendMessage Shrink)
	, ((modMask, xK_l), sendMessage Expand)                                --Expand the master area
	, ((modMask .|. shiftMask, xK_Right), sendMessage Expand)
	, ((modMask .|. shiftMask, xK_h), sendMessage MirrorShrink)            --MirrorShrink the master area
	, ((modMask .|. shiftMask, xK_Down), sendMessage MirrorShrink)
	, ((modMask .|. shiftMask, xK_l), sendMessage MirrorExpand)            --MirrorExpand the master area
	, ((modMask .|. shiftMask, xK_Up), sendMessage MirrorExpand)
	, ((modMask, xK_t), withFocused $ windows . W.sink)                    --Push window back into tiling
	, ((modMask .|. shiftMask, xK_t), rectFloatFocused)                    --Push window into float
	, ((modMask, xK_m), withFocused minimizeWindow)                        --Minimize window
	, ((modMask, xK_b), withFocused (sendMessage . maximizeRestore))       --Maximize window
	, ((modMask .|. shiftMask, xK_m), sendMessage RestoreNextMinimizedWin) --Restore window
	, ((modMask .|. shiftMask, xK_f), fullFloatFocused)                    --Push window into full screen
	, ((modMask, xK_comma), sendMessage (IncMasterN 1))                    --Increment the number of windows in the master area
	, ((modMask, xK_period), sendMessage (IncMasterN (-1)))                --Deincrement the number of windows in the master area
	, ((modMask, xK_Right), sendMessage $ Go R)                            --Change focus to right
	, ((modMask, xK_Left ), sendMessage $ Go L)                            --Change focus to left
	, ((modMask, xK_Up   ), sendMessage $ Go U)                            --Change focus to up
	, ((modMask, xK_Down ), sendMessage $ Go D)                            --Change focus to down
	, ((modMask .|. controlMask, xK_Right), sendMessage $ Swap R)          --Swap focused window to right
	, ((modMask .|. controlMask, xK_Left ), sendMessage $ Swap L)          --Swap focused window to left
	, ((modMask .|. controlMask, xK_Up   ), sendMessage $ Swap U)          --Swap focused window to up
	, ((modMask .|. controlMask, xK_Down ), sendMessage $ Swap D)          --Swap focused window to down
	--Layout management bindings
	, ((modMask, xK_space), sendMessage NextLayout)                                                                                    --Rotate through the available layout algorithms
	, ((modMask .|. shiftMask, xK_space ), flashText myTextConfig 1 " Set to Default Layout " >> (setLayout $ XMonad.layoutHook conf)) --Reset layout to workspaces default
	, ((modMask, xK_f), sendMessage $ XMonad.Layout.MultiToggle.Toggle TABBED)                                                         --Push layout into tabbed
	, ((modMask .|. controlMask, xK_f), sendMessage $ XMonad.Layout.MultiToggle.Toggle FLOATED)                                        --Push layout into float
	, ((modMask .|. shiftMask, xK_z), sendMessage $ Toggle MIRROR)                                                                     --Push layout into mirror
	, ((modMask .|. shiftMask, xK_x), sendMessage $ XMonad.Layout.MultiToggle.Toggle REFLECTX)                                         --Reflect layout by X
	, ((modMask .|. shiftMask, xK_y), sendMessage $ XMonad.Layout.MultiToggle.Toggle REFLECTY)                                         --Reflect layout by Y
	--Gaps management bindings
	, ((modMask .|. controlMask, xK_t), sendMessage $ ToggleGaps)  --toogle all gaps
	, ((modMask .|. controlMask, xK_u), sendMessage $ ToggleGap U) --toogle the top gap
	, ((modMask .|. controlMask, xK_d), sendMessage $ ToggleGap D) --toogle the bottom gap
	--Scripts management bindings
	, ((modMask , xK_x), spawn "/usr/bin/xcalib -invert -alter")                                                          --Invert colors in X
	, ((modMask , xK_d), spawn "/usr/bin/killall dzen2")                                                                  --Kill dzen2
	, ((0, xF86XK_AudioMute), spawn "/home/nnoell/bin/voldzen.sh t -d")                                                     --Mute/unmute volume
	, ((0, xF86XK_AudioRaiseVolume), spawn "/home/nnoell/bin/voldzen.sh + -d")                                              --Raise volume
	, ((mod1Mask, xK_Up), spawn "/home/nnoell/bin/voldzen.sh + -d")
	, ((0, xF86XK_AudioLowerVolume), spawn "/home/nnoell/bin/voldzen.sh - -d")                                              --Lower volume
	, ((mod1Mask, xK_Down), spawn "/home/nnoell/bin/voldzen.sh - -d")
	, ((0, xF86XK_AudioNext),  flashText myTextConfig 1 " Next Song " >> spawn "/usr/bin/ncmpcpp next")                   --Next song
	, ((mod1Mask, xK_Right), flashText myTextConfig 1 " Next Song " >> spawn "/usr/bin/ncmpcpp next")
	, ((0, xF86XK_AudioPrev), flashText myTextConfig 1 " Previous Song " >> spawn "/usr/bin/ncmpcpp prev")                --Prev song
	, ((mod1Mask, xK_Left), flashText myTextConfig 1 " Previous Song " >> spawn "/usr/bin/ncmpcpp prev")
	, ((0, xF86XK_AudioPlay), flashText myTextConfig 1 " Song Toggled " >> spawn "/usr/bin/ncmpcpp toggle")               --Toggle song
	, ((mod1Mask .|. controlMask, xK_Down), flashText myTextConfig 1 " Song Toggled " >> spawn "/usr/bin/ncmpcpp toggle")
	, ((0, xF86XK_AudioStop), flashText myTextConfig 1 " Song Stopped " >> spawn "/usr/bin/ncmpcpp stop")                 --Stop song
	, ((mod1Mask .|. controlMask, xK_Up), flashText myTextConfig 1 " Song Stopped " >> spawn "ncmpcpp stop")
	, ((0, xF86XK_MonBrightnessUp), spawn "/home/nnoell/bin/bridzen.sh")                                                    --Raise brightness
	, ((0, xF86XK_MonBrightnessDown), spawn "/home/nnoell/bin/bridzen.sh")                                                  --Lower brightness
	, ((0, xF86XK_ScreenSaver), spawn "/home/nnoell/bin/turnoffscreen.sh")                                                  --Lock screen
	, ((0, xK_Print), spawn "/usr/bin/scrot '%Y-%m-%d_$wx$h.png'")                                                        --Take a screenshot
	, ((modMask , xK_s), spawn "/home/nnoell/bin/turnoffscreen.sh")                                                         --Turn off screen
	--Workspaces management bindings
	, ((mod1Mask, xK_comma), flashText myTextConfig 1 " Toggled to Previous Workspace " >> toggleWS)                          --Toggle to the workspace displayed previously
	, ((mod1Mask, xK_masculine), flashText myTextConfig 1 " Switching with Workspace 1 " >> toggleOrView (myWorkspaces !! 0)) --If ws != 0 then move to workspace 0, else move to latest ws I was
	, ((mod1Mask .|. controlMask, xK_Left), flashText myTextConfig 1 " Moved to Previous Workspace " >> prevWS)               --Move to previous Workspace
	, ((mod1Mask .|. controlMask, xK_Right), flashText myTextConfig 1 " Moved to Next Workspace " >> nextWS)                  --Move to next Workspace
	, ((modMask .|. shiftMask, xK_n), flashText myTextConfig 1 " Shifted to Next Workspace " >> shiftToNext)                  --Send client to next workspace
	, ((modMask .|. shiftMask, xK_p), flashText myTextConfig 1 " Shifted to Previous Workspace " >> shiftToPrev)              --Send client to previous workspace
	]
	++
	[((m .|. modMask, k), windows $ f i)                                                        --Switch to n workspaces and send client to n workspaces
		| (i, k) <- zip (XMonad.workspaces conf) ([xK_1 .. xK_9] ++ [xK_0])
		, (f, m) <- [(W.greedyView, 0), (W.shift, shiftMask)]]
	++
	[((m .|. modMask, key), screenWorkspace sc >>= flip whenJust (windows . f))                 --Switch to n screens and send client to n screens
		| (key, sc) <- zip [xK_w, xK_e, xK_r] [0..]
		, (f, m) <- [(W.view, 0), (W.shift, shiftMask)]]
	where
		fullFloatFocused = withFocused $ \f -> windows =<< appEndo `fmap` runQuery doFullFloat f
		rectFloatFocused = withFocused $ \f -> windows =<< appEndo `fmap` runQuery (doRectFloat $ RationalRect 0.05 0.05 0.9 0.9) f

-- Mouse bindings
myMouseBindings :: XConfig Layout -> M.Map (KeyMask, Button) (Window -> X ())
myMouseBindings (XConfig {XMonad.modMask = modMask}) = M.fromList $
	[ ((modMask, button1), (\w -> focus w >> mouseMoveWindow w >> windows W.shiftMaster)) --Set the window to floating mode and move by dragging
	, ((modMask, button2), (\w -> focus w >> windows W.shiftMaster))                      --Raise the window to the top of the stack
	, ((modMask, button3), (\w -> focus w >> Flex.mouseResizeWindow w))                   --Set the window to floating mode and resize by dragging
	, ((modMask, button4), (\_ -> prevWS))                                                --Switch to previous workspace
	, ((modMask, button5), (\_ -> nextWS))                                                --Switch to next workspace
	, (((modMask .|. shiftMask), button4), (\_ -> shiftToPrev))                           --Send client  to previous workspace
	, (((modMask .|. shiftMask), button5), (\_ -> shiftToNext))                           --Send client  to next workspace
	]
