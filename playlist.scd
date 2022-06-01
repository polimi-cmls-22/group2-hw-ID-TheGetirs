s.boot;
SerialPort.devices; // select your correct serial port modifying the serialPort variable

(

var path = thisProcess.nowExecutingPath.dirname ++ "/GUI/data/songs/";
var netAddr = "127.0.0.1", netPort = 12000;
var serialPort = "/dev/cu.usbmodem1423101", serialBaud = 9600; // "/dev/cu.usbmodem1443101"

s.boot;

n = NetAddr(netAddr,netPort);

OSCdef('OSCreceiverStartup',
	{
		arg msg;
		~applicationSynth.value;
	},
	"/startup");

OSCdef('OSCreceiverCloseApp',
	{
		arg msg;
		~closeApplications.value;
	},
	"/closeApp");

~applicationSynth = {
	// real LegoPlayer app

	var sampleRate;
	var startingTime, pauseTime, elapsedTime, elapsedSamples = 0, isPaused = false;
	var lastRate = 1;
	var volume = 0.2;
	var mute = 1;

	var checkVolume = {
		// keeps volume between the limits

		if (volume < 0, { volume = 0 });
		if (volume > 1, { volume = 1 });
	};

	var resetPause = {
		// new song is starting, reset of the pause related variables for correctly computing the stop if the user pauses

		startingTime = Date.getDate.rawSeconds;
		elapsedSamples = 0;
		isPaused = false;
	};

	var playSynth = {
		// creates the playing synth according to the parameters and registers it on the NodeWatcher

		arg inbus, bufnum = 0, amp, rate = 1, startPos = 0;
		if(~synth.isRunning, { ~synth.free; });
		~synth = Synth(\song,[
			\inbus, inbus,
			\bufnum, bufnum,
			\amp, amp,
			\rate, rate,
			\startPos, startPos
		]).onFree({
			if(~songSkip, {~songSkip = false;}, {nextSong.value;});
		});
		NodeWatcher.register(~synth);
	};

	var nextSong = {
		// changes playing song to the next one

		arg naturalTurnOrSerial = true; // if the skip is from OSC i dont need to change image on GUI
		~songPlaying = ~songPlaying + 1;
		playSynth.value(
			inbus:~bus,
			bufnum:~bufnumArray.at(~songPlaying % ~numSongs),
			amp:mute*volume,
			rate:lastRate
		);
		resetPause.value;
		if(naturalTurnOrSerial, { n.sendMsg("/nextSong"); })

	};

	var prevSong = {
		// changes playing song to the previews one

		~songPlaying = ~songPlaying - 1;
		playSynth.value(
			inbus:~bus,
			bufnum:~bufnumArray.at(~songPlaying % ~numSongs),
			amp:mute*volume,
			rate:lastRate
		);
		resetPause.value;
	};

	var pauseSong = {
		// pauses the song

		var newSamples;
		if(isPaused == false, {
			// update elapsedSamples

			pauseTime = Date.getDate.rawSeconds;
			elapsedTime = pauseTime - startingTime;
			newSamples = elapsedTime * sampleRate * lastRate;
			elapsedSamples = elapsedSamples + newSamples;
			~songSkip = true;
			if(~synth.isRunning, { ~synth.free; }); // stop the synth
			isPaused = true;
		}, {
			// create the synth starting from the elapsedSample sample

			playSynth.value(
				inbus:~bus,
				bufnum:~bufnumArray.at(~songPlaying % ~numSongs),
				amp:mute*volume,
				startPos:elapsedSamples,
				rate:lastRate
			);
			startingTime = Date.getDate.rawSeconds;
			isPaused = false;
		});
	};

	var updateElapsedSamples = {
		// updates elapsedSamples in case of a new playing rate is received

		var newSamples;
		var newRateTime = Date.getDate.rawSeconds;
		elapsedTime = newRateTime - startingTime;
		newSamples = elapsedTime * sampleRate * lastRate;
		elapsedSamples = elapsedSamples + newSamples;
		startingTime = Date.getDate.rawSeconds;
	};


	~songSkip = false;

	~numSongs = 8;
	~songPlaying = 0;

	~bufnumArray = Array.newClear(~numSongs);

	~bufnumArray[0] = Buffer.read(s, path ++ "0_Giant_Steps.wav").bufnum;
	//~bufnumArray[0] = Buffer.read(s, path ++ "piano2.wav").bufnum; // to test natural turning of songs

	~bufnumArray[1] = Buffer.read(s, path ++ "1_Tarumbo.wav").bufnum;

	~bufnumArray[2] = Buffer.read(s, path ++ "2_Them_Changes.wav").bufnum;

	~bufnumArray[3] = Buffer.read(s, path ++ "3_Dior.wav").bufnum;

	~bufnumArray[4] = Buffer.read(s, path ++ "4_Dean_Town.wav").bufnum;

	~bufnumArray[5] = Buffer.read(s, path ++ "5_You_and_Me.wav").bufnum;

	~bufnumArray[6] = Buffer.read(s, path ++ "6_I_Want_You.wav").bufnum;

	~bufnumArray[7] = Buffer.read(s, path ++ "7_Killer_Queen.wav").bufnum;

	p = SerialPort.new(serialPort,serialBaud);

	~charArray = [ ];
	~getValues = Routine.new({
		var ascii;
		{
			ascii = p.read.asAscii;
			if(ascii.isDecDigit,{~charArray =
				~charArray.add(ascii)});

			// photoresistor -> LPF
			if(ascii == $L,{
				var lightVal=~charArray.collect(_.digit).convertDigits;
				~cutoffFreq = lightVal * 200; // results in a [0:20000]
				if (~cutoffFreq > 20000, { ~cutoffFreq = 20000 });
				// postln(~cutoffFreq);
				~master.set(\freq, ~cutoffFreq);
				n.sendMsg("/lpf", ~cutoffFreq.linlin(0,20000,1,8), ~cutoffFreq);
				~charArray = [ ];
			});

			// proximity sensor -> Playback Pate
			if(ascii == $D,{
				var newRate = ~charArray.collect(_.digit).convertDigits;
				newRate = newRate / 100; // results in a [0.5:2]
				postln(newRate);
				n.sendMsg("/prate", newRate);
				//postln(~synth);
				if(~synth.isRunning, {
					~synth.set(\rate, newRate);
				});
				if(isPaused == false, { updateElapsedSamples.value; });
				lastRate = newRate;
				~charArray = [ ];
			});

			// rgb sensor -> Equalizer
			if(ascii == $R,{
				~rVal=~charArray.collect(_.digit).convertDigits;
				~rVal = ~rVal/21504;
				n.sendMsg("/red", ~rVal*255*2);
				if( ((~rVal)*125) < 35, {~lboost = ((~rVal)*125);}, {~lboost = 35;});
				// postln(~lboost);
				~master.set(\lboost, ~lboost);
				~charArray = [ ];
			});
			if(ascii == $G,{
				~gVal=~charArray.collect(_.digit).convertDigits;
				~gVal = ~gVal/21504;
				n.sendMsg("/green", ~gVal*255*2);
				if( ((~gVal)*100) < 18, {~mboost = ((~gVal)*100);}, {~mboost = 18;});
				// postln(~mboost);
				~master.set(\mboost, ~mboost);
				~charArray = [ ];
			});
			if(ascii == $B,{
				~bVal=~charArray.collect(_.digit).convertDigits;
				~bVal = ~bVal /21504;
				n.sendMsg("/blue", ~bVal*255*1.5);
				if( ((~bVal)*100) < 18, {~hboost = ((~bVal)*100);}, {~hboost = 18;});
				// postln(~hboost);
				// postln("-----");
				~master.set(\hboost, ~hboost);
				~charArray = [ ];
			});

			// IR receiver
			if(ascii == $M,{ // mute
				mute = (mute + 1) % 2;
				// postln(mute);

				n.sendMsg("/volumeSerial", mute*volume);
				if(~synth.isRunning, {
					~synth.set(\amp, mute*volume);
				});
				~charArray = [ ];
			});
			if(ascii == $+,{ // increase volume
				volume = volume + 0.1;
				// postln(volume);

				checkVolume.value;
				n.sendMsg("/volumeSerial", volume);
				if(~synth.isRunning, {
					~synth.set(\amp, volume);
				});
				~charArray = [ ];
			});
			if(ascii == $-,{ // decrease volume
				volume = volume - 0.1;
				// postln(volume);

				checkVolume.value;
				n.sendMsg("/volumeSerial", volume);
				if(~synth.isRunning, {
					~synth.set(\amp, volume);
				});
				~charArray = [ ];
			});
			if(ascii == $>,{ // next song
				~songSkip = true;
				nextSong.value(true);
				~charArray = [ ];
			});
			if(ascii == $<,{ // prev song
				~songSkip = true;
				prevSong.value;
				n.sendMsg("/prevSong");
				~charArray = [ ];
			});
			if(ascii == $P,{ // play/pause song
				pauseSong.value;
				n.sendMsg("/pause");
				~charArray = [ ];
			});
	}.loop;});

	// actual playing synth
	SynthDef(\song,{
		arg inbus, bufnum = 0, amp, rate = 1, startPos = 0;
		var sig;
		sig = PlayBuf.ar(2, bufnum, rate:rate, startPos:startPos, doneAction:2);
		Out.ar(inbus,sig*amp!2);
	}).add;

	// master synth that receives the output of a \song one and applies LPFiltering and the Equalizer
	SynthDef(\master, {
		arg inbus , filterSwitch, freq=20000, lboost = 0, mboost = 0, hboost = 0;
		var sig,in;
		var sigl, sigm, sigh;
		in = In.ar(inbus,1);
		sig = RLPF.ar(in, freq, 0.7);
		sigl = BLowShelf.ar(sig, freq:80, db:lboost);
		sigm = BPeakEQ.ar(sigl, freq:2000, db:mboost);
		sigh = BHiShelf.ar(sigm, freq:8000, db:hboost);
		Out.ar([0,1],sigh);
	}).add;

	s.waitForBoot({ // in case of the first bootup, we wait for the server to be ready

		sampleRate = s.sampleRate;
		Date.localtime;

		// bus to connect \song and \master
		~bus = Bus.audio(s,1);

		~master = Synth(\master, [
			\inbus, ~bus,
			\filterSwitch, 1
		]);
		NodeWatcher.register(~master);

		~synth = Synth(\song,[
			\inbus, ~bus,
			\bufnum, ~bufnumArray.at(~songPlaying % ~numSongs),
			\amp, volume
		]).onFree({
			if(~songSkip, {~songSkip = false;}, {nextSong.value;});
		});
		NodeWatcher.register(~synth);
		startingTime = Date.getDate.rawSeconds;

		// start serial routine
		~getValues.play;

		// OSC reveivers
		OSCdef('OSCreceiverNextPrev',   // next or prev song from GUI button
			{
				arg msg;
				var move = msg[1]; // 1 = next, -1 = prev

				//update song
				~songSkip = true;
				if(move>0, { nextSong.value(false); }, { prevSong.value; });

			},
			"/nextPrev");

		OSCdef('OSCreceiverMenuSelect',  // play/pause from GUI button
			{
				arg msg;
				~songPlaying = msg[1];
				~songSkip = true;
				playSynth.value(
					inbus:~bus,
					amp:mute*volume,
					bufnum:~bufnumArray.at(~songPlaying % ~numSongs),
					rate:lastRate
				);
				resetPause.value;

			},
			"/menuSelect");

		OSCdef('OSCreceiverPlayPause',     // volume from GUI slider
			{
				arg msg;
				pauseSong.value;

			},
			"/playPause");

		OSCdef('OSCreceiverVolume',
			{
				arg msg;
				volume = msg[1];
				// postln(volume);

				if(mute == 0, {mute = 1;});

				if(~synth.isRunning, {
					~synth.set(\amp, volume);
				});
			},
			"/volumeOSC");

	}, onFailure:{ "error".postln; });
};

~closeApplications = {
	// frees playing synths and shuts the serial and OSC connection

	~songSkip = true;
	s.freeAll;
	SerialPort.closeAll;
	n.disconnect;
	"SHUT DOWN APP - SERVER STILL RUNS.\nOPEN THE GUI AGAIN TO RESTART.\n\n".postln;
};

"let's Lego!".postln;

)

SerialPort.closeAll;
s.plotTree;
s.freeAll;