module AslHelper where

import Effects exposing (Effects, Never)
import Html exposing (..)
import Html.Attributes exposing (style)
import Html.Events exposing (onClick)
import Http
import Json.Decode as Json
import Task
import Task exposing (Task)
import Signal exposing (Signal)

import Random exposing (int, initialSeed, generate, list)
import Time exposing (Time)

import List.Extra exposing ((!!))
import List exposing (head)

-----------
-- MODEL --
-----------

type alias Model =
   { unit : Int
   , seed : Random.Seed
   , ordering : List Int
   , index : Int
   , sign : Sign
   }

type alias Sign =
  { signifierUrl : String -- need better names
  , signifiedUrl : String
  , isSignifiedVisible : Bool
  }

init : Int -> (Model, Effects Action)
init unit' =
  ( { unit = unit'
    , ordering = []
    , seed = initialSeed 42
    , index = 0
    , sign = { signifierUrl = ""
             , signifiedUrl = ""
             , isSignifiedVisible = False
             }
    }
  , Effects.tick FirstSeed
  )

------------
-- UPDATE --
------------

type Action
  = NextSign
  | RevealSign
  | NewSign (Maybe String)
  | FirstSeed Time

randList : Random.Generator (List Int)
randList = list 20 (int 1 20)

update : Action -> Model -> (Model, Effects Action)
update action model =
  case action of
    NextSign ->
      let mint = model.ordering !! (model.index + 1)
      in case mint of
           Just i -> (model, getSign model.unit i)
           Nothing -> (model, Effects.none)


    RevealSign ->
      let msign = model.sign
          sign' = { msign | isSignifiedVisible = True }
      in ( { model | sign = sign' }
         , Effects.none
         )

    NewSign maybeUrl ->
      let msign = model.sign
          d = msign.signifiedUrl
          r = msign.signifierUrl
          sign' = Sign (Maybe.withDefault r maybeUrl)
                       (Maybe.withDefault d maybeUrl)
                       False
      in ( { model | index = model.index + 1, sign = sign' }
         , Effects.none
         )

    FirstSeed time ->
      let (ordering', seed') = generate randList (initialSeed (truncate time))
          mint = head ordering'
      in case mint of
           Just i -> ( { model | ordering = ordering' }
                     , getSign model.unit i
                     )
           Nothing -> (model, Effects.none)

----------
-- VIEW --
----------

(=>) : a -> b -> (a, b)
(=>) = (,)

view : Signal.Address Action -> Model -> Html
view address model =
  div [ style [ "width" => "200px" ] ]
        [ h2 [headerStyle] [text <| toString model.unit ]
        , div [imgStyle model.sign.signifierUrl] []
        , button [ onClick address NextSign ] [ text "Next Sign!" ]
        ]

headerStyle : Attribute
headerStyle =
  style
    [ "width" => "200px"
    , "text-align" => "center"
    ]

imgStyle : String -> Attribute
imgStyle url =
  style
    [ "display" => "inline-block"
    , "width" => "200px"
    , "height" => "200px"
    , "background-position" => "center center"
    , "background-size" => "cover"
    , "background-image" => ("url('" ++ url ++ "')")
    ]

-------------
-- EFFECTS --
-------------

getSign : Int -> Int -> Effects Action
getSign unit num =
  Http.get decodeUrl (signUrl unit num)
      |> Task.toMaybe
      |> Task.map NewSign
      |> Effects.task


signUrl : Int -> Int -> String
signUrl unit num =
  Http.url "http://localhost:8080" []

decodeUrl : Json.Decoder String
decodeUrl =
  Json.at ["data", "image_url"] Json.string
