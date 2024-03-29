module Judgment exposing (ConditionOption(..), Conditions(..), DismissalBasis(..), DismissalConditions, Entrance(..), Interest(..), Judgment, JudgmentEdit, JudgmentForm, OwedConditions, conditionText, conditionsOptions, conditionsText, decoder, dismissalBasisOption, dismissalBasisOptions, dismissalBasisPrint, editFromForm, tableColumns, toTableCover, toTableDetails, toTableRow)

import Attorney exposing (Attorney)
import Date exposing (Date)
import Hearing exposing (Hearing)
import Json.Decode as Decode exposing (Decoder, bool, float, int, nullable, string)
import Json.Decode.Pipeline exposing (custom, optional, required)
import Judge exposing (Judge)
import Plaintiff exposing (Plaintiff)
import PleadingDocument exposing (PleadingDocument)
import String.Extra
import Time exposing (Posix)
import Time.Utils exposing (posixDecoder)
import UI.Button exposing (Button)
import UI.Dropdown as Dropdown
import UI.Tables.Common as Common exposing (Row, cellFromButton, cellFromText, columnWidthPixels, columnsEmpty, rowCellButton, rowCellText, rowEmpty)
import UI.Tables.Stateful exposing (detailShown, detailsEmpty)
import UI.Text as Text
import UI.Utils.TypeNumbers as T


type Entrance
    = Default
    | AgreementOfParties
    | TrialInCourt


type DismissalBasis
    = FailureToProsecute
    | FindingInFavorOfDefendant
    | NonSuitByPlaintiff


type Interest
    = WithRate Float
    | FollowsSite


type alias OwedConditions =
    { awardsFees : Maybe Float
    , awardsPossession : Maybe Bool
    , interest : Maybe Interest
    }


type alias DismissalConditions =
    { basis : DismissalBasis
    , withPrejudice : Bool
    }


type Conditions
    = PlaintiffConditions OwedConditions
    | DefendantConditions DismissalConditions


type alias Judgment =
    { id : Int
    , docketId : String
    , notes : Maybe String
    , fileDate : Maybe Posix
    , enteredBy : Entrance
    , plaintiff : Maybe Plaintiff
    , plaintiffAttorney : Maybe Attorney
    , judge : Maybe Judge
    , conditions : Maybe Conditions
    , hearing : Hearing
    , document : Maybe PleadingDocument
    }


type alias JudgmentEdit =
    { id : Maybe Int
    , notes : Maybe String
    , enteredBy : Maybe String
    , inFavorOf : Maybe String
    , plaintiff : Maybe Plaintiff
    , plaintiffAttorney : Maybe Attorney
    , judge : Maybe Judge

    -- Plaintiff Favor
    , awardsFees : Maybe Float
    , awardsPossession : Maybe Bool
    , hasInterest : Bool
    , interestRate : Maybe Float
    , interestFollowsSite : Maybe Bool

    -- Tenant Favor
    , dismissalBasis : Maybe String
    , withPrejudice : Maybe Bool
    }


type alias JudgmentForm =
    { id : Maybe Int
    , conditionsDropdown : Dropdown.State (Maybe ConditionOption)
    , condition : Maybe ConditionOption
    , enteredBy : Entrance
    , notes : String
    , awardsFees : String
    , awardsPossession : Bool
    , hasInterest : Bool
    , interestRate : String
    , interestFollowsSite : Bool
    , dismissalBasisDropdown : Dropdown.State DismissalBasis
    , dismissalBasis : DismissalBasis
    , withPrejudice : Bool
    , plaintiff : Plaintiff.PlaintiffForm
    , plaintiffAttorney : Attorney.AttorneyForm
    , judge : Judge.JudgeForm
    }


type ConditionOption
    = PlaintiffOption
    | DefendantOption


conditionsOptions : List (Maybe ConditionOption)
conditionsOptions =
    [ Nothing, Just PlaintiffOption, Just DefendantOption ]


dismissalBasisOptions : List DismissalBasis
dismissalBasisOptions =
    [ FailureToProsecute, FindingInFavorOfDefendant, NonSuitByPlaintiff ]


conditionsText : Conditions -> String
conditionsText conditions =
    case conditions of
        PlaintiffConditions _ ->
            "Plaintiff"

        DefendantConditions _ ->
            "Defendant"


conditionText : ConditionOption -> String
conditionText option =
    case option of
        PlaintiffOption ->
            "Plaintiff"

        DefendantOption ->
            "Defendant"


