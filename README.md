# Water User Notify

A Flutter app for managing irrigation water users and sending notifications about sprinkler head usage based on water shares and rates.

## Features

### 🚰 Water Management
- **Rate Settings**: Configure the current water rate that affects all calculations
- **Water Users**: Add and manage water users with their contact information and water shares
- **Formula Calculation**: Uses the formula `(Rate × 3 × Shares) ÷ Hours = Sprinkler Heads`

### 👥 User Management
- **Manual Entry**: Add water users manually with name, phone, email, and water shares
- **Contact Import**: Import users directly from your device's contacts
- **User Details**: View and manage user information and contact details

### 📱 Notifications
- **SMS Notifications**: Send text messages to water users with their calculations
- **Email Notifications**: Send email notifications with detailed information
- **Local Notifications**: In-app notifications for immediate feedback
- **Batch Notifications**: Send notifications to all users at once for 12-hour or 24-hour periods

### 📊 Dashboard
- **System Overview**: View total users, total shares, and current rate
- **Real-time Calculations**: See sprinkler head calculations for each user
- **Quick Actions**: Send notifications with one tap

## Getting Started

### Prerequisites
- Flutter SDK (3.8.1 or higher)
- Android Studio / VS Code
- Android device or emulator

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd water_user_notify
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Run the app**
   ```bash
   flutter run
   ```

### Permissions

The app requires the following permissions:
- **Contacts**: To import water users from your device contacts
- **SMS**: To send text message notifications
- **Internet**: For email notifications
- **Notifications**: For local app notifications

## How to Use

### 1. Set the Rate
- Open the app and go to the "Rate Settings" card
- Tap the edit icon to modify the current rate
- Enter the new rate value and save
- The rate affects all sprinkler head calculations

### 2. Add Water Users

#### Manual Entry:
- Tap "Add User" button
- Fill in the user's name, phone number, email, and water shares
- Tap "Add Water User" to save

#### Import from Contacts:
- Tap "Add User" button
- Tap "Import from Contacts"
- Select a contact from your device
- Enter the water shares for that contact
- Tap "Add" to save

### 3. Send Notifications

#### Individual Notifications:
- Tap the notification icon on any user card
- Choose between 12-hour or 24-hour period
- The app will send SMS/email notifications

#### Batch Notifications:
- Use the "Quick Actions" card
- Tap "Notify All (12h)" or "Notify All (24h)"
- Confirm to send notifications to all users

### 4. View Calculations
- Expand any user card to see their sprinkler head calculations
- Calculations are shown for both 12-hour and 24-hour periods
- Values update automatically when the rate changes

## Formula Explanation

The app uses this formula to calculate sprinkler head usage:

```
Sprinkler Heads = (Rate × 3 × Water Shares) ÷ Hours in Period
```

**Example:**
- Rate: 2.0
- Water Shares: 5.0
- Period: 12 hours
- Calculation: (2.0 × 3 × 5.0) ÷ 12 = 2.5 sprinkler heads

## Technical Details

### Architecture
- **Provider Pattern**: State management using Provider
- **Service Layer**: Separate services for contacts, notifications, storage, and calculations
- **Local Storage**: SharedPreferences for data persistence
- **Platform Integration**: Native contact and notification APIs

### Dependencies
- `flutter_local_notifications`: Local notifications
- `shared_preferences`: Data persistence
- `contacts_service`: Contact management
- `permission_handler`: Permission handling
- `url_launcher`: SMS and email launching
- `provider`: State management
- `intl`: Date formatting

### File Structure
```
lib/
├── main.dart                 # App entry point
├── models/
│   └── water_user.dart      # Water user data model
├── providers/
│   └── water_management_provider.dart  # State management
├── screens/
│   ├── home_screen.dart     # Main dashboard
│   └── add_user_screen.dart # Add user screen
├── services/
│   ├── contact_service.dart     # Contact management
│   ├── notification_service.dart # Notifications
│   ├── storage_service.dart     # Data persistence
│   └── water_calculator.dart    # Calculation logic
└── widgets/
    ├── quick_actions_card.dart  # Quick action buttons
    ├── rate_settings_card.dart  # Rate configuration
    ├── stats_card.dart          # Dashboard stats
    └── water_users_list.dart    # User list display
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Support

For support or questions, please open an issue in the repository or contact the development team.
