% The Game of Hex in Oz
% by Bart Middag
%
% File: Player.oz
% Description: Player module - contains all of the methods a player thread needs to configure itself and react to opposing player's moves
%
% Possible messages:
% * (I#J): Tells thread that thread at OpponentPort has made a move to position (I#J)
% * nil: Ends game

functor
import
	Board
	Logic
	Strategy
	System
export
	%newPlayer:NewPlayer		% Debug (so I can test with 2 players with different strategies)
	newPlayer:NewPlayerDefault	% Release (so people don't create player with random strategy for tournament)
define
	% Create and return player with default strategy
	proc {NewPlayerDefault X ?PlayerPort OpponentPort OpponentType ?B}
		{NewPlayer X Strategy.bridge PlayerPort OpponentPort OpponentType B}
	end
	
	% Create and return player with specific strategy
	proc {NewPlayer X Strategy ?PlayerPort OpponentPort OpponentType ?B} Messages StartB PlayerMove MoveList in
		thread
			% Vertical (red) player gets the first move!
			if (X == 'V') then
				StartB = {SendMove {Board.createBoard} X Strategy nil OpponentPort OpponentType PlayerMove}
				MoveList = PlayerMove|nil
			else
				StartB = {Board.createBoard}
				MoveList = nil
			end
			% Start playing
			B = {Play StartB X Strategy Messages PlayerPort OpponentPort OpponentType 0 MoveList}
		end
		PlayerPort = {Port.new Messages}
	end
	
	% Based on FoldL, this method recursively processes all messages
	fun {Play B X Strategy Messages PlayerPort OpponentPort OpponentType Turn MoveList} NewB TempB OpponentX Translated TempMoveList NewMoveList PlayerMove in
		case Messages
		of nil|_ then
			B
		[] Message|NextMessages then
			Translated = {Translate B X OpponentType 'Bart' Message}
			case Translated
			of nil then
				B
			[] (I#J) then % Used for the usual (row, column) pairs
				% {System.showInfo "Got move: "#I#"."#J}
				% Get other player
				if X == 'H' then OpponentX = 'V' else OpponentX = 'H' end
				TempMoveList = {Translate B OpponentX 'Bart' OpponentType (I#J)}|MoveList
				TempB = {Board.move B OpponentX I J}
				if {DecideSwap X (I#J) Turn} then
					{System.showInfo "Player "#X#" has swapped and is now "#OpponentX#"!"}
					{SendSwap TempB OpponentX OpponentPort OpponentType}
					{Play TempB OpponentX Strategy NextMessages PlayerPort OpponentPort OpponentType Turn+1 TempMoveList}
				else
					if (Turn >= 9 andthen {CheckWon TempB OpponentX PlayerPort}) then
						if OpponentType == 'Robbert' then
							{Port.send OpponentPort lost}
						end
						NewB = TempB
						NewMoveList = TempMoveList
					else
						NewB = {SendMove TempB X Strategy (I#J) OpponentPort OpponentType PlayerMove}
						NewMoveList = PlayerMove|TempMoveList
						if (Turn >= 9) then
							if {CheckWon NewB X PlayerPort} andthen OpponentType == 'Robbert' then
								{Port.send OpponentPort won}
							end
						end
					end
					{Play NewB X Strategy NextMessages PlayerPort OpponentPort OpponentType Turn+1 NewMoveList} % React to next message
				end
			[] swap then
				% Get other player, switch with him and make a move
				if X == 'H' then OpponentX = 'V' else OpponentX = 'H' end
				{System.showInfo "Opponent "#OpponentX#" has swapped and is now "#X#"!"}
				NewB = {SendMove B OpponentX Strategy swap OpponentPort OpponentType PlayerMove}
				{Play NewB OpponentX Strategy NextMessages PlayerPort OpponentPort OpponentType Turn+1 PlayerMove|MoveList} % React to next message
			[] getPos(I#J ?Value) then
				local TempValue in
					TempValue = {Board.get B I J}
					Value = {Translate B X 'Bart' 'Robbert' TempValue}
				end
				{Play B X Strategy NextMessages PlayerPort OpponentPort OpponentType Turn MoveList}
			[] getMoves(?List) then
				List = MoveList
				{Play B X Strategy NextMessages PlayerPort OpponentPort OpponentType Turn MoveList}
			else
				B
			end
		else
			B
		end
	end
	
	fun {Translate B X FromType ToType Message} Types FromMessages ToMessages FromIndex ToIndex in		
		case Message
		of nil then
			nil
		[] getPos(I#J ?Value) then
			getPos(I-1#J-1 ?Value)
		[] getMoves(?List) then
			getMoves(?List)
		[] (I#J#C) then
			Types = ['Bart' 'Rian' 'Robbert']
			FromMessages = [(I#J) (J+1#I+1) (I+1#J+1#C)]	% Sent from Bart (result = conversion to other type)
			ToMessages = [(I#J) (J-1#I-1) (I-1#J-1)]		% Sent to Bart (result = conversion to my message type)
			FromIndex = {GetIndex Types FromType}
			ToIndex = {GetIndex Types ToType}
			if(FromType == 'Bart') then
				{List.nth FromMessages ToIndex}
			else
				{List.nth ToMessages FromIndex}
			end
		[] (I#J) then
			Types = ['Bart' 'Rian' 'Robbert']
			if(FromType == 'Rian' andthen {Board.get B J-1 I-1} == X) then
				swap
			else
				FromMessages = [(I#J) (J+1#I+1) (I+1#J+1#{Translate B X FromType ToType X})]	% Sent from Bart (result = conversion to other type)
				ToMessages = [(I#J) (J-1#I-1) (I-1#J-1)]										% Sent to Bart (result = conversion to my message type)
				FromIndex = {GetIndex Types FromType}
				ToIndex = {GetIndex Types ToType}
				if(FromType == 'Bart') then
					{List.nth FromMessages ToIndex}
				else
					{List.nth ToMessages FromIndex}
				end
			end
		[] swap then
			if(ToType == 'Rian') then
				local PieceList in
					PieceList = {Board.getAll B X}
					case PieceList
					of nil then
						nil
					[] (I#J)|_ then
						(J+1#I+1)
					end
				end
			else
				swap
			end
		[] Color then
			FromMessages = ['V' 'H' '.' r b]
			ToMessages = [r b nil 'V' 'H']
			{List.nth ToMessages {GetIndex FromMessages Color}}
		else
			nil
		end
	end
	
	fun {GetIndex List Element}
		case List
		of nil then
			1
		[] X|Xs then
			if(X == Element) then
				1
			else
				{GetIndex Xs Element}+1
			end
		end
	end
	
	fun {DecideSwap X OpponentMove Turn}
		if Turn == 0 andthen X == 'H' then
			{Strategy.decideSwap OpponentMove}
		else
			false
		end
	end
	
	% Execute move according to strategy, send it to other player and return the new board
	fun {SendMove B X Strategy OpponentMove OpponentPort OpponentType ?Move} NewB in
		local (I#J) = {Strategy B X OpponentMove} in
			NewB = {Board.move B X I J}
			Move = {Translate NewB X 'Bart' OpponentType (I#J)}
			{Port.send OpponentPort Move}
		end
		NewB
	end
	
	% Execute swap move
	proc {SendSwap B X OpponentPort OpponentType}
		{Port.send OpponentPort {Translate B X 'Bart' OpponentType swap}}
	end
	
	% Check if player X won, and if so, send stop message to current player
	fun {CheckWon B X PlayerPort}
		if {Logic.hasWon B X} then
			{Port.send PlayerPort nil} % We tell ourselves someone has won, the other thread can do so for itself too!
			true
		else
			false
		end
	end
end