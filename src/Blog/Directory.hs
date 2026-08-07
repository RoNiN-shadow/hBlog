module Blog.Directory
  ( convertDirectory,
    buildIndex,
  )
where

import Blog.Convert (convert, convertStructure)
import Blog.Env (Env (..))
import qualified Blog.Html as Html
import qualified Blog.Markup as Markup
import Control.Exception (SomeException (..), catch, displayException)
import Control.Monad (void, when)
import Control.Monad.Reader
import Data.List (partition, sortBy)
import Data.Maybe (listToMaybe, mapMaybe)
import Data.Time
import Data.Traversable (for)
import System.Directory
  ( copyFile,
    createDirectory,
    doesDirectoryExist,
    listDirectory,
    removeDirectoryRecursive,
  )
import System.Exit (exitFailure)
import System.FilePath
  ( takeBaseName,
    takeExtension,
    takeFileName,
    (<.>),
    (</>),
  )
import System.IO (hPutStrLn, stderr)
import Prelude hiding (head)

-- | Copy files from one to another directory and
-- then convert to .html files
convertDirectory :: Env -> FilePath -> FilePath -> IO ()
convertDirectory env inpDir outputDir = do
  DirContents filesToProcess filesToCopy <- getDirFilesAndContent inpDir
  createOutputDirectoryOrExit outputDir

  let outputHtmls = runReader (txtsToRenderedHtml filesToProcess) env
  copyFiles outputDir filesToCopy
  writeFiles outputDir outputHtmls
  copyFile (eStylePath env) (outputDir </> "style.css")

------------------------------------

-- * Read Directory Content

--

-- | Returns the directory content
getDirFilesAndContent :: FilePath -> IO DirContents
getDirFilesAndContent inpDir = do
  files <- map (inpDir </>) <$> listDirectory inpDir
  let (txtFiles, otherFiles) = partition ((== ".txt") . takeExtension) files

  txtFilesAndContent <- applyIoOnList readFile txtFiles >>= filterAndReportFailures
  pure $
    DirContents
      { dcFilesToProcess = txtFilesAndContent,
        dcFilesToCopy = otherFiles
      }

-- | Relevent directory content(data structure)
data DirContents = DirContents
  { -- | file paths and their content
    dcFilesToProcess :: [(FilePath, String)],
    dcFilesToCopy :: [FilePath]
  }

-------------------------------

-- * Build index page

-- | Builds the index page
buildIndex :: [(FilePath, Markup.Document)] -> Reader Env Html.Html
buildIndex files = do
  env <- ask
  let head =
        Html.title_ (eBlogName env)
          <> Html.stylesheet_ (eStylePath env)
          <> Html.meta_ "viewport" "width=device-width, initial-scale=1.0"

      header =
        Html.h_ 1 (Html.link_ "index.html" (Html.txt_ (eBlogName env)))
          <> Html.h_ 2 (Html.txt_ "Posts")

      documentation =
        Html.h_ 3 (Html.link_ "api/index.html" $ Html.txt_ "Documentation")

      sortedFiles = sortBy compareDocuments files
      articlePrews = foldMap buildPreview sortedFiles
  pure $ Html.html_ head (header <> documentation <> articlePrews)

buildPreview :: (FilePath, Markup.Document) -> Html.Structure
buildPreview (file, document) =
  case document of
    (Markup.Heading 1 title : article) ->
      Html.h_ 3 (Html.link_ file (Html.txt_ title))
        <> foldMap convertStructure (take 3 article)
        <> Html.p_ (Html.link_ file (Html.txt_ "..."))
    _ ->
      Html.h_ 3 (Html.link_ file (Html.txt_ file))

compareDocuments :: (FilePath, Markup.Document) -> (FilePath, Markup.Document) -> Ordering
compareDocuments (_, doc1) (_, doc2) =
  compare (extractDate doc2) (extractDate doc1)

extractDate :: Markup.Document -> Maybe Day
extractDate doc = listToMaybe (mapMaybe getDay doc)
  where
    getDay (Markup.Date mDay) = mDay
    getDay _ = Nothing

--------------------------

-- * Convertion

-- | Convert text to Markup, build index and render as html
txtsToRenderedHtml :: [(FilePath, String)] -> Reader Env [(FilePath, String)]
txtsToRenderedHtml txtFiles = do
  let txtOutputFiles = map toOutputMarkupFile txtFiles
  index <- (,) "index.html" <$> buildIndex txtOutputFiles

  htmlPages <- traverse convertFile txtOutputFiles
  pure $ map (fmap Html.render) (index : htmlPages)

toOutputMarkupFile :: (FilePath, String) -> (FilePath, Markup.Document)
toOutputMarkupFile (name, cont) = (takeBaseName name <.> "html", Markup.parse cont)

convertFile :: (FilePath, Markup.Document) -> Reader Env (FilePath, Html.Html)
convertFile (file, doc) = do
  env <- ask
  pure (file, convert env (takeBaseName file) doc)

-----------------------------------

-- * Output to directory

-- | Creates an output directory or terminates the program
createOutputDirectoryOrExit :: FilePath -> IO ()
createOutputDirectoryOrExit outDir =
  whenIO
    (not <$> createOutputDirectory outDir)
    (hPutStrLn stderr "Cancelled." *> exitFailure)

-- | Creats the output directory.
-- Returns whether the directory was created or not
createOutputDirectory :: FilePath -> IO Bool
createOutputDirectory outDir = do
  dirExists <- doesDirectoryExist outDir
  create <-
    if dirExists
      then do
        ovveride <- confirm "Output directory exists. Ovveride?"
        when ovveride (removeDirectoryRecursive outDir)
        pure ovveride
      else pure True
  when create (createDirectory outDir)
  pure create

-- | Copy files to a directory, recording erros to stderr
copyFiles :: FilePath -> [FilePath] -> IO ()
copyFiles outputDir files = do
  let copyFromTo file = copyFile file (outputDir </> takeFileName file)
  void $ applyIoOnList copyFromTo files >>= filterAndReportFailures

-- | Write files to a directory, recording errors to stderr
writeFiles :: FilePath -> [(FilePath, String)] -> IO ()
writeFiles outputDir files = do
  let writeFileContent (file, content) = writeFile (outputDir </> file) content
  void $ applyIoOnList writeFileContent files >>= filterAndReportFailures

-------------------------------------

-- * IO work and handling erros

-- | Try to apply an IO function to a list of values, document
-- the success and failures
applyIoOnList :: (a -> IO b) -> [a] -> IO [(a, Either String b)]
applyIoOnList action inputs = do
  for inputs $ \input -> do
    maybeResult <-
      catch
        (Right <$> action input)
        ( \(SomeException e) -> do
            pure $ Left (displayException e)
        )
    pure (input, maybeResult)

-- | Filter unsuccesful operations on files report them to stderr
filterAndReportFailures :: [(a, Either String b)] -> IO [(a, b)]
filterAndReportFailures =
  foldMap $ \(file, contentOrError) ->
    case contentOrError of
      Left err -> do
        hPutStrLn stderr err
        pure []
      Right content ->
        pure [(file, content)]

----------------------------------

-- * Utilities

--
confirm :: String -> IO Bool
confirm question = do
  putStrLn (question <> " (y/n)")
  answer <- getLine
  case answer of
    "y" -> pure True
    "n" -> pure False
    _ -> do
      putStrLn "Invalid response. Use y or n."
      confirm question

whenIO :: IO Bool -> IO () -> IO ()
whenIO cond action = do
  result <- cond
  when result action
