require("dotenv").config();

const express = require("express");
const cors = require("cors");
const crypto = require("crypto");
const OpenAI = require("openai");

const app = express();
const port = process.env.PORT || 3001;

// Configure CORS for all origins, methods, and headers
app.use(
  cors({
    origin: "*",
    methods: ["GET", "POST", "PUT", "DELETE", "OPTIONS"],
    allowedHeaders: ["Content-Type", "Authorization"],
  })
);

app.use(express.json());

// Initialize official OpenAI SDK with OPENAI_API_KEY from environment
const openai = new OpenAI({
  apiKey: process.env.OPENAI_API_KEY,
});

/**
 * Triggers or mocks HeyGen Interactive Avatar speech task.
 */
async function askAvatarToSpeak(sessionId, text) {
  console.info("HeyGen speech task queued:", { sessionId, text });
  return { task_id: `mock-task-${crypto.randomUUID()}` };
}

// Mock SDP offer for HeyGen Interactive Avatar WebRTC session negotiation
const mockOfferSdp = [
  "v=0",
  "o=- 0 0 IN IP4 127.0.0.1",
  "s=Mock Avatar Session",
  "t=0 0",
  "a=group:BUNDLE 0",
  "m=video 9 UDP/TLS/RTP/SAVPF 96",
  "c=IN IP4 0.0.0.0",
  "a=rtcp:9 IN IP4 0.0.0.0",
  "a=ice-ufrag:mock",
  "a=ice-pwd:mockpasswordmockpassword",
  "a=fingerprint:sha-256 00:00:00:00:00:00:00:00:00:00:00:00:00:00:00:00:00:00:00:00:00:00:00:00:00:00:00:00:00:00:00:00",
  "a=setup:actpass",
  "a=mid:0",
  "a=sendonly",
  "a=rtcp-mux",
  "a=rtpmap:96 VP8/90000",
  "",
].join("\r\n");

// Endpoint: Start Avatar Stream
app.post("/api/start-stream", async (_request, response) => {
  const session_id = `mock-session-${crypto.randomUUID()}`;
  response.status(201).json({
    session_id,
    offer: { type: "offer", sdp: mockOfferSdp },
  });
});

/**
 * Endpoint: Paw Live (AI Livestreamer Chat via OpenAI GPT-4o-mini)
 * Receives productContext and customerQuestion, calls OpenAI API dynamically, returns response.
 */
app.post(["/api/paw-live/chat", "/api/chat"], async (request, response) => {
  const { productContext = {}, customerQuestion, message, sessionId } = request.body || {};
  const queryText = customerQuestion || message || "";

  if (typeof queryText !== "string" || !queryText.trim()) {
    return response.status(400).json({ error: "customerQuestion must be a non-empty string" });
  }

  const {
    name = "Product",
    fabric = "Premium Material",
    fit = "Standard Cut",
    price = "$40",
    colors = "Various Colors",
    stock = "Limited Stock",
  } = productContext;

  const systemPrompt = `You are an energetic, charismatic TikTok livestream host for an MSME brand selling products live.
You are presenting the product "${name}".
Product Attributes:
- Fabric/Material: ${fabric}
- Fit/Cut: ${fit}
- Colors: ${colors}
- Price: ${price}
- Stock Remaining: ${stock}

Instructions:
- Answer the customer's question directly, warmly, and enthusiastically.
- Keep your response concise (under 2-3 sentences max).
- Highlight relevant product attributes naturally and build excitement for buying now!`;

  try {
    const completion = await openai.chat.completions.create({
      model: "gpt-4o-mini",
      messages: [
        { role: "system", content: systemPrompt },
        { role: "user", content: queryText.trim() },
      ],
      max_tokens: 150,
      temperature: 0.7,
    });

    const reply = completion.choices[0]?.message?.content?.trim() || "Thank you for asking! Grab yours now!";
    const streamId = `stream-${crypto.randomUUID()}`;
    const avatarTask = await askAvatarToSpeak(sessionId || "default-session", reply);

    return response.json({
      reply,
      streamId,
      avatarTask,
      session_id: sessionId || "default-session",
    });
  } catch (error) {
    console.error("OpenAI Paw Live Error:", error);
    return response.status(500).json({
      error: "Paw Live OpenAI API call failed",
      details: error.message,
    });
  }
});

/**
 * Endpoint: Paw Snap (TikTok Content Engine via OpenAI GPT-4o-mini Structured JSON)
 * Receives imageContext and demographic, calls OpenAI with JSON format, returns hook/script/caption/tags.
 */
app.post("/api/paw-snap/generate", async (request, response) => {
  const { imageContext = "Fashion Item", demographic = "Gen Z trendy" } = request.body || {};

  const systemPrompt = `You are an expert viral TikTok marketing strategist for e-commerce brands.
Your goal is to generate high-converting, viral TikTok video content tailored to a target demographic.

STRICT REQUIREMENT: You MUST respond ONLY with a JSON object containing exactly these four keys:
1. "hook": (string) Attention-grabbing opening statement for the first 3 seconds of the TikTok video.
2. "script": (string) Full scene-by-scene narration and camera direction script.
3. "caption": (string) Engaging TikTok post caption with a clear call-to-action.
4. "tags": (array of strings) Array of 4-6 trending hashtag strings starting with #.`;

  const userPrompt = `Target Demographic: ${demographic}
Product / Image Context: ${imageContext}`;

  try {
    const completion = await openai.chat.completions.create({
      model: "gpt-4o-mini",
      response_format: { type: "json_object" },
      messages: [
        { role: "system", content: systemPrompt },
        { role: "user", content: userPrompt },
      ],
      temperature: 0.8,
    });

    const rawJson = completion.choices[0]?.message?.content || "{}";
    const parsedContent = JSON.parse(rawJson);

    return response.json({
      hook: parsedContent.hook || "Check out this product!",
      script: parsedContent.script || "Full script...",
      caption: parsedContent.caption || "Shop now link in bio!",
      tags: parsedContent.tags || ["#PawSnap", "#FashionTok"],
      demographic,
      imageContext,
    });
  } catch (error) {
    console.error("OpenAI Paw Snap Error:", error);
    return response.status(500).json({
      error: "Paw Snap OpenAI API call failed",
      details: error.message,
    });
  }
});

app.listen(port, () => console.log(`AI Live Commerce API listening on http://localhost:${port}`));
