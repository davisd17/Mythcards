"""Irina — Private Favors B v1: an instrumental conversation and breakdown."""
from pathlib import Path
import json
import struct
import wave
import numpy as np

OUT = Path(__file__).resolve().parent
SR, BPM, BARS = 32000, 69, 24
BEAT = 60 / BPM
N = round(BARS * 4 * BEAT * SR)
rng = np.random.default_rng(18101981)
mix = np.memmap(OUT/'.irina-b-mix.tmp',mode='w+',shape=(N,2),dtype=np.float32)
mix[:] = 0
events = []


def put(sound, beat, pan=0, frame_offset=0):
    for offset in range(0,len(sound),1024):
        part = sound[offset:offset+1024]
        idx = (round(beat*BEAT*SR)+frame_offset+offset+np.arange(len(part),dtype=np.int32)) % N
        mix[idx,0] += part*np.float32(np.sqrt((1-pan)/2))
        mix[idx,1] += part*np.float32(np.sqrt((1+pan)/2))


def note(voice,pitch,beat,duration,velocity=.7,pan=0):
    events.append((voice,pitch,beat,duration,velocity))
    sustain = duration*BEAT
    release = {'keys':.45,'bass':.10,'pluck':.35,'silk':.23,'pad':.8}[voice]
    f = 440*2**((pitch-69)/12)
    frames = round((sustain+release)*SR)
    for offset in range(0,frames,1024):
        t = np.arange(offset,min(frames,offset+1024),dtype=np.float64)/SR
        absolute = t+beat*BEAT
        phase = 2*np.pi*f*t+.025*np.sin(2*np.pi*.32*absolute)
        if voice == 'keys':
            body = np.sin(phase+.68*np.exp(-t/.18)*np.sin(2*phase))
            body += .13*np.sin(phase*2)*np.exp(-t/.42)
            tone = np.tanh(body*1.3)*.8
            env = np.minimum(t/.006,1)*(.78*np.exp(-t/1.7)+.22*np.exp(-t/.23))
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
            gain = .085
        elif voice == 'silk':
            tone = np.sin(phase)+.24*np.sin(3*phase)/3+.12*np.sin(5*phase)/5
            env = np.minimum(t/.055,1)*(.7+.3*np.exp(-t/.16))
            gain = .08
        else:
            tone = .8*np.sin(phase)+.18*np.sin(phase+2*np.pi*.12*t)
            env = np.minimum(t/.5,1)
            gain = .026
        env *= np.where(t<sustain,1,np.exp(-(t-sustain)/(release/5)))
        sound = (tone*env*gain*velocity).astype(np.float32)
        put(sound,beat,pan,offset)
        if voice in ('keys','pluck','silk'):
            put(sound*.12,beat+.75,-pan*.8,offset)
            put(sound*.05,beat+1.5,pan,offset)


def drum(kind,beat,strength):
    length = {'kick':.25,'rim':.12,'hat':.08,'brush':.22}[kind]
    t = np.arange(round(length*SR),dtype=np.float32)/SR
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
# bottom register to the bass: dark luxury with a relaxed, memorable signature.
chords = [(38,[57,60,64,65]),(34,[57,60,62,65]),
          (43,[57,58,62,65]),(33,[55,58,61,64])]
