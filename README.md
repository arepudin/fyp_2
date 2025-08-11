# Tailormate - Configurable Flutter App

A Flutter application with a centralized configuration system that allows easy rebranding and environment-specific customization.

## Features

- **Centralized Configuration**: All app settings managed through environment files
- **Easy Rebranding**: Customize app name, colors, company information, and assets
- **Environment Support**: Separate configurations for development and production
- **Theme Consistency**: Centralized theme management with configurable colors

## Configuration System

The app uses a centralized configuration system that allows customization through environment files:

### Configuration Files

- **`lib/config/app_config.dart`**: Main configuration class for app settings
- **`lib/config/theme_config.dart`**: Theme and color configuration
- **`.env.development`**: Development environment variables  
- **`.env.production`**: Production environment variables

### Configurable Values

- **App Information**: App name and branding
- **Supabase Settings**: Database URL and API keys
- **Company Information**: Name, email, phone, and logo
- **Theme Colors**: Primary colors and backgrounds
- **Asset Paths**: Logo and icon file paths

## Environment Configuration

### Development Environment
```bash
flutter run --dart-define=ENVIRONMENT=development
```

### Production Environment  
```bash
flutter run --dart-define=ENVIRONMENT=production
```

### Building for Release
```bash
# Development build
flutter build apk --dart-define=ENVIRONMENT=development

# Production build
flutter build apk --dart-define=ENVIRONMENT=production
```

## Customization Guide

### Rebranding the App

1. **Update Environment Files**: Modify `.env.development` and `.env.production`
   ```env
   APP_NAME=YourAppName
   COMPANY_NAME=Your Company Name
   COMPANY_EMAIL=contact@yourcompany.com
   SUPPORT_PHONE=+1-234-567-8900
   COMPANY_LOGO_PATH=asset/your_logo.jpg
   ```

2. **Update Colors**: Change the PRIMARY_COLOR value
   ```env
   PRIMARY_COLOR=255,32,150,243  # Blue example (A,R,G,B)
   BACKGROUND_COLOR=255,250,250,250
   ```

3. **Replace Assets**: Update logo and icon files in the `asset/` directory

4. **Rebuild**: Run the app with your preferred environment

### Adding New Configuration Values

1. Add the variable to environment files
2. Add getter method to `AppConfig` class  
3. Use the config value in your code: `AppConfig.yourNewValue`

## Getting Started

### Prerequisites
- Flutter SDK (>=3.8.1)
- Dart SDK
- Android Studio / VS Code

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd fyp_2
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Set up environment**
   - Copy and customize `.env.development` and `.env.production` as needed
   - Update Supabase credentials if using a different backend

4. **Run the app**
   ```bash
   # Development
   flutter run --dart-define=ENVIRONMENT=development
   
   # Production  
   flutter run --dart-define=ENVIRONMENT=production
   ```

## Architecture

The app follows a modular architecture with:

- **Configuration Layer**: Environment-based settings management
- **Theme Layer**: Centralized styling and theming  
- **Service Layer**: Backend integration (Supabase)
- **UI Layer**: Screen components and widgets

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
