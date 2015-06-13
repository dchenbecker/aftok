{-# LANGUAGE NoImplicitPrelude, TemplateHaskell, DeriveDataTypeable #-}

module Aftok where

import ClassyPrelude

import Control.Lens(makePrisms, makeLenses)
import Data.Aeson
import Data.Aeson.Types
import Data.Data
import Data.UUID
import Network.Bitcoin (BTC)

newtype BtcAddr = BtcAddr Text deriving (Show, Eq, Ord)
makePrisms ''BtcAddr

parseBtcAddr :: Text -> Maybe BtcAddr
parseBtcAddr = Just . BtcAddr -- FIXME: perform validation

newtype Months = Months Integer 
  deriving (Eq, Show, Data, Typeable)

data DepreciationFunction = LinearDepreciation Months Months
  deriving (Eq, Show, Data, Typeable)

newtype UserId = UserId UUID deriving (Show, Eq)
makePrisms ''UserId

newtype UserName = UserName Text deriving (Show, Eq)
makePrisms ''UserName

data User = User
  { _username :: UserName
  , _userAddress :: BtcAddr
  , _userEmail :: Text
  }
makeLenses ''User

newtype ProjectId = ProjectId UUID deriving (Show, Eq)
makePrisms ''ProjectId

data Project = Project
  { _projectName :: Text
  , _inceptionDate :: UTCTime
  , _initiator :: UserId
  , _depf :: DepreciationFunction
  }
makeLenses ''Project

data Invitation = Invitation
  { _invitationProject :: ProjectId
  , _currentMember :: UserId
  , _sentAt :: UTCTime
  , _expiresAt :: UTCTime
  , _toAddr :: BtcAddr
  , _amount :: BTC
  }
makeLenses ''Invitation

newtype InvitationId = InvitationId UUID deriving (Show, Eq)

data Acceptance = Acceptance
  { _acceptedInvitation :: InvitationId
  , _blockHeight :: Integer
  , _observedAt :: UTCTime
  }
makeLenses ''Acceptance

--                        | others tbd

instance ToJSON DepreciationFunction where
  toJSON (LinearDepreciation (Months up) (Months dp)) =
    object [ "type" .= ("LinearDepreciation" :: Text)
           , "arguments" .= (
             object [ "undep" .= up
                    , "dep" .= dp
                    ]
           )]

instance FromJSON DepreciationFunction where
  parseJSON (Object v) = do
    t <- v .: "text" :: Parser Text
    args <- v .: "arguments"
    case unpack t of
      "LinearDepreciation" -> 
        let undep = Months <$> (args .: "undep")
            dep   = Months <$> (args .: "dep")
        in  LinearDepreciation <$> undep <*> dep
      x -> fail $ "No depreciation function recognized for type " <> x

  parseJSON _ = mzero

