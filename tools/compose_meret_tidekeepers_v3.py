"""Meret-Anu: Tidekeepers v3. Hand drums, synthetic wordless choir, water. A-B-A."""
from pathlib import Path
import argparse
import importlib.util
import json
import wave
import numpy as np

SOURCE=Path(__file__).with_name('compose_flood_survivors_music.py')
spec=importlib.util.spec_from_file_location('flood_engine',SOURCE)
engine=importlib.util.module_from_spec(spec)
spec.loader.exec_module(engine)
SR,BEAT=engine.SR,engine.BEAT
engine.VOICES=[('choir',0,52),('chant',1,53),('water',2,10),
               ('tide',3,89),('bass',4,38),('drums',9,None)]


class Tidekeepers(engine.Score):
    def __init__(self, form):
        super().__init__(True)
        self.form=form
        self.version=3
        self.title='Meret-Anu — Tidekeepers: '+form.upper()
        self.name='meret-anu-tidekeepers-'+form+'-v3'
        self.report_name='render-info-'+form+'-v3.json'
        if form=='aba':
            self.mix._mmap.close()
            del self.mix
            self.bars=72
            self.n=round(self.bars*4*BEAT*SR)
            self.mix=np.memmap(self.tmp,mode='w+',dtype=np.float32,shape=(self.n,2))
            self.mix[:]=0

    def note(self,voice,pitch,beat,duration,velocity=.7,pan=0):
        self.events.append((voice,pitch,beat,duration,velocity))
        length=duration*BEAT
        tail={'choir':.55,'chant':.25,'water':.4,'tide':.65,'bass':.08}[voice]
        frames=round((length+tail)*SR)
        f=440*2**((pitch-69)/12)
        for offset in range(0,frames,1024):
            t=np.arange(offset,min(frames,offset+1024))/SR
            absolute=t+beat*BEAT
            phase=2*np.pi*f*t
            if voice in ('choir','chant'):
                # Additive vowel formants, two subtly detuned singers. No speech,
                # human recordings, lyrics, or noise-bed masquerading as a choir.
                tone=np.zeros_like(t)
                opening=.52 if voice=='chant' else .18+.30*np.minimum(t/.7,1)
                weight_sum=0
                for h in range(1,min(19,int(5000/f))):
                    freq=f*h
                    oo=np.exp(-((freq-340)/190)**2)+.75*np.exp(-((freq-850)/230)**2)
                    ah=np.exp(-((freq-680)/220)**2)+.70*np.exp(-((freq-1200)/300)**2)
                    weight=(.12+(1-opening)*oo+opening*ah)/h**.65
                    vibrato=.19*np.sin(2*np.pi*4.8*t)*np.minimum(t/.3,1)
                    for cents in (-3.2,3.2):
                        singer=phase*2**(cents/1200)+vibrato
                        tone+=np.sin(h*singer)*weight*.5
                    weight_sum+=weight
                tone/=np.maximum(weight_sum,.01)
                env=np.minimum(t/(.035 if voice=='chant' else .14),1)
                env*=.86+.14*np.sin(2*np.pi*.8*absolute)
                gain=.21 if voice=='chant' else .078
            elif voice=='water':
                # Pitched liquid droplets, not an electric piano or surf hiss.
                phase+=.28*(1-np.exp(-t/.018))
                tone=np.sin(phase+.92*np.exp(-t/.055)*np.sin(2*phase))
                tone+=.12*np.sin(2.71*phase)*np.exp(-t/.045)
                env=np.minimum(t/.004,1)*np.exp(-t/.25)
                gain=.12
            elif voice=='tide':
                tone=np.sin(phase+.18*np.sin(2*np.pi*1.7*t))+.15*np.sin(phase*2)
                env=np.minimum(t/.32,1)*(.6+.4*np.sin(np.pi*np.minimum(t/max(length,.1),1))**2)
                gain=.035
            else:
                tone=np.sin(phase)+.09*np.sin(phase*3)/3
                env=np.minimum(t/.012,1)*np.exp(-t/1.3)
                gain=.19
            env*=np.where(t<length,1,np.exp(-(t-length)/(tail/5)))
            sound=(tone*env*gain*velocity).astype(np.float32)
            self.put(sound,beat,pan,offset)
            if voice in ('water','chant'):
                self.put(sound*(.22 if voice=='water' else .11),beat+2/3,-pan,offset)
                self.put(sound*.07,beat+4/3,pan,offset)

    def drum(self, kind, beat, velocity=.7, pan=0):
        t=np.arange(round(.32*SR))/SR
        if kind=='deep':
            phase=2*np.pi*(55*t+40*.024*(1-np.exp(-t/.024)))
            sound=np.sin(phase+.5*np.exp(-t/.025)*np.sin(phase*2))*np.exp(-t/.085)*.27
            pitch=41
        elif kind=='open':
            phase=2*np.pi*(148*t+32*.012*(1-np.exp(-t/.012)))
            sound=(np.sin(phase+.55*np.exp(-t/.022)*np.sin(phase*1.59))
                   +.23*np.sin(phase*2.13))*np.exp(-t/.060)*.15
            pitch=64
        elif kind=='slap':
            phase=2*np.pi*263*t
            sound=(np.sin(phase+1.8*np.exp(-t/.012)*np.sin(phase*1.47))
                   +.25*np.sin(phase*2.73))*np.exp(-t/.022)*.13
            pitch=62
        elif kind=='wood':
            sound=(np.sin(2*np.pi*673*t)+.3*np.sin(2*np.pi*1117*t))*np.exp(-t/.014)*.065
            pitch=75
        else:
            sound=(np.sin(2*np.pi*2413*t)+.27*np.sin(2*np.pi*3563*t))*np.exp(-t/.008)*.022
            pitch=69
        sound*=np.minimum(t/.0015,1)
        self.put(sound*velocity,beat,pan)
        self.events.append(('drums',pitch,beat,.15,min(.99,velocity)))

    def section(self, form, start):
        harmony=[(43,[55,58,62]),(41,[53,57,62]),
                 (36,[55,60,63]),(38,[54,57,60])]
        # G minor / F / C minor / D. A G-Bb-D / C-A signature in choral calls.
        hook=[[(0,55,.45),(2/3,58,.35),(4/3,62,.60),(7/3,60,.30),(3,57,.65)],
              [(1/3,58,.45),(4/3,57,.4),(7/3,55,1.0)],
              [(0,55,.45),(2/3,58,.35),(4/3,62,.60),(7/3,60,.3),(3,57,.65)],
              [(1/3,57,.45),(4/3,60,.4),(7/3,62,1.0)],
              [(0,60,.45),(2/3,63,.35),(4/3,67,.60),(7/3,65,.3),(3,62,.65)],
              [(1/3,63,.45),(4/3,62,.4),(7/3,60,1.0)],
              [(0,57,.45),(2/3,60,.35),(4/3,62,.60),(7/3,60,.3),(3,54,.65)],
              [(1/3,57,.45),(4/3,54,.4),(7/3,50,1.0)]]
        for bar in range(24):
            b=start+bar*4
            root,chord=harmony[(bar%8)//2]
            breaking=form=='b' and 12<=bar<16
            quiet=(form=='a' and 16<=bar<20) or breaking
            building=form=='b' and 16<=bar<20
            self.note('bass',root,b,1.35,.74 if not quiet else .48)
            if not breaking:
                self.note('bass',root+7,b+8/3,.72,.46)
            if not quiet or bar%2==0:
                self.drum('deep',b,.91 if not quiet else .44)
            if not breaking:
                self.drum('deep',b+2,.61 if not quiet else .28)
            if not quiet:
                for off,v in [(2/3,.69),(5/3,.45),(8/3,.77),(11/3,.40)]:
                    self.drum('open',b+off,v,-.23)
                for off,v in [(1,.53),(7/3,.65),(10/3,.48)]:
                    self.drum('slap',b+off,v,.20)
                for off in (1/3,4/3,2,3):
                    self.drum('wood',b+off,.45,.35)
                if (form=='b' and bar<12) or (form=='a' and 8<=bar<16):
                    for off in (1.5,2.5,3.5): self.drum('shell',b+off,.39,-.35)
                if bar%4==3:
                    for off,v in [(3,.37),(10/3,.46),(11/3,.57)]:
                        self.drum('open',b+off,v,.1)
            elif bar>=14:
                self.drum('wood',b+3,.25,.25)
            # Choir is the harmonic bed, not a faint pad behind lounge keys.
            if bar%2==0:
                for j,p in enumerate(chord):
                    self.note('choir',p,b,7.45,.72 if not breaking else .48,[-.45,0,.45][j])
                self.note('tide',root+12,b,7.5,.60,.10)
            if form=='a':
                for off,p,duration in hook[bar%8]:
                    if quiet:
                        if off==0:self.note('water',p+12,b+off,.55,.56,-.15)
                    else:
                        self.note('chant',p,b+off,duration,.87,-.08)
                if not quiet and bar%2:
                    for off,p in [(2,chord[1]+12),(8/3,chord[2]+12),(10/3,chord[1]+12)]:
                        self.note('water',p,b+off,.24,.45,.30)
            elif breaking:
                self.note('water',chord[1]+12,b+4/3,.4,.48,-.20)
                if bar%2: self.note('chant',chord[0],b+2,.8,.40,.16)
            elif bar<8:
                # Water/mallet improvisation-like replies in long and short phrases.
                seq=([chord[0]+12,chord[2]+12,chord[1]+12,chord[0]+12]
                     if bar%2==0 else [chord[1]+12,chord[2]+12,chord[1]+12])
                times=[1/3,1,5/3,3] if bar%2==0 else [2/3,5/3,8/3]
                for j,(off,p) in enumerate(zip(times,seq)):
                    self.note('water',p,b+off,.27 if j%2 else .48,.74,-.25 if bar%2 else .25)
                self.note('chant',chord[0],b,.65,.64,-.05)
            elif bar<12:
                # Choir call, water response: deliberately composed interplay.
                for off,p,duration in [(0,chord[0],.7),(1,chord[1],.5),(2,chord[2],.65)]:
                    self.note('chant',p,b+off,duration,.79,-.15)
                for off,p in [(8/3,chord[1]+12),(10/3,chord[2]+12)]:
                    self.note('water',p,b+off,.25,.65,.30)
            else:
                for j,(off,p,duration) in enumerate(hook[bar%8]):
                    if building and j%2: continue
                    self.note('chant',p,b+off,duration,.62 if building else .82,-.08)
                if bar%2 and bar<22:
                    self.note('water',chord[2]+12,b+3,.3,.48,.25)

    def arrange(self):
        for i,form in enumerate(['a','b','a'] if self.form=='aba' else [self.form]):
            self.section(form,i*96)

    def render(self):
        super().render()
        path=self.folder/(self.name+'.wav')
        # Measure the completed waveform, including the true quiet B breakdown.
        regions=([('A',0,96),('B',96,192),('A_return',192,288)] if self.form=='aba'
                 else [('whole',0,96)])
        if self.form in ('b','aba'):
            base=96 if self.form=='aba' else 0
            regions += [('B_breakdown',base+48,base+64)]
        measurements={}
        with wave.open(str(path),'rb') as f:
            for label,lo,hi in regions:
                first,end=round(lo*BEAT*SR),round(hi*BEAT*SR)
                f.setpos(first); remaining=end-first; energy=0; count=0
                while remaining:
                    size=min(2048,remaining)
                    pcm=np.frombuffer(f.readframes(size),dtype='<i2').astype(np.float64)/32768
                    energy+=float(np.sum(pcm**2)); count+=len(pcm); remaining-=size
                measurements[label]=10*np.log10(energy/count)
        report=self.folder/self.report_name
        data=json.loads(report.read_text(encoding='utf-8'))
        data.update({'form':self.form.upper(),'section_rms_dbfs':measurements,
                     'voice_source':'Original synthesized wordless vowel-formant choir; no human samples or lyrics'})
        report.write_text(json.dumps(data,indent=2)+'\n',encoding='utf-8',newline='\n')


if __name__=='__main__':
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--form',choices=['a','b','aba','all'],default='all')
    args=parser.parse_args()
    for form in (['a','b','aba'] if args.form=='all' else [args.form]):
        score=Tidekeepers(form); score.arrange(); score.render()
