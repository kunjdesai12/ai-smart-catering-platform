from contextlib import asynccontextmanager
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.config import get_settings
from app.services.ml_service import ml_service
from app.routers import (
    health_router,
    demand_router,
    eta_router,
    recommendation_router
)
from app.utils.logger import setup_logger

logger = setup_logger("main")
settings = get_settings()


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Load ML models at startup, cleanup at shutdown."""
    logger.info("Starting AI Catering Platform...")
    ml_service.load_all_models()
    logger.info("Server ready to accept requests")
    yield
    logger.info("Shutting down...")


app = FastAPI(
    title=settings.app_name,
    version=settings.app_version,
    description=(
        "AI-Powered Smart Catering Demand & Recommendation Platform.\n\n"
        "**3 ML Models:**\n"
        "- Demand Prediction (LightGBM)\n"
        "- ETA Prediction (LightGBM)\n"
        "- Restaurant Recommendation (TF-IDF Hybrid)\n\n"
        "Built for Flutter mobile app consumption."
    ),
    lifespan=lifespan,
    docs_url="/docs",
    redoc_url="/redoc"
)

# CORS — allows Flutter app to call this API from any device
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Register all routers
app.include_router(health_router)
app.include_router(demand_router)
app.include_router(eta_router)
app.include_router(recommendation_router)


@app.get("/", tags=["Root"])
async def root():
    return {
        "message": "AI Catering Platform API",
        "version": settings.app_version,
        "docs": "/docs",
        "endpoints": {
            "health": "/health",
            "demand": "/api/v1/predict-demand",
            "demand_bulk": "/api/v1/predict-demand-bulk",
            "eta": "/api/v1/predict-eta",
            "recommend": "/api/v1/recommend"
        }
    }