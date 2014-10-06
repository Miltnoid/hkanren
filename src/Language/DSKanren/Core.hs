{-# LANGUAGE RecordWildCards #-}
module Language.DSKanren.Core ( Term(..)
                              , Var
                              , (===)
                              , fresh
                              , conj
                              , disconj
                              , Predicate
                              , suco
                              , zero
                              , failure
                              , run ) where
import           Control.Monad.Logic
import           Data.String
import qualified Data.Map            as M

type Var = Integer
data Term = Var Var
          | Atom String
          | Integer Integer
          | Pair Term Term
          deriving Show
instance IsString Term where
  fromString = Atom

type Sol = M.Map Var Term

-- | Substitute all bound variables in a term giving the canonical
-- term in an environment. Sometimes the solution isn't canonical,
-- so some ugly recursion happens. Happily we don't have to prove
-- normalization.
canonize :: Sol -> Term -> Term
canonize sol t = case t of
  Atom a -> Atom a
  Integer i -> Integer i
  Pair l r -> canonize sol l `Pair` canonize sol r
  Var i -> maybe (Var i) (canonize sol) $ M.lookup i sol

-- | Extend an environment with a given term. Note that
-- that we don't even bother to canonize things here, that
-- can wait until we extact a solution.
extend :: Var -> Term -> Sol -> Sol
extend = M.insert

-- | Unification cannot need not backtrack so this will either
-- universally succeed or failure.
unify :: Term -> Term -> Sol -> Maybe Sol
unify l r sol= case (l, r) of
  (Atom a, Atom a') | a == a' -> Just sol
  (Integer i, Integer j) | i == j -> Just sol
  (Pair h t, Pair h' t') -> unify h h' sol >>= unify t t'
  (Var i, t) -> Just (extend i t sol)
  (t, Var i) -> Just (extend i t sol)
  _ -> Nothing

data State = State { sol  :: Sol
                   , var  :: Integer }
type Predicate = State -> Logic State

-- | Equating two terms will attempt to unify them and backtrack if
-- this is impossible.
(===) :: Term -> Term -> Predicate
(===) l r s@State {..} =
  case unify (canonize sol l) (canonize sol r) sol of
   Just sol' -> return s{sol = sol'}
   Nothing   -> mzero

-- | Generate a fresh (not rigid) term to use for our program.
fresh :: (Term -> Predicate) -> Predicate
fresh withTerm (State sol i) = withTerm (Var i) (State sol $ i + 1)

-- | Successor, only unify l and r if l is r + 1
suco :: Term -> Term -> Predicate
suco l r s@State{..} = case (canonize sol l, canonize sol r) of
  (Integer i, _) -> (===) r (Integer $ i + 1) s
  (_, Integer i) -> (===) l (Integer $ i - 1) s
  _ -> mzero

zero :: Term -> Predicate
zero = (=== Integer 0)

-- | Conjunction
conj :: Predicate -> Predicate -> Predicate
conj p1 p2 s = p1 s >>- p2

-- | Disjunction
disconj :: Predicate -> Predicate -> Predicate
disconj p1 p2 s = p1 s `interleave` p2 s

-- | The Eeyore of predicates, always fails.
failure :: Predicate
failure = const mzero

-- | Run a program and find all solutions for the parametrized term.
run :: (Term -> Predicate) -> [Term]
run mkProg = map answer (observeAll prog)
  where prog = mkProg (Var 0) $ State M.empty 1
        answer State{..} = canonize sol (Var 0)
