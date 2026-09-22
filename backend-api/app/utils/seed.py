"""Seed CPCB-style recyclers, materials, CSV-backed prices, safety cards, and demo users."""

from __future__ import annotations

import csv
import hashlib
import os
import uuid
from datetime import datetime, timedelta, timezone

from sqlalchemy.orm import Session

from app.core.security import hash_password
from app.models.entities import (
    Collector,
    Material,
    PriceHistory,
    PriceQuote,
    Recycler,
    SafetyCard,
)

MATERIALS = [
    ("MOTHERBOARD_HIGH_GRADE", "High Grade PCB", "हाई-ग्रेड मदरबोर्ड (पीसीबी)", "हाय-ग्रेड मदरबोर्ड (पीसीबी)", "ITEW2", False, "chip"),
    ("POWER_SUPPLY_LOW_GRADE", "Low Grade PCB", "लो-ग्रेड पीसीबी (एसएमपीएस)", "लो-ग्रेड पीसीबी (एसएमपीएस)", "ITEW2", False, "chip"),
    ("BATTERY_LITHIUM_PORTABLE", "Lithium Batteries", "लिथियम-आयन बैटरी", "लिथियम-आयन बॅटरी", "BATT", True, "battery"),
    ("LEAD_ACID", "Lead Batteries", "लेड-एसिड बैटरी", "लेड-अ‍ॅसिड बॅटरी", "BATT", True, "battery"),
    ("CRT_MONITOR", "CRT Monitors", "सीआरटी मॉनिटर", "सीआरटी मॉनिटर", "CEEW1", True, "glass"),
    ("LCD_PANEL_INTACT", "LCD/LED Flat Panel", "एलसीडी/एलईडी डिस्प्ले", "एलसीडी/एलईडी डिस्प्ले", "CEEW1", False, "glass"),
    ("MIXED_EWASTE_CASING", "Mixed Plastic", "मिश्रित ई-कचरा प्लास्टिक", "मिश्र ई-कचरा प्लास्टिक", "ITEW", False, "plastic"),
    ("COPPER_HEAVY_INSULATED", "Copper Wire", "तांबे का तार", "तांब्याची तार", "ITEW", False, "wire"),
    ("ALUMINIUM_WIRE", "Aluminium Wire", "एल्युमिनियम तार", "अ‍ॅल्युमिनियम तार", "ITEW", False, "wire"),
]

SAFETY = [
    dict(
        code="ppe",
        title_en="Wear gloves and a mask",
        title_hi="दस्ताने और मास्क पहनें",
        title_mr="हातमोजे आणि मास्क घाला",
        body_en="Never handle broken batteries or circuit boards with bare hands. Use gloves and a cloth mask.",
        body_hi="टूटी बैटरी या सर्किट बोर्ड नंगे हाथ न छुएँ। दस्ताने और कपड़े का मास्क पहनें।",
        body_mr="तुटलेल्या बॅटरी किंवा सर्किट बोर्ड नुसत्या हातांनी हाताळू नका. हातमोजे आणि मास्क वापरा.",
        pictogram="gloves",
        sort_order=1,
    ),
    dict(
        code="batteries",
        title_en="Keep batteries dry and separate",
        title_hi="बैटरी सूखी और अलग रखें",
        title_mr="बॅटरी कोरड्या आणि वेगळ्या ठेवा",
        body_en="Do not crush or burn batteries. Keep them away from water and food.",
        body_hi="बैटरी को कुचलें या जलाएँ नहीं। पानी और खाने से दूर रखें।",
        body_mr="बॅटरी चिरू किंवा जाळू नका. पाणी आणि अन्नापासून दूर ठेवा.",
        pictogram="battery",
        sort_order=2,
    ),
    dict(
        code="no_open_burning",
        title_en="Do not burn wires",
        title_hi="तारें न जलाएँ",
        title_mr="तार जाळू नका",
        body_en="Burning wires to get copper is poisonous. Sell cables as they are.",
        body_hi="तांबा निकालने के लिए तार जलाना ज़हर है। केबल जैसे हैं वैसे बेचें।",
        body_mr="तांबेसाठी तार जाळणे विषारी आहे. केबल्स जशा आहेत तशा विका.",
        pictogram="no-fire",
        sort_order=3,
    ),
    dict(
        code="qr_handover",
        title_en="Show your QR only at the recycler",
        title_hi="QR सिर्फ़ रीसाइक्लर के पास दिखाएँ",
        title_mr="QR फक्त रीसायक्लरकडे दाखवा",
        body_en="The QR opens the weigh session. Do not share photos of it.",
        body_hi="QR तौल सत्र खोलता है। इसकी फ़ोटो किसी को न भेजें।",
        body_mr="QR वजन सत्र उघडतो. त्याचा फोटो कोणाला देऊ नका.",
        pictogram="qr",
        sort_order=4,
    ),
    dict(
        code="consent",
        title_en="Agree only after you hear the amount",
        title_hi="राशि सुनने के बाद ही सहमति दें",
        title_mr="रक्कम ऐकल्यानंतरच सहमती द्या",
        body_en="The app will speak the weight and rupees. Tap the green tick only if it matches what you saw.",
        body_hi="ऐप तौल और रुपये बोलकर बताएगा। हरी टिक तभी दबाएँ जब बात सही हो।",
        body_mr="अॅप वजन आणि रुपये बोलून सांगेल. हिरवी टिक तेव्हाच दाबा जेव्हा ते बरोबर असेल.",
        pictogram="check",
        sort_order=5,
    ),
]


def find_csv_file(filename: str) -> str | None:
    """Helper to locate CSV files in root or data directory."""
    paths_to_try = [filename, os.path.join("data", filename), os.path.join("..", filename)]
    return next((p for p in paths_to_try if os.path.exists(p)), None)


