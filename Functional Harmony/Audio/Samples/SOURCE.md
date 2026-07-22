# Piano sample provenance

The `*_pno.caf` files (A1-C5, 40 chromatic notes) are derived from the
University of Iowa Electronic Music Studios "Musical Instrument Samples"
recordings of a Steinway & Sons Model B piano (mezzo-forte dynamic).

Source: https://theremin.music.uiowa.edu/MISpiano.html
The University of Iowa publishes these recordings free of charge for use
without restriction; no attribution is required.

Processing (see `tools/build_piano_samples.py`): downmixed to mono,
resampled to 48 kHz, trimmed to ~2 ms pre-attack (preserve hammer),
truncated to 6 s with a 250 ms raised-cosine fade tail, peak-normalized
to -3 dBFS, stored as Int16 CAF.
