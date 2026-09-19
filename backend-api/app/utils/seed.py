"""Seed CPCB-style recyclers, materials, prices, safety cards, and demo users."""

from __future__ import annotations

import hashlib
from datetime import datetime, timedelta, timezone

from sqlalchemy.orm import Session

from app.core.security import hash_password
from app.ml.price_engine import generate_synthetic_history
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

# Approximate informal-market buy rates (₹/kg)
# Cuttack / Bhubaneswar focused, plus metros for location demos.
RATES = {
    # material: (cuttack, bhubaneswar, mumbai, delhi) as (buy, min, max)
    "MOTHERBOARD_HIGH_GRADE": {
        "Cuttack": (290, 240, 360),
        "Bhubaneswar": (305, 250, 380),
        "Mumbai": (340, 280, 420),
        "Delhi": (330, 270, 410),
    },
    "POWER_SUPPLY_LOW_GRADE": {
        "Cuttack": (50, 38, 68),
        "Bhubaneswar": (54, 40, 72),
        "Mumbai": (62, 45, 82),
        "Delhi": (60, 44, 80),
    },
    "BATTERY_LITHIUM_PORTABLE": {
        "Cuttack": (135, 105, 175),
        "Bhubaneswar": (142, 110, 185),
        "Mumbai": (158, 120, 205),
        "Delhi": (152, 115, 198),
    },
    "LEAD_ACID": {
        "Cuttack": (88, 72, 110),
        "Bhubaneswar": (92, 75, 115),
        "Mumbai": (102, 82, 128),
        "Delhi": (98, 80, 122),
    },
    "CRT_MONITOR": {
        "Cuttack": (18, 12, 26),
        "Bhubaneswar": (20, 14, 28),
        "Mumbai": (24, 16, 34),
        "Delhi": (22, 15, 32),
    },
    "LCD_PANEL_INTACT": {
        "Cuttack": (78, 60, 102),
        "Bhubaneswar": (82, 64, 108),
        "Mumbai": (94, 72, 122),
        "Delhi": (90, 70, 118),
    },
    "MIXED_EWASTE_CASING": {
        "Cuttack": (20, 14, 30),
        "Bhubaneswar": (22, 15, 32),
        "Mumbai": (26, 18, 38),
        "Delhi": (25, 17, 36),
    },
    "COPPER_HEAVY_INSULATED": {
        "Cuttack": (440, 380, 520),
        "Bhubaneswar": (455, 390, 540),
        "Mumbai": (490, 420, 580),
        "Delhi": (480, 410, 570),
    },
    "ALUMINIUM_WIRE": {
        "Cuttack": (118, 92, 150),
        "Bhubaneswar": (124, 96, 158),
        "Mumbai": (138, 108, 175),
        "Delhi": (134, 104, 170),
    },
}

CITY_STATE = {
    "Cuttack": "Odisha",
    "Bhubaneswar": "Odisha",
    "Mumbai": "Maharashtra",
    "Delhi": "Delhi",
}

