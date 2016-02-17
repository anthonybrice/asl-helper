import Effects exposing (Never)
import AslHelper exposing (init, update, view)
import StartApp
import Task

app =
  StartApp.start
    { init = init "foobar"
    , update = update
    , view = view
    , inputs []
    }

main =
  app.html

port tasks : Signal (Task.Task Never ())
port tasks =
  app.tasks

-- import Html exposing (..)
-- import Html.Attributes exposing (..)
-- StartApp.Simple as StartApp

-- main =
--   StartApp.start { model = model, view = view, update = update }

-- type alias Model

-- import Html exposing (..)
-- import Html.Attributes exposing (..)
-- import Html.Events exposing (..)
-- import Html.Lazy exposing (..)
-- import Json.Decode as Json
-- import Signal exposing (Signal, Address)
-- import String
-- import Window

-- -----------
-- -- MODEL --
-- -----------

-- type alias Model =
--   { uid : Int }

-- -- The full application state
-- -- type alias Model =
-- --   { unit : Int
-- --   , totalSigns : Int
-- --   , ordering : List Sign
-- --   , current : Sign
-- --   }

-- -- type alias Sign =
-- --   { uid : Int
-- --   , signifier : String
-- --   , signified : String
-- --   , isSignifiedVisible : Bool
-- --   }

-- ------------
-- -- UPDATE --
-- ------------


-- ----------
-- -- VIEW --
-- ----------

-- view : Addres Action -> Model -> Html
-- view address model =
--   div
--     [ class "aslhelper-wrapper" ]
--     [ section
--         [ id "unit-list" ]
--         [ ]
--     , infoFooter
--     ]

-- infoFooter : Html
-- infoFooter =
--   footer
--     [ id "info" ]
--     [ p [] [ text "Click to advance." ]
--     , p []
--         [ text "Source: "
--         , a [ href "https://github.com/anthonybrice" ]
--             [ text "https://github.com/anthonybrice" ]
--         ]
--     ]
