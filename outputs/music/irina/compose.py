"""Irina Karpova — Private Favors, loop A. Python 3 + numpy only."""
from pathlib import Path
import json
import struct
import wave
import numpy as np

OUT = Path(__file__).resolve().parent
SR, BPM, BARS = 32000, 69, 24
BEAT = 60 / BPM
N = round(BARS * 4 * BEAT * SR)
rng = np.random.default_rng(18101980)
mix = np.zeros((N,2),dtype=np.float64)
events = []


def put(sound, beat, pan=0):
    idx = (round(beat*BEAT*SR)+np.arange(len(sound))) % N
    mix[idx,0] += sound*np.sqrt((1-pan)/2)
    mix[idx,1] += sound*np.sqrt((1+pan)/2)


def note(voice,pitch,beat,duration,velocity=.7,pan=0):
    events.append((voice,pitch,beat,duration,velocity))
    sustain = duration*BEAT
    release = {'keys':.45,'bass':.10,'pluck':.35,'silk':.23,'pad':.8}[voice]
    t = np.arange(round((sustain+release)*SR))/SR
    f = 440*2**((pitch-69)/12)
    absolute = t+beat*BEAT
    # A small amount of slow pitch movement supplies tape warmth, not wobble.
    phase = 2*np.pi*f*t+.025*np.sin(2*np.pi*.32*absolute)
    if voice == 'keys':
        body = np.sin(phase+.9*np.exp(-t/.12)*np.sin(2*phase))
        body += .16*np.sin(phase*2)*np.exp(-t/.36)
        tone = np.tanh(body*1.3)*.8
        env = np.minimum(t/.007,1)*(.72*np.exp(-t/1.5)+.28*np.exp(-t/.20))
        gain = .115
    elif voice == 'bass':
        tone = np.sin(phase)+.18*np.sin(phase*3)/3+.08*np.sin(phase*5)/5
        tone = np.tanh(tone*1.5)*.83
        env = np.minimum(t/.012,1)*np.exp(-t/1.6)
        gain = .23
    elif voice == 'pluck':
        tone = np.sin(phase+.38*np.sin(phase*2)*np.exp(-t/.08))
        tone += .12*np.sin(phase*3)*np.exp(-t/.07)
        env = np.minimum(t/.004,1)*np.exp(-t/.27)
        gain = .12
    elif voice == 'silk':
        # A dark, breath-like chip voice; no piercing upper-register square lead.
        tone = np.sin(phase)+.16*np.sin(3*phase)/3+.08*np.sin(5*phase)/5
        env = np.minimum(t/.055,1)*(.7+.3*np.exp(-t/.16))
        gain = .09
    else:
        tone = .8*np.sin(phase)+.18*np.sin(phase+2*np.pi*.12*t)
        env = np.minimum(t/.5,1)
        gain = .026
    env *= np.where(t<sustain,1,np.exp(-(t-sustain)/(release/5)))
    sound = tone*env*gain*velocity
    put(sound,beat,pan)
    if voice in ('keys','pluck','silk'):
        put(sound*.12,beat+.75,-pan*.8)
        put(sound*.05,beat+1.5,pan)


def drum(kind,beat,strength):
    length = {'kick':.25,'rim':.12,'hat':.08,'brush':.22}[kind]
    t = np.arange(round(length*SR))/SR
    noise = rng.uniform(-1,1,len(t))
    noise = np.convolve(noise,np.ones(5)/5,mode='same')
    if kind == 'kick':
        phase = 2*np.pi*(45*t+48*.016*(1-np.exp(-t/.016)))
        sound = np.tanh(1.5*np.sin(phase))*np.exp(-t/.075)*.24
        p = 36
    elif kind == 'rim':
        sound = (np.sin(2*np.pi*205*t)+.27*np.sin(2*np.pi*397*t))*np.exp(-t/.016)*.075
        sound += noise*np.exp(-t/.026)*.10
        p = 37
    elif kind == 'hat':
        sound = (noise-np.roll(noise,2))*np.exp(-t/.018)*.027
        p = 42
    else:
        sound = (noise+.22*np.sin(2*np.pi*163*t))*np.exp(-t/.055)*.09
        p = 38
    sound *= np.minimum(t/.002,1)
    put(sound*strength,beat,.26 if kind == 'hat' else -.04)
    events.append(('drums',p,beat,.12,min(.95,strength*.8)))


# Two bars per chord: Dm9 / Bbmaj9 / Gm9 / A7(b9). The voicings leave the
# bottom register to the bass and avoid a cheerful, showy luxury cliché.
chords = [(38,[57,60,64,65]),(34,[57,60,62,65]),
          (43,[57,58,62,65]),(33,[55,58,61,64])]
