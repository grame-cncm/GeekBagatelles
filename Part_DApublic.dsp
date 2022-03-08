declare name 	"Part_DApublic";
declare version "0.3";
declare author 	"Christophe Lebreton";
declare license "BSD";

import("stdfaust.lib");

// PROCESS
process = D01a + D02a :*(gain)
	with {
		gain = hslider("gain_dB [acc:2 0 -8 -3 -0.5] [hidden:1]",0.5,0,1,0.001):fi.lowpass(1,1.5); //
	};

// adjustment of smooth filter from accelerometers
lpfA = hslider("lpfA [hidden:1]",2,0.1,5,0.1);

// mapping level of each soundfiles
D01a = D_A_intermedaire * (hslider("d01a [acc:0 1 -1 0 1] [hidden:1]",0.5,0,1,0.001):fi.lowpass(1,lpfA));
D02a = D_A_principale * (hslider("d02a [acc:0 0 -1 0 1] [hidden:1]",0.5,0,1,0.001):fi.lowpass(1,lpfA));

// soundfiles
import("D_A_intermedaire_waveform.dsp");
import("D_A_principale_waveform.dsp");
