# SendGrid Email Setup Guide

This guide will help you set up SendGrid for password reset emails in your Finance Tracker application.

## 1. Create SendGrid Account

1. Go to [SendGrid.com](https://sendgrid.com)
2. Sign up for a free account (100 emails/day forever)
3. Verify your email address
4. Complete the account setup process

## 2. Create API Key

1. Log into your SendGrid dashboard
2. Go to **Settings** → **API Keys**
3. Click **Create API Key**
4. Choose **Restricted Access**
5. Give it a name like "Finance Tracker API"
6. Under **Mail Send**, select **Full Access**
7. Click **Create & View**
8. **IMPORTANT**: Copy the API key immediately (you won't see it again)

## 3. Configure Rails Credentials

### For Development:
```bash
# Edit credentials
EDITOR="code --wait" rails credentials:edit

# Add this to your credentials file:
sendgrid:
  api_key: your_sendgrid_api_key_here
```

### For Production:
```bash
# Edit production credentials
EDITOR="code --wait" rails credentials:edit --environment production

# Add this to your production credentials file:
sendgrid:
  api_key: your_sendgrid_api_key_here
```

## 4. Environment Variables

Set the following environment variables:

### Development (.env file):
```bash
# Optional: Web fallback URL for users without the app
WEB_FALLBACK_URL=http://localhost:3001
```

### Production:
```bash
# Optional: Web fallback URL for users without the app
WEB_FALLBACK_URL=https://your-website.com
```

## 5. Flutter App Deep Link Configuration

### Configure Deep Links in Your Flutter App:

1. **Update `android/app/src/main/AndroidManifest.xml`:**
```xml
<activity
    android:name=".MainActivity"
    android:exported="true"
    android:launchMode="singleTop"
    android:theme="@style/LaunchTheme">
    
    <!-- Existing intent filter -->
    <intent-filter android:autoVerify="true">
        <action android:name="android.intent.action.MAIN"/>
        <category android:name="android.intent.category.LAUNCHER"/>
    </intent-filter>
    
    <!-- Deep link intent filter -->
    <intent-filter android:autoVerify="true">
        <action android:name="android.intent.action.VIEW" />
        <category android:name="android.intent.category.DEFAULT" />
        <category android:name="android.intent.category.BROWSABLE" />
        <data android:scheme="financetracker" />
    </intent-filter>
</activity>
```

2. **Update `ios/Runner/Info.plist`:**
```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLName</key>
        <string>financetracker.deeplink</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>financetracker</string>
        </array>
    </dict>
</array>
```

3. **Add Deep Link Handling in Flutter:**
```dart
// Add to pubspec.yaml
dependencies:
  uni_links: ^0.5.1

// In your main.dart or appropriate widget
import 'package:uni_links/uni_links.dart';

class _MyAppState extends State<MyApp> {
  StreamSubscription? _linkSubscription;

  @override
  void initState() {
    super.initState();
    _initDeepLinks();
  }

  void _initDeepLinks() async {
    // Handle app launch from deep link
    try {
      final initialLink = await getInitialLink();
      if (initialLink != null) {
        _handleDeepLink(initialLink);
      }
    } catch (e) {
      print('Failed to get initial link: $e');
    }

    // Handle deep links while app is running
    _linkSubscription = linkStream.listen(
      (String link) {
        _handleDeepLink(link);
      },
      onError: (err) {
        print('Deep link error: $err');
      },
    );
  }

  void _handleDeepLink(String link) {
    final uri = Uri.parse(link);
    if (uri.scheme == 'financetracker' && uri.host == 'reset-password') {
      final token = uri.queryParameters['token'];
      if (token != null) {
        // Navigate to password reset screen
        Navigator.pushNamed(context, '/reset-password', arguments: token);
      }
    }
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    super.dispose();
  }
}
```

## 6. Domain Authentication (Recommended for Production)

1. In SendGrid dashboard, go to **Settings** → **Sender Authentication**
2. Click **Authenticate Your Domain**
3. Follow the DNS setup instructions for your domain
4. This improves email deliverability and removes "via sendgrid.net"

## 7. Test Email Sending

You can test the email functionality using Rails console:

```ruby
# Start Rails console
rails console

# Find a user
user = User.first

# Generate a test token
reset_token = SecureRandom.urlsafe_base64(32)

# Send test email
UserMailer.password_reset(user, reset_token).deliver_now
```

## 8. Monitoring

- Check SendGrid dashboard for email statistics
- Monitor Rails logs for email sending errors
- Set up email event webhooks for advanced tracking (optional)

## 9. Security Notes

- Never commit API keys to version control
- Use Rails credentials for storing sensitive data
- The reset token expires after 2 hours for security
- Always use HTTPS in production for reset links

## 10. Troubleshooting

### Common Issues:

1. **"Unauthorized" errors**: Check your API key is correct
2. **Emails not delivered**: Check spam folder, verify domain authentication
3. **Rails credentials errors**: Ensure master key exists and is correct
4. **SMTP errors**: Verify SendGrid SMTP settings in environment configs

### Debug Commands:

```ruby
# Check if credentials are loaded correctly
Rails.application.credentials.sendgrid[:api_key]

# Test SMTP connection
ActionMailer::Base.smtp_settings
```

## 11. Flutter App Specific Notes

### Deep Link Testing:
```bash
# Test deep link on Android (via ADB)
adb shell am start \
  -W -a android.intent.action.VIEW \
  -d "financetracker://reset-password?token=test123" \
  com.yourcompany.financetracker

# Test deep link on iOS Simulator
xcrun simctl openurl booted "financetracker://reset-password?token=test123"
```

### Custom URL Scheme:
- Change `financetracker://` to match your app's branding
- Update the scheme in both the mailer and Flutter configuration
- Ensure the scheme is unique to avoid conflicts

### Fallback Strategy:
- The email includes both deep link and web fallback
- Users without the app can still reset passwords via web
- Consider creating a simple web page that detects mobile and suggests app download

## 12. Production Checklist

- [ ] SendGrid account verified
- [ ] API key created with Mail Send permissions
- [ ] Production credentials configured
- [ ] FRONTEND_URL environment variable set
- [ ] Domain authentication completed (recommended)
- [ ] Test email sent successfully
- [ ] Email templates reviewed and customized
- [ ] Monitoring set up

Your password reset emails are now ready to go! 🚀
