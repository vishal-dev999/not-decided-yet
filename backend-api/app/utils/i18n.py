"""Audio-first spoken strings in English, Hindi, and Marathi."""

from __future__ import annotations

ONES_EN = [
    "", "one", "two", "three", "four", "five", "six", "seven", "eight", "nine",
    "ten", "eleven", "twelve", "thirteen", "fourteen", "fifteen", "sixteen",
    "seventeen", "eighteen", "nineteen",
]
TENS_EN = ["", "", "twenty", "thirty", "forty", "fifty", "sixty", "seventy", "eighty", "ninety"]

ONES_HI = [
    "", "एक", "दो", "तीन", "चार", "पाँच", "छह", "सात", "आठ", "नौ", "दस",
    "ग्यारह", "बारह", "तेरह", "चौदह", "पंद्रह", "सोलह", "सत्रह", "अठारह", "उन्नीस",
]
TENS_HI = ["", "", "बीस", "तीस", "चालीस", "पचास", "साठ", "सत्तर", "अस्सी", "नब्बे"]

ONES_MR = [
    "", "एक", "दोन", "तीन", "चार", "पाच", "सहा", "सात", "आठ", "नऊ", "दहा",
    "अकरा", "बारा", "तेरा", "चौदा", "पंधरा", "सोळा", "सतरा", "अठरा", "एकोणीस",
]
TENS_MR = ["", "", "वीस", "तीस", "चाळीस", "पन्नास", "साठ", "सत्तर", "ऐंशी", "नव्वद"]


