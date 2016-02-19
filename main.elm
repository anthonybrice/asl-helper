import Effects exposing (Never)
import AslHelper exposing (init, update, view, doSpace)
import StartApp
import Task exposing (Task)
import Html exposing (Html)
import Keyboard

app : StartApp.App AslHelper.Model
app =
  StartApp.start
    { init = init 1
    , update = update
    , view = view
    , inputs = [ Signal.map doSpace Keyboard.presses ]
    }

main : Signal Html
main =
  app.html

port tasks : Signal (Task Never ())
port tasks =
  app.tasks
