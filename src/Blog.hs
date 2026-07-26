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

process :: String -> String -> String
process title = Html.render . convert defaultEnv title . Markup.parse

-- | reads the content from handle. Processes and writes to the handle
convertSingle :: String -> Handle -> Handle -> IO ()
convertSingle title input output = do
  content <- hGetContents input
  hPutStrLn output (process title content)