entranceText : Entrance -> String
entranceText entrance =
    case entrance of
        Default ->
            "DEFAULT"

        AgreementOfParties ->
            "AGREEMENT_OF_PARTIES"

        TrialInCourt ->
            "TRIAL_IN_COURT"


dismissalBasisOption : DismissalBasis -> String
dismissalBasisOption basis =
    basis
        |> dismissalBasisText
        |> String.replace "_" " "
        |> String.toLower
        |> String.Extra.toSentenceCase


dismissalBasisText : DismissalBasis -> String
dismissalBasisText basis =
    case basis of
        FailureToProsecute ->
            "FAILURE_TO_PROSECUTE"

        FindingInFavorOfDefendant ->
            "FINDING_IN_FAVOR_OF_DEFENDANT"

        NonSuitByPlaintiff ->
            "NON_SUIT_BY_PLAINTIFF"


dismissalBasisPrint : DismissalBasis -> String
dismissalBasisPrint basis =
    case basis of
        FailureToProsecute ->
            "Failure to prosecute"

        FindingInFavorOfDefendant ->
            "Finding in favor of defendant"

        NonSuitByPlaintiff ->
            "Non-suit by plaintiff"


editFromForm : Date -> JudgmentForm -> JudgmentEdit
editFromForm today form =
    let
        rate =
            String.toFloat <| String.replace "%" "" form.interestRate
    in
    { id = form.id
    , notes =
        if String.isEmpty form.notes then
            Nothing

        else
            Just form.notes
    , enteredBy = Just <| entranceText form.enteredBy
    , inFavorOf =
        Maybe.map
            (\option ->
                case option of
                    PlaintiffOption ->
                        "PLAINTIFF"

                    DefendantOption ->
                        "DEFENDANT"
            )
            form.condition
    , awardsFees =
        if form.awardsFees == "" then
            Nothing

        else
            String.toFloat <| String.replace "," "" form.awardsFees
    , awardsPossession =
        if form.condition == Just DefendantOption then
            Nothing

        else
            Just form.awardsPossession
    , hasInterest = form.hasInterest
    , interestRate =
        if form.hasInterest && not form.interestFollowsSite then
            rate

        else
            Nothing
    , interestFollowsSite =
        if form.hasInterest && form.interestFollowsSite then
            Just form.interestFollowsSite

        else
            Nothing
    , dismissalBasis =
        if form.condition == Just DefendantOption then
            Just (dismissalBasisText form.dismissalBasis)

        else
            Nothing
    , withPrejudice =
        if form.condition == Just DefendantOption then
            Just form.withPrejudice

        else
            Nothing
    , plaintiff =
        form.plaintiff.person
    , plaintiffAttorney =
        form.plaintiffAttorney.person
    , judge =
        form.judge.person
    }


interestConditionsDecoder : Decoder Interest
interestConditionsDecoder =
    Decode.field "interest_rate" (nullable float)
        |> Decode.andThen
            (\rate ->
                Decode.succeed <|
                    case rate of
                        Nothing ->
                            FollowsSite

                        Just someRate ->
                            WithRate someRate
            )


interestDecoder : Decoder (Maybe Interest)
interestDecoder =
    Decode.field "interest" (nullable bool)
        |> Decode.andThen
            (\maybeHasInterest ->
                maybeHasInterest
                    |> Maybe.map
                        (\hasInterest ->
                            if hasInterest then
                                Decode.map Just interestConditionsDecoder

                            else
                                Decode.succeed Nothing
                        )
                    |> Maybe.withDefault (Decode.succeed Nothing)
            )


owedConditionsDecoder : Decoder OwedConditions
owedConditionsDecoder =
    Decode.succeed OwedConditions
        |> required "awards_fees" (nullable float)
        |> required "awards_possession" (nullable bool)
        |> custom interestDecoder


dismissalBasisDecoder : Decoder DismissalBasis
dismissalBasisDecoder =
    Decode.string
        |> Decode.andThen
            (\str ->
                case str of
                    "FAILURE_TO_PROSECUTE" ->
                        Decode.succeed FailureToProsecute

                    "FINDING_IN_FAVOR_OF_DEFENDANT" ->
                        Decode.succeed FindingInFavorOfDefendant

                    "NON_SUIT_BY_PLAINTIFF" ->
                        Decode.succeed NonSuitByPlaintiff

                    _ ->
                        Decode.fail "oops"
            )


