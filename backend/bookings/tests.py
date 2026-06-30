from django.test import TestCase
from django.core.exceptions import ValidationError
from django.contrib.auth import get_user_model
from datetime import date, time
from .models import OwnerProfile, Futsal, Court, Booking, Payment
from .services import confirm_booking

User = get_user_model()

class EnterpriseBookingTestCase(TestCase):
    def setUp(self):
        # Create user accounts
        self.owner_user = User.objects.create_user(
            username='futsalowner', password='password123', role=User.OWNER
        )
        self.customer1 = User.objects.create_user(
            username='customer1', password='password123', role=User.CUSTOMER
        )
        self.customer2 = User.objects.create_user(
            username='customer2', password='password123', role=User.CUSTOMER
        )

        # Create profiles
        self.owner_profile = OwnerProfile.objects.create(
            user=self.owner_user,
            company_name='Kickoff Enterprises',
            business_address='Kathmandu, Nepal'
        )

        # Create futsal arena
        self.futsal = Futsal.objects.create(
            owner=self.owner_profile,
            name='Kathmandu Futsal Arena',
            address='Hattisar, Kathmandu',
            contact_phone='9801122334',
            opening_hours=time(6, 0),
            closing_hours=time(22, 0),
            is_approved=True
        )

        # Create court
        self.court = Court.objects.create(
            futsal=self.futsal,
            name='Court A (Indoor)',
            is_indoor=True,
            price_per_hour=1500.00
        )
        self.booking_date = date.today()

    def test_overlapping_confirmed_booking_validation(self):
        # Create first confirmed booking
        booking1 = Booking.objects.create(
            user=self.customer1,
            court=self.court,
            booking_date=self.booking_date,
            start_time=time(6, 0),
            end_time=time(7, 0),
            status=Booking.CONFIRMED,
            total_price=1500.00
        )

        # Attempt overlapping booking (6:30 - 7:30)
        booking2 = Booking(
            user=self.customer2,
            court=self.court,
            booking_date=self.booking_date,
            start_time=time(6, 30),
            end_time=time(7, 30),
            total_price=1500.00
        )

        with self.assertRaises(ValidationError):
            booking2.save()

    def test_booking_confirmation_auto_cancellation(self):
        # Create booking A: 7:00 - 8:00 (PENDING)
        booking_a = Booking.objects.create(
            user=self.customer1,
            court=self.court,
            booking_date=self.booking_date,
            start_time=time(7, 0),
            end_time=time(8, 0),
            total_price=1500.00
        )

        # Create booking B: 7:30 - 8:30 (PENDING - overlapping)
        booking_b = Booking.objects.create(
            user=self.customer2,
            court=self.court,
            booking_date=self.booking_date,
            start_time=time(7, 30),
            end_time=time(8, 30),
            total_price=1500.00
        )

        # Confirm booking A
        confirm_booking(booking_a, Payment.METHOD_ESEWA, 'REF-12345')

        # Reload from DB
        booking_a.refresh_from_db()
        booking_b.refresh_from_db()

        self.assertEqual(booking_a.status, Booking.CONFIRMED)
        self.assertEqual(booking_b.status, Booking.CANCELLED)
        self.assertEqual(booking_a.payment.status, Payment.PAY_PAID)
        self.assertEqual(booking_a.payment.reference_number, 'REF-12345')
