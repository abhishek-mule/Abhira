const functions = require('firebase-functions');
const { GoogleGenerativeAI } = require('@google/generative-ai');

// Initialize Gemini AI with API key
const genAI = new GoogleGenerativeAI('AIzaSyBDlmB4m1SlxiGw_H0eQ70OchnyWyfXUzc');

exports.generateResponse = functions.https.onCall(async (data, context) => {
  try {
    const { prompt } = data;

    if (!prompt) {
      throw new functions.https.HttpsError('invalid-argument', 'Prompt is required');
    }

    // Get the generative model
    const model = genAI.getGenerativeModel({ model: 'gemini-2.0-flash' });

    // Generate content
    const result = await model.generateContent(prompt);
    const response = await result.response;
    const text = response.text();

    return {
      response: text,
      timestamp: new Date().toISOString(),
    };
  } catch (error) {
    console.error('Error generating response:', error);
    throw new functions.https.HttpsError('internal', 'Failed to generate response');
  }
});