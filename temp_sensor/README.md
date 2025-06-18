# 🌡️ TEMPerGold USB Thermometer Setup for Pi

<picture>
  <img src="/images/TEMPerGold.jpg" alt="A TEMPerGold attached to a USB Extension cable" width="600">
</picture>

Please note: if running on a Raspberry Pi, please use a USB Extender (as in the image) or USB Hub to make the heat of the Pi not artificially raise the temperature of the sensor. 

Tested on Pi 2 and Pi 3 (note both cases below in USB permissions).

## 1. Create Project Folder

```bash
mkdir temper-reader
cd temper-reader
```

## 2. Create Virtual Environment

```bash
python3 -m venv temper
```

## 3. Activate Virtual Environment

```bash
source temper/bin/activate
```

You should now see this in your terminal:

```
(temper) pi@raspberrypi:~/temper-reader $
```

## 4. Install Dependencies

Install `hid` and other required packages inside the virtual environment:

```bash
pip install hid requests dotenv
```

## 5. Configure Device Access

Allow the normal user to access the TEMPer device without using `sudo`.

### Create udev Rule

```bash
sudo nano /etc/udev/rules.d/99-temper.rules
```

Paste the following lines (to cover both cases of if the sensor is a root device or a child device, former on Pi 3, latter on Pi 2):

```bash
SUBSYSTEM=="hidraw", ATTRS{idVendor}=="3553", ATTRS{idProduct}=="a001", MODE="0666", GROUP="plugdev"
SUBSYSTEM=="hidraw", SUBSYSTEMS=="usb", ATTRS{idVendor}=="3553", ATTRS{idProduct}=="a001", MODE="0666", GROUP="plugdev"
```

### Reload udev Rules and Trigger

```bash
sudo udevadm control --reload-rules
sudo udevadm trigger
```

### Add User to plugdev Group

```bash
sudo usermod -aG plugdev $USER
```

### Reboot Pi to Apply Changes

```bash
sudo reboot
```

### Verify Group Membership

```bash
groups
```

- Ensure `plugdev` is included in the list.

## 6. Environment Configuration

### Create `.env` File

```bash
touch .env
nano .env
```

Contents of `.env`:

```env
WRITE_KEY = <write key goes here>
```

## 7. Run Temperature Reader

### Activate Virtual Environment Again

```bash
source temper/bin/activate
```

### Run Reader Script

```bash
python3 read_temp.py
```

## 8. Automate Upload with Cron

(note: please change the server URL to your URL in upload_temp.py)

### Edit Crontab

```bash
crontab -e
```

### Add This Line (Run Every Hour)

```cron
0 * * * * /home/mark/temper-env/bin/python /home/mark/upload_temp.py >> /home/mark/temp_log.txt 2>&1
```

---
Done! The Pi should now read and upload temperature to the server every hour, on the hour (i.e. runs at 5:00pm, 6:00pm, etc).
