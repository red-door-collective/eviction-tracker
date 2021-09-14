module Page.Admin.DetainerWarrants exposing (Data, Model, Msg, page)

import Api.Endpoint as Endpoint exposing (Endpoint)
import Browser.Navigation as Nav
import Color
import DataSource exposing (DataSource)
import Date exposing (Date)
import DatePicker exposing (ChangeEvent(..))
import DetainerWarrant exposing (DatePickerState, DetainerWarrant, Status(..))
import Element exposing (Element, centerX, column, fill, height, image, link, maximum, minimum, padding, paragraph, px, row, spacing, table, text, textColumn, width)
import Element.Background as Background
import Element.Border as Border
import Element.Events as Events
import Element.Font as Font
import Element.Input as Input
import FeatherIcons
import FormatNumber
import FormatNumber.Locales exposing (Decimals(..), usLocale)
import Head
import Head.Seo as Seo
import Html.Attributes
import Html.Events
import Http exposing (Error(..))
import InfiniteScroll
import Json.Decode as Decode
import Loader
import Log
import Maybe.Extra
import Page exposing (Page, PageWithState, StaticPayload)
import Pages.PageUrl exposing (PageUrl)
import Pages.Url
import Palette
import Path exposing (Path)
import QueryParams
import Rest exposing (Cred)
import Rollbar exposing (Rollbar)
import Route
import Runtime exposing (Runtime)
import Search exposing (Cursor(..), Search)
import Session exposing (Session)
import Settings exposing (Settings)
import Shared
import Url.Builder exposing (QueryParameter)
import User exposing (User)
import View exposing (View)
import Widget
import Widget.Icon


type alias Model =
    { fileDate : DatePickerState
    , courtDate : DatePickerState
    , warrants : List DetainerWarrant
    , selected : Maybe String
    , hovered : Maybe String
    , search : Search Search.DetainerWarrants
    , infiniteScroll : InfiniteScroll.Model Msg
    }


init :
    Maybe PageUrl
    -> Shared.Model
    -> StaticPayload Data RouteParams
    -> ( Model, Cmd Msg )
init pageUrl sharedModel static =
    let
        maybeCred =
            Session.cred sharedModel.session

        domain =
            Runtime.domain static.sharedData.runtime.environment

        filters =
            Maybe.withDefault Search.detainerWarrantsDefault <| Maybe.andThen (Maybe.map (Search.dwFromString << QueryParams.toString) << .query) pageUrl

        search =
            { filters = filters, cursor = NewSearch, previous = Just filters, totalMatches = Nothing }
    in
    ( { fileDate = initDatePicker static.sharedData.runtime.today filters.fileDate
      , courtDate = initDatePicker static.sharedData.runtime.today filters.courtDate
      , warrants = []
      , search = search
      , selected = Nothing
      , hovered = Nothing
      , infiniteScroll = InfiniteScroll.init (loadMore domain maybeCred search) |> InfiniteScroll.direction InfiniteScroll.Bottom
      }
    , searchWarrants domain maybeCred search
    )


searchWarrants : String -> Maybe Cred -> Search Search.DetainerWarrants -> Cmd Msg
searchWarrants domain maybeCred search =
    Rest.get (Endpoint.detainerWarrantsSearch domain (queryArgsWithPagination search)) maybeCred GotWarrants Rest.detainerWarrantApiDecoder


loadMore : String -> Maybe Cred -> Search Search.DetainerWarrants -> InfiniteScroll.Direction -> Cmd Msg
loadMore domain maybeCred search dir =
    case search.cursor of
        NewSearch ->
            Cmd.none

        After _ ->
            searchWarrants domain maybeCred search

        End ->
            Cmd.none


queryArgsWithPagination : Search Search.DetainerWarrants -> List ( String, String )
queryArgsWithPagination search =
    let
        filters =
            search.filters

        queryArgs =
            Search.detainerWarrantsArgs filters
    in
    if Just search.filters == search.previous then
        case search.cursor of
            NewSearch ->
                queryArgs

            After warrantsCursor ->
                ( "cursor", warrantsCursor ) :: queryArgs

            End ->
                queryArgs

    else
        queryArgs


