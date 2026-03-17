"""
Health & Infrastructure Tests
Tests that the server starts, models load, and basic endpoints work.
"""


class TestHealthEndpoints:
    """Test server health and model loading."""

    def test_health_returns_200(self, client):
        """Server should return 200 with healthy status."""
        response = client.get("/health")
        assert response.status_code == 200
        data = response.json()
        assert data["status"] == "healthy"
        assert data["models_loaded"] is True

    def test_root_returns_endpoints(self, client):
        """Root URL should list all available endpoints."""
        response = client.get("/")
        assert response.status_code == 200
        data = response.json()
        assert "endpoints" in data
        assert "demand" in data["endpoints"]
        assert "eta" in data["endpoints"]
        assert "recommend" in data["endpoints"]

    def test_model_info_returns_metrics(self, client):
        """Model info should show all 3 models with metrics."""
        response = client.get("/model-info")
        assert response.status_code == 200
        data = response.json()
        models = data["models"]
        assert models["models_loaded"] is True
        assert models["demand"]["features"] > 0
        assert models["eta"]["features"] > 0
        assert models["recommendation"]["restaurants"] > 0

    def test_swagger_docs_accessible(self, client):
        """Swagger UI should be accessible at /docs."""
        response = client.get("/docs")
        assert response.status_code == 200

    def test_locations_returns_countries(self, client):
        """Locations endpoint should return country-city hierarchy."""
        response = client.get("/api/v1/locations")
        assert response.status_code == 200
        data = response.json()
        assert data["success"] is True
        assert data["total_countries"] > 0
        assert len(data["countries"]) > 0
        # Each country should have cities
        first_country = data["countries"][0]
        assert "country" in first_country
        assert "cities" in first_country
        assert len(first_country["cities"]) > 0

    def test_cities_returns_list(self, client):
        """Cities endpoint should return flat city list."""
        response = client.get("/api/v1/cities")
        assert response.status_code == 200
        data = response.json()
        assert data["success"] is True
        assert len(data["cities"]) > 0