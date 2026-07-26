module Blog.Markup
  ( Document,
    Structure (..),
    parse,
  )
where

import Numeric.Natural

------------------------------

-- * Markup data types

--

-- | type alias for list of Structures
type Document = [Structure]

-- | Markup Structure
data Structure
  = Heading Natural String
  | Paragraph String
  | UnorderedList [String]
  | OrderedList [String]
  | CodeBlock [String]
  deriving (Show, Eq)

-- | Parses the string to Markup Document
parse :: String -> Document
parse = map parseBox . splitByEmptyLines . lines

-- | Splits the list of strings byt empty lines
splitByEmptyLines :: [String] -> [[String]]
splitByEmptyLines = foldr step [[]]
  where
    step line (p : ps) = case trim line of
      "" -> [] : p : ps
      _ -> (line : p) : ps

parseBox :: [String] -> Structure
parseBox [] = Paragraph ""
parseBox allLines@(first : _) =
  case first of
    ('*' : ' ' : text) -> Heading 1 (trim text)
    ('-' : ' ' : _) -> UnorderedList $ map (trim . drop 2) allLines
    ('#' : ' ' : _) -> OrderedList $ map (trim . drop 2) allLines
    ('>' : ' ' : _) -> CodeBlock $ map (drop 2) allLines
    _ -> Paragraph (unlines allLines)

trim :: String -> String
trim = unwords . words
