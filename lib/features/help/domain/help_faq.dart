import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// A single Frequently-Asked-Question, stored in Firestore at
/// `helpFaqs/{id}`. Authored from the admin portal, read publicly by
/// signed-in users on the Help screen.
enum FaqCategory {
  booking,
  pricing,
  creatives,
  goingLive,
  account,
  other;

  String get storageValue => switch (this) {
        FaqCategory.booking => 'booking',
        FaqCategory.pricing => 'pricing',
        FaqCategory.creatives => 'creatives',
        FaqCategory.goingLive => 'going_live',
        FaqCategory.account => 'account',
        FaqCategory.other => 'other',
      };

  String get label => switch (this) {
        FaqCategory.booking => 'Booking',
        FaqCategory.pricing => 'Pricing & GST',
        FaqCategory.creatives => 'Creatives',
        FaqCategory.goingLive => 'Going live',
        FaqCategory.account => 'Account',
        FaqCategory.other => 'Other',
      };

  IconData get icon => switch (this) {
        FaqCategory.booking => Icons.event_available_outlined,
        FaqCategory.pricing => Icons.currency_rupee_rounded,
        FaqCategory.creatives => Icons.image_outlined,
        FaqCategory.goingLive => Icons.play_arrow_rounded,
        FaqCategory.account => Icons.person_outline_rounded,
        FaqCategory.other => Icons.help_outline_rounded,
      };

  static FaqCategory fromStorage(String? raw) => switch (raw) {
        'booking' => FaqCategory.booking,
        'pricing' => FaqCategory.pricing,
        'creatives' => FaqCategory.creatives,
        'going_live' => FaqCategory.goingLive,
        'account' => FaqCategory.account,
        _ => FaqCategory.other,
      };

  /// Stable order in which categories appear on the Help screen.
  static const List<FaqCategory> displayOrder = [
    FaqCategory.booking,
    FaqCategory.pricing,
    FaqCategory.creatives,
    FaqCategory.goingLive,
    FaqCategory.account,
    FaqCategory.other,
  ];
}

class HelpFaq {
  const HelpFaq({
    required this.id,
    required this.category,
    required this.question,
    required this.answer,
    required this.order,
    required this.published,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final FaqCategory category;
  final String question;
  final String answer;
  final int order;
  final bool published;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  HelpFaq copyWith({
    FaqCategory? category,
    String? question,
    String? answer,
    int? order,
    bool? published,
  }) {
    return HelpFaq(
      id: id,
      category: category ?? this.category,
      question: question ?? this.question,
      answer: answer ?? this.answer,
      order: order ?? this.order,
      published: published ?? this.published,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  factory HelpFaq.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snap,
  ) {
    final d = snap.data() ?? const <String, dynamic>{};
    return HelpFaq(
      id: snap.id,
      category: FaqCategory.fromStorage(d['category'] as String?),
      question: (d['question'] as String?) ?? '',
      answer: (d['answer'] as String?) ?? '',
      order: (d['order'] as num?)?.toInt() ?? 0,
      published: (d['published'] as bool?) ?? false,
      createdAt: (d['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (d['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'category': category.storageValue,
        'question': question,
        'answer': answer,
        'order': order,
        'published': published,
        'createdAt': createdAt == null
            ? FieldValue.serverTimestamp()
            : Timestamp.fromDate(createdAt!),
        'updatedAt': FieldValue.serverTimestamp(),
      };
}
