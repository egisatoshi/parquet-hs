{-# LANGUAGE TemplateHaskell #-}

-- |
module Parquet.ParquetObject
  ( -- * Type definitions
    ParquetValue (..),
    ParquetObject (..),
    ParquetList (..),
  )
where

------------------------------------------------------------------------------

import Control.Lens (makeLenses, makePrisms)
import qualified Data.Aeson as JSON
import qualified Data.Aeson.KeyMap as JSON
import Data.Binary (Binary (get, put))
import Parquet.Prelude hiding (get, put)

------------------------------------------------------------------------------
newtype ParquetObject = MkParquetObject (Map Text ParquetValue)
  deriving (Eq, Show, Generic, Serialise)

instance Semigroup ParquetObject where
  MkParquetObject hm1 <> MkParquetObject hm2 = MkParquetObject (hm1 <> hm2)

instance Monoid ParquetObject where
  mempty = MkParquetObject mempty

instance Binary ParquetObject where
  put (MkParquetObject hm) = put (toList hm)
  get = MkParquetObject . fromList <$> get

instance ToJSON ParquetObject where
  toJSON (MkParquetObject obj) = toJSON obj

------------------------------------------------------------------------------
newtype ParquetList = MkParquetList [ParquetValue]
  deriving (Eq, Show, Generic, Serialise)

instance Semigroup ParquetList where
  MkParquetList l1 <> MkParquetList l2 = MkParquetList (l1 <> l2)

instance Monoid ParquetList where
  mempty = MkParquetList mempty

instance Binary ParquetList where
  put (MkParquetList l) = put l
  get = MkParquetList <$> get

instance ToJSON ParquetList where
  toJSON (MkParquetList l) = toJSON l

------------------------------------------------------------------------------
data ParquetValue
  = ParquetObject !ParquetObject
  | ParquetList !ParquetList
  | ParquetInt !Int64
  | ParquetString !ByteString
  | ParquetBool !Bool
  | ParquetNull
  | EmptyValue
  deriving (Eq, Show, Generic, Binary, Serialise)

instance FromJSON ParquetValue where
  parseJSON = \case
    JSON.Object obj -> do
      ParquetObject . MkParquetObject . JSON.toMapText <$> traverse parseJSON obj
    JSON.Array vec -> do
      ParquetList . MkParquetList . toList <$> traverse parseJSON vec
    JSON.Number sci ->
      pure $ ParquetInt $ fromInteger $ numerator $ toRational sci
    JSON.String s ->
      pure $ ParquetString $ encodeUtf8 s
    JSON.Bool b -> pure $ ParquetBool b
    JSON.Null -> pure ParquetNull

instance ToJSON ParquetValue where
  toJSON = \case
    ParquetObject obj -> toJSON obj
    ParquetList l -> toJSON l
    ParquetInt i64 -> JSON.Number (fromIntegral i64)
    ParquetString bs -> case decodeUtf8' bs of
      Right t -> JSON.String t
      Left _ -> JSON.String "<non-utf8-string>"
    ParquetBool b -> JSON.Bool b
    ParquetNull -> JSON.Null
    EmptyValue -> JSON.Null

------------------------------------------------------------------------------
makeLenses ''ParquetObject
makeLenses ''ParquetValue

makePrisms ''ParquetObject
makePrisms ''ParquetValue