# Deliberately written improvisation-like phrases. Each chorus passes the
# conversation between instruments instead of repeating A over busier drums.
piano_solo = [
 [(.18,69,.27),(.68,72,.28),(1.18,69,.48),(2.18,67,.23),(2.68,65,.4),(3.18,64,.22),(3.55,65,.25)],
 [(.18,69,.3),(.68,72,.28),(1.18,74,.35),(1.68,72,.25),(2.18,69,.36),(2.68,67,.28),(3.18,65,.55)],
 [(.68,69,.32),(1.18,72,.32),(1.68,74,.62),(2.68,72,.24),(3.18,69,.55)],
 [(.18,74,.25),(.68,72,.25),(1.18,69,.5),(2.18,65,.28),(2.68,64,.28),(3.18,62,.6)],
 [(.18,67,.32),(.68,70,.3),(1.18,74,.75),(2.68,69,.55),(3.55,67,.24)],
 [(.68,65,.23),(1.18,69,.28),(1.68,67,.5),(2.68,65,.24),(3.18,62,.6)],
 [(.18,64,.3),(.68,67,.28),(1.18,70,.46),(2.18,69,.22),(2.55,67,.22),(2.88,64,.22),(3.22,61,.43)],
 [(.68,64,.3),(1.18,61,.35),(2.18,58,.35),(2.68,61,.3),(3.18,64,.55)]
]
chip_solo = [
 [(.18,62,.55),(1.18,65,.35),(1.68,69,.65),(3.18,67,.45)],
 [(.68,65,.4),(1.68,64,.4),(2.68,62,.7)],
 [(.18,65,.4),(.68,69,.3),(1.68,72,.8),(3.18,69,.5)],
 [(.68,65,.6),(2.18,62,.4),(2.68,64,.75)]
]
rebuild = [
 [(.18,69,.5),(1.18,72,.35),(2.18,69,.7)],
 [(.68,67,.3),(1.18,65,.4),(2.68,64,.6)],
 [(.18,69,.3),(.68,72,.28),(1.18,74,.7),(2.68,72,.35),(3.18,69,.4)],
 [(.68,65,.3),(1.18,64,.3),(1.68,62,.85)],
 [(.18,69,.3),(.68,72,.3),(1.18,69,.55),(2.68,65,.7)],
 [(.68,67,.3),(1.18,65,.28),(1.68,62,.7),(3.18,65,.5)],
 [(.18,64,.3),(.68,67,.3),(1.18,64,.55),(2.68,61,.6)],
 [(.68,58,.4),(1.68,61,.4),(2.68,64,.48)]
]
for bar in range(BARS):
    b = bar*4
    root,chord = chords[(bar%8)//2]
    breakdown = 12 <= bar < 16
    rebuilding = 16 <= bar < 20
    # Keep A's pocket, but let the bass take the foreground during the breakdown.
    next_root = chords[((bar%8)//2+1)%4][0]
    pickup = next_root-1 if bar%2 else root+12
    bass_line = [(0,root,1.1,.80),(1.68,root+7,.38,.52),
                 (2.5,root+12,.7,.60),(3.68,pickup,.23,.40)]
    if breakdown:
        bass_line = [(0,root,1.3,.61),(2.18,root+7,.42,.46),(3.18,root+12,.5,.42)]
    for off,p,dur,v in bass_line:
        note('bass',p,b+off,dur,v)
    if not breakdown:
        drum('kick',b,.76 if rebuilding else .86)
        drum('kick',b+2.5,.42 if rebuilding else .57)
        for off in (1.025,3.025):
            drum('rim',b+off,.47 if rebuilding else .60)
            if bar < 12 or bar >= 20:
                drum('brush',b+off+.025,.24)
        for j in range(8):
            if rebuilding and j%2:
                continue
            off = j*.5+(.075 if j%2 else 0)
            drum('hat',b+off,.44 if j%2 else .23)
    elif bar >= 14:
        # Two bars without drums, then little touches announce the way back.
        drum('rim',b+3.025,.26)
        for off in (.575,2.575):
            drum('hat',b+off,.24)
    if bar in (7,19,23):
        drum('brush',b+3.18,.29)
        drum('rim',b+3.68,.24)
    comp = [(0,1.5,.44),(2.68,.65,.29)]
    if 8 <= bar < 12:
        comp = [(.18,1.4,.42),(2.18,.55,.30)]
    if breakdown:
        comp = [(.18,1.8,.32)] if bar%2 == 0 else [(1.18,1.3,.28)]
    for off,dur,v in comp:
        for j,p in enumerate(chord):
            note('keys',p,b+off+j*.014,dur,v, -.30 if j%2 else .24)
    if bar%2 == 0 and not breakdown:
        for p in (chord[0],chord[2]):
            note('pad',p,b,7.4,.54, -.45 if p==chord[0] else .45)
    if bar < 8:
        for j,(off,p,dur) in enumerate(piano_solo[bar]):
            # Small, composed variations in touch; no timing randomness on boundaries.
            note('keys',p,b+off,dur,.90 if j%3 == 0 else .73,-.12)
        if bar%2:
            note('silk',chord[0],b+3.55,.30,.48,.28)
    elif bar < 12:
        for off,p,dur in chip_solo[bar-8]:
            note('silk',p,b+off,dur,.86,.08)
        for off,p in [(2.95,chord[1]+12),(3.45,chord[2]+12)]:
            note('keys',p,b+off,.25,.47,-.20)
    elif breakdown:
        # The foreground is quiet: little piano fragments rather than a full hook.
        for off,p,dur in [(1.68,chord[1],.5),(2.68,chord[2],.8)]:
            note('keys',p,b+off,dur,.50,.10)
        if bar in (13,15):
            note('pluck',chord[2]+12,b+3.18,.28,.34,.30)
    else:
        voice = 'silk' if bar in (16,18) else 'keys'
        for off,p,dur in rebuild[bar-16]:
            note(voice,p if voice == 'keys' else p-12,b+off,dur,.80,-.10)
        if bar%2 and bar < 22:
            for off,p in [(2.68,chord[0]+12),(3.18,chord[2]+12)]:
                note('pluck',p,b+off,.22,.43,.32)

# File-backed, chunked mastering keeps memory modest even on a busy workstation.
CHUNK = 1024
room = np.memmap(OUT/'.irina-b-room.tmp',mode='w+',shape=(N,2),dtype=np.float32)
for start in range(0,N,CHUNK):
    end = min(N,start+CHUNK)
    previous = (np.arange(start,end)-round(.127*SR)) % N
    room[start:end] = np.tanh((mix[start:end]+.065*mix[previous,::-1])*1.2)/1.2
kernel = np.hanning(9).astype(np.float32)
kernel /= kernel.sum()
total = np.zeros(2,dtype=np.float64)
for start in range(0,N,CHUNK):
    end = min(N,start+CHUNK)
    idx = np.arange(start-4,end+4) % N
    for channel in range(2):
        mix[start:end,channel] = np.convolve(room[idx,channel],kernel,mode='valid')
    total += mix[start:end].sum(axis=0,dtype=np.float64)
mean = total/N
peak = energy = 0.0
for start in range(0,N,CHUNK):
    end = min(N,start+CHUNK)
    mix[start:end] -= mean
    block = mix[start:end]
    peak = max(peak,float(np.max(np.abs(block))))
    energy += float(np.sum(block**2,dtype=np.float64))
gain = min(.84/peak,.12/np.sqrt(energy/(N*2)))
for start in range(0,N,CHUNK):
    end = min(N,start+CHUNK)
    mix[start:end] = np.round(mix[start:end]*gain*2047)/2047
mix[-32:] += np.linspace(0,1,32)[:,None]*(mix[0]-mix[-1])
peak = energy = 0.0
clipped = 0
section_bounds = [(label,round(start*4*BEAT*SR),round(end*4*BEAT*SR)) for label,start,end in
                  [('piano_jam',0,8),('chip_exchange',8,12),('breakdown',12,16),('rebuild',16,24)]]
section_energy = {label:0.0 for label,_,_ in section_bounds}
with wave.open(str(OUT/'irina-private-favors-b-v1.wav'),'wb') as f:
    f.setparams((2,2,SR,N,'NONE','not compressed'))
    for start in range(0,N,CHUNK):
        end = min(N,start+CHUNK)
        block = mix[start:end]
        assert np.isfinite(block).all() and np.max(np.abs(block))<.9
        pcm = np.rint(block*32767).astype('<i2')
        f.writeframes(pcm.tobytes())
        peak = max(peak,float(np.max(np.abs(block))))
        energy += float(np.sum(block**2,dtype=np.float64))
        clipped += int(np.sum((pcm==32767)|(pcm==-32768)))
        for label,lo,hi in section_bounds:
            a,z = max(start,lo),min(end,hi)
            if a<z:
                section_energy[label] += float(np.sum(mix[a:z]**2,dtype=np.float64))


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
(OUT/'irina-private-favors-b-v1.mid').write_bytes(b'MThd'+struct.pack('>IHHH',6,1,len(tracks),480)+b''.join(tracks))
stats={'title':'Irina — Private Favors: After Hours','version':1,'loop':'B: jam and breakdown',
       'bpm':BPM,'bars':BARS,'seconds':N/SR,'sample_rate':SR,'channels':2,'bit_depth':16,
       'peak_dbfs':float(20*np.log10(peak)),
       'rms_dbfs':float(20*np.log10(np.sqrt(energy/(N*2)))),
       'clipped_samples':clipped,
       'loop_endpoint_difference':int(np.max(np.abs(np.rint(mix[0]*32767)-np.rint(mix[-1]*32767)))),
       'note_events':len(events)}
# Section measurements confirm that the breakdown leaves audible dynamic room.
stats['section_rms_dbfs'] = {}
for label,start,end in section_bounds:
    stats['section_rms_dbfs'][label] = float(20*np.log10(np.sqrt(section_energy[label]/((end-start)*2))))
(OUT/'render-info-b-v1.json').write_text(json.dumps(stats,indent=2)+'\n',encoding='utf-8',newline='\n')
print(json.dumps(stats,indent=2))
mix.flush()
room.flush()
mix._mmap.close()
room._mmap.close()
del mix,room
(OUT/'.irina-b-mix.tmp').unlink()
(OUT/'.irina-b-room.tmp').unlink()
