class AppStrings {
  AppStrings._();

  static const appName = 'InvoGen';
  static const tagline = 'Professional Invoices, Simplified';

  // Replace with your actual Gemini API key
  static const geminiApiKey = 'YOUR_GEMINI_API_KEY_HERE';
  static const geminiEndpoint =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent';

  static const geminiSystemPrompt =
      'You are InvoGen AI, a helpful assistant for a professional invoice generator app used by Indian businesses. '
      'Help users with: creating and managing invoices, understanding GST (CGST/SGST/IGST), '
      'managing clients, tracking payments, and generating PDF invoices. '
      'Keep answers concise, practical, and relevant to Indian business invoicing.';
}
