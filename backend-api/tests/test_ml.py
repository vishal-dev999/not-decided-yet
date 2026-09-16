from app.ml.fraud import assess
from app.ml.ranker import _distance_score, rank_recyclers
from app.utils.i18n import money_spoken
from app.utils.geo import haversine_km


class R:
    def __init__(self, **kw):
        self.__dict__.update(kw)
        self.verified = True
        self.is_active = True


def test_haversine_cuttack_bhubaneswar():
    km = haversine_km(20.4625, 85.8830, 20.2961, 85.8245)
    assert 15 < km < 30


def test_distance_score_monotonic():
    assert _distance_score(0) > _distance_score(50) > _distance_score(200)


def test_ranker_prefers_nearby_available():
    market = 220.0
    near = R(
        id="near",
        company_name="Near",
        authorization_no="A",
        city="Cuttack",
        latitude=20.46,
        longitude=85.88,
        pickup_available=True,
        karma_points=80,
        price_multiplier=1.0,
        accepted_categories="*",
    )
    far = R(
        id="far",
        company_name="Far",
        authorization_no="B",
        city="Mumbai",
        latitude=19.07,
        longitude=72.87,
        pickup_available=True,
        karma_points=99,
        price_multiplier=1.2,
        accepted_categories="*",
    )
    ranked = rank_recyclers(20.46, 85.88, market, [near, far], "pcb", top_n=2)
    assert ranked[0].recycler_id == "near"


def test_fraud_inflated_weight():
    r = assess(10, 40, 220, 220, 160, 380)
    assert "WEIGHT_INFLATED" in r.flags
    assert r.score >= 35


def test_fraud_low_rate():
    r = assess(10, 10, 50, 220, 160, 380)
    assert "RATE_FAR_BELOW_MARKET" in r.flags


def test_hindi_money():
    s = money_spoken(3080)
    assert "रुपये" in s["hi"]
    assert "three" in s["en"]
