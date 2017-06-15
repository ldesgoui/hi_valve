{- Copyright (c) 2017 ldesgoui
   -- read file 'LICENSE' for details
-}


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
    | DotA2


type Action
    = Input String
    | Receive (Result Http.Error Webhook)
    | Subscribe Channel Int
    | Send
    | Saved Bool
    | NoOp


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
            if String.startsWith "https://discordapp.com/api/webhooks/" (String.trim input) then
                { model | webhook = Err "Loading" }
                    ! [ Http.get (String.trim input) decodeWebhook
                            |> Http.send Receive
                      ]
            else
                { model | webhook = Err "Invalid URL" } ! []

        Receive (Ok webhook) ->
            { model | webhook = Ok webhook } ! []

        Receive _ ->
            { model | webhook = Err "Invalid URL (or Discord is unreachable)" } ! []

        Subscribe TF2 n ->
            { model | tf2 = n }
                ! []

        Subscribe CSGO n ->
            { model | csgo = n }
                ! []

        Subscribe DotA2 n ->
            { model | dota2 = n }
                ! []

        Send ->
            model ! [ save model ]

        Saved True ->
            { model | webhook = Err "Saved" }
                ! [ if model.tf2 + model.csgo + model.dota2 > 0 then
                        sendPreview model
                    else
                        Cmd.none
                  ]

        Saved False ->
            { model | webhook = Err "Server failed to save" } ! []

        NoOp ->
            model ! []


decodeWebhook =
    JD.map4 Webhook
        (JD.field "id" JD.string)
        (JD.field "token" JD.string)
        (JD.field "name" <| JD.maybe JD.string)
        (JD.field "avatar" <| JD.maybe JD.string)


sendPreview model =
    let
        tf2Message =
            case model.tf2 of
                1 ->
                    "massive TF2 updates"

                2 ->
                    "any TF2 update"

                3 ->
                    "any TF2 blogpost"

                _ ->
                    "nothing TF2"

        csgoMessage =
            case model.csgo of
                1 ->
                    "massive CS:GO updates"

                2 ->
                    "any CS:GO update"

                3 ->
                    "any CS:GO blogpost"

                _ ->
                    "nothing CS:GO"

        dota2Message =
            case model.dota2 of
                1 ->
                    "massive DotA2 updates"

                2 ->
                    "any DotA2 update"

                3 ->
                    "any DotA2 blogpost"

                _ ->
                    "nothing DotA2"
    in
        case model.webhook of
            Ok { id, token } ->
                Http.post ("https://discordapp.com/api/webhooks/" ++ id ++ "/" ++ token)
                    (Http.jsonBody
                        (JE.object
                            [ "content" => JE.string ("Hey, you've properly installed 'hi valve' with the following settings: " ++ tf2Message ++ ", " ++ csgoMessage ++ ", " ++ dota2Message ++ ". If you don't know what this is about, click the link below!")
                            , "embeds"
                                => JE.list
                                    [ JE.object
                                        [ "title" => JE.string "This is an example title!"
                                        , "description" => JE.string loremIpsum
                                        , "url" => JE.string "https://ldesgoui.xyz/hi_valve"
                                        , "timestamp" => JE.string "1970-01-01 00:01"
                                        , "image" => JE.object [ "url" => JE.string "http://www.valvesoftware.com/images/company/valve_logo.png" ]
                                        , "footer" => JE.string "from https://ldesgoui.xyz/hi_valve (CS:GO update only filter now available)"
                                        ]
                                    ]
                            ]
                        )
                    )
                    (JD.succeed ())
                    |> Http.send (always NoOp)

            Err _ ->
                Cmd.none


loremIpsum =
    """Lorem ipsum dolor sit amet, consectetur adipiscing elit. In molestie at velit eget feugiat. Cras tortor lacus, laoreet in cursus in, rhoncus dictum justo. In vel placerat leo. In hac habitasse platea dictumst. Nullam in arcu et ante ornare aliquet. Donec pharetra est tellus, sed cursus purus pootis in. Sed ullamcorper tristique mi, non consectetur nisi faucibus eu. Pellentesque non est tempus libero molestie blandit ac finibus ligula. Donec convallis ante non lorem molestie, vulputate mollis neque scelerisque. Phasellus vestibulum metus faucibus ligula rhoncus tempus. Etiam laoreet, nisi eu malesuada molestie, ex lorem vestibulum nunc, vel lacinia arcu leo sed ex. Phasellus dictum mattis libero, quis laoreet dui feugiat sit amet. Proin vel magna placerat, consectetur tortor et, imperdiet metus.
"""


