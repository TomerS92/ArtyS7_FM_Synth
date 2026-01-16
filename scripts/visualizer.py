import serial
import matplotlib.pyplot as plt
from matplotlib.animation import FuncAnimation
import collections
import time

# --- CONFIGURATION ---
PORT = 'COM4'  # Update to your COM port
BAUD = 115200
WINDOW_SIZE = 600  # Number of samples visible

# Data buffer initialized to the center (128)
data_buffer = collections.deque([128]*WINDOW_SIZE, maxlen=WINDOW_SIZE)

try:
    # Open with a larger buffer to handle bursty FPGA data
    ser = serial.Serial(PORT, BAUD, timeout=0.01)
    # Flush existing data to start clean
    ser.reset_input_buffer()
    print(f"Connected to {PORT}. Visualizing output...")
except Exception as e:
    print(f"Error: {e}. Close VS Code Serial Monitor before running!")
    exit()

# Setup Dark Mode Plot
plt.style.use('dark_background')
fig, ax = plt.subplots(figsize=(12, 6))
line, = ax.plot(list(data_buffer), color='#00FF41', linewidth=1.5)
ax.set_ylim(0, 255)
ax.set_xlim(0, WINDOW_SIZE)
ax.set_title("Arty S7 FM Synthesizer Output (Real-Time)")
ax.set_xlabel("Sample Buffer")
ax.set_ylabel("Amplitude")
ax.grid(True, alpha=0.1)

def update(frame):
    if ser.in_waiting > 0:
        # Read a chunk of data to avoid falling behind the 48kHz sub-sampled stream
        raw = ser.read(min(ser.in_waiting, 100))
        for byte in raw:
            data_buffer.append(byte)
    
    line.set_ydata(list(data_buffer))
    return line,

# Use a slightly faster interval for smoother FM visualization
ani = FuncAnimation(fig, update, interval=10, blit=True, cache_frame_data=False)

try:
    plt.show()
except KeyboardInterrupt:
    pass
finally:
    ser.close()
    print("Port closed.")