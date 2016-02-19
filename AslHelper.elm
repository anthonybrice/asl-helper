module AslHelper where

import Effects exposing (Effects, Never)
import Html exposing (..)
import Html.Attributes exposing (style)
import Html.Events exposing (onKeyPress, onClick)
import Char
import Http
--import Http exposing (Error)
import Json.Decode as Json
import Json.Decode exposing (Decoder, (:=))
import Task exposing (Task)
import Signal exposing (Signal)

import Random
import Time exposing (Time)

import List.Extra exposing ((!!))
import List exposing (head, length)

-----------
-- MODEL --
-----------

type alias Model =
  { unit : Int
  , seed : Random.Seed
  , signs : List (String, String)
  , ordering : List Int
  , index : Int
  , sign : Sign
  }

type alias Sign =
  { signifierUrl : String
  , desc : String
  , isDescVisible : Bool
  }

init : Int -> (Model, Effects Action)
init unit' =
  ( { unit = unit'
    , ordering = []
    , seed = Random.initialSeed 42
    , index = 0
    , signs = []
    , sign = { signifierUrl = ""
             , desc = ""
             , isDescVisible = False
             }
    }
  , getUnitInfo unit'
  )

------------
-- UPDATE --
------------

type Action
  = NextSign
  | RevealSign
  | NoOp
  | HandleSpace
  | FirstSeed Time
  | UnitInfo (List (String, String))

update : Action -> Model -> (Model, Effects Action)
update action model =
  case action of
    NoOp -> (model, Effects.none)

    NextSign ->
      let sign' = newSign model <| model.index + 1
      in ( { model | index = model.index + 1, sign = sign' }
         , Effects.none
         )

    RevealSign ->
      let msign = model.sign
          sign' = { msign | isDescVisible = True }
      in ( { model | sign = sign' }
         , Effects.none
         )

    FirstSeed time ->
      let maxInt = length model.signs
          (ordering', seed') = generate (permutation [0..maxInt])
                               (Random.initialSeed (truncate time))
          i = Maybe.withDefault 0 <| head ordering'
          sign' = newSign model i
      in ( { model | ordering = ordering', sign = sign', seed = seed' }
         , Effects.none
         )

    HandleSpace ->
      if model.sign.isDescVisible
      then (model, Effects.task <| Task.succeed NextSign)
      else (model, Effects.task <| Task.succeed RevealSign)

    UnitInfo signs' -> ( { model | signs = signs' }
                       , Effects.tick FirstSeed
                       )

newSign : Model -> Int -> Sign
newSign model signIndex =
  let (file, desc) = Maybe.withDefault ("Nothing in signs", "Nothing in signs")
                     <| model.signs !! signIndex
  in Sign (fileUrl file) desc False

----------
-- VIEW --
----------

(=>) : a -> b -> (a, b)
(=>) = (,)

view : Signal.Address Action -> Model -> Html
view address model =
  let descStyle = if model.sign.isDescVisible
                  then headerStyle
                  else invisibleStyle
  in div [ style [ "width" => "200px" ] ]
       [ h2 [headerStyle] [text <| "Unit " ++ (toString model.unit)]
       , div [imgStyle model.sign.signifierUrl] []
       , h3 [descStyle] [text model.sign.desc]
       , button [ onClick address NextSign ]
                [ text "Next Sign!" ]
       ]

headerStyle : Attribute
headerStyle =
  style
    [ "width" => "200px"
    , "text-align" => "center"
    ]

invisibleStyle : Attribute
invisibleStyle =
  style
    [ "visibility" => "hidden" ]

imgStyle : String -> Attribute
imgStyle url =
  style
    [ "display" => "inline-block"
    , "width" => "400px"
    , "height" => "400px"
    , "background-position" => "center center"
    , "background-size" => "cover"
    , "background-image" => ("url('" ++ url ++ "')")
    ]

-------------
-- EFFECTS --
-------------

getUnitInfo : Int -> Effects Action
getUnitInfo unit =
  Http.get decodeInfo (infoUrl unit)
    |> flip Task.onError infoError
    |> Task.map UnitInfo
    |> Effects.task

infoError : Http.Error -> Task a (List (String, String))
infoError e = Task.succeed [("","")]
  -- let doLog s = let _ = log s ""
  --               in Task.succeed [("","")]
  -- in case e of
  --   Http.Timeout -> doLog "Request timed out"
  --   Http.NetworkError -> doLog "A network error occurred"
  --   Http.UnexpectedPayload s -> doLog <| "Unexpected payload: " ++ s
  --   Http.BadResponse i s -> doLog <| "Bad response " ++ (toString i) ++ ": " ++ s

infoUrl : Int -> String
infoUrl unit =
  Http.url "http://localhost:8080/asl/signs"
        [ ("filter", "{'unit':" ++ (toString unit) ++ "}")
        , ("hal", "c")
        ]

decodeInfo : Json.Decoder (List (String, String))
decodeInfo =
  Json.at [ "_embedded", "rh:doc" ] <| Json.list decodeSign

decodeSign : Json.Decoder (String, String)
decodeSign =
  Json.object2 (,)
    ("file" := Json.string)
    ("desc" := Json.string)

fileUrl : String -> String
fileUrl file =
  Http.url ("http://localhost:8080/static/signs/" ++ file) []

doSpace : Int -> Action
doSpace keyCode =
  -- let _ = log "keyCode is " keyCode
  --     _ = log "char should be " <| Char.fromCode keyCode
  -- in
  case Char.fromCode keyCode of
       '\'' -> HandleSpace
       _ -> NoOp

------------------
-- PERMUTATIONS --
------------------

type Generator a =
  Generator (Random.Seed -> (a, Random.Seed))

generate : Generator a -> Random.Seed -> (a, Random.Seed)
generate (Generator generate) seed =
  generate seed

permutation : List a -> Generator (List a)
permutation list =
  let
    length = List.length list

    {- Knuth shuffle subproblem -}
    randomMove n ((output, seed), input) =
      let
        (rand, newSeed) =
          Random.generate (Random.int 0 (n-1)) seed

        {- Add the `rand`th element of the remaining list of inputs to the
        output permutation. -}
        output' =
          input
            |> List.drop rand
            |> List.take 1
            |> List.append output

        {- Strike the `rand`th element from the list of remaining inputs. -}
        input' =
          (List.take rand input) ++ (List.drop (rand+1) input)
      in
        ((output', newSeed), input')
  in
    Generator <| \seed ->
      List.foldr randomMove (([], seed), list) [1..length]
        |> fst
