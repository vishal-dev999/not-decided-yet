import os
from pathlib import Path

os.environ.setdefault("DATABASE_URL", "sqlite:///./data/test_kabadiwala.db")
os.environ.setdefault("SEED_ON_STARTUP", "true")
os.environ.setdefault("APP_DEBUG", "false")

Path("data").mkdir(parents=True, exist_ok=True)
