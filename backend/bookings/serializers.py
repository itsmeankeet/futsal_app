from rest_framework import serializers
from django.contrib.auth import get_user_model
from django.contrib.auth.hashers import make_password
from django.db import transaction
from datetime import datetime, date
from decimal import Decimal
from .models import (
    OwnerProfile, CustomerProfile, Facility, Futsal, 
    Court, CourtImage, TimeSlot, Booking, Payment, 
    Review, Favorite, Notification
)

User = get_user_model()

class OwnerProfileSerializer(serializers.ModelSerializer):
    username = serializers.ReadOnlyField(source='user.username')
    email = serializers.ReadOnlyField(source='user.email')

    class Meta:
        model = OwnerProfile
        fields = ['id', 'username', 'email', 'company_name', 'pan_number', 'business_address', 'is_verified']
        read_only_fields = ['is_verified']


class CustomerProfileSerializer(serializers.ModelSerializer):
    class Meta:
        model = CustomerProfile
        fields = ['phone', 'avatar_url']


class UserRegisterSerializer(serializers.ModelSerializer):
    company_name = serializers.CharField(write_only=True, required=False, allow_null=True, allow_blank=True)
    pan_number = serializers.CharField(write_only=True, required=False, allow_null=True, allow_blank=True)
    business_address = serializers.CharField(write_only=True, required=False, allow_null=True, allow_blank=True)
    phone = serializers.CharField(write_only=True, required=False, allow_null=True, allow_blank=True)
    avatar_url = serializers.URLField(write_only=True, required=False, allow_null=True, allow_blank=True)

    class Meta:
        model = User
        fields = [
            'id', 'username', 'email', 'password', 'role', 
            'phone', 'avatar_url', 'company_name', 'pan_number', 'business_address'
        ]
        extra_kwargs = {
            'password': {'write_only': True},
            'role': {'required': True}
        }

    def validate(self, data):
        role = data.get('role')
        if role == User.OWNER:
            if not data.get('company_name') or not data.get('business_address'):
                raise serializers.ValidationError("Futsal owners require company name and business address.")
        elif role == User.CUSTOMER:
            if not data.get('phone'):
                raise serializers.ValidationError("Customers require phone number.")
        return data

    def create(self, validated_data):
        with transaction.atomic():
            company_name = validated_data.pop('company_name', '')
            pan_number = validated_data.pop('pan_number', '')
            business_address = validated_data.pop('business_address', '')
            phone = validated_data.pop('phone', '')
            avatar_url = validated_data.pop('avatar_url', '')

            # Create User
            validated_data['password'] = make_password(validated_data['password'])
            user = super().create(validated_data)

            # Create profiles based on roles
            if user.role == User.OWNER:
                OwnerProfile.objects.create(
                    user=user,
                    company_name=company_name,
                    pan_number=pan_number,
                    business_address=business_address
                )
            elif user.role == User.CUSTOMER:
                CustomerProfile.objects.create(
                    user=user,
                    phone=phone,
                    avatar_url=avatar_url
                )

        return user


class UserSerializer(serializers.ModelSerializer):
    owner_profile = OwnerProfileSerializer(read_only=True)
    customer_profile = CustomerProfileSerializer(read_only=True)

    class Meta:
        model = User
        fields = ['id', 'username', 'email', 'role', 'owner_profile', 'customer_profile']


class FacilitySerializer(serializers.ModelSerializer):
    class Meta:
        model = Facility
        fields = '__all__'


class FutsalSerializer(serializers.ModelSerializer):
    facilities = FacilitySerializer(many=True, read_only=True)
    facility_ids = serializers.PrimaryKeyRelatedField(
        queryset=Facility.objects.all(), write_only=True, many=True, source='facilities'
    )
    average_rating = serializers.SerializerMethodField()
    owner_company = serializers.ReadOnlyField(source='owner.company_name')

    class Meta:
        model = Futsal
        fields = [
            'id', 'owner', 'owner_company', 'name', 'address', 'contact_phone', 
            'latitude', 'longitude', 'opening_hours', 'closing_hours', 
            'is_approved', 'is_closed_today', 'logo', 'cover_image', 'facilities', 
            'facility_ids', 'average_rating', 'created_at', 'description'
        ]
        read_only_fields = ['owner', 'is_approved']

    def get_average_rating(self, obj):
        reviews = obj.reviews.all()
        if not reviews:
            return 0.0
        return sum(r.rating for r in reviews) / len(reviews)


class CourtImageSerializer(serializers.ModelSerializer):
    class Meta:
        model = CourtImage
        fields = '__all__'


