/*
Program Note:

"Dastgah" brings together traditional Persian music theory, serialism, and microtonality, using SuperCollider to realize these concepts. At its center is a redefined serial matrix that expands beyond the standard 12-tone system to include 17 tones. These tones are inspired by the Persian Dastgah system, offering a microtonal perspective that extends the possibilities of serialism.

The Dastgah system is a core part of Persian music. It is known for its melodic modes and microtonal intervals, which differ from the standardized pitches of the Western equal-tempered scale. These intervals often include subtle pitch variations that give Persian music its unique expressiveness. For this piece, I used a set of 17 tones that reflect some of the diversity found in the Dastgah system, forming a microtonal foundation for serial techniques.

Serialism, originally based on the 12-tone method developed by Arnold Schoenberg, is adapted here to integrate this 17-tone structure. While preserving the serialist idea of avoiding tonal centers, the expanded tone set adds new possibilities for pitch relationships and interval patterns. This combination enhances the flexibility and depth of both serialism and microtonality.

SuperCollider played a central role in shaping this piece. The software allowed me to program the matrix to control pitch, rhythm, and dynamics with precision. I used it to create different forms of the matrix—Prime, Retrograde, Inversion, and Retrograde-Inversion—while including the microtonal variations influenced by Persian music. This interaction between serialism and microtonality produces a soundscape that evolves and transforms.

The composition moves through a range of tonal and microtonal spaces, guided by the 17-tone matrix. The matrix shapes the vertical and horizontal movements of tone progressions while allowing for moments of spontaneity and variation. The result is a work that is both structured and expressive, drawing from both Persian music and serialism.

Introducing microtonality to a serialist framework offers listeners an opportunity to experience subtleties in pitch that are less common in conventional tonal systems. The microtonal intervals inspired by the Persian Dastgah add unique textures of tension and resolution, creating a distinct musical language. This encourages listeners to connect with the cultural and theoretical ideas behind the work.

This composition seeks to create a dialogue between different musical traditions. By blending elements of Persian music, serialism, and microtonality, and by leveraging the capabilities of SuperCollider, it explores new approaches to musical expression. It is both a personal reflection on musical identity and a step toward fostering cross-cultural connections in contemporary music.

Ali Balighi - 2024

*/
(
var createMatrix, row, matrix, n, tempo, adjustFloat;

adjustFloat = { |value|
    if (value.isKindOf(Float)) {
        value = value.trunc(1) + 0.44;
    };
    value;
};

// Function to create the 17-tone matrix
createMatrix = { |row|
    var i, n = row.size;
    matrix = Array.fill(n, { Array.new(n) });  // Initialize a N * N matrix with empty sub-arrays

    matrix[0] = row;
    n.do { |i|
        if (i > 0) {
            matrix[i] = (matrix[i-1] + (row[i] - row[i-1])).mod(12);
        }
    };
    matrix;
};

// 17 Persian tones input row (Prime row)
row = [0, 1, 1.44, 2, 3, 3.44, 4, 5, 6, 6.44, 7, 8, 8.44, 9, 10, 11, 11.44].scramble;

// Generate the matrix
matrix = createMatrix.(row);

// Display the matrix
matrix.do { |row| row.postln };

// Set the tempo (beats per second)
tempo = 2;  // 2 notes per second (120 BPM)

// Function to convert pitch classes to MIDI notes and send to synth
n = row.size;  // The number of pitch classes
SynthDef(\atonalSynth, {

	|freq = 440, amp = 0.3, dur = 1|
    var sig, env, filter, osc, osc1, osc2, osc3, osc4, oscamp;

    // Envelope for the flute sound
	env = EnvGen.kr(Env.perc(0.01, Rand(0.01, 1).range(1, 4), amp, -4), doneAction: 2);

    // Create sine wave oscillators
	oscamp = Rand(0.1, 0.7);
	osc1 = SinOsc.ar(freq, 0, oscamp);
	osc2 = SinOsc.ar(freq * (5/4), 0, oscamp);
	osc3 = SinOsc.ar(freq * 2, oscamp);
	osc4 = SinOsc.ar(freq * (2 + (5/4)), 0, oscamp);

	osc = Mix.ar([osc1, osc2/2, osc3/3, osc4/4]);

    filter = LPF.ar(osc, 2000);  // Low-pass filter with cutoff frequency
    filter = HPF.ar(filter, 20);  // High-pass filter with cutoff frequency

    // Apply the envelope to the filtered signal
    sig = filter * env;

	//Panning the signals across 4 channels.
	sig = PanAz.ar(4, sig, Rand(0, 1.0), 0.8, 2, 0.5);

    // Output the signal
    Out.ar(0, sig);

}).add;

{
    var usedForms = List.new;
    var playNote, printForm, selectFormAndIndex, getPitchClassRange;

    // Function to randomly select a pitch class within a specified wide range
    getPitchClassRange = { |pitchClass|
        var baseNote;

        if (pitchClass.isNil) { pitchClass = 0; }; // Avoid nil values

        // Randomly choose a register: low, mid, or high
        switch(4.rand,
            0, { baseNote = (24 + 12.rand).clip(24, 36); },  // Low register
            1, { baseNote = (48 + 12.rand).clip(48, 60); },  // Mid register
            2, { baseNote = (72 + 12.rand).clip(72, 84); },   // High register
            3, { baseNote = (84 + 12.rand).clip(84, 96); }   // Post-High register
        );

        (baseNote + pitchClass).mod(127);  // Ensure it stays within MIDI range
    };

    // Function to play a note with a random register
    playNote = { |pitchClass|
        var midiNote = getPitchClassRange.(pitchClass);
        var freq = midiNote.midicps;
        Synth(\atonalSynth, [\freq, freq]);
		(exprand(0.1, 4)/ tempo).wait;  // Adjust wait time according to tempo
    };

    // Function to print the form used
    printForm = { |form, index, rowOrCol|
        ("Form: " ++ form ++ " " ++ index ++ ": " ++ rowOrCol).postln;
    };

    // Function to randomly select a form and index
    selectFormAndIndex = {
        var forms = [\P, \R, \I, \RI];
        var form, index;

        // Randomly select a form and index
        form = forms.choose;
        index = (0..(row.size-1)).choose;  // Ensure the index is within bounds

        [form, index];
    };

    // Continuous loop to play the matrix using random forms and indices
    inf.do {
        var formAndIndex = selectFormAndIndex.();
        var form = formAndIndex[0];
        var index = formAndIndex[1];
        var rowOrCol;

        switch(form,
            \P, { rowOrCol = matrix[index]; },
            \R, { rowOrCol = matrix[index].reverse; },
            \I, { rowOrCol = matrix.collect { |row| row[index] }; },
            \RI, { rowOrCol = matrix.collect { |row| row[index] }.reverse; }
        );

        printForm.(form.asString, index, rowOrCol);
        rowOrCol.do { |pitchClass| playNote.(pitchClass); };
    };

}.fork;
)

