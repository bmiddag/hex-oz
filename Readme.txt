/***************************************************\
|          Programming languages: Project           |
|        The Game of Hex: Oz implementation         |
|                   Bart Middag                     |
| Master of Science in Computer Science Engineering |
|             Academic year: 2014-2015              |
|                 Ghent University                  |
\___________________________________________________/

! IMPORTANT !
=============

In this zip file, I included two versions of the code, namely my standalone code and the code that follows the communiction scheme
decided upon by the group. The group's communication scheme is rather unorthodox, uses multiple threads and requires an (unsorted!) list of all
past moves to be sent every turn. In contrast to this, my own communication scheme (found in the Standalone/ folder) only sends the latest move
every turn and uses only one thread per player, which makes much better use of the message-passing concurrency model.
Please take this into consideration.


1. Usage Instructions (Standalone)
==================================

Use the command 'ozengine Main.ozf' to run the game, and make sure all compiled modules are in the same directory.

You can also use this Hex implementation with your own code. An example implementation is provided at the bottom of this document.
Extended specifications can be found below.

In order to integrate this code, you'll need to import the module Player.ozf and then use it as follows:

    {Player.newPlayer 'V' ?CurrentPort OpponentPort 'Bart' ?FinalBoard}
	
Here is what everything stands for:
  * 'V':         Stands for 'Vertical' (the red player). Since red starts first, this will immediately send a move message.
                 You can also use 'H', which is the 'Horizontal' (blue) player.

  * CurrentPort: Will be bound to the port that this thread listens to for messages.

  * 'Bart':      The opponent type which determines how the messages are translated.
                 You can use 'Rian' to use it with Rian's code or 'Robbert' if you also want to go through the hell
                 of implementing the group's weird communication scheme.

  * FinalBoard:  Will be bound to a list of lists representing the end result.
                 The board will be the same for both players in the end, so for one of the players, you should ignore this with '_' as in the example.

The communication is rather simple: there are two kinds of message that you need to send when using opponent type 'Bart':

  * (I#J):       This tuple signifies a move to row I and column J.
  * swap:        This lets the other player know that you swapped after the first move.
	
Do not send any other message. Internally, the threads also send a 'nil' message to themselves when the game has been decided,
but they do not send this between threads, so do not send additional 'nil' messages.

Also, feel free to make use of some of the helper procedures in my other modules if you want to.
Examples of helpful procedures are {Board.printBoard B}, {Board.get B I J} and {Logic.hasWon B 'V'}.


3. Usage Instructions (Group Communication Scheme)
==================================================

If you REALLY want to use my code with the group's code, then you're likely a member of the group.
In this case you'll need to do the following:
1. Copy the contents of "Group Communication Scheme/" to the directory where your App.ozf or Opponent.ozf is.
2. When prompted:
2a. (If my code will be the host player) replace your App.ozf with mine, but keep your Opponent.ozf
2b. (If my code will be the opponent player) replace your Opponent.ozf with mine, but keep your App.ozf.

You can also simply look inside the Tournament folder in the zip file I uploaded in the group space on Minerva. :)


4. Example implementation (Standalone)
======================================

Included below is the source code of Main.ozf which starts the game when run with 'ozengine Main.ozf'.

=======================================================================================

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
