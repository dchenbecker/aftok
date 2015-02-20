module Quixotic.Snaplet.WorkLog where

import ClassyPrelude 

import Control.Lens
import Control.Monad.State
import qualified Data.Aeson as A
import qualified Data.Map as M

import Quixotic
import Quixotic.Database
import Quixotic.Json
import Quixotic.TimeLog

import Quixotic.Snaplet
import Quixotic.Snaplet.Auth

import Snap.Core
import Snap.Snaplet
import Snap.Snaplet.PostgresqlSimple

logWorkHandler :: EventType -> Handler App App ()
logWorkHandler evType = do 
  QDB{..} <- view qdb <$> with qm get
  uid <- requireUserId
  pid <- requireProjectAccess uid
  addrBytes <- getParam "btcAddr"
  requestBody <- readRequestBody 4096
  timestamp <- liftIO getCurrentTime
  let em = maybe A.Null id $ A.decode requestBody
      workEvent = WorkEvent evType timestamp em
      storeEv addr = runReaderT . recordEvent pid uid $ LogEntry addr workEvent
  case fmap decodeUtf8 addrBytes >>= parseBtcAddr of
    Nothing -> snapError 400 $ "Unable to parse bitcoin address from " <> (tshow addrBytes)
    Just addr -> liftPG $ storeEv addr

loggedIntervalsHandler :: Handler App App ()
loggedIntervalsHandler = do
  QDB{..} <- view qdb <$> with qm get
  uid <- requireUserId 
  pid <- requireProjectAccess uid
  widx <- liftPG . runReaderT $ readWorkIndex pid
  modifyResponse $ addHeader "content-type" "application/json"
  writeLBS . A.encode . fmap (fmap IntervalJ) $ M.mapKeysWith (++) (^._BtcAddr) widx

payoutsHandler :: Handler App App ()
payoutsHandler = do 
  (QModules QDB{..} df) <- with qm get
  uid <- requireUserId 
  pid <- requireProjectAccess uid
  widx <- liftPG . runReaderT $ readWorkIndex pid
  ptime <- liftIO $ getCurrentTime
  modifyResponse $ addHeader "content-type" "application/json"
  writeLBS . A.encode . PayoutsJ $ payouts df ptime widx

