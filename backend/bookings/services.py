from django.db import transaction
from django.core.exceptions import ValidationError
from .models import Booking, Payment, Notification

def confirm_booking(booking, payment_method, reference_number=None):
    """
    Confirms a booking, records the payment, and automatically cancels
    any other pending bookings that overlap with this booking's time slot.
    """
    if booking.status == Booking.CONFIRMED:
        return booking

    with transaction.atomic():
        # Concurrency safety: double check if any overlapping confirmed booking got processed
        overlapping_confirmed = Booking.objects.filter(
            court=booking.court,
            booking_date=booking.booking_date,
            status=Booking.CONFIRMED,
        ).exclude(pk=booking.pk).filter(
            start_time__lt=booking.end_time,
            end_time__gt=booking.start_time
        )

        if overlapping_confirmed.exists():
            raise ValidationError("Cannot approve. This slot already has an active confirmed booking.")

        # Update current booking to CONFIRMED
        booking.status = Booking.CONFIRMED
        booking.save()

        # Create/Update the Payment record
        payment_status = Payment.PAY_PENDING
        if payment_method in [Payment.METHOD_ESEWA, Payment.METHOD_KHALTI]:
            payment_status = Payment.PAY_PAID

        Payment.objects.update_or_create(
            booking=booking,
            defaults={
                'amount': booking.total_price,
                'status': payment_status,
                'method': payment_method,
                'reference_number': reference_number
            }
        )

        # Notify user of booking success
        Notification.objects.create(
            user=booking.user,
            title="Booking Confirmed!",
            body=f"Your booking for {booking.court.name} on {booking.booking_date} ({booking.start_time}-{booking.end_time}) is confirmed."
        )

        # Find overlapping pending bookings
        overlapping_pending = Booking.objects.filter(
            court=booking.court,
            booking_date=booking.booking_date,
            status=Booking.PENDING,
        ).exclude(pk=booking.pk).filter(
            start_time__lt=booking.end_time,
            end_time__gt=booking.start_time
        )

        # Cancel overlapping pending bookings
        for pending in overlapping_pending:
            pending.status = Booking.CANCELLED
            pending.save()

            # Create notification for cancelled bookings
            Notification.objects.create(
                user=pending.user,
                title="Booking Cancelled",
                body=f"Your pending booking for {pending.court.name} on {pending.booking_date} ({pending.start_time}-{pending.end_time}) was cancelled because the slot was booked by another user."
            )

    return booking
