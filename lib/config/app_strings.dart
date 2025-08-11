class AppStrings {
  // General
  static const String login = 'Login';
  static const String submit = 'Submit';
  static const String next = 'Next';
  static const String email = 'Email';
  static const String password = 'Password';

  // Onboarding Screen
  static const String skip = 'Skip';
  static const String back = 'Back';
  static const String getStarted = 'GET STARTED';
  static const String onboarding1Title = 'Measure Your Windows';
  static const String onboarding1Desc = 'Step 1: Get accurate measurements for a perfect, custom fit.';
  static const String onboarding2Title = 'Find Your Perfect Style';
  static const String onboarding2Desc = 'Step 2: Explore our curated collection and find the best curtains for you.';
  static const String onboarding3Title = 'Place Your Order';
  static const String onboarding3Desc = 'Step 3: A few simple clicks to bring beautiful design into your home.';

  // Google Sign-In Screen
  static const String welcomeTo = 'Welcome to';
  static const String signInToContinue = 'Sign in with Google to continue';
  static const String signInWithGoogle = 'Sign in with Google';
  static const String errorSigningIn = 'Error signing in: ';

  // Support Screen
  static const String helpAndSupport = 'Help & Support';
  static const String contactUs = 'Contact Us';
  static const String phoneSupport = 'Phone Support';
  static const String emailSupport = 'Email Support';
  static const String faqs = 'Frequently Asked Questions';
  static const String faq1Question = 'What is the process after I order?';
  static const String faq1Answer = 'Once you submit your design, our team begins production, which typically takes 5-7 business days. We will notify you via email and a push notification as soon as your order is ready for pickup at our shop.';
  static const String faq2Question = 'What is your quality and return policy?';
  static const String faq2Answer = 'To ensure you are 100% satisfied, we do not ship items. You must inspect your custom curtains at our shop during pickup. If you are happy with the quality, you will complete your payment at that time. All sales are final after inspection and payment.';
  static const String faq3Question = 'What happens if I find an issue during pickup?';
  static const String faq3Answer = 'Please bring any defects or concerns to our staff\'s attention immediately during your inspection. We will work with you to correct the issue, which may involve remaking the item. Our goal is for you to be completely happy before you leave the shop.';
  static const String faq4Question = 'What payment methods do you accept in-store?';
  static const String faq4Answer = 'We accept all major credit/debit cards, cash, and mobile payments (Apple Pay, Google Pay) at our physical location.';

  // Tailor Dashboard
  static const String tailorDashboardTitle = 'Tailor Dashboard';
  static const String manageOrdersTab = 'Manage Orders';
  static const String manageStockTab = 'Manage Stock';
  static const String errorFetchingOrders = 'Error fetching orders: ';
  static const String orderStatusUpdated = 'Order status updated to ';
  static const String errorUpdatingStatus = 'Error updating status: ';
  static const String updateOrderStatusTitle = 'Update Order Status';
  static const String statusPending = 'Pending';
  static const String statusProcessing = 'Processing';
  static const String statusCompleted = 'Completed';
  static const String statusCancelled = 'Cancelled';
  static const String statusNotAvailable = 'N/A';
  static const String noPhoneProvided = 'No phone provided';
  static const String noAddressProvided = 'No address provided';
  static const String measurementsLabel = 'Measurements: ';
  static const String widthUnit = ' m (W) x ';
  static const String heightUnit = ' m (H)';
  static const String orderedOnLabel = 'Ordered on: ';
  static const String updateStatusTooltip = 'Update Status';
  static const String noOrdersFound = 'No orders found.';

  // Stock Management
  static const String searchByCurtainName = 'Search by curtain name';
  static const String filterAll = 'All';
  static const String filterInStock = 'In Stock';
  static const String filterOutOfStock = 'Out of Stock';
  static const String errorFetchingData = 'Error fetching data: ';
  static const String noCurtainsFound = 'No curtains match your criteria.';
  static const String inStock = 'In Stock';
  static const String outOfStock = 'Out of Stock';

  // Reminder Screen
  static const String reminderTitle = 'Reminder';
  static const String reminderMessage = "It looks like you're outside our delivery zone. To keep our curtains in top shape, we only offer in-store pickup. \n\nAre you still interested in placing an order?";

  // Profile Setup Screen
  static const String profileSetupTitle = 'Customer Details';
  static const String hintName = 'Name';
  static const String hintPhone = 'Phone Number';
  static const String hintAddress = 'Address';
  static const String errorEnterName = 'Please enter your name';
  static const String errorEnterPhone = 'Please enter your phone number';
  static const String errorValidPhone = 'Please enter a valid phone number';
  static const String errorEnterAddress = 'Please enter your address';
  static const String errorSavingProfile = 'Error saving profile: ';

  // Recommendation Screen
  static const String topPicksTitle = 'Our Top Picks For You';
  static const String noMatchesFound = 'No matching curtains found.\nTry a different combination!';
  static const String confirmOrderTitle = 'Confirm Your Order';
  static const String fetchingMeasurement = 'Fetching latest measurement...';
  static const String errorNoMeasurement = 'No measurement found. Please add a window measurement first.';
  static const String errorFetchMeasurement = 'Could not fetch your measurements.';
  static const String usingLatestMeasurement = 'Using your latest saved measurement:';
  static const String labelWidth = 'Width';
  static const String labelHeight = 'Height';
  static const String buttonCancel = 'Cancel';
  static const String buttonAddMeasurement = 'Add Measurement';
  static const String buttonPlaceOrder = 'Place Order';
  static const String orderPlacedSuccess = 'Order placed successfully!';
  static const String errorPlacingOrder = 'Error placing order: ';
  static const String matchSuffix = '% Match';
  static const String buttonSimilar = 'Similar';
  static const String buttonOrderNow = 'Order Now';

  // My Orders
  static const String myOrdersTitle = 'My Orders';
  static const String errorMustBeLoggedIn = 'You must be logged in to see your orders.';
  static const String errorFailedToLoadOrders = 'Failed to load orders: ';
  static const String noOrdersYet = "You haven't placed any orders yet.";
  static const String orderPrefix = 'Order #';
  static const String curtainNotFound = 'Curtain Not Found';
  static const String labelSize = 'Size: ';
  static const String labelPlacedOn = 'Placed on: ';

  // Measurement Method Selection
  static const String windowMeasurementTitle = 'Window Measurement';
  static const String chooseMethodTitle = 'Choose Your Measurement Method';
  static const String chooseMethodSubtitle = 'Select the method that works best for you:';
  static const String aiMethodTitle = 'AI-Assisted Measurement';
  static const String aiMethodSubtitle = 'Use your camera for quick, accurate results';
  static const String manualMethodTitle = 'Manual Measurement';
  static const String manualMethodSubtitle = 'Follow our guide using a measuring tape';
  static const String infoCardTitle = 'Why accurate measurements matter:';
  static const String infoCardPoint1 = '• Ensures a perfect fit for your windows';
  static const String infoCardPoint2 = '• Reduces the need for returns or exchanges';
  static const String infoCardPoint3 = '• Saves time and provides better results';

  // Manual Measurement Guide
  static const String manualGuideTitle = 'Manual Measurement Guide';
  static const String step1Title = 'Prepare Your Tools';
  static const String step1Desc = "You'll need a measuring tape or ruler for accurate measurements.";
  static const String step1Tip1 = 'Use a metal measuring tape for best accuracy.';
  static const String step1Tip2 = 'Have someone help you hold the tape steady.';
  static const String step1Tip3 = 'Ensure the tape is straight and not sagging.';
  static const String step2Title = 'Measure Window Width';
  static const String step2Desc = 'Measure the width of your window from the inside edge of the frame to the other.';
  static const String step2Tip1 = 'Measure at the top, middle, and bottom.';
  static const String step2Tip2 = 'Use the smallest measurement to ensure a proper fit.';
  static const String step2Tip3 = 'Include the window frame in your measurement.';
  static const String step3Title = 'Measure Window Height';
  static const String step3Desc = 'Measure the height from the top to the bottom of the window frame.';
  static const String step3Tip1 = 'Measure at the left, center, and right sides.';
  static const String step3Tip2 = 'Use the smallest measurement for a proper fit.';
  static const String step3Tip3 = 'Measure from frame to frame, not glass to glass.';
  static const String step4Title = 'Record Your Measurements';
  static const String step4Desc = 'Enter your measurements below and double-check for accuracy.';
  static const String step4Tip1 = 'Round to the nearest centimeter or 1/8 inch.';
  static const String step4Tip2 = 'Double-check your measurements before proceeding.';
  static const String step4Tip3 = 'Consider adding extra length for the curtain rod placement.';
  static const String labelTips = 'Tips:';
  static const String labelUnit = 'Measurement Unit';
  static const String unitMeters = 'Meters';
  static const String unitInches = 'Inches';
  static const String labelWindowWidth = 'Window Width';
  static const String labelWindowHeight = 'Window Height';
  static const String hintMeters = 'e.g., 1.5';
  static const String hintInches = 'e.g., 60';
  static const String errorEnterValue = 'Please enter a value.';
  static const String errorValidNumber = 'Please enter a valid number.';
  static const String previous = 'Previous';
  static const String savedDialogTitle = 'Measurement Saved';
  static const String savedDialogContent = 'Your measurement has been saved successfully!';
  static const String warningDialogTitle = 'Measurement Warning';
  static const String review = 'Review';
  static const String continueAnyway = 'Continue Anyway';
  static const String errorDialogTitle = 'Save Failed';
  static const String errorDialogContent = 'Failed to save measurement: ';
  static const String retry = 'Retry';
  static const String ok = 'Okay';
  // ... add all other strings here
}