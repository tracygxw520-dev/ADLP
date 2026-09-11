require("dotenv").config();

const express = require("express");
const cors = require("cors");
const crypto = require("crypto");

const app = express();
const port = process.env.PORT || 3001;
const sessions = new Map();

app.use(cors());
app.use(express.json());

// TODO: HACKATHON API KEY
const OPENAI_API_KEY = process.env.OPENAI_API_KEY;
// TODO: HACKATHON API KEY
const HEYGEN_API_KEY = process.env.HEYGEN_API_KEY;

const streamerSystemPrompt =
  "You are an energetic live streamer for an MSME. Answer questions about the leather wallets. Keep responses under 2 sentences.";

// Replace this mock with an OpenAI Chat Completions/Responses API call before deployment.
async function getStreamerReply(message) {
  console.info("OpenAI mock prompt:", streamerSystemPrompt);
  const lowerMessage = message.toLowerCase();
  if (lowerMessage.includes("stock") || lowerMessage.includes("available")) {
    return "We have just 5 handmade leather wallets left—grab yours while they are still here!";
  }
  if (lowerMessage.includes("price") || lowerMessage.includes("cost")) {
    return "This handcrafted leather wallet is $40, a great everyday piece made to last.";
  }
  return "Great question! This handmade leather wallet is crafted for everyday use and makes a wonderful gift.";
}

// Replace this mock with POST https://api.heygen.com/v1/streaming.task using the active session.
async function askAvatarToSpeak(sessionId, text) {
  console.info("HeyGen mock speech task:", { sessionId, text });
  return { task_id: `mock-task-${crypto.randomUUID()}` };
}

// Mock SDP offer: replace with the offer returned when creating a HeyGen Interactive Avatar session.
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

// Creates a new avatar session and returns the SDP offer required by RTCPeerConnection.
app.post("/api/start-stream", async (_request, response) => {
  const session_id = `mock-session-${crypto.randomUUID()}`;
  sessions.set(session_id, { createdAt: Date.now() });

  response.status(201).json({
    session_id,
    offer: { type: "offer", sdp: mockOfferSdp },
  });
});

// Produces a streamer response and sends it to the avatar's speech task endpoint.
app.post("/api/chat", async (request, response) => {
  const { message, sessionId } = request.body || {};
  if (typeof message !== "string" || !message.trim()) {
    return response.status(400).json({ error: "message must be a non-empty string" });
  }

  try {
    const reply = await getStreamerReply(message.trim());
    const avatarTask = await askAvatarToSpeak(sessionId, reply);
    return response.json({ reply, avatarTask });
  } catch (error) {
    console.error("Chat pipeline failed:", error);
    return response.status(500).json({ error: "Unable to process chat" });
  }
});

app.listen(port, () => console.log(`AI Live Commerce API listening on http://localhost:${port}`));
