import hxd.snd.effect.Pitch;
import event.TalkedToEvent;
import event.ModifyTalk;
import ecs.event.EventBus;
import hxd.snd.ChannelGroup;
import ecs.utils.MathUtils;
import hxd.snd.Channel;
import hxd.res.Sound;

class AudioController {
	static var instance:AudioController;

	public var talkEnabled = true;

	var levelMusicTracks:Array<Sound>;
	var inbetween:Sound;
	var menu:Sound;
	var play:Sound;
	var currentMusic:Channel;
	var oldMusic:Channel;
	var talking:Bool;
	var talkSounds:Array<Sound>;
	var talkingGroup:ChannelGroup;
	var talkingTimers:Array<haxe.Timer>;
	var talkingPitch:Pitch;
	var musicFadeTime = 1.;
	var maxTalkVolume = .65;
	var noiseVolume = .5;

	function new(eventBus:EventBus) {
		levelMusicTracks = new Array<Sound>();
		levelMusicTracks[0] = hxd.Res.audio.party;
		levelMusicTracks[1] = hxd.Res.audio.club;
		levelMusicTracks[2] = hxd.Res.audio.coffee;
		levelMusicTracks[3] = hxd.Res.audio.noise;

		talkSounds = [
			hxd.Res.audio.text_0,
			hxd.Res.audio.text_1,
			hxd.Res.audio.text_2,
			hxd.Res.audio.text_3,
			hxd.Res.audio.text_4,
			hxd.Res.audio.text_5,
			hxd.Res.audio.text_6,
		];

		inbetween = hxd.Res.audio.inbetween;
		menu = hxd.Res.audio.menu;
		play = hxd.Res.audio.play;

		talkingPitch = new Pitch(1.0);

		talkingGroup = new ChannelGroup("talking");
		talkingGroup.addEffect(talkingPitch);

		eventBus.subscribe(ModifyTalk, function(e:ModifyTalk) {
			talkEnabled = e.talkEnabled;
		});
	}

	public static function get():AudioController {
		if (AudioController.instance == null) {
			throw 'Please call AudioController.init() before using';
		}

		return AudioController.instance;
	}

	public static function init(eventBus:EventBus) {
		if (AudioController.instance != null)
			return;

		AudioController.instance = new AudioController(eventBus);
	}

	public function startTalking(pitch:Float) {
		if (!talkEnabled || talking)
			return;

		talkingPitch.value = pitch;
		talking = true;
		talkingGroup.volume = maxTalkVolume;
		talkingGroup.mute = false;
		talk();
	}

	var talkTimerMin = 50;
	var talkTimerMax = 200;

	function talk() {
		if (!talking)
			return;

		talkSounds[MathUtils.roll(talkSounds.length) - 1].play(false, 1., talkingGroup);
		var delay = talkTimerMin + MathUtils.roll(talkTimerMax - talkTimerMin);
		haxe.Timer.delay(talk, delay);
	}

	public function stopTalking() {
		talking = false;
		talkingGroup.fadeTo(0., .25, function() talkingGroup.mute = true);
	}

	public function fadeOut(time:Float) {
		if (currentMusic == null || currentMusic.isReleased())
			return;

		oldMusic = currentMusic;
		oldMusic.fadeTo(0., time, function() oldMusic.stop());
	}

	public function playMenu() {
		if (handleCrossFadeMusic(menu, true)) {
			return;
		}

		currentMusic = menu.play(true);
	}

	public function playPlay() {
		play.play();
	}

	public function playInbetween(fadeIn:Bool = false) {
		if (fadeIn) {
			fadeOut(2.);
			currentMusic = inbetween.play(true, 0.);
			currentMusic.fadeTo(1, 2.5);
			return;
		}
		if (handleCrossFadeMusic(inbetween, true)) {
			return;
		}

		currentMusic = inbetween.play(true);
	}

	public function playLevelMusic(level:Int) {
		var v = 1.;
		if (level == 3)
			v = noiseVolume;

		if (handleCrossFadeMusic(levelMusicTracks[level], false, v)) {
			return;
		}

		var nextSong = levelMusicTracks[level];
		currentMusic = nextSong.play(false, v);
	}

	function handleCrossFadeMusic(newSound:Sound, loop:Bool, volume:Float = 1.):Bool {
		if (currentMusic != null && !currentMusic.isReleased()) {
			oldMusic = currentMusic;
			oldMusic.fadeTo(0, musicFadeTime, function() {
				oldMusic.stop();
			});

			currentMusic = newSound.play(loop, volume);

			return true;
		}

		return false;
	}
}