save model =
    case model.webhook of
        Err _ ->
            Cmd.none

        Ok webhook ->
            Http.post "https://ldesgoui.xyz/hi_valve/api/rpc/subscribe"
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
                |> Http.send (Saved << isOk)


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

    .label {
        margin: 8px 32px;
    }
    label {
        margin: auto 16px;
    }

    hr {
        width: 42%
    }

    input:not([type]), button {
        width: 100%;
        box-sizing: border-box;
        margin: 4px auto;
    }

    a {
        color: #b35215;
        margin: auto;
    }

    img {
        max-width: 100%;
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

                2 ->
                    "You will receive CS:GO notifications about any update"

                _ ->
                    "You will receive all CS:GO notifications published"

        dota2Message =
            case model.dota2 of
                0 ->
                    "You will receive no DotA2-related notifications"

                1 ->
                    "You will receive DotA2 notifications about massive updates"

                2 ->
                    "You will receive DotA2 notifications about any update"

                _ ->
                    "You will receive all DotA2 notifications published"

        subMessage w =
            case w.name of
                Just name ->
                    "Subscribe with " ++ name

                Nothing ->
                    "Subscribe using webhooks"
    in
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
        , span [] [ text "Your Discord server will receive:" ]
        ]
            ++ (List.map
                    (\( g, v, f, t ) ->
                        [ input
                            [ type_ "radio"
                            , name <| toString g
                            , onCheck (always <| Subscribe g v)
                            , id (toString g ++ toString v)
                            , checked (f model == v)
                            ]
                            []
                        , label [ for (toString g ++ toString v) ]
                            [ text t ]
                        ]
                            |> div [ class "label" ]
                    )
                    options
               )
            ++ [ hr [] []
               , div [] (List.concatMap (\( q, a ) -> [ blockquote [] [ text q ], p [] [ text a ] ]) info)
               , a [ href "https://github.com/ldesgoui/hi_valve" ] [ text "Source code of the app" ]
               , a [ href "https://discordapp.com/invite/GZ7yhnT" ] [ text "My Discord server" ]
               , img [ src "https://p.ldesgoui.xyz/1497003672.png" ] []
               ]
            |> main_ []


options =
    [ ( TF2, 0, (.tf2), "nothing TF2-related" )
    , ( TF2, 1, (.tf2), "massive TF2 updates" )
    , ( TF2, 2, (.tf2), "any TF2 update" )
    , ( TF2, 3, (.tf2), "any TF2 blogpost" )
    , ( CSGO, 0, (.csgo), "nothing CS:GO-related" )
    , ( CSGO, 1, (.csgo), "massive CS:GO updates" )
    , ( CSGO, 2, (.csgo), "any CS:GO update" )
    , ( CSGO, 3, (.csgo), "any CS:GO blogpost" )
    , ( DotA2, 0, (.dota2), "nothing DotA2-related" )
    , ( DotA2, 1, (.dota2), "massive DotA2 updates" )
    , ( DotA2, 2, (.dota2), "any DotA2 update" )
    , ( DotA2, 3, (.dota2), "any DotA2 blogpost" )
    ]


info =
    [ "What does this do?" => "Valve games publish updates and other news on the games' blogs, this tools fetches them every minute and sends a Discord message to your server whenever something you've subscribed for shows up."
    , "How do I use it?" => "In the Server Settings, you will find a Webhook tab where you can create a Webhook, simply paste the URL given to you after creation and tweak the sliders to your heart's desire."
    , "How do I unsubscribe?" => "You can either delete the Webhook from your Discord server, or re-use it with all values set to 0 if you want to keep it."
    , "Why can't I get only CS:GO patchnotes?" => "You now can!"
    , "How fast will I get the notification?" => "At most, it will take 2 minutes after the update is published on the website (a little more after 1000 subscribers due to Discord rate limits)."
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
