# 🌡️ TEMPerGold USB Thermometer Setup for Pi

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

Paste the following lines (to cover both cases - root device and child device):

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

### Edit Crontab

```bash
crontab -e
```

### Add This Line (Run Every Hour)

```cron
0 * * * * /home/mark/temper-env/bin/python /home/mark/upload_temp.py >> /home/mark/temp_log.txt 2>&1
```

---

That’s it! Your TEMPer USB thermometer should now read and upload temperature data every hour automatically.
