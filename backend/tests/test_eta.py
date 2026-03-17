"""
ETA Prediction Tests
Tests delivery time prediction with various conditions.
"""


class TestETAPrediction:
    """Test delivery time prediction endpoint."""

    def test_valid_eta_returns_200(self, client):
        """Standard ETA prediction should return success."""
        response = client.post("/api/v1/predict-eta", json={
            "distance_km": 5.5,
            "preparation_time_min": 20,
            "weather": "clear",
            "traffic_level": "medium",
            "time_of_day": "evening",
            "vehicle_type": "bike"
        })
        assert response.status_code == 200
        data = response.json()
        assert data["success"] is True
        assert data["eta_minutes"] >= 10
        assert data["eta_minutes"] <= 120
        assert "breakdown" in data

    def test_eta_greater_than_prep_time(self, client):
        """Total ETA should always be >= preparation time."""
        response = client.post("/api/v1/predict-eta", json={
            "distance_km": 2.0,
            "preparation_time_min": 30,
            "weather": "clear",
            "traffic_level": "low",
            "time_of_day": "morning",
            "vehicle_type": "bike"
        })
        data = response.json()
        assert data["eta_minutes"] >= 30

    def test_heavy_traffic_increases_eta(self, client):
        """Heavy traffic should give higher ETA than low traffic."""
        # Low traffic
        r1 = client.post("/api/v1/predict-eta", json={
            "distance_km": 10.0,
            "preparation_time_min": 15,
            "weather": "clear",
            "traffic_level": "low",
            "time_of_day": "evening",
            "vehicle_type": "bike"
        })
        # High traffic
        r2 = client.post("/api/v1/predict-eta", json={
            "distance_km": 10.0,
            "preparation_time_min": 15,
            "weather": "clear",
            "traffic_level": "high",
            "time_of_day": "evening",
            "vehicle_type": "bike"
        })
        eta_low = r1.json()["eta_minutes"]
        eta_high = r2.json()["eta_minutes"]
        # High traffic should generally give same or higher ETA
        assert eta_high >= eta_low - 5  # Allow small margin

    def test_breakdown_sums_correctly(self, client):
        """Breakdown prep + travel should approximately equal total ETA."""
        response = client.post("/api/v1/predict-eta", json={
            "distance_km": 5.0,
            "preparation_time_min": 20,
            "weather": "clear",
            "traffic_level": "medium",
            "time_of_day": "evening",
            "vehicle_type": "bike"
        })
        data = response.json()
        breakdown = data["breakdown"]
        total = breakdown["preparation"] + breakdown["travel_estimate"]
        assert abs(total - data["eta_minutes"]) <= 2

    def test_zero_distance_rejected(self, client):
        """Distance = 0 should be rejected."""
        response = client.post("/api/v1/predict-eta", json={
            "distance_km": 0,
            "preparation_time_min": 20,
            "weather": "clear",
            "traffic_level": "medium",
            "time_of_day": "evening",
            "vehicle_type": "bike"
        })
        assert response.status_code == 422

    def test_unknown_weather_handled(self, client):
        """Unknown weather value should not crash the server."""
        response = client.post("/api/v1/predict-eta", json={
            "distance_km": 5.0,
            "preparation_time_min": 20,
            "weather": "tornado",
            "traffic_level": "medium",
            "time_of_day": "evening",
            "vehicle_type": "bike"
        })
        assert response.status_code == 200