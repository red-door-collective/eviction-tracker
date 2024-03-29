module Page.Logout exposing (Data, Model, Msg, page)

import Browser.Navigation as Nav
import DataSource exposing (DataSource)
import Head
import Head.Seo as Seo
import Http
import Log
import Logo
import Page exposing (PageWithState, StaticPayload)
import Pages.PageUrl exposing (PageUrl)
import Path exposing (Path)
import Rest
import Rollbar exposing (Rollbar)
import Runtime
import Session
import Shared
import View exposing (View)


type alias Model =
    ()


type Msg
    = GotLogout (Result Rest.HttpError ())
    | NoOp


type alias RouteParams =
    {}


page : PageWithState RouteParams Data Model Msg
page =
    Page.single
        { head = head
        , data = data
        }
        |> Page.buildWithLocalState
            { init = init
            , update = update
            , view = view
            , subscriptions = subscriptions
            }


type alias Data =
    ()


data : DataSource Data
data =
    DataSource.succeed ()


init :
    Maybe PageUrl
    -> Shared.Model
    -> StaticPayload Data RouteParams
    -> ( Model, Cmd Msg )
init pageUrl sharedModel static =
    ( ()
    , Cmd.batch
        [ Rest.logout (Runtime.domain static.sharedData.runtime.environment) (Session.cred sharedModel.session) GotLogout
        ]
    )


update :
    PageUrl
    -> Maybe Nav.Key
    -> Shared.Model
    -> StaticPayload Data RouteParams
    -> Msg
    -> Model
    -> ( Model, Cmd Msg )
update pageUrl navKey sharedModel static msg model =
    case msg of
        GotLogout (Ok _) ->
            ( model
            , Cmd.none
            )

        GotLogout (Err httpError) ->
            let
                rollbar =
                    Log.reporting static.sharedData.runtime

                logHttpError =
                    error rollbar << Log.httpErrorMessage
            in
            ( model, logHttpError httpError )

        NoOp ->
            ( model, Cmd.none )


error : Rollbar -> String -> Cmd Msg
error rollbar report =
    Log.error rollbar (\_ -> NoOp) report


head :
    StaticPayload Data RouteParams
    -> List Head.Tag
head static =
    Seo.summary
        { canonicalUrlOverride = Nothing
        , siteName = "Red Door Collective"
        , image = Logo.smallImage
        , description = "Log out of the Red Door Collective Administration Center"
        , locale = Just "en-us"
        , title = title
        }
        |> Seo.website


title =
    "Red Door Collective | Logout"


view :
    Maybe PageUrl
    -> Shared.Model
    -> Model
    -> StaticPayload Data RouteParams
    -> View Msg
view maybeUrl sharedModel model static =
    View.placeholder "Logout"


subscriptions : Maybe PageUrl -> RouteParams -> Path -> Model -> Sub Msg
subscriptions pageUrl params path model =
    Sub.none
