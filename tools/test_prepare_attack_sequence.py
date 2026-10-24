"""Focused regression checks for attack and claim packaging."""

import contextlib
import io
import json
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch

from PIL import Image, ImageDraw
import prepare_attack_sequence as packer


class SequencePackagingTests(unittest.TestCase):
    def check_kind(self, kind, poses, holds):
        with tempfile.TemporaryDirectory(prefix=".sequence-test-", dir=packer.ROOT) as directory:
            root = Path(directory)
            output = root / "game/assets/figures/test-character"
            output.mkdir(parents=True)
            sprite = Image.new("RGBA", (512, 768))
            ImageDraw.Draw(sprite).rectangle((170, 30, 340, 756), fill="white")
            sprite.save(output / "default.png")
            manifest = root / "sources.json"
            manifest.write_text(json.dumps({pose: "game/assets/figures/test-character/default.png" for pose in poses}))
            argv = ["packer", "test-character", str(manifest)]
            if kind != "attack":
                argv += ["--kind", kind]
            with patch.object(packer, "ROOT", root), patch("sys.argv", argv), contextlib.redirect_stdout(io.StringIO()):
                packer.main()
            folder = {"attack": "attack-art", "claim": "ember-claim", "transform": "form-change"}[kind]
            review = root / "docs/art-specs" / folder / "test-character"
            registration = json.loads((review / "registration.json").read_text())
            self.assertEqual([f["pose"] for f in registration["frames"]], poses)
            self.assertEqual([f["ms"] for f in registration["frames"]], holds)
            self.assertEqual(len(list(output.glob(f"{kind}-*.png"))), len(poses))
            self.assertTrue((review / f"test-character-{kind}.ora").exists())
            with Image.open(review / f"{kind}-preview.gif") as gif:
                duration = 0
                for index in range(gif.n_frames):
                    gif.seek(index)
                    duration += gif.info["duration"]
                self.assertEqual(duration, 600)

    def test_attack_default_unchanged(self):
        self.check_kind("attack", packer.POSES, packer.HOLDS)

    def test_three_pose_claim(self):
        self.check_kind("claim", ["gather", "hold", "settle"], [120, 360, 120])

    def test_three_pose_transform(self):
        self.check_kind("transform", ["awaken", "manifest", "seraph"], [150, 200, 250])


if __name__ == "__main__":
    unittest.main()
