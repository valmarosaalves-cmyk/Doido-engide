package doido.utils;

import lime.app.Application;
import lime.ui.MouseCursor;

class EditorUtil
{
    /*
        ARROW
        CROSSHAIR
        DEFAULT
        MOVE
        POINTER
        RESIZE_NESW
        RESIZE_NS
        RESIZE_NWSE
        RESIZE_WE
        TEXT
        WAIT
        WAIT_ARROW
        CUSTOM
    */
    public static function setCursor(newCursor:MouseCursor)
    {
        Application.current.window.cursor = newCursor;
    }
}