#!/usr/bin/env python3
import os
import json
import asyncio
import logging
from contextlib import asynccontextmanager
from typing import Any, Dict, List, Optional

from fastapi import FastAPI, WebSocket, WebSocketDisconnect, Query
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from pydantic import BaseModel, Field, field_validator

# --- Google Gemini SDK ---
# Using the 'google-genai' wrapper as requested
from google import genai

# ---------------------------------------------------------------------
# Logging Configuration
# ---------------------------------------------------------------------
LOG_LEVEL = os.getenv("LOG_LEVEL", "INFO").upper()

logging.basicConfig(
    level=LOG_LEVEL,
    format="%(asctime)s [%(levelname)s] %(name)s: %(message)s",
    datefmt="%Y-%m-%d %H:%M:%S",
)
logger = logging.getLogger("gemini-fastapi")

# ---------------------------------------------------------------------
# Gemini Client Setup (Using genai.Client)
# ---------------------------------------------------------------------
API_KEY = os.getenv("GOOGLE_API_KEY")
if not API_KEY:
    logger.error("Missing GOOGLE_API_KEY environment variable.")
    raise RuntimeError("Missing GOOGLE_API_KEY environment variable")

try:
    # Use the genai.Client as requested
    client = genai.Client(api_key=API_KEY)
    logger.info("✅ Gemini client (google-genai wrapper) initialized successfully.")
except Exception as e:
    logger.exception("Failed to initialize Gemini client: %s", e)
    raise

# ---------------------------------------------------------------------
# FastAPI Lifespan
# ---------------------------------------------------------------------
@asynccontextmanager
async def lifespan(app: FastAPI):
    """Modern lifespan event handler for startup and shutdown."""
    logger.info("🚀 FastAPI Gemini app starting up...")
    try:
        yield
    finally:
        logger.info("🛑 FastAPI Gemini app shutting down...")

# ---------------------------------------------------------------------
# FastAPI App
# ---------------------------------------------------------------------
app = FastAPI(
    title="Gemini Streaming Proxy (google-genai wrapper)",
    lifespan=lifespan,
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # tighten for production
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ---------------------------------------------------------------------
# Pydantic Models (Compatible with Pydantic v2.12.3)
# ---------------------------------------------------------------------
class MessageIn(BaseModel):
    content: str = Field(..., description="User's message for the model")
    history: Optional[List[Dict[str, Any]]] = Field(default_factory=list)
    model: str = Field(default="gemini-1.5-flash-latest")
    system_instruction: Optional[str] = None
    config: Optional[Dict[str, Any]] = Field(
        default_factory=lambda: {
            "temperature": 0.7,
            "top_p": 1.0,
            "max_output_tokens": 2048,
        }
    )

    # Pydantic v2 validator
    @field_validator("model")
    @classmethod
    def validate_model_prefix(cls, v: str) -> str:
        """
        The google-genai wrapper library expects models to be prefixed.
        e.g., 'models/gemini-1.5-flash-latest'
        This validator adds it if missing.
        """
        if not v.startswith("models/"):
            return f"models/{v}"
        return v

# ---------------------------------------------------------------------
# Health Check
# ---------------------------------------------------------------------
@app.get("/healthz")
def health() -> Dict[str, str]:
    return {"status": "ok"}

# ---------------------------------------------------------------------
# WebSocket Endpoint (Using genai.Client.aio.chats)
# ---------------------------------------------------------------------
@app.websocket("/ws/chat")
async def ws_chat(ws: WebSocket, model: Optional[str] = Query(default='gemini-flash-lite-latest')):
    """
    WebSocket protocol:
      - Client sends JSON: {"content": "...", "history": [...], "model": "..."}
      - Server streams: {"type": "delta", "text": "..."} then {"type": "done"}
    """
    await ws.accept()
    client_ip = ws.client.host if ws.client else "unknown"
    logger.info(f"🌐 Client connected: {client_ip} model {model}")

    try:
        while True:
            try:
                raw = await ws.receive_text()
                data = json.loads(raw)
                
                # Allow query param to override model
                if model:
                    data["model"] = model
                    
                msg = MessageIn(**data)
                
                logger.info(f"📩 Received message from {client_ip} (model={msg.model})")
            
            except json.JSONDecodeError:
                err_msg = "Invalid JSON format from client."
                logger.warning(f"{client_ip} - {err_msg}")
                await ws.send_json({"type": "error", "message": err_msg})
                continue
            except Exception as e: # Catches Pydantic validation errors
                logger.exception(f"Error parsing client message: {e}")
                await ws.send_json({"type": "error", "message": str(e)})
                continue

            try:
                # 1. Setup Chat creation arguments
                chat_kwargs: Dict[str, Any] = {"model": msg.model}
                
                # This library handles system instructions by prepending them to the history
                if msg.system_instruction:
                    history_to_send = [
                        {"role": "user", "parts": [msg.system_instruction]},
                        {"role": "model", "parts": ["Understood."]} 
                    ] + msg.history
                else:
                    history_to_send = msg.history
                
                if history_to_send:
                    chat_kwargs["history"] = history_to_send

                # 2. Create a new, stateless chat session FOR THIS REQUEST
                #    We pass the history here.
                chat = client.aio.chats.create(**chat_kwargs)
                
                generation_config = msg.config or {}

                # 3. Send ONLY the new content to the stream
                #    The history is already in the session.
                async for chunk in await chat.send_message_stream(
                    msg.content, 
                    config=generation_config
                ):
                    if getattr(chunk, "text", None):
                        await ws.send_json({"type": "delta", "text": chunk.text})

                await ws.send_json({"type": "done"})
                logger.info(f"✅ Stream completed for {client_ip} (model={msg.model})")

            except Exception as gen_err:
                logger.exception(f"Gemini streaming error: {gen_err}")
                await ws.send_json({"type": "error", "message": str(gen_err)})

    except WebSocketDisconnect:
        logger.info(f"🔌 Client disconnected: {client_ip}")
    except Exception as e:
        logger.exception(f"Unexpected server error: {e}")
        try:
            await ws.send_json({"type": "error", "message": f"Server error: {e}"})
        except Exception:
            pass
    finally:
        try:
            await ws.close()
        except RuntimeError:
            pass # Already closed

# ---------------------------------------------------------------------
# HTTP Fallback Endpoint (Using genai.Client)
# ---------------------------------------------------------------------
@app.post("/chat")
async def http_chat(msg: MessageIn):
    """Simple non-streaming Gemini chat endpoint."""
    try:
        logger.info(f"HTTP chat request (model={msg.model})")
        
        # 1. Setup Chat creation arguments
        chat_kwargs: Dict[str, Any] = {"model": msg.model}
        
        if msg.system_instruction:
            history_to_send = [
                {"role": "user", "parts": [msg.system_instruction]},
                {"role": "model", "parts": ["Understood."]}
            ] + msg.history
        else:
            history_to_send = msg.history
        
        if history_to_send:
            chat_kwargs["history"] = history_to_send

        # 2. Create session and send message
        chat = client.aio.chats.create(**chat_kwargs)
        resp = await chat.send_message(
            msg.content,
            generation_config=msg.config
        )

        return JSONResponse({"text": resp.text})
    except Exception as e:
        logger.exception(f"HTTP chat generation failed: {e}")
        return JSONResponse({"error": str(e)}, status_code=500)

