from __future__ import annotations

from pathlib import Path

VIDEO_EXTENSIONS = {".mp4", ".mkv", ".webm", ".avi", ".mov"}
IMAGE_EXTENSIONS = {".jpg", ".jpeg", ".png", ".webp", ".tif", ".tiff", ".gif"}
VALID_WALLPAPER_EXTENSIONS = VIDEO_EXTENSIONS | IMAGE_EXTENSIONS


def is_video_file(path: str | Path) -> bool:
    return Path(path).suffix.lower() in VIDEO_EXTENSIONS


def should_regenerate_cache(source: str | Path, cache: str | Path) -> bool:
    source_path = Path(source)
    cache_path = Path(cache)

    if not source_path.exists():
        return False

    if not cache_path.exists():
        return True

    try:
        return source_path.stat().st_mtime_ns > cache_path.stat().st_mtime_ns
    except OSError:
        return True