class CourtSerializer(serializers.ModelSerializer):
    images = CourtImageSerializer(many=True, read_only=True)
    futsal_name = serializers.ReadOnlyField(source='futsal.name')

    class Meta:
        model = Court
        fields = [
            'id', 'futsal', 'futsal_name', 'name', 'is_indoor', 
            'price_per_hour', 'description', 'status', 'images'
        ]

    def create(self, validated_data):
        court = super().create(validated_data)
        request = self.context.get('request')
        if request and request.FILES:
            files = request.FILES.getlist('images')
            for f in files:
                CourtImage.objects.create(court=court, image=f)
        return court


class TimeSlotSerializer(serializers.ModelSerializer):
    class Meta:
        model = TimeSlot
        fields = '__all__'


class PaymentSerializer(serializers.ModelSerializer):
    class Meta:
        model = Payment
        fields = '__all__'


class BookingSerializer(serializers.ModelSerializer):
    user = UserSerializer(read_only=True)
    court_details = CourtSerializer(source='court', read_only=True)
    payment = PaymentSerializer(read_only=True)

    class Meta:
        model = Booking
        fields = [
            'id', 'user', 'court', 'court_details', 'booking_date', 
            'start_time', 'end_time', 'status', 'total_price', 'payment', 'created_at'
        ]
        read_only_fields = ['status', 'total_price', 'created_at']

    def validate(self, data):
        court = data.get('court')
        booking_date = data.get('booking_date')
        start_time = data.get('start_time')
        end_time = data.get('end_time')

        if start_time >= end_time:
            raise serializers.ValidationError("Start time must be before end time.")

        if booking_date < date.today():
            raise serializers.ValidationError("Booking date cannot be in the past.")

        if booking_date == date.today() and court.futsal.is_closed_today:
            raise serializers.ValidationError("This futsal is closed today and cannot accept bookings.")

        if court.status != Court.STATUS_ACTIVE:
            raise serializers.ValidationError("This court is currently not active or under maintenance.")

        # Overlapping check for confirmed bookings
        overlapping = Booking.objects.filter(
            court=court,
            booking_date=booking_date,
            status=Booking.CONFIRMED,
        ).filter(
            start_time__lt=end_time,
            end_time__gt=start_time
        )
        if overlapping.exists():
            raise serializers.ValidationError("Time slot overlaps with an already confirmed booking.")

        return data

    def create(self, validated_data):
        court = validated_data['court']
        start = validated_data['start_time']
        end = validated_data['end_time']

        dummy_date = date.today()
        dt_start = datetime.combine(dummy_date, start)
        dt_end = datetime.combine(dummy_date, end)
        duration_hours = Decimal((dt_end - dt_start).total_seconds() / 3600.0)

        # Standard price calculation
        validated_data['total_price'] = duration_hours * court.price_per_hour
        validated_data['user'] = self.context['request'].user
        
        return super().create(validated_data)


class ReviewSerializer(serializers.ModelSerializer):
    username = serializers.ReadOnlyField(source='user.username')

    class Meta:
        model = Review
        fields = ['id', 'user', 'username', 'futsal', 'rating', 'comment', 'created_at']
        read_only_fields = ['user']

    def validate(self, data):
        # Only customers who have completed a booking can review
        user = self.context['request'].user
        futsal = data.get('futsal')

        has_booked = Booking.objects.filter(
            user=user,
            court__futsal=futsal,
            status=Booking.CONFIRMED, # Confirmed represents completed bookings
            booking_date__lte=date.today()
        ).exists()

        if not has_booked:
            raise serializers.ValidationError("Only customers who completed a booking at this futsal can leave a review.")
        return data


class FavoriteSerializer(serializers.ModelSerializer):
    futsal_details = FutsalSerializer(source='futsal', read_only=True)

    class Meta:
        model = Favorite
        fields = ['id', 'futsal', 'futsal_details']


class NotificationSerializer(serializers.ModelSerializer):
    class Meta:
        model = Notification
        fields = ['id', 'title', 'body', 'is_read', 'created_at']


from rest_framework_simplejwt.serializers import TokenObtainPairSerializer

class CustomTokenObtainPairSerializer(TokenObtainPairSerializer):
    def validate(self, attrs):
        data = super().validate(attrs)
        # Check if user is owner and verified
        if self.user.role == 'OWNER':
            if not hasattr(self.user, 'owner_profile') or not self.user.owner_profile.is_verified:
                raise serializers.ValidationError("Your owner account is pending admin approval.")
        return data

