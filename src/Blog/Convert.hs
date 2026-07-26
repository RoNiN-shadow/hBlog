module Blog.Convert where

import Blog.Env (Env (..))
import qualified Blog.Html as Html
import qualified Blog.Markup as Markup
import Prelude hiding (head)

-- | Converts Markup structure to the html structure
convertStructure :: Markup.Structure -> Html.Structure
convertStructure st =
  case st of
    Markup.Heading n txt ->
      Html.h_ n $ Html.txt_ txt
    Markup.Paragraph p ->
      Html.p_ $ Html.txt_ p
    Markup.UnorderedList ls ->
      Html.ul_ $ map (Html.p_ . Html.txt_) ls
    Markup.OrderedList ls ->
      Html.ol_ $ map (Html.p_ . Html.txt_) ls
    Markup.CodeBlock cod ->
      Html.code_ $ unlines cod

-- | converts Markup doc to html
convert :: Env -> String -> Markup.Document -> Html.Html
convert env title doc =
  let head =
        Html.title_ (eBlogName env <> " - " <> title)
          <> Html.stylesheet_ (eStylePath env)
          <> Html.meta_ "viewport" "width=device-width, initial-scale=1.0"

      article = foldMap convertStructure doc

      websiteTitle = Html.h_ 1 (Html.link_ "index.html" $ Html.txt_ $ eBlogName env)
      body = websiteTitle <> article
   in Html.html_ head body
