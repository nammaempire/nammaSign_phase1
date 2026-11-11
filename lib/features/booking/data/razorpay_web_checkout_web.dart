import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

const _scriptUrl = 'https://checkout.razorpay.com/v1/checkout.js';

Future<void>? _scriptLoad;

/// Loads Razorpay's checkout.js once (the `razorpay_flutter` plugin is
/// Android / iOS only, so web uses Razorpay's standard browser checkout).
Future<void> _ensureScript() {
  if (globalContext.has('Razorpay')) return Future<void>.value();
  final existing = _scriptLoad;
  if (existing != null) return existing;

  final completer = Completer<void>();
  final document = globalContext['document'] as JSObject;
  final script = document.callMethod<JSObject>(
    'createElement'.toJS,
    'script'.toJS,
  );
  script['src'] = _scriptUrl.toJS;
  script['onload'] = ((JSAny? _) {
    if (!completer.isCompleted) completer.complete();
  }).toJS;
  script['onerror'] = ((JSAny? _) {
    _scriptLoad = null; // allow a retry on the next attempt
    if (!completer.isCompleted) {
      completer.completeError(StateError('checkout.js failed to load'));
    }
  }).toJS;
  (document['head'] as JSObject).callMethod<JSAny?>('appendChild'.toJS, script);
  return _scriptLoad = completer.future;
}

String? _str(JSObject o, String key) {
  final v = o[key];
  if (v == null || !v.isA<JSString>()) return null;
  return (v as JSString).toDart;
}

/// Opens Razorpay Checkout in the browser and resolves with one of:
///   {status: 'success', paymentId, orderId, signature}
///   {status: 'cancelled'}
///   {status: 'error', message}
Future<Map<String, Object?>> openRazorpayWebCheckout(
  Map<String, dynamic> options,
) async {
  try {
    await _ensureScript();
  } catch (_) {
    return {'status': 'error', 'message': 'Could not open payment.'};
  }

  final completer = Completer<Map<String, Object?>>();
  String? lastFailure;

  void finish(Map<String, Object?> result) {
    if (!completer.isCompleted) completer.complete(result);
  }

  final jsOptions = options.jsify() as JSObject;
  jsOptions['handler'] = ((JSObject response) {
    finish({
      'status': 'success',
      'paymentId': _str(response, 'razorpay_payment_id'),
      'orderId': _str(response, 'razorpay_order_id'),
      'signature': _str(response, 'razorpay_signature'),
    });
  }).toJS;
  // Closing the sheet: a plain close is a cancel; closing after a declined
  // attempt is reported as that failure.
  final modal = JSObject();
  modal['ondismiss'] = ((JSAny? _) {
    finish(
      lastFailure == null
          ? {'status': 'cancelled'}
          : {'status': 'error', 'message': lastFailure},
    );
  }).toJS;
  jsOptions['modal'] = modal;

  try {
    final ctor = globalContext['Razorpay'] as JSFunction;
    final checkout = ctor.callAsConstructor<JSObject>(jsOptions);
    checkout.callMethod<JSAny?>(
      'on'.toJS,
      'payment.failed'.toJS,
      ((JSObject response) {
        final error = response['error'];
        lastFailure = (error != null && error.isA<JSObject>())
            ? _str(error as JSObject, 'description')
            : null;
        lastFailure ??= 'Payment failed.';
      }).toJS,
    );
    checkout.callMethod<JSAny?>('open'.toJS);
  } catch (_) {
    finish({'status': 'error', 'message': 'Could not open payment.'});
  }

  return completer.future;
}
