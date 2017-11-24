//SynthDefs....

~sparks = Buffer.read(s,"Sparks.wav"); //Use Terminal to get the exact direction on your audio.

(
SynthDef(\foldsaw,
	{
		arg freq=4, detune=1, atk=0.01, dec=0.3, rel=3, c1=1, c2=(-1), gate=1, mincf=40, maxcf=12000, minrq=0.002, maxrq=0.2, boost=1.25, amp = 1, out=0, buttonA = 0, buttonB = 0, buttonplus = 0, buttonminus = 0, buttonhome = 0;
		var signalbg, signal, env, envspark, envfm;
		env = EnvGen.kr(Env.adsr(atk,dec,0.5,rel),gate, doneAction:2);
		envspark = EnvGen.kr(Env.perc);
		envfm = EnvGen.kr(
			Env.circle([200,1600,200],[10,10,0],'exp'));
		//Background noises....
		signalbg = LFTri.ar(
			freq +
			LFNoise1.kr(LFNoise1.kr(0.5!8).range(0.1,1)).bipolar(detune), mul: amp * 0.5
		);
		5.do{
			signalbg = (signalbg*boost).fold(-1,0,1,0)
		};
		//Since you can´t put booleans in synths, I´m gonna use the values 0 & 1, is basically the same and make it a new signal.
		//This is when pressing A...
		signal = PlayBuf.ar(2,~sparks,maxrq, loop: 1) * 2 * buttonA;
		signal = signal + SinOsc.ar(SinOsc.kr(SinOsc.kr(maxrq,0,5,5),0,freq*100,100),0,(amp * buttonA * Line.kr(boost,0)), mul: amp * buttonA);
		//This is when pressing B...
		3.do{
			signal = signal +
			SinOsc.ar(SinOsc.kr(500 * boost, mul: 50 * detune), mul: buttonB * amp * 0.2);
		};
		//This is when pressing plus...
		signal = signal + SinOsc.ar(200 + SinOsc.ar(envfm,0,500),mul: amp * buttonplus);
		//This is when pressing minus...
		signal = signal +
		(
			({RHPF.ar(OnePole.ar(BrownNoise.ar, 0.99), LPF.ar(BrownNoise.ar, 14) * 400 + 500, 0.03,  amp * buttonminus)}!2) +
			({RHPF.ar(OnePole.ar(BrownNoise.ar, 0.99), LPF.ar(BrownNoise.ar, 20)
				* 800 + 1000, 0.03, amp * buttonminus)}!2)
		);
		//This is when pressing home....
		signal = signal + SinOsc.ar(OnePole.ar(Mix(
LFSaw.ar([1,0.99],[0,0.6],2000,2000).trunc([400,600])*[1,-1]
),0.98), mul: amp * 0.5 * buttonhome);
		//
		signal = BPF.ar(signal,
			LFNoise1.kr({ExpRand(0.005,0.05)}!8).exprange(mincf,maxcf),
			LFNoise1.kr({ExpRand(0,1,0.75)}!8).range(minrq, maxrq));
		signalbg = Splay.ar(signalbg) * env * amp * 2;
		Out.ar(0,signalbg * amp/2);
		Out.ar(0,Pan2.ar(signal.sum * env * amp * 2,out));
}).store;
SynthDef(\Klanging,
	{
		arg bufNum, change = 3, amp = 0.5, maxrq = 1, buttonA = 0, buttonB = 0, buttonplus = 0 , out = 0;
		var signalbg, signal, env, array0, array1, random;
		array0 = Array.fill(12, 0);
		array1 = Array.rand(12, 200.0, 1000.0);
		random = TIRand.ar(array0,array1);
		signalbg = Klang.ar(`random, 1, 0);
		env = EnvGen.kr(Env.sine(change, amp), 1, 0.02, doneAction: 2);
		signalbg = Splay.ar(signalbg) * env * amp;
		Out.ar(0,signalbg);
	}
).store;
)

//Action

(
//General variables

var screen, wiigroup, width = 1000, height = 700, seed, run = true, phase = 0, currentroll = 0, currentpitch = 0, currentacel = 0, time = 0, pastx = 0, pasty = 0, xfreeze = 0, yfreeze = 0;

//Synths variables

var synth1 =[], synth2 = [], points = []; //Start doing the stuff of points....

//Buttons variables

var button1 = false, button2 = false, buttonplus = false, buttonminus = false, buttonA = false, buttonB = false, buttonhome = false;

screen = Window("Videogame#1", Rect(150, 100, width, height), false);
screen.view.background = Color.white;
screen.onClose = { run = false };
screen.front;
//s.plotTree;   //Remove "//" if you want to see the groups
wiigroup = Group.new;
// Patterns for synth2 Klanging
p = Pbind (*[
	instrument: \Klanging,
	change: Prand([5,2,1,3,4], inf)
	]
);
//---------------------------------------------Setting buttons----------------------------------------
OSCdef(\prya, {
	arg msg;
	//convert each movement into values between 0 & 1.
	currentroll = ((msg[2].value) - 300)/2700;
	currentpitch = ((msg[1].value)- 200)/1800;
	currentacel = msg[4].value;
	//msg[2].linlin(300,3000,-1,1).postln;
	//(currentacel+1).postln;  //Remove "//" if you want to see the values
	wiigroup.set(
		\detune, msg[1].linexp(0,1,0.001,80),// Vertical position of the wiimote
		\maxrq, msg[2].linexp(0,1,0.01,0.5), // Rolling the wii like a taco
		\boost, msg[4].linlin(0.2,1,1,16), // Aceleration
		\out, msg[2].linlin(300,3000,-1,1) //Panning...
	);
	},'/wii/1/accel/pry'
);
//For the button A...
OSCdef(\buttonA, {
	arg msg;
	if (
		msg[1]==1,
		{
			//If pressed...
			"A Pressed".postln;
			//This is for running the visual stuff
			buttonA = true;
			//This is for running the audio stuff
			wiigroup.set(
				\buttonA, 1
			);
		},
		{
			//When button is released
			//Turn off visual stuff
			buttonA = false;
			//Mute audio stuff
			wiigroup.set(
				\buttonA, 0
			);
		}
	);
	}, '/a'
);
//For button B...
OSCdef(\buttonB,
	{
		arg msg;
		if (
			msg[1]==1,
			{
				"B Pressed".postln;
				buttonB = true;
				wiigroup.set(
					\buttonB, 1
				);
			},
			{
				buttonB = false;
				wiigroup.set(
					\buttonB, 0
				);
			};
		);
	}, '/b'
);
//Button1 activate synths setup 1
OSCdef(\button1,
	{
		arg msg;
		if (msg[1]==1,
			{
				"1 Pressed".postln;
				button1 = true;
				//Adding a synth each time when pressed
				if ((synth2.size > 0) || (synth1.size == 0),
					{
						//Killing the other syth..
						if (synth2.size > 0,
							{
								synth2[0].set(\gate,0);
								synth2.removeAt(0);
							}

						);
						//Adding new synth..
						synth1 = synth1.add(Synth(\foldsaw,
							[
								\freq, exprand(1,8),
								\atk, exprand(2,8),
								\rel, exprand(2,8)
							],
							wiigroup
							)
						);
					}
				);
			},
			{
				button1 = false;
			};
		)
	}, '/1'
);
//Button2 deactivate synths setup 1, soon I´ll make a second synths setup.....
OSCdef(\button2,
	{
		arg msg;
		if (msg[1]==1,
			{
				"2 Pressed".postln;
				button2 = true;
				//Remove synths from the group
				if ((synth1.size > 0) || (synth2.size == 0),
					{
						if (synth1.size >0,
							{
								synth1[0].set(\gate,0);
								synth1.removeAt(0);
							}
						);
						synth2 = synth2.add(Synth(\Klanging,
							[
								\freq, exprand(1,8),
								\atk, exprand(2,8),
								\rel, exprand(2,8)
							],
							wiigroup
							);

						);
						p.play;
					}
				);
			},
			{
				button2 = false;
			}
		)
	}, '/2'
);
OSCdef(\buttonplus,
	{
		arg msg;
		if (msg[1]==1,
			{
				"+ Pressed".postln;
				buttonplus = true;
				wiigroup.set(
					\buttonplus, 1
				);
			},
			{
				buttonplus = false;
				wiigroup.set(
					\buttonplus, 0
				);
			};
		)
	}, '/+'
);
OSCdef(\buttonminus,
	{
		arg msg;
		if (msg[1]==1,
			{
				"- Pressed".postln;
				buttonminus = true;
				wiigroup.set(
					\buttonminus, 1
				);
			},
			{
				buttonminus = false;
				wiigroup.set(
					\buttonminus, 0
				);
			};
		)
	}, '/-'
);

OSCdef(\buttonhome,
	{
		arg msg;
		if (msg[1]==1,
			{
				"HOME Pressed".postln;
				buttonhome = true;
				wiigroup.set(
					\buttonhome, 1
				);
			},
			{
				buttonhome = false;
				wiigroup.set(
					\buttonhome, 0
				);
			};
		)
	}, '/home'
);

//---------------------------------------------Animation!!!-----------------

screen.drawFunc = {
	if (synth1.size > 0,
		{
			x = currentroll * 1000;
			y = (currentpitch - 1).abs * 700;
			pastx = x * 0.2 + pastx * 0.8;
			pasty = y * 0.2 + pasty * 0.8;
			screen.view.background = Color.rand(0.87,0.9);
			Pen.use {
				Pen.strokeColor = Color.blue(0.5);
				Pen.width = 4;
				Pen.translate((pastx - 200),(pasty - 125) % height);
				Pen.fillColor = Color.rand;
				Pen.addArc(
					(x - 250)@(y - 200),
					currentacel * currentacel * 500, 0, 2pi
				);
				Pen.fill;
				if(buttonA,       // When pressing A
					{
						1.do {
							Pen.color = Color.rand(0.0,1.0).alpha_(rrand(0.1,0.7));
							Pen.addAnnularWedge(
								Point(
									(x - 250),
									(y - 200)
								),
								rrand(60,300),
								50.rand2,
								2pi.rand + (phase * 2.0.rand2),
								2pi.rand
							);
						};
						if (0.5.coin) {Pen.stroke}{Pen.fill};
					}
				);
				if (buttonB,   //When pressing B
					{
						1.do {
							Pen.color = Color.rand(0.0,1.0).alpha_(rrand(0.1,0.7));
							Pen.addAnnularWedge(
								Point(
									(x - 250),
									(y - 200)),
								rrand(60,300),
								rrand(51,100),
								0,
								2pi
							);
						};
						Pen.fill;
					};
				);
				if (buttonplus,   //When pressing +
					{
						xfreeze = pastx;
						yfreeze = pasty;
						Pen.addAnnularWedge(
							Point(
								(pastx - 140),
								(pasty - 130)
							),
							100,
							300,
							(time * time * (1 + 0.2pi)),
							1pi
						);
						Pen.fillColor = Color.rand;
						Pen.fill;
					}
				);
				if (buttonminus,   //When pressing -
					{
						xfreeze = pastx;
						yfreeze = pasty;
						rrand(10,20).do {
							Pen.color = Color.blue(rrand(0.5, 1), rrand(0.0, 0.5));
							Pen.addAnnularWedge(
								            Point(
									(x - 250),
									(y - 200)
								),
								            rrand(10, 50),
								            rrand(51, 500),
								            0,
								            2pi
							        );
							Pen.stroke;
						}

					}
				);
				if (buttonhome,   //When pressing -
					{
						xfreeze = pastx;
						yfreeze = pasty;
						rrand(10,30).do {
							Pen.color = Color.green(rrand(0.5, 1), rrand(0.0, 0.5));
							Pen.addAnnularWedge(
								            Point(
									(x - 250),
									(y - 200)),
								            rrand(10, 50),
								            rrand(51, 250),
								            2pi.rand,
								            2pi.rand
							        );
							Pen.perform([\stroke, \fill].choose);
						};

					}
				);
			};
		},
		{
			screen.view.background = Color.white;
		}
	);
	if(synth2.size>0,
		{
			seed = Date.getDate.second;
			screen.view.background = Color.blue(rrand(0.5, 1));
		}
	);
};
{
	while
	{run}
	{screen.refresh; 0.05.wait;
		phase = phase + 0.01pi;   //Just a counter
		time = time + 0.1; //Also a counter
	};
}.fork(AppClock);
)