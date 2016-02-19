module AslHelper where

import Effects exposing (Effects, Never)
import Html exposing (..)
import Html.Attributes exposing (style)
import Char
import Http
import Json.Decode as Json
import Json.Decode exposing (Decoder, (:=))
import Task exposing (Task)
import Signal exposing (Signal)

import Random
import Time exposing (Time)

import List.Extra exposing ((!!))
import List exposing (head, length, map, take, drop)

--import Debug exposing (..)

-----------
-- MODEL --
-----------

{-| A struct with the current state of the helper. -}
type alias Model =
  { unit : Int                    -- ^ The unit (in reference to signing
                                  --   naturally)
  , seed : Random.Seed            -- ^ The seed we use to permute the signs
  , signs : List Sign             -- ^ The signs this helper will iterate
  , index : Int                   -- ^ Current index into signs
  , sign : Sign                   -- ^ The current sign
  }

{-| A struct of a sign. -}
type alias Sign =
  { signifierUrl : String         -- ^ The URL to an image of the signifier
  , desc : String                 -- ^ An English description of the signified
  , isDescVisible : Bool          -- ^
  }

{-| Sets dummy values, then gets things rolling with a call to `getUnitInfo`. -}
init : Int -> (Model, Effects Action)
init unit' =
  ( { unit = unit'
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

{-| All the actions a helper can take. -}
type Action
  = NextSign                         -- ^ Iterate to the next sign given by ordering
  | RevealSign                       -- ^ Show desc
  | NoOp                             -- ^
  | NextOrRevealSign                 -- ^
  | FirstSeed Time                   -- ^ Get the initial seed from the program's start time
  | UnitInfo (List (String, String)) -- ^ Get the signs for the given unit
  | PreviousSign                     -- ^ Iterate backwards.

update : Action -> Model -> (Model, Effects Action)
update action model =
  case action of
    NoOp -> (model, Effects.none)

    NextSign ->
      let l = length model.signs
          i' = clamp 0 l <| model.index + 1
          sign' = getSign model.signs i'
      in ( { model | index = i', sign = sign' }
         , Effects.none
         )

    RevealSign ->
      let msign = model.sign
          sign' = { msign | isDescVisible = True }
          signs' = replaceSign model.signs sign' model.index
      in ( { model | sign = sign', signs = signs' }
         , Effects.none
         )

    FirstSeed time ->
      let (signs', seed') = generate (permutation model.signs)
                            (Random.initialSeed (truncate time))
          sign' = getSign signs' model.index
      in ( { model | signs = signs', sign = sign', seed = seed' }
         , Effects.none
         )

    NextOrRevealSign ->
      if model.sign.isDescVisible
      then (model, Effects.task <| Task.succeed NextSign)
      else (model, Effects.task <| Task.succeed RevealSign)

    PreviousSign ->
      let l = length model.signs
          i' = clamp 0 l (model.index - 1)
          sign' = getSign model.signs i'
      in ( { model | index = i', sign = sign' }
         , Effects.none
         )

    UnitInfo tups ->
      let signs' = map initSign tups
      in ( { model | signs = signs' }
         , Effects.tick FirstSeed
         )

replaceSign : List Sign -> Sign -> Int -> List Sign
replaceSign xs y i = take i xs ++ [y] ++ drop (i + 1) xs

initSign : (String, String) -> Sign
initSign (x, y) = Sign (fileUrl x) y False

getSign : List Sign -> Int -> Sign
getSign signs signIndex =
  Maybe.withDefault (Sign "Nothing in signs" "Nothing in signs" False)
         <| signs !! signIndex

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
  in div [ style [ "width" => "20em" ] ]
       [ h2 [headerStyle] [text <| "Unit " ++ (toString model.unit)]
       , div [imgStyle model.sign.signifierUrl] []
       , h3 [descStyle] [text model.sign.desc]
       , text "Use the arrow keys to navigate."
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
    |> flip Task.onError (always (Task.succeed [("", "")]))
    |> Task.map UnitInfo
    |> Effects.task

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
  --let _ = log "Char.fromCode keyCode == " <| Char.fromCode keyCode
  --in
  case Char.fromCode keyCode of
    '\'' -> NextOrRevealSign -- ^ right arrow
    '%' -> PreviousSign      -- ^ and left arrow according to firefox apparently
                             -- see: https://github.com/elm-lang/core/pull/463
    _ -> NoOp

-----------------
-- PERMUTATION --
-----------------
-- ^ Credit: blitzrk
-- ^ https://gist.github.com/blitzrk/3a1f2d07191823af1393

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

--  LocalWords:  getUnitInfo