def load_recyclers_from_csv(csv_path: str = "recyclers.csv") -> list[dict]:
    """Reads all 567 certified recyclers dynamically from the CSV file."""
    recyclers_list = []
    resolved_path = find_csv_file(csv_path)

    if not resolved_path:
        print(f"[Seeder Warning] recyclers.csv not found. Returning empty list.")
        return recyclers_list

    print(f"[Seeder] Loading recyclers from CSV: {resolved_path}")
    with open(resolved_path, mode="r", encoding="utf-8") as f:
        reader = csv.DictReader(f)
        for i, row in enumerate(reader):
            reg_id = row.get("cpcb_registration_id") or f"CPCB-REG-{i}"
            safe_tag = "".join([c if c.isalnum() else "_" for c in reg_id]).lower()
            state = row.get("state", "Odisha")
            
            recyclers_list.append(
                dict(
                    id=row.get("recycler_id") or str(uuid.uuid4()),
                    recycler_code=reg_id,
                    company_name=row.get("company_name", "Certified Recycler"),
                    authorization_no=reg_id,
                    email=f"support.{safe_tag}@renova-recycler.in",
                    phone=row.get("contact_phone", "+91-9999999999"),
                    city=row.get("city", state),  # Granular city from Claude's extraction
                    state=state,
                    pincode="751001",
                    latitude=float(row.get("latitude", 20.2961)),
                    longitude=float(row.get("longitude", 85.8245)),
                    address=row.get("registered_address", ""),
                    pickup_available=str(row.get("pickup_available", "True")).lower() == "true",
                    karma_points=float(row.get("fulfillment_score", 0.9)) * 100,
                    price_multiplier=1.0,
                    accepted_categories=row.get("materials_accepted", "*"),
                )
            )
    print(f"[Seeder] Successfully parsed {len(recyclers_list)} recyclers from CSV.")
    return recyclers_list


def seed_prices_from_csv(db: Session) -> None:
    """Loads price_quotes and price_history directly from generated CSV files."""
    quotes_path = find_csv_file("price_quotes.csv")
    history_path = find_csv_file("price_history.csv")

    if quotes_path:
        print(f"[Seeder] Loading price quotes from: {quotes_path}")
        with open(quotes_path, mode="r", encoding="utf-8") as f:
            reader = csv.DictReader(f)
            for row in reader:
                try:
                    mat_code = row["material_code"].strip().upper()  # Normalize to uppercase
                    db.add(
                        PriceQuote(
                            material_code=mat_code,
                            city=row["city"],
                            state=row["state"],
                            buy_rate_per_kg=float(row["buy_rate_per_kg"]),
                            min_rate=float(row["min_rate"]),
                            max_rate=float(row["max_rate"]),
                            source=row.get("source", "cpcb-national-mandi-index"),
                            updated_at=datetime.strptime(row.get("updated_at", datetime.utcnow().strftime("%Y-%m-%d %H:%M:%S")), "%Y-%m-%d %H:%M:%S")
                        )
                    )
                except Exception as e:
                    pass

    if history_path:
        print(f"[Seeder] Loading price history trends from: {history_path}")
        with open(history_path, mode="r", encoding="utf-8") as f:
            reader = csv.DictReader(f)
            for row in reader:
                try:
                    mat_code = row["material_code"].strip().upper()  # Normalize to uppercase
                    db.add(
                        PriceHistory(
                            material_code=mat_code,
                            city=row["city"],
                            as_of=datetime.strptime(row["as_of"], "%Y-%m-%d"),
                            buy_rate_per_kg=float(row["buy_rate_per_kg"])
                        )
                    )
                except Exception as e:
                    pass
    print("[Seeder] Price quotes and historical trends successfully seeded from CSVs.")


def seed_if_empty(db: Session) -> None:
    if db.query(Material).first():
        return

    # 1. Seed Materials Catalog
    for code, en, hi, mr, ew, haz, icon in MATERIALS:
        db.add(
            Material(
                code=code,
                name_en=en,
                name_hi=hi,
                name_mr=mr,
                e_waste_code=ew,
                hazardous=haz,
                icon=icon,
            )
        )

    # 2. Seed Nationwide Prices & History from CSVs
    seed_prices_from_csv(db)

    # 3. Seed Demo Collectors
    demo_pin = hash_password("1234")
    db.add(
        Collector(
            phone="9876543210",
            pin_hash=demo_pin,
            full_name="Ramesh Sahu",
            language="hi",
            city="Cuttack",
            state="Odisha",
            pincode="753001",
            latitude=20.4625,
            longitude=85.8828,
            upi_id="ramesh@upi",
            aadhaar_last4="4321",
        )
    )
    db.add(
        Collector(
            phone="9123456780",
            pin_hash=demo_pin,
            full_name="Savitri Patil",
            language="mr",
            city="Mumbai",
            state="Maharashtra",
            pincode="400012",
            latitude=19.0760,
            longitude=72.8777,
            upi_id="savitri@upi",
        )
    )

    # 4. Seed 567 CPCB Recyclers from CSV
    demo_pw = hash_password("recycle123")
    csv_recyclers = load_recyclers_from_csv("recyclers.csv")
    
    for row in csv_recyclers:
        db.add(Recycler(password_hash=demo_pw, verified=True, is_active=True, **row))

    # 5. Seed Multi-lingual Safety Cards
    for card in SAFETY:
        db.add(SafetyCard(**card))

    db.commit()


def next_pickup(minutes: int = 60) -> datetime:
    return datetime.now(timezone.utc) + timedelta(minutes=minutes)
