"""Render revision 2 Ember stings: distinct materials, minimal shared noise."""
from pathlib import Path
import argparse
import hashlib
import json
import wave
import numpy as np

ROOT = Path(__file__).resolve().parents[1]
RATE = 44100
# IDs and wording are checked against the approved line source, never rewritten.
BRIEFS = {
    'r-reactor-worker': (.55, 'Ringing wrench tap, restrained steam puff, warm pipe resonance'),
    'r-vera-7': (.65, 'Clean telemetry chirps, tonal servo motion and confirmation click'),
    'r-yuri-volkov': (.60, 'Dry pressure-seal clunk and two precise instrument clicks'),
    'r-irina-karpova': (.45, 'Pen-like metal click and muted low brass punctuation'),
    'r-mikhail-orlov': (.75, 'Needle tick and smooth reactor-hum swell'),
    'r-elena-morozova': (.75, 'Brief radio catch resolving into a clear glass chime'),
    'r-zoya-miranova': (.70, 'A distinctive short static flutter into an eerie tonal breath'),
    'a-flood-survivor-stone-line-laborer': (.60, 'Dry stone knock and separate little grit taps'),
    'a-flood-survivor-ahesu': (.85, 'Deep rolling vessel resonance and low water burbles'),
    'a-flood-survivor-naia': (.70, 'Shield-metal contact, stone resonance and low drum'),
    'a-flood-survivor-meret-anu': (.75, 'Smooth rising tidal tones and a bronze latch'),
    'a-flood-survivor-sahu-ren': (.80, 'Clear wooden-reed tone with layered echoes'),
    'a-flood-survivor-iset-nara': (.65, 'Clear fifth-interval chimes and a low sliding resonance'),
    'a-flood-survivor-thalassa-nekh': (.90, 'Non-syllabic submerged choir-like pad and rising bubbles'),
}


def synth(character, seconds):
    n = round(seconds*RATE)
    t = np.arange(n)/RATE
    out = np.zeros(n)
    seed = int.from_bytes(hashlib.sha256(character.encode()).digest()[:4], 'big')
    noise = np.random.default_rng(seed).uniform(-1,1,n)

    def tone(f, start=0, level=.3, decay=.12, harmonics=(1,), glide=0, attack=.002):
        u = np.maximum(t-start,0)
        phase = 2*np.pi*(f*u+glide*u*u/2)
        signal = sum(np.sin(phase*h)/h**1.5 for h in harmonics)
        env = (t>=start)*np.minimum(u/attack,1)*np.exp(-u/decay)
        out[:] += signal*env*level

    def air(start, length, level, smooth=13):
        u = np.maximum(t-start,0)/length
        env = np.where((t>=start)&(u<1), np.sin(np.pi*np.minimum(u,1))**.7, 0)
        texture = np.convolve(noise,np.ones(smooth)/smooth,mode='same')
        out[:] += texture*env*level

    if character == 'r-reactor-worker':
        tone(1120,level=.30,decay=.065); tone(1711,level=.13,decay=.039)
        tone(2527,level=.05,decay=.020); tone(140,level=.22,decay=.17)
        air(.025,.095,.11,29)
    elif character == 'r-vera-7':
        tone(620,level=.28,decay=.045); tone(930,.09,.24,.05)
        tone(1240,.18,.18,.045); tone(190,.025,.18,.16,glide=480)
        tone(1050,.30,.14,.012)
    elif character == 'r-yuri-volkov':
        tone(82,level=.44,decay=.10); tone(193,level=.19,decay=.027)
        tone(347,level=.10,decay=.018)
        tone(1650,.12,.13,.009); tone(1410,.25,.11,.009)
    elif character == 'r-irina-karpova':
        tone(1160,level=.17,decay=.009); tone(1730,.006,.08,.012)
        tone(146.83,.015,.39,.14,(1,2,3),attack=.008)
        tone(220,.025,.15,.13,attack=.009)
    elif character == 'r-mikhail-orlov':
        tone(1720,level=.14,decay=.008)
        tone(110,.008,.33,.25,attack=.035)
        tone(220,.010,.095,.21,attack=.025)
        tone(430,.31,.12,.09)
    elif character == 'r-elena-morozova':
        air(0,.075,.20,7); tone(217,level=.14,decay=.12,glide=-100)
        tone(660,.14,.31,.16); tone(990,.145,.10,.11)
        tone(664,.16,.10,.15)
    elif character == 'r-zoya-miranova':
        air(0,.10,.23,5); air(.12,.16,.11,37)
        tone(320,.01,.21,.22,glide=-120); tone(487,.09,.10,.18)
        tone(492,.10,.05,.17)
    elif character == 'a-flood-survivor-stone-line-laborer':
        tone(135,level=.43,decay=.085); tone(229,level=.20,decay=.035)
        tone(83,.008,.18,.17)
        for start,f,level in [(.11,410,.10),(.17,283,.075),(.24,351,.05)]:
            tone(f,start,level,.011)
    elif character == 'a-flood-survivor-ahesu':
        tone(63,level=.32,decay=.29,glide=-16)
        tone(94,level=.25,decay=.24); tone(157,level=.12,decay=.19)
        tone(142,.16,.16,.075,glide=-550)
        tone(181,.34,.10,.060,glide=-730)
    elif character == 'a-flood-survivor-naia':
        tone(388,level=.22,decay=.095); tone(613,level=.15,decay=.065)
        tone(1009,level=.085,decay=.035)
        tone(88,.008,.32,.17); tone(69,.025,.22,.13)
    elif character == 'a-flood-survivor-meret-anu':
        tone(130,level=.28,decay=.24,glide=110)
        tone(195,.008,.14,.23,glide=165)
        tone(731,.44,.22,.024); tone(1079,.445,.09,.026)
    elif character == 'a-flood-survivor-sahu-ren':
        for start, level in [(0,.29),(.17,.12),(.34,.055)]:
            tone(293.66,start,level,.17,(1,2,3),attack=.009)
    elif character == 'a-flood-survivor-iset-nara':
        tone(330,level=.27,decay=.14); tone(495,.10,.25,.14)
        tone(990,.103,.065,.08)
        tone(140,.22,.16,.12,glide=-260)
    else:
        for f in (220,277.18,330):
            tone(f,level=.15,decay=.28)
        for start,f in [(.16,410),(.31,520),(.48,670)]:
            tone(f,start,.09,.035,glide=1200,attack=.003)

    # Avoid DC, clicks and cut-off tails. All starts have an audible immediate cue.
    out -= out.mean()
    out[:88] *= np.linspace(0,1,88)
    tail = round(.025*RATE)
    out[-tail:] *= np.linspace(1,0,tail)**2
    out *= min(.79/np.max(np.abs(out)), .24/np.sqrt(np.mean(out**2)))
    return np.rint(out*32767).astype('<i2')


