import os
import shutil
import time
from enum import Enum
from PIL import Image
from google import genai
from google.genai import types
from google.genai.errors import APIError

api_key = os.environ.get("GEMINI_API_KEY")
client = genai.Client(api_key=api_key)

RAW_PCB_DIR = "../datasets/raw_data/unsorted_pcbs"
DEST_HIGH = "../datasets/images/train/MOTHERBOARD_HIGH_GRADE"
DEST_LOW = "../datasets/images/train/POWER_SUPPLY_LOW_GRADE"
DEST_REJECT = "../datasets/images/train/REJECTED_NOISE"

os.makedirs(DEST_HIGH, exist_ok=True)
os.makedirs(DEST_LOW, exist_ok=True)
os.makedirs(DEST_REJECT, exist_ok=True)

class ScrapGrade(str, Enum):
    HIGH_GRADE = "HIGH_GRADE"
    LOW_GRADE = "LOW_GRADE"
    REJECT = "REJECT"

SYSTEM_PROMPT = """
You are an expert industrial e-waste scrap grader. Classify the electronic circuit board in the image into exactly ONE category:

1. HIGH_GRADE:
   - Green, blue, or black multi-layer FR-4 fiberglass substrate.
   - Flat black integrated circuits (IC chips, microcontrollers, BGAs, QFPs, SoCs, RAM, flash memory).
   - Computing, telecom, remote, sensor, or audio logic boards (e.g. mice, walkie-talkies, routers, motherboards).
   - NOTE: Small round copper or yellow toroidal choke coils DO NOT make it low grade if SMD chips are present.

2. LOW_GRADE:
   - Heavy switched-mode power supplies (SMPS), charger bricks, or appliance power boards.
   - Single-sided brown/yellow/tan phenolic paper (FR-2) substrate.
   - Bulky yellow-tape wrapped cube transformers (e.g. PGSA2Z), large iron-core magnetic blocks, thick aluminum heat sinks.
   - Dominated by through-hole wire jumpers, thick diodes, and large capacitors with virtually no flat silicon ICs.

3. REJECT:
   - Extreme occlusion by human hands/fingers covering >35% of the board.
   - Severe blur, empty plastic shells, or non-PCB objects.
"""

valid_exts = {".jpg", ".jpeg", ".png", ".webp"}
images = [f for f in sorted(os.listdir(RAW_PCB_DIR)) if os.path.splitext(f.lower())[1] in valid_exts]

print(f"Starting classification for {len(images)} images...\n")

for i, fname in enumerate(images, 1):
    src_path = os.path.join(RAW_PCB_DIR, fname)
    success = False
    retries = 0

    while not success and retries < 4:
        try:
            pil_img = Image.open(src_path)

            response = client.models.generate_content(
                model="gemini-2.5-flash",
                contents=[pil_img, SYSTEM_PROMPT],
                config=types.GenerateContentConfig(
                    response_mime_type="text/x.enum",
                    response_schema=ScrapGrade,
                    thinking_config=types.ThinkingConfig(thinking_budget=0)
                )
            )

            decision = (response.text or "").strip()

            if decision == "HIGH_GRADE":
                target = os.path.join(DEST_HIGH, fname)
                category = "HIGH_GRADE"
            elif decision == "LOW_GRADE":
                target = os.path.join(DEST_LOW, fname)
                category = "LOW_GRADE"
            else:
                target = os.path.join(DEST_REJECT, fname)
                category = "REJECTED"

            shutil.move(src_path, target)
            print(f"[{i:3d}/{len(images)}] {fname} ➔ {category}")
            success = True

            # Delay for 5 RPM limit
            time.sleep(12.5)

        except APIError as e:
            if "429" in str(e) or "RESOURCE_EXHAUSTED" in str(e) or "503" in str(e):
                retries += 1
                wait_time = 25 * retries
                print(f"[{i:3d}/{len(images)}] Temporary API limit/spike, cooling down for {wait_time}s...")
                time.sleep(wait_time)
            else:
                print(f"[{i:3d}/{len(images)}] API Error on {fname}: {e}")
                break
        except Exception as e:
            print(f"[{i:3d}/{len(images)}] Error on {fname}: {e}")
            break

print("\n--- Auto-sorting Complete ---")
print(f"High-Grade: {len(os.listdir(DEST_HIGH))}")
print(f"Low-Grade:  {len(os.listdir(DEST_LOW))}")
print(f"Rejected:   {len(os.listdir(DEST_REJECT))}")
