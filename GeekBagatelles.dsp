//declare name 		"Geek Bagatelles";

declare version 	"1.05";
declare author 		"Faust Grame ONE is more"; // Christophe Lebreton
declare license 	"BSD";

import("stdfaust.lib");

JOIE_A = component("Part_DApublic.dsp"),_:enable;
JOIE_B = component("Part_DBpublic.dsp"),_:enable;
FREUDE = component("Part_Fpublic.dsp"),_:enable;
VOCALISES = component("Part_Gpublic.dsp"),_:*;

// PROCESS
process = 1 <: multiselect_smooth(4,selection) : JOIE_A, JOIE_B, FREUDE, VOCALISES :> _ : hmeter : *(out) <: _,_
	with {
		out = checkbox("v:Geek Bagatelles  |  B. Cavanna/ ON/OFF [1]"):si.smooth(0.998);
		selection = vslider("v:Geek Bagatelles  |  B. Cavanna/ Select Part [2] [style:radio{'JOY I':0;'JOY II':1;'FREUDE':2;'VOCALISE':3}]", 0, 0, 3, 1);
	};

// MULTISELECT ////////////////////////////////////////////////////////////////////
multiselect_smooth(n,s) = par(i,n, *(i==int(s):si.smooth(0.998)));

// VUMETER ////////////////////////////////////////////////////////////////////
//-----------------------------------------------------------------------------------
hmeter(x) = attach(x, envelop(x) : hbargraph("v:Geek Bagatelles  |  B. Cavanna/Output[3][unit:dB]", -70, +0));
envelop = abs : max ~ -(1.0/ma.SR) : max(ba.db2linear(-70)) : ba.linear2db;
