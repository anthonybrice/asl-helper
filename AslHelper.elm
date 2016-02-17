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

import Random exposing (int, initialSeed, generate)
import Time exposing (Time)

import List.Extra exposing ((!!))

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
  { signifierUrl : String
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
  | FirstSeed Time

randList = list 20 (int 1 20)

update : Action -> Model -> (Model, Effects Action)
update action model =
  case action of
    NextSign ->
      ( model
      , getNextSign <| model.ordering !! (model.index + 1)
      )

    RevealSign ->
      ( Model model.unit model.ordering model.current True
      , Effects.none
      )

    NewSign maybeUrl ->
      ( { model | index = index + 1
        , sign = Sign (Maybe.withDefault model.sign.signifierUrl maybeUrl)
                      (Maybe.withDefault model.sign.signifiedUrl maybeUrl)
                      False
        }
      , Effects.none
      )

    FirstSeed time ->
      let (ordering', seed') = generate randList (initialSeed (truncate time))
      in ( { model | ordering = ordering' }
         , getNextSign <| ordering' !! 0
         )

-------------
-- EFFECTS --
-------------

getNextSign : Int -> Int -> Effects Action
getNextSign unit num =
  Http.get decodeUrl (signUrl unit num)
      |> Task.toMaybe
      |> Task.map NewSign
      |> Effects.task


signUrl : Json.Decoder String
signUrl =
  Json.at ["data", "image_url"] Json.string
