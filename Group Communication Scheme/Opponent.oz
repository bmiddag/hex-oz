functor
import
	System
	Player at 'Bart/Player.ozf'	% Used for playing the game and communication between player threads
export new:NewPlayer
define
	fun {GetNewMove EnemyMoves Moves}
		case EnemyMoves
		of nil then
			nil
		[] (I#J#C)|EnemyMovesr then
			if {List.member (I#J#C) Moves} then
				{GetNewMove EnemyMovesr Moves}
			else
				(I#J#C)
			end
		else
			nil
		end
	end


	% PUBLIC {BoardAgent.new}
	% Create a new board ans start listening for messages
	fun {NewPlayer HostPlayer MyColour}
	
      % Get messages
      % Will loop trough messages
      % You might want to add some acumulators here...
      %
      % Msgs    - The message stream
      proc {MsgLoop Msgs PlayerPort Moves} EnemyMoves TempMoves in
		%{System.showInfo "Waiting for message from host player."}
         case Msgs of Msg|Msgr then
            case Msg
            of doMove(c:C x:X y:Y) then
				{Port.send HostPlayer getMoves(?EnemyMoves)}
				{Wait EnemyMoves}
				TempMoves = {GetNewMove EnemyMoves Moves}|Moves
				%{System.printInfo "Sorted: "}
				%{System.show TempMoves}
				case TempMoves
				of (I#J#OtherC)|_ then
					{Port.send PlayerPort (I#J#OtherC)}
					case Msgr of MsgrHead|MsgrTail then
						case MsgrHead
						of (PlayerI#PlayerJ#PlayerC) then
							X = PlayerI
							Y = PlayerJ
							C = PlayerC
							{MsgLoop MsgrTail PlayerPort (PlayerI#PlayerJ#PlayerC)|TempMoves}
						[] swap then
							X = 0
							Y = 0
							C = OtherC
							{MsgLoop MsgrTail PlayerPort TempMoves}
						end
					end
				end
			[] won then
				{System.showInfo "Bart's Opponent.ozf won! :)"}
			[] lost then
				{System.showInfo "Bart's Opponent.ozf lost. :("}
            end
         end
      end

      Msgs
	  PlayerPort
	  GamePort
   in

      %Define stuff here that will allow you to communicate with the stuff
      %that calculates your moves

      thread
         {MsgLoop Msgs PlayerPort nil}
      end
	  {Player.newPlayer 'H' ?PlayerPort GamePort 'Robbert' _}
      GamePort = {Port.new Msgs}
	  GamePort
   end
end
