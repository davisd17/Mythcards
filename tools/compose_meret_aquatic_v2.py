"""Meret-Anu — Pearl Current: the Queen's own aquatic lo-fi listening groove."""
from pathlib import Path
import importlib.util
import numpy as np

SOURCE=Path(__file__).with_name('compose_flood_survivors_music.py')
spec=importlib.util.spec_from_file_location('flood_score',SOURCE)
engine=importlib.util.module_from_spec(spec)
spec.loader.exec_module(engine)
SR,BEAT=engine.SR,engine.BEAT
engine.VOICES=engine.VOICES+[('keys',6,4),('liquid',7,10)]


class PearlCurrent(engine.Score):
    def __init__(self):
        super().__init__(True)
        self.name='meret-anu-pearl-current-a-v2'
        self.title='Meret-Anu — Pearl Current'
        self.version=2
        self.rng=np.random.default_rng(26102026)

    def note(self,voice,pitch,beat,duration,velocity=.7,pan=0):
        if voice not in ('keys','liquid'):
            return super().note(voice,pitch,beat,duration,velocity,pan)
        self.events.append((voice,pitch,beat,duration,velocity))
        length=duration*BEAT
        tail=.5 if voice=='keys' else .35
        frames=round((length+tail)*SR)
        f=440*2**((pitch-69)/12)
        for offset in range(0,frames,1024):
            t=np.arange(offset,min(frames,offset+1024))/SR
            absolute=t+beat*BEAT
            phase=2*np.pi*f*t+.018*np.sin(2*np.pi*.23*absolute)
            if voice=='keys':
                tone=np.sin(phase+.52*np.exp(-t/.13)*np.sin(2*phase))
                tone+=.10*np.sin(2*phase)*np.exp(-t/.28)
                tone=np.tanh(tone*1.2)*.86
                env=np.minimum(t/.007,1)*(.8*np.exp(-t/1.8)+.2*np.exp(-t/.19))
                # A light breathing motion around the kick, never a hard pump.
                q=(t/BEAT+beat)%4
                env*=1-.13*np.exp(-q/.13)-.10*np.exp(-((q-2.65)%4)/.13)
                gain=.13
            else:
                phase+=.12*(1-np.exp(-t/.014))
                tone=np.sin(phase+.67*np.exp(-t/.065)*np.sin(2*phase))
                env=np.minimum(t/.004,1)*np.exp(-t/.34)
                gain=.12
            env*=np.where(t<length,1,np.exp(-(t-length)/(tail/5)))
            sound=(tone*env*gain*velocity).astype(np.float32)
            self.put(sound,beat,pan,offset)
            self.put(sound*(.19 if voice=='liquid' else .09),beat+.75,-pan*.9,offset)
            self.put(sound*.07,beat+1.5,pan,offset)

    def drum(self,kind,beat,velocity=.7):
        t=np.arange(round(.25*SR))/SR
        if kind=='skin':
            phase=2*np.pi*(47*t+48*.018*(1-np.exp(-t/.018)))
            sound=np.tanh(1.4*np.sin(phase))*np.exp(-t/.075)*.24
            pitch=36
        elif kind=='stone':
            # A compact rim/brush backbeat; noise ends quickly, with no fuzzy bed.
            noise=self.rng.uniform(-1,1,len(t))
            brush=np.convolve(noise,np.ones(7)/7,mode='same')
            sound=(np.sin(2*np.pi*178*t)+.3*np.sin(2*np.pi*347*t))*np.exp(-t/.021)*.072
            sound+=brush*np.exp(-t/.018)*.10
            pitch=37
        else:
            sound=(np.sin(2*np.pi*2203*t)+.23*np.sin(2*np.pi*3431*t))*np.exp(-t/.009)*.016
            pitch=42
        sound*=np.minimum(t/.002,1)
        self.put(sound*velocity,beat,.25 if kind=='shell' else -.04)
        self.events.append(('drums',pitch,beat,.12,velocity))

    def arrange(self):
        # Open ninths and thirteenths give her space to enjoy the music.
        # Dm9 -> G13 -> Cmaj9 -> Fmaj9; shared Atlantean color without a march.
        harmony=[(38,[53,57,60,64]),(43,[53,57,59,64]),
                 (36,[52,55,59,62]),(41,[57,60,64,67])]
        hook=[[(.18,65,.27),(.68,69,.30),(1.18,67,.55),(2.18,64,.27),(2.68,62,.95)],
              [(.68,65,.3),(1.18,64,.3),(1.68,62,.8),(3.18,57,.45)],
              [(.18,65,.27),(.68,69,.30),(1.18,67,.55),(2.18,64,.27),(2.68,62,.95)],
              [(.68,64,.3),(1.18,62,.3),(1.68,59,.8),(3.18,62,.45)],
              [(.18,64,.27),(.68,67,.30),(1.18,65,.55),(2.18,62,.27),(2.68,59,.95)],
              [(.68,62,.3),(1.18,64,.3),(1.68,67,.8),(3.18,64,.45)],
              [(.18,65,.27),(.68,69,.30),(1.18,67,.55),(2.18,64,.27),(2.68,62,.95)],
              [(.68,64,.3),(1.18,62,.3),(1.68,60,.8),(3.18,64,.45)]]
        for bar in range(24):
            b=bar*4
            root,chord=harmony[(bar%8)//2]
            hush=16<=bar<20
            next_root=harmony[((bar%8)//2+1)%4][0]
            pickup=next_root-1 if bar%2 else root+7
            for off,p,duration,v in [(0,root,1.2,.83),(1.68,root+7,.35,.45),
                                      (2.65,root+12,.58,.57),(3.68,pickup,.23,.35)]:
                if hush and off in (1.68,3.68): continue
                self.note('bass',p,b+off,duration,v)
            self.drum('skin',b,.62 if hush else .87)
            if not hush:
                self.drum('skin',b+2.65,.60)
                if bar%4==3: self.drum('skin',b+3.5,.31)
            for off in (1.035,3.035): self.drum('stone',b+off,.35 if hush else .76)
            for j in range(8):
                if hush and j%2: continue
                self.drum('shell',b+j*.5+(.075 if j%2 else 0),.48 if j%2 else .24)
            for off,duration,v in [(0,1.45,.57),(2.65,.85,.37)]:
                if hush and off: continue
                for j,p in enumerate(chord):
                    self.note('keys',p,b+off+j*.016,duration,v,(-.30 if j%2 else .24))
            if bar%2==0:
                for j,p in enumerate((chord[0],chord[2])):
                    self.note('pad',p,b,7.5,.46,(-.44,.44)[j])
            for off,p,duration in hook[bar%8]:
                if hush:
                    if off in (.18,1.68): self.note('liquid',p-12,b+off,duration,.64,.08)
                else:
                    self.note('keys',p,b+off,duration,.9 if off in (.18,1.18,1.68) else .77,-.08)
                    if bar%2==0 and off==.68:
                        self.note('liquid',p,b+off+.025,.28,.39,.32)
            if not hush and bar%2:
                for off,p in [(2.68,chord[1]+12),(3.68,chord[2]+12)]:
                    self.note('liquid',p,b+off,.3,.45,.33)
            # Thin plucked details suggest reflections; never a ceremonial fanfare.
            if bar in (3,11,23):
                self.note('harp',chord[2]+12,b+2.18,.24,.32,-.25)


if __name__=='__main__':
    score=PearlCurrent()
    score.arrange()
    score.render()
