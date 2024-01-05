# From Colmap to NeRF

Running the `colmap2nerf.py` Script

This guide is designed to assist you in using the `colmap2nerf.py` script to convert video data into training data for Neural Radiance Fields (NeRF) models. Follow these steps and instructions to run the script effectively.

## Requirements

- **Linux Users**: Ensure that you have installed [COLMAP](https://colmap.github.io/) and [FFmpeg](https://www.ffmpeg.org/), and that they are added to your system PATH.
- **Windows Users**: No need for prior installations. COLMAP and FFmpeg will automatically download when running the script.

## Usage Instructions

### Training from a Video File

1. **Navigate to Your Video File's Directory**:
   - Open a terminal or command prompt window.
   - Change to the directory containing your video file.

2. **Run the Script**:
   - Execute the script with the following command:
     ```
     python [path-to-instant-ngp]/scripts/colmap2nerf.py --video_in <video file name> --video_fps 2 --run_colmap --aabb_scale 32
     ```
   - Replace `[path-to-instant-ngp]` with the actual path to the script.
   - Substitute `<video file name>` with your video file's name (e.g., `bag.mov`).

3. **Processing**:
   - The script will first use FFmpeg to convert the video into a series of images.
   - Then, it runs COLMAP for 3D reconstruction.
   - Finally, it generates a `transforms.json` file containing necessary data for NeRF training.

### Training from Image Files

1. **Prepare Your Images**:
   - Place your images in a subfolder named `images`.

2. **Run the Script**:
   - Run the script with the following command:
     ```
     python [path-to-instant-ngp]/scripts/colmap2nerf.py --colmap_matcher exhaustive --run_colmap --aabb_scale 32
     ```
   - Ensure the path and parameters are correctly set.

3. **Processing**:
   - The script will process your images with COLMAP and generate data for NeRF training.

## Output Files

- A series of images extracted at the specified frame rate (if starting from a video).
- COLMAP generated reconstruction files such as `cameras.txt` and `images.txt`.
- `transforms.json`: Contains necessary data for training a NeRF model.

## Training from Image Files

1. **Prepare Your Images**:
   - Place images in a subfolder named `images`.

2. **Run the Script for Images**:
   - Use the command:
     ```
     python [path-to-instant-ngp]/scripts/colmap2nerf.py --colmap_matcher exhaustive --run_colmap --aabb_scale 16 --overwrite
     ```
   - This command uses exhaustive matching, ideal for unordered image sets.

3. **Processing Images**:
   - The script processes images with COLMAP.
   - Generates data for NeRF training.




## Additional Options

- Use the `--mask_categories` parameter to automatically generate masks for specific objects (e.g., `--mask_categories person car`).
- `--overwrite` to replace existing images and COLMAP data.

## Notes

- Make sure your system meets the requirements.
- Adjust the paths and filenames in the commands according to your specific setup.
- For more options and advanced usage, refer to the script's `--help` or relevant documentation.

 