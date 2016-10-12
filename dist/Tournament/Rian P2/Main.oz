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
	RianPlayer at 'Rian/ScorePlayer.ozf'
	RianBoardViewer at 'Rian/BoardViewer.ozf'
define
	{System.showInfo "Let the game begin!"}
	
	% Game
	local B Port1 Port2 History Viewer RianWon in
		% Start game
		{Player.newPlayer 'V' ?Port1 Port2 'Rian' ?B}
		Port2 = {RianPlayer.startPlayer 2 Port1 History RianWon}
		%{Player.newPlayer 'H' ?Port2 Port1 'Bart' _} % We don't really care about the final board for player 2 since should be the same as player 1's
		
		Viewer = {RianBoardViewer.new 20}
		{ForAll History proc {$ X} {RianBoardViewer.move Viewer X} {Delay 100} end}
		if RianWon then
			{System.showInfo 'Player 2 wins!'}
		else
			{System.showInfo 'Player 1 wins!'}
		end
		
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