motif = [
 [(0,69,.6),(1.68,65,.7),(3,64,.65)],
 [(.68,62,1.0),(2.68,64,.38),(3.2,65,.5)],
 [(0,65,.8),(1.68,69,.6),(3,72,.55)],
 [(.68,69,.8),(2.68,65,.9)],
 [(0,67,.7),(1.68,65,.5),(2.68,62,.7)],
 [(.68,69,.55),(2,67,.5),(3.2,65,.45)],
 [(0,64,.7),(1.68,61,.7),(3,58,.5)],
 [(.68,61,.6),(2.68,64,.8)]
]
for bar in range(BARS):
    b = bar*4
    section = bar//8
    root,chord = chords[(bar%8)//2]
    sparse = section == 2 and bar%8 < 4
    # Weighted, deliberate bass; late offbeats give the groove its relaxed pull.
    for off,p,dur,v in [(0,root,1.05,.83),(1.68,root,.48,.53),
                        (2.68,root+7,.6,.65),(3.68,root+12,.23,.42)]:
        if sparse and off in (1.68,3.68):
            continue
        note('bass',p,b+off,dur,v)
    drum('kick',b,.86)
    if not sparse:
        drum('kick',b+2.68,.58)
        if bar%4 == 3:
            drum('kick',b+3.5,.34)
    for off in (1.025,3.025):
        drum('rim',b+off,.72 if not sparse else .42)
        if section == 1:
            drum('brush',b+off+.025,.35)
    for j in range(8):
        if sparse and j%2:
            continue
        off = j*.5+(.075 if j%2 else 0)
        drum('hat',b+off,.42 if j%2 else .28)
    # Softly rolled extended chords: rich harmony, restrained delivery.
    for off,dur,v in [(0,1.2,.71),(2.68,.75,.48)]:
        if sparse and off > 0:
            continue
        for j,p in enumerate(chord):
            note('keys',p,b+off+j*.014,dur,v,(-.28 if j%2 else .22))
    if bar%2 == 0:
        for p in (chord[0],chord[2]):
            note('pad',p,b,7.4,.65, -.45 if p==chord[0] else .45)
    # The signature is unhurried and leaves air for the other instruments.
    for off,p,dur in motif[bar%8]:
        if sparse:
            if off == 0 or off == .68:
                note('keys',p-12,b+off,dur,.58,.16)
        elif section == 1:
            note('silk',p-12,b+off,dur,.74,-.08)
            if off == 0:
                note('pluck',p,b+off+.04,.5,.44,.25)
        else:
            note('pluck',p,b+off,dur,.74,-.13)
    if section == 1 and bar%2:
        # Short replies, not yet the planned free instrumental B loop.
        for off,p in [(2.15,chord[1]+12),(2.68,chord[2]+12)]:
            note('keys',p,b+off,.23,.30,.34)

# Circular room reflections and a soft tape-like finish. Keep the lows firm.
mix += .065*np.roll(mix,round(.127*SR),axis=0)[:,::-1]
mix = np.tanh(mix*1.2)/1.2
for channel in range(2):
    extended = np.concatenate([mix[-4:,channel],mix[:,channel],mix[:4,channel]])
    kernel = np.hanning(9)
    kernel /= kernel.sum()
    mix[:,channel] = np.convolve(extended,kernel,mode='valid')
mix -= mix.mean(axis=0)
mix *= min(.84/np.max(np.abs(mix)),.12/np.sqrt(np.mean(mix**2)))
# Fine 12-bit texture rather than harsh crushing or foreground vinyl noise.
mix = np.round(mix*2047)/2047
mix[-32:] += np.linspace(0,1,32)[:,None]*(mix[0]-mix[-1])
assert np.isfinite(mix).all() and np.max(np.abs(mix))<.9
pcm = np.rint(mix*32767).astype('<i2')
with wave.open(str(OUT/'irina-private-favors-a-v1.wav'),'wb') as f:
    f.setparams((2,2,SR,N,'NONE','not compressed'))
    f.writeframes(pcm.tobytes())


def vlq(n):
    parts = [n&127]
    while n>>7:
        n >>= 7
        parts.insert(0,(n&127)|128)
    return bytes(parts)


def track(messages):
    data = bytearray()
    prev = 0
    for tick,order,msg in sorted(messages,key=lambda m:(m[0],m[1])):
        data.extend(vlq(tick-prev)+msg)
        prev=tick
    data.extend(vlq(BARS*4*480-prev)+b'\xff\x2f\x00')
    return b'MTrk'+struct.pack('>I',len(data))+data


tracks = [track([(0,0,b'\xff\x51\x03'+round(60_000_000/BPM).to_bytes(3,'big')),
                 (0,1,b'\xff\x58\x04\x04\x02\x18\x08')])]
for voice,ch,program in [('keys',0,4),('bass',1,38),('pluck',2,11),
                         ('silk',3,80),('pad',4,89),('drums',9,None)]:
    name=voice.encode()
    messages=[(0,0,b'\xff\x03'+vlq(len(name))+name)]
    if program is not None:
        messages.append((0,1,bytes([0xC0+ch,program])))
    for v,p,start,duration,vel in events:
        if v==voice:
            messages.extend([(round(start*480),3,bytes([0x90+ch,p,round(vel*100)])),
                             (min(BARS*4*480,round((start+duration)*480)),2,bytes([0x80+ch,p,0]))])
    tracks.append(track(messages))
(OUT/'irina-private-favors-a-v1.mid').write_bytes(b'MThd'+struct.pack('>IHHH',6,1,len(tracks),480)+b''.join(tracks))
stats={'title':'Irina — Private Favors','version':1,'loop':'A: main theme',
       'bpm':BPM,'bars':BARS,'seconds':N/SR,'sample_rate':SR,'channels':2,'bit_depth':16,
       'peak_dbfs':float(20*np.log10(np.max(np.abs(pcm.astype(float)))/32768)),
       'rms_dbfs':float(20*np.log10(np.sqrt(np.mean((pcm.astype(float)/32768)**2)))),
       'clipped_samples':int(np.sum(np.abs(pcm.astype(int))>=32767)),
       'loop_endpoint_difference':int(np.max(np.abs(pcm[0].astype(int)-pcm[-1].astype(int)))),
       'note_events':len(events)}
(OUT/'render-info.json').write_text(json.dumps(stats,indent=2)+'\n',encoding='utf-8',newline='\n')
print(json.dumps(stats,indent=2))
