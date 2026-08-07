module Blog.Markup
  ( Document,
    Structure (..),
    compareByDate,
    parse,
  )
where

import Data.Maybe (listToMaybe, mapMaybe)
import Data.Time
import Numeric.Natural

------------------------------

-- * Markup data types

-- | type alias for list of Structures
type Document = [Structure]

-- | Markup Structure
data Structure
  = Heading Natural String
  | Paragraph String
  | UnorderedList [String]
  | OrderedList [String]
  | CodeBlock [String]
  | Date (Maybe Day)
  deriving (Show, Eq)

-- | Parses the string to Markup Document
parse :: String -> Document
parse = ensureDates . map parseBox . splitByEmptyLines . lines

-- | Splits the list of strings byt empty lines
splitByEmptyLines :: [String] -> [[String]]
splitByEmptyLines = foldr step [[]]
  where
    step line (p : ps) = case trim line of
      "" -> [] : p : ps
      _ -> (line : p) : ps
    step line [] = [[line]]

parseBox :: [String] -> Structure
parseBox [] = Paragraph ""
parseBox allLines@(first : _) =
  case first of
    ('*' : ' ' : text) -> Heading 1 (trim text)
    ('-' : ' ' : _) -> UnorderedList $ map (trim . drop 2) allLines
    ('#' : ' ' : _) -> OrderedList $ map (trim . drop 2) allLines
    ('>' : ' ' : _) -> CodeBlock $ map (trim . drop 2) allLines
    ('~' : ' ' : text) -> Date $ parseIsoDay text
    _ -> Paragraph (unlines allLines)

parseIsoDay :: String -> Maybe Day
parseIsoDay = parseTimeM True defaultTimeLocale "%Y-%m-%d"

trim :: String -> String
trim = unwords . words

ensureDates :: Document -> Document
ensureDates doc =
  if any isDate doc
    then doc
    else insertDate doc
  where
    isDate (Date _) = True
    isDate _ = False

    insertDate (heading@(Heading _ _) : rest) = heading : Date Nothing : rest
    insertDate other = Date Nothing : other

compareByDate :: Document -> Document -> Ordering
compareByDate doc1 doc2 =
  compare (extractDate doc2) (extractDate doc1)

extractDate :: Document -> Maybe Day
extractDate doc = listToMaybe (mapMaybe getDay doc)
  where
    getDay (Date mDay) = mDay
    getDay _ = Nothing
