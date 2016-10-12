% The Game of Hex in Oz
% by Bart Middag
%
% File: Board.oz
% Description: Board module - manages the game board

functor
import
	System
export
	createBoard:CreateBoard
	printBoard:PrintBoard
	move:Move
	checkMove:CheckMove
	get:Get
	getPiece:GetPiece
	getAll:GetAll
	isValidPosition:IsValidPosition
define
	% Create new board
	fun {CreateBoard}
		{List.map {List.make 11} fun {$ I} I = {List.map {List.make 11} fun {$ J} J = '.' end} end}
	end

	% Returns a virtual string representing a list
	fun {PrintList B}
		case B
		of nil then
			""
		[] X|nil then
			X
		[] X|Xs then
			X#" "#{PrintList Xs}
		end
	end
	
	% Print I spaces
	proc {PrintSpacing I}
		if (I > 0) then
			{System.printInfo " "}
			{PrintSpacing I-1}
		end
	end
	
	% Display board neatly
	proc {PrintBoard B}
		{List.forAllInd B
			proc {$ I Row}
				{PrintSpacing I-1}
				{System.showInfo {PrintList Row}}
			end
		}
	end
	
	% Execute move from player X to position (I#J) on board B
	fun {Move B X I J} OutB RowsBefore RowsAfter ColumnsBefore ColumnsAfter EditedRow in
		if {CheckMove B I J} then
			RowsBefore = {List.take B I}
			RowsAfter = {List.drop B I+1}
			ColumnsBefore = {List.take {List.nth B I+1} J}
			ColumnsAfter = {List.drop {List.nth B I+1} J+1}
			EditedRow = {List.append ColumnsBefore X|ColumnsAfter}
			OutB = {List.append RowsBefore EditedRow|RowsAfter}
		else
			{System.showInfo "That's not a valid move..."}
			{System.showInfo "Player "#X#" tried to move to ("#I#"#"#J#") on this board:"}
			{PrintBoard B}
			OutB = B
		end
		OutB
	end
	
	fun {IsValidPosition I J}
		(I =< 10 andthen J =< 10 andthen I >= 0 andthen J >= 0)
	end
	
	% Checks if move is possible
	fun {CheckMove B I J}
		{IsValidPosition I J} andthen ({List.nth {List.nth B I+1} J+1} == '.')
	end
	
	% Get piece at position (I#J)
	fun {Get B I J}
		if {IsValidPosition I J} then
			{List.nth {List.nth B I+1} J+1}
		else
			nil
		end
	end
	
	fun {GetPiece B Tile}
		case Tile
		of nil then
			nil
		[] (I#J) then
			{Get B I J}
		else
			nil
		end
	end
	
	% Get a list of all piece positions (I#J) that match X
	fun {GetAll B X}
		{List.filter {List.flatten {List.mapInd B
			fun {$ I Row}
				{List.mapInd Row
					fun {$ J Element}
						if(Element == X) then
							(I-1#J-1)
						else nil end
					end
				}
			end
		}} fun {$ Element} (Element \= nil) end}
	end
end