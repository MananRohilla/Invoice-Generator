class AppStrings {
  AppStrings._();

  static const appName = 'InvoGen';
  static const tagline = 'Professional Invoices, Simplified';

  // -- AI Chatbot (commented out — re-enable when feature is active) --
  // Import flutter_dotenv and uncomment these when re-enabling the chatbot:
  // static String get geminiApiKey => dotenv.env['GEMINI_API_KEY'] ?? '';
  // static String get geminiEndpoint => dotenv.env['GEMINI_ENDPOINT'] ?? '';
  // static const geminiSystemPrompt =
  //     'You are InvoGen AI, a helpful assistant for a professional invoice generator app used by Indian businesses. '
  //     'Help users with: creating and managing invoices, understanding GST (CGST/SGST/IGST), '
  //     'managing clients, tracking payments, and generating PDF invoices. '
  //     'Keep answers concise, practical, and relevant to Indian business invoicing.';
}
