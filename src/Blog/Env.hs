module Blog.Env where

--------------------------

-- * Envariment

--

-- | Envariment data
data Env = Env
  { -- | The Blog name
    eBlogName :: String,
    -- | The path to the style css file
    eStylePath :: FilePath
  }
  deriving (Show)

-- | Default environment data
defaultEnv :: Env
defaultEnv = Env "My blog" "style.css"
