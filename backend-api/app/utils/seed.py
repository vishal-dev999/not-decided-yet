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
    ("pcb", "PCB / Circuit boards", "सर्किट बोर्ड", "सर्किट बोर्ड", "ITEW2", True, "chip"),
    ("copper_wires", "Copper wires", "तांबे की तारें", "तांब्याच्या तारा", "ITEW", False, "wire"),
    ("aluminum", "Aluminum", "एल्युमिनियम", "अॅल्युमिनियम", "ITEW", False, "metal"),
    ("hard_plastics", "Hard plastics", "कठोर प्लास्टिक", "कठीण प्लास्टिक", "ITEW", False, "plastic"),
    ("batteries", "Batteries", "बैटरी", "बॅटरी", "BATT", True, "battery"),
    ("cables", "Cables", "केबल", "केबल्स", "ITEW", False, "cable"),
    ("mixed_ewaste", "Mixed e-waste", "मिश्र ई-कचरा", "मिश्र ई-कचरा", "ITEW", True, "mixed"),
    ("steel", "Steel", "स्टील", "स्टील", "ITEW", False, "steel"),
    ("glass", "CRT / Glass", "काँच", "काच", "CEEW1", True, "glass"),
    ("motors", "Motors", "मोटर", "मोटार", "CEEW", False, "motor"),
]

# Approximate informal-market buy rates (₹/kg) — placeholder until field research
# Cuttack / Bhubaneswar focused, plus a couple of metros for location demos.
RATES = {
    # material: (cuttack, bhubaneswar, mumbai, delhi) as (buy, min, max)
    "pcb": {
        "Cuttack": (220, 160, 380),
        "Bhubaneswar": (230, 170, 400),
        "Mumbai": (260, 190, 450),
        "Delhi": (250, 180, 430),
    },
    "copper_wires": {
        "Cuttack": (480, 400, 620),
        "Bhubaneswar": (490, 410, 630),
        "Mumbai": (530, 450, 680),
        "Delhi": (520, 440, 670),
    },
    "aluminum": {
        "Cuttack": (125, 95, 160),
        "Bhubaneswar": (128, 98, 165),
        "Mumbai": (140, 110, 180),
        "Delhi": (138, 108, 175),
    },
    "hard_plastics": {
        "Cuttack": (22, 12, 35),
        "Bhubaneswar": (24, 14, 38),
        "Mumbai": (28, 16, 42),
        "Delhi": (26, 15, 40),
    },
    "batteries": {
        "Cuttack": (78, 60, 95),
        "Bhubaneswar": (80, 62, 98),
        "Mumbai": (88, 70, 110),
        "Delhi": (85, 68, 105),
    },
    "cables": {
        "Cuttack": (90, 60, 140),
        "Bhubaneswar": (95, 65, 145),
        "Mumbai": (110, 75, 160),
        "Delhi": (105, 72, 155),
    },
    "mixed_ewaste": {
        "Cuttack": (32, 18, 55),
        "Bhubaneswar": (34, 20, 58),
        "Mumbai": (40, 22, 65),
        "Delhi": (38, 21, 62),
    },
    "steel": {
        "Cuttack": (28, 20, 38),
        "Bhubaneswar": (29, 21, 39),
        "Mumbai": (32, 24, 42),
        "Delhi": (31, 23, 41),
    },
    "glass": {
        "Cuttack": (6, 2, 12),
        "Bhubaneswar": (6, 2, 12),
        "Mumbai": (8, 3, 14),
        "Delhi": (7, 3, 13),
    },
    "motors": {
        "Cuttack": (55, 35, 80),
        "Bhubaneswar": (58, 38, 85),
        "Mumbai": (70, 45, 95),
        "Delhi": (66, 42, 90),
    },
}

CITY_STATE = {
    "Cuttack": "Odisha",
    "Bhubaneswar": "Odisha",
    "Mumbai": "Maharashtra",
    "Delhi": "Delhi",
}

RECYCLERS = [
    # Cuttack / Odisha cluster — these will typically win distance for demo lots
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
        accepted_categories="pcb,copper_wires,cables,mixed_ewaste",
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
        accepted_categories="batteries,pcb,motors",
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
        accepted_categories="hard_plastics,cables,mixed_ewaste,steel",
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
