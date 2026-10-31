import os
import glob
from PIL import Image

def make_gif():
    images_dir = os.path.join(os.path.dirname(__file__), '..', 'docs', 'images')
    frame_files = [
        os.path.join(images_dir, 'frame1.png'),
        os.path.join(images_dir, 'frame2.png'),
        os.path.join(images_dir, 'frame3.png'),
        os.path.join(images_dir, 'frame4.png'),
        os.path.join(images_dir, 'frame5.png'),
        os.path.join(images_dir, 'frame6.png'),
    ]

    existing_frames = [f for f in frame_files if os.path.exists(f)]
    if not existing_frames:
        print("[!] No frames found to create GIF.")
        return

    frames = []
    for f in existing_frames:
        im = Image.open(f)
        # Convert to RGB (or optimize palette)
        # Resize to 1280 width for crisp yet compact presentation
        if im.width > 1280:
            scale = 1280 / im.width
            new_size = (int(im.width * scale), int(im.height * scale))
            im = im.resize(new_size, Image.Resampling.LANCZOS)
        # Convert to P mode with adaptive palette for crisp GIF rendering
        im_p = im.convert('P', palette=Image.ADAPTIVE, colors=256)
        frames.append(im_p)

    out_gif = os.path.join(images_dir, 'blaisenotebook_demo.gif')
    # Duration per frame: 2500ms
    frames[0].save(
        out_gif,
        save_all=True,
        append_images=frames[1:],
        duration=2500,
        loop=0,
        optimize=True
    )
    print(f"[+] Animated demo GIF created successfully at: {out_gif} ({len(frames)} frames)")

if __name__ == '__main__':
    make_gif()
