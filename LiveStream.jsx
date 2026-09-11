import { useEffect, useRef, useState } from "react";
import { Send, ShoppingBag, Volume2 } from "lucide-react";

const API_BASE_URL = import.meta.env.VITE_API_BASE_URL || "http://localhost:3001";

const product = {
  name: "Handmade Leather Wallet",
  price: "$40",
  stock: 5,
  image:
    "https://images.unsplash.com/photo-1627123424574-724758594e93?auto=format&fit=crop&w=320&q=80",
};

/** A mobile-first TikTok-Live-style AI commerce stream. */
export default function LiveStream() {
  const videoRef = useRef(null);
  const peerConnectionRef = useRef(null);
  const chatEndRef = useRef(null);
  const [sessionId, setSessionId] = useState(null);
  const [isStarting, setIsStarting] = useState(false);
  const [status, setStatus] = useState("Ready to go live");
  const [message, setMessage] = useState("");
  const [isSending, setIsSending] = useState(false);
  const [messages, setMessages] = useState([
    { id: "welcome", author: "Leather Live", text: "Hi! Ask me anything about today’s handmade wallets." },
  ]);

  useEffect(() => {
    chatEndRef.current?.scrollIntoView({ behavior: "smooth" });
  }, [messages]);

  useEffect(() => () => peerConnectionRef.current?.close(), []);

  // Negotiates the browser half of the WebRTC connection with the avatar service.
  const startStream = async () => {
    if (isStarting || sessionId) return;

    setIsStarting(true);
    setStatus("Connecting to avatar…");

    try {
      const response = await fetch(`${API_BASE_URL}/api/start-stream`, { method: "POST" });
      if (!response.ok) throw new Error("Unable to start avatar session");

      const { session_id, offer } = await response.json();
      const peerConnection = new RTCPeerConnection({
        iceServers: [{ urls: "stun:stun.l.google.com:19302" }],
      });
      peerConnectionRef.current = peerConnection;

      peerConnection.ontrack = (event) => {
        if (videoRef.current) {
          videoRef.current.srcObject = event.streams[0];
          videoRef.current.play().catch(() => {});
        }
        setStatus("Live");
      };

      peerConnection.onconnectionstatechange = () => {
        if (peerConnection.connectionState === "failed") setStatus("Connection failed");
        if (peerConnection.connectionState === "disconnected") setStatus("Reconnecting…");
      };

      await peerConnection.setRemoteDescription(new RTCSessionDescription(offer));
      const answer = await peerConnection.createAnswer();
      await peerConnection.setLocalDescription(answer);

      // In the real HeyGen flow, POST peerConnection.localDescription to its answer endpoint here.
      // This demo backend has no remote media service to receive the answer.
      setSessionId(session_id);
      setStatus("Avatar session ready");
    } catch (error) {
      console.error(error);
      peerConnectionRef.current?.close();
      peerConnectionRef.current = null;
      setStatus(error.message || "Could not start stream");
    } finally {
      setIsStarting(false);
    }
  };

  const sendChat = async (event) => {
    event.preventDefault();
    const text = message.trim();
    if (!text || isSending) return;

    setMessages((current) => [...current, { id: crypto.randomUUID(), author: "You", text }]);
    setMessage("");
    setIsSending(true);

    try {
      const response = await fetch(`${API_BASE_URL}/api/chat`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ message: text, sessionId }),
      });
      if (!response.ok) throw new Error("Chat request failed");

      const { reply } = await response.json();
      setMessages((current) => [
        ...current,
        { id: crypto.randomUUID(), author: "Leather Live", text: reply },
      ]);
    } catch (error) {
      setMessages((current) => [
        ...current,
        { id: crypto.randomUUID(), author: "System", text: "Sorry, please try again." },
      ]);
    } finally {
      setIsSending(false);
    }
  };

  return (
    <main className="mx-auto flex h-[100dvh] max-w-md overflow-hidden bg-zinc-950 text-white">
      <section className="relative isolate flex h-full w-full flex-col bg-zinc-900">
        <video ref={videoRef} autoPlay playsInline muted className="absolute inset-0 h-full w-full object-cover" />
        <div className="absolute inset-0 bg-gradient-to-b from-black/45 via-transparent to-black/85" />

        <header className="relative z-10 flex items-center justify-between p-4 pt-[max(1rem,env(safe-area-inset-top))]">
          <div className="flex items-center gap-2 rounded-full bg-black/45 px-3 py-1.5 text-sm backdrop-blur">
            <span className={`h-2 w-2 rounded-full ${status === "Live" ? "bg-red-500" : "bg-amber-400"}`} />
            {status}
          </div>
          <button onClick={startStream} disabled={isStarting || Boolean(sessionId)} className="rounded-full bg-white px-4 py-2 text-sm font-bold text-zinc-950 disabled:opacity-60">
            {isStarting ? "Starting…" : sessionId ? "Live session" : "Go live"}
          </button>
        </header>

        <article className="relative z-10 ml-auto mr-4 mt-1 flex w-60 gap-3 rounded-2xl bg-white/95 p-2 text-zinc-900 shadow-xl">
          <img src={product.image} alt={product.name} className="h-16 w-16 rounded-xl object-cover" />
          <div className="min-w-0 py-0.5">
            <p className="line-clamp-2 text-sm font-bold">{product.name}</p>
            <p className="mt-1 text-sm font-bold text-emerald-700">{product.price}</p>
            <p className="text-xs text-zinc-500">Only {product.stock} in stock</p>
          </div>
        </article>

        <div className="relative z-10 mt-auto bg-gradient-to-t from-black/90 via-black/65 to-transparent px-4 pb-[max(1rem,env(safe-area-inset-bottom))] pt-16">
          <div className="mb-3 flex items-center gap-2 text-sm font-semibold text-white/90"><Volume2 size={16} /> AI host is here to help</div>
          <div className="h-[26vh] overflow-y-auto pr-1">
            {messages.map((item) => (
              <p key={item.id} className="mb-2 max-w-[92%] text-sm leading-5 drop-shadow"><span className="mr-1 font-bold text-amber-300">{item.author}:</span>{item.text}</p>
            ))}
            <div ref={chatEndRef} />
          </div>
          <form onSubmit={sendChat} className="mt-3 flex gap-2">
            <label className="sr-only" htmlFor="live-chat">Ask about the wallet</label>
            <input id="live-chat" value={message} onChange={(event) => setMessage(event.target.value)} placeholder="Ask about the wallet…" className="min-w-0 flex-1 rounded-full border border-white/20 bg-white/15 px-4 py-3 text-sm outline-none placeholder:text-white/60 focus:border-amber-300" />
            <button type="submit" disabled={isSending} aria-label="Send message" className="grid h-11 w-11 shrink-0 place-items-center rounded-full bg-amber-400 text-zinc-950 disabled:opacity-50"><Send size={18} /></button>
          </form>
          <p className="mt-2 flex items-center gap-1 text-xs text-white/60"><ShoppingBag size={13} /> Tap Go live to connect the avatar.</p>
        </div>
      </section>
    </main>
  );
}
