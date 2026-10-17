"""MythCards: The Threshold. Original ambient loop; Python 3 + numpy."""
from pathlib import Path
import json
import wave
import numpy as np

OUT = Path(__file__).resolve().parent
SR = 32000
SECONDS = 64
N = SR * SECONDS
rng = np.random.default_rng(1701980)
t = np.arange(N) / SR
mix = np.zeros((N, 2), dtype=np.float64)


def hz(note):
    # Integer cycles per loop keep sustained oscillators continuous at the seam.
    return round(440 * 2 ** ((note-69)/12) * SECONDS) / SECONDS


def bed(sound, pan=0):
    mix[:, 0] += sound*np.sqrt((1-pan)/2)
    mix[:, 1] += sound*np.sqrt((1+pan)/2)


def circular(sound, start, pan=0):
    idx = (round(start*SR)+np.arange(len(sound))) % N
    mix[idx, 0] += sound*np.sqrt((1-pan)/2)
    mix[idx, 1] += sound*np.sqrt((1+pan)/2)


# Low D remains underneath the harmonic motion. Upper partials let the weight
# carry on small speakers as well as headphones; no sharp attack or dance beat.
for pitch, level in [(26,.052),(38,.060),(50,.025),(57,.014)]:
    f = hz(pitch)
    breath = .78 + .15*np.cos(2*np.pi*t/16) + .07*np.sin(2*np.pi*t/64)
    core = np.sin(2*np.pi*f*t)+.16*np.sin(2*np.pi*f*3*t)
    bed(core*breath*level, -.1 if pitch == 50 else .1)

# Slow suspended shapes: Dm(add9), B-flat, G, and open D/A. No lead voice.
chords = [[50,57,64,65],[50,57,62,65],[46,53,60,65],[46,53,62,65],
          [43,50,57,62],[43,50,58,62],[45,52,57,64],[50,57,62,64]]
for i, chord in enumerate(chords):
    center = i*8+4
    distance = np.abs((t-center+SECONDS/2) % SECONDS-SECONDS/2)
    env = np.where(distance < 7, (.5+.5*np.cos(np.pi*np.minimum(distance,7)/7))**1.4, 0)
    for j, pitch in enumerate(chord):
        f = hz(pitch)
        voice = np.sin(2*np.pi*f*t + .3*np.sin(2*np.pi*t/16))
        voice += .20*np.sin(2*np.pi*(f+1/SECONDS)*t)
        voice += .07*np.sin(2*np.pi*f*3*t)
        bed(voice*env*.022, [-.58,.42,-.28,.63][j])

# Filtered circular noise: a distant air current, rather than prominent hiss.
freq = np.fft.rfftfreq(N, 1/SR)
for pan in [-.72,.72]:
    noise = rng.normal(0,1,N)
    spectrum = np.fft.rfft(noise)
    shape = np.exp(-(freq/1100)**2)*(1-np.exp(-(freq/140)**2))
    air = np.fft.irfft(spectrum*shape,n=N)
    air /= np.sqrt(np.mean(air**2))
    breath = .55+.45*np.sin(2*np.pi*t/16 + pan)**2
    bed(air*breath*.0038,pan)

# Slow engine-like pressure swells, with a soft low-mid mechanical rasp.
for i in range(16):
    u = np.arange(SR*4)/SR
    env = np.sin(np.pi*u/4)**4
    f = hz(38)
    phase = 2*np.pi*f*u
    body = np.sin(phase+.38*np.sin(phase*2))+.18*np.sin(phase/2)
    circular(body*env*.033,i*4,0)

# Distant inharmonic resonances, softly struck and heard through a long room.
for i, start in enumerate([1.5,17.5,33.5,49.5]):
    u = np.arange(12*SR)/SR
    base = hz([62,58,55,57][i])
    sound = np.zeros_like(u)
    for ratio, level, decay in [(1,.016,3),(1.503,.006,2.6),(2.117,.003,1.8)]:
        sound += np.sin(2*np.pi*base*ratio*u)*level*np.exp(-u/decay)
    sound *= (1-np.exp(-u/.11))
    pan = -.4 if i%2 else .4
    circular(sound,start,pan)
    circular(sound*.28,start+.37,-pan)
    circular(sound*.15,start+.83,pan)

mix += .13*np.roll(mix,round(.29*SR),axis=0)[:,::-1]
mix -= mix.mean(axis=0)
mix *= .10/np.sqrt(np.mean(mix**2))
assert np.isfinite(mix).all() and np.max(np.abs(mix)) < .8
# Small endpoint correction; all continuous beds and envelopes are already cyclic.
mix[-32:] += np.linspace(0,1,32)[:,None]*(mix[0]-mix[-1])
pcm = np.rint(mix*32767).astype('<i2')
with wave.open(str(OUT/'the-threshold-menu-v1.wav'),'wb') as wav:
    wav.setparams((2,2,SR,N,'NONE','not compressed'))
    wav.writeframes(pcm.tobytes())
stats = {'title':'The Threshold','version':1,'purpose':'Menu and team selection ambience',
         'seconds':SECONDS,'sample_rate':SR,'channels':2,'bit_depth':16,
         'peak_dbfs':float(20*np.log10(np.max(np.abs(pcm.astype(float)))/32768)),
         'rms_dbfs':float(20*np.log10(np.sqrt(np.mean((pcm.astype(float)/32768)**2)))),
         'clipped_samples':int(np.sum(np.abs(pcm.astype(int))>=32767)),
         'loop_endpoint_difference':int(np.max(np.abs(pcm[0].astype(int)-pcm[-1].astype(int))))}
(OUT/'render-info.json').write_text(json.dumps(stats,indent=2)+'\n',encoding='utf-8',newline='\n')
print(json.dumps(stats,indent=2))