def inspect(path):
    with wave.open(str(path),'rb') as f:
        channels,width,rate,frames,compression,_ = f.getparams()
        pcm = np.frombuffer(f.readframes(frames),dtype='<i2').astype(np.int32)
    assert (channels,width,rate,compression)==(1,2,RATE,'NONE'), path
    assert .4 <= frames/rate <= .9, path
    peak = int(np.max(np.abs(pcm)))
    assert 0<peak<=round(32767*10**(-1/20)), path
    assert pcm[0]==0 and pcm[-1]==0, path
    audible = np.flatnonzero(np.abs(pcm)>peak*.01)
    assert len(audible) and audible[0]/rate <= .010, path
    return {'seconds':frames/rate,'peak_dbfs':float(20*np.log10(peak/32768)),
            'rms_dbfs':float(20*np.log10(np.sqrt(np.mean((pcm/32768)**2)))),
            'attack_ms':float(audible[0]/rate*1000),'tail_sample':int(pcm[-1]),
            'sha256':hashlib.sha256(path.read_bytes()).hexdigest()}


def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--check',action='store_true',help='Verify existing files without changing them')
    args=parser.parse_args()
    lines=json.loads((ROOT/'data/ember_lines.json').read_text(encoding='utf-8'))
    assert set(lines)==set(BRIEFS), 'Sound roster differs from approved line roster'
    review=ROOT/'outputs/ember-claim'
    review.mkdir(parents=True,exist_ok=True)
    report={}
    for character,(seconds,direction) in BRIEFS.items():
        path=ROOT/'game/assets/sfx'/character/'claim.wav'
        if not args.check:
            path.parent.mkdir(parents=True,exist_ok=True)
            with wave.open(str(path),'wb') as f:
                f.setparams((1,2,RATE,0,'NONE','not compressed'))
                f.writeframes(synth(character,seconds).tobytes())
        report[character]=inspect(path)
        report[character]['revision']=2
        if not args.check:
            source=ROOT/'docs/art-specs/ember-claim'/character/'AUDIO_SOURCE.md'
            source.parent.mkdir(parents=True,exist_ok=True)
            source.write_text(f'# Ember claim audio — {character}\n\n'
                f'Status: revision 2 sound candidate; listening review pending.\n\n'
                'Revision: removed the shared noise wash. Static is limited to Elena '
                'and Zoya, with only a very small steam puff for Reactor Worker; '
                'other characters use clean tonal/material-specific synthesis.\n\n'
                f'Direction: {direction}.\n\n'
                'Original procedural synthesis by Codex for MythCards. No recordings, '
                'external samples, third-party music, voice, or spoken words. No external '
                'sample licence is required. Source: `tools/synthesize_ember_claims.py` '
                '(Python and numpy; deterministic per-character seed).\n\n'
                f'Runtime: `game/assets/sfx/{character}/claim.wav`. '
                f'Mono, 44.1 kHz, 16-bit PCM, {seconds:.2f} s. '
                'Same sting for normal and big claims; Sound setting controls playback.\n\n'
                'Approved text remains verbatim in `data/ember_lines.json`; this asset '
                'does not speak or modify it. Art approval is tracked separately.\n',encoding='utf-8',newline='\n')
    if not args.check:
        (review/'audio-report.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8',newline='\n')
        cursor=0
        index=['# Ember claim audio review','',
               'Fourteen original nonverbal candidates, in the order below. Each gap is 0.45 seconds.',
               'All use the same runtime sting for normal and big claims. Listening review is pending.',
               '', '| Start | Character | Sound |','| --- | --- | --- |']
        with wave.open(str(review/'audio-review.wav'),'wb') as reel:
            reel.setparams((1,2,RATE,0,'NONE','not compressed'))
            for character,(_,direction) in BRIEFS.items():
                with wave.open(str(ROOT/'game/assets/sfx'/character/'claim.wav'),'rb') as f:
                    data=f.readframes(f.getnframes())
                index.append(f'| {cursor/RATE:.2f} s | `{character}` | {direction} |')
                reel.writeframes(data)
                reel.writeframes(bytes(round(.45*RATE)*2))
                cursor+=len(data)//2+round(.45*RATE)
        (review/'AUDIO_INDEX.md').write_text('\n'.join(index)+'\n',encoding='utf-8',newline='\n')
        # A versioned preview avoids stale playback caches; v1 is archived separately.
        (review/'audio-review-v2.wav').write_bytes((review/'audio-review.wav').read_bytes())
    print(json.dumps({'verified_stings':len(report),'report':report},indent=2))


if __name__=='__main__':
    main()
