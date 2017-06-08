module App exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Http


main =
    Html.program
        { init = init
        , update = update
        , subscriptions = subscriptions
        , view = view
        }


type alias Model =
    { webhook : String
    , tf2 : Int
    , csgo : Int
    , dota2 : Int
    }


init =
    { webhook = ""
    , tf2 = 0
    , csgo = 0
    , dota2 = 0
    }
        ! []


type Channel
    = TF2
    | CSGO
    | DOTA2


type Action
    = SetWebhook String
    | Subscribe Channel Int
    | Get Model
    | Send


purify =
    identity


valid _ =
    False


fetchSubscription _ =
    Cmd.none


subscribe _ =
    Cmd.none


update action model =
    case action of
        SetWebhook input ->
            { model | webhook = purify input }
                ! [ if valid <| purify input then
                        fetchSubscription <| purify input
                    else
                        Cmd.none
                  ]

        Subscribe TF2 n ->
            { model | tf2 = n }
                ! []

        Subscribe CSGO n ->
            { model | csgo = n }
                ! []

        Subscribe DOTA2 n ->
            { model | dota2 = n }
                ! []

        Get savedModel ->
            savedModel ! []

        Send ->
            model ! [ subscribe model ]


subscriptions =
    always Sub.none


view model =
    div []
        [ input [ placeholder "https://discordapp.com/api/webhook/...", onInput SetWebhook ] []
        , input [ type_ "range", attribute "min" "0", attribute "max" "3", value <| toString model.tf2 ] []
        , input [ type_ "range", attribute "min" "0", attribute "max" "2", value <| toString model.csgo ] []
        , input [ type_ "range", attribute "min" "0", attribute "max" "3", value <| toString model.dota2 ] []
        , button [ onClick Send ] [ text "Send" ]
        ]
