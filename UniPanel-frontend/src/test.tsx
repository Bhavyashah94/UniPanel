import React, { useEffect } from 'react';
import io from 'socket.io-client';

const realtimecomponent = () => {
  useEffect(() => {
    const socket = io('http://localhost:8000'); // Adjust the URL as needed

    socket.on('connect', () => {
      console.log('Connected to server');
    });

    socket.on('message', (data) => {
      console.log('Message from server:', data);
    });

    return () => {
      socket.disconnect();
      console.log('Disconnected from server');
    };
  }, []);

  return (
    <>
    </>
  );
}

export default realtimecomponent;