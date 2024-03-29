module Ex03 where

import Test.QuickCheck
import Data.List(sort, nub)

data BinaryTree = Branch Integer BinaryTree BinaryTree
                | Leaf
                deriving (Show, Ord, Eq)

isBST :: BinaryTree -> Bool
isBST Leaf = True
isBST (Branch v l r) 
  = allTree (< v) l  && 
    allTree (>= v) r &&
    isBST l          && 
    isBST r
  where allTree :: (Integer -> Bool) -> BinaryTree -> Bool
        allTree f (Branch v l r) = f v && allTree f l && allTree f r
        allTree f (Leaf) = True
        
--Add an integer to a BinaryTree, preserving BST property.
insert :: Integer -> BinaryTree -> BinaryTree
insert i Leaf = Branch i Leaf Leaf
insert i (Branch v l r) 
  | i < v     = Branch v (insert i l) r
  | otherwise = Branch v l (insert i r)

--Remove all instances of an integer in a binary tree, preserving BST property
deleteAll :: Integer -> BinaryTree -> BinaryTree
deleteAll i Leaf = Leaf
deleteAll i (Branch j Leaf r) | i == j = deleteAll i r
deleteAll i (Branch j l Leaf) | i == j = deleteAll i l
deleteAll i (Branch j l r) | i == j = let (x, l') = deleteRightmost l
                                       in Branch x l' (deleteAll i r)
                           | i <  j = Branch j (deleteAll i l) r
                           | i >  j = Branch j l (deleteAll i r)
  where deleteRightmost :: BinaryTree -> (Integer, BinaryTree)
        deleteRightmost (Branch i l Leaf) = (i, l)
        deleteRightmost (Branch i l r)    = let (x, r') = deleteRightmost r
                                             in (x, Branch i l r')

searchTrees :: Gen BinaryTree
searchTrees = sized searchTrees'
  where 
   searchTrees' 0 = return Leaf
   searchTrees' n = do 
      v <- (arbitrary :: Gen Integer)
      fmap (insert v) (searchTrees' $ n - 1)

----------------------

-- where i is in the binary tree
mysteryPred :: Integer -> BinaryTree -> Bool
mysteryPred i t = case t of 
  Leaf -> False
  Branch val ltree rtree
    | i == val -> True
    | i < val -> mysteryPred i ltree
    | i > val -> mysteryPred i rtree


prop_mysteryPred_1 integer = 
  forAll searchTrees $ \tree -> mysteryPred integer (insert integer tree)

prop_mysteryPred_2 integer = 
  forAll searchTrees $ \tree -> not (mysteryPred integer (deleteAll integer tree))

----------------------

-- change a binary tree to a sorted list
mysterious :: BinaryTree -> [Integer]
mysterious t = mysterious_helper t []
  where 
    mysterious_helper :: BinaryTree -> [Integer] -> [Integer]
    mysterious_helper t added_i = case t of 
      Leaf -> added_i
      Branch val ltree rtree -> mysterious_helper ltree (val : (mysterious_helper rtree added_i))


isSorted :: [Integer] -> Bool
isSorted (x:y:rest) = x <= y && isSorted (y:rest)
isSorted _ = True


prop_mysterious_1 integer = forAll searchTrees $ \tree -> 
  mysteryPred integer tree == (integer `elem` mysterious tree)

prop_mysterious_2 = forAll searchTrees $ isSorted . mysterious
----------------------


-- Note `nub` is a function that removes duplicates from a sorted list
sortedListsWithoutDuplicates :: Gen [Integer]
sortedListsWithoutDuplicates = fmap (nub . sort) arbitrary


balance :: BinaryTree -> BinaryTree
balance t = case t of 
  Leaf -> t
  Branch _ ltree rtree
    | abs (height ltree - height rtree) <= 1 -> t
    | height ltree - height rtree > 1 -> rotateR t
    | height rtree - height ltree > 1 -> rotateL t
  where 
    height :: BinaryTree -> Int
    height Leaf = 0
    height (Branch v l r) = 1 + max (height l) (height r)
    rotateR :: BinaryTree -> BinaryTree
    rotateR (Branch v (Branch lv llt lrt) rtree) = Branch lv (llt) (Branch v (lrt) (rtree))
    rotateL :: BinaryTree -> BinaryTree
    rotateL (Branch v ltree (Branch rv rlt rrt)) = Branch rv (Branch v (ltree) (rlt)) (rrt)


-- helper function
balanceInsert :: Integer -> BinaryTree -> BinaryTree
balanceInsert i Leaf = Branch i Leaf Leaf
balanceInsert i (Branch v l r) 
  | i < v     = balance $ Branch v (balanceInsert i l) r
  | otherwise = balance $ Branch v l (balanceInsert i r)


astonishing :: [Integer] -> BinaryTree
astonishing xs = astonishing_helper xs Leaf
  where 
    astonishing_helper :: [Integer] -> BinaryTree -> BinaryTree
    astonishing_helper integers t = case integers of
      [] -> balance t
      (x:xs) -> astonishing_helper xs (balanceInsert x t)


prop_astonishing_1 
  = forAll sortedListsWithoutDuplicates $ isBST . astonishing

prop_astonishing_2 
  = forAll sortedListsWithoutDuplicates $ isBalanced . astonishing

prop_astonishing_3 
  = forAll sortedListsWithoutDuplicates $ \ integers -> 
    mysterious (astonishing integers) == integers


isBalanced :: BinaryTree -> Bool
isBalanced Leaf = True
isBalanced (Branch v l r) = and [ abs (height l - height r) <= 1 
                                , isBalanced l 
                                , isBalanced r
                                ]
  where height Leaf = 0
        height (Branch v l r) = 1 + max (height l) (height r)

