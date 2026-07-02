import uuid
from django.db import models
from django.contrib.auth.models import AbstractUser
from django.conf import settings
from django.core.exceptions import ValidationError
from django.db import transaction

# 1. Custom User Model (UUID Primary Key)
class User(AbstractUser):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    
    ADMIN = 'ADMIN'
    OWNER = 'OWNER'
    CUSTOMER = 'CUSTOMER'
    ROLE_CHOICES = [
        (ADMIN, 'Admin'),
        (OWNER, 'Futsal Owner'),
        (CUSTOMER, 'Customer'),
    ]
    role = models.CharField(max_length=15, choices=ROLE_CHOICES, default=CUSTOMER)

    def __str__(self):
        return f"{self.username} ({self.role})"


# 2. Owner Profile
class OwnerProfile(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    user = models.OneToOneField(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='owner_profile')
    company_name = models.CharField(max_length=150)
    pan_number = models.CharField(max_length=20, blank=True, null=True)
    business_address = models.CharField(max_length=250)
    is_verified = models.BooleanField(default=False)

    def __str__(self):
        return f"{self.company_name} (Verified: {self.is_verified})"


# 3. Customer Profile
class CustomerProfile(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    user = models.OneToOneField(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='customer_profile')
    phone = models.CharField(max_length=15)
    avatar_url = models.URLField(max_length=500, blank=True, null=True)

    def __str__(self):
        return self.user.username


# 4. Futsal Facility Model
class Facility(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    name = models.CharField(max_length=50, unique=True) # e.g., Parking, Shower, WiFi, Locker Room

    class Meta:
        verbose_name_plural = "Facilities"

    def __str__(self):
        return self.name


# 5. Futsal Arena Model
class Futsal(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    owner = models.ForeignKey(OwnerProfile, on_delete=models.CASCADE, related_name='futsals')
    name = models.CharField(max_length=150)
    address = models.CharField(max_length=250)
    contact_phone = models.CharField(max_length=15)
    latitude = models.FloatField(blank=True, null=True)
    longitude = models.FloatField(blank=True, null=True)
    opening_hours = models.TimeField()
    closing_hours = models.TimeField()
    is_approved = models.BooleanField(default=False)
    is_closed_today = models.BooleanField(default=False)
    description = models.TextField(blank=True, null=True)
    logo = models.ImageField(upload_to='logos/', blank=True, null=True)
    cover_image = models.ImageField(upload_to='covers/', blank=True, null=True)
    facilities = models.ManyToManyField(Facility, related_name='futsals', blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    def __str__(self):
        return self.name


# 6. Court Model
class Court(models.Model):
    STATUS_ACTIVE = 'ACTIVE'
    STATUS_MAINTENANCE = 'MAINTENANCE'
    STATUS_DISABLED = 'DISABLED'
    STATUS_CHOICES = [
        (STATUS_ACTIVE, 'Active'),
        (STATUS_MAINTENANCE, 'Maintenance Mode'),
        (STATUS_DISABLED, 'Disabled'),
    ]

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    futsal = models.ForeignKey(Futsal, on_delete=models.CASCADE, related_name='courts')
    name = models.CharField(max_length=100)
    is_indoor = models.BooleanField(default=True)
    price_per_hour = models.DecimalField(max_digits=10, decimal_places=2)
    description = models.TextField(blank=True, null=True)
    status = models.CharField(max_length=15, choices=STATUS_CHOICES, default=STATUS_ACTIVE)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    def __str__(self):
        return f"{self.futsal.name} - {self.name}"


# 7. Court Additional Images
class CourtImage(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    court = models.ForeignKey(Court, on_delete=models.CASCADE, related_name='images')
    image = models.ImageField(upload_to='courts/', blank=True, null=True)

    def __str__(self):
        return f"Image for {self.court}"


# 8. Custom Time Slot (For Owner-specific pricing/management)
class TimeSlot(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    court = models.ForeignKey(Court, on_delete=models.CASCADE, related_name='timeslots')
    start_time = models.TimeField()
    end_time = models.TimeField()
    is_active = models.BooleanField(default=True)
    weekend_price = models.DecimalField(max_digits=10, decimal_places=2, blank=True, null=True)
    holiday_price = models.DecimalField(max_digits=10, decimal_places=2, blank=True, null=True)

    def __str__(self):
        return f"{self.court} ({self.start_time}-{self.end_time})"


# 9. Booking Model
class Booking(models.Model):
    PENDING = 'PENDING'
    CONFIRMED = 'CONFIRMED'
    CANCELLED = 'CANCELLED'
    STATUS_CHOICES = [
        (PENDING, 'Pending'),
        (CONFIRMED, 'Confirmed'),
        (CANCELLED, 'Cancelled'),
    ]

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='futsal_bookings')
    court = models.ForeignKey(Court, on_delete=models.CASCADE, related_name='futsal_bookings')
    booking_date = models.DateField()
    start_time = models.TimeField()
    end_time = models.TimeField()
    status = models.CharField(max_length=15, choices=STATUS_CHOICES, default=PENDING)
    total_price = models.DecimalField(max_digits=10, decimal_places=2)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ['-booking_date', '-start_time']

    def __str__(self):
        return f"{self.user.username} - {self.court.name} ({self.booking_date} {self.start_time}-{self.end_time})"

    def clean(self):
        super().clean()
        if self.start_time >= self.end_time:
            raise ValidationError("Start time must be before end time.")

        if self.status != Booking.CANCELLED:
            # Concurrency safety overlap checking
            overlapping_confirmed = Booking.objects.filter(
                court=self.court,
                booking_date=self.booking_date,
                status=Booking.CONFIRMED,
            ).exclude(pk=self.pk).filter(
                start_time__lt=self.end_time,
                end_time__gt=self.start_time
            )

            if overlapping_confirmed.exists():
                raise ValidationError("This time slot has already been booked and confirmed.")

    def save(self, *args, **kwargs):
        self.clean()
        super().save(*args, **kwargs)


# 10. Payment Details
class Payment(models.Model):
    PAY_PENDING = 'PENDING'
    PAY_PAID = 'PAID'
    PAY_FAILED = 'FAILED'
    PAYMENT_STATUS_CHOICES = [
        (PAY_PENDING, 'Pending'),
        (PAY_PAID, 'Paid'),
        (PAY_FAILED, 'Failed'),
    ]

    METHOD_ESEWA = 'ESEWA'
    METHOD_KHALTI = 'KHALTI'
    METHOD_CASH = 'CASH'
    METHOD_CHOICES = [
        (METHOD_ESEWA, 'eSewa'),
        (METHOD_KHALTI, 'Khalti'),
        (METHOD_CASH, 'Cash'),
    ]

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    booking = models.OneToOneField(Booking, on_delete=models.CASCADE, related_name='payment')
    amount = models.DecimalField(max_digits=10, decimal_places=2)
    status = models.CharField(max_length=15, choices=PAYMENT_STATUS_CHOICES, default=PAY_PENDING)
    method = models.CharField(max_length=15, choices=METHOD_CHOICES)
    reference_number = models.CharField(max_length=100, blank=True, null=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    def __str__(self):
        return f"Payment #{self.id} for Booking #{self.booking.id} - Status: {self.status}"


# 11. Review
class Review(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='futsal_reviews')
    futsal = models.ForeignKey(Futsal, on_delete=models.CASCADE, related_name='reviews')
    rating = models.IntegerField()
    comment = models.TextField()
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"{self.user.username} - {self.futsal.name} ({self.rating}/5)"


# 12. Favorite
class Favorite(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='futsal_favorites')
    futsal = models.ForeignKey(Futsal, on_delete=models.CASCADE, related_name='favorites')

    class Meta:
        unique_together = ('user', 'futsal')

    def __str__(self):
        return f"{self.user.username} likes {self.futsal.name}"


# 13. Notification
class Notification(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='notifications')
    title = models.CharField(max_length=150)
    body = models.TextField()
    is_read = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"Notification to {self.user.username}: {self.title}"
