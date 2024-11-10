//initialize
(
//Server.default.options.inDevice_("Windows WASAPI: Mic/Inst/Line In 1/2 (Studio 68)";
//Server.default.options.outDevice_("Windows WASAPI: Main Out  1/2 (Studio 68c)";
//Server.default.options.device_("WASAPI (studio 68c)");
Server.default.options.inDevice_("Windows WASAPI : Mic/Inst/Line In 1/2 (Studio 68c)");
Server.default.options.outDevice_("Windows WASAPI : Main Out 1/2 (Studio 68c)");
s.latency=0.001;
s.options.memSize = 65536;

s.waitForBoot({

//LOOPER
	Buffer.freeAll;
	s.sync;
	~b = Buffer.alloc(s, s.sampleRate * 300);

	SynthDef(\looper, {
		arg xfade=0.02, trigg=0, buf=0, run=0, reclev=0, prelev=0, recAmp=1, loopAmp=1, micAmp=1, mixAmp=1;
		var mic, trig, max, ptr, loop, rec, mix;
		mic = In.ar(50);
		trig = Trig1.ar(trigg, ControlDur.ir);
		max = Sweep.ar(trig, SampleRate.ir * run);
		ptr = Phasor.ar(trig, 1, 0, max, 0);
	    loop = BufRd.ar(1, buf, ptr);
		rec = sum([
			mic * reclev.varlag(xfade,-2),
			loop * prelev.varlag(xfade,-2)
		]);
		rec = rec * recAmp.varlag(xfade,-2);
		BufWr.ar(rec, buf, ptr);
		mix = sum([
			loop * loopAmp.varlag(xfade,-2),
			mic * micAmp.varlag(xfade,-2)
		]);
		mix = mix * mixAmp.varlag(xfade,-2);
		Out.ar(0, mix!2);
	}).add;

	s.sync;




//DELAY
SynthDef(\delay,
	{
		arg delayTime=0.5, decayTime=5;
		var sig, input;
		input=SoundIn.ar(0!2);
			sig=CombN.ar(input, 10, VarLag.kr(delayTime, 0.1), decayTime);
		Out.ar(10, sig);
	}
).add;



//REVERB
SynthDef(\reverb,
	{
		arg room=0.5, damp=0.5;
		var sig, input;
		input=SoundIn.ar(0!2);
		sig=FreeVerb.ar(input, 1, room, damp);
		Out.ar(12, sig);
	}
).add;



//PHASER
SynthDef(\phaser,
	{
		arg rate=0.2;
		var sig, input;
		input=SoundIn.ar(0!2);
		sig=CombC.ar(input, 4, SinOsc.ar(rate, 0).range(0.0018675, 0.005), 0);
		//per sentire l'effetto decommentare la parte sotto deve essere mixato con il segnale clean
		//sig=(input+(sig*1))*0.2;
		Out.ar(14, sig);
	}
).add;


//FLANGER
SynthDef(\flanger, {

	arg freq = 0.25;

	var sig, delayed;

	sig = SoundIn.ar(0);
	delayed = CombN.ar(sig,0.01,LinLin.ar(SinOsc.ar(freq),-1,1,0.001,0.008),0.05);

	Out.ar([16, 17], Mix([sig,delayed]));

}).add;


//DISTORTION
SynthDef(\distortion, {

	arg dist=0.01;

	var sig, tremolo;

	sig = SoundIn.ar(0);
	sig = sig.clip2(dist);

	Out.ar([18, 19], sig);

}).add;


//HARMONIZER
SynthDef(\harmonizer, {
	arg amp=1;
	var sig, phs, del, enve, rate, maxdel=0.05, env;
	// n ---> valore in semitoni
	rate = \n.kr(0).midiratio - 1 / maxdel;
	sig = SoundIn.ar(0!2);
	phs = LFSaw.ar(rate.neg, [1,0]).range(0, maxdel);
	enve=SinOsc.ar(rate, [3pi/2, pi/2]).range(0,1).sqrt;
	del = DelayC.ar(sig, maxdel, phs)*enve;
	del = del.sum!2;
	Out.ar(20, del*amp);
}).add;


//TREMOLO
SynthDef(\tremolo, {

	arg freq = 5;

	var sig, tremolo;

	sig = SoundIn.ar(0);

	tremolo = PitchShift.ar(sig, 0.2, LinLin.kr(SinOsc.kr(freq),-1,1,0.95,1.05),0,0.1);

	Out.ar([22, 23], tremolo);

}).add;


//CHORUS
SynthDef(\chorus, {

	arg delay=0;
	var sig, delayed, pitched;

	sig = SoundIn.ar(0);

	delayed = Mix.ar(Array.fill(4, {DelayN.ar(sig,0.05,Rand.new(0.015, 0.035+delay))}));

	pitched = Mix.ar(Array.fill(4, {PitchShift.ar(delayed, 0.2, LinLin.ar(SinOsc.kr(Rand.new(4, 7)),-1,1,Rand.new(0.95, 0.99),Rand.new(1.01, 1.05)))}),0,0.01);

	Out.ar([24, 25], pitched)

}).add;


//MIX E ISTANZE EFFETTI-----------------------------------------------------------------------------------------------------------

SynthDef(\mix,
	{
		arg fxIndexDx, fxIndexSx, ampDx=1, ampSx=1;
	    var input, ampIn=1, sigDx, sigSx, mix;

		input=SoundIn.ar(0!2);
		sigDx=In.ar((10+(fxIndexDx*2)),2);
		sigSx=In.ar((10+(fxIndexSx*2)),2);

		mix=(input*ampIn)+(sigDx*ampDx)+(sigSx*ampSx);
		Out.ar(50, mix);
}).add;


{
		~b.zero;
		~prev_r_closed=0;
		~prev_l_closed=0;
		~looper = Synth(\looper, [\buf, ~b.bufnum]);
		~mix = Synth.new(\mix, [\fxIndexDx, 10, \fxIndexSx, 10]);
		~delay = Synth.new(\delay, [\delayTime, 0.5, \decayTime, 5]);
		~reverb = Synth.new(\reverb, [\room, 2, \damp, 0.5]);
		~phaser = Synth.new(\phaser);
		~flanger = Synth.new(\flanger);
		~distortion = Synth.new(\distortion);
		~harmonizer1 = Synth.new(\harmonizer, [\n, -5]);
		~harmonizer2 = Synth.new(\harmonizer, [\n, -2]);
		~harmonizer3 = Synth.new(\harmonizer, [\n, 4]);
		~tremolo = Synth.new(\tremolo);
		~chorus = Synth.new(\chorus);
}.defer(1.5);




//SCELTA EFFETTI ATTIVI------------------------------------------------------------------------------------------------

OSCdef.new(\fxIndexSxOSC,
	{
		arg msg;
		//msg[1].postln;
		~fxIndexSx = msg[1];
		~mix.set(\fxIndexSx, msg[1]);
	},
	'/sx',
	nil,
	57120
);


OSCdef.new(\fxIndexDxOSC,
	{
		arg msg;
		//msg[1].postln;
		~fxIndexDx= msg[1];
		~mix.set(\fxIndexDx, msg[1]);
	},
	'/dx',
	nil,
	57120
);


//KINECT---------------------------------------------------------------------------------------------------


~fxIndexSx=10;
~fxIndexDx=10;

//LEFT EFFECT MODULATION
s = OSCFunc({ arg msg;
	switch (~fxIndexSx,
			0, { ~delay.set(\delayTime, LinLin.ar(msg[1], 0, 1, 0.1, 1.2));},
			1, { ~reverb.set(\room, LinLin.ar(msg[1], 0, 1, 0.1, 3));},
			2, { ~phaser.set(\rate, LinLin.ar(msg[1], 0, 1, 0.1, 3));},
			3, { ~flanger.set(\freq, LinLin.ar(msg[1], 0, 1, 0.1, 3));},
			4, { ~distortion.set(\dist, LinLin.ar(msg[1], 0, 1, 0.1, 0.01));},
		    5, {
			if (msg[1]>0.2, {~harmonizer1.set(\amp, 1);}, {~harmonizer1.set(\amp, 0);});
			if (msg[1]>0.4, {~harmonizer2.set(\amp, 1);}, {~harmonizer2.set(\amp, 0);});
			if (msg[1]>0.6, {~harmonizer3.set(\amp, 1);}, {~harmonizer3.set(\amp, 0);});
			},
			6, { ~tremolo.set(\freq, LinLin.ar(msg[1], 0, 1, 4, 7));},
			7, { ~chorus.set(\delay, LinLin.ar(msg[1], 0, 1, 0, 1));},
			8, {}
		);
	}, '/p1/hand_l:tx', nil, 7002);


//RIGHT EFFECT MODULATION
d = OSCFunc({ arg msg;
	switch (~fxIndexDx,
			0, { ~delay.set(\delayTime, LinLin.ar(msg[1], 0, 1, 0.1, 1.2));},
			1, { ~reverb.set(\room, LinLin.ar(msg[1], 0, 1, 0.1, 3));},
			2, { ~phaser.set(\rate, LinLin.ar(msg[1], 0, 1, 0.1, 3));},
			3, { ~flanger.set(\freq, LinLin.ar(msg[1], 0, 1, 0.1, 3));},
			4, { ~distortion.set(\dist, LinLin.ar(msg[1], 0, 1, 0.1, 0.01));},
		    5, {
			if (msg[1]>0.2, {~harmonizer1.set(\amp, 1);}, {~harmonizer1.set(\amp, 0);});
			if (msg[1]>0.4, {~harmonizer2.set(\amp, 1);}, {~harmonizer2.set(\amp, 0);});
			if (msg[1]>0.6, {~harmonizer3.set(\amp, 1);}, {~harmonizer3.set(\amp, 0);});
			},
			6, { ~tremolo.set(\freq, LinLin.ar(msg[1], 0, 1, 4, 7));},
			7, { ~chorus.set(\delay, LinLin.ar(msg[1], 0, 1, 0, 1));},
			8, {}
		);
	}, '/p1/hand_r:tx', nil, 7002);


//LEFT EFFECT AMP
OSCdef.new(\l_h_y,
	{
		arg msg;
		~mix.set(\ampSx, msg[1].linexp(-0.5,1,0.001,1.5));
	},
	'/p1/hand_l:ty',
	nil,
	7002
);

//RIGHT EFFECT AMP
OSCdef.new(\r_h_y,
	{
		arg msg;
		~mix.set(\ampDx, msg[1].linexp(-0.5,1,0.001,1.5));
	},
	'/p1/hand_r:ty',
	nil,
	7002
);

//LOOPER

s = OSCFunc({ arg msg;
	if(msg[1]==~prev_r_closed,{
	},{
		if( msg[1]==1,{
			~b.zero;        //clear buffer
			~looper.free; //free synth
			~looper = Synth(\looper, [\buf, ~b.bufnum], addAction: 'addToTail');  //re-instantiate synth
			~looper.set(\trig, 1, \run, 1, \reclev, 0.5, \prelev, 1, \xfade, 0.02);    //start rec
		},{
			~looper.set(\run, 0, \reclev, 0, \prelev, 1);    //stop rec and play loop
		});
		~prev_r_closed=msg[1].postln;
	}
	)
	}, '/p1/hand_r_closed', nil, 7002);


s = OSCFunc({ arg msg;
	if(msg[1]==~prev_l_closed,{
	},{
		if( msg[1]==1,{
			~looper.set(\run, 0, \reclev, 0.5, \prelev, -1.dbamp); //start overdub
		},{
			~looper.set(\run, 0, \reclev, 0, \prelev, 1);    //stop overdub and play loop
		});
		~prev_l_closed=msg[1];
	}
	)
	}, '/p1/hand_l_closed', nil, 7002);


s = OSCFunc({ arg msg;
	if( msg[1]==1,{
        ~looper.set(\run, 0, \reclev, 0, \prelev, -20.dbamp); //Fade out loop
    },{
    })
	}, '/p1/hands_touching', nil, 7002);
});
)