def _under_100(n: int, ones: list[str], tens: list[str]) -> str:
    n = int(n)
    if n < 20:
        return ones[n]
    return (tens[n // 10] + ((" " + ones[n % 10]) if n % 10 else "")).strip()


def _en_int(n: int) -> str:
    n = int(n)
    if n == 0:
        return "zero"
    parts = []
    crore, n = divmod(n, 10_000_000)
    lakh, n = divmod(n, 100_000)
    thousand, n = divmod(n, 1000)
    hundred, rest = divmod(n, 100)
    if crore:
        parts.append(f"{_en_int(crore)} crore")
    if lakh:
        parts.append(f"{_en_int(lakh)} lakh")
    if thousand:
        parts.append(f"{_en_int(thousand)} thousand")
    if hundred:
        parts.append(f"{ONES_EN[hundred]} hundred")
    if rest:
        parts.append(_under_100(rest, ONES_EN, TENS_EN))
    return " ".join(parts)


def _hi_int(n: int) -> str:
    n = int(n)
    if n == 0:
        return "शून्य"
    parts = []
    crore, n = divmod(n, 10_000_000)
    lakh, n = divmod(n, 100_000)
    thousand, n = divmod(n, 1000)
    hundred, rest = divmod(n, 100)
    if crore:
        parts.append(f"{_hi_int(crore)} करोड़")
    if lakh:
        parts.append(f"{_hi_int(lakh)} लाख")
    if thousand:
        parts.append(f"{_hi_int(thousand)} हज़ार")
    if hundred:
        parts.append(f"{ONES_HI[hundred]} सौ")
    if rest:
        parts.append(_under_100(rest, ONES_HI, TENS_HI))
    return " ".join(parts)


def _mr_int(n: int) -> str:
    n = int(n)
    if n == 0:
        return "शून्य"
    parts = []
    crore, n = divmod(n, 10_000_000)
    lakh, n = divmod(n, 100_000)
    thousand, n = divmod(n, 1000)
    hundred, rest = divmod(n, 100)
    if crore:
        parts.append(f"{_mr_int(crore)} कोटी")
    if lakh:
        parts.append(f"{_mr_int(lakh)} लाख")
    if thousand:
        parts.append(f"{_mr_int(thousand)} हजार")
    if hundred:
        parts.append(f"{ONES_MR[hundred]} शे")
    if rest:
        parts.append(_under_100(rest, ONES_MR, TENS_MR))
    return " ".join(parts)


def money_spoken(amount: float) -> dict[str, str]:
    rupees = int(round(amount))
    return {
        "en": f"{_en_int(rupees)} rupees",
        "hi": f"{_hi_int(rupees)} रुपये",
        "mr": f"{_mr_int(rupees)} रुपये",
    }


def kg_spoken(kg: float) -> dict[str, str]:
    if abs(kg - round(kg)) < 0.05:
        n = int(round(kg))
        return {
            "en": f"{_en_int(n)} kilograms",
            "hi": f"{_hi_int(n)} किलो",
            "mr": f"{_mr_int(n)} किलो",
        }
    return {
        "en": f"{kg:.1f} kilograms",
        "hi": f"{kg:.1f} किलो",
        "mr": f"{kg:.1f} किलो",
    }


def spoken(en: str, hi: str, mr: str) -> dict[str, str]:
    return {"en": en, "hi": hi, "mr": mr}


def pick(bundle: dict[str, str], lang: str = "hi") -> str:
    return bundle.get(lang) or bundle.get("hi") or bundle.get("en") or ""


def consent_prompt(weight_kg: float, total: float, recycler_name: str) -> dict[str, str]:
    w = kg_spoken(weight_kg)
    m = money_spoken(total)
    return spoken(
        f"{recycler_name} entered {w['en']} for {m['en']}. Do you agree?",
        f"{recycler_name} ने {w['hi']} के लिए {m['hi']} दर्ज किए हैं। क्या आप सहमत हैं?",
        f"{recycler_name} ने {w['mr']} साठी {m['mr']} नोंदवले आहेत. तुम्ही सहमत आहात का?",
    )


def price_board_line(name: dict[str, str], rate: float) -> dict[str, str]:
    m = money_spoken(rate)
    return spoken(
        f"Today {name['en']} rate is {m['en']} per kilogram.",
        f"आज {name['hi']} का भाव {m['hi']} प्रति किलो है।",
        f"आज {name['mr']} चा भाव {m['mr']} प्रति किलो आहे.",
    )


def earnings_spoken(balance: float, dues: float) -> dict[str, str]:
    b = money_spoken(balance)
    d = money_spoken(dues)
    return spoken(
        f"Your earnings balance is {b['en']}. Pending dues {d['en']}.",
        f"आपकी कमाई {b['hi']} है। बकाया {d['hi']} है।",
        f"तुमची कमाई {b['mr']} आहे. थकबाकी {d['mr']} आहे.",
    )


def match_spoken(recycler_name: str, city: str) -> dict[str, str]:
    return spoken(
        f"Recycler {recycler_name} from {city} has accepted your lot. Pickup is scheduled.",
        f"{city} के रीसाइक्लर {recycler_name} ने आपका लॉट स्वीकार किया है। पिकअप तय हो गया है।",
        f"{city} येथील रीसायक्लर {recycler_name} ने तुमचा लॉट स्वीकारला आहे. पिकअप ठरला आहे.",
    )


def success_spoken(amount: float) -> dict[str, str]:
    m = money_spoken(amount)
    return spoken(
        f"Transaction complete. {m['en']} credited to your earnings.",
        f"लेन-देन पूरा हुआ। {m['hi']} आपकी कमाई में जुड़ गए।",
        f"व्यवहार पूर्ण झाला. {m['mr']} तुमच्या कमाईत जमा झाले.",
    )


MATERIAL_NAMES = {
    # 9 Distinct Target Categories
    "MOTHERBOARD_HIGH_GRADE": {
        "en": "high grade PCB motherboards",
        "hi": "हाई-ग्रेड मदरबोर्ड पीसीबी",
        "mr": "हाय-ग्रेड मदरबोर्ड पीसीबी",
    },
    "POWER_SUPPLY_LOW_GRADE": {
        "en": "low grade PCB power supplies",
        "hi": "लो-ग्रेड पीसीबी व एसएमपीएस",
        "mr": "लो-ग्रेड पीसीबी आणि एसएमपीएस",
    },
    "BATTERY_LITHIUM_PORTABLE": {
        "en": "lithium ion batteries",
        "hi": "लिथियम बैटरी",
        "mr": "लिथियम बॅटरी",
    },
    "LEAD_ACID": {
        "en": "lead acid batteries",
        "hi": "लेड-एसिड बैटरी",
        "mr": "लेड-अ‍ॅसिड बॅटरी",
    },
    "CRT_MONITOR": {
        "en": "CRT monitors",
        "hi": "सीआरटी मॉनिटर",
        "mr": "सीआरटी मॉनिटर",
    },
    "LCD_PANEL_INTACT": {
        "en": "LCD flat panel displays",
        "hi": "एलसीडी फ्लैट डिस्प्ले",
        "mr": "एलसीडी फ्लॅट डिस्प्ले",
    },
    "MIXED_EWASTE_CASING": {
        "en": "mixed e-waste plastic casing",
        "hi": "मिश्रित ई-कचरा प्लास्टिक",
        "mr": "मिश्र ई-कचरा प्लास्टिक",
    },
    "COPPER_HEAVY_INSULATED": {
        "en": "copper insulated wires",
        "hi": "तांबे का तार",
        "mr": "तांब्याची तार",
    },
    "ALUMINIUM_WIRE": {
        "en": "aluminium wires",
        "hi": "एल्युमिनियम तार",
        "mr": "अ‍ॅल्युमिनियम तार",
    },

    # Legacy & Shorthand Aliases (Prevents KeyErrors on older endpoints)
    "pcb": {"en": "PCB circuit boards", "hi": "सर्किट बोर्ड", "mr": "सर्किट बोर्ड"},
    "copper_wires": {"en": "copper wires", "hi": "तांबे की तारें", "mr": "तांब्याच्या तारा"},
    "aluminum": {"en": "aluminum", "hi": "एल्युमिनियम", "mr": "अॅल्युमिनियम"},
    "hard_plastics": {"en": "hard plastics", "hi": "कठोर प्लास्टिक", "mr": "कठीण प्लास्टिक"},
    "batteries": {"en": "batteries", "hi": "बैटरी", "mr": "बॅटरी"},
    "cables": {"en": "cables", "hi": "केबल", "mr": "केबल्स"},
    "mixed_ewaste": {"en": "mixed e-waste", "hi": "मिश्र ई-कचरा", "mr": "मिश्र ई-कचरा"},
    "steel": {"en": "steel", "hi": "स्टील", "mr": "स्टील"},
    "glass": {"en": "glass", "hi": "काँच", "mr": "काच"},
    "motors": {"en": "motors", "hi": "मोटर", "mr": "मोटार"},
}
