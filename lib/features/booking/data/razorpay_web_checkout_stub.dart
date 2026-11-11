/// Non-web placeholder for the browser Razorpay checkout. Android / iOS use
/// the native `razorpay_flutter` sheet and never call this.
Future<Map<String, Object?>> openRazorpayWebCheckout(
  Map<String, dynamic> options,
) {
  throw UnsupportedError('Web checkout is only available on web.');
}
