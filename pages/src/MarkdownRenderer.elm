module MarkdownRenderer exposing (renderer, view)

import Element
    exposing
        ( Element
        , alignTop
        , centerX
        , centerY
        , clip
        , clipX
        , clipY
        , column
        , el
        , fill
        , height
        , link
        , maximum
        , minimum
        , newTabLink
        , padding
        , paddingEach
        , paddingXY
        , paragraph
        , rgb255
        , rgba
        , row
        , spacing
        , spacingXY
        , table
        , text
        , width
        )
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import Element.Input as Input
import Element.Region as Region
import Html exposing (Attribute, Html)
import Html.Attributes
import Markdown.Block as Block exposing (Block, Inline, ListItem(..), Task(..))
import Markdown.Html
import Markdown.Parser
import Markdown.Renderer
import SyntaxHighlight


buildToc : List Block -> TableOfContents
buildToc blocks =
    let
        headings =
            gatherHeadings blocks
    in
    headings
        |> List.map Tuple.second
        |> List.map
            (\styledList ->
                { anchorId = styledList |> inlinesToId
                , name = styledToString styledList
                , level = 1
                }
            )


tocView : TableOfContents -> Element msg
tocView toc =
    Element.column
        [ Element.alignTop
        , Element.spacing 20
        ]
        [ Element.el [ Font.bold, Font.size 22 ] (Element.text "Table of Contents")
        , Element.column [ Element.spacing 10 ]
            (toc
                |> List.map
                    (\headingBlock ->
                        Element.link [ Font.color (Element.rgb255 100 100 100) ]
                            { url = "#" ++ headingBlock.anchorId
                            , label = Element.text headingBlock.name
                            }
                    )
            )
        ]


styledToString : List Inline -> String
styledToString inlines =
    --List.map .string list
    --|> String.join "-"
    -- TODO do I need to hyphenate?
    inlines
        |> Block.extractInlineText


inlinesToId : List Inline -> String
inlinesToId list =
    list
        |> Block.extractInlineText
        |> String.split " "
        |> String.join "-"


gatherHeadings : List Block -> List ( Block.HeadingLevel, List Inline )
gatherHeadings blocks =
    List.filterMap
        (\block ->
            case block of
                Block.Heading level content ->
                    Just ( level, content )

                _ ->
                    Nothing
        )
        blocks


type alias TableOfContents =
    List { anchorId : String, name : String, level : Int }


view : String -> Result String ( TableOfContents, List (Element msg) )
view markdown =
    case
        markdown
            |> Markdown.Parser.parse
    of
        Ok okAst ->
            case Markdown.Renderer.render renderer okAst of
                Ok rendered ->
                    Ok ( buildToc okAst, rendered )

                Err errors ->
                    Err errors

        Err error ->
            Err (error |> List.map Markdown.Parser.deadEndToString |> String.join "\n")


renderer : Markdown.Renderer.Renderer (Element msg)
renderer =
    { heading = heading
    , paragraph =
        paragraph
            [ width fill
            , spacingXY 0 10
            , padding 10
            ]
    , thematicBreak = Element.none
    , text = \value -> paragraph [ width fill ] [ text value ]
    , strong = \content -> paragraph [ width fill, Font.bold, Font.color grayFont ] content
    , emphasis = \content -> paragraph [ width fill, Font.italic ] content
    , strikethrough = \content -> paragraph [ width fill, Font.strike ] content
    , codeSpan = code
    , link =
        \{ title, destination } body ->
            Element.newTabLink []
                { url = destination
                , label =
                    paragraph
                        [ Font.color (rgb255 0 0 255)
                        , Element.htmlAttribute (Html.Attributes.style "overflow-wrap" "break-word")
                        , Element.htmlAttribute (Html.Attributes.style "word-break" "break-word")
                        ]
                        body
                }
    , hardLineBreak = Html.br [] [] |> Element.html
    , image =
        \image ->
            case image.title of
                Just title ->
                    column [ width fill ]
                        [ paragraph [ Font.bold, Font.center, Font.color grayFont ] [ text title ]
                        , Element.image [ width fill ] { src = image.src, description = image.alt }
                        ]

                Nothing ->
                    Element.image [ width fill ] { src = image.src, description = image.alt }
    , blockQuote =
        \children ->
            paragraph
                [ Border.widthEach { top = 0, right = 0, bottom = 0, left = 10 }
                , padding 10
                , Border.color (rgb255 145 145 145)
                , Background.color (rgb255 245 245 245)
                , width fill
                ]
                children
    , unorderedList =
        \items ->
            column [ spacingXY 0 10, width fill, paddingXY 0 10 ]
                (items
                    |> List.map
                        (\(ListItem task children) ->
                            paragraph [ spacing 5 ]
                                [ paragraph
                                    [ alignTop ]
                                    ((case task of
                                        IncompleteTask ->
                                            Input.defaultCheckbox False

                                        CompletedTask ->
                                            Input.defaultCheckbox True

                                        NoTask ->
                                            text "•"
                                     )
                                        :: text " "
                                        :: children
                                    )
                                ]
                        )
                )
    , orderedList =
        \startingIndex items ->
            column [ spacingXY 0 10, width fill ]
                (items
                    |> List.indexedMap
                        (\index itemBlocks ->
                            paragraph [ spacing 5 ]
                                [ paragraph [ alignTop ]
                                    (text (String.fromInt (index + startingIndex) ++ " ") :: itemBlocks)
                                ]
                        )
                )
    , codeBlock = codeBlock
    , table = column [ width fill ]
    , tableHeader =
        column
            [ Font.bold
            , width fill
            , Font.center
            ]
    , tableBody = column [ width fill ]
    , tableRow =
        row
            [ height fill
            , width fill
            ]
    , tableHeaderCell =
        \maybeAlignment children ->
            paragraph
                tableBorder
                children
    , tableCell =
        \maybeAlignment children ->
            paragraph
                tableBorder
                children
    , html = Markdown.Html.oneOf []
    }


