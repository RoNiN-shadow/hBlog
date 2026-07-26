{-# LANGUAGE LambdaCase #-}

module Main where

import qualified Blog
import OptParse
import System.Directory (doesFileExist)
import System.Exit (exitFailure)
import System.IO

main :: IO ()
main = do
  options <- parse
  case options of
    ConvertDir input output env ->
      Blog.convertDirectory env input output
    ConvertSingle input output ->
      withInputHandle input $ \title inHandle ->
        withOutputHandle output $ \outHandle ->
          Blog.convertSingle title inHandle outHandle

--------------------------

-- * Helper functions

withInputHandle :: SingleInput -> (String -> Handle -> IO a) -> IO a
withInputHandle Stdin action = action "" stdin
withInputHandle (InputFile file) action = withFile file ReadMode (action file)

withOutputHandle :: SingleOutput -> (Handle -> IO a) -> IO a
withOutputHandle Stdout action = action stdout
withOutputHandle (OutputFile file) action = do
  exists <- doesFileExist file
  shouldOpen <- if exists then confirm else pure True
  if shouldOpen
    then withFile file WriteMode action
    else exitFailure

------------------------

-- * Utils

confirm :: IO Bool
confirm =
  putStrLn "Are you sure? (y/n)"
    *> getLine
    >>= \case
      "y" -> pure True
      "n" -> pure False
      _ ->
        putStrLn "Invalid response try: y or n"
          *> confirm
