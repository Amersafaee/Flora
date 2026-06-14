import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import * as nodemailer from "nodemailer";
import { GoogleGenerativeAI } from "@google/generative-ai";

// Initialize Firebase Admin SDK once
admin.initializeApp();

// ─────────────────────────────────────────────────────────────────────────────
// Email transporter setup
// ─────────────────────────────────────────────────────────────────────────────
// To configure: create a .env file in the functions directory with:
//   EMAIL_USER="youremail@gmail.com"
//   EMAIL_PASS="your_gmail_app_password"
//
// To get a Gmail App Password:
//   1. Go to myaccount.google.com → Security → 2-Step Verification → App passwords
//   2. Create an App password for "Mail" → copy the 16-character password
// ─────────────────────────────────────────────────────────────────────────────
function createTransporter() {
  return nodemailer.createTransport({
    service: "gmail",
    auth: {
      user: process.env.EMAIL_USER ?? "",
      pass: process.env.EMAIL_PASS ?? "",
    },
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// sendEmailOTP
// ─────────────────────────────────────────────────────────────────────────────
// Generates a 6-digit code, stores it in Firestore with a 10-minute TTL,
// and sends it to the user's email via Gmail.
//
// Flutter call:
//   final fn = FirebaseFunctions.instance.httpsCallable('sendEmailOTP');
//   await fn.call({'email': 'user@example.com'});
// ─────────────────────────────────────────────────────────────────────────────
export const sendEmailOTP = functions.https.onCall(
  async (request: functions.https.CallableRequest) => {
    const email = (request.data.email as string | undefined)?.trim().toLowerCase();

    if (!email || !email.includes("@")) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "A valid email address is required."
      );
    }

    // Generate 6-digit code
    const code = Math.floor(100000 + Math.random() * 900000).toString();

    // Store hashed code + expiry in Firestore (_otps collection)
    const expiresAt = admin.firestore.Timestamp.fromDate(
      new Date(Date.now() + 10 * 60 * 1000) // 10 minutes
    );
    await admin.firestore().collection("_otps").doc(email).set({
      code,         // store plaintext (low-risk; expires in 10 min)
      expiresAt,
      attempts: 0,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    // Send the email
    const transporter = createTransporter();
    await transporter.sendMail({
      from: `Flora 🌿 <${process.env.EMAIL_USER}>`,
      to: email,
      subject: "Your Flora sign-in code",
      text: `Your Flora sign-in code is: ${code}\n\nThis code expires in 10 minutes. Do not share it.`,
      html: `
        <div style="font-family:sans-serif;max-width:400px;margin:auto;padding:32px">
          <h2 style="color:#2D5016">🌿 Flora</h2>
          <p style="color:#3B2F1E">Your sign-in code is:</p>
          <div style="font-size:48px;font-weight:700;letter-spacing:12px;color:#2D5016;
                      background:#D4E6C3;border-radius:12px;padding:16px 24px;
                      text-align:center;margin:16px 0">
            ${code}
          </div>
          <p style="color:#6B8F5E;font-size:14px">
            This code expires in <strong>10 minutes</strong>.<br>
            Do not share it with anyone. Flora will never ask for this code over chat.
          </p>
        </div>
      `,
    });

    return { success: true };
  }
);

// ─────────────────────────────────────────────────────────────────────────────
// verifyEmailOTP
// ─────────────────────────────────────────────────────────────────────────────
// Verifies the 6-digit code and returns a Firebase custom token so the
// Flutter app can sign in with FirebaseAuth.signInWithCustomToken().
//
// Flutter call:
//   final fn = FirebaseFunctions.instance.httpsCallable('verifyEmailOTP');
//   final result = await fn.call({'email': '...', 'code': '123456'});
//   await FirebaseAuth.instance.signInWithCustomToken(result.data['customToken']);
// ─────────────────────────────────────────────────────────────────────────────
export const verifyEmailOTP = functions.https.onCall(
  async (request: functions.https.CallableRequest) => {
    const email = (request.data.email as string | undefined)?.trim().toLowerCase();
    const code = (request.data.code as string | undefined)?.trim();

    if (!email || !code) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "Email and code are required."
      );
    }

    const ref = admin.firestore().collection("_otps").doc(email);
    const doc = await ref.get();

    if (!doc.exists) {
      throw new functions.https.HttpsError(
        "not-found",
        "No code was sent to this email. Please request a new one."
      );
    }

    const data = doc.data()!;
    const now = admin.firestore.Timestamp.now();

    // Check expiry
    if (now.seconds > (data.expiresAt as admin.firestore.Timestamp).seconds) {
      await ref.delete();
      throw new functions.https.HttpsError(
        "deadline-exceeded",
        "This code has expired. Please request a new one."
      );
    }

    // Check attempt limit (max 5)
    if ((data.attempts as number) >= 5) {
      await ref.delete();
      throw new functions.https.HttpsError(
        "resource-exhausted",
        "Too many incorrect attempts. Please request a new code."
      );
    }

    // Check code
    if (data.code !== code) {
      await ref.update({ attempts: (data.attempts as number) + 1 });
      const left = 5 - ((data.attempts as number) + 1);
      throw new functions.https.HttpsError(
        "unauthenticated",
        `Incorrect code. ${left} attempt${left === 1 ? "" : "s"} left.`
      );
    }

    // ✅ Code is correct — delete it immediately (single-use)
    await ref.delete();

    // Get or create the Firebase Auth user for this email
    let uid: string;
    try {
      const existing = await admin.auth().getUserByEmail(email);
      uid = existing.uid;
    } catch {
      // User doesn't exist yet — create them
      const newUser = await admin.auth().createUser({ email });
      uid = newUser.uid;
    }

    // Return a short-lived custom token the Flutter app uses to sign in
    const customToken = await admin.auth().createCustomToken(uid);
    return { customToken };
  }
);

// ─────────────────────────────────────────────────────────────────────────────
// identifyPlant — placeholder for Gemini Vision API
// ─────────────────────────────────────────────────────────────────────────────
export const identifyPlant = functions.https.onCall(
  async (request: functions.https.CallableRequest) => {
    if (!request.auth) {
      throw new functions.https.HttpsError("unauthenticated", "User must be signed in.");
    }

    const { imageBase64, mode } = request.data;
    if (!imageBase64 || !mode) {
      throw new functions.https.HttpsError("invalid-argument", "Missing image or mode.");
    }

    try {
      const apiKey = process.env.GEMINI_API_KEY;
      if (!apiKey) {
        throw new functions.https.HttpsError("failed-precondition", "GEMINI_API_KEY is not configured");
      }
      const genAI = new GoogleGenerativeAI(apiKey);
      const generativeModel = genAI.getGenerativeModel({
        model: "gemini-1.5-flash",
      });

      const prompt = mode === "species"
        ? `You are an expert botanist. Analyze this plant image. Return a JSON with: "commonName" (string), "scientificName" (string), "confidence" (number 0-100), "traits" (array of strings like "Pet Friendly", "Low Light", etc), and "careDefaults" (object with "sun", "water", "fertilizer" each being "low", "medium", or "high"). Ensure it is 100% valid JSON and nothing else.`
        : `You are an expert plant pathologist. Analyze this plant image for diseases or pests. Return a JSON with: "diagnosis" (string), "severity" ("low", "medium", or "high"), "confidence" (number 0-100), and "treatmentSteps" (array of strings). Ensure it is 100% valid JSON and nothing else.`;

      const req = {
        contents: [{
          role: "user",
          parts: [
            { text: prompt },
            { inlineData: { data: imageBase64, mimeType: "image/jpeg" } }
          ]
        }],
        generationConfig: {
          responseMimeType: "application/json",
        }
      };

      const result = await generativeModel.generateContent(req);
      const responseText = result.response.text() || "{}";

      const cleanJson = responseText.replace(/```json/g, '').replace(/```/g, '').trim();

      return JSON.parse(cleanJson);

    } catch (error) {
      console.error("Generative AI Error:", error);
      throw new functions.https.HttpsError("internal", "Failed to analyze image.");
    }
  }
);

// ─────────────────────────────────────────────────────────────────────────────
// floraChat — placeholder for Gemini chat API
// ─────────────────────────────────────────────────────────────────────────────
export const floraChat = functions.https.onRequest(async (req, res) => {
  res.set("Access-Control-Allow-Origin", "*");
  res.set("Access-Control-Allow-Methods", "POST, OPTIONS");
  res.set("Access-Control-Allow-Headers", "Content-Type, Authorization");

  if (req.method === "OPTIONS") {
    res.status(204).send("");
    return;
  }

  if (req.method !== "POST") {
    res.status(405).send("Method Not Allowed");
    return;
  }

  const authHeader = req.headers.authorization;
  if (!authHeader || !authHeader.startsWith("Bearer ")) {
    res.status(401).send("Unauthorized");
    return;
  }

  const idToken = authHeader.split("Bearer ")[1];
  let uid: string;
  try {
    const decodedToken = await admin.auth().verifyIdToken(idToken);
    uid = decodedToken.uid;
  } catch (error) {
    res.status(401).send("Unauthorized");
    return;
  }

  try {
    const plantsSnapshot = await admin.firestore().collection("users").doc(uid).collection("plants").limit(10).get();
    const plantNicknames = plantsSnapshot.docs.map(d => {
      const data = d.data();
      return data.nickname || data.commonName || "Unknown Plant";
    });

    const systemInstruction = `You are Flora, a warm, knowledgeable, and conversational AI plant care expert. You have a long memory of this conversation. Keep your answers brief, practical, and highly personalized based on our chat history. The user currently has ${plantNicknames.length} plants in their collection: ${plantNicknames.join(", ")}. Always prioritize referring to their actual plants if relevant.`;

    const apiKey = process.env.GEMINI_API_KEY;
    if (!apiKey) {
      throw new Error("GEMINI_API_KEY is not configured");
    }
    const genAI = new GoogleGenerativeAI(apiKey);
    const generativeModel = genAI.getGenerativeModel({
      model: "gemini-1.5-flash",
      systemInstruction: systemInstruction
    });

    res.setHeader("Content-Type", "text/event-stream");
    res.setHeader("Cache-Control", "no-cache");
    res.setHeader("Connection", "keep-alive");

    const messages = req.body.messages || [];

    const streamingResp = await generativeModel.generateContentStream({
      contents: messages.map((m: any) => ({
        role: m.role === "assistant" ? "model" : m.role,
        parts: [{ text: m.content }]
      }))
    });

    for await (const chunk of streamingResp.stream) {
      const text = chunk.text?.() ?? "";
      if (text) {
        res.write(`data: ${JSON.stringify({ text })}\n\n`);
      }
    }

    const flashModel = genAI.getGenerativeModel({
      model: "gemini-1.5-flash",
      systemInstruction: "Generate exactly 3 short suggestion phrases for the user to reply with in the context of the conversation. Return ONLY a JSON array of strings, nothing else."
    });

    const flashReq = {
      contents: messages.map((m: any) => ({
        role: m.role === "assistant" ? "model" : m.role,
        parts: [{ text: m.content }]
      })),
      generationConfig: {
        responseMimeType: "application/json",
      }
    };
    const suggestionsResult = await flashModel.generateContent(flashReq);
    let suggestions = ["How much water?", "What about sunlight?", "Any fertilizer?"];
    try {
      const flashText = suggestionsResult.response.text() || "[]";
      const cleanJson = flashText.replace(/```json/g, '').replace(/```/g, '').trim();
      const parsed = JSON.parse(cleanJson);
      if (Array.isArray(parsed) && parsed.length > 0) {
        suggestions = parsed.slice(0, 3);
      }
    } catch (e) {
      console.error("Failed to parse suggestions", e);
    }

    res.write(`data: ${JSON.stringify({ suggestions })}\n\n`);
    res.write(`data: [DONE]\n\n`);
    res.end();
  } catch (error) {
    console.error("Generative AI Error:", error);
    res.status(500).send("Internal Server Error");
  }
});