type Msg
    = InputDocketId (Maybe String)
    | ChangedFileDate ChangeEvent
    | ChangedCourtDate ChangeEvent
    | InputPlaintiff (Maybe String)
    | InputPlaintiffAttorney (Maybe String)
    | InputDefendant (Maybe String)
    | InputAddress (Maybe String)
    | SelectWarrant String
    | HoverWarrant String
    | SearchWarrants
    | GotWarrants (Result Http.Error (Rest.Collection DetainerWarrant))
    | ChangedSorting String
    | InfiniteScrollMsg InfiniteScroll.Msg
    | NoOp


updateFilters :
    (Search.DetainerWarrants -> Search.DetainerWarrants)
    -> Model
    -> ( Model, Cmd Msg )
updateFilters transform model =
    let
        search =
            model.search
    in
    ( { model | search = { search | filters = transform search.filters } }, Cmd.none )


update :
    PageUrl
    -> Maybe Nav.Key
    -> Shared.Model
    -> StaticPayload Data RouteParams
    -> Msg
    -> Model
    -> ( Model, Cmd Msg )
update pageUrl navKey sharedModel static msg model =
    let
        rollbar =
            Log.reporting static.sharedData.runtime

        domain =
            Runtime.domain static.sharedData.runtime.environment

        logHttpError =
            error rollbar << Log.httpErrorMessage

        session =
            sharedModel.session
    in
    case msg of
        InputDocketId query ->
            updateFilters (\filters -> { filters | docketId = query }) model

        ChangedFileDate changeEvent ->
            case changeEvent of
                DateChanged date ->
                    let
                        fileDate =
                            model.fileDate

                        updatedFileDate =
                            { fileDate | date = Just date, dateText = Date.toIsoString date }
                    in
                    ( { model | fileDate = updatedFileDate }, Cmd.none )

                TextChanged text ->
                    ( let
                        fileDate =
                            model.fileDate

                        updatedFileDate =
                            { fileDate
                                | date =
                                    Date.fromIsoString text
                                        |> Result.toMaybe
                                , dateText = text
                            }
                      in
                      { model | fileDate = updatedFileDate }
                    , Cmd.none
                    )

                PickerChanged subMsg ->
                    let
                        fileDate =
                            model.fileDate

                        updatedFileDate =
                            { fileDate | pickerModel = fileDate.pickerModel |> DatePicker.update subMsg }
                    in
                    ( { model | fileDate = updatedFileDate }
                    , Cmd.none
                    )

        ChangedCourtDate changeEvent ->
            case changeEvent of
                DateChanged date ->
                    let
                        courtDate =
                            model.courtDate

                        updatedCourtDate =
                            { courtDate | date = Just date, dateText = Date.toIsoString date }
                    in
                    ( { model | courtDate = updatedCourtDate }, Cmd.none )

                TextChanged text ->
                    ( let
                        courtDate =
                            model.courtDate

                        updatedCourtDate =
                            { courtDate
                                | date =
                                    Date.fromIsoString text
                                        |> Result.toMaybe
                                , dateText = text
                            }
                      in
                      { model | courtDate = updatedCourtDate }
                    , Cmd.none
                    )

                PickerChanged subMsg ->
                    let
                        courtDate =
                            model.courtDate

                        updatedCourtDate =
                            { courtDate | pickerModel = courtDate.pickerModel |> DatePicker.update subMsg }
                    in
                    ( { model | courtDate = updatedCourtDate }
                    , Cmd.none
                    )

        InputPlaintiff query ->
            updateFilters (\filters -> { filters | plaintiff = query }) model

        InputPlaintiffAttorney query ->
            updateFilters (\filters -> { filters | plaintiffAttorney = query }) model

        InputDefendant query ->
            updateFilters (\filters -> { filters | defendant = query }) model

        InputAddress query ->
            updateFilters (\filters -> { filters | address = query }) model

        SelectWarrant docketId ->
            ( { model | selected = Just docketId }, Cmd.none )

        HoverWarrant docketId ->
            ( { model | hovered = Just docketId }, Cmd.none )

        SearchWarrants ->
            let
                updatedModel =
                    updateFilters
                        (\filters ->
                            { filters
                                | fileDate = model.fileDate.date
                                , courtDate = model.courtDate.date
                            }
                        )
                        model
                        |> Tuple.first
            in
            ( updatedModel
            , Cmd.batch
                [ Maybe.withDefault Cmd.none <|
                    Maybe.map
                        (\key ->
                            Nav.replaceUrl key
                                (Url.Builder.relative
                                    [ "detainer-warrants"
                                    ]
                                    (Endpoint.toQueryArgs <| Search.detainerWarrantsArgs updatedModel.search.filters)
                                )
                        )
                        (Session.navKey session)
                , searchWarrants domain (Session.cred session) updatedModel.search
                ]
            )

        GotWarrants (Ok detainerWarrantsPage) ->
            let
                maybeCred =
                    Session.cred sharedModel.session

                queryFilters =
                    Maybe.withDefault Search.detainerWarrantsDefault <| Maybe.map Search.dwFromString sharedModel.queryParams

                search =
                    { filters = queryFilters
                    , cursor = Maybe.withDefault End <| Maybe.map After detainerWarrantsPage.meta.afterCursor
                    , previous = Just queryFilters
                    , totalMatches = Just detainerWarrantsPage.meta.totalMatches
                    }

                updatedModel =
                    { model | search = search }
            in
            if updatedModel.search.previous == Just updatedModel.search.filters then
                ( { updatedModel
                    | warrants = model.warrants ++ detainerWarrantsPage.data
                    , infiniteScroll =
                        InfiniteScroll.stopLoading model.infiniteScroll
                            |> InfiniteScroll.loadMoreCmd (loadMore domain maybeCred search)
                  }
                , Cmd.none
                )

            else
                ( { updatedModel
                    | warrants = detainerWarrantsPage.data
                    , infiniteScroll =
                        InfiniteScroll.stopLoading model.infiniteScroll
                            |> InfiniteScroll.loadMoreCmd (loadMore domain maybeCred search)
                  }
                , Cmd.none
                )

        GotWarrants (Err httpError) ->
            ( model, logHttpError httpError )

        ChangedSorting _ ->
            ( model, Cmd.none )

        InfiniteScrollMsg subMsg ->
            case model.search.cursor of
                End ->
                    ( model, Cmd.none )

                _ ->
                    let
                        ( infiniteScroll, cmd ) =
                            InfiniteScroll.update InfiniteScrollMsg subMsg model.infiniteScroll
                    in
                    ( { model | infiniteScroll = infiniteScroll }, cmd )

        NoOp ->
            ( model, Cmd.none )


