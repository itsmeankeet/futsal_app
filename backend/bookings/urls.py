from django.urls import path, include
from rest_framework.routers import DefaultRouter
from rest_framework_simplejwt.views import TokenObtainPairView, TokenRefreshView
from drf_spectacular.views import SpectacularAPIView, SpectacularRedocView, SpectacularSwaggerView

from .views import (
    UserRegisterView, UserProfileView, FacilityViewSet, 
    FutsalViewSet, CourtViewSet, BookingViewSet, 
    ReviewViewSet, FavoriteViewSet, NotificationViewSet,
    OwnerProfileViewSet, CustomTokenObtainPairView
)

router = DefaultRouter()
router.register(r'facilities', FacilityViewSet, basename='facility')
router.register(r'futsals', FutsalViewSet, basename='futsal')
router.register(r'courts', CourtViewSet, basename='court')
router.register(r'bookings', BookingViewSet, basename='booking')
router.register(r'reviews', ReviewViewSet, basename='review')
router.register(r'favorites', FavoriteViewSet, basename='favorite')
router.register(r'notifications', NotificationViewSet, basename='notification')
router.register(r'owners', OwnerProfileViewSet, basename='owner')

v1_urlpatterns = [
    # Authentication
    path('auth/register/', UserRegisterView.as_view(), name='register'),
    path('auth/login/', CustomTokenObtainPairView.as_view(), name='login'),
    path('auth/token/refresh/', TokenRefreshView.as_view(), name='token_refresh'),
    path('auth/profile/', UserProfileView.as_view(), name='profile'),
    
    # OpenAPI Swagger Docs
    path('schema/', SpectacularAPIView.as_view(), name='schema'),
    path('schema/swagger-ui/', SpectacularSwaggerView.as_view(url_name='schema'), name='swagger-ui'),
    path('schema/redoc/', SpectacularRedocView.as_view(url_name='schema'), name='redoc'),

    # Viewsets Include
    path('', include(router.urls)),
]

urlpatterns = [
    path('v1/', include(v1_urlpatterns)),
]
