from rest_framework import viewsets, permissions, status, generics, filters
from rest_framework.decorators import action
from rest_framework.response import Response
from django.shortcuts import get_object_or_404
from django.core.exceptions import ValidationError as DjangoValidationError
from rest_framework.exceptions import ValidationError
from django.contrib.auth import get_user_model
from django_filters.rest_framework import DjangoFilterBackend
from django.db import transaction
from rest_framework_simplejwt.views import TokenObtainPairView

from .models import (
    OwnerProfile, CustomerProfile, Facility, Futsal, 
    Court, CourtImage, TimeSlot, Booking, Payment, 
    Review, Favorite, Notification
)
from .serializers import (
    UserRegisterSerializer, UserSerializer, OwnerProfileSerializer,
    CustomerProfileSerializer, FacilitySerializer, FutsalSerializer, 
    CourtSerializer, CourtImageSerializer, TimeSlotSerializer, 
    BookingSerializer, PaymentSerializer, ReviewSerializer, 
    FavoriteSerializer, NotificationSerializer, CustomTokenObtainPairSerializer
)
from .services import confirm_booking

User = get_user_model()

# --- Role-Based Access Control Permissions ---

class IsAdminRole(permissions.BasePermission):
    def has_permission(self, request, view):
        return request.user and request.user.is_authenticated and request.user.role == User.ADMIN


class IsOwnerRole(permissions.BasePermission):
    def has_permission(self, request, view):
        return request.user and request.user.is_authenticated and request.user.role == User.OWNER


class IsCustomerRole(permissions.BasePermission):
    def has_permission(self, request, view):
        return request.user and request.user.is_authenticated and request.user.role == User.CUSTOMER


class IsOwnerOrAdminOrReadOnly(permissions.BasePermission):
    def has_permission(self, request, view):
        if request.method in permissions.SAFE_METHODS:
            return True
        return request.user and request.user.is_authenticated and request.user.role in [User.OWNER, User.ADMIN]


# --- Authentication API ---

class UserRegisterView(generics.CreateAPIView):
    queryset = User.objects.all()
    serializer_class = UserRegisterSerializer
    permission_classes = [permissions.AllowAny]


class UserProfileView(generics.RetrieveUpdateAPIView):
    serializer_class = UserSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_object(self):
        return self.request.user


# --- Facility API ---

class FacilityViewSet(viewsets.ModelViewSet):
    queryset = Facility.objects.all()
    serializer_class = FacilitySerializer
    permission_classes = [IsOwnerOrAdminOrReadOnly]


# --- Futsal API ---

class FutsalViewSet(viewsets.ModelViewSet):
    queryset = Futsal.objects.all()
    serializer_class = FutsalSerializer
    permission_classes = [permissions.IsAuthenticated]
    filter_backends = [DjangoFilterBackend, filters.SearchFilter, filters.OrderingFilter]
    filterset_fields = ['is_approved']
    search_fields = ['name', 'address']
    ordering_fields = ['created_at', 'name']

    def get_queryset(self):
        user = self.request.user
        if user.role == User.ADMIN:
            return Futsal.objects.all()
        elif user.role == User.OWNER:
            # Owners see only their own futsals
            owner_profile = get_object_or_404(OwnerProfile, user=user)
            return Futsal.objects.filter(owner=owner_profile)
        # Customers only see approved futsals
        return Futsal.objects.filter(is_approved=True)

    def perform_create(self, serializer):
        owner_profile = get_object_or_404(OwnerProfile, user=self.request.user)
        # Owners must register futsals as unapproved first
        serializer.save(owner=owner_profile, is_approved=False)

    @action(detail=True, methods=['post'], permission_classes=[IsAdminRole])
    def approve(self, request, pk=None):
        futsal = self.get_object()
        futsal.is_approved = True
        futsal.save()
        return Response({"status": "Futsal listing approved"}, status=status.HTTP_200_OK)

    @action(detail=True, methods=['post'], permission_classes=[IsAdminRole])
    def reject(self, request, pk=None):
        futsal = self.get_object()
        futsal.is_approved = False
        futsal.save()
        return Response({"status": "Futsal listing rejected/unapproved"}, status=status.HTTP_200_OK)


# --- Court API ---

class CourtViewSet(viewsets.ModelViewSet):
    serializer_class = CourtSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        user = self.request.user
        futsal_id = self.request.query_params.get('futsal')
        
        queryset = Court.objects.all()
        if futsal_id:
            queryset = queryset.filter(futsal_id=futsal_id)

        if user.role == User.ADMIN:
            return queryset
        elif user.role == User.OWNER:
            owner_profile = get_object_or_404(OwnerProfile, user=user)
            return queryset.filter(futsal__owner=owner_profile)
        
        # Customers can only view courts of approved futsals
        return queryset.filter(futsal__is_approved=True, status=Court.STATUS_ACTIVE)


