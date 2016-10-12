% The Game of Hex in Oz
% by Bart Middag
%
% File: Logic.oz
% Description: Logic module - contains the game logic, used for rules or checking whether the game is finished

% How to check if a player has won: check all paths as follows:
% Visit(Node x, List[Node] FollowedPath, List[Node] CheckedPlaces); Returns when you win, e.g. a connection is found that goes until the other end,
% or when you don't win, e.g. no path can be found and all possible starting points have been checked
% You shouldn't visit a node if it's already in CheckedPlaces.

% Possible paths y from node x (2D Array view):
% - y y
% y x y
% y y -
% Possible paths y from node x (Hex board view):
% - y y
%  y x y
%   y y -

% 1. Visit left, except if (X=H and J=1) or J=0
% 2. Visit down left, except if (X=H and J=1) or J=0 or I=10
% 3. Visit down, except if (X=H and J=0) or I=10
% 4. Visit up, except if (X=V and I=1) or I=0
% 5. Visit up right, except if (X=V and I=1) or I=0 or J=10
% 6. Visit right, except if (X=V and I=0) or J=10

functor
import
	Board
export
	hasWon:HasWon
define
	% Check if player X has won. Functions as an entry point for the Visit procedure.
	fun {HasWon B X}
		{Visit B X 0 0 nil nil}
	end
	
	% Recursively checks all possible paths to see if player X has won
	fun {Visit B X I J FollowedPath CheckedPlaces} Won CheckNextPlace in
		proc {CheckNextPlace NewI NewJ}
			if {Value.isFree Won} andthen {Board.isValidPosition NewI NewJ} andthen ({Not {List.member (NewI#NewJ) CheckedPlaces}})
			andthen ({Not (X == 'H') andthen (NewJ == 0) andthen ((NewI > I) orelse (NewJ < J))})
			andthen ({Not (X == 'V') andthen (NewI == 0) andthen ((NewI < I) orelse (NewJ > J))}) then
				Won = {Visit B X NewI NewJ (I#J)|FollowedPath (I#J)|CheckedPlaces}
			end
		end
	
		if ({Board.get B I J} == X) then
			{CheckNextPlace I J-1}
			{CheckNextPlace I+1 J-1}
			{CheckNextPlace I+1 J}
			{CheckNextPlace I-1 J}
			{CheckNextPlace I-1 J+1}
			{CheckNextPlace I J+1}
		end
		if {Value.isFree Won} then
			if ((J == 0) andthen (X == 'H')) orelse ((I == 0) andthen (X == 'V')) then
				if ((I == 10) andthen (X == 'H')) orelse ((J == 10) andthen (X == 'V')) then
					Won = false
				elseif ((X == 'H') andthen {Not {List.member (I+1#J) CheckedPlaces}}) then
					% Visit down, regardless of whether current node is X or not
					Won = {Visit B X I+1 J (I#J)|FollowedPath (I#J)|CheckedPlaces}
				elseif ((X == 'V') andthen {Not {List.member (I#J+1) CheckedPlaces}}) then
					% Visit right, regardless of whether current node is X or not
					Won = {Visit B X I J+1 (I#J)|FollowedPath (I#J)|CheckedPlaces}
				end
			elseif ((X == 'H' andthen J == 10) orelse (X == 'V' andthen I == 10)) andthen ({Board.get B I J} == X) then
				Won = true
			end
		end
		% Backtracking
		if {Value.isFree Won} then
			case FollowedPath
			of ((Y#Z)|Xr) then
				Won = {Visit B X Y Z Xr (I#J)|CheckedPlaces}
			else
				Won = false
			end
		end
		Won
	end
end