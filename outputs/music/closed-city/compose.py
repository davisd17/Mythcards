"""Rebuild the original Closed City v1 composition: Python 3 + numpy only."""
from pathlib import Path
import json
import struct
import wave
import numpy as np

OUT = Path(__file__).resolve().parent
SR = 32000
BPM = 92
BEAT = 60 / BPM
BARS = 32
SECONDS = BARS * 4 * BEAT
N = round(SECONDS * SR)
rng = np.random.default_rng(1980)
mix = np.zeros((N, 2), dtype=np.float64)
events = []


def note(voice, pitch, start, duration, velocity=0.7, pan=0.0):
    events.append((voice, pitch, start, duration, velocity))
    length = duration * BEAT
    tail = {'pluck': .18, 'lead': .07, 'bass': .04, 'accordion': .18,
            'pad': .65, 'signal': .28}[voice]
    t = np.arange(round((length + tail) * SR)) / SR
    f = 440 * 2 ** ((pitch - 69) / 12)
    # Additive oscillators avoid the harsh aliasing of naive digital squares.
    def pulse(duty=.5, harmonics=15):
        result = np.zeros_like(t)
        for h in range(1, min(harmonics, int(SR / 2 / f)) + 1):
            result += 2 * np.sin(np.pi * h * duty) / (np.pi * h) * np.cos(2*np.pi*h*f*t - np.pi*h*duty)
        return result
    if voice == 'pluck':
        tone = .7*pulse(.25, 18) + .25*np.sin(2*np.pi*f*t)
        env = np.minimum(t/.003, 1) * np.exp(-t/ max(.09, length*.42))
        gain = .19
    elif voice == 'lead':
        phase = 2*np.pi*f*t + .012*np.sin(2*np.pi*5*t)*np.minimum(t/.2, 1)
        tone = sum(np.sin(h*phase)/h for h in (1, 3, 5, 7, 9)) * .65
        env = np.minimum(t/.012, 1) * (.82+.18*np.exp(-t/.1))
        gain = .12
    elif voice == 'bass':
        tone = sum((-1)**((h-1)//2)*np.sin(2*np.pi*h*f*t)/(h*h) for h in (1,3,5,7))
        env = np.minimum(t/.008, 1)*np.exp(-t/1.7)
        gain = .18
    elif voice == 'accordion':
        tone = sum(np.sin(2*np.pi*f*h*t)/h**1.3 for h in range(1, 7))*.55
        tone += .09*np.sin(2*np.pi*f*1.003*t)
        env = np.minimum(t/.075, 1)*(.92+.08*np.sin(2*np.pi*3.8*t))
        gain = .065
    elif voice == 'pad':
        tone = .7*np.sin(2*np.pi*f*t)+.2*np.sin(2*np.pi*f*1.002*t)+.1*np.sin(2*np.pi*f*2*t)
        env = np.minimum(t/.45, 1)
        gain = .032
    else:
        tone = np.sin(2*np.pi*f*t)+.14*np.sin(2*np.pi*f*3*t)
        env = np.minimum(t/.006, 1)*np.exp(-t/.16)
        gain = .045
    env *= np.where(t < length, 1, np.exp(-(t-length)/(tail/5)))
    sound = tone*env*gain*velocity
    put(sound, start*BEAT, pan)
    if voice in ('lead', 'pluck', 'signal'):
        put(sound*.13, start*BEAT+BEAT*.75, -pan*.7)


def put(sound, seconds, pan):
    # Circular accumulation preserves releases and echoes across the loop seam.
    start = round(seconds*SR)
    idx = (start + np.arange(len(sound))) % N
    mix[idx, 0] += sound*np.sqrt((1-pan)/2)
    mix[idx, 1] += sound*np.sqrt((1+pan)/2)


def drum(kind, beat, strength=1):
    duration = {'kick': .2, 'snare': .14, 'hat': .055, 'metal': .28}[kind]
    t = np.arange(round(duration*SR))/SR
    noise = rng.uniform(-1,1,len(t))
    if kind == 'kick':
        phase = 2*np.pi*(48*t + 65*.018*(1-np.exp(-t/.018)))
        sound = np.sin(phase)*np.exp(-t/.055)*.20
        pitch = 36
    elif kind == 'snare':
        sound = (noise*.65+.35*np.sin(2*np.pi*175*t))*np.exp(-t/.034)*.095
        pitch = 38
    elif kind == 'hat':
        sound = (noise-np.roll(noise,1))*.025*np.exp(-t/.014)
        pitch = 42
    else:
        sound = (np.sin(2*np.pi*731*t)+.5*np.sin(2*np.pi*1097*t))*np.exp(-t/.07)*.035
        pitch = 76
    put(sound*strength, beat*BEAT, .12 if kind == 'hat' else -.05)
    events.append(('drums',pitch,beat,.1,min(.95,strength*.65)))


# D minor with a raised leading tone at cadences. All melodies are original;
# folk influence is expressed in phrasing, ornaments, and plucked/reed timbres.
chords = [(38, [62,65,69]), (34, [62,65,70]),
          (43, [62,67,70]), (33, [61,64,69])]
# Eight-bar question and answer; tuples are beat offset, MIDI note, duration.
melody = [
 [(0,74,.75),(1,77,.45),(1.5,76,.45),(2,74,.9),(3,69,.7)],
 [(0,70,.9),(1,74,.45),(1.5,77,.45),(2,76,.9),(3,74,.65)],
 [(0,79,.8),(1,77,.45),(1.5,74,.45),(2,70,.9),(3,74,.7)],
 [(0,73,.7),(1,76,.7),(2,73,.45),(2.5,71,.45),(3,69,.7)],
 [(0,74,.9),(1,77,.45),(1.5,81,.45),(2,79,.9),(3,77,.7)],
 [(0,77,.7),(1,74,.7),(2,70,.9),(3,69,.7)],
 [(0,67,.75),(1,70,.45),(1.5,74,.45),(2,77,.7),(3,76,.7)],
 [(0,76,.7),(1,73,.7),(2,69,1.45)]
]

for bar in range(BARS):
    b = bar*4
    section = bar//8
    root, chord = chords[bar%4]
    # A subdued two-step pulse: industrial regularity beneath the human melody.
    for off,p in [(0,root),(1.75,root+12),(2,root+7),(3.5,root+12)]:
        note('bass',p,b+off,.42 if off%1 else .7,.77)
    for off in (0,2):
        drum('kick',b+off,.68 if section == 2 else .86)
    for off in (1,3):
        drum('snare',b+off,.43 if section == 2 else .62)
    for off in np.arange(.5,4,1 if section == 2 else .5):
        drum('hat',b+float(off),.48 if off%1 else .32)
    if bar%4 == 0:
        drum('metal',b+3.5,.62)
    # Balalaika-like repeated plucking, left deliberately spacious.
    offsets = [0,.5,1.5,2,2.5,3.5]
    for j,off in enumerate(offsets):
        p = chord[[0,2,1,2,0,1][j]]
        note('pluck',p,b+off,.22,.52 if section == 0 else .66,-.34)
        if section == 1 and j in (2,5):
            note('pluck',p+12,b+off+.25,.13,.33,-.24)
    # Reedy offbeats are synthesized, with no claim of sampled authenticity.
    for off in (1,3):
        for p in chord[:2]:
            note('accordion',p-12,b+off,.58,.6,.25)
    for p in (root+24, chord[1]):
        note('pad',p,b,3.8,.7, .15 if p == chord[1] else -.15)
    phrase = melody[bar%8]
    for off,p,dur in phrase:
        if section == 2:
            # Rooftop-like respite, in a lower, softer reed register.
            note('accordion',p-12,b+off,dur,.92,.08)
            if off == 0:
                note('pluck',p,b+off,.45,.6,-.15)
        else:
            if section == 1 and off == 0:
                note('lead',p-2,b+off,.09,.42,-.08)
                off += .12
                dur = max(.15,dur-.12)
            note('lead',p,b+off,dur,.72 if section == 0 else .83,-.08)
    # A recurring receiver reply, more exposed as the theme returns.
    if bar%2 == 1:
        for off,p in [(2.75,86),(3.25,81),(3.75,85 if bar%4==3 else 86)]:
            note('signal',p,b+off,.10,.48 if section == 3 else .28,.42)

# Subtle circular room reflections avoid introducing silence at loop boundaries.
mix += .055*np.roll(mix,round(.113*SR),axis=0)[:,::-1]
mix -= np.mean(mix, axis=0)
peak_before = float(np.max(np.abs(mix)))
mix *= .86 / peak_before
# Match the endpoint across a 1 ms transition to suppress a discontinuity click.
seam = 32
mix[-seam:] += np.linspace(0,1,seam)[:,None]*(mix[0]-mix[-1])
pcm = np.clip(np.rint(mix*32767),-32768,32767).astype('<i2')
with wave.open(str(OUT/'closed-city-v1.wav'),'wb') as f:
    f.setnchannels(2)
    f.setsampwidth(2)
    f.setframerate(SR)
    f.writeframes(pcm.tobytes())


def vlq(n):
    values = [n & 127]
    while n >> 7:
        n >>= 7
        values.insert(0,(n & 127)|128)
    return bytes(values)


def track(messages):
    payload = bytearray()
    previous = 0
    for tick, priority, msg in sorted(messages,key=lambda x:(x[0],x[1])):
        payload.extend(vlq(tick-previous))
        payload.extend(msg)
        previous = tick
    payload.extend(vlq(128*480-previous)+b'\xff\x2f\x00')
    return b'MTrk'+struct.pack('>I',len(payload))+payload


tempo = round(60_000_000/BPM)
tracks = [track([(0,0,b'\xff\x51\x03'+tempo.to_bytes(3,'big')),
                 (0,1,b'\xff\x58\x04\x04\x02\x18\x08')])]
voices = [('lead',0,80),('pluck',1,105),('bass',2,38),
          ('accordion',3,21),('pad',4,89),('signal',5,10),('drums',9,None)]
for voice,channel,program in voices:
    name = voice.encode()
    messages = [(0,0,b'\xff\x03'+vlq(len(name))+name)]
    if program is not None:
        messages.append((0,1,bytes([0xC0+channel,program])))
    for v,p,start,duration,velocity in events:
        if v != voice:
            continue
        on = round(start*480)
        off = min(128*480,round((start+duration)*480))
        messages.extend([(on,3,bytes([0x90+channel,p,round(velocity*100)])),
                         (off,2,bytes([0x80+channel,p,0]))])
    tracks.append(track(messages))
(OUT/'closed-city-v1.mid').write_bytes(b'MThd'+struct.pack('>IHHH',6,1,len(tracks),480)+b''.join(tracks))
stats = {'title':'Closed City — Behind the Gates', 'version':1,
         'bpm':BPM,'bars':BARS,'seconds':N/SR,'sample_rate':SR,
         'channels':2,'bit_depth':16,'peak_dbfs':float(20*np.log10(np.max(np.abs(pcm.astype(float)))/32768)),
         'rms_dbfs':float(20*np.log10(np.sqrt(np.mean((pcm.astype(float)/32768)**2)))),
         'clipped_samples':int(np.sum(np.abs(pcm.astype(int))>=32767)),
         'loop_endpoint_difference':int(np.max(np.abs(pcm[0].astype(int)-pcm[-1].astype(int)))),
         'note_events':len(events)}
(OUT/'render-info.json').write_text(json.dumps(stats,indent=2),encoding='utf-8')
print(json.dumps(stats,indent=2))