error : Rollbar -> String -> Cmd Msg
error rollbar report =
    Log.error rollbar (\_ -> NoOp) report


onEnter : msg -> Element.Attribute msg
onEnter msg =
    Element.htmlAttribute
        (Html.Events.on "keyup"
            (Decode.field "key" Decode.string
                |> Decode.andThen
                    (\key ->
                        if key == "Enter" then
                            Decode.succeed msg

                        else
                            Decode.fail "Not the enter key"
                    )
            )
        )


type alias SearchInputField =
    { label : String
    , placeholder : String
    , onChange : Maybe String -> Msg
    , query : Maybe String
    }


type alias DateSearchField =
    { label : String
    , onChange : ChangeEvent -> Msg
    , state : DatePickerState
    , today : Date
    }


type SearchField
    = DateSearch DateSearchField
    | TextSearch SearchInputField


initDatePicker : Date -> Maybe Date -> DatePickerState
initDatePicker today date =
    { date = date
    , dateText = Maybe.withDefault "" <| Maybe.map Date.toIsoString date
    , pickerModel = DatePicker.init |> DatePicker.setToday today
    }


textSearch : SearchInputField -> Element Msg
textSearch { label, placeholder, query, onChange } =
    Input.search
        [ Element.width (fill |> Element.maximum 400)
        , onEnter SearchWarrants
        ]
        { onChange = onChange << Just
        , text = Maybe.withDefault "" query
        , placeholder = Nothing
        , label = Input.labelAbove [] (text label)
        }


dateSearch : DateSearchField -> Element Msg
dateSearch { label, onChange, state, today } =
    DatePicker.input []
        { onChange = onChange
        , selected = state.date
        , text = state.dateText
        , label =
            Input.labelAbove [] (text label)
        , placeholder = Nothing
        , settings = DatePicker.defaultSettings
        , model = state.pickerModel
        }


