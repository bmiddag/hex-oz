% The Game of Hex in Oz
% by Bart Middag
%
% File: Strategy.oz
% Description: Strategy module - contains strategies with syntax {Strategy Board Player LastMoveByOpponent}
% Always returns a move pair (I#J) that is the optimal next move for player X according to the chosen strategy
%
% After the last deadline of May 4th, I added not only comments but also code that checks whether a place should be visited or not
% in the GetShortestBridgePath procedure (if the amount of bridges made to arrive at this place is shorter than before, it should be).
% This doesn't make the strategy better than before but speeds it up a lot, as playing against a really good opponent almost froze my
% computer during the tournament, as the code checked all possible paths.

functor
import
	OS
	Board
export
	random:Random
	bridge:BridgeBuilder
	decideSwap:DecideSwap
define
	% Decide whether or not to swap
	fun {DecideSwap OpponentMove}
		local (I#J) = OpponentMove in
			(I > 1 andthen I < 9 andthen J > 1 andthen J < 9)
		end
	end

	% Random strategy
	fun {Random B X OpponentMove} Move RandomValue in
		RandomValue = {OS.rand} mod 121
		if {Board.checkMove B (RandomValue div 11) (RandomValue mod 11)} then
			Move = ((RandomValue div 11)#(RandomValue mod 11))
		else
			Move = {Random B X OpponentMove}
		end
		Move
	end
	
	%Bridge builder strategy
	fun {BridgeBuilder B X OpponentMove} Move BridgeList AdjacentBridge ShortestBridgePath ShortestBridgePathMoves in
		BridgeList = {GetExistingBridges B X}
		case OpponentMove
		of nil then
			skip % First move
		[] (I#J) then
			% Check if move is threatening any bridge we made
			AdjacentBridge = {GetAdjacentBridge (I#J) BridgeList}
			case AdjacentBridge
			of nil then
				skip
			[] bridge(_ _) then
				% This next move should fill the bridge that was threatened by the opponent.
				Move = {FillBridge AdjacentBridge (I#J)}
			end
		[] swap then
			skip % It's not threatening any bridge we made because this is now the "first move" for us.
		end
		% If the move hasn't been decided yet
		if {Value.isFree Move} then
			% Determine the shortest path we can make with bridges that are either still fully open or already connected.
			% Remember that if there is a bridge that is not connected but have a stone from the opponent between them,
			% the previous step will have connected the bridge.
			{GetShortestBridgePathEntry B X ?ShortestBridgePath ?ShortestBridgePathMoves}
			if (ShortestBridgePathMoves == 121) then
				% No bridge path was found. This means the opponent will win if it is smart enough to close all of its bridges.
				% Of course, if it isn't, then we can still win, but I did not have enough time to take that into consideration.
				Move = {Random B X OpponentMove}
			elseif (ShortestBridgePathMoves > 0) then
				% A bridge path was found and still needs to be completed.
				Move = {GetFreePieceFromBridgeList B ShortestBridgePath}
			else
				% A bridge path was found, but the bridges are already completed (not connected).
				% The only thing left to do is connect all the bridges.
				local TempMove in
					TempMove = {FillBridge {GetUnconnectedBridgeFromList B X ShortestBridgePath} nil}
					if TempMove == nil then
						Move = {Random B X OpponentMove}
					else
						Move = TempMove
					end
				end
			end
		end
		Move
	end
	
	% Get the first bridge where the bridge tiles aren't connected.
	fun {GetUnconnectedBridgeFromList B X BridgeList}
		case BridgeList
		of nil then
			nil
		[] bridge(Tile1 Tile2)|OtherBridges then
			if {AreConnected B X Tile1 Tile2} then
				{GetUnconnectedBridgeFromList B X OtherBridges}
			else
				bridge(Tile1 Tile2)
			end
		end
	end
	
	% Get the shortest bridge path (entry procedure)
	proc {GetShortestBridgePathEntry B X ?ShortestBridgePath ?ShortestBridgePathMoves}
		if X == 'H' then
			{GetShortestBridgePath B X 5 ~1 0 nil nil nil 0 nil 121 ShortestBridgePath ShortestBridgePathMoves}
		elseif X == 'V' then
			{GetShortestBridgePath B X ~1 5 0 nil nil nil 0 nil 121 ShortestBridgePath ShortestBridgePathMoves}
		end
	end
	
	% Get the shortest bridge path (inner procedure)
	proc {GetShortestBridgePath B X I J BridgesChecked CurrentBridgePath CurrentPiecePath CheckedPieces CurrentMoves ShortestBridgePath ShortestMoves FinalShortestBridgePath FinalShortestMoves} CheckNextBridgeTile PathTaken in
		
		% Helper function to check a candidate next bridge tile
		proc {CheckNextBridgeTile NewI NewJ NewBridgesChecked} AdjacentTiles in
			if ({Value.isFree PathTaken} andthen {Value.isFree FinalShortestBridgePath} andthen (BridgesChecked < NewBridgesChecked) andthen {Not {PiecePathContains CurrentPiecePath NewI NewJ}} andthen (CurrentMoves < {GetCheckedPieceMoves NewI NewJ CheckedPieces})
			andthen ({Board.isValidPosition NewI NewJ} orelse (X == 'H' andthen NewI >= 0 andthen NewJ == 11) orelse (X == 'V' andthen NewI == 11 andthen NewJ >= 0))) then
				PathTaken = true
				AdjacentTiles = {GetTilesBetweenBridge bridge((I#J) (NewI#NewJ))}
				if {AreConnected B X (I#J) (NewI#NewJ)} then
					{GetShortestBridgePath B X NewI NewJ 0 bridge((I#J) (NewI#NewJ))|CurrentBridgePath (I#J#NewBridgesChecked#CurrentMoves)|CurrentPiecePath CheckedPieces CurrentMoves ShortestBridgePath ShortestMoves FinalShortestBridgePath FinalShortestMoves}
				elseif ({List.length {GetFreePiecesFromList B AdjacentTiles}} == {List.length AdjacentTiles}) then
					if ((X == 'V' andthen NewJ >= 0 andthen NewI == 11) orelse (X == 'H' andthen NewI >= 0 andthen NewJ == 11) orelse ({Board.get B NewI NewJ} == X)) then
						{GetShortestBridgePath B X NewI NewJ 0 bridge((I#J) (NewI#NewJ))|CurrentBridgePath (I#J#NewBridgesChecked#CurrentMoves)|CurrentPiecePath CheckedPieces CurrentMoves ShortestBridgePath ShortestMoves FinalShortestBridgePath FinalShortestMoves}
					elseif (CurrentMoves+1 < ShortestMoves) then
						{GetShortestBridgePath B X NewI NewJ 0 bridge((I#J) (NewI#NewJ))|CurrentBridgePath (I#J#NewBridgesChecked#CurrentMoves)|CurrentPiecePath CheckedPieces CurrentMoves+1 ShortestBridgePath ShortestMoves FinalShortestBridgePath FinalShortestMoves}
					else
						{GetShortestBridgePath B X I J NewBridgesChecked CurrentBridgePath CurrentPiecePath CheckedPieces CurrentMoves ShortestBridgePath ShortestMoves FinalShortestBridgePath FinalShortestMoves}
					end
				else
					{GetShortestBridgePath B X I J NewBridgesChecked CurrentBridgePath CurrentPiecePath CheckedPieces CurrentMoves ShortestBridgePath ShortestMoves FinalShortestBridgePath FinalShortestMoves}
				end
			end
		end
		
		if ((X == 'H' andthen I == ~1) orelse (X == 'V' andthen J == ~1)) then
			% All possibilities have been checked - Final bridge path is now determined
			FinalShortestBridgePath = ShortestBridgePath
			FinalShortestMoves = ShortestMoves
		elseif (((X == 'H' andthen J >= 11) orelse (X == 'V' andthen I >= 11)) orelse (({Board.get B I J} == X) andthen ((X == 'H' andthen J == 10) orelse (X == 'V' andthen I == 10)))) then
			% Reached the end of the board. Going back and saving the current bridge path if it requires less moves to make.
			local _|BridgePathTail = CurrentBridgePath in
				local (TileI#TileJ#TileBridgesChecked#TilePreviousMoves)|PiecePathTail = CurrentPiecePath in
					if (CurrentMoves < ShortestMoves) then
						{GetShortestBridgePath B X TileI TileJ TileBridgesChecked BridgePathTail PiecePathTail CheckedPieces TilePreviousMoves CurrentBridgePath CurrentMoves FinalShortestBridgePath FinalShortestMoves}
					else
						{GetShortestBridgePath B X TileI TileJ TileBridgesChecked BridgePathTail PiecePathTail CheckedPieces TilePreviousMoves ShortestBridgePath ShortestMoves FinalShortestBridgePath FinalShortestMoves}
					end
				end
			end
		elseif (((X == 'H' andthen J < 0) orelse (X == 'V' andthen I < 0) orelse {Board.get B I J} == X orelse {Board.checkMove B I J}) andthen ((X == 'H' andthen J < 10) orelse (X == 'V' andthen I < 10))) then
			% Check all possible bridge locations
			{CheckNextBridgeTile I-1 J+2 1}
			{CheckNextBridgeTile I+1 J+1 2}
			{CheckNextBridgeTile I+2 J-1 3}
			{CheckNextBridgeTile I+1 J-2 4}
			{CheckNextBridgeTile I-1 J-1 5}
			{CheckNextBridgeTile I-2 J+1 6}
		end
		if {Value.isFree FinalShortestBridgePath} then
			case CurrentPiecePath
			of nil then
				local OldPos NewPos in
					% We are back at the beginning of the board. It is time to start from another row/column.
					% We check from the middle and go left/right or up/down all the time until we end up at place ~1.
					if (X == 'H') then
						OldPos = I
					else
						OldPos = J
					end
					if (OldPos >= 5) then
						NewPos = 5-(OldPos-5)-1
					else
						NewPos = 5+(5-OldPos)
					end
					if (X == 'H' andthen J < 0) then
						{GetShortestBridgePath B X NewPos J 0 CurrentBridgePath CurrentPiecePath CheckedPieces CurrentMoves ShortestBridgePath ShortestMoves FinalShortestBridgePath FinalShortestMoves}
					elseif (X == 'V' andthen I < 0) then
						{GetShortestBridgePath B X I NewPos 0 CurrentBridgePath CurrentPiecePath CheckedPieces CurrentMoves ShortestBridgePath ShortestMoves FinalShortestBridgePath FinalShortestMoves}
					end
				end
			[] (TileI#TileJ#TileBridgesChecked#TilePreviousMoves)|PiecePathTail then
				% We go back one piece.
				local _|BridgePathTail = CurrentBridgePath in
					{GetShortestBridgePath B X TileI TileJ TileBridgesChecked BridgePathTail PiecePathTail {AddCheckedPiece I J CurrentMoves CheckedPieces} TilePreviousMoves ShortestBridgePath ShortestMoves FinalShortestBridgePath FinalShortestMoves}
				end
			end
		end
	end
	
	% To help with GetShortestBridgePath, this decide whether or not to add the current piece
	% to the checked pieces. It doesn't change the result of the algorithm but speeds it up quite a bit.
	fun {AddCheckedPiece I J Moves CheckedPieces} ExistingMoves in
		ExistingMoves = {GetCheckedPieceMoves I J CheckedPieces}
		if (ExistingMoves == 121) then
			(I#J#Moves)|CheckedPieces
		elseif (ExistingMoves < Moves) then
			local PiecesBefore PiecesAfter Index in
				Index = {GetIndex CheckedPieces (I#J#ExistingMoves)}
				PiecesBefore = {List.take CheckedPieces Index-1}
				PiecesAfter = {List.drop CheckedPieces Index}
				{List.append PiecesBefore (I#J#Moves)|PiecesAfter}
			end
		else
			CheckedPieces
		end
	end
	
	% Get the index of an element in the list.
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
	
	% Get amount of bridges(/moves) that were built to reach a certain checked piece.
	% Used to see if a new route is shorter (less bridges/moves).
	fun {GetCheckedPieceMoves I J CheckedPieces}
		case CheckedPieces
		of nil then
			121
		[] (PieceI#PieceJ#Moves)|CheckedRest then
			if(PieceI == I andthen PieceJ == J) then
				Moves
			else
				{GetCheckedPieceMoves I J CheckedRest}
			end
		else
			121
		end
	end
	
	% Check if the piece path contains a certain piece
	fun {PiecePathContains PiecePath I J}
		case PiecePath
		of nil then
			false
		[] (PieceI#PieceJ#_#_)|OtherPieces then
			if (PieceI == I andthen PieceJ == J) then
				true
			else
				{PiecePathContains OtherPieces I J}
			end
		else
			false
		end
	end
	
	% Check pieces in a list, keep only free pieces
	fun {GetFreePiecesFromList B PieceList}
		case PieceList
		of nil then
			nil
		[] (I#J)|OtherPieces then
			if {Board.checkMove B I J} then
				(I#J)|{GetFreePiecesFromList B OtherPieces}
			else
				{GetFreePiecesFromList B OtherPieces}
			end
		else
			nil
		end
	end
	
	% Check pieces in a list, keep only first free piece
	fun {GetFreePieceFromList B PieceList}
		case PieceList
		of nil then
			nil
		[] (I#J)|OtherPieces then
			if {Board.checkMove B I J} then
				(I#J)
			else
				{GetFreePieceFromList B OtherPieces}
			end
		else
			nil
		end
	end
	
	% Check pieces in a list of bridges, keep only first free piece
	fun {GetFreePieceFromBridgeList B BridgeList}
		case BridgeList
		of nil then
			nil
		[] bridge((I1#J1) (I2#J2))|OtherBridges then
			if {Board.checkMove B I1 J1} then
				(I1#J1)
			elseif {Board.checkMove B I2 J2} then
				(I2#J2)
			else
				{GetFreePieceFromBridgeList B OtherBridges}
			end
		else
			nil
		end
	end
	
	% Get existing bridges
	fun {GetExistingBridges B X} Pieces BridgeList UpdatedBridgeList in
		Pieces = {Board.getAll B X} % Get all pieces from the current player
		BridgeList = {GetExistingBridgesFromEdges B X} % Get existing bridges that start at the edges of the board
		UpdatedBridgeList = {GetExistingBridgesFromPieceList B X Pieces BridgeList} % Add to this the bridges that start on the board itself
		{FilterBridges B X UpdatedBridgeList}
	end
	
	% Keep all bridges that aren't connected, discard those that are
	fun {FilterBridges B X BridgeList}
		case BridgeList
		of nil then
			nil
		[] bridge(Tile1 Tile2)|OtherBridges then
			if({AreConnected B X Tile1 Tile2}) then
				{FilterBridges B X OtherBridges}
			else
				bridge(Tile1 Tile2)|{FilterBridges B X OtherBridges}
			end
		else
			nil
		end
	end
	
	% Are two tiles connected by pieces of player X?
	fun {AreConnected B X Tile1 Tile2} ValidTile1 ValidTile2 in
		ValidTile1 = {GetClosestValidTile B X Tile1}
		ValidTile2 = {GetClosestValidTile B X Tile2}
		if(ValidTile1 \= nil andthen ValidTile2 \= nil) then
			local (Tile1I#Tile1J) = ValidTile1 in
				local (Tile2I#Tile2J) = ValidTile2 in
					{Visit B X Tile1I Tile1J Tile2I Tile2J nil nil}
				end
			end
		else
			false
		end
	end
	
	% Get closest tile on the board. Only works if the tile is either valid or on the edge (I or J is ~1 or 11) of the board.
	fun {GetClosestValidTile B X Tile}
		local (I#J) = Tile in
			if {Board.isValidPosition I J} then
				Tile
			else
				local Tiles PlayerTiles in
					Tiles = {GetValidAdjacentTiles Tile}
					PlayerTiles = {GetPlayerTilesFromList B X Tiles}
					case PlayerTiles
					of nil then
						nil
					[] PlayerTile|_ then
						PlayerTile
					end
				end
			end
		end
	end
	
	% Get adjacent tiles that are valid (entry)
	fun {GetValidAdjacentTiles Tile} AdjacentPositions in
		AdjacentPositions = [(0#~1) (1#~1) (1#0) (~1#0) (~1#1) (0#1)]
		{GetValidAdjacentTilesInner Tile AdjacentPositions}
	end
	
	% Get adjacent tiles that are valid (inner)
	fun {GetValidAdjacentTilesInner Tile AdjacentPositions}
		case AdjacentPositions
		of nil then
			nil
		[] (AddI#AddJ)|MoreAdjacentPositions then
			local (TileI#TileJ) = Tile in
				if {Board.isValidPosition TileI+AddI TileJ+AddJ} then
					(TileI+AddI#TileJ+AddJ)|{GetValidAdjacentTilesInner Tile MoreAdjacentPositions}
				else
					{GetValidAdjacentTilesInner Tile MoreAdjacentPositions}
				end
			end
		end
	end
	
	% Get tiles from a list that are occupied by stones of player X
	fun {GetPlayerTilesFromList B X Tiles}
		case Tiles
		of nil then
			nil
		[] Tile|MoreTiles then
			if ({Board.getPiece B Tile} == X) then
				Tile|{GetPlayerTilesFromList B X MoreTiles}
			else
				{GetPlayerTilesFromList B X MoreTiles}
			end
		end
	end
	
	% Inner function to check whether two tiles are connected. More or less adapted from Logic.oz's algorithm to check if player X has won.
	fun {Visit B X I J I2 J2 FollowedPath CheckedPlaces} Connected CheckNextPlace in
		proc {CheckNextPlace NewI NewJ}
			if {Value.isFree Connected} andthen {Board.isValidPosition NewI NewJ} andthen ({Not {List.member (NewI#NewJ) CheckedPlaces}}) then
				Connected = {Visit B X NewI NewJ I2 J2 (I#J)|FollowedPath (I#J)|CheckedPlaces}
			end
		end
		
		if ({Board.get B I J} == X) then
			if (I == I2 andthen J == J2) then
				Connected = true
			end
			{CheckNextPlace I J-1}
			{CheckNextPlace I+1 J-1}
			{CheckNextPlace I+1 J}
			{CheckNextPlace I-1 J}
			{CheckNextPlace I-1 J+1}
			{CheckNextPlace I J+1}
		end
		
		% Backtracking
		if {Value.isFree Connected} then
			case FollowedPath
			of ((Y#Z)|Xr) then
				Connected = {Visit B X Y Z I2 J2 Xr (I#J)|CheckedPlaces}
			else
				Connected = false
			end
		end
		Connected
	end
	
	% Check list of pieces for all bridges that start at each piece
	fun {GetExistingBridgesFromPieceList B X Pieces BridgeList} UpdatedBridgeList in
		case Pieces
		of nil then
			BridgeList
		[] Tile|MoreTiles then
			UpdatedBridgeList = {GetExistingBridgesFromPiece B X Tile BridgeList}
			{GetExistingBridgesFromPieceList B X MoreTiles UpdatedBridgeList}
		end
	end
	
	% Get all existing bridges that start at a certain piece (entry)
	fun {GetExistingBridgesFromPiece B X Tile BridgeList} BridgePositions in
		BridgePositions = [(~1#2) (1#1) (2#~1) (1#~2) (~1#~1) (~2#1)]
		{GetExistingBridgesFromPieceInner B X Tile BridgePositions BridgeList}
	end
	
	% Get all existing bridges that start from a certain piece (inner)
	fun {GetExistingBridgesFromPieceInner B X Tile1 BridgePositions BridgeList} Tile2 in
		case BridgePositions
		of nil then
			BridgeList
		[] (AddI#AddJ)|MorePositions then
			case Tile1
			of nil then
				BridgeList
			[] (TileI#TileJ) then
				Tile2 = (TileI+AddI#TileJ+AddJ)
				if ({Board.isValidPosition TileI+AddI TileJ+AddJ} andthen ({Board.getPiece B Tile2} == X) andthen {Not {ContainsBridge Tile1 Tile2 BridgeList}}) then
					local Tiles Tile1X Tile2X in
						Tiles = {GetTilesBetweenBridge bridge(Tile1 Tile2)}
						Tile1X = {Board.getPiece B {List.nth Tiles 1}}
						Tile2X = {Board.getPiece B {List.nth Tiles 2}}
						if(Tile1X \= X andthen Tile2X \= X andthen (Tile1X == '.' orelse Tile2X == '.')) then
							bridge(Tile1 Tile2)|{GetExistingBridgesFromPieceInner B X Tile1 MorePositions BridgeList}
						else
							{GetExistingBridgesFromPieceInner B X Tile1 MorePositions BridgeList}
						end
					end
				else
					{GetExistingBridgesFromPieceInner B X Tile1 MorePositions BridgeList}
				end
			else
				BridgeList
			end
		else
			BridgeList
		end
	end
	
	% Check if a bridge list contains a bridge between the specified pieces
	fun {ContainsBridge Tile1 Tile2 BridgeList}
		({List.member bridge(Tile1 Tile2) BridgeList} orelse {List.member bridge(Tile2 Tile1) BridgeList})
	end
	
	% Get existing bridges from edges (entry)
	fun {GetExistingBridgesFromEdges B X}
		{GetExistingBridgesFromEdgesInner B X 0 nil}
	end
	
	% Get existing bridges from edges (inner)
	fun {GetExistingBridgesFromEdgesInner B X I BridgeList} CurrentBridgeList GetExistingBridgeFromEdge in
		proc {GetExistingBridgeFromEdge I1 J1 I2 J2}
			if({Value.isFree CurrentBridgeList} andthen ({Board.get B I2 J2} == X) andthen {Not {ContainsBridge (I1#J1) (I2#J2) BridgeList}}) then
				local Tiles Tile1 Tile2 in
					Tiles = {GetTilesBetweenBridge bridge((I1#J1) (I2#J2))}
					Tile1 = {Board.getPiece B {List.nth Tiles 1}}
					Tile2 = {Board.getPiece B {List.nth Tiles 2}}
					if(Tile1 \= X andthen Tile2 \= X andthen (Tile1 == '.' orelse Tile2 == '.')) then
						CurrentBridgeList = {GetExistingBridgesFromEdgesInner B X I bridge((I1#J1) (I2#J2))|BridgeList}
					end
				end
			end
		end
		if (X == 'H') then
			{GetExistingBridgeFromEdge I+1 ~1 I 1}
			{GetExistingBridgeFromEdge I 11 I+1 9}
		else
			{GetExistingBridgeFromEdge ~1 I+1 1 I}
			{GetExistingBridgeFromEdge 11 I 9 I+1}
		end
		if {Value.isFree CurrentBridgeList} then
			if (I < 9) then
				{GetExistingBridgesFromEdgesInner B X I+1 BridgeList}
			else
				BridgeList
			end
		else
			CurrentBridgeList
		end
	end
	
	% Return the move necessary to connect the specified bridge.
	fun {FillBridge Bridge OpponentMove} TileList in
		TileList = {GetTilesBetweenBridge Bridge}
		if (OpponentMove == {List.nth TileList 1}) then
			{List.nth TileList 2}
		else
			{List.nth TileList 1}
		end
	end
	
	% Get the tiles between the the bridge (entry). If opponent places a move on one
	% of these two tiles, we can easily close the bridge by placing on the other tile.
	fun {GetTilesBetweenBridge Bridge} AdjacentPositions in
		AdjacentPositions = [(0#~1) (1#~1) (1#0) (~1#0) (~1#1) (0#1)]
		{GetTilesBetweenBridgeInner Bridge AdjacentPositions}
	end
	
	% Get the tiles between the bridge (inner)
	fun {GetTilesBetweenBridgeInner Bridge AdjacentPositions}
		local bridge(Tile1 Tile2) = Bridge in
			case AdjacentPositions
			of nil then
				nil
			[] (AddI#AddJ)|MoreAdjacentPositions then
				local (TileI#TileJ) = Tile1 in
					if {Board.isValidPosition TileI+AddI TileJ+AddJ} andthen {IsAdjacent (TileI+AddI#TileJ+AddJ) Tile2} then
						(TileI+AddI#TileJ+AddJ)|{GetTilesBetweenBridgeInner Bridge MoreAdjacentPositions}
					else
						{GetTilesBetweenBridgeInner Bridge MoreAdjacentPositions}
					end
				end
			end
		end
	end
	
	% Get a bridge from this list for which Tile is one of the two tiles in-between the bridge.
	fun {GetAdjacentBridge Tile BridgeList} AdjacentBridge in
		case BridgeList
		of nil then
			AdjacentBridge = nil
		[] bridge(Tile1 Tile2)|MoreBridges then
			if({IsAdjacent Tile Tile1} andthen {IsAdjacent Tile Tile2}) then
				AdjacentBridge = bridge(Tile1 Tile2)
			else
				AdjacentBridge = {GetAdjacentBridge Tile MoreBridges}
			end
		end
		AdjacentBridge
	end
	
	% Is a tile adjacent to another tile? (entry)
	fun {IsAdjacent Tile AdjacentTile} AdjacentPositions in
		AdjacentPositions = [(0#~1) (1#~1) (1#0) (~1#0) (~1#1) (0#1)]
		{IsAdjacentInner Tile AdjacentTile AdjacentPositions}
	end
	
	% Is a tile adjacent to another tile? (inner)
	fun {IsAdjacentInner Tile AdjacentTile AdjacentPositions} Adjacent in
		case AdjacentPositions
		of nil then
			Adjacent = false
		[] (AddI#AddJ)|MoreAdjacentPositions then
			local (TileI#TileJ) = Tile in
				% if({Board.isValidPosition TileI+AddI TileJ+AddJ} andthen ((TileI+AddI#TileJ+AddJ) == AdjacentTile)) then
				if((TileI+AddI#TileJ+AddJ) == AdjacentTile) then
					Adjacent = true
				else
					Adjacent = {IsAdjacentInner Tile AdjacentTile MoreAdjacentPositions}
				end
			end
		end
		Adjacent
	end
end