alternateTableRowBackground =
    rgb255 245 247 249


tableBorder =
    [ Border.color (rgb255 223 226 229)
    , Border.width 1
    , Border.solid
    , paddingXY 6 13
    , height fill
    , Font.color grayFont
    , Font.size 8
    , clip
    ]


redFont =
    rgb255 220 47 54


grayFont =
    rgb255 75 75 75


rawTextToId : String -> String
rawTextToId rawText =
    rawText
        |> String.split " "
        |> String.join "-"
        |> String.toLower


heading : { level : Block.HeadingLevel, rawText : String, children : List (Element msg) } -> Element msg
heading { level, rawText, children } =
    let
        attrs =
            [ Font.size 20
            , Font.bold
            , Font.family [ Font.typeface "system" ]
            , Region.heading (Block.headingLevelToInt level)
            , Element.htmlAttribute
                (Html.Attributes.attribute "name" (rawTextToId rawText))
            , Element.htmlAttribute
                (Html.Attributes.id (rawTextToId rawText))
            , paddingXY 10 15
            , Font.color redFont
            , width fill
            ]
    in
    column
        [ width fill
        , paddingEach { top = 15, bottom = 0, left = 0, right = 0 }
        ]
        [ case level of
            Block.H1 ->
                paragraph
                    (attrs
                        ++ [ Background.color grayFont
                           , Font.color (rgb255 255 87 87)
                           , Font.center
                           , centerX
                           , centerY
                           , Font.size 40
                           ]
                    )
                    [ link
                        [ width fill ]
                        { url = "#" ++ rawTextToId rawText
                        , label = paragraph [ width fill ] children
                        }
                    ]

            Block.H2 ->
                paragraph
                    (attrs
                        ++ [ Background.color (rgb255 255 87 87)
                           , Font.color (rgb255 255 255 255)
                           , paddingXY 10 15
                           , Font.size 36
                           ]
                    )
                    [ link
                        [ width fill ]
                        { url = "#" ++ rawTextToId rawText
                        , label = paragraph [ width fill ] children
                        }
                    ]

            Block.H3 ->
                paragraph (attrs ++ [ Font.size 26 ])
                    [ link
                        [ width fill ]
                        { url = "#" ++ rawTextToId rawText
                        , label = paragraph [ width fill ] children
                        }
                    ]

            Block.H4 ->
                paragraph (attrs ++ [ Font.color grayFont ]) children

            _ ->
                paragraph attrs children
        ]


code : String -> Element msg
code snippet =
    el
        [ Background.color
            (rgba 0 0 0 0.04)
        , Border.rounded 2
        , paddingXY 5 3
        , Font.family
            [ Font.external
                { url = "https://fonts.googleapis.com/css?family=Source+Code+Pro"
                , name = "Source Code Pro"
                }
            ]
        ]
        (text snippet)


codeBlock : { body : String, language : Maybe String } -> Element msg
codeBlock details =
    paragraph
        [ Background.color (rgba 0 0 0 0.03)
        , Element.htmlAttribute (Html.Attributes.style "white-space" "pre")
        , Element.htmlAttribute (Html.Attributes.style "overflow-wrap" "break-word")
        , Element.htmlAttribute (Html.Attributes.style "word-break" "break-word")
        , padding 20
        , Font.family
            [ Font.external
                { url = "https://fonts.googleapis.com/css?family=Source+Code+Pro"
                , name = "Source Code Pro"
                }
            ]
        ]
        [ text details.body ]
