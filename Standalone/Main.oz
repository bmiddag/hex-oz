% The Game of Hex in Oz
% by Bart Middag
%
% File: Main.oz
% Description: Main module - starts the game
%
% Common variable names have been shortened for shorter and better readable code:
% * X = Player direction (e.g. 'V' for vertical or 'H' for horizontal)
% * B = Board

functor
import
	Application
	System
	Board		% Used for creating or editing the board
	Logic		% Used for rules or checking whether the game is finished
	Player		% Used for playing the game and communication between player threads
define
	{System.showInfo "Let the game begin!"}
	
	% Game
	local B Port1 Port2 in
		% Start game
		{Player.newPlayer 'V' ?Port1 Port2 'Bart' ?B}
		{Player.newPlayer 'H' ?Port2 Port1 'Bart' _} % We don't really care about the final board for player 2 since should be the same as player 1's
		
		% Get results
		{Board.printBoard B}
		{System.printInfo "Results: "}
		if {Logic.hasWon B 'V'} then
			{System.showInfo "Red/Vertical (V) won the game! :)"}
		elseif {Logic.hasWon B 'H'} then
			{System.showInfo "Blue/Horizontal (H) won the game! :)"}
		else
			{System.showInfo "Nobody won. This means there is an error somewhere! :|"}
		end
		{Application.exit 0}
	end
end