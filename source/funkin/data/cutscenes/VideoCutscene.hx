package funkin.data.cutscenes;

class VideoCutscene
{
	public static function playVideo(videoName:String, onEnd:() -> Void)
	{
		var game = PlayState.instance;
		if (videoName != null)
		{
			#if VIDEOS_ALLOWED
			game.startVideo(videoName);
			var video = game.videoCutscene;
			if (video == null)
			{
				onEnd();
			}
			else
			{
				video.finishCallback = video.onSkip = function()
				{
					game.videoCutscene = null;
					onEnd();
				};
			}
			#end
		}
	}
}