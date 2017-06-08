module App exposing (..)

import Json.Encode as JE
import Json.Decode as JD
import Task
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Http


type alias Model =
    { webhook : Result String Webhook
    , tf2 : Int
    , csgo : Int
    , dota2 : Int
    }


type alias Webhook =
    { id : String
    , token : String
    , name : Maybe String
    , avatar : Maybe String
    }


type Channel
    = TF2
    | CSGO
    | DOTA2


type Action
    = Input String
    | Receive (Result Http.Error Webhook)
    | Subscribe Channel (Result String Int)
    | Send
    | Saved Bool


main =
    Html.program
        { init = init
        , update = update
        , subscriptions = subscriptions
        , view = view
        }


init =
    { webhook = Err "Paste your webhook URL"
    , tf2 = 0
    , csgo = 0
    , dota2 = 0
    }
        ! []


update action model =
    case action of
        Input input ->
            if String.startsWith "https://discordapp.com/api/webhooks/" input then
                { model | webhook = Err "Loading" } ! [ load input ]
            else
                { model | webhook = Err "Invalid URL" } ! []

        Receive (Ok webhook) ->
            { model | webhook = Ok webhook } ! []

        Receive _ ->
            { model | webhook = Err "Failed to load webhook information" } ! []

        Subscribe TF2 (Ok n) ->
            { model | tf2 = n }
                ! []

        Subscribe CSGO (Ok n) ->
            { model | csgo = n }
                ! []

        Subscribe DOTA2 (Ok n) ->
            { model | dota2 = n }
                ! []

        Subscribe _ _ ->
            model ! []

        Send ->
            model ! [ save model ]

        Saved True ->
            { model | webhook = Err "Saved" } ! []

        Saved False ->
            { model | webhook = Err "Failed to save" } ! []


load url =
    Http.get url decodeWebhook
        |> Http.toTask
        |> Task.attempt Receive


decodeWebhook =
    JD.map4 Webhook
        (JD.field "id" JD.string)
        (JD.field "token" JD.string)
        (JD.field "name" <| JD.maybe JD.string)
        (JD.field "avatar" <| JD.maybe JD.string)


save model =
    case model.webhook of
        Err _ ->
            Cmd.none

        Ok webhook ->
            Http.post "http://ldesgoui.xyz/hi_valve/api/rpc/subscribe"
                (Http.jsonBody
                    (JE.object
                        [ "webhook" => JE.string (webhook.id ++ "/" ++ webhook.token)
                        , "tf2" => JE.int model.tf2
                        , "csgo" => JE.int model.csgo
                        , "dota2" => JE.int model.dota2
                        ]
                    )
                )
                (JD.succeed ())
                |> Http.toTask
                |> Task.attempt (Saved << isOk)


(=>) =
    (,)


subscriptions =
    always Sub.none


css =
    """
    main {
        display: flex;
        flex-flow: column wrap;
        max-width: 30em;
        margin: 0 auto;
        font-family: "Helvetica", "Arial", sans-serif;
        line-height: 1.5;
        color: #555;
    }

    h1 {
        text-align: center;
    }

    hr {
        width: 42%
    }

    input, button {
        width: 100%;
        box-sizing: border-box;
        margin: 4px auto;
    }

    span {
        margin-bottom: 16px;
    }

    input[type="range"] {
        width: 42%;
    }

    a {
        color: #b35215;
        margin: auto;
    }
    """



-- """ (fix vim bug)


view model =
    let
        tf2Message =
            case model.tf2 of
                0 ->
                    "You will receive no TF2-related notifications"

                1 ->
                    "You will receive TF2 notifications about massive updates"

                2 ->
                    "You will receive TF2 notifications about any update"

                _ ->
                    "You will receive all TF2 notifications published"

        csgoMessage =
            case model.csgo of
                0 ->
                    "You will receive no CS:GO-related notifications"

                1 ->
                    "You will receive CS:GO notifications about massive updates"

                _ ->
                    "You will receive all CS:GO notifications published"

        dota2Message =
            case model.dota2 of
                0 ->
                    "You will receive no DOTA2-related notifications"

                1 ->
                    "You will receive DOTA2 notifications about massive updates"

                2 ->
                    "You will receive DOTA2 notifications about any update"

                _ ->
                    "You will receive all DOTA2 notifications published"

        subMessage w =
            case w.name of
                Just name ->
                    "Subscribe with " ++ name

                Nothing ->
                    "Subscribe using webhooks"
    in
        main_ []
            [ node "style" [] [ text css ]
            , h1 [] [ text "hi valve" ]
            , input [ placeholder "https://discordapp.com/api/webhook/...", onInput Input ] []
            , button
                [ if isOk model.webhook then
                    onClick Send
                  else
                    disabled True
                ]
                [ text <| fromResult identity subMessage model.webhook ]
            , input
                [ type_ "range"
                , attribute "min" "0"
                , attribute "max" "3"
                , value <| toString model.tf2
                , onInput (Subscribe TF2 << String.toInt)
                ]
                []
            , span [] [ text tf2Message ]
            , input
                [ type_ "range"
                , attribute "min" "0"
                , attribute "max" "2"
                , value <| toString model.csgo
                , onInput (Subscribe CSGO << String.toInt)
                ]
                []
            , span [] [ text csgoMessage ]
            , input
                [ type_ "range"
                , attribute "min" "0"
                , attribute "max" "3"
                , value <| toString model.dota2
                , onInput (Subscribe DOTA2 << String.toInt)
                ]
                []
            , span [] [ text dota2Message ]
            , hr [] []
            , div [] (List.concatMap (\( q, a ) -> [ blockquote [] [ text q ], p [] [ text a ] ]) info)
            , a [ href "https://github.com/ldesgoui/hi_valve" ] [ text "Source code of the app" ]
            , a [ href "https://discordapp.com/invite/GZ7yhnT" ] [ text "My Discord server" ]
            ]


info =
    [ "What does this do?" => "Valve games publish updates and other news on the games' blogs, this tools fetches them every minute and sends a Discord message to your server whenever something you've subscribed for shows up."
    , "How do I use it?" => "In the Server Settings, you will find a Webhook tab where you can create a Webhook, simply paste the URL given to you after creation and tweak the sliders to your heart's desire."
    , "How do I unsubcribe?" => "You can either delete the Webhook from your Discord server, or re-use it with all values set to 0 if you want to keep it."
    , "Why can't I get only CS:GO patchnotes?" => "Sadly, Valve is not consistent on their title scheme, making it impossible to detect when a post is either a simple blogpost or a changelog."
    , "Can you do this for my game?" => "Sure, it will depend on the time I can allow and if it isn't a pain to fetch the update informations."
    , "Can you hack my server from this?" => "All I can read from these are the identifiers of your server and channel, those cannot be used unless authenticated and invited to the server."
    ]


fromResult onErr onOk result =
    case result of
        Ok ok ->
            onOk ok

        Err err ->
            onErr err


isOk result =
    case result of
        Ok _ ->
            True

        Err _ ->
            False