searchField : SearchField -> Element Msg
searchField field =
    case field of
        DateSearch dateField ->
            dateSearch dateField

        TextSearch inputField ->
            textSearch inputField


searchFields : Date -> Model -> Search.DetainerWarrants -> List SearchField
searchFields today model filters =
    [ TextSearch { label = "Docket #", placeholder = "", onChange = InputDocketId, query = filters.docketId }
    , DateSearch { label = "File date", onChange = ChangedFileDate, state = model.fileDate, today = today }
    , DateSearch { label = "Court date", onChange = ChangedCourtDate, state = model.courtDate, today = today }
    , TextSearch { label = "Plaintiff", placeholder = "", onChange = InputPlaintiff, query = filters.plaintiff }
    , TextSearch { label = "Plnt. attorney", placeholder = "", onChange = InputPlaintiffAttorney, query = filters.plaintiffAttorney }
    , TextSearch { label = "Defendant", placeholder = "", onChange = InputDefendant, query = filters.defendant }
    , TextSearch { label = "Address", placeholder = "", onChange = InputAddress, query = filters.address }
    ]


viewSearchBar : Date -> Model -> Element Msg
viewSearchBar today model =
    Element.wrappedRow
        [ Element.width (fill |> maximum 1200)
        , Element.spacing 10
        , Element.padding 10
        , Element.centerY
        , Element.centerX
        ]
        (List.map searchField (searchFields today model model.search.filters)
            ++ [ Input.button
                    [ Element.alignBottom
                    , Background.color Palette.redLight
                    , Element.focused [ Background.color Palette.red ]
                    , Element.height fill
                    , Font.color (Element.rgb 255 255 255)
                    , Element.padding 10
                    , Border.rounded 5
                    , height (px 50)
                    ]
                    { onPress = Just SearchWarrants, label = Element.text "Search" }
               ]
        )


createNewWarrant : Element Msg
createNewWarrant =
    row [ centerX ]
        [ link buttonLinkAttrs
            { url = "/admin/detainer-warrants/edit"
            , label = text "Enter New Detainer Warrant"
            }
        ]


viewFilter filters =
    let
        ifNonEmpty prefix fn filter =
            case filter of
                Just value ->
                    [ paragraph [ centerX, Font.center ] [ text (prefix ++ "\"" ++ fn value ++ "\"") ] ]

                Nothing ->
                    []
    in
    List.concat
        [ ifNonEmpty "docket number contains " identity filters.docketId
        , ifNonEmpty "file date is " Date.toIsoString filters.fileDate
        , ifNonEmpty "court date is " Date.toIsoString filters.courtDate
        , ifNonEmpty "plaintiff contains " identity filters.plaintiff
        , ifNonEmpty "plaintiff attorney contains " identity filters.plaintiffAttorney
        , ifNonEmpty "defendant contains " identity filters.defendant
        , ifNonEmpty "address contains " identity filters.address
        ]


viewEmptyResults filters =
    textColumn [ centerX, spacing 10 ]
        ([ paragraph [ Font.center, centerX, Font.size 24 ]
            [ text "No detainer warrants exist matching your search criteria:" ]
         , paragraph [ centerX, Font.italic, Font.center ]
            [ text "where..." ]
         ]
            ++ (List.intersperse (paragraph [ centerX, Font.center ] [ text "&" ]) <| viewFilter filters)
        )


view :
    Maybe PageUrl
    -> Shared.Model
    -> Model
    -> StaticPayload Data RouteParams
    -> View Msg
view maybeUrl sharedModel model static =
    { title = "Admin - Detainer Warrants"
    , body =
        [ row [ centerX, padding 10, Font.size 20, width (fill |> maximum 2000 |> minimum 400) ]
            [ column
                [ centerX
                , spacing 10
                , Element.inFront (loader model)
                ]
                [ createNewWarrant
                , viewSearchBar static.sharedData.runtime.today model
                , case model.search.totalMatches of
                    Just total ->
                        if total > 1 then
                            paragraph [ Font.center ] [ text (FormatNumber.format { usLocale | decimals = Exact 0 } (toFloat total) ++ " detainer warrants matched your search.") ]

                        else
                            Element.none

                    Nothing ->
                        Element.none
                , if model.search.totalMatches == Just 0 then
                    Maybe.withDefault Element.none <| Maybe.map viewEmptyResults model.search.previous

                  else
                    viewWarrants model
                ]
            ]
        ]
    }


