module Main where

import PromJS
import StreamWeb (startServer, sendWithStatus, corsHeaders)
import qualified Streamly.Prelude as SP
import qualified Streamly as S
import StreamWeb.Types

main :: IO ()
main = SP.drain $ S.parallely $ SP.mapM (\(so, req) -> getQ >>= flip (sendWithStatus so 200) corsHeaders) $ startServer 8081
