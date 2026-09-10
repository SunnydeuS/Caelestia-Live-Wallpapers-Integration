import os
import tempfile
import unittest
from pathlib import Path

from video_cache import is_video_file, should_regenerate_cache


class VideoCacheTest(unittest.TestCase):
    def test_is_video_file_accepts_video_extensions(self):
        self.assertTrue(is_video_file(Path("example.mp4")))
        self.assertTrue(is_video_file(Path("example.mkv")))
        self.assertTrue(is_video_file(Path("example.webm")))
        self.assertFalse(is_video_file(Path("example.jpg")))

    def test_should_regenerate_cache_when_thumbnail_missing(self):
        with tempfile.TemporaryDirectory() as tmp:
            source = Path(tmp) / "clip.mp4"
            thumb = Path(tmp) / "clip.jpg"
            source.write_bytes(b"video")

            self.assertTrue(should_regenerate_cache(source, thumb))

    def test_should_regenerate_cache_when_source_is_newer(self):
        with tempfile.TemporaryDirectory() as tmp:
            source = Path(tmp) / "clip.mp4"
            thumb = Path(tmp) / "clip.jpg"
            source.write_bytes(b"video")
            thumb.write_bytes(b"old")

            source_ts = 2000
            thumb_ts = 1000
            os.utime(source, (source_ts, source_ts))
            os.utime(thumb, (thumb_ts, thumb_ts))

            self.assertTrue(should_regenerate_cache(source, thumb))

    def test_should_not_regenerate_cache_when_thumbnail_is_fresh(self):
        with tempfile.TemporaryDirectory() as tmp:
            source = Path(tmp) / "clip.mp4"
            thumb = Path(tmp) / "clip.jpg"
            source.write_bytes(b"video")
            thumb.write_bytes(b"thumb")

            self.assertFalse(should_regenerate_cache(source, thumb))


if __name__ == "__main__":
    unittest.main()
