import socketio

# Define your allowed origins for CORS
# This should include the URL where your frontend is running (e.g., http://localhost:5173)
# For production, replace 'http://localhost:5173' with your actual frontend domain(s).
# Avoid using "*" in production as it's a security risk.
allowed_origins = [
    "http://localhost:5173",  # Your frontend development server
    "http://127.0.0.1:5173",  # Sometimes localhost resolves to 127.0.0.1
    "http://localhost",       # For direct access if needed
    # Add other production origins here, e.g., "https://your-frontend-domain.com"
]

# Create a Socket.IO server instance
# Configure CORS by passing the allowed_origins list
sio = socketio.AsyncServer(
    async_mode='asgi',
    cors_allowed_origins=allowed_origins,
    # You can also set other CORS options if needed, e.g.,
    # cors_credentials=True,
    # cors_methods=['GET', 'POST'],
    # cors_headers=['Content-Type'],
)

# Wrap the Socket.IO server with an ASGI application
# This 'app' object is what Uvicorn will run
app = socketio.ASGIApp(sio)

@sio.event
async def connect(sid, environ):
    """
    Handles a new client connection.
    sid: The session ID of the connected client.
    environ: A dictionary containing WSGI/ASGI environment variables.
    """
    print(f"Client connected: {sid}")
    # You can emit a message back to the connected client
    await sio.emit('server_message', {'data': f'Welcome, client {sid}!'}, room=sid)

@sio.event
async def my_message(sid, data):
    """
    Handles a custom 'my_message' event sent from a client.
    sid: The session ID of the client that sent the message.
    data: The data payload sent by the client.
    """
    print(f"Received message from {sid}: {data}")
    # Example: Echo the message back to the sender
    await sio.emit('response_message', {'status': 'received', 'your_data': data}, room=sid)
    # Example: Broadcast the message to all connected clients (excluding sender)
    # await sio.emit('broadcast_message', {'user': sid, 'message': data}, skip_sid=sid)

@sio.event
async def disconnect(sid):
    """
    Handles a client disconnection.
    sid: The session ID of the disconnected client.
    """
    print(f"Client disconnected: {sid}")

# To run this server, save it as (e.g.) `src/websockets/test.py`
# Then, from your project's root directory (e.g., UniPanel/backend), run:
# uvicorn src.websockets.test:app --reload --port 8000
