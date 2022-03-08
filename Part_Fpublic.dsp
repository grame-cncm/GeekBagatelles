declare name 	"Part_Fpublic";
declare version "0.3";
declare author 	"Christophe Lebreton";
declare license "BSD";

import("stdfaust.lib");

nb_soundfile = 5; // number of soundfile

// PROCESS
process = play:(@(ramp*ma.SR): select_sound ),(rampa(ramp):1,_:-):*:*(gain):*(temporisation:si.smooth(0.998))
    with {
        play = ((1-Trig_Accel)<:sh(1),_:*),Trig_Accel;
        sh(x,t) = select2(t,x,_) ~ _;

        select_sound = _<:select_a_sound,par(i,nb_soundfile,linplayer(sound(i))):multiselect(nb_soundfile):>_;

        //-----------------------------------------------------------------------------------
        /// Random Selection ID /////////////////////////////////////////////////////////////
        random_ID = no.noise:+(1):*(0.5):*(nb_soundfile):int;

        //-----------------------------------------------------------------------------------
        /// Selection Random  Audio file with accelerometer trigger /////////////////////////
        select_a_sound(x) = sh(random_ID,x):int;

        ramp = 0.001; //second

        gain = hslider("gain_dB [acc:2 0 -8 -3 -0.5] [hidden:1]",0.5,0,1,0.001):fi.lowpass(1,1.5);
        temporisation = time_count(1) > 2500; // 2.5sec
    };

//---------------------------------------------------------------------------------------
// Soundfiles
import("freunde_1_fois_soprano_waveform.dsp");
import("freunde_1_fois_baryton_waveform.dsp");
import("freunde_soprano_waveform.dsp");
import("freunde_baryton_waveform.dsp");
import("freunde_vocalise_waveform.dsp");

sound(0) = freunde_1_fois_soprano_0;
sound(1) = freunde_1_fois_baryton_0;
sound(2) = freunde_soprano_0;
sound(3) = freunde_baryton_0;
sound(4) = freunde_vocalise_0;

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////// ANALYSE INPUT FROM ACCELEROMETER //////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

//////////////////////////////// Acellerometer ////////////////////////////////////////
accel_x = hslider("acc_x [acc:0 0 -30 0 30][hidden:1]",0,-1,1,0.001);
accel_y = hslider("acc_y [acc:1 0 -30 0 30][hidden:1]",0,-1,1,0.001);
accel_z = hslider("acc_z [acc:2 0 -30 0 30][hidden:1]",0,-1,1,0.001);

Accel(x,y,z) = (x*x),(y*y),(z*z):> sqrt;

range_utile = - (offest:*(0.01)):max(0)
	with {
		offest = hslider("offset [hidden:1]",9,0,100,0.1);
	};
//////////////////////////////// Bonk ////////////////////////////////////////
bonk(c) = (c-c@t)>a
    with {
        t = hslider("winsdow_size [unit:ms][hidden:1]",1,1,7000,1);
        a = hslider("threshold [hidden:1]",30,0,30,0.01)*0.01;
    };
//////////////////////////////// Antirebond ////////////////////////////////////////
// usage: _:antirebond:_
// input signal will be binary type... int this way it was created
// logical need to don't listen input during "time_count"
choix =  select2(_,1,_);

logic_selector = _,(0): == ;

// time count in ms
time_base = 1/ma.SR;
time_count (reset) = +(0)~(+(time_base): * (reset)):*(1000);

decount =_<:time_count<(fin),_:*
	with {
		fin = hslider("antirebond [unit:ms][hidden:1]", 250,0,500,1);
	};

antirebond = (choix : decount <: logic_selector,_) ~_:!,_;
////////////////////////////////////////////////////////////////////////////////////
// usage: Trig_Accel:_
Trig_Accel=Accel(accel_x,accel_y,accel_z):range_utile:bonk:antirebond<:(_>mem);

// VUMETER ////////////////////////////////////////////////////////////////////
//-----------------------------------------------------------------------------------
hmeter(x) = attach(x, envelop(x) : hbargraph("h:Part G/vumeter[2][unit:dB]", -70, +0));
envelop = abs : max ~ -(1.0/ma.SR) : max(ba.db2linear(-70)) : ba.linear2db;

//-----------------------------------------------------------------------------------
// SAMPLE & HOLD ////////////////////////////////////////////////////////////////////
sh(x,t) = select2(t,_,x) ~ _;

// MUTLISWITCH ////////////////////////////////////////////////////////////////////
//multiswitch(n,s) = _<:par(i,n, *(i==int(s)));
multiswitch(n,select,trig) = par(i,n, trig*(i==int(select))) ;

// MULTISELECT ////////////////////////////////////////////////////////////////////
multiselect(n,s) = par(i,n, *(i==int(s))) :> _;

//-----------------------------------------------------------------------------------
/// special phasor start by a trig down and stop after 1 cycle…----------------------
rampa(time,trig) = delta : (+ : select2(trig,_,0) : max(0)) ~ _ : raz
	with {
		raz(x) = select2 (x > 1, x, 0);
		f = 1/(time:max(0.001));
		delta = sh(f/ma.SR,trig);
	};

//-----------------------------------------------------------------------------------
/// Random Selection ID /////////////////////////////////////////////////////////////
random_ID = no.noise:+(1):*(0.5):*(nb_soundfile):int;

//-----------------------------------------------------------------------------------
/// Selection Random  Audio file with accelerometer trigger /////////////////////////
select_a_sound(x) = sh(random_ID,x):int;

//---------------------------------------------------------------------------------------
// read table with linear interpolation
// wf : waveform to read
// x  : position to read (0 <= x < size(wf))

lintable(wf,pos) = linterpolation(y0,y1,d)
with {
	size = wf : _,!;					// size of the waveform
	wave = wf : !,_;					// content of the waveform
	x  = fmod(pos+size,size);			// make sure we don't read beyond boundaries
	x0 = int(x);						//
	x1 = int(x+1);						//
	d  = x-x0;
	y0 = rdtable(size+3,wave,x0);		//
	y1 = rdtable(size+3,wave,x1);		//
	linterpolation(v0,v1,c) = v0*(1-c)+v1*c;
};

//---------------------------------------------------------------------------------------
// player(wf, play) : play a waveform while play is 1
// (automatically disable itself when it doesn't have to play)
// wf   : the waveform to play
// play : control signal 1-play, 0-stop

linplayer(wf, play) =  index : lintable(wf)
	with {
		index = play : (* : max(-size) : min(size-0.000001)) ~ +(speed); // grow index while playing, 0 otherwise
		size = wf : _,!;
		speed = hslider("speed [hidden:1]",1,-2,2,0.0001);
	};
