module Main (main) where

import qualified Parquet.Decoder.Spec
import Test.Hspec
import Parquet.Prelude

main :: IO ()
main =
  hspec Parquet.Decoder.Spec.spec
