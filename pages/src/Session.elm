module Session exposing (Session, changes, cred, fromViewer, isLoggedIn, navKey, viewer)

import Browser.Navigation as Nav
import Json.Decode as Decode exposing (Decoder)
import Json.Decode.Pipeline exposing (custom, required)
import Json.Encode as Encode exposing (Value)
import Rest exposing (Cred)
import Time
import Viewer exposing (Viewer)



-- TYPES


type Session
    = LoggedIn (Maybe Nav.Key) Viewer
    | Guest (Maybe Nav.Key)



-- INFO


viewer : Session -> Maybe Viewer
viewer session =
    case session of
        LoggedIn _ val ->
            Just val

        Guest _ ->
            Nothing


cred : Session -> Maybe Cred
cred session =
    case session of
        LoggedIn _ val ->
            Just (Viewer.cred val)

        Guest _ ->
            Nothing


navKey : Session -> Maybe Nav.Key
navKey session =
    case session of
        LoggedIn key _ ->
            key

        Guest key ->
            key


isLoggedIn : Session -> Bool
isLoggedIn session =
    case session of
        LoggedIn _ _ ->
            True

        Guest _ ->
            False



-- CHANGES


changes : (Session -> msg) -> Maybe Nav.Key -> Sub msg
changes toMsg key =
    Rest.viewerChanges (\maybeViewer -> toMsg (fromViewer key maybeViewer)) Viewer.decoder


fromViewer : Maybe Nav.Key -> Maybe Viewer -> Session
fromViewer key maybeViewer =
    -- It's stored in localStorage as a JSON String;
    -- first decode the Value as a String, then
    -- decode that String as JSON.
    case maybeViewer of
        Just viewerVal ->
            LoggedIn key viewerVal

        Nothing ->
            Guest key