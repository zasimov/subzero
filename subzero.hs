{-# LANGUAGE OverloadedStrings #-}
module Main where

import Data.Time

import Data.ByteString.Char8

import Network hiding (accept)
import Network.BufferType
import Network.HTTP
import Network.Socket
import Network.Socket.ByteString (sendAll)
import Network.TCP (HandleStream, socketConnection, close)
import Network.Stream

import System.Environment
import System.Exit

import Control.Concurrent

import Control.Monad.State
import Data.Text (strip)

import Data.Char


data Answer = Answer String

instance Show Answer where
    show (Answer s) = s


data TemporaryBuffer = TemporaryBuffer {
    tbContents :: String,
    tbAnswers :: [Answer]
    } deriving Show


trim xs = dropSpaceTail "" $ Prelude.dropWhile isSpace xs


dropSpaceTail maybeStuff "" = ""
dropSpaceTail maybeStuff (x:xs)
        | isSpace x = dropSpaceTail (x:maybeStuff) xs
        | Prelude.null maybeStuff = x : dropSpaceTail "" xs
        | otherwise       = Prelude.reverse maybeStuff ++ x : dropSpaceTail "" xs


skipEmptyLines [] = []
skipEmptyLines l@(x:xs)
   | trim x == "" = skipEmptyLines xs
   | otherwise = l


readScrollT :: FilePath -> StateT TemporaryBuffer IO [Answer]
readScrollT filename = do
    ls <- liftIO $ fmap Prelude.lines (Prelude.readFile filename)
    load (skipEmptyLines ls)

    where eol = "\n"

          load [] = saveAnswer >> get >>= return . Prelude.reverse . tbAnswers
          load (x:xs) = do
              case x of
                  "$$" -> saveAnswer >> load (skipEmptyLines xs)
                  s -> saveLine s >> load xs

          saveLine s = do
              state <- get
              {- FIXME: In answer we have additional \n symbol -}
              put (state { tbContents = (tbContents state ++ s ++ eol) })

          saveAnswer = do
              state <- get
              let buffer = tbContents state
              let answers = tbAnswers state
              if Prelude.length buffer /= 0
                   then put (TemporaryBuffer "" (Answer buffer : answers))
                   else return ()


readScroll filename = runStateT (readScrollT filename) (TemporaryBuffer "" []) >>= return . fst


logo port = do
    Prelude.putStrLn ""
    Prelude.putStrLn "                          +-------------+"
    Prelude.putStrLn "                          |   0     0   |"
    Prelude.putStrLn "                          |      +      |"
    Prelude.putStrLn "                          |    \\___/    |"
    Prelude.putStrLn "                          +-------------+"
    Prelude.putStrLn "                        TheServer is running...  "
    Prelude.putStrLn $ "                           Port is " ++ show port
    Prelude.putStrLn ""


defaultPort = 5002


main = do
    args <- getArgs
    let (fname, port) = case args of
                           [fname] -> (fname, defaultPort)
                           [fname, port] -> (fname, read port)
                           _ -> error "usage: subzero filename [port]"
    answers <- readScroll fname
    logo port
    withSocketsDo $ do
      sock <- listenOn $ PortNumber (fromIntegral port)
      loop (Prelude.map show answers) (Prelude.map show answers) sock


connection :: BufferType ty => Socket -> IO (HandleStream ty)
connection sock = do
    port <- Network.Socket.socketPort sock
    socketConnection "" (fromIntegral port) sock


safetail [] = []
safetail xs = Prelude.tail xs


loop origin_answers answers sock = do
   (conn, _) <- accept sock
   forkIO $ body answers conn
   let real_answers = case safetail answers of
                          [] -> origin_answers
                          answers -> answers
   loop origin_answers real_answers sock
  where
   body answers c = do conn <- connection c
                       request <- receiveHTTP conn :: IO (Result (Request ByteString))
                       case request of
                           Right request -> let answer = case answers of
                                                             (x:xs) -> x
                                                             _ -> defaultAnswer
                                            in do now <- getCurrentTime
                                                  Prelude.putStrLn $ "*** " ++ (show now) ++ " Request"
                                                  Prelude.putStrLn (show request)
                                                  Prelude.putStrLn (unpack $ rqBody request)
                                                  Prelude.putStrLn "*** Answer"
                                                  Prelude.putStrLn answer
                                                  sendAll c (pack answer) >> return ()
                           Left e -> print (show e) >> return ()
                       Network.TCP.close conn


defaultAnswer = "HTTP/1.0 200 OK\nContent-Type: text/plain\n\nEnd of answers."