loader : Model -> Element Msg
loader { infiniteScroll, search } =
    if InfiniteScroll.isLoading infiniteScroll || search.totalMatches == Nothing then
        row
            [ width fill
            , Element.alignBottom
            ]
            [ Element.el [ centerX, width Element.shrink, height Element.shrink ] (Element.html (Loader.horizontal Color.red)) ]

    else
        Element.none


ascIcon =
    FeatherIcons.chevronUp
        |> Widget.Icon.elmFeather FeatherIcons.toHtml


sortIconStyle =
    { size = 20, color = Color.white }


descIcon =
    FeatherIcons.chevronDown
        |> Widget.Icon.elmFeather FeatherIcons.toHtml


noSortIcon =
    FeatherIcons.chevronDown
        |> Widget.Icon.elmFeather FeatherIcons.toHtml


tableStyle =
    { elementTable = []
    , content =
        { header = buttonStyle
        , ascIcon = ascIcon
        , descIcon = descIcon
        , defaultIcon = noSortIcon
        }
    }


buttonStyle =
    { elementButton =
        [ width (px 40), height (px 40), Background.color Palette.sred, centerX, Font.center ]
    , ifDisabled = []
    , ifActive = []
    , otherwise = []
    , content =
        { elementRow = [ centerX, Font.center ]
        , content =
            { text = { contentText = [] }
            , icon = { ifDisabled = sortIconStyle, ifActive = sortIconStyle, otherwise = sortIconStyle }
            }
        }
    }


buttonLinkAttrs : List (Element.Attribute Msg)
buttonLinkAttrs =
    [ Background.color Palette.white
    , Font.color Palette.red
    , Border.rounded 3
    , Border.color Palette.sred
    , Border.width 1
    , padding 10
    , Font.size 16
    , Element.mouseOver [ Background.color Palette.redLightest ]
    , Element.focused [ Background.color Palette.redLightest ]
    ]


viewEditButton : Maybe String -> Int -> DetainerWarrant -> Element Msg
viewEditButton hovered index warrant =
    row
        (tableCellAttrs (modBy 2 index == 0) hovered warrant)
        [ link
            (buttonLinkAttrs ++ [ Events.onFocus (SelectWarrant warrant.docketId) ])
            { url = Url.Builder.relative [ "detainer-warrants", "edit" ] (Endpoint.toQueryArgs [ ( "docket-id", warrant.docketId ) ])
            , label = text "Edit"
            }
        ]


tableCellAttrs : Bool -> Maybe String -> DetainerWarrant -> List (Element.Attribute Msg)
tableCellAttrs striped hovered warrant =
    [ Element.width (Element.shrink |> maximum 200)
    , height (px 60)
    , Element.clipX
    , Element.padding 10
    , Border.solid
    , Border.color Palette.grayLight
    , Border.widthEach { bottom = 1, left = 0, right = 0, top = 0 }
    , Events.onMouseDown (SelectWarrant warrant.docketId)
    , Events.onMouseEnter (HoverWarrant warrant.docketId)
    ]
        ++ (if hovered == Just warrant.docketId then
                [ Background.color Palette.redLightest ]

            else if striped then
                [ Background.color Palette.grayBack ]

            else
                []
           )


viewHeaderCell text =
    Element.row
        [ Element.width (Element.shrink |> maximum 200)
        , Element.padding 10
        , Font.semiBold
        , Border.solid
        , Border.color Palette.grayLight
        , Border.widthEach { bottom = 1, left = 0, right = 0, top = 0 }
        ]
        [ Element.text text ]


viewTextRow : Maybe String -> (DetainerWarrant -> String) -> Int -> DetainerWarrant -> Element Msg
viewTextRow hovered toText index warrant =
    Element.row (tableCellAttrs (modBy 2 index == 0) hovered warrant)
        [ Element.text (toText warrant) ]


