functor
import
   Browser
   BoardViewer at 'BoardViewer.ozf'
   ScorePlayer at 'ScorePlayer.ozf'
define
   local Port1 Port2 History Won Viewer in
      Port1 = {ScorePlayer.startPlayer 1 Port2 History Won}
      Port2 = {ScorePlayer.startPlayer 2 Port1 _ _}
      Viewer = {BoardViewer.new 20}
      {ForAll History proc {$ X} {BoardViewer.move Viewer X} {Delay 100} end}
      if Won then
	 {Browser.browse 'Player 1 wins!'}
      else
	 {Browser.browse 'Player 2 wins!'}
      end
   end
end
