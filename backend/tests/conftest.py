"""
Shared test fixtures — loaded once, used by all test files.
This is the pytest equivalent of setUp() in other frameworks.
"""

import pytest
from fastapi.testclient import TestClient
from app.main import app
from app.services.ml_service import ml_service


@pytest.fixture(scope="session", autouse=True)
def load_models():
    """Load ML models once for entire test session."""
    ml_service.load_all_models()
    yield


@pytest.fixture(scope="session")
def client():
    """Create a test client that doesn't need a running server."""
    with TestClient(app) as c:
        yield c