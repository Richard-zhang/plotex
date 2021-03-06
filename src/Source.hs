module Source where

import           Data.Char                              (isSpace)
import qualified Data.Text                              as T
import qualified Math                                   as M
import           Text.ParserCombinators.Parsec
import           Text.ParserCombinators.Parsec.Language (haskellDef)
import qualified Text.ParserCombinators.Parsec.Token    as P
type PlotExpr = M.Expr Double

data PlotSL = PSeq PlotSL PlotSL
            | PRange PlotRange PlotSL
            | PCom PlotExpr PlotConfig
            deriving (Show, Eq)

data PlotRange = PFor Integer Integer PlotExpr deriving (Show, Eq)

data PlotConfig = PlotConfig { range :: (Integer, Integer), style :: String } deriving (Show, Eq)

lexer       = P.makeTokenParser haskellDef
parens      = P.parens lexer
symbol      = P.symbol lexer
comma       = P.comma lexer
commaSep    = P.commaSep lexer
squares     = P.squares lexer

defaultConfig :: PlotConfig
defaultConfig = PlotConfig
    { range = (0, 10)
    , style = "---"
    }

listOfStyle :: [String]
listOfStyle = ["---", "***"]

parseStyle :: Parser String
parseStyle = foldl1 (<|>) $ fmap string listOfStyle

digits :: Parser Integer
digits = fmap read (many1 digit)

parsePlotExpr :: Parser PlotExpr
parsePlotExpr = M.build

parsePlotSL :: Parser PlotSL
parsePlotSL = (try parsePSeq <|> try parsePRange <|> parsePCom)

parsePlotConfigRange ::Parser (PlotConfig -> PlotConfig)
parsePlotConfigRange = parens $ do
    [lowerBound, upperBound] <- sepBy1 digits $ try comma
    return $ \config -> config { range = (lowerBound, upperBound) }

parsePlotConfigStyle :: Parser (PlotConfig -> PlotConfig)
parsePlotConfigStyle = do
    string "style"
    char '='
    optional $ char '\"'
    sty <- parseStyle
    optional $ char '\"'
    return $ \config -> config { style = sty }

parsePlotConfig ::Parser (PlotConfig -> PlotConfig)
parsePlotConfig = parsePlotConfigRange <|> parsePlotConfigStyle

parsePlotRange :: Parser PlotRange
parsePlotRange = do
    string "for"
    expr <- M.variable
    char '='
    lowerBound <- digits
    char ':'
    upperBound <- digits
    return $ PFor lowerBound upperBound expr

parsePRange :: Parser PlotSL
parsePRange = do
    plotRange <- parsePlotRange
    plotSL <- parsePlotSL
    string "end"
    return $ PRange plotRange plotSL

parseSinglePlot :: Parser PlotSL
parseSinglePlot = (try parsePRange) <|> parsePCom

parsePSeq :: Parser PlotSL
parsePSeq = do
    first <- parseSinglePlot
    second <- try parsePSeq <|> parseSinglePlot
    return $ PSeq first second

parsePCom :: Parser PlotSL
parsePCom =
    string "plot" >>
    parens (do
        expr <- parsePlotExpr
        optional comma
        configs <- sepBy parsePlotConfig $ try comma
        let config = foldl (.) id configs defaultConfig
        return $ PCom expr config
        )

plotSLparse :: T.Text -> Either ParseError PlotSL
plotSLparse = parse parsePlotSL "" . filter (not . isSpace) . T.unpack
