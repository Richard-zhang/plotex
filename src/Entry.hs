module Entry
    (main) where

import           Config
import           Lib

import           Data.Semigroup      ((<>))
import           Options.Applicative
import           System.Directory

config :: FilePath -> Parser Config
config defdir = Config
    <$> strOption
        ( long "dir"
       <> short 'd'
       <> help "File path of the LaTeX file"
       <> value defdir)

configWithInfo :: FilePath -> ParserInfo Config
configWithInfo defdir =
    info (config defdir <**> helper)
        ( fullDesc
       <> header "Plotex - a tool for Practical mathematicians")

main :: IO ()
main = do
    filePath <- getCurrentDirectory
    con <- execParser $ configWithInfo filePath
    evalLatex con