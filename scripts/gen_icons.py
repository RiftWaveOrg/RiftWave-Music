from PIL import Image
import os

def resize_icon(src_path, dst_dir, size):
    os.makedirs(dst_dir, exist_ok=True)
    with Image.open(src_path) as img:
        img = img.resize((size, size), Image.Resampling.LANCZOS)
        img.save(os.path.join(dst_dir, 'ic_launcher.png'), 'PNG')

base_dir = r"p:\RiftWave-Music\android\app\src\main\res"
src = r"p:\RiftWave-Music\assets\images\app_icon.jpg"

sizes = {
    "mipmap-mdpi": 48,
    "mipmap-hdpi": 72,
    "mipmap-xhdpi": 96,
    "mipmap-xxhdpi": 144,
    "mipmap-xxxhdpi": 192,
}

for folder, size in sizes.items():
    resize_icon(src, os.path.join(base_dir, folder), size)
    
print("Icons generated.")
