module OptParse
  ( Options (..),
    SingleInput (..),
    SingleOutput (..),
    parse,
  )
where

import Blog.Env
import Data.Maybe (fromMaybe)
import Options.Applicative

data Options
  = ConvertSingle SingleInput SingleOutput
  | ConvertDir FilePath FilePath Env
  deriving (Show)

data SingleInput = Stdin | InputFile FilePath
  deriving (Show)

data SingleOutput = Stdout | OutputFile FilePath
  deriving (Show)

pInputFile :: Parser SingleInput
pInputFile =
  InputFile
    <$> strOption
      ( long "input"
          <> short 'i'
          <> metavar "FILE"
          <> help "input file"
      )

pSingleInput :: Parser SingleInput
pSingleInput = fromMaybe Stdin <$> optional pInputFile

pOutputFile :: Parser SingleOutput
pOutputFile =
  OutputFile
    <$> strOption
      ( long "output"
          <> short 'o'
          <> metavar "FILE"
          <> help "output file"
      )

pSingleOuput :: Parser SingleOutput
pSingleOuput = fromMaybe Stdout <$> optional pOutputFile

pConvertSingle :: Parser Options
pConvertSingle = ConvertSingle <$> pSingleInput <*> pSingleOuput

pInputDir :: Parser FilePath
pInputDir =
  strOption $
    long "input"
      <> short 'i'
      <> metavar "DIRECTORY"
      <> help "input directory"

pOutputDir :: Parser FilePath
pOutputDir =
  strOption $
    long "output"
      <> short 'o'
      <> metavar "DIRECTORY"
      <> help "output directory"

pConvertDir :: Parser Options
pConvertDir =
  ConvertDir <$> pInputDir <*> pOutputDir <*> pEnv

pEnv :: Parser Env
pEnv =
  Env <$> pBlogName <*> pStylesheet

pBlogName :: Parser String
pBlogName =
  strOption
    ( long "name"
        <> short 'N'
        <> metavar "STRING"
        <> help "Blog name"
        <> value (eBlogName defaultEnv)
        <> showDefault
    )

pStylesheet :: Parser String
pStylesheet =
  strOption
    ( long "style"
        <> short 'S'
        <> metavar "FILE"
        <> help "Stylesheet filename"
        <> value (eStylePath defaultEnv)
        <> showDefault
    )

pConvertSingleInfo :: ParserInfo Options
pConvertSingleInfo =
  info
    (helper <*> pConvertSingle)
    (progDesc "Convert a single markup source to html")

pConvertSingleCommand :: Mod CommandFields Options
pConvertSingleCommand =
  command
    "convert"
    pConvertSingleInfo

pConvertDirectoryInfo :: ParserInfo Options
pConvertDirectoryInfo =
  info
    (helper <*> pConvertDir)
    (progDesc "Convert a directory of markups sources to html")

pConvertDirectoryCommand :: Mod CommandFields Options
pConvertDirectoryCommand =
  command
    "convert-dir"
    pConvertDirectoryInfo

pOptions :: Parser Options
pOptions =
  subparser $
    pConvertSingleCommand
      <> pConvertDirectoryCommand

opts :: ParserInfo Options
opts =
  info (helper <*> pOptions) $
    fullDesc
      <> header "blog - static blog generator"
      <> progDesc "Convert markup files or directories"

parse :: IO Options
parse = execParser opts