dismissalConditionsDecoder : Decoder DismissalConditions
dismissalConditionsDecoder =
    Decode.succeed DismissalConditions
        |> optional "dismissal_basis" dismissalBasisDecoder FailureToProsecute
        |> optional "with_prejudice" bool False


entranceDecoder : Decoder Entrance
entranceDecoder =
    Decode.string
        |> Decode.andThen
            (\str ->
                case str of
                    "DEFAULT" ->
                        Decode.succeed Default

                    "AGREEMENT_OF_PARTIES" ->
                        Decode.succeed AgreementOfParties

                    "TRIAL_IN_COURT" ->
                        Decode.succeed TrialInCourt

                    _ ->
                        Decode.fail "oops"
            )


fromConditions : Maybe Conditions -> Decoder Judgment
fromConditions conditions =
    Decode.succeed Judgment
        |> required "id" int
        |> required "detainer_warrant_id" string
        |> required "notes" (nullable string)
        |> required "file_date" (nullable posixDecoder)
        |> required "entered_by" entranceDecoder
        |> required "plaintiff" (nullable Plaintiff.decoder)
        |> required "plaintiff_attorney" (nullable Attorney.decoder)
        |> required "judge" (nullable Judge.decoder)
        |> custom (Decode.succeed conditions)
        |> required "hearing" Hearing.decoder
        |> required "document" (nullable PleadingDocument.decoder)


decoder : Decoder Judgment
decoder =
    Decode.field "in_favor_of" (nullable string)
        |> Decode.andThen
            (\maybeStr ->
                case maybeStr of
                    Just "PLAINTIFF" ->
                        Decode.map (Just << PlaintiffConditions) owedConditionsDecoder

                    Just "DEFENDANT" ->
                        Decode.map (Just << DefendantConditions) dismissalConditionsDecoder

                    _ ->
                        Decode.succeed Nothing
            )
        |> Decode.andThen fromConditions


tableColumns =
    columnsEmpty
        |> Common.column "Docket ID" (columnWidthPixels 150)
        |> Common.column "File date" (columnWidthPixels 150)
        |> Common.column "Court date" (columnWidthPixels 150)
        |> Common.column "Plaintiff" (columnWidthPixels 240)
        |> Common.column "Pltf. Attorney" (columnWidthPixels 240)
        |> Common.column "" (columnWidthPixels 100)


toTableRow : (Judgment -> Button msg) -> { toKey : Judgment -> String, view : Judgment -> Row msg T.Six }
toTableRow toEditButton =
    { toKey = .docketId, view = toTableRowView toEditButton }


toTableRowView : (Judgment -> Button msg) -> Judgment -> Row msg T.Six
toTableRowView toEditButton ({ docketId, fileDate, plaintiff, plaintiffAttorney } as judgment) =
    rowEmpty
        |> rowCellText (Text.body2 docketId)
        |> rowCellText (Text.body2 (Maybe.withDefault "" <| Maybe.map Time.Utils.toIsoString fileDate))
        |> rowCellText (Text.body2 (Time.Utils.toIsoString judgment.hearing.courtDate))
        |> rowCellText (Text.body2 (Maybe.withDefault "" <| Maybe.map .name plaintiff))
        |> rowCellText (Text.body2 (Maybe.withDefault "" <| Maybe.map .name plaintiffAttorney))
        |> rowCellButton (toEditButton judgment)


toTableDetails toEditButton ({ docketId, fileDate, plaintiff, plaintiffAttorney } as judgment) =
    detailsEmpty
        |> detailShown
            { label = "Docket ID"
            , content = cellFromText <| Text.body2 docketId
            }
        |> detailShown
            { label = "File date"
            , content = cellFromText <| Text.body2 (Maybe.withDefault "" <| Maybe.map Time.Utils.toIsoString fileDate)
            }
        |> detailShown
            { label = "Court date"
            , content = cellFromText <| Text.body2 (Time.Utils.toIsoString judgment.hearing.courtDate)
            }
        |> detailShown
            { label = "Plaintiff"
            , content = cellFromText <| Text.body2 (Maybe.withDefault "" <| Maybe.map .name plaintiff)
            }
        |> detailShown
            { label = "Pltf. Attorney"
            , content = cellFromText <| Text.body2 (Maybe.withDefault "" <| Maybe.map .name plaintiffAttorney)
            }
        |> detailShown
            { label = "Edit"
            , content = cellFromButton (toEditButton judgment)
            }


toTableCover { docketId } =
    { title = docketId, caption = Nothing }
