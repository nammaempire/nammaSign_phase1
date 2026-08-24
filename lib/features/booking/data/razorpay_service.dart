import 'dart:async';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

import '../../../../core/utils/logger.dart';
import '../../../../shared/providers/firebase_providers.dart';

/// Outcome of a checkout attempt. [success] means the payment was made AND
/// verified server-side; the booking is now paid + in admin review.
class PaymentResult {
  const PaymentResult._({
    required this.success,
    this.cancelled = false,
    this.code,
    this.message,
  });

  const PaymentResult.success() : this._(success: true);

  const PaymentResult.cancelled()
      : this._(success: false, cancelled: true, message: 'Payment cancelled');

  const PaymentResult.failed({int? code, String? message})
      : this._(success: false, code: code, message: message);

  final bool success;
  final bool cancelled;
  final int? code;
  final String? message;
}

/// Wraps the Razorpay Checkout flow behind a single awaitable call:
///   create order (Cloud Function) → open Checkout → verify (Cloud Function).
///
/// The amount is decided server-side from the booking document, so nothing
/// the client passes can change what the user is charged.
class RazorpayPaymentService {
  RazorpayPaymentService(this._functions);

  final FirebaseFunctions _functions;

  Future<PaymentResult> payForBooking({
    required String bookingId,
    String? displayName,
    String? email,
    String? contact,
  }) async {
    // 1. Create the order on the server (authoritative amount).
    final Map<String, dynamic> order;
    try {
      final res = await _functions
          .httpsCallable('createRazorpayOrder')
          .call<Map<String, dynamic>>({'bookingId': bookingId});
      order = Map<String, dynamic>.from(res.data as Map);
    } on FirebaseFunctionsException catch (e, st) {
      appLogger.w('createRazorpayOrder failed', error: e, stackTrace: st);
      return PaymentResult.failed(
        message: e.message ?? 'Could not start payment. Please try again.',
      );
    } catch (e, st) {
      appLogger.e('createRazorpayOrder error', error: e, stackTrace: st);
      return const PaymentResult.failed(
        message: 'Could not start payment. Please try again.',
      );
    }

    final orderId = order['orderId'] as String?;
    final keyId = order['keyId'] as String?;
    final amount = (order['amount'] as num?)?.toInt();
    final currency = (order['currency'] as String?) ?? 'INR';
    if (orderId == null || keyId == null || amount == null) {
      return const PaymentResult.failed(
        message: 'Payment is not available right now.',
      );
    }

    // 2. Open the Razorpay Checkout sheet and await the outcome.
    final _CheckoutOutcome outcome = await _openCheckout(
      keyId: keyId,
      orderId: orderId,
      amount: amount,
      currency: currency,
      displayName: displayName,
      email: email,
      contact: contact,
    );

    if (outcome.cancelled) return const PaymentResult.cancelled();
    if (!outcome.isSuccess) {
      return PaymentResult.failed(
        code: outcome.code,
        message: outcome.message,
      );
    }

    // 3. Verify the signature server-side before we trust the payment.
    try {
      final res = await _functions
          .httpsCallable('verifyRazorpayPayment')
          .call<Map<String, dynamic>>({
        'bookingId': bookingId,
        'razorpayOrderId': outcome.orderId,
        'razorpayPaymentId': outcome.paymentId,
        'razorpaySignature': outcome.signature,
      });
      final data = Map<String, dynamic>.from(res.data as Map);
      if (data['verified'] == true) return const PaymentResult.success();
      return const PaymentResult.failed(
        message: 'Payment could not be verified.',
      );
    } catch (e, st) {
      appLogger.w('verifyRazorpayPayment failed', error: e, stackTrace: st);
      // The money may well have been captured — the webhook will settle the
      // booking. Tell the user it's being confirmed rather than "failed".
      return const PaymentResult.failed(
        message: 'Payment is being confirmed. Check History in a minute.',
      );
    }
  }

  Future<_CheckoutOutcome> _openCheckout({
    required String keyId,
    required String orderId,
    required int amount,
    required String currency,
    String? displayName,
    String? email,
    String? contact,
  }) {
    final completer = Completer<_CheckoutOutcome>();
    final razorpay = Razorpay();

    void finish(_CheckoutOutcome outcome) {
      if (!completer.isCompleted) completer.complete(outcome);
    }

    razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS,
        (PaymentSuccessResponse r) {
      finish(_CheckoutOutcome.success(
        paymentId: r.paymentId ?? '',
        orderId: r.orderId ?? orderId,
        signature: r.signature ?? '',
      ));
    });
    razorpay.on(Razorpay.EVENT_PAYMENT_ERROR,
        (PaymentFailureResponse r) {
      // Razorpay reports user-dismissal as PAYMENT_CANCELLED.
      final cancelled = r.code == Razorpay.PAYMENT_CANCELLED;
      finish(cancelled
          ? const _CheckoutOutcome.cancelled()
          : _CheckoutOutcome.error(r.code, r.message));
    });
    razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET,
        (ExternalWalletResponse r) {
      // Selecting an external wallet is not itself a completion — the
      // success/error event still follows. Nothing to do here.
    });

    final prefill = <String, dynamic>{
      if (contact != null && contact.trim().isNotEmpty) 'contact': contact.trim(),
      if (email != null && email.trim().isNotEmpty) 'email': email.trim(),
    };

    final options = <String, dynamic>{
      'key': keyId,
      'order_id': orderId,
      'amount': amount,
      'currency': currency,
      'name': 'Reset95',
      'description': 'Ad campaign booking',
      'timeout': 300, // seconds — auto-dismiss the sheet after 5 min
      'theme': {'color': '#7B2FE3'},
      if (prefill.isNotEmpty) 'prefill': prefill,
    };

    try {
      razorpay.open(options);
    } catch (e, st) {
      appLogger.e('Razorpay.open failed', error: e, stackTrace: st);
      finish(const _CheckoutOutcome.error(0, 'Could not open payment.'));
    }

    // Always clear the native listeners once we have an outcome.
    return completer.future.whenComplete(() {
      Future<void>.delayed(
        const Duration(seconds: 2),
        razorpay.clear,
      );
    });
  }
}

/// Internal result of the native Checkout sheet (before server verification).
class _CheckoutOutcome {
  const _CheckoutOutcome._({
    required this.isSuccess,
    this.cancelled = false,
    this.paymentId,
    this.orderId,
    this.signature,
    this.code,
    this.message,
  });

  const _CheckoutOutcome.success({
    required String paymentId,
    required String orderId,
    required String signature,
  }) : this._(
          isSuccess: true,
          paymentId: paymentId,
          orderId: orderId,
          signature: signature,
        );

  const _CheckoutOutcome.error(int? code, String? message)
      : this._(isSuccess: false, code: code, message: message);

  const _CheckoutOutcome.cancelled()
      : this._(isSuccess: false, cancelled: true, message: 'Payment cancelled');

  final bool isSuccess;
  final bool cancelled;
  final String? paymentId;
  final String? orderId;
  final String? signature;
  final int? code;
  final String? message;
}

final razorpayPaymentServiceProvider = Provider<RazorpayPaymentService>(
  (ref) => RazorpayPaymentService(ref.read(cloudFunctionsProvider)),
);
