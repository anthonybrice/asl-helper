import Effects exposing (Never)
import AslHelper exposing (init, update, view)
import StartApp
import Task
import Html

app : StartApp.App AslHelper.Model
app =
  StartApp.start
    { init = init 1
    , update = update
    , view = view
    , inputs = []
    }

main : Signal Html.Html
main =
  app.html

port tasks : Signal (Task.Task Never ())
port tasks =
  app.tasks
