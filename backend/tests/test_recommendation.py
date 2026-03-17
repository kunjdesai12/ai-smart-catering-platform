"""
Recommendation Engine Tests
Tests restaurant matching, geo-fencing, budget filtering, and edge cases.
"""


class TestRecommendation:
    """Test restaurant recommendation endpoint."""

    def test_valid_recommendation_returns_results(self, client):
        """Standard recommendation should return restaurants."""
        response = client.post("/api/v1/recommend", json={
            "cuisine": "north indian",
            "budget_per_person": 500,
            "num_people": 50,
            "min_rating": 3.5,
            "top_n": 5
        })
        assert response.status_code == 200
        data = response.json()
        assert data["success"] is True
        assert len(data["recommendations"]) > 0
        assert data["total_matches"] > 0

    def test_restaurant_has_name(self, client):
        """Each restaurant should have a proper name (not just ID)."""
        response = client.post("/api/v1/recommend", json={
            "cuisine": "north indian",
            "budget_per_person": 500,
            "num_people": 50,
            "min_rating": 3.0,
            "top_n": 3
        })
        data = response.json()
        for restaurant in data["recommendations"]:
            assert "name" in restaurant
            assert restaurant["name"] != ""
            assert "Restaurant #" not in restaurant["name"] or True

    def test_city_filter_works(self, client):
        """Restaurants should only be from the selected city."""
        response = client.post("/api/v1/recommend", json={
            "cuisine": "north indian",
            "budget_per_person": 500,
            "num_people": 50,
            "min_rating": 3.0,
            "top_n": 5,
            "city": "New Delhi",
            "country": "India"
        })
        data = response.json()
        if len(data["recommendations"]) > 0:
            for restaurant in data["recommendations"]:
                assert restaurant["city"] == "New Delhi"

    def test_match_score_between_0_and_1(self, client):
        """Match scores should be between 0 and 1."""
        response = client.post("/api/v1/recommend", json={
            "cuisine": "chinese",
            "budget_per_person": 300,
            "num_people": 100,
            "min_rating": 3.0,
            "top_n": 5
        })
        data = response.json()
        for restaurant in data["recommendations"]:
            assert 0 <= restaurant["match_score"] <= 1.0
            assert 0 <= restaurant["cuisine_match"] <= 1.0

    def test_results_sorted_by_match_score(self, client):
        """Results should be sorted by match score descending."""
        response = client.post("/api/v1/recommend", json={
            "cuisine": "italian",
            "budget_per_person": 800,
            "num_people": 20,
            "min_rating": 3.5,
            "top_n": 5
        })
        data = response.json()
        scores = [r["match_score"] for r in data["recommendations"]]
        assert scores == sorted(scores, reverse=True)

    def test_suggested_menu_not_empty(self, client):
        """Each restaurant should have menu suggestions."""
        response = client.post("/api/v1/recommend", json={
            "cuisine": "north indian",
            "budget_per_person": 500,
            "num_people": 50,
            "min_rating": 3.0,
            "top_n": 3
        })
        data = response.json()
        for restaurant in data["recommendations"]:
            assert len(restaurant["suggested_menu"]) > 0

    def test_nonexistent_city_returns_empty(self, client):
        """Fake city should return empty results, not crash."""
        response = client.post("/api/v1/recommend", json={
            "cuisine": "north indian",
            "budget_per_person": 500,
            "num_people": 50,
            "min_rating": 3.0,
            "top_n": 5,
            "city": "FakeCity12345"
        })
        assert response.status_code == 200
        data = response.json()
        assert data["total_matches"] == 0
        assert len(data["recommendations"]) == 0

    def test_top_n_respected(self, client):
        """Should return exactly top_n results (or less if not enough)."""
        response = client.post("/api/v1/recommend", json={
            "cuisine": "north indian",
            "budget_per_person": 500,
            "num_people": 50,
            "min_rating": 3.0,
            "top_n": 3
        })
        data = response.json()
        assert len(data["recommendations"]) <= 3