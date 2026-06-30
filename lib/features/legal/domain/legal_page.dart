import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// One legal document — Privacy Policy, Terms of Service, or Content
/// Guidelines. Stored at `legalPages/{id}` in Firestore where `id` is
/// one of the well-known [LegalPageId] string values, so the route
/// `/legal/:id` can fetch a deterministic single document.
///
/// The body is plain text with paragraph breaks (`\n\n`) — keeps the
/// admin form simple and the user-side renderer fast. Section headings
/// are written as ALL CAPS lines on their own ("1. WHO WE ARE").
class LegalPageId {
  LegalPageId._();
  static const String privacy = 'privacy';
  static const String terms = 'terms';
  static const String content = 'content-guidelines';

  static const List<String> all = [privacy, terms, content];
}

class LegalPage {
  const LegalPage({
    required this.id,
    required this.title,
    required this.body,
    required this.version,
    this.published = true,
    this.effectiveFrom,
    this.updatedAt,
  });

  /// One of the [LegalPageId] constants.
  final String id;
  final String title;

  /// The actual policy text. Newlines preserved for paragraph rendering.
  final String body;

  /// Monotonic version number. Bump every time the policy is materially
  /// changed so the user-side "Last updated …" line is accurate, and so
  /// you can later show users a re-consent prompt when the number rises.
  final int version;

  /// Drafts (false) are hidden from non-admins so legal can be edited
  /// without flashing half-finished text at customers.
  final bool published;

  /// Date the new version takes legal effect — usually = updatedAt, but
  /// gives the option of staging a future change.
  final DateTime? effectiveFrom;
  final DateTime? updatedAt;

  IconData get icon => switch (id) {
        LegalPageId.privacy => Icons.lock_outline_rounded,
        LegalPageId.terms => Icons.description_outlined,
        LegalPageId.content => Icons.policy_outlined,
        _ => Icons.article_outlined,
      };

  factory LegalPage.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snap,
  ) {
    final d = snap.data() ?? const <String, dynamic>{};
    return LegalPage(
      id: snap.id,
      title: (d['title'] as String?) ?? 'Untitled',
      body: (d['body'] as String?) ?? '',
      version: (d['version'] as num?)?.toInt() ?? 1,
      published: (d['published'] as bool?) ?? true,
      effectiveFrom: (d['effectiveFrom'] as Timestamp?)?.toDate(),
      updatedAt: (d['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'title': title,
        'body': body,
        'version': version,
        'published': published,
        if (effectiveFrom != null)
          'effectiveFrom': Timestamp.fromDate(effectiveFrom!),
        'updatedAt': FieldValue.serverTimestamp(),
      };

  LegalPage copyWith({
    String? title,
    String? body,
    int? version,
    bool? published,
    DateTime? effectiveFrom,
  }) {
    return LegalPage(
      id: id,
      title: title ?? this.title,
      body: body ?? this.body,
      version: version ?? this.version,
      published: published ?? this.published,
      effectiveFrom: effectiveFrom ?? this.effectiveFrom,
      updatedAt: updatedAt,
    );
  }
}
