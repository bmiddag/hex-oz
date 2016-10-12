functor
   import
      Opponent
	  Application
	  System
	  Board at 'Bart/Board.ozf'		% Used for creating or editing the board
	  Logic at 'Bart/Logic.ozf'		% Used for rules or checking whether the game is finished
	  Player at 'Bart/Player.ozf'	% Used for playing the game and communication between player threads
   define
      % Get messages
      % Will loop trough messages
      % You might want to add some acumulators here...
      %
      % Msgs    - The message stream
      proc {GameLoop Msgs PlayerPort MovePort}
		%{System.showInfo "Game: Waiting for new Msg!"}
         case Msgs of Msg|Msgr then
			%{System.printInfo "Game Msg: "}
			%{System.show Msg}
            case Msg
			of getPos(X#Y ?Value) then
				{Port.send PlayerPort getPos(X#Y ?Value)}
			[] getMoves(?List) then
				{Port.send PlayerPort getMoves(?List)}
			[] enemyMove(i:I j:J c:C) then
				if(I == 0 andthen J == 0) then
					{Port.send PlayerPort swap}
				else
					{Port.send PlayerPort (I#J#C)}
				end
			[] (_#_#_) then
				{Port.send MovePort move}
			[] won then
				{System.showInfo "Bart's App.ozf won! :)"}
			[] lost then
				{System.showInfo "Bart's App.ozf lost. :("}
            end
			{GameLoop Msgr PlayerPort MovePort}
         end
      end
	  
	  proc {MoveLoop Msgs GamePort OpponentPort C} I J in
		case Msgs of Msg|Msgr then
			%{System.printInfo "Move Msg: "}
			%{System.show Msg}
			case Msg
			of move then
				{Port.send OpponentPort doMove(x:I y:J c:C)}
				{Wait I}{Wait J}
				{Port.send GamePort enemyMove(i:I j:J c:C)}
			end
			{MoveLoop Msgr GamePort OpponentPort C}
		end
	  end

      MoveMsgs
	  GameMsgs
	  PlayerPort
	  OpponentPort
	  GamePort
	  MovePort
	  B
	  C
   in

      %Define stuff here that will allow you to communicate with the stuff
      %that calculates your moves

      thread
         {GameLoop GameMsgs PlayerPort MovePort}
      end
	  
	  thread
		{MoveLoop MoveMsgs GamePort OpponentPort C}
	  end
	  
	  GamePort = {Port.new GameMsgs}
	  MovePort = {Port.new MoveMsgs}
	  {Player.newPlayer 'V' ?PlayerPort GamePort 'Robbert' ?B}
      OpponentPort = {Opponent.new GamePort b}
	  
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