# --- Booking API ---

class BookingViewSet(viewsets.ModelViewSet):
    serializer_class = BookingSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        user = self.request.user
        if user.role == User.ADMIN:
            return Booking.objects.all()
        elif user.role == User.OWNER:
            owner_profile = get_object_or_404(OwnerProfile, user=user)
            return Booking.objects.filter(court__futsal__owner=owner_profile)
        # Customer sees their own
        return Booking.objects.filter(user=user)

    def perform_create(self, serializer):
        serializer.save()

    @action(detail=True, methods=['post'])
    def confirm(self, request, pk=None):
        booking = self.get_object()
        payment_method = request.data.get('payment_method')
        reference_number = request.data.get('reference_number')

        if not payment_method:
            return Response({"error": "Payment method is required"}, status=status.HTTP_400_BAD_REQUEST)

        # Allow payment confirmation for customers or owners/admins
        try:
            confirm_booking(booking, payment_method, reference_number)
            return Response({
                "status": "Booking confirmed and payment processed",
                "booking": BookingSerializer(booking).data
            }, status=status.HTTP_200_OK)
        except DjangoValidationError as e:
            raise ValidationError(e.message)

    @action(detail=True, methods=['post'])
    def cancel(self, request, pk=None):
        booking = self.get_object()
        user = request.user

        # Business Rule: customers can cancel only pending bookings, owners/admins can cancel any
        if user.role == User.CUSTOMER and booking.user != user:
            return Response({"error": "Unauthorized"}, status=status.HTTP_403_FORBIDDEN)
        
        if user.role == User.CUSTOMER and booking.status != Booking.PENDING:
            return Response({"error": "Customers can only cancel pending bookings"}, status=status.HTTP_400_BAD_REQUEST)

        with transaction.atomic():
            booking.status = Booking.CANCELLED
            booking.save()

            # Update associated payment if exists
            if hasattr(booking, 'payment'):
                payment = booking.payment
                payment.status = Payment.PAY_FAILED
                payment.save()

            Notification.objects.create(
                user=booking.user,
                title="Booking Cancelled",
                body=f"Your booking for {booking.court.name} has been cancelled."
            )

        return Response({"status": "Booking cancelled successfully"}, status=status.HTTP_200_OK)


# --- Review API ---

class ReviewViewSet(viewsets.ModelViewSet):
    serializer_class = ReviewSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        futsal_id = self.request.query_params.get('futsal')
        if futsal_id:
            return Review.objects.filter(futsal_id=futsal_id)
        return Review.objects.all()

    def perform_create(self, serializer):
        serializer.save(user=self.request.user)


# --- Favorites API ---

class FavoriteViewSet(viewsets.ModelViewSet):
    serializer_class = FavoriteSerializer
    permission_classes = [permissions.IsAuthenticated, IsCustomerRole]

    def get_queryset(self):
        return Favorite.objects.filter(user=self.request.user)

    def perform_create(self, serializer):
        serializer.save(user=self.request.user)


# --- Notification API ---

class NotificationViewSet(viewsets.ReadOnlyModelViewSet):
    serializer_class = NotificationSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        return Notification.objects.filter(user=self.request.user).order_by('-created_at')

    @action(detail=False, methods=['post'])
    def mark_all_read(self, request):
        Notification.objects.filter(user=request.user, is_read=False).update(is_read=True)
        return Response({"status": "All notifications marked as read"}, status=status.HTTP_200_OK)


class CustomTokenObtainPairView(TokenObtainPairView):
    serializer_class = CustomTokenObtainPairSerializer


class OwnerProfileViewSet(viewsets.ModelViewSet):
    queryset = OwnerProfile.objects.all()
    serializer_class = OwnerProfileSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        user = self.request.user
        if user.role == User.ADMIN:
            return OwnerProfile.objects.all()
        elif user.role == User.OWNER:
            return OwnerProfile.objects.filter(user=user)
        return OwnerProfile.objects.none()

    @action(detail=True, methods=['post'], permission_classes=[IsAdminRole])
    def approve(self, request, pk=None):
        profile = self.get_object()
        profile.is_verified = True
        profile.save()
        return Response({"status": "Owner account approved/verified"}, status=status.HTTP_200_OK)

    @action(detail=True, methods=['post'], permission_classes=[IsAdminRole])
    def reject(self, request, pk=None):
        profile = self.get_object()
        user = profile.user
        profile.delete()
        user.delete()
        return Response({"status": "Owner account rejected and deleted"}, status=status.HTTP_200_OK)

