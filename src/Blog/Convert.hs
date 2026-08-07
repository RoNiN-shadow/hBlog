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
    Markup.Date d ->
      Html.p_ $
        Html.txt_ $
          "Date: " <> maybe "Somewhere in the universe" show d

-- | takes @/Env/@ the @/title/@ and the Markup document.
--
-- Converts to @/Html/@ type, adds the @/head/@ with the /BlogName/, stylesheet and meta.
--
-- Adds the BlogName which leads to index.html page, with article itself.
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
