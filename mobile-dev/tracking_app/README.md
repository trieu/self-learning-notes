# **LEO CDP — Flutter Demo Tracking App**

A minimal Flutter application demonstrating how to send tracking events to **LEO CDP** using a lightweight client library and `.env` API credentials.
This demo shows both **simple event tracking** and **structured event tracking** with full transaction metadata.

---

## **📱 About the Demo**

This app provides a very small UI that allows a developer to:

* Select an event type from a dropdown.
* Send a tracking event to LEO CDP.
* See the response (success/failure) immediately.
* Learn how to implement custom event payloads using the included `LeoCdpClient` and `TrackingEvent` classes.

The purpose is educational: engineers can copy the client code and embed event tracking inside their own Flutter apps.

---

## **🧩 Project Structure**

```
mobile-dev/tracking_app/
│
├── lib/
│    ├── main.dart              # Flutter UI + event sender
│    ├── tracking_service.dart  # Simple event sender
│    ├── leocdp_client.dart     # Full LEO CDP structured event client
│
├── assets/.env                 # Your API keys (not committed)
└── README.md                   # This file
```

---

## **🔑 Environment Variables**

The app loads API credentials from:

```
assets/.env
```

Add the following keys:

```
LEO_TOKEN_KEY=your-key
LEO_TOKEN_VALUE=your-value
```

Your `pubspec.yaml` must include:

```yaml
flutter:
  assets:
    - assets/.env
```

---

## **🚀 Running the App**

```bash
flutter pub get
flutter run
```

If `.env` loads successfully, you will see:

```
✅ Loaded .env
```

If not:

```
⚠️ Could not load .env: <error>
```

The app still runs, but token-based requests will fail.

---

## **🛰 How Events Are Sent**

### **Option 1: Simple Event**

Used by the UI screen.

```dart
_trackingService.sendEvent(selectedEvent);
```

This sends a minimal JSON payload:

```json
{
  "event_name": "screen-view",
  "timestamp": "2024-10-28T18:21:00Z",
  "device": "Flutter-Android12"
}
```

### **Option 2: Full Structured Event (Recommended)**

In real apps, use this:

```dart
final event = TrackingEvent(
  metric: "purchase",
  targetUpdateEmail: "user@example.com",
  tsId: "TX12345",
  tsVal: 1900000,
  tsCur: "VND",
  tditems: [
    TradingItem(tickerSymbol: "VN30"),
  ],
);

final result = await LeoCdpClient().trackEvent(event);
```

This produces a detailed request to:

```
POST https://datahub4dcdp.bigdatavietnam.org/api/event/save
```

---

## **📦 TrackingEvent Data Model**

The `TrackingEvent` class supports:

* Page/screen events
* Product/content view events
* Stock/asset view events
* Purchase and checkout events
* Custom metadata
* Touchpoint information
* Shipping / transaction details

It enforces correctness:

```dart
if (metric == 'purchase' || metric == 'order-checkout') {
  assert(tsId != null);
  assert(tditems != null);
}
```

Meaning:
**Purchase events require transaction ID and items.**

---

## **📡 HTTP Headers**

All tracking requests include:

```http
Content-Type: application/json
tokenkey: <LEO_TOKEN_KEY>
tokenvalue: <LEO_TOKEN_VALUE>
```

These map directly to LEO CDP’s API Gateway authentication.

---

## **🧪 Example Response Messages**

**Success**

```
✅ Event sent: screen-view
```

**Failed**

```
⚠️ Failed (400)
```

**Network Error**

```
❌ Error: SocketException: Failed host lookup
```

---

## **🛠 Tech Stack**

* Flutter 3.x
* Dart
* HTTP Client (`package:http`)
* Dotenv loader (`flutter_dotenv`)
* Immutable payload models

---

## **📘 What Developers Should Learn From This Demo**

1. How to integrate LEO CDP event tracking into Flutter apps.
2. How to structure analytics events properly.
3. How to use `.env` securely in mobile development.
4. How to extend the payload for real-world product, stock, or content tracking.
5. How to safely reuse a tracking service across screens.

This demo is intentionally simple so real product teams can adapt it easily.

---

