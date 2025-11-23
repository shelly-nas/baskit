# Email Service Setup

## Overview

The user service now includes a fully functional email service for sending verification emails and password reset emails.

## Current Implementation

The email service uses **Nodemailer** with flexible SMTP configuration:

### Development Mode (Default)

- Uses **Ethereal Email** (https://ethereal.email) - a fake SMTP service for testing
- Automatically creates a temporary test account on startup
- Emails are captured and can be viewed via preview URLs in the logs
- No configuration needed!

### How to View Test Emails

1. Register a new user or trigger an email action
2. Check the Docker logs:
   ```bash
   docker compose logs user-service | grep "previewUrl"
   ```
3. Copy the preview URL and open it in your browser
4. You'll see the exact email that would be sent in production

Example log output:

```json
{
  "messageId": "<02eb3cee-72dc-4deb-d9e9-7b2a990cd3fa@baskit.app>",
  "previewUrl": "https://ethereal.email/message/aSM9TDKY-EBaB.jRaSM9TdthUtbp7yf3AAAAAW2-4r4JsfTNT7UdRppla3Q",
  "to": "test@example.com",
  "verificationUrl": "http://localhost:3000/verify-email?token=..."
}
```

## Production Configuration

For production deployment, configure these environment variables in `docker-compose.yml`:

```yaml
environment:
  - APP_URL=https://your-domain.com
  - FROM_EMAIL=noreply@your-domain.com

  # SMTP Configuration
  - SMTP_HOST=smtp.sendgrid.net # Your SMTP provider
  - SMTP_PORT=587 # Usually 587 or 465
  - SMTP_SECURE=false # true for 465, false for 587
  - SMTP_USER=your-smtp-username # Your SMTP username
  - SMTP_PASS=your-smtp-password # Your SMTP password
```

### Popular SMTP Providers

#### SendGrid

```yaml
- SMTP_HOST=smtp.sendgrid.net
- SMTP_PORT=587
- SMTP_SECURE=false
- SMTP_USER=apikey
- SMTP_PASS=<your-sendgrid-api-key>
```

#### AWS SES

```yaml
- SMTP_HOST=email-smtp.<region>.amazonaws.com
- SMTP_PORT=587
- SMTP_SECURE=false
- SMTP_USER=<your-aws-smtp-username>
- SMTP_PASS=<your-aws-smtp-password>
```

#### Gmail (for testing only)

```yaml
- SMTP_HOST=smtp.gmail.com
- SMTP_PORT=587
- SMTP_SECURE=false
- SMTP_USER=your-email@gmail.com
- SMTP_PASS=<app-specific-password>
```

**Note:** Gmail requires an app-specific password. Not recommended for production.

#### Mailgun

```yaml
- SMTP_HOST=smtp.mailgun.org
- SMTP_PORT=587
- SMTP_SECURE=false
- SMTP_USER=<your-mailgun-username>
- SMTP_PASS=<your-mailgun-password>
```

## Email Types

### 1. Verification Email

Sent when a user registers a new account.

- Contains a verification link valid for 24 hours
- Link format: `{APP_URL}/verify-email?token={token}`

### 2. Password Reset Email

Sent when a user requests a password reset.

- Contains a reset link valid for 1 hour
- Link format: `{APP_URL}/reset-password?token={token}`

## Local Development with Mailhog (Alternative)

If you prefer to use Mailhog instead of Ethereal Email:

1. Add Mailhog to `docker-compose.yml`:

```yaml
mailhog:
  image: mailhog/mailhog
  container_name: baskit-mailhog
  ports:
    - "1025:1025" # SMTP port
    - "8025:8025" # Web UI port
  networks:
    - baskit-network
```

2. Update user-service environment:

```yaml
- SMTP_HOST=mailhog
- SMTP_PORT=1025
```

3. View emails at: http://localhost:8025

## Testing

### Manual Test

```bash
curl -X POST http://localhost:3001/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "SecurePass123!",
    "displayName": "Test User"
  }'
```

Then check logs for the preview URL:

```bash
docker compose logs user-service --tail=50 | grep "previewUrl"
```

### Integration Tests

The existing integration tests in `test/integration/` include email verification flow tests.

## Troubleshooting

### Email not being sent

1. Check Docker logs: `docker compose logs user-service`
2. Look for "Email transporter initialized" message
3. Check for any error messages in the logs

### Cannot see preview URLs

- Make sure you're looking at the logs after registration
- The preview URL is only available when using Ethereal Email (development mode)

### Production emails not working

1. Verify SMTP credentials are correct
2. Check your SMTP provider's dashboard for errors
3. Ensure your domain is verified (for SES, SendGrid, etc.)
4. Check firewall/security group settings for outbound port 587/465

## Security Notes

- Never commit SMTP credentials to version control
- Use environment variables for all sensitive configuration
- In production, use a dedicated email service provider
- Consider implementing rate limiting for email sending
- Monitor your email sending quota with your provider

## Future Enhancements

- [ ] Email templates with better styling
- [ ] Support for multiple languages
- [ ] Email queue for bulk sending
- [ ] Retry logic for failed emails
- [ ] Email analytics and tracking
- [ ] Unsubscribe functionality