RECYCLERS = [
    dict(
        recycler_code="OD-CTC-001",
        company_name="Mahanadi E-Waste Recyclers",
        authorization_no="CPCB/OR/EWR/2024/001",
        email="mahanadi@demo.kabadiwala",
        phone="06712300001",
        city="Cuttack",
        state="Odisha",
        pincode="753001",
        latitude=20.4625,
        longitude=85.8830,
        address="Industrial Estate, Cuttack",
        pickup_available=True,
        karma_points=88.0,
        price_multiplier=1.04,
        accepted_categories="*",
    ),
    dict(
        recycler_code="OD-BBSR-002",
        company_name="Kalinga Green Tech",
        authorization_no="CPCB/OR/EWR/2023/014",
        email="kalinga@demo.kabadiwala",
        phone="06742300002",
        city="Bhubaneswar",
        state="Odisha",
        pincode="751024",
        latitude=20.2961,
        longitude=85.8245,
        address="Chandaka Industrial Area, Bhubaneswar",
        pickup_available=True,
        karma_points=76.0,
        price_multiplier=1.08,
        accepted_categories="*",
    ),
    dict(
        recycler_code="OD-CTC-003",
        company_name="Utkal Circuit Recovery",
        authorization_no="CPCB/OR/EWR/2022/009",
        email="utkal@demo.kabadiwala",
        phone="06712300003",
        city="Cuttack",
        state="Odisha",
        pincode="753014",
        latitude=20.4800,
        longitude=85.9100,
        address="Jagatpur, Cuttack",
        pickup_available=True,
        karma_points=64.0,
        price_multiplier=0.97,
        accepted_categories="MOTHERBOARD_HIGH_GRADE,POWER_SUPPLY_LOW_GRADE,COPPER_HEAVY_INSULATED,ALUMINIUM_WIRE",
    ),
    dict(
        recycler_code="OD-BBSR-004",
        company_name="Eastern Battery Loop",
        authorization_no="CPCB/OR/EWR/2024/021",
        email="ebl@demo.kabadiwala",
        phone="06742300004",
        city="Bhubaneswar",
        state="Odisha",
        pincode="751019",
        latitude=20.2700,
        longitude=85.8400,
        address="Rasulgarh, Bhubaneswar",
        pickup_available=False,
        karma_points=71.0,
        price_multiplier=1.12,
        accepted_categories="BATTERY_LITHIUM_PORTABLE,LEAD_ACID,MOTHERBOARD_HIGH_GRADE",
    ),
    dict(
        recycler_code="MH-MUM-005",
        company_name="Western Eco Reclaim",
        authorization_no="CPCB/MH/EWR/2021/077",
        email="western@demo.kabadiwala",
        phone="02223000005",
        city="Mumbai",
        state="Maharashtra",
        pincode="400013",
        latitude=19.0760,
        longitude=72.8777,
        address="Andheri East, Mumbai",
        pickup_available=True,
        karma_points=92.0,
        price_multiplier=1.15,
        accepted_categories="*",
    ),
    dict(
        recycler_code="DL-DEL-006",
        company_name="Yamuna Authorized Recyclers",
        authorization_no="CPCB/DL/EWR/2020/033",
        email="yamuna@demo.kabadiwala",
        phone="01123000006",
        city="Delhi",
        state="Delhi",
        pincode="110092",
        latitude=28.6139,
        longitude=77.2090,
        address="Mayapuri Industrial Area, Delhi",
        pickup_available=True,
        karma_points=81.0,
        price_multiplier=1.10,
        accepted_categories="*",
    ),
    dict(
        recycler_code="OD-CTC-007",
        company_name="Bay Plastic Recovery",
        authorization_no="CPCB/OR/EWR/2023/044",
        email="bayplastic@demo.kabadiwala",
        phone="06712300007",
        city="Cuttack",
        state="Odisha",
        pincode="753003",
        latitude=20.4500,
        longitude=85.8700,
        address="Buxi Bazaar, Cuttack",
        pickup_available=True,
        karma_points=55.0,
        price_multiplier=0.92,
        accepted_categories="MIXED_EWASTE_CASING,CRT_MONITOR,LCD_PANEL_INTACT",
    ),
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


def seed_if_empty(db: Session) -> None:
    if db.query(Material).first():
        return

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

    for mat, cities in RATES.items():
        for i, (city, (buy, lo, hi)) in enumerate(cities.items()):
            db.add(
                PriceQuote(
                    material_code=mat,
                    city=city,
                    state=CITY_STATE[city],
                    buy_rate_per_kg=buy,
                    min_rate=lo,
                    max_rate=hi,
                    source="seed-prototype",
                )
            )
            stable = int(hashlib.md5(f"{mat}:{city}".encode()).hexdigest()[:8], 16) % 10_000
            for ts, price in generate_synthetic_history(buy, days=45, seed=stable):
                db.add(
                    PriceHistory(
                        material_code=mat,
                        city=city,
                        as_of=ts,
                        buy_rate_per_kg=price,
                    )
                )

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

    demo_pw = hash_password("recycle123")
    for row in RECYCLERS:
        db.add(Recycler(password_hash=demo_pw, verified=True, is_active=True, **row))

    for card in SAFETY:
        db.add(SafetyCard(**card))

    db.commit()


def next_pickup(minutes: int = 60) -> datetime:
    return datetime.now(timezone.utc) + timedelta(minutes=minutes)