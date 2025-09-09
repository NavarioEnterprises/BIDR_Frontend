# Flutter Chat Message Sending Troubleshooting Guide

## Backend Status ✅
The Django backend is working correctly:
- ✅ Authentication removal successful
- ✅ Conversation creation working
- ✅ Message sending API working (`POST /api/v1/chat/conversations/{id}/send_message/`)
- ✅ Message retrieval API working (`GET /api/v1/chat/conversations/{id}/messages/`)

## Issue: "Send information" text field not sending messages to backend

Since the backend is working, the issue is in the Flutter frontend. Here are the most likely causes and solutions:

### 1. Check API Endpoint URL ❗
**Problem**: Flutter app using wrong API endpoint
**Correct URLs**:
```
- Conversations: http://localhost:8001/api/v1/chat/conversations/
- Send Message: http://localhost:8001/api/v1/chat/conversations/{conversation_id}/send_message/
- Get Messages: http://localhost:8001/api/v1/chat/conversations/{conversation_id}/messages/
```

**Check in Flutter code**:
```dart
// Make sure your ChatService is using the correct URLs
final String baseUrl = 'http://localhost:8001/api/v1/chat';
// NOT: 'http://localhost:8001/api/conversations'
```

### 2. Verify Request Method and Headers ❗
**Correct POST request format**:
```dart
final response = await http.post(
  Uri.parse('$baseUrl/conversations/$conversationId/send_message/'),
  headers: {
    'Content-Type': 'application/json',
  },
  body: jsonEncode({
    'content': messageText,
    'message_type': 'text',
  }),
);
```

### 3. Check Request Payload Format ❗
**Correct JSON format**:
```json
{
  "content": "Your message text here",
  "message_type": "text"
}
```

**Optional fields**:
```json
{
  "content": "Your message text here", 
  "message_type": "text",
  "reply_to": null,
  "client_message_id": "",
  "external_reference": null,
  "metadata": {}
}
```

### 4. Debug Network Requests 🔍
Add debugging to your Flutter code:

```dart
Future<void> sendMessage(String conversationId, String content) async {
  print('🔍 Sending message to conversation: $conversationId');
  print('🔍 Message content: $content');
  
  final url = '$baseUrl/conversations/$conversationId/send_message/';
  print('🔍 Request URL: $url');
  
  try {
    final response = await http.post(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'content': content,
        'message_type': 'text',
      }),
    );
    
    print('🔍 Response status: ${response.statusCode}');
    print('🔍 Response body: ${response.body}');
    
    if (response.statusCode == 201) {
      print('✅ Message sent successfully');
      // Handle success
    } else {
      print('❌ Failed to send message');
      // Handle error
    }
  } catch (e) {
    print('❌ Network error: $e');
  }
}
```

### 5. Check Text Field Callback ❗
Ensure your text field is properly wired to call the API:

```dart
TextField(
  controller: messageController,
  onSubmitted: (text) {
    if (text.trim().isNotEmpty) {
      sendMessage(conversationId, text.trim());
      messageController.clear();
    }
  },
  decoration: InputDecoration(
    hintText: 'Send information',
    suffixIcon: IconButton(
      icon: Icon(Icons.send),
      onPressed: () {
        final text = messageController.text.trim();
        if (text.isNotEmpty) {
          sendMessage(conversationId, text);
          messageController.clear();
        }
      },
    ),
  ),
)
```

### 6. Verify Server Connection 🌐
Test if your Flutter app can reach the server:

```dart
Future<void> testConnection() async {
  try {
    final response = await http.get(
      Uri.parse('http://localhost:8001/health/'),
    );
    print('🔍 Health check status: ${response.statusCode}');
    print('🔍 Health check body: ${response.body}');
  } catch (e) {
    print('❌ Cannot connect to server: $e');
    print('Make sure Django server is running on port 8001');
  }
}
```

### 7. Common Issues and Solutions 🛠️

**Issue**: Connection refused
**Solution**: Make sure Django server is running: `python manage.py runserver 8001`

**Issue**: CORS errors (in web)
**Solution**: Already configured in Django settings, but check browser console

**Issue**: 404 Not Found
**Solution**: Verify API URLs are correct (include `/api/v1/chat/` prefix)

**Issue**: 400 Bad Request
**Solution**: Check request payload format matches expected JSON structure

**Issue**: Text field not triggering API call
**Solution**: Check `onSubmitted` and `onPressed` callbacks are properly implemented

### 8. Working API Test Examples 🧪

You can test the APIs directly using curl or a tool like Postman:

```bash
# Get conversations
curl -X GET http://localhost:8001/api/v1/chat/conversations/

# Send message
curl -X POST http://localhost:8001/api/v1/chat/conversations/{CONVERSATION_ID}/send_message/ \
  -H "Content-Type: application/json" \
  -d '{"content": "Test message", "message_type": "text"}'

# Get messages
curl -X GET http://localhost:8001/api/v1/chat/conversations/{CONVERSATION_ID}/messages/
```

### 9. Next Steps 📋

1. Add the debug print statements to your Flutter code
2. Run your app and try sending a message
3. Check the console output for the debug messages
4. Verify the API URL being called
5. Check if the network request is being made at all
6. If no request is made, check the button/text field callbacks
7. If request is made but fails, check the error response

### 10. Expected Successful Flow ✅

1. User types message in text field
2. User presses send button or hits enter
3. `onPressed`/`onSubmitted` callback is triggered
4. `sendMessage()` function is called with conversation ID and message content
5. HTTP POST request is made to `/api/v1/chat/conversations/{id}/send_message/`
6. Backend responds with 201 status code
7. Message is added to the conversation
8. UI updates to show the new message

---

**Backend APIs Tested and Confirmed Working** ✅  
**Date**: 2025-08-27  
**Server**: http://localhost:8001  
**Status**: Ready for frontend integration
