{-# LANGUAGE QuasiQuotes #-}

module HtmlParsingSpec where

import qualified Blog.Html.Internal as Html
import Test.Hspec
import Text.RawString.QQ

spec :: Spec
spec = do
  describe "Check Html markup creating" $ do
    it "meta tag" $ do
      shouldBe
        (Html.meta_ "viewport" "width=device-width, initial-scale=1.0")
        (Html.Head metaString)

metaString :: String
metaString = [r|<meta name="viewport" content="width=device-width, initial-scale=1.0">|]
