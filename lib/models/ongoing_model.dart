import 'package:intl/intl.dart';

class ParallelSessionsResponse {
  final String status;
  final String message;
  final List<SessionData> data;

  ParallelSessionsResponse({
    required this.status,
    required this.message,
    required this.data,
  });

  factory ParallelSessionsResponse.fromJson(Map<String, dynamic> json) {
    return ParallelSessionsResponse(
      status: json['status'],
      message: json['message'],
      data: List<SessionData>.from(
        json['data'].map((item) => SessionData.fromJson(item)),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'message': message,
      'data': data.map((item) => item.toJson()).toList(),
    };
  }
}

class SessionData {
  final int id;
  final int? sessionId;
  final String starttime;
  final String endtime;
  final String name;
  final String? topic;
  final String? sessionchair;
  final String? hall;
  final String? zoomlink;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final Session session;
  final List<Speaker> speakers;

  SessionData({
    required this.id,
    this.sessionId,
    required this.starttime,
    required this.endtime,
    required this.name,
    this.topic,
    this.sessionchair,
    this.hall,
    this.zoomlink,
    this.createdAt,
    this.updatedAt,
    required this.session,
    required this.speakers,
  });

  factory SessionData.fromJson(Map<String, dynamic> json) {
    // Handle createdAt and updatedAt which might be missing or null
    DateTime? createdAt;
    DateTime? updatedAt;
    try {
      if (json['createdAt'] != null) {
        createdAt = DateTime.parse(json['createdAt']);
      }
    } catch (_) {}
    try {
      if (json['updatedAt'] != null) {
        updatedAt = DateTime.parse(json['updatedAt']);
      }
    } catch (_) {}

    // Handle both nested 'session' structure (from parallel sessions endpoint)
    // and flat structure (from /sessions/session endpoint)
    Session session;
    if (json['session'] != null) {
      session = Session.fromJson(json['session']);
    } else {
      // Flat structure: create Session from root-level fields
      session = Session(
        id: json['id'] ?? 0,
        name: json['name'] ?? '',
        date: DateTime.now(), // Will be overridden by parsing below if needed
      );
      // Try to parse the date field if it exists
      if (json['date'] != null) {
        try {
          session = Session(
            id: json['id'] ?? 0,
            name: json['name'] ?? '',
            date: DateTime.parse(json['date']),
          );
        } catch (_) {
          try {
            final parsed = DateFormat('EEEE, MMMM d, yyyy').parse(json['date']);
            session = Session(
              id: json['id'] ?? 0,
              name: json['name'] ?? '',
              date: parsed,
            );
          } catch (_) {
            try {
              final parsed = DateFormat('MMMM d, yyyy').parse(json['date']);
              session = Session(
                id: json['id'] ?? 0,
                name: json['name'] ?? '',
                date: parsed,
              );
            } catch (_) {
              session = Session(
                id: json['id'] ?? 0,
                name: json['name'] ?? '',
                date: DateTime.now(),
              );
            }
          }
        }
      }
    }

    return SessionData(
      id: json['id'],
      sessionId: json['sessionId'] as int?,
      starttime: json['starttime'],
      endtime: json['endtime'],
      name: json['name'],
      topic: json['topic'] as String?,
      sessionchair: json['sessionchair'],
      hall: json['hall'] ?? "",
      zoomlink: json['zoomlink'] ?? "",
      createdAt: createdAt,
      updatedAt: updatedAt,
      session: session,
      speakers: List<Speaker>.from(
        json['Speakers'].map((s) => Speaker.fromJson(s)),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sessionId': sessionId,
      'starttime': starttime,
      'endtime': endtime,
      'name': name,
      'topic': topic,
      'sessionchair': sessionchair,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'session': session.toJson(),
      'Speakers': speakers.map((s) => s.toJson()).toList(),
    };
  }
}

class Session {
  final int id;
  final String name;
  final DateTime date;

  Session({
    required this.id,
    required this.name,
    required this.date,
  });

  factory Session.fromJson(Map<String, dynamic> json) {
    // The API sometimes returns an ISO date string and sometimes a human-readable
    // string like "Friday, July 3, 2026". Try ISO parse first, then fall back
    // to a DateFormat parser for the human-readable form.
    DateTime parsedDate;
    final rawDate = json['date'];
    try {
      parsedDate = DateTime.parse(rawDate);
    } catch (_) {
      try {
        parsedDate = DateFormat('EEEE, MMMM d, yyyy').parse(rawDate);
      } catch (e) {
        // As a last resort try parsing without weekday: "MMMM d, yyyy"
        parsedDate = DateFormat('MMMM d, yyyy').parse(rawDate);
      }
    }

    return Session(
      id: json['id'],
      name: json['name'],
      date: parsedDate,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'date': DateFormat('yyyy-MM-dd').format(date),
    };
  }
}

class Speaker {
  final int id;
  final String? prefix;
  final String? fname;
  final String? lname;
  final String? suffix;
  final String? email;
  final String? linkedin;
  final String? company;
  final String? bio;
  final String? image;
  final String? notes;
  final String? custom;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Speaker({
    required this.id,
    this.prefix,
    this.fname,
    this.lname,
    this.suffix,
    this.email,
    this.linkedin,
    this.company,
    this.bio,
    this.image,
    this.notes,
    this.custom,
    this.createdAt,
    this.updatedAt,
  });

  factory Speaker.fromJson(Map<String, dynamic> json) {
    // Handle null values gracefully with defaults
    DateTime? createdAt;
    DateTime? updatedAt;
    try {
      if (json['createdAt'] != null) {
        createdAt = DateTime.parse(json['createdAt']);
      }
    } catch (_) {}
    try {
      if (json['updatedAt'] != null) {
        updatedAt = DateTime.parse(json['updatedAt']);
      }
    } catch (_) {}

    return Speaker(
      id: json['id'] ?? 0,
      prefix: json['prefix'],
      fname: json['fname'] as String?,
      lname: json['lname'] as String?,
      suffix: json['suffix'],
      email: json['email'] as String?,
      linkedin: json['linkedin'],
      company: json['company'] as String?,
      bio: json['bio'],
      image: json['image'] as String?,
      notes: json['notes'],
      custom: json['custom'],
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'prefix': prefix,
      'fname': fname,
      'lname': lname,
      'suffix': suffix,
      'email': email,
      'linkedin': linkedin,
      'company': company,
      'bio': bio,
      'image': image,
      'notes': notes,
      'custom': custom,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }
}

