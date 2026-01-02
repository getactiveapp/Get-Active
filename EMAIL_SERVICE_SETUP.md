# Email Service Setup for 2FA

## Choose Your Email Provider

### Option 1: SendGrid (Recommended - Easiest)

#### Setup Steps:

1. **Create SendGrid Account**
   - Go to [sendgrid.com](https://sendgrid.com)
   - Sign up for free account (100 emails/day free)

2. **Create API Key**
   - Go to Settings → API Keys
   - Click "Create API Key"
   - Name: "Get Active 2FA"
   - Permissions: "Full Access" (or just "Mail Send")
   - Copy the API key (you'll only see it once!)

3. **Verify Sender Email**
   - Go to Settings → Sender Authentication
   - Verify your sender email (e.g., noreply@getactive.app)

4. **Configure in App**
   ```swift
   // In your app initialization (App.swift or similar)
   EmailService.shared.configure(
       provider: .sendGrid,
       apiKey: "SG.your-api-key-here",
       fromEmail: "noreply@getactive.app",
       fromName: "Get Active"
   )
   ```

   Or set environment variable:
   - `SENDGRID_API_KEY` = your API key
   - `FROM_EMAIL` = noreply@getactive.app

---

### Option 2: Mailgun

#### Setup Steps:

1. **Create Mailgun Account**
   - Go to [mailgun.com](https://mailgun.com)
   - Sign up (5,000 emails/month free)

2. **Get API Key**
   - Go to Settings → API Keys
   - Copy your Private API key

3. **Get Domain**
   - Add and verify your domain
   - Or use sandbox domain for testing

4. **Configure in App**
   ```swift
   EmailService.shared.configure(
       provider: .mailgun,
       apiKey: "your-mailgun-api-key",
       fromEmail: "noreply@yourdomain.com",
       fromName: "Get Active"
   )
   ```

   Set environment variables:
   - `MAILGUN_DOMAIN` = your domain
   - Email service will use Mailgun API key from environment

---

### Option 3: AWS SES

#### Setup Steps:

1. **Create AWS Account**
   - Go to [aws.amazon.com](https://aws.amazon.com)
   - Sign up for AWS account

2. **Set Up SES**
   - Go to AWS SES Console
   - Verify your email/domain
   - Request production access (if needed)

3. **Create IAM User**
   - Go to IAM Console
   - Create user with SES permissions
   - Generate access keys

4. **Configure in App**
   - Requires AWS SDK implementation
   - More complex setup

---

### Option 4: Custom Backend Endpoint

If you have your own backend, you can use a custom endpoint:

```swift
EmailService.shared.configure(
    provider: .custom(url: "https://your-api.com/send-email"),
    apiKey: "your-api-key",
    fromEmail: "noreply@getactive.app",
    fromName: "Get Active"
)
```

---

## Quick Start (SendGrid - Recommended)

### 1. Get SendGrid API Key
- Sign up at sendgrid.com
- Create API key in Settings → API Keys
- Copy the key

### 2. Set Environment Variable (Development)

In Xcode:
1. Edit Scheme → Run → Arguments
2. Add Environment Variable:
   - Name: `SENDGRID_API_KEY`
   - Value: `SG.your-key-here`

### 3. Set From Email

Add another environment variable:
- Name: `FROM_EMAIL`
- Value: `noreply@getactive.app`

### 4. Verify Sender in SendGrid

1. Go to SendGrid → Settings → Sender Authentication
2. Verify your email address
3. Or set up domain authentication

### 5. Test

1. Run your app
2. Try logging in
3. Check your email for 2FA code
4. If email fails, check debug console for error

---

## Production Setup

### For Production:

1. **Use Environment Variables or Keychain**
   - Don't hardcode API keys
   - Store in secure configuration

2. **Set Up Domain Authentication**
   - Verify your domain in SendGrid
   - Set up SPF and DKIM records
   - Improves deliverability

3. **Monitor Email Delivery**
   - Check SendGrid dashboard
   - Monitor bounce rates
   - Set up alerts

4. **Rate Limiting**
   - SendGrid free tier: 100 emails/day
   - Monitor usage
   - Upgrade if needed

---

## Testing

### Test Email Service:

```swift
// In your app, test sending:
EmailService.shared.send2FACode(
    to: "your-email@example.com",
    code: "123456"
) { result in
    switch result {
    case .success:
        print("✅ Email sent!")
    case .failure(let error):
        print("❌ Error: \(error)")
    }
}
```

---

## Troubleshooting

### "Email service not configured" error
- Make sure API key is set
- Check environment variables
- Verify `EmailService.shared.configure()` was called

### "Failed to send email" error
- Check API key is correct
- Verify sender email is verified in SendGrid
- Check SendGrid dashboard for errors
- Verify network connection

### Emails going to spam
- Set up domain authentication
- Use verified sender email
- Add SPF/DKIM records
- Warm up your IP (for new accounts)

---

## Current Implementation

The app is already set up to use `EmailService`! Just:

1. **Configure the service** with your API key
2. **Set environment variables** (easiest)
3. **Or call `EmailService.shared.configure()`** in app initialization

The 2FA flow will automatically use the email service once configured.

---

## Cost Estimates

- **SendGrid Free**: 100 emails/day (good for testing)
- **SendGrid Essentials**: $19.95/month for 50,000 emails
- **Mailgun Free**: 5,000 emails/month
- **Mailgun Foundation**: $35/month for 50,000 emails
- **AWS SES**: $0.10 per 1,000 emails (very cheap)

For a campus app with moderate usage, SendGrid free tier or Mailgun free tier should be sufficient initially.
