#=======================================================
# Arturo
# Programming Language + Bytecode VM compiler
# (c) 2019-2025 Yanis Zafirópulos
#
# @file: library/Ui.nim
#=======================================================

## The main Ui module 
## (part of the standard library)

#=======================================
# Pragmas
#=======================================

{.used.}

#=======================================
# Libraries
#=======================================

import vm/lib

when not defined(NOWEBVIEW):
    import algorithm, hashes, os, tables

    import helpers/objects
    import helpers/webviews
    import helpers/windows

    import vm/[errors, exec, parse, values/custom/verror]

when not defined(NOCLIPBOARD):
    import helpers/clipboard

when not defined(NODIALOGS):
    import helpers/dialogs

#=======================================
# Variables
#=======================================

when (not defined(WEB)) and not defined(NOWEBVIEW):
    var
        ActiveWindow: Value = VNULL

#=======================================
# Definitions
#=======================================

proc defineModule*(moduleName: string) =

    #----------------------------
    # Functions
    #----------------------------

    when not defined(NODIALOGS):
        
        builtin "alert",
            alias       = unaliased,
            op          = opNop,
            rule        = PrefixPrecedence,
            description = "show notification with given title and message",
            args        = {
                "title"     : {String},
                "message"   : {String}
            },
            attrs       = {
                "info"      : ({Logical},"show informational notification"),
                "warning"   : ({Logical},"show notification as a warning"),
                "error"     : ({Logical},"show notification as an error")
            },
            returns     = {Nothing},
            example     = """
            alert "Hello!" "This is a notification..."
            ; show an OS notification without any styling

            alert.error "Ooops!" "Something went wrong!"
            ; show an OS notification with an error message
            """:
                #=======================================================
                var alertIcon = NoIcon

                if (hadAttr("info")):
                    alertIcon = InfoIcon
                elif (hadAttr("warning")):
                    alertIcon = WarningIcon
                elif (hadAttr("error")):
                    alertIcon = ErrorIcon

                showAlertDialog(x.s, y.s, alertIcon)

    when not defined(NOCLIPBOARD):

        builtin "clip",
            alias       = unaliased, 
            op          = opNop,
            rule        = PrefixPrecedence,
            description = "set clipboard content to given text",
            args        = {
                "content"   : {String}
            },
            attrs       = NoAttrs,
            returns     = {Nothing},
            example     = """
            clip "this is something to be pasted into the clipboard"
            """:
                #=======================================================
                setClipboard(x.s)

    when not defined(NODIALOGS):

        builtin "dialog",
            alias       = unaliased, 
            op          = opNop,
            rule        = PrefixPrecedence,
            description = "show a file selection dialog and return selection",
            args        = {
                "title"     : {String}
            },
            attrs       = {
                "folder"    : ({Logical},"select folders instead of files"),
                "path"      : ({String},"use given starting path")      
            },
            returns     = {String},
            example     = """
            selectedFile: dialog "Select a file to open"
            ; gets full path for selected file, after dialog closes
            ..........
            selectedFolder: dialog.folder "Select a folder"
            ; same as above, only for folder selection
            """:
                #=======================================================
                var path: string
                let selectFiles = not hadAttr("folder")
                if checkAttr("path"): 
                    path = aPath.s

                push newString(showSelectionDialog(x.s, path, selectFiles))

        builtin "popup",
            alias       = unaliased, 
            op          = opNop,
            rule        = PrefixPrecedence,
            description = "show popup dialog with given title and message and return result",
            args        = {
                "title"     : {String},
                "message"   : {String}
            },
            attrs       = {
                "info"              : ({Logical},"show informational popup"),
                "warning"           : ({Logical},"show popup as a warning"),
                "error"             : ({Logical},"show popup as an error"),
                "question"          : ({Logical},"show popup as a question"),
                "ok"                : ({Logical},"show an OK dialog (default)"),
                "okCancel"          : ({Logical},"show an OK/Cancel dialog"),
                "yesNo"             : ({Logical},"show a Yes/No dialog"),
                "yesNoCancel"       : ({Logical},"show a Yes/No/Cancel dialog"),
                "retryCancel"       : ({Logical},"show a Retry/Cancel dialog"),
                "retryAbortIgnore"  : ({Logical},"show an Abort/Retry/Ignore dialog"),
                "literal"           : ({Logical},"return the literal value of the pressed button")
            },
            returns     = {Logical,Literal},
            example     = """
            popup "Hello!" "This is a popup message"
            ; shows a message dialog with an OK button
            ; when the dialog is closed, it returns: true
            ..........
            if popup.yesNo "Hmm..." "Are you sure you want to continue?" [
                ; a Yes/No dialog will appear - if the user clicks YES,
                ; then the function will return true; thus we can do what
                ; we want here

            ]
            ..........
            popup.okCancel.literal "Hello" "Click on a button"
            ; => 'ok (if user clicked OK)
            ; => 'cancel (if user clicked Cancel)
            """:
                #=======================================================
                var popupIcon = NoIcon
                var popupType = OKDialog

                if (hadAttr("info")):
                    popupIcon = InfoIcon
                elif (hadAttr("warning")):
                    popupIcon = WarningIcon
                elif (hadAttr("error")):
                    popupIcon = ErrorIcon
                elif (hadAttr("question")):
                    popupIcon = QuestionIcon

                if (hadAttr("ok")):
                    popupType = OKDialog
                elif (hadAttr("okCancel")):
                    popupType = OKCancelDialog
                elif (hadAttr("yesNo")):
                    popupType = YesNoDialog
                elif (hadAttr("yesNoCancel")):
                    popupType = YesNoCancelDialog
                elif (hadAttr("retryCancel")):
                    popupType = RetryCancelDialog
                elif (hadAttr("retryAbortIgnore")):
                    popupType = RetryAbortIgnoreDialog

                let res = showPopupDialog(x.s, y.s, popupType, popupIcon)


                if (hadAttr("literal")):
                    push newLiteral(getLiteralDialogResult(popupType, res))
                else:
                    push newLogical(getBooleanDialogResult(popupType, res))

    when not defined(NOCLIPBOARD):

        builtin "unclip",
            alias       = unaliased, 
            op          = opNop,
            rule        = PrefixPrecedence,
            description = "get clipboard content",
            args        = NoArgs,
            attrs       = NoAttrs,
            returns     = {String},
            example     = """
            ; paste something into the clipboard (optionally)
            clip "this is something to be pasted into the clipboard"

            ; now, let's fetch whatever there is in the clipboard
            unclip 
            ; => "this is something to be pasted into the clipboard"
            """:
                #=======================================================
                push newString(getClipboard())

    when not defined(NOWEBVIEW):

        builtin "webview",
            alias       = unaliased, 
            op          = opNop,
            rule        = PrefixPrecedence,
            description = "show webview window with given url or html source",
            args        = {
                "content"   : {String,Literal}
            },
            attrs       = {
                "title"     : ({String},"set window title"),
                "width"     : ({Integer},"set window width"),
                "height"    : ({Integer},"set window height"),
                "fixed"     : ({Logical},"window shouldn't be resizable"),
                "maximized" : ({Logical},"start in maximized mode"),
                "fullscreen": ({Logical},"start in fullscreen mode"),
                "borderless": ({Logical},"show as borderless window"),
                "topmost"   : ({Logical},"set window as always-on-top"),
                "debug"     : ({Logical},"add inspector console"),
                "on"        : ({Dictionary},"execute code on specific events"),
                "inject"    : ({String},"inject JS code on webview initialization")
            },
            returns     = {Nothing},
            example     = """
            webview "Hello world!"
            ; (opens a webview windows with "Hello world!")
            ..........
            webview .width:  200 
                    .height: 300
                    .title:  "My webview app"
            ; (opens a webview with given attributes)
            ---
                <h1>This is my webpage</h1>
                <p>
                    This is some content
                </p>
            """:
                #=======================================================
                var title = "Arturo"
                var width = 640
                var height = 480
                var fixed = (hadAttr("fixed"))
                var maximized = (hadAttr("maximized"))
                var fullscreen = (hadAttr("fullscreen"))
                var borderless = (hadAttr("borderless"))
                var topmost = (hadAttr("topmost"))
                var withDebug = (hadAttr("debug"))
                var inject: string
                var on: ValueDict

                if checkAttr("title"): title = aTitle.s
                if checkAttr("width"): width = aWidth.i
                if checkAttr("height"): height = aHeight.i
                if checkAttr("inject"): inject = aInject.s
                
                if checkAttr("on"): on = aOn.d
                else: on = newOrderedTable[string,Value]()

                var content = x.s

                let wv: Webview = newWebview(
                    title       = title, 
                    content     = content, 
                    width       = width, 
                    height      = height, 
                    resizable   = not fixed, 
                    maximized   = maximized,
                    fullscreen  = fullscreen,
                    borderless  = borderless,
                    topmost     = topmost,
                    debug       = withDebug,
                    initializer = inject,
                    callHandler = proc (call: WebviewCallKind, value: Value): Value =
                        result = VNULL
                        if call==FunctionCall:
                            if SymExists(value.d["method"].s) and GetSym(value.d["method"].s).kind==Function:
                                let prevSP = SP

                                let fun = GetSym(value.d["method"].s)
                                for v in value.d["args"].a.reversed:
                                    push(v)

                                if fun.fnKind==UserFunction:
                                    let fid = hash(value.d["method"].s)
                                    execFunction(fun, fid)
                                else:
                                    fun.action()()

                                if SP > prevSP:
                                    result = stack.pop()

                        elif call==ExecuteCode:
                            try:
                                let parsed = doParse(value.s, isFile=false)
                                let prevSP = SP
                                if not isNil(parsed):
                                    execUnscoped(parsed)
                                if SP > prevSP:
                                    result = stack.pop()
                            except VError as e:
                                showError(e)
                            except CatchableError, Defect:
                                let e = getCurrentException()
                                showError(VError(e))
                            
                        elif call==WebviewEvent:
                            if (let onEvent = on.getOrDefault(value.s, nil); not onEvent.isNil):
                                execUnscoped(onEvent)
                        else:
                            discard
                )

                builtin "eval",
                    alias       = unaliased, 
                    op          = opNop,
                    rule        = PrefixPrecedence,
                    description = "Evaluate JavaScript code in active webview",
                    args        = {
                        "js": {String}
                    },
                    attrs       = NoAttrs,
                    returns     = {Integer,Nothing},
                    example     = """
                    """:
                        #=======================================================
                        echo "in old eval: " & $(x.s)
                        wv.evaluate(x.s)

                # necessary so that "__webviewWindow" is available
                execInternal("Ui/window")

                let emptyvarr: ValueArray = @[]
                ActiveWindow = generateNewObject(getType("__webviewWindow"),emptyvarr)
                ActiveWindow.o["title"] = newString(title)
                ActiveWindow.o["maximizable?"] = newLogical(true)
                ActiveWindow.o["minimizable?"] = newLogical(true)
                ActiveWindow.o["topmost?"] = newLogical(topmost)

                ActiveWindow.o["_setTitle"] = adhocPrivate({"title": {String}}, NoAttrs):
                    push(newLogical(webview_set_title(wv, cstring(x.s)) == OK))

                ActiveWindow.o["_isVisible"] = adhocPrivate(NoArgs, NoAttrs):
                    push(newLogical(wv.getWindow().isVisible()))

                ActiveWindow.o["_isFocused"] = adhocPrivate(NoArgs, NoAttrs):
                    push(newLogical(wv.getWindow().isFocused()))

                ActiveWindow.o["_isFullscreen"] = adhocPrivate(NoArgs, NoAttrs):
                    push(newLogical(wv.getWindow().isFullscreen()))

                ActiveWindow.o["_isMaximized"] = adhocPrivate(NoArgs, NoAttrs):
                    push(newLogical(wv.getWindow().isMaximized()))

                ActiveWindow.o["_maximize"] = adhocPrivate(NoArgs, NoAttrs):
                    wv.getWindow().maximize()
                
                ActiveWindow.o["_unmaximize"] = adhocPrivate(NoArgs, NoAttrs):
                    wv.getWindow().unmaximize()

                ActiveWindow.o["_isMinimized"] = adhocPrivate(NoArgs, NoAttrs):
                    push(newLogical(wv.getWindow().isMinimized()))

                ActiveWindow.o["_minimize"] = adhocPrivate(NoArgs, NoAttrs):
                    wv.getWindow().minimize()
                
                ActiveWindow.o["_unminimize"] = adhocPrivate(NoArgs, NoAttrs):
                    wv.getWindow().unminimize()
            
                ActiveWindow.o["_fullscreen"] = adhocPrivate(NoArgs, NoAttrs):
                    wv.getWindow().fullscreen()
            
                ActiveWindow.o["_unfullscreen"] = adhocPrivate(NoArgs, NoAttrs):
                    wv.getWindow().unfullscreen()

                ActiveWindow.o["_topmost"] = adhocPrivate(NoArgs, NoAttrs):
                    wv.getWindow().set_topmost_window()
            
                ActiveWindow.o["_untopmost"] = adhocPrivate(NoArgs, NoAttrs):
                    wv.getWindow().unset_topmost_window()

                ActiveWindow.o["_getSize"] = adhocPrivate(NoArgs, NoAttrs):
                    let sz = wv.getWindow().getSize()
                    push(newBlock(@[newInteger(sz.width), newInteger(sz.height)]))

                ActiveWindow.o["_setSize"] = adhocPrivate({"size": {Block}}, NoAttrs):
                    wv.getWindow().setSize(WindowSize(width: x.a[0].i, height: x.a[1].i))

                ActiveWindow.o["_getMinSize"] = adhocPrivate(NoArgs, NoAttrs):
                    let sz = wv.getWindow().getMinSize()
                    push(newBlock(@[newInteger(sz.width), newInteger(sz.height)]))

                ActiveWindow.o["_setMinSize"] = adhocPrivate({"size": {Block}}, NoAttrs):
                    wv.getWindow().setMinSize(WindowSize(width: x.a[0].i, height: x.a[1].i))

                ActiveWindow.o["_getMaxSize"] = adhocPrivate(NoArgs, NoAttrs):
                    let sz = wv.getWindow().getMaxSize()
                    push(newBlock(@[newInteger(sz.width), newInteger(sz.height)]))

                ActiveWindow.o["_setMaxSize"] = adhocPrivate({"size": {Block}}, NoAttrs):
                    wv.getWindow().setMaxSize(WindowSize(width: x.a[0].i, height: x.a[1].i))

                ActiveWindow.o["_getPosition"] = adhocPrivate(NoArgs, NoAttrs):
                    let pos = wv.getWindow().getPosition()
                    push(newBlock(@[newInteger(pos.x), newInteger(pos.y)]))

                ActiveWindow.o["_setPosition"] = adhocPrivate({"pos": {Block}}, NoAttrs):
                    wv.getWindow().setPosition(WindowPosition(x: x.a[0].i, y: x.a[1].i))

                ActiveWindow.o["center"] = adhocPrivate(NoArgs, NoAttrs):
                    wv.getWindow().center()

                ActiveWindow.o["_show"] = adhocPrivate(NoArgs, NoAttrs):
                    wv.getWindow().show()
                    
                ActiveWindow.o["_hide"] = adhocPrivate(NoArgs, NoAttrs):
                    wv.getWindow().hide()

                ActiveWindow.o["_setFocused"] = adhocPrivate({"val": {Logical}}, NoAttrs):
                    wv.getWindow().setFocused(isTrue(x))

                ActiveWindow.o["_setClosable"] = adhocPrivate({"val": {Logical}}, NoAttrs):
                    wv.getWindow().setClosable(isTrue(x))

                ActiveWindow.o["_setMaximizable"] = adhocPrivate({"val": {Logical}}, NoAttrs):
                    wv.getWindow().setMaximizable(isTrue(x))

                ActiveWindow.o["_setMinimizable"] = adhocPrivate({"val": {Logical}}, NoAttrs):
                    wv.getWindow().setMinimizable(isTrue(x))
                
                ActiveWindow.o["close"] = adhocPrivate(NoArgs, NoAttrs):
                    push(newLogical(wv.webview_terminate() == OK))

                ActiveWindow.o["evaluate"] = adhocPrivate({"code": {String}}, NoAttrs):
                    wv.evaluate(x.s)

                SetSym("window", ActiveWindow)

                wv.show()

        constant "window",
            alias       = unaliased,
            description = "the main active window":
                ActiveWindow
