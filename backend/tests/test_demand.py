"""
Demand Prediction Tests
Tests single prediction, bulk prediction, edge cases, and validation.
"""


class TestDemandPrediction:
    """Test demand forecasting endpoint."""

    def test_valid_prediction_returns_200(self, client):
        """Standard prediction should return success with orders > 0."""
        response = client.post("/api/v1/predict-demand", json={
            "restaurant_id": 285,
            "day_of_week": 5,
            "hour_of_day": 19,
            "is_weekend": 1,
            "holiday": 0,
            "restaurant_rating": 4.2,
            "price_range": 3
        })
        assert response.status_code == 200
        data = response.json()
        assert data["success"] is True
        assert data["predicted_orders"] >= 0
        assert 0 < data["confidence"] <= 1.0
        assert data["model_rmse"] > 0

    def test_peak_hour_detected(self, client):
        """Hour 19 (7PM) should be detected as peak."""
        response = client.post("/api/v1/predict-demand", json={
            "restaurant_id": 285,
            "day_of_week": 5,
            "hour_of_day": 19,
            "is_weekend": 1,
            "holiday": 0,
            "restaurant_rating": 4.0,
            "price_range": 2
        })
        data = response.json()
        assert data["peak_status"] == "peak"

    def test_dead_hour_detected(self, client):
        """Hour 3 (3AM) should be detected as dead."""
        response = client.post("/api/v1/predict-demand", json={
            "restaurant_id": 285,
            "day_of_week": 2,
            "hour_of_day": 3,
            "is_weekend": 0,
            "holiday": 0,
            "restaurant_rating": 4.0,
            "price_range": 2
        })
        data = response.json()
        assert data["peak_status"] == "dead"

    def test_bulk_prediction_returns_24_hours(self, client):
        """Bulk prediction should return exactly 24 hourly forecasts."""
        response = client.post("/api/v1/predict-demand-bulk", json={
            "restaurant_id": 285,
            "day_of_week": 5,
            "hour_of_day": 0,
            "is_weekend": 1,
            "holiday": 0,
            "restaurant_rating": 4.2,
            "price_range": 3
        })
        assert response.status_code == 200
        data = response.json()
        assert data["success"] is True
        assert len(data["hourly_forecast"]) == 24
        assert data["peak_hour"] >= 0
        assert data["peak_hour"] <= 23
        assert data["total_day_orders"] > 0

    def test_unknown_restaurant_still_works(self, client):
        """Unknown restaurant ID should still return prediction (via blending)."""
        response = client.post("/api/v1/predict-demand", json={
            "restaurant_id": 9999999,
            "day_of_week": 3,
            "hour_of_day": 12,
            "is_weekend": 0,
            "holiday": 0,
            "restaurant_rating": 3.5,
            "price_range": 2
        })
        assert response.status_code == 200
        data = response.json()
        assert data["predicted_orders"] >= 1

    def test_invalid_day_rejected(self, client):
        """Day of week > 6 should be rejected with 422."""
        response = client.post("/api/v1/predict-demand", json={
            "restaurant_id": 285,
            "day_of_week": 9,
            "hour_of_day": 12,
            "is_weekend": 0,
            "holiday": 0,
            "restaurant_rating": 4.0,
            "price_range": 2
        })
        assert response.status_code == 422

    def test_invalid_hour_rejected(self, client):
        """Hour > 23 should be rejected with 422."""
        response = client.post("/api/v1/predict-demand", json={
            "restaurant_id": 285,
            "day_of_week": 3,
            "hour_of_day": 25,
            "is_weekend": 0,
            "holiday": 0,
            "restaurant_rating": 4.0,
            "price_range": 2
        })
        assert response.status_code == 422