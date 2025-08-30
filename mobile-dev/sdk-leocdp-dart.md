# Example of Dart SDK for LEO CDP

I’ll structure it like a **mini SDK**:

* `LeoCdpClient` → main API client (handles base URL, headers, requests).
* `Profile` → data model class for profile
* `Event` → data model class for events of profile
* `ExtAttributes`, `SocialMediaProfiles`, etc. → embedded value objects.

---

# 📦 Example Dart SDK for LEO CDP

```dart
import 'dart:convert';
import 'package:http/http.dart' as http;

/// ----------------------
/// Client
/// ----------------------
class LeoCdpClient {
  final String baseUrl;
  final String tokenKey;
  final String tokenValue;

  LeoCdpClient({
    required this.baseUrl,
    required this.tokenKey,
    required this.tokenValue,
  });

  Map<String, String> get _headers => {
        "Content-Type": "application/json",
        "Access-Control-Allow-Origin": "*",
        "tokenkey": tokenKey,
        "tokenvalue": tokenValue,
      };

  /// Generic POST
  Future<Map<String, dynamic>> post(String path, Map<String, dynamic> payload) async {
    final uri = Uri.https(baseUrl, path);
    final body = jsonEncode(payload);

    final response = await http.post(uri, headers: _headers, body: body);

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception("Error ${response.statusCode}: ${response.body}");
    }
  }

  /// Save profile
  Future<Map<String, dynamic>> saveProfile(Profile profile) async {
    return await post("/api/profile/save", profile.toJson());
  }

  /// Track Event
  Future<Map<String, dynamic>> trackEvent(Event event) async {
    return await post("/api/event/save", event.toJson());
  }
}

/// ----------------------
/// Profile Model (same as before)
/// ----------------------
class Profile {
  final String crmRefId;
  final String primaryEmail;
  final String primaryPhone;
  final String firstName;
  final String lastName;
  final String gender;
  final int age;

  final ExtAttributes extAttributes;
  final SocialMediaProfiles socialMediaProfiles;
  final Map<String, dynamic> incomeHistory;

  final bool deduplicate;
  final bool overwriteData;

  Profile({
    required this.crmRefId,
    required this.primaryEmail,
    required this.primaryPhone,
    required this.firstName,
    required this.lastName,
    required this.gender,
    required this.age,
    required this.extAttributes,
    required this.socialMediaProfiles,
    required this.incomeHistory,
    this.deduplicate = false,
    this.overwriteData = true,
  });

  Map<String, dynamic> toJson() => {
        "crmRefId": crmRefId,
        "primaryEmail": primaryEmail,
        "primaryPhone": primaryPhone,
        "firstName": firstName,
        "lastName": lastName,
        "gender": gender,
        "age": age,
        "extAttributes": jsonEncode(extAttributes.toJson()),
        "socialMediaProfiles": jsonEncode(socialMediaProfiles.toJson()),
        "incomeHistory": jsonEncode(incomeHistory),
        "deduplicate": deduplicate,
        "overwriteData": overwriteData,
      };
}

/// ----------------------
/// Value Objects
/// ----------------------
class ExtAttributes {
  final int hasBooking;
  final String lastBookingDate;

  ExtAttributes({required this.hasBooking, required this.lastBookingDate});

  Map<String, dynamic> toJson() => {
        "hasBooking": hasBooking,
        "lastBookingDate": lastBookingDate,
      };
}

class SocialMediaProfiles {
  final String zalo;
  final String facebook;
  final String linkedin;
  final String twitter;
  final String github;

  SocialMediaProfiles({
    required this.zalo,
    required this.facebook,
    required this.linkedin,
    required this.twitter,
    required this.github,
  });

  Map<String, dynamic> toJson() => {
        "zalo": zalo,
        "facebook": facebook,
        "linkedin": linkedin,
        "twitter": twitter,
        "github": github,
      };
}

/// ----------------------
/// Event Model
/// ----------------------
class Event {
  final String targetUpdatePhone;
  final String tpname;
  final String tpurl;
  final String tprefurl;
  final String funnelStage;
  final String eventtime;
  final String eventdata;
  final String imageUrls;
  final String metric;
  final num tsval;
  final String tspayment;
  final String tscur;
  final String tsstatus;
  final String message;

  final List<Map<String, dynamic>>? scitems; // optional shopping cart
  final String? tsid; // optional transaction id

  Event({
    required this.targetUpdatePhone,
    required this.tpname,
    required this.tpurl,
    this.tprefurl = "",
    required this.funnelStage,
    required this.eventtime,
    this.eventdata = "",
    required this.imageUrls,
    required this.metric,
    required this.tsval,
    required this.tspayment,
    required this.tscur,
    required this.tsstatus,
    required this.message,
    this.scitems,
    this.tsid,
  });

  Map<String, dynamic> toJson() => {
        "targetUpdatePhone": targetUpdatePhone,
        "tpname": tpname,
        "tpurl": tpurl,
        "tprefurl": tprefurl,
        "funnelStage": funnelStage,
        "eventtime": eventtime,
        "eventdata": eventdata,
        "imageUrls": imageUrls,
        "metric": metric,
        "tsval": tsval,
        "tspayment": tspayment,
        "tscur": tscur,
        "tsstatus": tsstatus,
        "message": message,
        if (scitems != null) "scitems": scitems,
        if (tsid != null) "tsid": tsid,
      };
}

/// ----------------------
/// Usage Example
/// ----------------------
Future<void> main() async {
  final client = LeoCdpClient(
    baseUrl: "your-cdp-host.com",
    tokenKey: "your-token-key",
    tokenValue: "your-token-value",
  );

  // Example Event
  final event = Event(
    targetUpdatePhone: "0903122290",
    tpname: "ALPHA TOWER",
    tpurl: "https://maps.app.goo.gl/RAdDJqiQe5qKvvrx5",
    funnelStage: "engaged-customer",
    eventtime: "2024-07-24T10:51:25.110Z",
    imageUrls: "https://ohtea.vn/img/B%C3%A1nh%20tr%C3%A1ng%20cu%E1%BB%91n.jpg",
    metric: "an-banh-trang",
    tsval: -28000,
    tspayment: "momo",
    tscur: "VND",
    tsstatus: "yesy",
    message: "test aaaa",
  );

  try {
    final result = await client.trackEvent(event);
    print("Event tracked successfully: $result");
  } catch (e) {
    print("Error tracking event: $e");
  }
}
```

```dart 
/// ----------------------
/// Usage Example for creating Profile
/// ----------------------
Future<void> main() async {
  final client = LeoCdpClient(
    baseUrl: "your-cdp-host.com", // e.g. api.leocdp.io
    tokenKey: "your-token-key",
    tokenValue: "your-token-value",
  );

  final profile = Profile(
    crmRefId: "zalo-123456789",
    primaryEmail: "bill.john123@example.com",
    primaryPhone: "09031222271",
    firstName: "Anh",
    lastName: "Nguyen",
    gender: "female",
    age: 20,
    extAttributes: ExtAttributes(hasBooking: 10, lastBookingDate: "2024-10-15"),
    socialMediaProfiles: SocialMediaProfiles(
      zalo: "123456789",
      facebook: "123456789",
      linkedin: "123456789",
      twitter: "123456789",
      github: "123456789",
    ),
    incomeHistory: {"2022-2023": 2000000, "2023-2024": 3000000},
  );

  try {
    final result = await client.saveProfile(profile);
    print("Profile saved successfully: $result");
  } catch (e) {
    print("Error saving profile: $e");
  }
}

```

---

✅ **Now your SDK supports both**:

* `saveProfile(Profile profile)`
* `trackEvent(Event event)`





