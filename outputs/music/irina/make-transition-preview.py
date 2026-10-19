"""Audition A's last eight bars -> full B -> A's first eight bars, no grid shift."""
from pathlib import Path
import wave
import numpy as np

OUT = Path(__file__).resolve().parent
with wave.open(str(OUT/'irina-private-favors-a-v2.wav'),'rb') as a:
    count = a.getnframes()
    sr = a.getframerate()
bar8 = round(8*4*60/69*sr)
bar16 = round(16*4*60/69*sr)
parts = [('irina-private-favors-a-v2.wav',bar16,count),
         ('irina-private-favors-b-v1.wav',0,count),
         ('irina-private-favors-a-v2.wav',0,bar8)]
last_frame = None
with wave.open(str(OUT/'irina-a-b-a-transition-preview.wav'),'wb') as output:
    output.setparams((2,2,sr,0,'NONE','not compressed'))
    for filename,start,end in parts:
        with wave.open(str(OUT/filename),'rb') as source:
            assert (source.getnchannels(),source.getsampwidth(),source.getframerate())==(2,2,sr)
            source.setpos(start)
            remaining=end-start
            first=True
            while remaining:
                frames=min(1024,remaining)
                block=np.frombuffer(source.readframes(frames),dtype='<i2').reshape(-1,2).copy()
                if first and last_frame is not None:
                    n=min(128,len(block))
                    offset=last_frame.astype(float)-block[0].astype(float)
                    adjusted=block[:n].astype(float)+np.linspace(1,0,n)[:,None]*offset
                    block[:n]=np.clip(np.rint(adjusted),-32768,32767).astype('<i2')
                output.writeframes(block.tobytes())
                last_frame=block[-1].copy()
                first=False
                remaining-=frames
print('Created 139-second A -> B -> A transition audition.')
