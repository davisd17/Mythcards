"""Vera Kargina — The Snow Keeps Tracks. Far North lo-fi chip folk, A-B-A."""
from pathlib import Path
import argparse
import importlib.util
import json
import wave
import numpy as np

ROOT=Path(__file__).resolve().parents[1]
spec=importlib.util.spec_from_file_location('northern_score_engine',Path(__file__).with_name('compose_flood_survivors_music.py'))
engine=importlib.util.module_from_spec(spec)
spec.loader.exec_module(engine)
engine.BPM=72
engine.BEAT=60/72
SR,BEAT=engine.SR,engine.BEAT
engine.VOICES=[('folk',0,105),('bow',1,42),('reed',2,22),('aurora',3,89),
               ('bass',4,38),('ice',5,10),('drums',9,None)]


class NorthernTracks(engine.Score):
    def __init__(self,form):
        # Reuse only the 4/4 render/master/MIDI mechanics, not another score's notes.
        self.queen=True
        self.form=form
        self.version=1
        self.bars,self.beats=(72 if form=='aba' else 24),4
        self.title='Vera Kargina — The Snow Keeps Tracks: '+form.upper()
        self.name='vera-kargina-snow-keeps-tracks-'+form+'-v1'
        self.folder=ROOT/'outputs/music/vera-kargina'
        self.folder.mkdir(parents=True,exist_ok=True)
        self.report_name='render-info-'+form+'-v1.json'
        self.n=round(self.bars*self.beats*BEAT*SR)
        self.tmp=self.folder/'.render.tmp'
        self.mix=np.memmap(self.tmp,mode='w+',dtype=np.float32,shape=(self.n,2))
        self.mix[:]=0
        self.events=[]

    def note(self,voice,pitch,beat,duration,velocity=.7,pan=0):
        self.events.append((voice,pitch,beat,duration,velocity))
        length=duration*BEAT
        tail={'folk':.24,'bow':.45,'reed':.23,'aurora':.65,'bass':.08,'ice':.38}[voice]
        f=440*2**((pitch-69)/12)
        frames=round((length+tail)*SR)
        for offset in range(0,frames,1024):
            t=np.arange(offset,min(frames,offset+1024))/SR
            absolute=t+beat*BEAT
            phase=2*np.pi*f*t+.014*np.sin(2*np.pi*.31*absolute)
            if voice=='folk':
                # Dark plucked strings, a small pulse-like overtone, no piano FM.
                tone=np.sin(phase)+.23*np.sin(2*phase)*np.exp(-t/.13)
                tone+=.14*np.sin(3*phase)*np.exp(-t/.08)
                tone+=.07*np.sin(5*phase)*np.exp(-t/.04)
                env=np.minimum(t/.0035,1)*np.exp(-t/.38)
                gain=.17
            elif voice=='bow':
                tone=sum(np.sin(h*phase)/h**1.6 for h in range(1,8))
                tone+=.14*np.sin(phase*1.0018)
                env=np.minimum(t/.13,1)*(.92+.08*np.sin(2*np.pi*4.1*t))
                gain=.065
            elif voice=='reed':
                tone=np.sin(phase)+.23*np.sin(3*phase)/3+.09*np.sin(5*phase)/5
                env=np.minimum(t/.025,1)*(.76+.24*np.exp(-t/.18))
                gain=.096
            elif voice=='aurora':
                tone=np.sin(phase+.10*np.sin(2*np.pi*.67*t))
                tone+=.16*np.sin(phase+2*np.pi*.11*t)
                env=np.minimum(t/.48,1)*(.73+.27*np.sin(np.pi*np.minimum(t/max(length,.1),1))**2)
                gain=.026
            elif voice=='bass':
                tone=np.sin(phase)+.11*np.sin(3*phase)/3
                env=np.minimum(t/.010,1)*np.exp(-t/1.2)
                gain=.21
            else:
                # Sparse icy harmonics: warmth stays in the foreground melody.
                tone=np.sin(phase)+.13*np.sin(2.43*phase)*np.exp(-t/.075)
                env=np.minimum(t/.007,1)*np.exp(-t/.26)
                gain=.075
            env*=np.where(t<length,1,np.exp(-(t-length)/(tail/5)))
            sound=(tone*env*gain*velocity).astype(np.float32)
            self.put(sound,beat,pan,offset)
            if voice in ('folk','reed','ice'):
                self.put(sound*.13,beat+.75,-pan*.9,offset)
                self.put(sound*.045,beat+1.5,pan,offset)

    def drum(self,kind,beat,velocity=.7,pan=0):
        t=np.arange(round(.25*SR))/SR
        if kind=='frame':
            phase=2*np.pi*(65*t+32*.020*(1-np.exp(-t/.020)))
            sound=(np.sin(phase+.30*np.exp(-t/.015)*np.sin(2*phase))
                   +.14*np.sin(phase*1.63))*np.exp(-t/.058)*.22
            pitch=41
        elif kind=='wood':
            sound=(np.sin(2*np.pi*231*t)+.29*np.sin(2*np.pi*413*t))*np.exp(-t/.020)*.085
            pitch=76
        else:
            sound=(np.sin(2*np.pi*1417*t)+.24*np.sin(2*np.pi*2191*t))*np.exp(-t/.013)*.029
            pitch=42
        sound*=np.minimum(t/.002,1)
        self.put(sound*velocity,beat,pan)
        self.events.append(('drums',pitch,beat,.12,velocity))

    def section(self,form,start):
        # Open E-minor/C/A-minor/B shapes, not rich lounge voicings or Atlantis choir.
        harmony=[(40,[52,59,67]),(36,[48,55,64]),(33,[45,52,60]),(35,[47,54,63])]
        hook=[[(0,64,.35),(.5,64,.30),(1.25,67,.50),(2,66,.38),(2.75,59,.38),(3.5,62,.35)],
              [(.25,64,.65),(1.5,62,.40),(2.5,59,.75)],
              [(0,64,.35),(.5,64,.30),(1.25,67,.50),(2,66,.38),(2.75,64,.38),(3.5,62,.35)],
              [(.25,60,.65),(1.5,62,.40),(2.5,64,.75)],
              [(0,64,.35),(.5,64,.30),(1.25,69,.50),(2,67,.38),(2.75,64,.38),(3.5,62,.35)],
              [(.25,60,.65),(1.5,59,.40),(2.5,57,.75)],
              [(0,63,.35),(.5,63,.30),(1.25,66,.50),(2,64,.38),(2.75,63,.38),(3.5,59,.35)],
              [(.25,66,.65),(1.5,63,.40),(2.5,59,.75)]]
        for bar in range(24):
            b=start+bar*4
            root,chord=harmony[(bar%8)//2]
            breaking=form=='b' and 12<=bar<16
            quiet=(form=='a' and 16<=bar<20) or breaking
            building=form=='b' and 16<=bar<20
            self.note('bass',root,b,1.15,.75 if not quiet else .46)
            if not breaking:
                self.note('bass',root+7,b+1.5,.65,.47)
                self.note('bass',root+12,b+3,.55,.40)
            # A grounded 3+3+2 eighth-note gait, with dry wood and frame skin.
            if not quiet or bar%2==0:self.drum('frame',b,.82 if not quiet else .45)
            if not quiet:
                self.drum('frame',b+1.5,.49,-.12)
                self.drum('frame',b+3,.64,.08)
                self.drum('wood',b+.75,.46,-.24)
                self.drum('wood',b+2.25,.60,.22)
                if bar%2:self.drum('metal',b+3.5,.42,.3)
                if form=='b' and bar%4==3:
                    self.drum('wood',b+2.75,.34,-.1)
                    self.drum('frame',b+3.75,.41,.15)
            elif bar>=14:self.drum('wood',b+3,.26,.15)
            if bar%2==0:
                for j,p in enumerate(chord[:2]):
                    self.note('bow',p,b,7.45,.49 if not quiet else .37,(-.38,.38)[j])
                self.note('aurora',chord[2],b,7.5,.61,.2)
            # Small picked accompaniment suggests firelight and practical warmth.
            for off,p in [(0,chord[0]+12),(1.5,chord[1]),(3,chord[2]-12)]:
                if quiet and off:continue
                self.note('folk',p,b+off,.25,.31,-.30)
            if form=='a':
                for j,(off,p,dur) in enumerate(hook[bar%8]):
                    if quiet:
                        if j==0:self.note('reed',p-12,b+off,.9,.56,.05)
                    else:
                        self.note('folk',p,b+off,dur,.91 if j in (0,2) else .74,-.07)
                        if 8<=bar<16 and j in (0,2,4):
                            self.note('reed',p-12,b+off+.018,dur,.43,.10)
                if bar%4==3 and not quiet:
                    self.note('ice',chord[1]+24,b+3.25,.36,.36,.38)
            elif breaking:
                self.note('ice',chord[1]+24,b+1.5,.45,.45,.3)
                if bar%2:self.note('bow',chord[2],b+2,.8,.53,-.12)
            elif bar<8:
                pitches=([64,67,71,69,67,66] if bar%2==0 else [67,64,62,59])
                # Transpose replies into the current harmony rather than a scale run.
                if bar>=4:pitches=[p-2 for p in pitches]
                times=[.25,.75,1.5,2,2.75,3.5] if bar%2==0 else [.5,1.25,2.25,3.25]
                for j,(off,p) in enumerate(zip(times,pitches)):
                    if bar>=6:p={62:63,65:66}.get(p,p)
                    self.note('folk',p,b+off,.24 if j%2 else .45,.83,-.18)
                if bar%2:self.note('reed',chord[2]-12,b,.7,.50,.2)
            elif bar<12:
                for off,p,dur in [(0,chord[1],.8),(1.5,chord[2],.65),(2.75,chord[1],.75)]:
                    self.note('bow',p,b+off,dur,.87,-.10)
                for off,p in [(1,chord[2]+12),(3.5,chord[1]+12)]:
                    self.note('folk',p,b+off,.28,.50,.26)
            else:
                for j,(off,p,dur) in enumerate(hook[bar%8]):
                    if building and j%2:continue
                    self.note('folk',p,b+off,dur,.65 if building else .86,-.07)
                if bar%2 and bar<22:
                    self.note('reed',chord[2]-12,b+3,.48,.45,.24)

    def arrange(self):
        for i,form in enumerate(['a','b','a'] if self.form=='aba' else [self.form]):
            self.section(form,i*96)

    def render(self):
        super().render()
        regions=([('A',0,96),('B',96,192),('A_return',192,288)]
                 if self.form=='aba' else [('whole',0,96)])
        if self.form in ('b','aba'):
            base=96 if self.form=='aba' else 0
            regions.append(('B_breakdown',base+48,base+64))
        levels={}
        with wave.open(str(self.folder/(self.name+'.wav')),'rb') as f:
            for label,lo,hi in regions:
                first,end=round(lo*BEAT*SR),round(hi*BEAT*SR)
                f.setpos(first); remaining=end-first; energy=count=0
                while remaining:
                    size=min(2048,remaining)
                    block=np.frombuffer(f.readframes(size),dtype='<i2').astype(np.float64)/32768
                    energy+=float(np.sum(block**2)); count+=len(block); remaining-=size
                levels[label]=10*np.log10(energy/count)
        report=self.folder/self.report_name
        data=json.loads(report.read_text(encoding='utf-8'))
        data.update({'form':self.form.upper(),'section_rms_dbfs':levels,
                     'character':'Vera Kargina / Meteor Spear, Far North',
                     'status':'Approved October 30, 2026; exact-name/Far North music fallback prepared; playable roster entry still pending'})
        report.write_text(json.dumps(data,indent=2)+'\n',encoding='utf-8',newline='\n')


if __name__=='__main__':
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--form',choices=['a','b','aba','all'],default='all')
    args=parser.parse_args()
    for form in (['a','b','aba'] if args.form=='all' else [args.form]):
        score=NorthernTracks(form); score.arrange(); score.render()
