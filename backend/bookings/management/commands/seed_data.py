from django.core.management.base import BaseCommand
from django.contrib.auth import get_user_model
from bookings.models import OwnerProfile, CustomerProfile, Facility, Futsal, Court, Booking, Payment, TimeSlot
from datetime import date, time, timedelta

User = get_user_model()

class Command(BaseCommand):
    help = 'Seeds database with realistic data for enterprise roles (Admin, Owner, Customer)'

    def handle(self, *args, **kwargs):
        self.stdout.write('Seeding database with enterprise datasets...')

        # 1. Create Admin
        admin, created = User.objects.get_or_create(
            username='admin',
            email='admin@futsal.com',
            defaults={'role': User.ADMIN, 'is_staff': True, 'is_superuser': True}
        )
        if created:
            admin.set_password('admin123')
            admin.save()
            self.stdout.write('Created Admin user (admin / admin123)')

        # 2. Create Owner
        owner_user, created = User.objects.get_or_create(
            username='owner',
            email='owner@futsal.com',
            defaults={'role': User.OWNER}
        )
        if created:
            owner_user.set_password('owner123')
            owner_user.save()
            self.stdout.write('Created Owner user (owner / owner123)')

        owner_profile, _ = OwnerProfile.objects.get_or_create(
            user=owner_user,
            defaults={
                'company_name': 'Kickoff Futsal Arena Pvt. Ltd.',
                'pan_number': '601234567',
                'business_address': 'Jhamsikhel, Lalitpur',
                'is_verified': True
            }
        )

        # 3. Create Customer
        customer_user, created = User.objects.get_or_create(
            username='customer',
            email='customer@futsal.com',
            defaults={'role': User.CUSTOMER}
        )
        if created:
            customer_user.set_password('customer123')
            customer_user.save()
            self.stdout.write('Created Customer user (customer / customer123)')

        customer_profile, _ = CustomerProfile.objects.get_or_create(
            user=customer_user,
            defaults={
                'phone': '9841234567',
                'avatar_url': 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?q=80&w=150&auto=format&fit=crop'
            }
        )

        # 4. Create Facilities
        facility_names = ['Parking', 'Shower', 'WiFi', 'Cafeteria', 'Floodlights', 'Locker Room', 'Drinking Water']
        facilities = {}
        for name in facility_names:
            fac, _ = Facility.objects.get_or_create(name=name)
            facilities[name] = fac

        # 5. Create Futsals
        futsal1, _ = Futsal.objects.get_or_create(
            owner=owner_profile,
            name='Apex Futsal Arena',
            defaults={
                'address': 'Jhamsikhel, Lalitpur',
                'contact_phone': '01-5544332',
                'latitude': 27.6800,
                'longitude': 85.3120,
                'opening_hours': time(6, 0),
                'closing_hours': time(22, 0),
                'is_approved': True,
                'logo': 'logos/apex_logo.png',
                'cover_image': 'covers/apex_cover.png',
                'description': 'Apex Futsal Arena is Lalitpur\'s premier sporting destination. Featuring premium FIFA-standard indoor wooden flooring, top-tier lighting systems, high-speed free WiFi, changing rooms with hot showers, and a spacious cafeteria serving healthy refreshments. Ideal for both casual matches and professional tournaments.'
            }
        )
        futsal1.facilities.set([facilities['Parking'], facilities['Shower'], facilities['WiFi'], facilities['Cafeteria']])

        futsal2, _ = Futsal.objects.get_or_create(
            owner=owner_profile,
            name='Elite Futsal Hub',
            defaults={
                'address': 'Hattisar, Kathmandu',
                'contact_phone': '01-4433221',
                'latitude': 27.7120,
                'longitude': 85.3280,
                'opening_hours': time(6, 0),
                'closing_hours': time(22, 0),
                'is_approved': True,
                'logo': 'logos/elite_logo.png',
                'cover_image': 'covers/elite_cover.png',
                'description': 'Elite Futsal Hub located in the heart of Hattisar, Kathmandu offers a premium playing experience. Equipped with professional shock-absorbent indoor rubber court flooring, professional floodlights, lockers, and clean drinking water facilities. We also offer coaching sessions and regular amateur leagues.'
            }
        )
        futsal2.facilities.set([facilities['Parking'], facilities['Locker Room'], facilities['Drinking Water'], facilities['Floodlights']])

        # Unapproved futsal to test Admin Approvals
        futsal3, _ = Futsal.objects.get_or_create(
            owner=owner_profile,
            name='Valley Futsal Ground',
            defaults={
                'address': 'Koteshwor, Kathmandu',
                'contact_phone': '01-4477889',
                'latitude': 27.6740,
                'longitude': 85.3480,
                'opening_hours': time(7, 0),
                'closing_hours': time(21, 0),
                'is_approved': False,
                'logo': 'logos/valley_logo.png',
                'cover_image': 'covers/valley_cover.png',
                'description': 'Valley Futsal Ground in Koteshwor, Kathmandu features outdoor artificial turf pitches. Great ventilation, scenic open-air environment, parking space, and refreshments bar. Perfect for weekend games with friends.'
            }
        )

        # 6. Create Courts
        court1, _ = Court.objects.get_or_create(
            futsal=futsal1,
            name='Standard Pitch A (Indoor)',
            defaults={'is_indoor': True, 'price_per_hour': 1500.00, 'description': 'Wooden flooring indoor standard pitch'}
        )
        court2, _ = Court.objects.get_or_create(
            futsal=futsal1,
            name='Standard Pitch B (Outdoor)',
            defaults={'is_indoor': False, 'price_per_hour': 1200.00, 'description': 'Artificial turf outdoor standard pitch'}
        )
        court3, _ = Court.objects.get_or_create(
            futsal=futsal2,
            name='Championship Court 1 (Indoor)',
            defaults={'is_indoor': True, 'price_per_hour': 1800.00, 'description': 'Premium rubber floor standard futsal pitch'}
        )

        # 7. Create pre-determined bookings
        booking_dates = [date.today(), date.today() + timedelta(days=1)]
        
        # Booking 1: Confirmed and Paid
        b1, b1_created = Booking.objects.get_or_create(
            user=customer_user,
            court=court1,
            booking_date=booking_dates[0],
            start_time=time(8, 0),
            end_time=time(9, 0),
            defaults={'status': Booking.CONFIRMED, 'total_price': 1500.00}
        )
        if b1_created:
            Payment.objects.create(
                booking=b1,
                amount=1500.00,
                status=Payment.PAY_PAID,
                method=Payment.METHOD_ESEWA,
                reference_number='ESEWA-MOCK-REF-992'
            )

        # Booking 2: Pending Unpaid
        Booking.objects.get_or_create(
            user=customer_user,
            court=court1,
            booking_date=booking_dates[0],
            start_time=time(10, 0),
            end_time=time(11, 0),
            defaults={'status': Booking.PENDING, 'total_price': 1500.00}
        )

        # Booking 3: Confirmed via Cash (Payment Status Pending)
        b3, b3_created = Booking.objects.get_or_create(
            user=customer_user,
            court=court3,
            booking_date=booking_dates[1],
            start_time=time(16, 0),
            end_time=time(17, 0),
            defaults={'status': Booking.CONFIRMED, 'total_price': 1800.00}
        )
        if b3_created:
            Payment.objects.create(
                booking=b3,
                amount=1800.00,
                status=Payment.PAY_PENDING,
                method=Payment.METHOD_CASH
            )

        self.stdout.write(self.style.SUCCESS('Enterprise seed data loaded successfully.'))
