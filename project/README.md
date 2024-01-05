# NeRF-based 3D Reconstruction

Wang Weida 2151300

Mao Lingjun 2053058

Liang Xin 2053246

## Requirements

In this task, you are required to reconstruct a scene based on NeRF

1. Capture a set of images for a real-world scene with your device.
2. Calibrate the images using SfM tools such as Colmap to get the corresponding poses.
3. Run a NeRF-based model to reconstruct the scene from the images and poses you prepared.
4. Convert the reconstruction result to a 3D mesh (in ‘ply’ or ‘obj’ format).
5. Describe the above process in detail in your report. The following details are required:
   1. How is the scene you have chosen and how did you prepare your data
   2. Which NeRF project were you based on and what is your understanding on it
   3. What hyper-parameters did you adjust for adapting to your own data and why
   4. (Optional) What modification do you make to the codebase beyond hyper-parameter adjustments to improve the reconstruction quality?

## References

1. Mildenhall, B., Srinivasan, P. P., Tancik, M., Barron, J. T., Ramamoorthi, R., & Ng, R. (2020, August). NeRF: Representing Scenes as Neural Radiance Fields for View Synthesis. In European Conference on Computer Vision (pp. 405-421). Cham: Springer International Publishing.
2. Müller, T., Evans, A., Schied, C., & Keller, A. (2022). Instant neural graphics primitives with a multiresolution hash encoding. ACM Transactions on Graphics (ToG), 41(4), 1-15.
3. Kerbl, B., Kopanas, G., Leimkühler, T., & Drettakis, G. (2023). 3D Gaussian Splatting for Real-Time Radiance Field Rendering. ACM Transactions on Graphics, 42(4).
4. https://github.com/NVlabs/instant-ngp
5. https://lumalabs.ai/dashboard/captures
6. https://www.matthewtancik.com/nerf
7. https://www.bilibili.com/video/BV1uV4y1Y7cA/?spm_id_from=333.337.search-card.all.click&vd_source=54848bbaacc95a6670b0f8ac0228b019
8. https://zhuanlan.zhihu.com/p/648087218
9. https://www.youtube.com/watch?v=3TWxO1PftMc

## Special Acknowledgments

Special thanks to teaching assistant **Fengyi Zhang** for providing guidance, and to **Chen Xialu**, an student from College of Design and Innovation, Tongji University, for offering us the efficient and effective baseline of Luma AI. Also, thanks to the great teamwork of our two teammates **Mao and Liang**.

You can also view our project at my blog: https://wwd.zeabur.app/article/homework:cv-nerf-based-3d-restruction.