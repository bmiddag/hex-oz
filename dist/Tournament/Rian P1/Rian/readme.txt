There are several binaries, all have to be in the same folder for everything to work.

The only file you will need to use is ScorePlayer.ozf, this exports one function.
When imported as ScorePlayer, you can use the function in this manner:

MyPort = {ScorePlayer.startPlayer Player OtherPort History Won} 

MyPort: the port to send messages to ScorePlayer.
Player: 1 or 2 depending on if the player has to be first or second.
OtherPort: the port of the other player.
History: optional (you can use _) additional output, will contain a list of every move played in format Player#X#Y.
Won: optional additional output, will contain a boolean that is true when ScorePlayer wins.

ScorePlayer does not output anything to the browser, instead you can use History as follows:

local History in
	{ForAll History proc {$ X} {Browser.browse X} end}
end

This will show every move in the browser as soon as it happens.

In addition, a simple game GUI is presented in BoardViewer.ozf. 
You can use it as follows (if QTk works on your computer):

local Viewer in
	Viewer = {BoardViewer.new 20}
	{ForAll History proc {$ X} {BoardViewer.move Viewer X} {Delay 100} end}
end

The message system is very simple, a message looks like this:

	X#Y

With X and Y in [1,11] and X being the column and Y being the row.

If Blue wants to start playing with Red tiles, all he has to do is send a move which overrides the first red tile during his first move.
	
When ScorePlayer wins or loses, it will automatically stop running. 
ScorePlayer is a bit slow, so please allow it up to a few seconds per move, certainly later in the game.

I have included an example on how to use the player, in Example.oz and Example.ozf.