module Blog.Html.Internal where

import Numeric.Natural

--------------------------

-- * Data Types for HTML

newtype Html = Html String

type Title = String

newtype Head = Head String deriving (Eq, Show)

-- | Basically a html tag that may have other "structures"
newtype Structure = Structure String

-- | The content of html tag
newtype Content = Content String

----------------------------------------

-- * Helper functions for our data types

-- | Transforms Html data type to String
render :: Html -> String
render (Html h) = h

getStructureString :: Structure -> String
getStructureString (Structure a) = a

getContentString :: Content -> String
getContentString (Content a) = a

------------------------------------

-- * Instances to group the Structures

instance Semigroup Head where
  (<>) (Head h1) (Head h2) =
    Head (h1 <> h2)

instance Monoid Head where
  mempty = Head ""

instance Semigroup Structure where
  (<>) c1 c2 =
    Structure (getStructureString c1 <> getStructureString c2)

instance Monoid Structure where
  mempty = Structure ""

instance Semigroup Content where
  (<>) m n =
    Content (getContentString m <> getContentString n)

instance Monoid Content where
  mempty = Content ""

-----------------------------------

-- * Html tags

-- | the Html page itself
html_ :: Head -> Structure -> Html
html_ (Head head') content =
  Html
    ( el
        "html"
        ( el "head" head'
            <> el "body" (getStructureString content)
        )
    )

-- | makes a custom html tag
el :: String -> String -> String
el tag content =
  "<" <> tag <> ">" <> content <> "</" <> tag <> ">"

-- | sets the attributes for the tag
elAttr :: String -> String -> String -> String
elAttr tag attrs content =
  "<" <> tag <> " " <> attrs <> ">" <> content <> "</" <> tag <> ">"

-- ** Structure

p_ :: Content -> Structure
p_ = Structure . el "p" . getContentString

ul_ :: [Structure] -> Structure
ul_ = Structure . el "ul" . concatMap (el "li" . getStructureString)

ol_ :: [Structure] -> Structure
ol_ = Structure . el "ol" . concatMap (el "li" . getStructureString)

code_ :: String -> Structure
code_ = Structure . el "pre" . escape

h_ :: Natural -> Content -> Structure
h_ n = Structure . el ("h" <> show n) . getContentString

--  ** Content

-- | adds the link to the tag "a"
link_ :: FilePath -> Content -> Content
link_ path content =
  Content $
    elAttr
      "a"
      ("href=\"" <> escape path <> "\"")
      (getContentString content)

txt_ :: String -> Content
txt_ = Content . escape

img_ :: FilePath -> Content
img_ path = Content $ "<img src=\"" <> escape path <> "\">"

b_ :: Content -> Content
b_ content = Content $ el "b" (getContentString content)

i_ :: Content -> Content
i_ content = Content $ el "i" (getContentString content)

-- ** Head

title_ :: String -> Head
title_ = Head . el "title" . escape

stylesheet_ :: FilePath -> Head
stylesheet_ path =
  Head $ "<link rel=\"stylesheet\" type=\"text/css\" href=\"" <> escape path <> "\">"

meta_ :: String -> String -> Head
meta_ name content =
  Head $ "<meta name=\"" <> escape name <> "\" content=\"" <> escape content <> "\">"

--------------------------------

-- * Utilities

-- | Transforms special Html characters
escape :: String -> String
escape = concatMap escapeChar
  where
    escapeChar c =
      case c of
        '<' -> "&lt;"
        '>' -> "&gt;"
        '&' -> "&amp;"
        '"' -> "&quot;"
        '\'' -> "&#39;"
        _ -> [c]
