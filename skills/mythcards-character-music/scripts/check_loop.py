"""Stream-check a 16-bit PCM WAV loop using only the Python standard library."""
import argparse
from array import array
import json
import math
from pathlib import Path
import sys
import wave


def check(path, bpm=None, bars=None, beats_per_bar=4, reference=None,
          require_loop=False, max_seam_step=32):
    problems = []
    with wave.open(str(path), 'rb') as source:
        channels, width, rate, frames, compression, _ = source.getparams()
        if width != 2 or compression != 'NONE':
            raise ValueError('Expected uncompressed 16-bit PCM WAV')
        if not frames:
            raise ValueError('WAV contains no frames')
        peak = clipped = count = energy = 0
        first = last = None
        while data := source.readframes(4096):
            samples = array('h')
            samples.frombytes(data)
            if sys.byteorder != 'little':
                samples.byteswap()
            if first is None:
                first = list(samples[:channels])
            last = list(samples[-channels:])
            peak = max(peak, max(samples), -min(samples))
            clipped += sum(s == 32767 or s == -32768 for s in samples)
            energy += sum(s*s for s in samples)
            count += len(samples)
    seam = max(abs(a-b) for a,b in zip(first,last))
    if not peak:
        problems.append('Audio is silent')
    if clipped:
        problems.append(f'{clipped} full-scale samples')
    if require_loop and seam > max_seam_step:
        problems.append(f'Endpoint step {seam} exceeds {max_seam_step}')
    if bpm is not None or bars is not None:
        if bpm is None or bars is None or min(bpm,bars,beats_per_bar) <= 0:
            raise ValueError('Supply positive --bpm and --bars together')
        expected = round(bars*beats_per_bar*60/bpm*rate)
        if frames != expected:
            problems.append(f'Frame count {frames} differs from musical target {expected}')
    if reference:
        with wave.open(str(reference), 'rb') as other:
            # Compare durations as rational numbers, allowing half a current sample.
            difference = abs(frames/rate-other.getnframes()/other.getframerate())
            if difference > .5/rate:
                problems.append('Duration differs from reference by more than half a sample')
    return {'path': str(Path(path).resolve()), 'seconds': frames/rate,
            'frames': frames, 'sample_rate': rate, 'channels': channels,
            'peak_dbfs': 20*math.log10(peak/32768) if peak else None,
            'rms_dbfs': 10*math.log10(energy/count/(32768**2)) if energy else None,
            'clipped_samples': clipped, 'endpoint_step': seam,
            'passed': not problems, 'problems': problems}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('wav', type=Path)
    parser.add_argument('--bpm', type=float)
    parser.add_argument('--bars', type=int)
    parser.add_argument('--beats-per-bar', type=int, default=4)
    parser.add_argument('--compare-length', type=Path)
    parser.add_argument('--require-loop', action='store_true')
    parser.add_argument('--max-seam-step', type=int, default=32)
    args = parser.parse_args()
    try:
        result = check(args.wav,args.bpm,args.bars,args.beats_per_bar,
                       args.compare_length,args.require_loop,args.max_seam_step)
    except (OSError,ValueError,wave.Error,EOFError) as exc:
        print(json.dumps({'passed': False, 'error': str(exc)}))
        return 1
    print(json.dumps(result, indent=2))
    return 0 if result['passed'] else 1


if __name__ == '__main__':
    raise SystemExit(main())