viewDocketId : Maybe String -> Maybe String -> Int -> DetainerWarrant -> Element Msg
viewDocketId hovered selected index warrant =
    let
        striped =
            modBy 2 index == 0

        attrs =
            [ width (Element.shrink |> maximum 200)
            , height (px 60)
            , Border.widthEach { bottom = 0, top = 0, right = 0, left = 4 }
            , Border.color Palette.transparent
            ]
    in
    row
        (attrs
            ++ (if selected == Just warrant.docketId then
                    [ Border.color Palette.sred
                    ]

                else
                    []
               )
            ++ (if hovered == Just warrant.docketId then
                    [ Background.color Palette.redLightest
                    ]

                else if striped then
                    [ Background.color Palette.grayBack ]

                else
                    []
               )
        )
        [ column
            [ width fill
            , height (px 60)
            , padding 10
            , Border.solid
            , Border.color Palette.grayLight
            , Border.widthEach { bottom = 1, left = 0, right = 0, top = 0 }
            ]
            [ Element.el [ Element.centerY ] (text warrant.docketId)
            ]
        ]


viewStatusIcon : Maybe String -> Int -> DetainerWarrant -> Element Msg
viewStatusIcon hovered index warrant =
    let
        icon ( letter, fontColor, backgroundColor ) =
            Element.el
                [ width (px 20)
                , height (px 20)
                , centerX
                , Border.width 1
                , Border.rounded 2
                , Font.color fontColor
                , Background.color backgroundColor
                ]
                (Element.el [ centerX, Element.centerY ]
                    (text <| letter)
                )
    in
    Element.row (tableCellAttrs (modBy 2 index == 0) hovered warrant)
        [ case warrant.status of
            Just Pending ->
                icon ( "P", Palette.gold, Palette.white )

            Just Closed ->
                icon ( "C", Palette.purple, Palette.white )

            Nothing ->
                Element.none
        ]


viewWarrants : Model -> Element Msg
viewWarrants model =
    let
        cell =
            viewTextRow model.hovered
    in
    Element.indexedTable
        [ width (fill |> maximum 1400)
        , height (px 600)
        , Font.size 14
        , Element.scrollbarY
        , Element.htmlAttribute (InfiniteScroll.infiniteScroll InfiniteScrollMsg)
        ]
        { data = model.warrants
        , columns =
            [ { header = Element.none -- viewHeaderCell "Status"
              , view = viewStatusIcon model.hovered
              , width = px 40
              }
            , { header = viewHeaderCell "Docket #"
              , view = viewDocketId model.hovered model.selected
              , width = Element.fill
              }
            , { header = viewHeaderCell "File Date"
              , view = cell (Maybe.withDefault "" << Maybe.map Date.toIsoString << .fileDate)
              , width = Element.fill
              }
            , { header = viewHeaderCell "Plaintiff"
              , view = cell (Maybe.withDefault "" << Maybe.map .name << .plaintiff)
              , width = fill
              }
            , { header = viewHeaderCell "Plnt. Attorney"
              , view = cell (Maybe.withDefault "" << Maybe.map .name << .plaintiffAttorney)
              , width = fill
              }
            , { header = viewHeaderCell "Amount Claimed"
              , view = cell (Maybe.withDefault "" << Maybe.map (String.append "$" << String.fromFloat) << .amountClaimed)
              , width = fill
              }
            , { header = viewHeaderCell "Address"
              , view = cell (Maybe.withDefault "" << Maybe.map .address << List.head << .defendants)
              , width = fill
              }
            , { header = viewHeaderCell "Defendant"
              , view = cell (Maybe.withDefault "" << Maybe.map .name << List.head << .defendants)
              , width = fill
              }
            , { header = viewHeaderCell "Edit"
              , view = viewEditButton model.hovered
              , width = fill
              }
            ]
        }


subscriptions : Maybe PageUrl -> RouteParams -> Path -> Model -> Sub Msg
subscriptions pageUrl params path model =
    Sub.none


type alias RouteParams =
    {}


page : Page.PageWithState RouteParams Data Model Msg
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


head :
    StaticPayload Data RouteParams
    -> List Head.Tag
head static =
    Seo.summary
        { canonicalUrlOverride = Nothing
        , siteName = "elm-pages"
        , image =
            { url = Pages.Url.external "TODO"
            , alt = "elm-pages logo"
            , dimensions = Nothing
            , mimeType = Nothing
            }
        , description = "TODO"
        , locale = Nothing
        , title = "TODO title" -- metadata.title -- TODO
        }
        |> Seo.website