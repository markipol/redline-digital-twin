import hid
import time

VENDOR_ID = 0x3553
PRODUCT_ID = 0xA001


def parse_temperature_packet(data):
    """
    Parses a temperature reading packet.
    Expected format: 80 80 XX XX 4E 20 00 00
    Extracts temperature from bytes 2-3 (little endian).
    """
    if len(data) != 8:
        return None

    if data[0] == 0x80 and data[1] == 0x80 and data[4] == 0x4E and data[5] == 0x20:
        raw_temp = data[3] | (data[2] << 8)
        return raw_temp / 100.0

    return None


def find_temper_device():
    """
    Finds the TEMPer device with the correct interface number.
    Returns the device path or None if not found.
    """
    for d in hid.enumerate():
        if d['vendor_id'] == VENDOR_ID and d['product_id'] == PRODUCT_ID and d['interface_number'] == 1:
            return d['path']
    return None


def read_temperature():
    """
    Initializes the TEMPer device and reads the current temperature.
    Returns the temperature in Celsius or None if failed.
    """
    device_path = find_temper_device()
    if not device_path:
        print("Interface 1 not found.")
        return None

    try:
        with hid.Device(path=device_path) as h:
            # Packet 1 (get device string / trigger temp read)
            packet = [0x01, 0x80, 0x33, 0x01, 0x00, 0x00, 0x00, 0x00]
            h.write(bytes(packet))
            time.sleep(0.1)
            response = h.read(16, 1000)
            return parse_temperature_packet(response)
    except Exception as e:
        print("Error reading device:", e)
        return None


if __name__ == "__main__":
    temp = read_temperature()
    if temp is not None:
        print(f"Temperature: {temp:.2f} °C")
    else:
        print("Failed to read temperature.")
