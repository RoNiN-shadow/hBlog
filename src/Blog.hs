module Blog
  ( process,
    convertSingle,
    convertDirectory,
    buildIndex,
  )
where

import Blog.Convert (convert)
import Blog.Directory (buildIndex, convertDirectory)
import Blog.Env (defaultEnv)
import qualified Blog.Html as Html
import qualified Blog.Markup as Markup
import System.IO

----------------------

-- | takes __title__ . Then parses the given __String__ to Markup. Outputs __String__ Html
process :: String -> String -> String
process title = Html.render . convert defaultEnv title . Markup.parse

-- | takes the /title/ input and output handels. Converts the single Markup page and writes the html on the disk to the given /output/ handle
convertSingle :: String -> Handle -> Handle -> IO ()
convertSingle title input output = do
  content <- hGetContents input
  hPutStrLn output (process title content)
