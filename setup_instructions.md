# Google Calendar to Telegram Daily Summary Service - Setup Instructions

This service automatically fetches your Google Calendar events each day and sends a summary to your Telegram chat at 9 AM.

## Prerequisites

- Python 3.7 or higher
- A Google account with Google Calendar
- A Telegram account

## Step 1: Set Up Google Calendar API

### 1.1 Create a Google Cloud Project

1. Go to the [Google Cloud Console](https://console.cloud.google.com/)
2. Click on "Select a project" and then "New Project"
3. Enter a project name (e.g., "Calendar Telegram Bot")
4. Click "Create"

### 1.2 Enable Google Calendar API

1. In the Google Cloud Console, ensure your new project is selected
2. Go to "APIs & Services" > "Library"
3. Search for "Google Calendar API"
4. Click on it and then click "Enable"

### 1.3 Configure OAuth Consent Screen

1. Go to "APIs & Services" > "OAuth consent screen"
2. Choose "External" user type (unless you have a Google Workspace account)
3. Fill in the required information:
   - App name: "Calendar Telegram Bot"
   - User support email: Your email
   - Developer contact information: Your email
4. Click "Save and Continue"
5. On the Scopes page, click "Add or Remove Scopes"
6. Add the scope: `https://www.googleapis.com/auth/calendar.readonly`
7. Click "Save and Continue"
8. Add your email as a test user
9. Click "Save and Continue"

### 1.4 Create Credentials

1. Go to "APIs & Services" > "Credentials"
2. Click "Create Credentials" > "OAuth client ID"
3. Choose "Desktop application" as the application type
4. Enter a name (e.g., "Calendar Bot Client")
5. Click "Create"
6. Download the JSON file and rename it to `credentials.json`
7. Place this file in the same directory as the Python script

## Step 2: Set Up Telegram Bot

### 2.1 Create a Telegram Bot

1. Open Telegram and search for `@BotFather`
2. Start a chat with BotFather
3. Send the command `/newbot`
4. Follow the instructions:
   - Choose a name for your bot (e.g., "My Calendar Bot")
   - Choose a username ending with "bot" (e.g., "mycalendarbot")
5. BotFather will provide you with a bot token. **Save this token securely!**

### 2.2 Get Your Chat ID

1. Start a chat with your newly created bot
2. Send any message to the bot
3. Open this URL in your browser (replace `YOUR_BOT_TOKEN` with your actual token):
   ```
   https://api.telegram.org/botYOUR_BOT_TOKEN/getUpdates
   ```
4. Look for the `"chat":{"id":` field in the response. The number after `"id":` is your chat ID
5. **Save this chat ID!**

## Step 3: Install and Configure the Service

### 3.1 Install Dependencies

```bash
pip install -r requirements.txt
```

### 3.2 Set Environment Variables

Set the following environment variables with your Telegram bot token and chat ID:

**On Linux/macOS:**
```bash
export TELEGRAM_BOT_TOKEN="your_bot_token_here"
export TELEGRAM_CHAT_ID="your_chat_id_here"
```

**On Windows:**
```cmd
set TELEGRAM_BOT_TOKEN=your_bot_token_here
set TELEGRAM_CHAT_ID=your_chat_id_here
```

### 3.3 Test the Service

Run the script manually to test:

```bash
python calendar_telegram_service.py
```

The first time you run it, it will open a browser window for Google OAuth authentication. Follow the prompts to authorize the application.

## Step 4: Schedule Daily Execution

### 4.1 Using Cron (Linux/macOS)

1. Open your crontab:
   ```bash
   crontab -e
   ```

2. Add this line to run the script daily at 9 AM:
   ```
   0 9 * * * /usr/bin/python3 /path/to/your/calendar_telegram_service.py
   ```

3. Make sure to use the full paths to both Python and your script

### 4.2 Using Task Scheduler (Windows)

1. Open Task Scheduler
2. Click "Create Basic Task"
3. Name: "Calendar Telegram Summary"
4. Trigger: Daily at 9:00 AM
5. Action: Start a program
6. Program: `python`
7. Arguments: `C:\path\to\your\calendar_telegram_service.py`
8. Start in: `C:\path\to\your\script\directory`

## Troubleshooting

### Common Issues

1. **"Credentials file not found"**
   - Make sure `credentials.json` is in the same directory as the script
   - Verify the file was downloaded correctly from Google Cloud Console

2. **"Environment variables not set"**
   - Ensure `TELEGRAM_BOT_TOKEN` and `TELEGRAM_CHAT_ID` are properly set
   - On some systems, you may need to restart your terminal/command prompt

3. **"Permission denied" errors**
   - Make sure the script has execute permissions: `chmod +x calendar_telegram_service.py`
   - Verify the paths in your cron job are correct

4. **Bot not responding**
   - Verify your bot token is correct
   - Make sure you've started a chat with your bot
   - Check that your chat ID is correct

### Testing

To test individual components:

1. **Test Google Calendar connection:**
   - Run the script and check if it authenticates successfully
   - Verify it can fetch your calendar events

2. **Test Telegram messaging:**
   - Try sending a test message using the Telegram Bot API
   - Verify your bot token and chat ID are working

## Security Notes

- Keep your `credentials.json` file secure and never share it
- Keep your Telegram bot token secure
- Consider using environment variables or a secure configuration file for sensitive data
- The `token.json` file will be created automatically after first authentication - keep this secure too

## File Structure

Your project directory should look like this:
```
calendar-telegram-service/
├── calendar_telegram_service.py
├── credentials.json
├── requirements.txt
├── setup_instructions.md
└── token.json (created automatically)
```

