{-# LANGUAGE ExistentialQuantification #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE UnicodeSyntax #-}
module PromJS where

import Data.Typeable
import qualified Data.Aeson as D
import qualified Data.ByteString.Char8 as B
import qualified Data.Text as DT
import Control.Exception
import Network.HTTP.Req
import qualified Data.HashMap.Strict as HM
import qualified Data.Vector as DV
import BasicPrelude (readMay)
import Data.HashMap.Strict as DH
import Data.ByteString.Lazy as BSL
import Data.Hashable
import Data.String
import Data.Default

data Res = Res
  {
    gateway      :: String,
    insttance     :: String,
    job          :: String,
    payment_type :: String,
    merchant_id  :: String
  } deriving (Show, Eq)

writeF :: FilePath -> ByteString  -> IO ()
writeF = BSL.writeFile

getPrometheusMetrics ∷ String → String → String → String → IO (Either HttpException (JsonResponse D.Value))
getPrometheusMetrics url userName passwd query = do
     let auth       = basicAuthUnsafe (B.pack userName) (B.pack passwd) <> (DT.pack "query" =: query)
         host       = http $ DT.pack url -- TODO: Support for both https and http
         pathPieces = Prelude.map DT.pack ["api", "v1", "query"]
         urlScheme  = Prelude.foldl (/:) host pathPieces
     try . runReq def . req GET urlScheme NoReqBody jsonResponse $ auth


extract :: Either HttpException (JsonResponse D.Value) -> DV.Vector (DT.Text, Int)
extract x = do
    let b = fmap responseBody x
    case b of
      Right r ->
        case r of
          D.Object obj -> do
             let o1 = HM.lookup "data" obj
             case o1 of
               Just (D.Object obj2) -> do
                  let li = HM.lookup "result" obj2
                  case li of
                    Just (D.Array obj3) ->
                      let pg = DV.map (processpg "metric" "gateway") obj3
                          tc = DV.mapMaybe (process "value") obj3
                          pgtc = DV.zip pg tc
                       in pgtc


getQ = do
    let queryTotalCount = "sum_over_time(failure_count{merchant_id=\"dream11\", gateway!=\"\", card_type=\"\", card_issuer_bank_name=\"\", payment_method=\"\", payment_type=\"online\",euler_txn_app_version=\"\",job=\"iris_vision_15\",instance=\"172.16.105.50:8000\",app_version=\"\"}[1m])"
        querySuccessCount = "sum_over_time(success_count{merchant_id=\"dream11\", gateway!=\"\", card_type=\"\", card_issuer_bank_name=\"\", payment_method=\"\", payment_type=\"online\",euler_txn_app_version=\"\",job=\"iris_vision_15\",instance=\"172.16.105.50:8000\",app_version=\"\"}[1m])"
    pgtc <- getPrometheusMetrics "prometheus-prod.juspay.net" "grafana-user" "u7ChqX2LVQFBCj2sfZrYLD96XajPGvff" queryTotalCount
    pgsc <- getPrometheusMetrics "prometheus-prod.juspay.net" "grafana-user" "u7ChqX2LVQFBCj2sfZrYLD96XajPGvff" querySuccessCount
    let pgtcV = extract pgtc
        pgscV = extract pgsc
        pgtcHM = DH.fromList $ DV.toList $ extract pgtc
        pgscHM = DH.fromList $ DV.toList $ extract pgsc
        pg = DV.toList $ DV.map fst pgtcV
        metricsJSON = Prelude.map (\x -> makeJSON (DT.unpack x) (pgto_ pgtcHM x) (pgto_ pgscHM x)) pg
        nodesJSON = makenodes pg
    return $ BSL.toStrict $ D.encode $ (HM.insert "name" "dream11" $ HM.insert "renderer" "global" $ HM.insert "nodes" (D.toJSON (nodesJSON :: [D.Object])) $ HM.insert "connections" (D.toJSON (metricsJSON :: [HashMap String D.Value])) HM.empty :: D.Object)

pgto_ m pg =
    case d of
        Just x -> x
    where d = HM.lookup pg m


processpg y z x = case x of
    D.Object obj -> do
        let o = HM.lookup y obj
        case o of
            Just (D.Object ob) -> do
                let val = HM.lookup z ob
                case val of
                    Just (D.String st) -> st

process y x = case x of
    D.Object obj -> do
        let o = HM.lookup y obj
        case o of
            Just (D.Array ob) -> do
                let st = DV.last ob
                case st of
                    (D.String s) -> readMay s :: Maybe Int
-- makeJSON :: String -> Int -> Int -> HashMap String D.Value
makeJSON pg tc sc = HM.insert "source" (D.toJSON ("dream11" :: String)) $ HM.insert "target" (D.toJSON pg) $ makeMetrics tc sc

makecount :: Int -> Int -> HashMap String Int
makecount tc sc = DH.fromList [("normal", sc), ("danger", tc)]

makeMetrics :: Int -> Int -> HashMap String D.Value
makeMetrics tc sc=  HM.insert "metrics" (D.toJSON (makecount tc sc )) HM.empty

makemetricsJSON pgtcHM pgscHM pg= Prelude.map (\x -> makeJSON (DT.unpack x) (pgto_ pgtcHM x) (pgto_ pgscHM x)) pg

makenodes pg = (++) [constJSON] $ Prelude.map (\x ->
                            HM.insert "class" (D.toJSON ("normal" :: String))
                            $ HM.insert "maxVolume" (D.toJSON (200 :: Int))
                            $ HM.insert "renderer" (D.toJSON ("region" :: String))
                            $ HM.insert "name" (D.toJSON x) HM.empty) pg
constJSON :: D.Object
constJSON =
            HM.insert "class" (D.String "normal")
            $ HM.insert "renderer" (D.toJSON ("global" :: String))
            $ HM.insert "name" (D.toJSON ("dream11" :: String)) HM.empty
