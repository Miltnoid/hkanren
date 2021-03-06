-- | /What's in hkanren?/
--
-- ['disconj']
--   Try the left and the right and gather solutions that satisfy
--   either one.
-- ['fresh']
--   Create a fresh logical variable
-- ['===']
--   Equate two terms. This will backtrack if we can't unify
--   them in this branch.
-- ['run']
--   Actually run a logical computation and return results and
--   the constraints on them.
--
-- In addition to these core combinators, we also export a few
-- supplimentary tools.
--
-- ['=/=']
--   The opposite of '===', ensure that the left and right
--   never unify.
--
-- /The Classic Example/
--
-- We can define the classic @appendo@ relationship by encoding
-- lists in the Lisp "bunch-o-pairs" method.
--
-- > appendo :: Term -> Term -> Term -> Predicate
-- > appendo l r o =
-- >   conde [ program [l === "nil",  o === r]
-- >         , manyFresh $ \h t o ->
-- >             program [ Pair h t === l
-- >                     , appendo t r o
-- >                     , Pair h o === o ]]
--
-- Once we have a relationship, we can run it backwards and forwards
-- as we can with most logic programs.
--
-- >>> let l = list ["foo", "bar"]
--
-- >>> map fst . runN 1 $ \t -> appendo t l l
-- [nil]
-- >>> map fst . runN 1 $ \t -> appendo l t l
-- [nil]
-- >>> map fst . runN 1 $ \t -> appendo l l t
-- [(foo, (bar, (foo, (bar, nil))))]
--
-- The toplevel module exports the core language, in
-- 'Language.HKanren.Core' and some simple combinators from
-- 'Language.HKanren.Sugar'.

module Language.HKanren
  ( module Language.HKanren.Core
  , mkLVar
  , Subst
  , TypeI(..)
  , If
  , Equal
  , typeOf
  )
where

import Language.HKanren.Core
import Language.HKanren.Subst
