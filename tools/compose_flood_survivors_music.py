"""Original Flood Survivors and Queen Meret-Anu listening drafts; Python + numpy."""
from pathlib import Path
import argparse
import json
import struct
import wave
import numpy as np

ROOT = Path(__file__).resolve().parents[1]
SR, BPM, BEAT = 32000, 69, 60/69
VOICES = [('harp',0,46),('reed',1,73),('horn',2,60),('pad',3,89),
          ('bass',4,38),('chime',5,11),('drums',9,None)]


class Score:
    def __init__(self, queen):
        self.queen = queen
        self.bars, self.beats = (24,4) if queen else (32,3)
        self.name = 'meret-anu-a-drowned-crown-a-v1' if queen else 'flood-survivors-stone-remembers-v1'
        self.folder = ROOT/'outputs/music'/('meret-anu' if queen else 'flood-survivors')
        self.folder.mkdir(parents=True,exist_ok=True)
        self.n = round(self.bars*self.beats*BEAT*SR)
        self.tmp = self.folder/'.render.tmp'
        self.mix = np.memmap(self.tmp,mode='w+',dtype=np.float32,shape=(self.n,2))
        self.mix[:] = 0
        self.events = []

    def put(self, sound, beat, pan, offset=0):
        index = (round(beat*BEAT*SR)+offset+np.arange(len(sound))) % self.n
        self.mix[index,0] += sound*np.sqrt((1-pan)/2)
        self.mix[index,1] += sound*np.sqrt((1+pan)/2)

    def note(self,voice,pitch,beat,duration,velocity=.7,pan=0):
        self.events.append((voice,pitch,beat,duration,velocity))
        length=duration*BEAT
        tail={'harp':.32,'reed':.24,'horn':.25,'pad':.7,'bass':.09,'chime':.4}[voice]
        f=440*2**((pitch-69)/12)
        frames=round((length+tail)*SR)
        for offset in range(0,frames,1024):
            t=np.arange(offset,min(frames,offset+1024))/SR
            phase=2*np.pi*f*t+.018*np.sin(2*np.pi*.27*(t+beat*BEAT))
            if voice=='harp':
                tone=np.sin(phase+.45*np.exp(-t/.07)*np.sin(2*phase))
                tone+=.13*np.sin(3*phase)*np.exp(-t/.12)
                env=np.minimum(t/.004,1)*np.exp(-t/.42)
                gain=.125
            elif voice=='reed':
                tone=np.sin(phase)+.19*np.sin(2*phase)+.08*np.sin(3*phase)
                env=np.minimum(t/.026,1)*(.78+.22*np.exp(-t/.18))
                gain=.103
            elif voice=='horn':
                tone=np.sin(phase)+.25*np.sin(2*phase)+.15*np.sin(3*phase)/3
                tone=np.tanh(tone*1.25)*.8
                env=np.minimum(t/.04,1)*(.72+.28*np.exp(-t/.16))
                gain=.082
            elif voice=='pad':
                tone=np.sin(phase)+.15*np.sin(phase+2*np.pi*.09*t)
                env=np.minimum(t/.5,1)*(.82+.18*np.sin(2*np.pi*t/4))
                gain=.025
            elif voice=='bass':
                tone=np.sin(phase)+.12*np.sin(3*phase)/3
                env=np.minimum(t/.012,1)*np.exp(-t/1.6)
                gain=.22
            else:
                tone=np.sin(phase)+.12*np.sin(2.76*phase)*np.exp(-t/.09)
                env=np.minimum(t/.004,1)*np.exp(-t/.32)
                gain=.075
            env*=np.where(t<length,1,np.exp(-(t-length)/(tail/5)))
            sound=(tone*env*gain*velocity).astype(np.float32)
            self.put(sound,beat,pan,offset)
            if voice in ('harp','reed','chime'):
                self.put(sound*.12,beat+.75,-pan,offset)
                self.put(sound*.045,beat+1.5,pan,offset)

    def drum(self,kind,beat,velocity=.7):
        t=np.arange(round(.25*SR))/SR
        if kind=='skin':
            phase=2*np.pi*(57*t+42*.022*(1-np.exp(-t/.022)))
            sound=np.sin(phase+.45*np.exp(-t/.018)*np.sin(2*phase))*np.exp(-t/.065)*.23
            pitch=36
        elif kind=='stone':
            sound=(np.sin(2*np.pi*181*t)+.35*np.sin(2*np.pi*307*t))*np.exp(-t/.027)*.085
            pitch=37
        else:
            sound=(np.sin(2*np.pi*2303*t)+.32*np.sin(2*np.pi*3571*t))*np.exp(-t/.010)*.022
            pitch=42
        sound*=np.minimum(t/.002,1)
        self.put(sound*velocity,beat,.2 if kind=='shell' else -.05)
        self.events.append(('drums',pitch,beat,.15,velocity))

    def arrange(self):
        # Dorian color for people building a way forward; the Queen changes B to
        # B-flat and uses a stronger dominant cadence for disciplined authority.
        area=[(38,[53,57,59,64]),(43,[55,59,62,64]),
              (41,[57,60,64,67]),(36,[52,55,62,64])]
        royal=[(38,[53,60,64,69]),(34,[53,57,62,64]),
               (43,[53,58,62,69]),(33,[55,58,61,64])]
        folk=[[(.08,62,.50),(.75,69,.38),(1.5,67,.50),(2.25,64,.50)],
              [(.5,65,.5),(1.5,64,.4),(2.25,62,.5)],
              [(.08,62,.5),(.75,69,.38),(1.5,71,.5),(2.25,69,.5)],
              [(.5,67,.5),(1.5,64,.45),(2.25,62,.5)],
              [(.08,67,.5),(.75,69,.38),(1.5,71,.5),(2.25,74,.5)],
              [(.5,71,.5),(1.5,69,.45),(2.25,67,.5)],
              [(.08,65,.5),(.75,69,.38),(1.5,67,.5),(2.25,64,.5)],
              [(.5,62,.5),(1.5,64,.4),(2.25,60,.5)]]
        crown=[[(.10,62,.55),(.85,69,.55),(1.6,67,.7),(2.65,64,.9)],
               [(.35,65,.5),(1.35,64,.45),(2.35,62,1.1)],
               [(.10,62,.55),(.85,69,.55),(1.6,67,.7),(2.65,64,.9)],
               [(.35,65,.5),(1.35,64,.45),(2.35,62,.65),(3.35,65,.4)],
               [(.10,67,.55),(.85,74,.55),(1.6,72,.7),(2.65,69,.9)],
               [(.35,70,.5),(1.35,69,.45),(2.35,67,1.1)],
               [(.10,64,.55),(.85,69,.55),(1.6,67,.7),(2.65,61,.9)],
               [(.35,64,.5),(1.35,61,.45),(2.35,57,1.1)]]
        for bar in range(self.bars):
            b=bar*self.beats
            if not self.queen:
                root,chord=area[(bar%16)//4]
                hush=16<=bar<24
                self.note('bass',root,b,1.15,.69)
                self.note('bass',root+7,b+1.5,1.0,.46)
                self.drum('skin',b,.54 if hush else .73)
                if not hush:
                    self.drum('stone',b+1.5,.55)
                    for off in (.5,2.0,2.5): self.drum('shell',b+off,.4)
                for j,off in enumerate((0,.5,1.0,1.5,2.0,2.5)):
                    if hush and j%2: continue
                    self.note('harp',chord[[0,2,1,3,2,1][j]],b+off,.24,.42,-.33)
                if bar%4==0:
                    for j,p in enumerate(chord[::2]):
                        self.note('pad',p,b,11.6,.65,(-.4,.4)[j])
                for off,p,duration in folk[bar%8]:
                    if hush:
                        if off==.08: self.note('harp',p-12,b+off,.75,.66,.05)
                    else:
                        self.note('reed',p,b+off,duration,.72 if bar<8 else .79,-.08)
                if bar%4==3 and not hush:
                    self.note('chime',chord[2]+12,b+2.5,.3,.34,.4)
            else:
                root,chord=royal[(bar%8)//2]
                hush=16<=bar<20
                for off,p,duration,v in [(0,root,1.5,.82),(2.5,root+7,.9,.53)]:
                    self.note('bass',p,b+off,duration,v)
                self.drum('skin',b,.63 if hush else .87)
                if not hush:
                    self.drum('skin',b+2.5,.47)
                    self.drum('stone',b+1.1,.44)
                    self.drum('stone',b+3.1,.57)
                    for off in (.75,1.75,3.75): self.drum('shell',b+off,.34)
                for off,v in [(0,.57),(2.65,.36)]:
                    if hush and off: continue
                    for j,p in enumerate(chord):
                        self.note('harp',p,b+off+j*.035,1.25,v,(-.3 if j%2 else .23))
                if bar%2==0:
                    for j,p in enumerate((chord[0],chord[2])):
                        self.note('pad',p,b,7.6,.63,(-.42,.42)[j])
                for off,p,duration in crown[bar%8]:
                    if hush:
                        if off==.1: self.note('horn',p-12,b+off,1.0,.57)
                    else:
                        self.note('reed',p,b+off,duration,.88,-.06)
                        if off in (.1,2.65):
                            self.note('horn',p-12,b+off+.025,duration,.5,.10)
                if bar in (0,8,20): self.note('chime',74,b+.85,.65,.45,.32)
                if bar%4==3 and not hush:
                    for off,p in [(2.85,chord[1]+12),(3.35,chord[2]+12)]:
                        self.note('harp',p,b+off,.3,.46,.32)

    def render(self):
        # Chunked circular room and mastering; no continuous noise/hiss layer.
        room_path=self.folder/'.room.tmp'
        room=np.memmap(room_path,mode='w+',dtype=np.float32,shape=(self.n,2))
        size=2048
        for start in range(0,self.n,size):
            end=min(self.n,start+size)
            idx=(np.arange(start,end)-round(.173*SR))%self.n
            room[start:end]=np.tanh((self.mix[start:end]+.10*self.mix[idx,::-1])*1.15)/1.15
        kernel=np.hanning(9).astype(np.float32); kernel/=kernel.sum()
        total=np.zeros(2)
        for start in range(0,self.n,size):
            end=min(self.n,start+size); idx=np.arange(start-4,end+4)%self.n
            for c in range(2): self.mix[start:end,c]=np.convolve(room[idx,c],kernel,mode='valid')
            total+=self.mix[start:end].sum(axis=0,dtype=np.float64)
        mean=total/self.n
        energy=peak=0.0
        for start in range(0,self.n,size):
            end=min(self.n,start+size); self.mix[start:end]-=mean
            block=self.mix[start:end]
            energy+=float(np.sum(block**2,dtype=np.float64)); peak=max(peak,float(np.max(np.abs(block))))
        target=.115 if self.queen else .10
        gain=min(.82/peak,target/np.sqrt(energy/(self.n*2)))
        for start in range(0,self.n,size):
            end=min(self.n,start+size)
            self.mix[start:end]=np.round(self.mix[start:end]*gain*2047)/2047
        self.mix[-32:]+=np.linspace(0,1,32)[:,None]*(self.mix[0]-self.mix[-1])
        peak=energy=0.0; clipped=0
        with wave.open(str(self.folder/(self.name+'.wav')),'wb') as f:
            f.setparams((2,2,SR,self.n,'NONE','not compressed'))
            for start in range(0,self.n,size):
                block=self.mix[start:min(self.n,start+size)]
                assert np.isfinite(block).all() and np.max(np.abs(block))<.9
                pcm=np.rint(block*32767).astype('<i2'); f.writeframes(pcm.tobytes())
                energy+=float(np.sum(block**2,dtype=np.float64)); peak=max(peak,float(np.max(np.abs(block))))
                clipped+=int(np.sum((pcm==32767)|(pcm==-32768)))
        version=getattr(self,'version',1)
        stats={'title':getattr(self,'title','A Drowned Crown' if self.queen else 'Stone Remembers'),'version':version,
               'bpm_quarter':BPM,'bars':self.bars,'meter':'4/4' if self.queen else '6/8',
               'seconds':self.n/SR,'frames':self.n,'sample_rate':SR,'channels':2,'bit_depth':16,
               'peak_dbfs':20*np.log10(peak),'rms_dbfs':20*np.log10(np.sqrt(energy/(self.n*2))),
               'clipped_samples':clipped,'endpoint_step':int(np.max(np.abs(self.mix[0]-self.mix[-1]))*32767),
               'note_events':len(self.events)}
        report_name=getattr(self,'report_name','render-info-v%d.json'%version)
        (self.folder/report_name).write_text(json.dumps(stats,indent=2)+'\n',encoding='utf-8',newline='\n')
        self.midi()
        self.mix.flush(); room.flush(); self.mix._mmap.close(); room._mmap.close()
        del self.mix,room
        self.tmp.unlink(); room_path.unlink()
        print(json.dumps(stats,indent=2))

    def midi(self):
        def vlq(n):
            out=[n&127]
            while n>>7:
                n>>=7; out.insert(0,(n&127)|128)
            return bytes(out)
        def track(messages):
            out=bytearray(); last=0
            for tick,order,msg in sorted(messages,key=lambda v:(v[0],v[1])):
                out.extend(vlq(tick-last)+msg); last=tick
            out.extend(vlq(self.bars*self.beats*480-last)+b'\xff\x2f\x00')
            return b'MTrk'+struct.pack('>I',len(out))+out
        signature=bytes([4,2,24,8]) if self.queen else bytes([6,3,36,8])
        tracks=[track([(0,0,b'\xff\x51\x03'+round(60_000_000/BPM).to_bytes(3,'big')),
                       (0,1,b'\xff\x58\x04'+signature)])]
        for voice,ch,program in VOICES:
            name=voice.encode(); messages=[(0,0,b'\xff\x03'+vlq(len(name))+name)]
            if program is not None: messages.append((0,1,bytes([0xC0+ch,program])))
            for v,p,start,duration,vel in self.events:
                if v==voice:
                    messages.extend([(round(start*480),3,bytes([0x90+ch,p,round(vel*100)])),
                                     (min(self.bars*self.beats*480,round((start+duration)*480)),2,bytes([0x80+ch,p,0]))])
            tracks.append(track(messages))
        (self.folder/(self.name+'.mid')).write_bytes(b'MThd'+struct.pack('>IHHH',6,1,len(tracks),480)+b''.join(tracks))


if __name__=='__main__':
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--track',choices=['area','queen','both'],default='both')
    args=parser.parse_args()
    for queen in ([False,True] if args.track=='both' else [args.track=='queen']):
        score=Score(queen); score.arrange(); score.render()
