# Email Service Quick Setup

## ✅ Automatic Configuration

The email service is now **automatically configured** on app startup! You just need to provide your SendGrid API key.

## 🚀 Setup Steps (2 minutes)

### Option 1: Environment Variables (Recommended for Development)

1. **In Xcode:**
   - Click on your project in the navigator
   - Select the "Get Active" target
   - Go to **Edit Scheme...** (or press `⌘<`)
   - Select **Run** → **Arguments** tab
   - Under **Environment Variables**, click **+** and add:

   ```
   Name: SENDGRID_API_KEY
   Value: SG.your-actual-api-key-here
   ```

   ```
   Name: FROM_EMAIL
   Value: noreply@getactive.app
   ```

   ```
   Name: FROM_NAME
   Value: Get Active
   ```

2. **Get Your SendGrid API Key:**
   - Go to [sendgrid.com](https://sendgrid.com) and sign up (free: 100 emails/day)
   - Go to **Settings → API Keys**
   - Click **Create API Key**
   - Name it "Get Active 2FA"
   - Select **Full Access** (or just "Mail Send")
   - **Copy the key** (you'll only see it once!)
   - Paste it as the value for `SENDGRID_API_KEY`

3. **Verify Sender Email in SendGrid:**
   - Go to **Settings → Sender Authentication**
   - Click **Verify a Single Sender**
   - Enter your email (e.g., noreply@getactive.app)
   - Verify the email

4. **Run the app** - Email service will automatically configure!

### Option 2: Configure in Code (Alternative)

If you prefer to configure in code instead of environment variables, you can add this to `Get_ActiveApp.swift`:

```swift
init() {
    // Configure email service
    EmailService.shared.configure(
        provider: .sendGrid,
        apiKey: "SG.your-actual-api-key-here",
        fromEmail: "noreply@getactive.app",
        fromName: "Get Active"
    )
    
    configureEmailService()
}
```

**Note:** This is less secure as the API key will be in your code. Use environment variables for production.

## ✅ How It Works

1. **On app startup**, the app automatically:
   - Checks for `SENDGRID_API_KEY` environment variable
   - If found, configures email service automatically
   - Saves the key to Keychain for future use

2. **If environment variable is not set**, it:
   - Checks Keychain for a previously saved key
   - Uses that if available

3. **If neither exists**, it:
   - Logs a warning
   - Email service will fail when trying to send (but won't crash)

## 🧪 Testing

1. **Set up environment variables** (see Option 1 above)
2. **Run the app**
3. **Try logging in** - you should receive a 2FA email!
4. **Check console** for: `✅ Email service configured from environment variables (SendGrid)`

## 🔍 Troubleshooting

### "Email service not configured" warning
- Make sure you set the `SENDGRID_API_KEY` environment variable
- Check that the API key is correct (starts with `SG.`)
- Restart Xcode if environment variables don't appear

### "Failed to send email" error
- Verify your SendGrid API key is correct
- Check that sender email is verified in SendGrid
- Check SendGrid dashboard for any errors
- Make sure you're not exceeding the free tier limit (100 emails/day)

### Email going to spam
- Verify your sender email in SendGrid
- Set up domain authentication (SPF/DKIM records)
- Use a professional email address

## 📝 Current Configuration

The email service is configured to:
- **Provider**: SendGrid (default)
- **From Email**: `noreply@getactive.app` (or from `FROM_EMAIL` env var)
- **From Name**: `Get Active` (or from `FROM_NAME` env var)
- **Auto-configure**: Yes, on app startup

## 🎯 Next Steps

1. ✅ Get SendGrid API key
2. ✅ Set environment variables in Xcode
3. ✅ Verify sender email in SendGrid
4. ✅ Test by logging in (should receive 2FA email)

That's it! The email service will work automatically. 🎉


## ✅ Automatic Configuration

The email service is now **automatically configured** on app startup! You just need to provide your SendGrid API key.

## 🚀 Setup Steps (2 minutes)

### Option 1: Environment Variables (Recommended for Development)

1. **In Xcode:**
   - Click on your project in the navigator
   - Select the "Get Active" target
   - Go to **Edit Scheme...** (or press `⌘<`)
   - Select **Run** → **Arguments** tab
   - Under **Environment Variables**, click **+** and add:

   ```
   Name: SENDGRID_API_KEY
   Value: SG.your-actual-api-key-here
   ```

   ```
   Name: FROM_EMAIL
   Value: noreply@getactive.app
   ```

   ```
   Name: FROM_NAME
   Value: Get Active
   ```

2. **Get Your SendGrid API Key:**
   - Go to [sendgrid.com](https://sendgrid.com) and sign up (free: 100 emails/day)
   - Go to **Settings → API Keys**
   - Click **Create API Key**
   - Name it "Get Active 2FA"
   - Select **Full Access** (or just "Mail Send")
   - **Copy the key** (you'll only see it once!)
   - Paste it as the value for `SENDGRID_API_KEY`

3. **Verify Sender Email in SendGrid:**
   - Go to **Settings → Sender Authentication**
   - Click **Verify a Single Sender**
   - Enter your email (e.g., noreply@getactive.app)
   - Verify the email

4. **Run the app** - Email service will automatically configure!

### Option 2: Configure in Code (Alternative)

If you prefer to configure in code instead of environment variables, you can add this to `Get_ActiveApp.swift`:

```swift
init() {
    // Configure email service
    EmailService.shared.configure(
        provider: .sendGrid,
        apiKey: "SG.your-actual-api-key-here",
        fromEmail: "noreply@getactive.app",
        fromName: "Get Active"
    )
    
    configureEmailService()
}
```

**Note:** This is less secure as the API key will be in your code. Use environment variables for production.

## ✅ How It Works

1. **On app startup**, the app automatically:
   - Checks for `SENDGRID_API_KEY` environment variable
   - If found, configures email service automatically
   - Saves the key to Keychain for future use

2. **If environment variable is not set**, it:
   - Checks Keychain for a previously saved key
   - Uses that if available

3. **If neither exists**, it:
   - Logs a warning
   - Email service will fail when trying to send (but won't crash)

## 🧪 Testing

1. **Set up environment variables** (see Option 1 above)
2. **Run the app**
3. **Try logging in** - you should receive a 2FA email!
4. **Check console** for: `✅ Email service configured from environment variables (SendGrid)`

## 🔍 Troubleshooting

### "Email service not configured" warning
- Make sure you set the `SENDGRID_API_KEY` environment variable
- Check that the API key is correct (starts with `SG.`)
- Restart Xcode if environment variables don't appear

### "Failed to send email" error
- Verify your SendGrid API key is correct
- Check that sender email is verified in SendGrid
- Check SendGrid dashboard for any errors
- Make sure you're not exceeding the free tier limit (100 emails/day)

### Email going to spam
- Verify your sender email in SendGrid
- Set up domain authentication (SPF/DKIM records)
- Use a professional email address

## 📝 Current Configuration

The email service is configured to:
- **Provider**: SendGrid (default)
- **From Email**: `noreply@getactive.app` (or from `FROM_EMAIL` env var)
- **From Name**: `Get Active` (or from `FROM_NAME` env var)
- **Auto-configure**: Yes, on app startup

## 🎯 Next Steps

1. ✅ Get SendGrid API key
2. ✅ Set environment variables in Xcode
3. ✅ Verify sender email in SendGrid
4. ✅ Test by logging in (should receive 2FA email)

That's it! The email service will work automatically. 🎉




